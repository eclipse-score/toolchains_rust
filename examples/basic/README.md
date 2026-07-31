# Basic example

Minimal Rust targets demonstrating Ferrocene toolchain usage and serving as
CI smoke tests (`.github/workflows/examples.yml`):

```bash
bazel build    --config=smoke //examples/basic/...
bazel test     --config=smoke //examples/basic/...
bazel coverage --config=smoke //examples/basic:basic_test
```

The `smoke` config (see `.bazelrc`) registers the Ferrocene toolchain via
`--extra_toolchains`, exactly the way downstream repositories consume it.
The coverage run additionally smoke-tests the LLVM coverage wiring: the
toolchain's `llvm_cov`/`llvm_profdata` (from the coverage-tools archive)
make `rules_rust` instrument the test, and CI asserts that the resulting
LCOV data contains executed lines of `src/lib.rs`.
