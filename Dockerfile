#▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
#▐  __  __ _       _                 _  ▌
#▐ |  \/  (_)_ __ (_)_ __ ___   __ _| | ▌
#▐ | |\/| | | '_ \| | '_ ` _ \ / _` | | ▌
#▐ | |  | | | | | | | | | | | | (_| | | ▌
#▐ |_|  |_|_|_| |_|_|_| |_| |_|\__,_|_| ▌
#▐                                      ▌
#▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌
FROM docker.io/library/debian:13.7 AS minimal

SHELL ["/bin/bash", "-x", "-c"]

WORKDIR /root

# Install dependencies to compile and run x86 with nasm and gcc
RUN export DEBIAN_FRONTEND=noninteractive \
 && echo "Installing minimal dependencies" \
 && apt-get update \
 && apt-get install -y \
        nasm gcc g++ bison yacc make \
        curl build-essential pkg-config unzip \
 && apt-get clean autoclean \
 && apt-get autoremove --yes \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /id2202


#▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
#▐   ____                      _      _        ▌
#▐  / ___|___  _ __ ___  _ __ | | ___| |_ ___  ▌
#▐ | |   / _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ ▌
#▐ | |__| (_) | | | | | | |_) | |  __/ ||  __/ ▌
#▐  \____\___/|_| |_| |_| .__/|_|\___|\__\___| ▌
#▐                      |_|                    ▌
#▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌
FROM minimal AS complete

WORKDIR /root

# Setup environment variable that are necessary at install
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    OPAMROOTISOK=1 \
    PATH=/usr/local/cargo/bin:/root/.local/bin:$PATH

ARG TARGETPLATFORM
ARG INSTALL_OCAML
ARG INSTALL_HASKELL
ARG INSTALL_JAVA
ARG INSTALL_SCALA
ARG INSTALL_RUST
RUN export DEBIAN_FRONTEND=noninteractive \
 && if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        export ARCHITECTURE=x86_64; \
    elif [ "$TARGETPLATFORM" = "linux/x86_64" ]; then \
        export ARCHITECTURE=x86_64; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        export ARCHITECTURE=aarch64; \
    elif [ "$TARGETPLATFORM" = "linux/aarch64" ]; then \
        export ARCHITECTURE=aarch64; \
    else \
        export ARCHITECTURE=noarch; \
    fi \
 && echo "Updating apt lists" \
 && apt-get update \
 && apt-get install -y ca-certificates ca-certificates-java \
 # OCaml
 && if [ "$INSTALL_OCAML" = "y" ]; then \
        echo -e "\e[1;32m<<<<==== Installing OCaml + Opam ====>>>>\e[0m" \
     && bash -c "curl -fsSL https://opam.ocaml.org/install.sh | bash" \
     && opam init -y --disable-sandboxing --compiler=5.5.0 \
     && opam install -y ocamlbuild menhir ocamlfind core utop \
  ; else \
        echo -e "\e[1;33m<<<<==== Skipping OCaml + Opam ====>>>>\e[0m" \
  ; fi \
 # Haskell
 && if [ "$INSTALL_HASKELL" = "y" ]; then \
        echo -e "\e[1;32m<<<<==== Installing Haskell ====>>>>\e[0m" \
     && mkdir -p /buildsrc/haskell \
     && cd /buildsrc/haskell \
     && curl -fsSL https://get.haskellstack.org/ -o /buildsrc/haskell/stackinstall.sh \
     && sh /buildsrc/haskell/stackinstall.sh \
     # Setup stack packages
     && apt-get install -y libnuma-dev \
     && stack setup --resolver lts-24.6 \
     && stack install --resolver lts-24.6 \
            alex-3.5.4.0 \
            happy-2.1.7 \
            optparse-applicative-0.18.1.0 \
            pretty-show-1.10 \
            prettyprinter-1.7.1 \
            protolude-0.3.5 \
            recursion-schemes-5.2.3 \
            uniplate-1.6.13 \
            unordered-containers-0.2.20 \
     # Remove documentation
     && rm -rf /root/.stack/programs/*/ghc-*/share/doc \
  ; else \
        echo -e "\e[1;33m<<<<==== Skipping Haskell ====>>>>\e[0m" \
  ; fi \
 # Java
 && if [ "$INSTALL_JAVA" = "y" ]; then \
        echo -e "\e[1;32m<<<<==== Installing Java ====>>>>\e[0m" \
     && apt-get install -y openjdk-21-jdk-headless maven \
  ; else \
        echo -e "\e[1;33m<<<<==== Skipping Java ====>>>>\e[0m" \
  ; fi \
 # Scala
 && if [ "$INSTALL_SCALA" = "y" ]; then \
        echo -e "\e[1;32m<<<<==== Installing Scala ====>>>>\e[0m" \
     && mkdir -p /buildsrc/scala \
     && cd /buildsrc/scala \
     && apt-get install -y openjdk-21-jdk-headless \
     && curl -fL https://github.com/coursier/launchers/raw/master/cs-${ARCHITECTURE}-pc-linux.gz | gzip -d > /buildsrc/scala/cs \
     && chmod +x /buildsrc/scala/cs \
     && mv cs /usr/local/bin/cs \
     && cs setup --yes --apps scala:3.10.0,scalac:3.10.0,scala-cli \
     && echo '@main def main = println(s"Scala library version ${dotty.tools.dotc.config.Properties.versionNumberString}")' > /buildsrc/scala/test.scala \
     && cs launch scala -- -nocompdaemon test.scala \
     # Scala-Bison
     && curl -fL https://gist.githubusercontent.com/phaller/8e7b57c23f80b0ef8b1e68d4eb579dc7/raw/3d5019801e56fb91337b00878df2cae1c7730fa2/scala-bison -o /buildsrc/scala/scala-bison.sh \
     && chmod +x /buildsrc/scala/scala-bison.sh \
     && mv /buildsrc/scala/scala-bison.sh /usr/local/bin/scala-bison \
     && curl -fL https://github.com/phaller/scala-bison/releases/download/v1.2/scala-bison-3.3.jar -o /buildsrc/scala/scala-bison-3.3.jar \
     && mkdir -p /usr/local/share/scala-bison/lib \
     && mv scala-bison-3.3.jar /usr/local/share/scala-bison/lib/scala-bison-3.3.jar \
     && (scala-bison || true) \
     # Prepare scala-cli
     && cd /root \
     && echo "object Temp extends App" > /root/Temp.scala \
     && cs launch scala-cli -- --power package Temp.scala -o temp \
     && rm /root/temp /root/Temp.scala \
  ; else \
        echo -e "\e[1;33m<<<<==== Skipping Scala ====>>>>\e[0m" \
  ; fi \
 # Rust
 && if [ "$INSTALL_RUST" = "y" ]; then \
        echo -e "\e[1;32m<<<<==== Installing Rust ====>>>>\e[0m" \
     && mkdir -p /buildsrc/rust \
     && cd /buildsrc/rust \
     && apt-get install -y --no-install-recommends libc6-dev libssl-dev \
     && curl -fLO "https://static.rust-lang.org/rustup/dist/${ARCHITECTURE}-unknown-linux-gnu/rustup-init" \
     && chmod +x rustup-init \
     && ./rustup-init -y --profile minimal -c clippy,rustfmt --no-modify-path --default-toolchain 1.99.0 \
     && rm rustup-init \
     && rustup --version \
     && cargo --version \
     && rustc --version \
     # Setup Rust Cargo
     && cargo install -j1 cargo-prefetch \
     && cargo prefetch \
     # Cleanup
     && rm -rf $CARGO_HOME/registry/src \
     && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
  ; else \
        echo -e "\e[1;33m<<<<==== Skipping Rust ====>>>>\e[0m" \
  ; fi \
 # Cleanup
 && cd /root \
 && rm -rf /buildsrc \
 && apt-get clean autoclean \
 && apt-get autoremove --yes \
 && rm -rf /var/lib/apt/lists/* \
 # Finalize
 && echo "Done."

ENV OPAM_SWITCH_PREFIX='/root/.opam/5.5.0' \
    CAML_LD_LIBRARY_PATH='/root/.opam/5.5.0/lib/stublibs:/root/.opam/5.5.0/lib/ocaml/stublibs:/root/.opam/5.5.0/lib/ocaml' \
    OCAML_TOPLEVEL_PATH='/root/.opam/5.5.0/lib/toplevel' \
    MANPATH=':/root/.opam/system/man:/root/.opam/5.5.0/man' \
    PATH='/root/.opam/5.5.0/bin:/root/.opam/system/bin:/usr/local/cargo/bin:/root/.local/share/coursier/bin:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH'

WORKDIR /id2202
