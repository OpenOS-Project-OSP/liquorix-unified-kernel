#!/bin/bash
# Runs inside the Fedora build container.
# Delegates to the upstream container_build-binary.sh from damentz/liquorix-package,
# which is synced into this directory by scripts/bootstrap.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "${SCRIPT_DIR}/container_build-binary.sh" \
    "${ARCH:-amd64}" \
    "fedora" \
    "${RELEASE:?RELEASE must be set}" \
    "${BUILD:-1}"
