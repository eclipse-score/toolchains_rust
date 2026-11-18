#!/usr/bin/env python3
# Copyright (c) 2026 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0

"""Exercise the Python-compatible repository implementation with a mock context.

Bazel integration checks cover Starlark execution and repository cache reuse.
"""

import ast
from pathlib import Path
from types import SimpleNamespace
import unittest


def fail(message):
    raise ValueError(message)


source = Path(__file__).with_name("ferrocene_toolchain_ext.bzl")
module = ast.parse(source.read_text(), filename=str(source))
module.body = [
    node
    for node in module.body
    if isinstance(node, ast.FunctionDef)
    or (
        isinstance(node, ast.Assign)
        and all(
            isinstance(target, ast.Name) and target.id.isupper()
            for target in node.targets
        )
    )
]
namespace = {"fail": fail}
exec(compile(module, str(source), "exec"), namespace)
implementation = namespace["_ferrocene_toolchain_repo_impl"]


class LegacyContext:
    def __init__(self, **attributes):
        defaults = dict(
            url="file:///custom.tar.gz",
            sha256="a" * 64,
            strip_prefix="",
            coverage_tools_url="",
            coverage_tools_sha256="",
            coverage_tools_strip_prefix="",
            miri_sysroot_url="",
            miri_sysroot_sha256="",
            miri_sysroot_strip_prefix="",
            toolchain_name="rust_ferrocene",
            target_triple="x86_64-unknown-linux-gnu",
            exec_triple="x86_64-unknown-linux-gnu",
            staticlib_ext=".a",
            dylib_ext=".so",
            binary_ext="",
            default_edition="2021",
            stdlib_linkflags=[],
            extra_rustc_flags=[],
            extra_exec_rustc_flags=[],
            exec_compatible_with=[],
            target_compatible_with=[],
            env={},
        )
        defaults.update(attributes)
        self.attr = SimpleNamespace(**defaults)
        self.operations = []
        self.files = {}

    def download_and_extract(self, **arguments):
        self.operations.append(("extract", arguments))

    def file(self, path, content, executable=False):
        self.operations.append(("file", path))
        self.files[path] = content

    def path(self, path):
        return SimpleNamespace(exists=True)


class Context(LegacyContext):
    def repo_metadata(self, **arguments):
        self.operations.append(("metadata", arguments))
        return arguments


class ReproducibilityTest(unittest.TestCase):
    def test_checked_archives_declare_reproducibility_after_generation(self):
        for optional in (False, True):
            with self.subTest(optional=optional):
                ctx = Context(
                    coverage_tools_url="file:///coverage.tar.gz" if optional else "",
                    coverage_tools_sha256="b" * 64,
                    miri_sysroot_url="file:///miri.tar.gz" if optional else "",
                    miri_sysroot_sha256="c" * 64,
                )
                self.assertEqual(implementation(ctx), {"reproducible": True})
                self.assertEqual(ctx.operations[-2], ("file", "BUILD.bazel"))
                self.assertEqual(
                    ctx.operations[-1], ("metadata", {"reproducible": True})
                )
                self.assertEqual(
                    sum(op[0] == "extract" for op in ctx.operations),
                    3 if optional else 1,
                )
                if optional:
                    self.assertIn("miri.sh", ctx.files)
                    self.assertIn("symbol-report.sh", ctx.files)

    def test_unchecksummed_custom_archive_still_generates_without_metadata(self):
        ctx = Context(sha256="")
        self.assertIsNone(implementation(ctx))
        self.assertEqual(ctx.operations[0][1]["sha256"], "")
        self.assertEqual(ctx.operations[-1], ("file", "BUILD.bazel"))

    def test_legacy_bazel_context_still_generates(self):
        ctx = LegacyContext()
        self.assertIsNone(implementation(ctx))
        self.assertIn("BUILD.bazel", ctx.files)

    def test_unchecksummed_optional_archives_fail_without_metadata(self):
        for prefix in ("coverage_tools", "miri_sysroot"):
            with self.subTest(prefix=prefix):
                ctx = Context(**{prefix + "_url": "file:///optional.tar.gz"})
                with self.assertRaisesRegex(ValueError, prefix + "_sha256 must be set"):
                    implementation(ctx)
                self.assertFalse(any(op[0] == "metadata" for op in ctx.operations))

    def test_failed_extraction_or_generation_never_declares_reproducibility(self):
        for operation in ("download_and_extract", "file"):
            with self.subTest(operation=operation):
                ctx = Context()

                def failing_operation(*args, **kwargs):
                    raise OSError("repository operation failed")

                setattr(ctx, operation, failing_operation)
                with self.assertRaisesRegex(OSError, "repository operation failed"):
                    implementation(ctx)
                self.assertFalse(any(op[0] == "metadata" for op in ctx.operations))


if __name__ == "__main__":
    unittest.main()
