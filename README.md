<a href="https://www.xdpxi.dev/neyhost" target="_blank">
  <img src="https://www.xdpxi.dev/imgs/neyhost-banner.png"/>
</a>

Have you ever wanted your own **Minecraft server** but didn't know where to start? NeyHost makes it easy to create a server for a variety of use cases without needing any technical experience. Get started today and use my code `XDPXI` for **30% off your first month**!

[Visit NeyHost](https://www.xdpxi.dev/neyhost)

---

**NOT APPROVED BY OR ASSOCIATED WITH FABRICMC.**

## Description

This mod provides a fake Fabric Loader to satisfy mods that require a specific Fabric Loader version you don’t want to use (or can't).

## Issues

Please keep in mind that mods require specific versions of Fabric Loader for a reason. This mod only spoofs the reported Fabric Loader version and does not actually change or upgrade the underlying loader.

Because of this, a mod may believe that a compatible loader version is installed when it actually isn't. This can lead to unexpected behaviour, crashes, incompatibilities, or other issues.

While I’ll try to fix issues where possible, this mod cannot guarantee compatibility or a completely smooth experience. If a mod depends on features or changes introduced in a newer Fabric Loader version, spoofing the version will not provide those features.


## Example (my use case)

RRLS requires the latest version of Fabric Loader. If you’re using Quilt, updates to Fabric Loader are often delayed, and sometimes never arrive. This is where this mod helps, it pretends that the required Fabric Loader version is present, allowing RRLS to run without issues.

## Choosing a version

Each release corresponds to a specific Fabric Loader version. All versions are functionally identical, only the reported version number differs.
