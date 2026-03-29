#!/bin/bash
# Live build pipeline test.
#
# Validates the full build pipeline end-to-end for a given distro and release
# by running bootstrap + build and checking that output packages are produced.
#
# Usage:
#   ./scripts/test-build.sh [options]
#
# Options:
#   -d, --distro   DISTRO    Target distro (default: debian)
#   -r, --release  RELEASE   Release codename (default: bookworm)
#   -a, --arch     ARCH      Target arch (default: x86_64)
#   -j, --jobs     N         Parallel jobs (default: 2)
#   -s, --skip-bootstrap     Skip bootstrap if images already exist
#   -h, --help               Show this help
#
# Examples:
#   ./scripts/test-build.sh
#   ./scripts/test-build.sh -d ubuntu -r noble
#   ./scripts/test-build.sh -d arch
#   ./scripts/test-build.sh -d fedora -r 42
#   ./scripts/test-build.sh -d opensuse -r tumbleweed

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${REPO_ROOT}/scripts"

# shellcheck source=lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"

# ── Defaults ──────────────────────────────────────────────────────────────────

DISTRO="debian"
RELEASE="bookworm"
ARCH="x86_64"
JOBS=2
SKIP_BOOTSTRAP=0

# ── Argument parsing ──────────────────────────────────────────────────────────

usage() {
    grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--distro)          DISTRO="$2";  shift 2 ;;
        -r|--release)         RELEASE="$2"; shift 2 ;;
        -a|--arch)            ARCH="$2";    shift 2 ;;
        -j|--jobs)            JOBS="$2";    shift 2 ;;
        -s|--skip-bootstrap)  SKIP_BOOTSTRAP=1; shift ;;
        -h|--help)            usage ;;
        *) log ERROR "Unknown option: $1"; usage ;;
    esac
done

# ── Preflight checks ──────────────────────────────────────────────────────────

ERRORS=0

check() {
    local cmd=$1 msg=$2
    if ! command -v "$cmd" &>/dev/null; then
        log ERROR "Missing required tool: ${cmd} — ${msg}"
        ERRORS=$(( ERRORS + 1 ))
    fi
}

check docker  "Install Docker: https://docs.docker.com/engine/install/"
check git     "Install git"
check make    "Install make"
check rsync   "Install rsync (needed by bootstrap)"

[[ $ERRORS -gt 0 ]] && exit 1

# ── Bootstrap ─────────────────────────────────────────────────────────────────

if [[ $SKIP_BOOTSTRAP -eq 0 ]]; then
    log INFO "Bootstrapping ${DISTRO}"
    "${SCRIPT_DIR}/bootstrap.sh" "$DISTRO"
else
    log INFO "Skipping bootstrap (--skip-bootstrap)"
fi

# ── Build ─────────────────────────────────────────────────────────────────────

log INFO "Starting build: distro=${DISTRO} release=${RELEASE} arch=${ARCH} jobs=${JOBS}"
START=$(date +%s)

case "$DISTRO" in
    debian|ubuntu)
        make -C "$REPO_ROOT" "build-${DISTRO}" \
            RELEASE="$RELEASE" ARCH="$ARCH" PROCS="$JOBS"
        ;;
    arch)
        make -C "$REPO_ROOT" build-arch ARCH="$ARCH" PROCS="$JOBS"
        ;;
    fedora)
        make -C "$REPO_ROOT" build-fedora \
            FEDORA_RELEASE="$RELEASE" ARCH="$ARCH" PROCS="$JOBS"
        ;;
    opensuse)
        make -C "$REPO_ROOT" build-opensuse \
            OPENSUSE_RELEASE="$RELEASE" ARCH="$ARCH" PROCS="$JOBS"
        ;;
    *)
        log ERROR "Unsupported distro for test-build: ${DISTRO}"
        log WARN  "Supported: debian, ubuntu, arch, fedora, opensuse"
        exit 1
        ;;
esac

END=$(date +%s)
ELAPSED=$(( END - START ))

# ── Verify output ─────────────────────────────────────────────────────────────

log INFO "Verifying output packages"

ARTIFACT_DIR=""
PATTERN=""

case "$DISTRO" in
    debian|ubuntu)
        ARTIFACT_DIR="${REPO_ROOT}/artifacts/debian/${RELEASE}"
        PATTERN="*.deb"
        ;;
    arch)
        ARTIFACT_DIR="${REPO_ROOT}/artifacts/arch"
        PATTERN="*.pkg.tar.zst"
        ;;
    fedora)
        ARTIFACT_DIR="${REPO_ROOT}/artifacts/fedora"
        PATTERN="*.rpm"
        ;;
    opensuse)
        ARTIFACT_DIR="${REPO_ROOT}/artifacts/opensuse"
        PATTERN="*.rpm"
        ;;
esac

mapfile -t packages < <(find "$ARTIFACT_DIR" -name "$PATTERN" ! -name '*.src.rpm' 2>/dev/null)

if [[ ${#packages[@]} -eq 0 ]]; then
    log ERROR "No output packages found in ${ARTIFACT_DIR}"
    exit 1
fi

log INFO "Build succeeded in $(( ELAPSED / 60 ))m$(( ELAPSED % 60 ))s"
log INFO "Output packages (${#packages[@]}):"
for pkg in "${packages[@]}"; do
    printf "  %s  (%s)\n" "$(basename "$pkg")" "$(du -sh "$pkg" | cut -f1)"
done
