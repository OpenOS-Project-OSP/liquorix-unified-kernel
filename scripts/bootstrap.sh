#!/bin/bash
# Fetch upstream build infrastructure and bootstrap Docker images.
#
# This must be run once before any `make build-*` target.
# It pulls Dockerfiles and container scripts from damentz/liquorix-package,
# then builds the Docker images for the requested distros.
#
# Usage:
#   ./scripts/bootstrap.sh [distro ...]
#
# Examples:
#   ./scripts/bootstrap.sh                    # bootstrap all distros
#   ./scripts/bootstrap.sh debian arch        # bootstrap specific distros
#   ./scripts/bootstrap.sh fedora
#
# Supported distros: debian ubuntu arch fedora

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${REPO_ROOT}/scripts"

# shellcheck source=lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=lib/upstream.sh
source "${SCRIPT_DIR}/lib/upstream.sh"

export REPO_ROOT

ALL_DISTROS=(debian ubuntu arch fedora opensuse)

# Map our distro names to upstream script directory names
upstream_dir() {
    case "$1" in
        debian|ubuntu) echo "debian" ;;
        arch)          echo "archlinux" ;;
        fedora)        echo "fedora" ;;
        opensuse)      echo "" ;;  # no upstream scripts — self-contained
    esac
}

# Map our distro names to Docker base image args
docker_base_args() {
    local distro=$1
    case "$distro" in
        debian)
            # Build images for all supported Debian releases
            for release in bookworm trixie forky sid; do
                echo "amd64 debian $release"
            done
            ;;
        ubuntu)
            for release in jammy noble questing resolute; do
                echo "amd64 ubuntu $release"
            done
            ;;
        arch)
            echo "amd64 archlinux latest"
            ;;
        fedora)
            for release in 40 41 42; do
                echo "amd64 fedora $release"
            done
            ;;
        opensuse)
            echo "amd64 opensuse tumbleweed"
            echo "amd64 opensuse leap"
            ;;
    esac
}

build_docker_image() {
    local arch=$1 distro=$2 release=$3
    local image_tag="liquorix_${arch}/${distro}/${release}"
    local dockerfile

    case "$distro" in
        debian|ubuntu) dockerfile="${REPO_ROOT}/packaging/debian/Dockerfile" ;;
        archlinux)     dockerfile="${REPO_ROOT}/packaging/arch/Dockerfile" ;;
        fedora)        dockerfile="${REPO_ROOT}/packaging/fedora/Dockerfile" ;;
        opensuse)      dockerfile="${REPO_ROOT}/packaging/opensuse/Dockerfile" ;;
    esac

    log INFO "Building Docker image: ${image_tag}"
    docker buildx build \
        --network=host \
        --progress=plain \
        -f "$dockerfile" \
        -t "$image_tag" \
        --pull \
        --build-arg ARCH="$arch" \
        --build-arg DISTRO="$distro" \
        --build-arg RELEASE="$release" \
        "${REPO_ROOT}/"
}

# ── Main ──────────────────────────────────────────────────────────────────────

DISTROS=("${@:-${ALL_DISTROS[@]}}")

# Resolve which upstream script dirs we need.
# Distros with an empty upstream_dir (e.g. opensuse) are self-contained
# and do not require a sync from damentz/liquorix-package.
declare -A upstream_dirs_needed
for distro in "${DISTROS[@]}"; do
    udir=$(upstream_dir "$distro")
    [[ -n "$udir" ]] && upstream_dirs_needed["$udir"]=1
done

# Fetch upstream scripts once per unique upstream dir.
# env.sh must exist before any container_*.sh script is invoked — it is
# sourced at the top of every container script for version/path variables.
for udir in "${!upstream_dirs_needed[@]}"; do
    fetch_upstream_scripts "$udir"
done

# Verify env.sh was synced for distros that require it
for distro in "${DISTROS[@]}"; do
    udir=$(upstream_dir "$distro")
    [[ -z "$udir" ]] && continue
    local_dir="${REPO_ROOT}/packaging/${udir}"
    if [[ ! -f "${local_dir}/env.sh" ]]; then
        log WARN "env.sh missing in ${local_dir} — upstream sync may have failed"
    fi
done

# Build Docker images
for distro in "${DISTROS[@]}"; do
    while IFS=' ' read -r arch base_distro release; do
        build_docker_image "$arch" "$base_distro" "$release"
    done < <(docker_base_args "$distro")
done

log INFO "Bootstrap complete. You can now run: make build-<distro>"
