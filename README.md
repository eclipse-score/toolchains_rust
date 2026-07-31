# toolchains_rust

Bazel module that packages prebuilt Ferrocene Rust toolchains and a helper
extension to wrap custom Ferrocene archives.

## What’s inside

- `MODULE.bazel`: pins Ferrocene 1.3.1 archives built from the Ubuntu 24.04 Ferrocene image and depends on `score_bazel_platforms`.
- `extensions/ferrocene_toolchain_ext.bzl`: bzlmod extension to wrap arbitrary Ferrocene archives.
- Optional Ferrocene Rust coverage tools (`symbol-report`, `blanket`) when configured.
- Optional Miri toolchain support backed by prebuilt Miri sysroot archives.
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

Preconfigured Miri toolchain aliases:
- `ferrocene_x86_64_unknown_linux_gnu_miri`
- `ferrocene_aarch64_unknown_linux_gnu_miri`
- `ferrocene_x86_64_pc_nto_qnx800_miri`
- `ferrocene_aarch64_unknown_nto_qnx800_miri`

Preconfigured direct-Miri artifact aliases:
- `*_miri_driver`
- `*_miri_sysroot_files`
- `*_miri_runtime_files`

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
    url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.3.1/ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    sha256 = "6fd7c7053a80463b2bfd24202de02e16959b18ed185c55b738148e9caac42eff",
    coverage_tools_url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.3.1/coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    coverage_tools_sha256 = "9cf5d76b2e505bf2a8b2b47c60f191ac1273f87851ed387e53080b8e5d14dedf",
    miri_sysroot_url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.3.1/miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    miri_sysroot_sha256 = "143260fe3873249160d57b370717005828e129d3b6782448a32d8cc578384fe0",
    miri_sysroot_strip_prefix = "x86_64-unknown-linux-gnu",
    target_triple = "x86_64-unknown-linux-gnu",
    exec_triple = "x86_64-unknown-linux-gnu",
)

use_repo(ferrocene, "ferrocene_x86_64_unknown_linux_gnu")
register_toolchains("@ferrocene_x86_64_unknown_linux_gnu//:rust_ferrocene_toolchain")
```

`miri_sysroot_url` is the supported path for Miri integration. The generated repo
expects a prebuilt Miri sysroot archive and does not build one at repository
rule time. For the built-in Ferrocene toolchains, `score_toolchains_rust`
re-exports a `rules_rust` Miri toolchain through the same simple public aliases:

```bazelrc
build:x86_64-linux --extra_toolchains=@score_toolchains_rust//toolchains/ferrocene:ferrocene_x86_64_unknown_linux_gnu_miri
```

The base Ferrocene repos remain backward compatible because they only expose the
direct `miri` wrapper and its artifacts. The `rules_rust` Miri toolchain is
created in separate companion repositories and is only loaded when a `*_miri`
alias is actually used. This keeps repositories that do not use Miri working
with older `rules_rust` versions.

For custom Ferrocene archives, you can still opt in explicitly to the companion
`rules_rust` Miri toolchain via `ferrocene_rules_rust_miri_toolchain_ext`.

Add more `ferrocene.toolchain(...)` entries for other archives such as
`aarch64-unknown-linux-gnu`, `aarch64-unknown-nto-qnx800`, or
`x86_64-pc-nto-qnx800`.

Ferrocene `1.3.1` artifacts:

Base URL:
`https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.3.1/`

| File | sha256 |
| --- | --- |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `a8e80da21c6abebfb31063f3815cd3a4bbb5a1466855a12043d7c243ef152715` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `06ee88a935083068325b69028e9d4e9adc696542cea9b4322642a55dafcae552` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `6fd7c7053a80463b2bfd24202de02e16959b18ed185c55b738148e9caac42eff` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `655ad0d212baf63f4dd03065735ca55cddadc86cf6bd005aeb19689e348a0023` |
| `coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `9cf5d76b2e505bf2a8b2b47c60f191ac1273f87851ed387e53080b8e5d14dedf` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `143260fe3873249160d57b370717005828e129d3b6782448a32d8cc578384fe0` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `4059e74c79147b942eb595c14a5f998ebdb1063764ea756b4f32c21bf5903a16` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `9684ea089c883a0739f402165fc6aa374a69641e763957c314688779e8124931` |
| `miri-sysroot-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `3077170b7384d6bcf2cf8f53db8b670d48fc7e2237285b4fd799c64e7412bdff` |

---

© 2025 Contributors to the Eclipse Foundation
