#!/bin/bash
# Runs inside the openSUSE build container.
# Reuses the Fedora RPM spec with openSUSE-compatible adjustments.
set -euo pipefail

REPO_ROOT="/build"
SPEC="${REPO_ROOT}/packaging/fedora/kernel-liquorix.spec"
OUT_DIR="/artifacts"

: "${PROCS:=2}"
: "${BUILD:=1}"
: "${RELEASE:=tumbleweed}"

# Resolve kernel version from upstream env.sh if available
if [[ -f "${REPO_ROOT}/packaging/fedora/env.sh" ]]; then
    # shellcheck source=/dev/null
    source "${REPO_ROOT}/packaging/fedora/env.sh"
fi

: "${version_upstream:?version_upstream must be set in env.sh}"

# openSUSE uses %{dist} = .opensuse<release> or .suse
DIST=".opensuse.${RELEASE}"

rpmbuild -bb \
    --define "version_upstream ${version_upstream}" \
    --define "version_build ${BUILD}" \
    --define "fedora_release ${RELEASE}" \
    --define "dist ${DIST}" \
    --define "_smp_mflags -j${PROCS}" \
    "$SPEC"

# Copy built RPMs to output dir
find ~/rpmbuild/RPMS -name '*.rpm' -exec cp -v {} "${OUT_DIR}/" \;
