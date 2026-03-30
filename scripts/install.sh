#!/bin/bash
# Liquorix unified installer.
#
# Detects the running distro and architecture, then installs the Liquorix
# kernel using the appropriate method for that environment.
#
# Usage:
#   sudo ./scripts/install.sh
#   sudo ENABLE_BDFS=1 ./scripts/install.sh          # also install btrfs_dwarfs module
#
# Environment variables:
#   KERNEL_VERSION  Required on Gentoo (e.g. KERNEL_VERSION=6.12.1)
#   ENABLE_BDFS     Set to 1 to install the btrfs_dwarfs out-of-tree module after
#                   the kernel.  Requires the module to have been built first via
#                   `scripts/build.sh --bdfs` (or ENABLE_BDFS=1 make build-*).
#   BDFS_SRC        Path to the btrfs-dwarfs-framework checkout containing the
#                   built btrfs_dwarfs.ko (default: .bdfs-src/ in repo root)
#
# Supported distros:
#   Debian, Ubuntu and all derivatives (apt-based)
#   Arch Linux and all derivatives (pacman-based)
#   Fedora
#   RHEL, AlmaLinux, Rocky, Oracle, CentOS Stream, Nobara, Bazzite, Ultramarine
#   openSUSE Tumbleweed and Leap
#   Gentoo (source build via genkernel)
#   Alpine (detected but not supported — musl libc incompatibility)
#   Generic (any distro — kernel was installed during build via make install)
#
# Supported arches:
#   x86_64 (pre-built packages)
#   arm64, riscv64 (build from source — configs not yet authored)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENABLE_BDFS="${ENABLE_BDFS:-0}"
BDFS_SRC="${BDFS_SRC:-${REPO_ROOT}/.bdfs-src}"

# shellcheck source=lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=lib/releases.sh
source "${SCRIPT_DIR}/lib/releases.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"
# shellcheck source=lib/install-debian.sh
source "${SCRIPT_DIR}/lib/install-debian.sh"
# shellcheck source=lib/install-ubuntu.sh
source "${SCRIPT_DIR}/lib/install-ubuntu.sh"
# shellcheck source=lib/install-arch.sh
source "${SCRIPT_DIR}/lib/install-arch.sh"
# shellcheck source=lib/install-fedora.sh
source "${SCRIPT_DIR}/lib/install-fedora.sh"
# shellcheck source=lib/install-rhel.sh
source "${SCRIPT_DIR}/lib/install-rhel.sh"
# shellcheck source=lib/install-opensuse.sh
source "${SCRIPT_DIR}/lib/install-opensuse.sh"
# shellcheck source=lib/install-gentoo.sh
source "${SCRIPT_DIR}/lib/install-gentoo.sh"
# shellcheck source=lib/install-alpine.sh
source "${SCRIPT_DIR}/lib/install-alpine.sh"
# shellcheck source=lib/install-generic.sh
source "${SCRIPT_DIR}/lib/install-generic.sh"

# ── Guards ────────────────────────────────────────────────────────────────────

if [[ "$(id -u)" -ne 0 ]]; then
    log ERROR "This script must be run as root."
    exit 1
fi

# ── Detection ─────────────────────────────────────────────────────────────────

ARCH=$(detect_arch) || {
    raw_arch=$(uname -m)
    case "$raw_arch" in
        i386|i486|i586|i686)
            log ERROR "i386/i686 is not supported."
            log WARN  "Liquorix and its upstream Zen patch set target 64-bit kernels only."
            log WARN  "The last Linux kernel with native i386 support was 3.7.10 (2013)."
            log WARN  "If you need a modern kernel on 32-bit x86 hardware, consider:"
            log WARN  "  - gray386linux (kernel 3.7.10 + musl): https://github.com/marmolak/gray386linux"
            log WARN  "  - Debian i386 with a stock kernel (no Liquorix patches)"
            ;;
        *)
            log ERROR "Unsupported architecture: ${raw_arch}"
            ;;
    esac
    exit 1
}

DISTRO=$(detect_distro)

log INFO "Detected distro : ${DISTRO}"
log INFO "Detected arch   : ${ARCH}"

# ── Dispatch ──────────────────────────────────────────────────────────────────

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND='*'

case "$DISTRO" in
    debian)   install_debian   "$ARCH" ;;
    ubuntu)   install_ubuntu   "$ARCH" ;;
    arch)     install_arch     "$ARCH" ;;
    fedora)   install_fedora   "$ARCH" ;;
    rhel)     install_rhel     "$ARCH" ;;
    opensuse) install_opensuse "$ARCH" ;;
    gentoo)   install_gentoo   "$ARCH" ;;
    alpine)   install_alpine   "$ARCH" ;;
    generic)  install_generic  "$ARCH" ;;
    *)
        log ERROR "Unsupported distribution: ${DISTRO}"
        log WARN  "Supported: Debian/Ubuntu family, Arch family, Fedora, RHEL family, openSUSE, Gentoo, generic"
        log WARN  "See docs/adding-distro.md to contribute support for your distro"
        exit 1
        ;;
esac

# ── Optional: install btrfs_dwarfs out-of-tree module ─────────────────────────
if [[ "${ENABLE_BDFS}" == "1" ]]; then
    log INFO "Installing btrfs_dwarfs module"

    local_ko="${BDFS_SRC}/kernel/btrfs_dwarfs/btrfs_dwarfs.ko"
    if [[ ! -f "${local_ko}" ]]; then
        log ERROR "btrfs_dwarfs.ko not found at ${local_ko}"
        log WARN  "Build it first: ENABLE_BDFS=1 make build-<distro>"
        exit 1
    fi

    kernel_version=$(uname -r)
    dest="/lib/modules/${kernel_version}/extra"
    install -D -m 644 "${local_ko}" "${dest}/btrfs_dwarfs.ko"
    depmod -a "${kernel_version}"
    log INFO "btrfs_dwarfs.ko installed to ${dest}/"
    log INFO "Load with: modprobe btrfs_dwarfs"
fi
