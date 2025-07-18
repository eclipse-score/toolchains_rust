load("@rules_rust//rust:extensions.bzl", "rust_register_toolchains")

def register_score_rust_toolchains(platforms = None):
    all_versions = {
        "x86_64-linux": "1.83.0",
        "aarch64-linux": "1.83.0",
        # more if needed
    }
    all_urls = {
        "x86_64-linux": "https://static.rust-lang.org/dist/rust-1.83.0-x86_64-unknown-linux-gnu.tar.xz",
        "aarch64-linux": "https://static.rust-lang.org/dist/rust-1.83.0-aarch64-unknown-linux-gnu.tar.xz",
    }
    all_sha256s = {
        "x86_64-linux": "6b373e8b43c870e99393093c38b23fd9f74bf8a1c9e3fd5403e4e91a5a6c8371",
        "aarch64-linux": "b6467a0e8a6c5dca35269785c994e4d80d89754d6c600162cc9146f90c87ee08",
    }

    if platforms == None:
        platforms = all_versions.keys()
    unknown = [p for p in platforms if p not in all_versions]
    if unknown:
        fail("Unknown platform(s): %s" % unknown)

    selected_versions = {p: all_versions[p] for p in platforms}
    selected_urls = {p: all_urls[p] for p in platforms}
    selected_sha256s = {p: all_sha256s[p] for p in platforms}

    rust_register_toolchains(
        edition = "2021",
        versions = selected_versions,
        toolchain_urls = selected_urls,
        sha256s = selected_sha256s,
    )
