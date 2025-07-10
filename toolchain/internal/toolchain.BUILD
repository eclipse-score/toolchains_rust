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

# this is a template for the BUILD file that gets created
# for every new toolchain that gets registered
load("@rules_rust//rust:defs.bzl", "rust_toolchain")


filegroup(
    name = "rustc_bin",
    srcs = ["@%{rust_repo}//:rustc"],
)

filegroup(
    name = "cargo_bin",
    srcs = ["@%{rust_repo}//:cargo"],
)

rust_toolchain(
    name = "rust_toolchain",
    rustc = ":rustc_bin",
    cargo = ":cargo_bin",
    target_triple = "%{target_triple}",
    version = "%{version}",
    # More attributes as needed!
)

# this rule ties everything together and sets which
# platform this toolchain is for
toolchain(
    name = "%{tc_name}",
    toolchain = ":rust_toolchain",
    toolchain_type = "@rules_rust//rust:toolchain_type",
    exec_compatible_with = ["%{platform}"],
    target_compatible_with = ["%{platform}"],
    visibility = ["//visibility:public"],
)
