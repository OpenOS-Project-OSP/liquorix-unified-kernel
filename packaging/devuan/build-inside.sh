#!/bin/bash
# Runs inside the Debian/Ubuntu build container.
# Delegates to the upstream container_build-binary.sh from damentz/liquorix-package,
# which is synced into this directory by scripts/bootstrap.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Upstream script expects these positional args: arch distro release [build]
exec "${SCRIPT_DIR}/container_build-binary.sh" \
    "${ARCH:-amd64}" \
    "${DISTRO:?DISTRO must be set}" \
    "${RELEASE:?RELEASE must be set}" \
    "${BUILD:-1}"
