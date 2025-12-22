################################################################################
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
################################################################################
"""Bzlmod extension for wiring Ferrocene Rust toolchain archives.

This extension wraps a prebuilt Ferrocene archive (e.g. produced by
`ferrocene_toolchain_builder`) and generates a repository containing:
- Filegroups for `rustc`, `cargo`, `rustdoc`, `clippy-driver`, and libs.
- A `rust_toolchain` + `toolchain` definition for `rules_rust`.

The produced repository is self-contained and can be registered via
`register_toolchains("@<repo>//:<toolchain_name>_toolchain")`.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_BUILD_TMPL = """\
load("@rules_rust//rust:toolchain.bzl", "rust_stdlib_filegroup", "rust_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "rustc",
    srcs = glob(
        [
            "bin/rustc",
            "usr/bin/rustc",
            "usr/local/bin/rustc",
        ],
        allow_empty = True,
    ),
)

filegroup(
    name = "cargo",
    srcs = glob(
        [
            "bin/cargo",
            "usr/bin/cargo",
            "usr/local/bin/cargo",
        ],
        allow_empty = True,
    ),
)

filegroup(
    name = "rustdoc",
    srcs = glob(
        [
            "bin/rustdoc",
            "usr/bin/rustdoc",
            "usr/local/bin/rustdoc",
        ],
        allow_empty = True,
    ),
)

filegroup(
    name = "clippy_driver",
    srcs = glob(
        [
            "bin/clippy-driver",
            "usr/bin/clippy-driver",
            "usr/local/bin/clippy-driver",
        ],
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-{target_triple}",
    srcs = glob(
        [
            "lib/rustlib/{target_triple}/**",
            "usr/lib/rustlib/{target_triple}/**",
            "usr/local/lib/rustlib/{target_triple}/**",
        ],
        allow_empty = True,
    ),
)

filegroup(
    name = "rustc_lib",
    srcs = glob(
        [
            "lib/**",
            "usr/lib/**",
            "usr/local/lib/**",
        ],
        allow_empty = True,
    ),
)

rust_toolchain(
    name = "{toolchain_name}",
    rustc = ":rustc",
    cargo = ":cargo",
    rust_doc = ":rustdoc",
    clippy_driver = ":clippy_driver",
    rust_std = ":rust_std-{target_triple}",
    rustc_lib = ":rustc_lib",
    target_triple = "{target_triple}",
    exec_triple = "{exec_triple}",
    staticlib_ext = "{staticlib_ext}",
    dylib_ext = "{dylib_ext}",
    binary_ext = "{binary_ext}",
    default_edition = "{default_edition}",
    stdlib_linkflags = {stdlib_linkflags},
    extra_rustc_flags = {extra_rustc_flags},
    extra_exec_rustc_flags = {extra_exec_rustc_flags},
    env = {env},
    tags = ["manual"],
)

toolchain(
    name = "{toolchain_name}_toolchain",
    toolchain_type = "@rules_rust//rust:toolchain_type",
    toolchain = ":{toolchain_name}",
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = {target_compatible_with},
)
"""

def _fmt_list(values):
    """Render a string list for embedding into Starlark text."""
    if not values:
        return "[]"
    return "[\n        " + ",\n        ".join(['"%s"' % v for v in values]) + "\n    ]"

def _fmt_dict(values):
    """Render a string->string dict for embedding into Starlark text."""
    if not values:
        return "{}"

    # Keep output stable for reproducibility.
    items = []
    for key in sorted(values.keys()):
        items.append('"%s": "%s"' % (key, values[key]))
    return "{\n        " + ",\n        ".join(items) + "\n    }"

def _render_build_content(args):
    return _BUILD_TMPL.format(
        toolchain_name = args.toolchain_name,
        target_triple = args.target_triple,
        exec_triple = args.exec_triple,
        staticlib_ext = args.staticlib_ext,
        dylib_ext = args.dylib_ext,
        binary_ext = args.binary_ext,
        default_edition = args.default_edition,
        stdlib_linkflags = _fmt_list(args.stdlib_linkflags),
        extra_rustc_flags = _fmt_list(args.extra_rustc_flags),
        extra_exec_rustc_flags = _fmt_list(args.extra_exec_rustc_flags),
        exec_compatible_with = _fmt_list(args.exec_compatible_with),
        target_compatible_with = _fmt_list(args.target_compatible_with),
        env = _fmt_dict(args.env),
    )

def _ferrocene_toolchain_ext_impl(ctx):
    for mod in ctx.modules:
        for toolchain in mod.tags.toolchain:
            http_archive(
                name = toolchain.name,
                urls = [toolchain.url],
                sha256 = toolchain.sha256,
                strip_prefix = toolchain.strip_prefix,
                build_file_content = _render_build_content(toolchain),
            )

ferrocene_toolchain_ext = module_extension(
    implementation = _ferrocene_toolchain_ext_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "Repository name that will host the Ferrocene archive and toolchain definition.",
                ),
                "url": attr.string(
                    mandatory = True,
                    doc = "URL of the Ferrocene toolchain archive.",
                ),
                "sha256": attr.string(
                    mandatory = True,
                    doc = "SHA256 of the archive (hex).",
                ),
                "strip_prefix": attr.string(
                    default = "",
                    doc = "Optional strip_prefix for the archive.",
                ),
                "toolchain_name": attr.string(
                    default = "rust_ferrocene",
                    doc = "Name for the rust_toolchain target inside the generated repo.",
                ),
                "target_triple": attr.string(
                    mandatory = True,
                    doc = "Rust target triple for the toolchain outputs.",
                ),
                "exec_triple": attr.string(
                    default = "x86_64-unknown-linux-gnu",
                    doc = "Execution triple (host) for rustc.",
                ),
                "staticlib_ext": attr.string(default = ".a"),
                "dylib_ext": attr.string(default = ".so"),
                "binary_ext": attr.string(default = ""),
                "default_edition": attr.string(default = "2021"),
                "stdlib_linkflags": attr.string_list(default = []),
                "extra_rustc_flags": attr.string_list(default = []),
                "extra_exec_rustc_flags": attr.string_list(default = []),
                "env": attr.string_dict(
                    default = {},
                    doc = "Environment variables passed to the rust toolchain actions.",
                ),
                "exec_compatible_with": attr.string_list(
                    default = [
                        "@platforms//cpu:x86_64",
                        "@platforms//os:linux",
                    ],
                    doc = "Compatibility constraints for the execution platform.",
                ),
                "target_compatible_with": attr.string_list(
                    default = [
                        "@platforms//cpu:x86_64",
                        "@platforms//os:linux",
                    ],
                    doc = "Compatibility constraints for the target platform.",
                ),
            },
        ),
    },
)
