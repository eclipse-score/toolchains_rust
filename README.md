# toolchains_rust

Reusable Bazel module for Rust toolchains, platform definitions, and sysroot management.  
Supports cross-compilation for Linux (x86_64, aarch64) and QNX (aarch64) targets (not ready )

## Features

- Bazel platforms for Linux and QNX
- Rust toolchain definitions for cross-compilation
- Extension for sysroot management
- Integration with `rules_rust` and `toolchains_llvm`

## Repository Structure

- `platforms/` — Bazel platform definitions (Linux, QNX)
- `toolchains/` — Rust toolchain definitions for each platform
- `extensions/` — Starlark extensions for sysroot/toolchain registration
- `MODULE.bazel` — Bazel module metadata

## How to Use in Consumer Repositories

Add this module and configure extensions in your `MODULE.bazel`:

```python
bazel_dep(name = "score_toolchains_rust", version = "0.1")

# Bring in the extension
rust_ext = use_extension("@score_toolchains_rust//extensions:rust_toolchain_ext.bzl", "rust_toolchain_ext")

# Tell it which sysroots to download:
rust_ext.sysroot(
    name = "sysroot_linux_x64",
    url = "https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/4f611ec025be98214164d4bf9fbe8843f58533f7/debian_bullseye_amd64_sysroot.tar.xz",
    sha256 = "5df5be9357b425cdd70d92d4697d07e7d55d7a923f037c22dc80a78e85842d2c",
    strip_prefix = "",
    build_file = "@score_toolchains_rust//sysroot:BUILD.bazel",
)
rust_ext.sysroot(
    name = "sysroot_linux_aarch64",
    url = "https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/906cc7c6bf47d4bd969a3221fc0602c6b3153caa/debian_bullseye_arm64_sysroot.tar.xz",
    sha256 = "d303cf3faf7804c9dd24c9b6b167d0345d41d7fe4bfb7d34add3ab342f6a236c",
    strip_prefix = "",
    build_file = "@score_toolchains_rust//sysroot:BUILD.bazel",
)

use_repo(rust_ext, "sysroot_linux_x64")
use_repo(rust_ext, "sysroot_linux_aarch64")

# User must also configure rules_rust and toolchains_llvm extensions directly:
bazel_dep(name = "rules_rust", version = "0.61.0")
bazel_dep(name = "toolchains_llvm", version = "1.2.0")

llvm = use_extension("@toolchains_llvm//toolchain/extensions:llvm.bzl", "llvm")
llvm.toolchain(
    name = "llvm_toolchain",
    llvm_versions = { "": "19.1.0" },
    stdlib = { "linux-x86_64": "stdc++", "linux-aarch64": "stdc++" },
)
llvm.sysroot(name="llvm_toolchain", label="@sysroot_linux_x64//:sysroot", targets=["linux-x86_64"])
llvm.sysroot(name="llvm_toolchain", label="@sysroot_linux_aarch64//:sysroot", targets=["linux-aarch64"])
use_repo(llvm, "llvm_toolchain")

rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(
    edition = "2021",
    extra_target_triples = ["x86_64-unknown-linux-gnu", "aarch64-unknown-linux-gnu"],
    versions = ["1.83.0"],
)
use_repo(rust, "rust_toolchains")
register_toolchains("@rust_toolchains//:all")
register_toolchains("@llvm_toolchain//:all")
```

## Example: Cross-Compiling from a Consumer Repository

To build a Rust binary for a specific platform (e.g., aarch64-unknown-linux-gnu), use:

```sh
bazel build //src/rust/rust_kvs_tool:kvs_tool --platforms=@score_toolchains_rust//platforms:aarch64-unknown-linux-gnu
```

Replace the target with your own Bazel target as needed.


---

© 2025 Contributors to the Eclipse Foundation
