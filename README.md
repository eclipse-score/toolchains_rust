# toolchains_rust

Bazel module that packages prebuilt Ferrocene Rust toolchains and a helper
extension to wrap custom Ferrocene archives.

## What’s inside

- `MODULE.bazel`: pins Ferrocene 1.0.0-pre archives and depends on `score_bazel_platforms`.
- `extensions/ferrocene_toolchain_ext.bzl`: bzlmod extension to wrap arbitrary Ferrocene archives.
- `toolchains/ferrocene/BUILD.bazel`: aliases to the preconfigured toolchains declared in `MODULE.bazel`.

> Note: This module no longer ships platform definitions or the old rust sysroot
> extension. Consumers must provide `rules_rust` themselves.

## Using the preconfigured Ferrocene toolchains (recommended)

```python
bazel_dep(name = "rules_rust", version = "0.56.0")  # or your pinned version
bazel_dep(name = "score_toolchains_rust", version = "0.2.0", dev_dependency = True)

register_toolchains(
    "@score_toolchains_rust//toolchains/ferrocene:all",
    dev_dependency = True,
)
```

## Wrapping your own Ferrocene archives

```python
bazel_dep(name = "rules_rust", version = "0.56.0")
bazel_dep(name = "score_toolchains_rust", version = "0.2.0")

ferrocene = use_extension(
    "@score_toolchains_rust//extensions:ferrocene_toolchain_ext.bzl",
    "ferrocene_toolchain_ext",
)

ferrocene.toolchain(
    name = "ferrocene_x86_64_unknown_linux_gnu",
    url = "https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.0.0-pre/ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz",
    sha256 = "31f71ce24f357afcb04fb4d1bab046ed595455849b4e4dcf60fcca2eab02e0a9",
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

Ferrocene `1.0.0-pre` artifacts:

Base URL:
`https://github.com/eclipse-score/ferrocene_toolchain_builder/releases/download/1.0.0-pre/`

| File | sha256 |
| --- | --- |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-nto-qnx800.tar.gz` | `1333d212ddc7718f9a42ec360e5c1a53d5fdc0984ca32d8ffc11ebb4542a69a2` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-linux-gnu.tar.gz` | `35137bac58f795ea55ab7dd05c3e8534ea6a7f995b475a7798898cd9247e99f0` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-aarch64-unknown-ferrocene.subset.tar.gz` | `e7ade5d375e0f0dfe7715db038a170fa5a4249e46fb7bc445c84b7ea76761e31` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-linux-gnu.tar.gz` | `31f71ce24f357afcb04fb4d1bab046ed595455849b4e4dcf60fcca2eab02e0a9` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-unknown-ferrocene.subset.tar.gz` | `ec6cac9b1d5cfb4569c05c4168cbf5cc61a5e14a8c0bfe39c2c6c2aa9462771e` |
| `ferrocene-779fbed05ae9e9fe2a04137929d99cc9b3d516fd-x86_64-pc-nto-qnx800.tar.gz` | `292be24f2330a134f763ef1f8f820455aeff15ba5b4683553d97f83c98561be8` |

---

© 2025 Contributors to the Eclipse Foundation
