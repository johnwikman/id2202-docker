FROM docker.io/library/ubuntu:24.04

SHELL ["/bin/bash", "-c"]

WORKDIR /root

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/root/.local/bin:$PATH

ARG TARGETPLATFORM
RUN DEBIAN_FRONTEND=noninteractive echo "Installing dependencies" \
 && apt-get update \
 && apt-get install -y curl software-properties-common build-essential \
                       libssl-dev pkg-config zsh nasm \
 && apt-add-repository -y ppa:fish-shell/release-3 \
 && apt-get install -y --no-install-recommends fish \
 # C/C++
 && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
 && apt-get install -y gcc-10 g++-10 flex wget \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 1 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 1 \
 # Install recent version of bison (3.8.2)
 && mkdir -p /buildsrc/bison \
 && cd /buildsrc/bison \
 && wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz \
 && tar -xzvf bison-3.8.2.tar.gz \
 && cd /buildsrc/bison/bison-3.8.2 \
 && ./configure \
 && make \
 && make install \
 && ln -s /usr/local/bin/bison /usr/bin/bison \
 && cd /root \
 # OCaml (Install Opam here, configure later in Dockerfile)
 && add-apt-repository -y ppa:avsm/ppa \
 && apt-get install -y apt-utils m4 opam \
 # Haskell (Install Stack only, config later)
 && mkdir -p /buildsrc/haskell \
 && cd /buildsrc/haskell \
 && curl -sSL https://get.haskellstack.org/ -o /buildsrc/haskell/stackinstall.sh \
 && sh /buildsrc/haskell/stackinstall.sh \
 # Java
 && add-apt-repository -y ppa:openjdk-r/ppa \
 && apt-get install -y ca-certificates-java openjdk-17-jdk \
 # Scala
 && mkdir -p /buildsrc/scala \
 && cd /buildsrc/scala \
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
 && curl -fL https://github.com/coursier/launchers/raw/master/cs-${ARCHITECTURE}-pc-linux.gz | gzip -d > /buildsrc/scala/cs \
 && chmod +x /buildsrc/scala/cs \
 && mv cs /usr/local/bin/cs \
 && cs setup --yes --apps scala,scalac,scala-cli \
 && echo '@main def main = println(s"Scala library version ${dotty.tools.dotc.config.Properties.versionNumberString}")' > /buildsrc/scala/test.scala \
 && cs launch scala -- -nocompdaemon test.scala \
 # Scala-Bison
 && curl -fL https://gist.githubusercontent.com/phaller/5a104d227818eed3ae2ab1d4d2191675/raw/d911f070a6860803c91b28e2b58a23b2ca024854/scala-bison-cs-3.3 -o /buildsrc/scala/scala-bison.sh \
 && chmod +x /buildsrc/scala/scala-bison.sh \
 && mv /buildsrc/scala/scala-bison.sh /usr/local/bin/scala-bison \
 && curl -fL https://github.com/phaller/scala-bison/releases/download/v1.2/scala-bison-3.3.jar -o /buildsrc/scala/scala-bison-3.3.jar \
 && mkdir -p /usr/local/share/scala-bison/lib \
 && mv scala-bison-3.3.jar /usr/local/share/scala-bison/lib/scala-bison-3.3.jar \
 # Rust
 && mkdir -p /buildsrc/rust \
 && cd /buildsrc/rust \
 && apt-get install -y --no-install-recommends ca-certificates gcc libc6-dev \
 && wget "https://static.rust-lang.org/rustup/dist/${ARCHITECTURE}-unknown-linux-gnu/rustup-init" \
 && chmod +x rustup-init \
 && ./rustup-init -y --no-modify-path --default-toolchain nightly \
 && rm rustup-init \
 && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
 && rustup --version \
 && cargo --version \
 && rustc --version \
 # Prepare scala-cli
 && cd /root \
 && echo "object Temp extends App" > /root/Temp.scala \
 && cs launch scala-cli -- --power package Temp.scala -o temp \
 && rm /root/temp /root/Temp.scala \
 # Setup stack (Haskell)
 && stack setup --resolver lts-18.14 \
 && stack install --resolver lts-18.14 unordered-containers pretty-show prettyprinter optparse-applicative uniplate protolude recursion-schemes alex happy \
 # Setup Opam
 && opam init -y --disable-sandboxing \
 && opam install -y ocamlbuild menhir ocamlfind core \
 # Setup Rust Cargo
 && cargo install cargo-prefetch \
 && cargo prefetch \
 # Cleanup
 && cd /root \
 && rm -rf /buildsrc \
 && apt-get clean autoclean \
 && apt-get autoremove --yes \
 && rm -rf /var/lib/apt/lists/* \
 # Finalize
 && echo "Done."

ENV OPAM_SWITCH_PREFIX='/root/.opam/default' \
    CAML_LD_LIBRARY_PATH='/root/.opam/default/lib/stublibs:/root/.opam/default/lib/ocaml/stublibs:/root/.opam/default/lib/ocaml' \
    OCAML_TOPLEVEL_PATH='/root/.opam/default/lib/toplevel' \
    MANPATH=':/root/.opam/system/man:/root/.opam/default/man' \
    PATH='/root/.opam/default/bin:/root/.opam/system/bin:/usr/local/cargo/bin:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH'

WORKDIR /id2202
