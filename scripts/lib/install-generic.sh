#!/bin/bash
# Install a Liquorix kernel built with build-generic (plain make install).
# Sourced by install.sh — do not execute directly.
#
# This backend is a no-op for the package-install path because build-generic
# already runs make modules_install + make install during the build step.
# It exists so install.sh can source it without error and to provide a clear
# status message.
#
# If BDFS_KO is set (btrfs_dwarfs module was built), it installs the module
# into /lib/modules/<running-kernel>/extra/ and runs depmod.

install_generic() {
    local arch=$1

    log INFO "Generic backend: kernel was installed during build (make install + modules_install)."
    log INFO "No additional package installation step required."

    # Install btrfs_dwarfs module if it was built
    if [[ -n "${BDFS_KO:-}" && -f "${BDFS_KO}" ]]; then
        local kver
        kver=$(uname -r)
        local dest="/lib/modules/${kver}/extra"
        log INFO "Installing btrfs_dwarfs module to ${dest}/"
        install -D -m 644 "${BDFS_KO}" "${dest}/btrfs_dwarfs.ko"
        depmod -a "${kver}"
        log INFO "btrfs_dwarfs module installed and depmod updated"
    fi
}
