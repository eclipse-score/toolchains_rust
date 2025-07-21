load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _rust_toolchain_ext_impl(ctx):
    # Gather all sysroot tags from all modules
    for mod in ctx.modules:
        for sysroot in mod.tags.sysroot:
            # Download sysroot archive
            http_archive(
                name = sysroot.name,
                urls = [sysroot.url],
                sha256 = sysroot.sha256,
                strip_prefix = sysroot.strip_prefix,
                build_file = sysroot.build_file,  # Label to BUILD.bazel for sysroot
            )
    # (Optional) You could add more repo_rules for toolchain wrappers here

rust_toolchain_ext = module_extension(
    implementation = _rust_toolchain_ext_impl,
    tag_classes = {
        "sysroot": tag_class(
            attrs = {
                "name": attr.string(mandatory=True, doc="Repo name, e.g. sysroot_linux_x64"),
                "url": attr.string(mandatory=True),
                "sha256": attr.string(mandatory=True),
                "strip_prefix": attr.string(default=""),
                "build_file": attr.label(mandatory=True, doc="Label to BUILD.bazel for sysroot"),
            }
        ),
    },
)
