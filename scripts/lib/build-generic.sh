#!/bin/bash
# Build Liquorix directly on the host using plain make install.
# No packaging, no Docker — works on any distro.
# Sourced by build.sh — do not execute directly.
#
# Requires: gcc, make, bc, flex, bison, libssl-dev, libelf-dev
# Globals used: KERNEL_VERSION, ARCH, MLEVEL, PROCS, REPO_ROOT
#
# After a successful build the kernel, modules, and headers are installed
# via the standard make targets:
#   make modules_install
#   make install          (copies vmlinuz + System.map, runs installkernel)
#
# The caller is responsible for running update-grub / grub-mkconfig /
# dracut / mkinitcpio as appropriate for the host distro.

build_generic() {
    local procs=$1

    if [[ -z "${KERNEL_VERSION:-}" ]]; then
        log ERROR "KERNEL_VERSION must be set (e.g. KERNEL_VERSION=6.12.1 make build-generic)"
        exit 1
    fi

    local kernel_major="${KERNEL_VERSION%.*}"

    # Resolve LQX release tag from upstream.sh helpers
    # shellcheck source=upstream.sh
    source "${REPO_ROOT}/scripts/lib/upstream.sh"
    local lqx_rel
    lqx_rel=$(get_lqx_release "$kernel_major")

    export KERNEL_MAJOR="$kernel_major"
    export LQX_REL="$lqx_rel"
    export SRCDIR="${REPO_ROOT}/build/generic"

    log INFO "Kernel : ${KERNEL_VERSION} (Liquorix ${kernel_major}-${lqx_rel})"
    log INFO "Arch   : ${ARCH}"
    [[ "$ARCH" == "x86_64" && -n "${MLEVEL:-}" ]] && log INFO "Mlevel : x86-64-${MLEVEL}"
    log INFO "Jobs   : ${procs}"
    log INFO "SRCDIR : ${SRCDIR}"

    fetch_sources
    apply_patches
    select_config

    local kernel_dir="${SRCDIR}/linux-${kernel_major}"

    log INFO "Building kernel (jobs=${procs})"
    make -C "$kernel_dir" -j"$procs" ARCH="$ARCH"

    log INFO "Installing modules"
    make -C "$kernel_dir" -j"$procs" ARCH="$ARCH" modules_install

    log INFO "Installing kernel"
    make -C "$kernel_dir" ARCH="$ARCH" install

    log INFO "Generic build complete — kernel installed to /boot"
    log WARN "Run your bootloader update command (e.g. update-grub, grub-mkconfig, grub2-mkconfig)"
    log WARN "and regenerate your initramfs (e.g. update-initramfs, dracut, mkinitcpio) before rebooting."
}
