#!/bin/sh

docker build -f Dockerfile_qnx800 -t qnx-rust-container-qnx800 --build-arg HOST_ARCH=aarch64 .