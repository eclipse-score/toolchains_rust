# toolchains_rust

Bazel module that packages prebuilt Ferrocene Rust toolchains and a helper
extension to wrap custom Ferrocene archives.

## What’s inside

- `MODULE.bazel`: pins Ferrocene 1.2.0 archives built from the Ubuntu 24.04 Ferrocene image and depends on `score_bazel_platforms`.
- `extensions/ferrocene_toolchain_ext.bzl`: bzlmod extension to wrap arbitrary Ferrocene archives.
- Optional Ferrocene Rust coverage tools (`symbol-report`, `blanket`) when configured.
- Optional Miri toolchains backed by prebuilt Miri sysroot archives.
- `toolchains/ferrocene/BUILD.bazel`: aliases to the preconfigured toolchains declared in `MODULE.bazel`.

> Note: This module no longer ships platform definitions or the old rust sysroot
> extension. Consumers must provide `rules_rust` themselves.

## Using the preconfigured Ferrocene toolchains (recommended)

```python
bazel_dep(name = "rules_rust", version = "0.56.0")  # or your pinned version
bazel_dep(name = "score_toolchains_rust", version = "0.3.0", dev_dependency = True)

register_toolchains(
    "@score_toolchains_rust//toolchains/ferrocene:all",
    dev_dependency = True,
)
```

Preconfigured toolchains:
- `ferrocene_x86_64_unknown_linux_gnu`
- `ferrocene_aarch64_unknown_linux_gnu`
- `ferrocene_x86_64_pc_nto_qnx800`
- `ferrocene_aarch64_unknown_nto_qnx800`

Preconfigured Miri toolchains:
- `ferrocene_x86_64_unknown_linux_gnu_miri`
- `ferrocene_aarch64_unknown_linux_gnu_miri`
- `ferrocene_x86_64_pc_nto_qnx800_miri`
- `ferrocene_aarch64_unknown_nto_qnx800_miri`

Coverage tools are available from the generated repositories (wrappers set `LD_LIBRARY_PATH` automatically):

```
bazel run @score_toolchains_rust//toolchains/ferrocene:ferrocene_x86_64_unknown_linux_gnu_symbol-report -- --help
bazel run @score_toolchains_rust//toolchains/ferrocene:ferrocene_x86_64_unknown_linux_gnu_blanket -- --help
```

## Wrapping your own Ferrocene archives

```python
bazel_dep(name = "rules_rust", version = "0.56.0")
bazel_dep(name = "score_toolchains_rust", version = "0.5.0")

ferrocene = use_extension(
    "@score_toolchains_rust//extensions:ferrocene_toolchain_ext.bzl",
    "ferrocene_toolchain_ext",
)

ferrocene.toolchain(
    name = "ferrocene_x86_64_unknown_linux_gnu",
    url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.2.0/ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    sha256 = "4082058e4d054b1e26261e7ec99f01bf807f87b4ea580d246e48d9ccd487a591",
    coverage_tools_url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.2.0/coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    coverage_tools_sha256 = "5a136b0b654625b794aec9e189ab1be92a23c0a56eb6fc16984b629fee034cab",
    miri_sysroot_url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.2.0/miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    miri_sysroot_sha256 = "8b745cc64fe4d9d27081196cc565ea3cd198b24fce0ef7e2f014a11d85629745",
    miri_sysroot_strip_prefix = "x86_64-unknown-linux-gnu",
    target_triple = "x86_64-unknown-linux-gnu",
    exec_triple = "x86_64-unknown-linux-gnu",
)

use_repo(ferrocene, "ferrocene_x86_64_unknown_linux_gnu")
register_toolchains("@ferrocene_x86_64_unknown_linux_gnu//:rust_ferrocene_toolchain")
```

`miri_sysroot_url` is the supported path for Miri integration. The generated repo
expects a prebuilt Miri sysroot archive and does not build one at repository
rule time. Generate and publish the sysroot alongside the Ferrocene release
artifacts in `ferrocene_builder`, then point `miri_sysroot_url` at that asset.

Add more `ferrocene.toolchain(...)` entries for other archives such as
`aarch64-unknown-linux-gnu`, `aarch64-unknown-nto-qnx800`, or
`x86_64-pc-nto-qnx800`.

Ferrocene `1.2.0` artifacts:

Base URL:
`https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.2.0/`

| File | sha256 |
| --- | --- |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `d5ccceb0e3118a5e6bfdf1a3f894054db3c2cd346f927b39a57a69faf688849d` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `3fd5fe5da4836eb6d554731e7899d378a6992106ce6275b136279dec29598383` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `4082058e4d054b1e26261e7ec99f01bf807f87b4ea580d246e48d9ccd487a591` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `3fede22a89d7431668d4bc2810147a957d2b334ee8cb7097ad9c56b546f805cc` |
| `coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `5a136b0b654625b794aec9e189ab1be92a23c0a56eb6fc16984b629fee034cab` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `8b745cc64fe4d9d27081196cc565ea3cd198b24fce0ef7e2f014a11d85629745` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `74f90eabcb34809e44300535016f25eb0cf4a500763c0d18e7f587583b5b9908` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `ac434b7dc3cc3d67d31f73513a027aea50cca355c189c3a3f8c3162b1fccbca0` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `8fc8f406c33a7dc31362133b8a2ffbb66b44f62354bfc98a3bc21a1fcbc9a7e6` |

---

© 2025 Contributors to the Eclipse Foundation
