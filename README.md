# toolchains_rust

Bazel module that packages prebuilt Ferrocene Rust toolchains and a helper
extension to wrap custom Ferrocene archives.

## What’s inside

- `MODULE.bazel`: pins Ferrocene 1.0.1 archives and depends on `score_bazel_platforms`.
- `extensions/ferrocene_toolchain_ext.bzl`: bzlmod extension to wrap arbitrary Ferrocene archives.
- Optional Ferrocene Rust coverage tools (`symbol-report`, `blanket`) when configured.
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

Coverage tools are available from the generated repositories (wrappers set `LD_LIBRARY_PATH` automatically):

```
bazel run @score_toolchains_rust//toolchains/ferrocene:ferrocene_x86_64_unknown_linux_gnu_symbol-report -- --help
bazel run @score_toolchains_rust//toolchains/ferrocene:ferrocene_x86_64_unknown_linux_gnu_blanket -- --help
```

## Wrapping your own Ferrocene archives

```python
bazel_dep(name = "rules_rust", version = "0.56.0")
bazel_dep(name = "score_toolchains_rust", version = "0.3.0")

ferrocene = use_extension(
    "@score_toolchains_rust//extensions:ferrocene_toolchain_ext.bzl",
    "ferrocene_toolchain_ext",
)

ferrocene.toolchain(
    name = "ferrocene_x86_64_unknown_linux_gnu",
    url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.0.1/ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    sha256 = "4c08b41eaafd39cff66333ca4d4646a5331c780050b8b9a8447353fcd301dddc",
    coverage_tools_url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.0.1/coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    coverage_tools_sha256 = "06298b2f809a99c4a649c24763add29243e33865e8561683dd8f52724c4b9e18",
    target_triple = "x86_64-unknown-linux-gnu",
    exec_triple = "x86_64-unknown-linux-gnu",
)

use_repo(ferrocene, "ferrocene_x86_64_unknown_linux_gnu")
register_toolchains("@ferrocene_x86_64_unknown_linux_gnu//:rust_ferrocene_toolchain")
```

Add more `ferrocene.toolchain(...)` entries for other archives such as
`aarch64-unknown-linux-gnu`, `aarch64-unknown-nto-qnx800`, or
`x86_64-pc-nto-qnx800`. For QNX targets, pass the needed environment variables
(`QNX_HOST`, `QNX_TARGET`, `PATH`, etc.) to match your SDK layout.

Ferrocene `1.0.1` artifacts:

Base URL:
`https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.0.1/`

| File | sha256 |
| --- | --- |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `563a2438324ee1c6fdcfd13fbe352bedf1cf3f0756d07bb7ba7bdca334df92bf` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `b1f1eb1146bf595fe1f4a65d5793b7039b37d2cb6d395d1c3100fa7d0377b6c9` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-ferrocene.subset.tar.gz` | `ddbdb8e47f56bbd8b4ddad02e4ec58c270242e9ecd43a9efb44a1099bc5afd58` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `4c08b41eaafd39cff66333ca4d4646a5331c780050b8b9a8447353fcd301dddc` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-ferrocene.subset.tar.gz` | `e4dbaab02bfdf2f0f3b008ce14d7770c54bc3cea69fd3bb45778b4a3d36d0fa0` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `6daabbe20c0b06551335f83c2490326ce447759628dea04cd1c90d297c3a0bd3` |
| `coverage-tools-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `06298b2f809a99c4a649c24763add29243e33865e8561683dd8f52724c4b9e18` |

---

© 2025 Contributors to the Eclipse Foundation
