# QNX Rust Compiler builder guide

## Introduction

As of end of April 2025 there is no readily available rust compile target for any QNX operating system publicly available.

However, following the rustc book on https://doc.rust-lang.org/rustc/platform-support/nto-qnx.html it's possible to build QNX 7.0 (untested), QNX 7.1 (tested) and QNX 8.0 (tested, but no std support yet) targets.

Since QNX 7.0 is quite old, it is ignored in this guide.

Prerequisites: A QNX SDP (Software Development Plattform) is required to build the compiler target and the linker (qcc) is also always required when you compile a program. For QNX 8.0 there are non-commercial licenses available, however, for QNX 7.1 as of April 2025 not.

To build you need Docker running on a x86_64 or aarch64 system, it is tested on Ubuntu 22.04 LTS, Ubuntu 24.04 LTS on x86_64 and on a Mac M1 (Aarch64). It should also work on regular Linux aarch64, however, not tested yet. In case of non-x86_64 hardware, the rust compiler is built natively on the architecture it runs on, and the linker is then emulated (rosetta or qemu-userland emulation). By doing so, the performance penalty on non-x86_64 systems is minimal.

Once built, you can use the container to build qnx and local targets. Local target is also build so you can execute unit tests or examples. Also cargo and other tools are build.

The entire process takes from a couple of minutes on a threadripper class workstation to about an hour on a first generation Mac Mini M1 with 16gb RAM.

The container is designed to be run in Visual Studio Code as devcontainer. See devcontainer examples in the hello world rust crate suppied in this repo to get you started.

## One baby step at a time

### QNX 7.1

Copy .qnx and qnx710 into this directory and then execute (on aarch64):

```sh
docker build -t qnx-rust-container-qnx710 --build-arg LM_LICENSE_FILE=12345@your.floating.license.server.example --build-arg HOST_ARCH=aarch64 -f Dockerfile_qnx710 .
```

Or on x86_64:
```sh
docker build -t qnx-rust-container-qnx710 --build-arg LM_LICENSE_FILE=12345@your.floating.license.server.example --build-arg HOST_ARCH=x86_64 -f Dockerfile_qnx710.
```

TODO: Arch autodetection would be helpful minimizing errors.

Check `tools/qnx_hello_world` and the devcontainer there to see how to get started quickly with VSCode. Simly launch vscode in that directory after you build the image and you should be able to compile binaries using cargo. Default target is already set in `.cargo/config.toml`.

Note: you may need to source the qnx environment variables before using cargo `. ./qnx710/qnxsdp-env.sh`

TODO: fix this by writing a proper entrypoint that does that already.

### QNX 8.0

Copy .qnx and qnx800 into this directory and then execute (on aarch64):

```sh
docker build -t qnx-rust-container-qnx800-rust-container --build-arg HOST_ARCH=aarch64 -f Dockerfile_qnx710 .
```

Or on x86_64:
```sh
docker build -t qnx-rust-container-qnx800 --build-arg HOST_ARCH=x86_64 -f Dockerfile_qnx710.
```

TODO: Arch autodetection would be helpful minimizing errors.

The resulting compiler is not really useful as std is not yet supported.

### Testing

To run a qemu virtual machine, check:
https://doc.rust-lang.org/rustc/platform-support/nto-qnx.html#testing

It describes how to use mkqnximage to build a virtual disk and launch qemu.

