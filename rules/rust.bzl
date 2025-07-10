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

# wraps the rust_toolchain that registers filegroups for binaries
# it turs the Rust tarball into a usable Bazel toolchain
def _impl(rctx):
    rctx.template(
        "BUILD",
        rctx.attr._toolchain_build,
        {
            "%{rust_repo}": rctx.attr.rust_repo,
            "%{tc_name}": rctx.attr.name,
            "%{version}": rctx.attr.version,
            "%{target_triple}": rctx.attr.target_triple,
            "%{platform}": rctx.attr.platform,
        },
    )

rust_toolchain = repository_rule(
    implementation = _impl,
    attrs = {
        "rust_repo": attr.string(doc="The repository name of the unpacked rust toolchain."),
        "version": attr.string(),
        "target_triple": attr.string(),
        "platform": attr.string(),
        "_toolchain_build": attr.label(
            default = "@score_toolchains_rust//toolchain/internal:toolchain.BUILD",
            doc = "Path to the toolchain BUILD template.",
        ),
    },
)
