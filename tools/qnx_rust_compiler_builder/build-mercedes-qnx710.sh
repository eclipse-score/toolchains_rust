#!/bin/sh

docker build -f Dockerfile_qnx710 -t qnx-rust-container-qnx710 --build-arg LM_LICENSE_FILE=27057@qnx-dev.swf.i.mercedes-benz.com --build-arg HOST_ARCH=aarch64 .