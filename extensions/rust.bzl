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
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@score_toolchains_rust//rules:rust.bzl", "rust_toolchain")


# in here we define an extension which is how users tell Bazel about the new
# Rust toolchains they want to use
def _rust_impl(mctx):
    for mod in mctx.modules:
        for tag in mod.tags.toolchain:
            tc = tag
            http_archive(
                name = "%s_rust" % tc.name,
                urls = [tc.url],
                build_file = "@score_toolchains_rust//toolchain/third_party:rust.BUILD",
                sha256 = tc.sha256,
                strip_prefix = tc.strip_prefix,
            )
            rust_toolchain(
                name = tc.name,
                rust_repo = "%s_rust" % tc.name,
                version = tc.version,
                target_triple = tc.target_triple,
                platform = tc.platform,
            )

rust = module_extension(
    implementation = _rust_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "name": attr.string(default = "rust_toolchain"),
                "version": attr.string(),
                "url": attr.string(),
                "strip_prefix": attr.string(default = ""),
                "sha256": attr.string(),
                "target_triple": attr.string(),
                "platform": attr.string(), # e.g. "@score_toolchains_rust//platforms:x86_64-linux"
            },
        ),
    }
)
