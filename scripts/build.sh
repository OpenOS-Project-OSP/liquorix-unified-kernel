#!/bin/bash
# Liquorix unified build script.
#
# Builds Liquorix kernel packages for the requested distro format and
# architecture using Docker (except Gentoo, which uses genkernel on-host).
#
# Usage:
#   ./scripts/build.sh [options]
#
# Options:
#   -d, --distro   DISTRO    Target distro: debian|ubuntu|arch|fedora|gentoo
#   -r, --release  RELEASE   Release codename (Debian/Ubuntu only, e.g. trixie)
#   -a, --arch     ARCH      Target arch: x86_64|arm64|riscv64  (default: host arch)
#   -j, --jobs     N         Parallel jobs (default: nproc/2, min 2)
#   -b, --build    N         Build number (default: 1)
#   -h, --help               Show this help
#
# Environment variables:
#   KERNEL_VERSION  Required for Gentoo builds (e.g. 6.12.1)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${REPO_ROOT}/scripts"

# shellcheck source=lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"
# shellcheck source=lib/build-common.sh
source "${SCRIPT_DIR}/lib/build-common.sh"
# shellcheck source=lib/build-deb.sh
source "${SCRIPT_DIR}/lib/build-deb.sh"
# shellcheck source=lib/build-arch.sh
source "${SCRIPT_DIR}/lib/build-arch.sh"
# shellcheck source=lib/build-rpm.sh
source "${SCRIPT_DIR}/lib/build-rpm.sh"
# shellcheck source=lib/build-opensuse.sh
source "${SCRIPT_DIR}/lib/build-opensuse.sh"
# shellcheck source=lib/build-gentoo.sh
source "${SCRIPT_DIR}/lib/build-gentoo.sh"

export REPO_ROOT

# ── Defaults ──────────────────────────────────────────────────────────────────

DISTRO=""
RELEASE=""
ARCH=$(detect_arch)
NPROC=$(nproc 2>/dev/null || echo 4)
PROCS=$(( NPROC / 2 > 2 ? NPROC / 2 : 2 ))
BUILD=1

# ── Argument parsing ──────────────────────────────────────────────────────────

usage() {
    grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--distro)   DISTRO="$2";  shift 2 ;;
        -r|--release)  RELEASE="$2"; shift 2 ;;
        -a|--arch)     ARCH="$2";    shift 2 ;;
        -j|--jobs)     PROCS="$2";   shift 2 ;;
        -b|--build)    BUILD="$2";   shift 2 ;;
        -h|--help)     usage ;;
        *) log ERROR "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$DISTRO" ]]; then
    log ERROR "--distro is required"
    usage
fi

export ARCH

# ── Dispatch ──────────────────────────────────────────────────────────────────

log INFO "Build target  : ${DISTRO}${RELEASE:+/${RELEASE}}"
log INFO "Architecture  : ${ARCH}"
log INFO "Parallel jobs : ${PROCS}"
log INFO "Build number  : ${BUILD}"

case "$DISTRO" in
    debian|ubuntu)
        if [[ -z "$RELEASE" ]]; then
            log ERROR "--release is required for ${DISTRO} builds"
            exit 1
        fi
        build_deb "$DISTRO" "$RELEASE" "$PROCS" "$BUILD"
        ;;
    arch)
        build_arch "$PROCS"
        ;;
    fedora|rhel)
        build_rpm "$PROCS" "$BUILD"
        ;;
    opensuse)
        build_opensuse "$PROCS" "$BUILD"
        ;;
    gentoo)
        build_gentoo "$PROCS"
        ;;
    *)
        log ERROR "Unknown distro: ${DISTRO}"
        log WARN  "Supported: debian, ubuntu, arch, fedora, rhel, opensuse, gentoo"
        exit 1
        ;;
esac
