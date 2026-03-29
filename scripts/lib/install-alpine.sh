#!/bin/bash
# Alpine Linux handler.
# Sourced by install.sh — do not execute directly.
#
# Alpine uses musl libc. The Liquorix kernel is built against glibc and its
# pre-built packages are not compatible with Alpine's userspace. Building
# the kernel itself from source is possible (the kernel is libc-agnostic),
# but the resulting vmlinuz cannot be packaged as an .apk without a custom
# APKBUILD and Alpine-specific toolchain.
#
# This is tracked as a future work item. See docs/adding-distro.md.

install_alpine() {
    local arch=$1
    log ERROR "Alpine Linux is not yet supported."
    log WARN  "Alpine uses musl libc. Liquorix pre-built packages require glibc."
    log WARN  "A custom APKBUILD is needed to package the kernel for Alpine."
    log WARN  "See docs/adding-distro.md to contribute Alpine support."
    exit 1
}
