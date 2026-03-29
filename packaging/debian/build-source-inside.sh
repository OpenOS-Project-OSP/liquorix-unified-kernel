#!/bin/bash
# Runs inside the Debian source-build container (always debian/bookworm).
# Produces .dsc + .orig.tar.xz consumed by all subsequent binary builds.
# Delegates to the upstream container_build-source.sh synced by bootstrap.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Upstream script args: distro release [build]
exec "${SCRIPT_DIR}/container_build-source.sh" \
    "${DISTRO:?DISTRO must be set}" \
    "${RELEASE:?RELEASE must be set}" \
    "${BUILD:-1}"
