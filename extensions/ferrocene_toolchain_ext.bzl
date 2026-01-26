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

Optionally, the same repository can include the Ferrocene Rust coverage tools
(`symbol-report` and `blanket`) with wrapper scripts that set `LD_LIBRARY_PATH`
for the embedded `rustc_private` shared libraries.
"""

_BUILD_TMPL = """\\
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

{coverage_tools_block}
"""

_COVERAGE_TOOLS_TMPL = """\\
filegroup(
    name = "symbol-report-bin",
    srcs = ["symbol-report"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "blanket-bin",
    srcs = ["blanket"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "symbol-report-wrapper",
    srcs = ["symbol-report.sh"],
    data = [
        ":symbol-report-bin",
        ":rustc_lib",
    ],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "blanket-wrapper",
    srcs = ["blanket.sh"],
    data = [
        ":blanket-bin",
        ":rustc_lib",
    ],
    visibility = ["//visibility:public"],
)
"""

_WRAPPER_SCRIPT_TMPL = """#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="${script_dir}/__TOOL__"

if [[ ! -x "${bin}" ]]; then
  echo "Missing __TOOL__ binary at ${bin}" >&2
  exit 1
fi

target_triple="__TARGET_TRIPLE__"

lib_dirs=(
  "${script_dir}/lib"
  "${script_dir}/lib/rustlib/${target_triple}/lib"
  "${script_dir}/usr/lib"
  "${script_dir}/usr/lib/rustlib/${target_triple}/lib"
  "${script_dir}/usr/local/lib"
  "${script_dir}/usr/local/lib/rustlib/${target_triple}/lib"
)

ld_paths=()
for dir in "${lib_dirs[@]}"; do
  if [[ -d "${dir}" ]]; then
    ld_paths+=("${dir}")
  fi
done

if [[ ${#ld_paths[@]} -gt 0 ]]; then
  export LD_LIBRARY_PATH="$(IFS=:; echo "${ld_paths[*]}")${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

exec "${bin}" "$@"
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


def _render_build_content(args, coverage_tools_block):
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
        coverage_tools_block = coverage_tools_block,
    )


def _render_wrapper_script(tool, target_triple):
    return _WRAPPER_SCRIPT_TMPL.replace("__TOOL__", tool).replace("__TARGET_TRIPLE__", target_triple)


def _ferrocene_toolchain_repo_impl(ctx):
    ctx.download_and_extract(
        url = ctx.attr.url,
        sha256 = ctx.attr.sha256,
        strip_prefix = ctx.attr.strip_prefix,
    )

    coverage_tools_block = ""
    if ctx.attr.coverage_tools_url:
        if not ctx.attr.coverage_tools_sha256:
            fail("coverage_tools_sha256 must be set when coverage_tools_url is provided")
        ctx.download_and_extract(
            url = ctx.attr.coverage_tools_url,
            sha256 = ctx.attr.coverage_tools_sha256,
            strip_prefix = ctx.attr.coverage_tools_strip_prefix,
        )
        ctx.file(
            "symbol-report.sh",
            _render_wrapper_script("symbol-report", ctx.attr.target_triple),
            executable = True,
        )
        ctx.file(
            "blanket.sh",
            _render_wrapper_script("blanket", ctx.attr.target_triple),
            executable = True,
        )
        coverage_tools_block = _COVERAGE_TOOLS_TMPL

    ctx.file("BUILD.bazel", _render_build_content(ctx.attr, coverage_tools_block))


ferrocene_toolchain_repo = repository_rule(
    implementation = _ferrocene_toolchain_repo_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(default = ""),
        "toolchain_name": attr.string(default = "rust_ferrocene"),
        "target_triple": attr.string(mandatory = True),
        "exec_triple": attr.string(default = "x86_64-unknown-linux-gnu"),
        "staticlib_ext": attr.string(default = ".a"),
        "dylib_ext": attr.string(default = ".so"),
        "binary_ext": attr.string(default = ""),
        "default_edition": attr.string(default = "2021"),
        "stdlib_linkflags": attr.string_list(default = []),
        "extra_rustc_flags": attr.string_list(default = []),
        "extra_exec_rustc_flags": attr.string_list(default = []),
        "env": attr.string_dict(default = {}),
        "exec_compatible_with": attr.string_list(default = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ]),
        "target_compatible_with": attr.string_list(default = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ]),
        "coverage_tools_url": attr.string(default = ""),
        "coverage_tools_sha256": attr.string(default = ""),
        "coverage_tools_strip_prefix": attr.string(default = ""),
    },
)


def _ferrocene_toolchain_ext_impl(ctx):
    for mod in ctx.modules:
        for toolchain in mod.tags.toolchain:
            ferrocene_toolchain_repo(
                name = toolchain.name,
                url = toolchain.url,
                sha256 = toolchain.sha256,
                strip_prefix = toolchain.strip_prefix,
                toolchain_name = toolchain.toolchain_name,
                target_triple = toolchain.target_triple,
                exec_triple = toolchain.exec_triple,
                staticlib_ext = toolchain.staticlib_ext,
                dylib_ext = toolchain.dylib_ext,
                binary_ext = toolchain.binary_ext,
                default_edition = toolchain.default_edition,
                stdlib_linkflags = toolchain.stdlib_linkflags,
                extra_rustc_flags = toolchain.extra_rustc_flags,
                extra_exec_rustc_flags = toolchain.extra_exec_rustc_flags,
                env = toolchain.env,
                exec_compatible_with = toolchain.exec_compatible_with,
                target_compatible_with = toolchain.target_compatible_with,
                coverage_tools_url = toolchain.coverage_tools_url,
                coverage_tools_sha256 = toolchain.coverage_tools_sha256,
                coverage_tools_strip_prefix = toolchain.coverage_tools_strip_prefix,
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
                "coverage_tools_url": attr.string(
                    default = "",
                    doc = "Optional URL of the Ferrocene Rust coverage tools archive.",
                ),
                "coverage_tools_sha256": attr.string(
                    default = "",
                    doc = "SHA256 of the coverage tools archive (hex).",
                ),
                "coverage_tools_strip_prefix": attr.string(
                    default = "",
                    doc = "Optional strip_prefix for the coverage tools archive.",
                ),
            },
        ),
    },
)
