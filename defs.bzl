# *******************************************************************************
# Copyright (c) 2025 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************
load("@rules_rust//rust:extensions.bzl", "rust")
load("@rules_rust//rust:toolchain:toolchain.bzl", "register_toolchains")
load("@bazel_tools//tools/build_defs/bzlmod:use_repo.bzl", "use_repo")
load("@bazel_tools//tools/build_defs/pkg:alias.bzl", "alias")
load("@bazel_tools//tools/build_defs/genrule:genrule.bzl", "genrule")

# Versions & editions shared across all targets
RUST_EDITION = "2021"
RUST_VERSION = "1.83.0"


def register_score_rust_toolchains():
    # Linux x86_64
    rust_linux = use_extension("@rules_rust//rust:extensions.bzl", "rust")
    rust_linux.toolchain(
        name     = "rust_linux_x86_64",
        edition  = "2021",
        versions = ["1.83.0"],
        sha256s = {
  "rustc-1.83.0-x86_64-unknown-linux-gnu.tar.xz":
    "6ec40e0405c8cbed3b786a97d374c144b012fc831b7c22b535f8ecb524f495ad",
  "cargo-1.83.0-x86_64-unknown-linux-gnu.tar.xz":
    "de834a4062d9cd200f8e0cdca894c0b98afe26f1396d80765df828880a39b98c",
  "clippy-1.83.0-x86_64-unknown-linux-gnu.tar.xz":
    "ef6c05abcfd861ff0bca41d408e126dda195dc966ee35abee57645a12d418f5b",
  "rust-std-1.83.0-x86_64-unknown-linux-gnu.tar.xz":
    "c88fe6cb22f9d2721f26430b6bdd291e562da759e8629e2b4c7eb2c7cad705f2",
  "llvm-tools-1.83.0-x86_64-unknown-linux-gnu.tar.xz":
    "b931673b309c229e234f03271aaa777ea149c3c41f0fb43f3ef13a272540299a",
        },
        exec_triple          = "x86_64-unknown-linux-gnu",
        extra_target_triples = ["aarch64-unknown-linux-gnu"],
    )
    use_repo(rust_linux, "rust_linux_x86_64")

    # Linux aarch64
    #TODO
    rust_linux_aarch = use_extension("@rules_rust//rust:extensions.bzl", "rust")
    rust_linux_aarch.toolchain(
        name     = "rust_linux_aarch64",
        edition  = "2021",
        versions = ["1.83.0"],
        sha256s = {
            "rustc-1.83.0-aarch64-unknown-linux-gnu.tar.xz":     "<SHA256>",
            "cargo-1.83.0-aarch64-unknown-linux-gnu.tar.xz":     "<SHA256>",
            "clippy-1.83.0-aarch64-unknown-linux-gnu.tar.xz":    "<SHA256>",
            "rust-std-1.83.0-aarch64-unknown-linux-gnu.tar.xz":   "<SHA256>",
            "llvm-tools-1.83.0-aarch64-unknown-linux-gnu.tar.xz": "<SHA256>",
        },
        exec_triple          = "aarch64-unknown-linux-gnu",
        extra_target_triples = [],
    )
    use_repo(rust_linux_aarch, "rust_linux_aarch64")

    # QNX aarch64
    rust_qnx = use_extension("@rules_rust//rust:extensions.bzl", "rust")
    rust_qnx.toolchain(
        name     = "rust_qnx_aarch64",
        edition  = "2021",
        versions = ["1.83.0"],
    #TODO        
        sha256s = {
            "rustc-1.83.0-aarch64-nto-qnx8.0.0.tar.xz":     "<SHA256>",
            "cargo-1.83.0-aarch64-nto-qnx8.0.0.tar.xz":     "<SHA256>",
            "clippy-1.83.0-aarch64-nto-qnx8.0.0.tar.xz":    "<SHA256>",
            "rust-std-1.83.0-aarch64-nto-qnx8.0.0.tar.xz":   "<SHA256>",
            "llvm-tools-1.83.0-aarch64-nto-qnx8.0.0.tar.xz": "<SHA256>",
        },
        exec_triple          = "aarch64-nto-qnx8.0.0",
        extra_target_triples = [],
    )
    use_repo(rust_qnx, "rust_qnx_aarch64")

    # Register all toolchains with Bazel
    register_toolchains(
        "@rust_linux_x86_64//:all",
        "@rust_linux_aarch64//:all",
        "@rust_qnx_aarch64//:all",
    )
