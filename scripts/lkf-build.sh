#!/usr/bin/env bash
# scripts/lkf-build.sh — lkf remix hook for liquorix-unified-kernel
#
# Called by `lkf remix` when a remix.toml contains [lkf_hook] script = "scripts/lkf-build.sh".
# Translates lkf environment variables into the liquorix-unified-kernel build pipeline.
#
# lkf sets these env vars before calling this script:
#   LKF_ARCH          target arch (x86_64, aarch64, armv7l)
#   LKF_FLAVOR        kernel flavor (liquorix)
#   LKF_VERSION       kernel version string or "latest"
#   LKF_LLVM          1 if --llvm was passed
#   LKF_LTO           lto mode (none|thin|full)
#   LKF_THREADS       parallel jobs
#   LKF_OUTPUT_FORMAT output format (deb|rpm|pkg)
#   LKF_BUILD_DIR     build output directory
#
# [lkf_hook] env overrides are merged into the environment before this script runs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Map lkf arch names → liquorix ARCH names ─────────────────────────────────
lkf_arch="${LKF_ARCH:-${ARCH:-x86_64}}"
case "${lkf_arch}" in
  x86_64|amd64)   export ARCH="x86_64" ;;
  aarch64|arm64)  export ARCH="arm64"  ;;
  armv7l|armhf)   export ARCH="armhf"  ;;
  *)
    echo "[lkf-build] Unsupported arch for liquorix: ${lkf_arch}" >&2
    echo "[lkf-build] Supported: x86_64, arm64, armhf" >&2
    exit 1
    ;;
esac

# ── Propagate lkf build settings ─────────────────────────────────────────────
export PROCS="${LKF_THREADS:-${PROCS:-$(nproc)}}"
export DISTRO="${DISTRO:-debian}"
export RELEASE="${RELEASE:-trixie}"

# Output format → make target
case "${LKF_OUTPUT_FORMAT:-deb}" in
  deb)  MAKE_TARGET="build-${DISTRO}" ;;
  rpm)  MAKE_TARGET="build-fedora"    ;;
  pkg)  MAKE_TARGET="build-arch"      ;;
  *)    MAKE_TARGET="build-${DISTRO}" ;;
esac
export MAKE_TARGET

# Build directory
if [[ -n "${LKF_BUILD_DIR:-}" ]]; then
  export BUILD_DIR="${LKF_BUILD_DIR}"
fi

echo "[lkf-build] liquorix: DISTRO=${DISTRO} RELEASE=${RELEASE} ARCH=${ARCH} PROCS=${PROCS}"
echo "[lkf-build] make target: ${MAKE_TARGET}"

# ── Resolve upstream branch ───────────────────────────────────────────────────
UPSTREAM_BRANCH=$(git ls-remote --heads https://github.com/damentz/liquorix-package \
  | grep -oP '\d+\.\d+/master' | sort -V | tail -1)
echo "[lkf-build] upstream branch: ${UPSTREAM_BRANCH}"

# ── Bootstrap (Docker images + upstream cache) ────────────────────────────────
cd "${REPO_ROOT}"
bash scripts/bootstrap.sh "${DISTRO}"

# ── Download kernel source if not cached ─────────────────────────────────────
if ! ls .upstream-cache/linux-liquorix_*.orig.tar.xz &>/dev/null; then
  echo "[lkf-build] downloading kernel source..."
  .upstream-cache/scripts/debian/common_bootstrap.sh
fi

# ── Build ─────────────────────────────────────────────────────────────────────
make "${MAKE_TARGET}" \
  RELEASE="${RELEASE}" \
  ARCH="${ARCH}" \
  PROCS="${PROCS}"
