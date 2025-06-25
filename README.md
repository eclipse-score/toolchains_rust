# toolchains_rust

This repository provides Bazel toolchain definitions for building Rust projects using [rules_rust](https://github.com/bazelbuild/rules_rust). It includes support for multiple platforms and integrates with Clippy and Rustfmt for linting and formatting.

## Features

- **Multi-platform Rust toolchains**: Predefined toolchains for Linux (x86_64, aarch64) and QNX (aarch64).
- **Bazel integration**: Easily register and use Rust toolchains in your Bazel projects.
- **Clippy and Rustfmt support**: Lint and format your Rust code using Bazel output groups.
- **Customizable versions**: Easily update Rust versions and SHA256 checksums.

## Repository Structure

- [`defs.bzl`](defs.bzl): Bazel Starlark file defining and registering Rust toolchains.
- [`MODULE.bazel`](MODULE.bazel): Bazel module file declaring dependencies (e.g., rules_rust).
- [`defaults.bazelrc`](defaults.bazelrc): Bazel configuration for Clippy, Rustfmt, and coverage.
- [`clippy.toml`](clippy.toml): Clippy lint configuration.
- [`rustfmt.toml`](rustfmt.toml): Rustfmt formatting configuration.

## Usage

1. **Add as a Bazel module dependency**  
   In your `MODULE.bazel`:
   ```python
   bazel_dep(name = "toolchains_rust", version = "1.0.0")
   ```

2. **Register toolchains in your `WORKSPACE` or `.bzl` file**  
   ```python
   load("@toolchains_rust//:defs.bzl", "register_score_rust_toolchains")
   register_score_rust_toolchains()
   ```

3. **Configure Bazel**  
   Import settings from [`defaults.bazelrc`](defaults.bazelrc) for Clippy, Rustfmt, and coverage.

## Linting and Formatting

- **Clippy**: Run `bazel build //...` to see lint warnings/errors.
- **Rustfmt**: Run `bazel build //...` to check formatting.


