# Template for Rust platform configuration in MODULE.bazel.
# Copy the relevant parts into your MODULE.bazel file.
#another way of making this reusable has to be found since  converting it into an extension doesn't seem 
# to be working

RUST_EDITION = "2021"
RUST_VERSION = "1.83.0"
RUST_TARGETS = ["x86_64", "aarch64"]  # Choose: ["x86_64"], ["aarch64"] or both

rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(
    edition = RUST_EDITION,
    versions = [RUST_VERSION],
)

if "x86_64" in RUST_TARGETS:
    rust.repository_set(
        name = "rust_linux_x86_64",
        edition = RUST_EDITION,
        exec_triple = "x86_64-unknown-linux-gnu",
        target_compatible_with = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        target_triple = "x86_64-unknown-linux-gnu",
        versions = [RUST_VERSION],
    )

if "aarch64" in RUST_TARGETS:
    rust.repository_set(
        name = "rust_linux_x86_64",
        target_compatible_with = [
            "@platforms//cpu:arm64",
            "@platforms//os:linux",
        ],
        target_triple = "aarch64-unknown-linux-musl",
    )