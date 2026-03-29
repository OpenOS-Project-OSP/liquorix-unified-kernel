#!/bin/bash
# Build Liquorix .deb packages via Docker.
# Sourced by build.sh — do not execute directly.
#
# The Debian pipeline has two stages:
#   1. Source build  — runs in a fixed debian/bookworm container, produces
#                      .dsc + .orig.tar.xz under artifacts/debian/<release>/
#   2. Binary build  — runs in the target distro/release container, consumes
#                      the source packages and produces installable .deb files
#
# Requires: Docker, upstream scripts synced by scripts/bootstrap.sh

build_deb() {
    local distro=$1   # debian | ubuntu
    local release=$2  # trixie | noble | etc.
    local procs=$3
    local build_num=$4

    # Image tag format: liquorix_<arch>/<distro>/<release>
    local docker_arch="amd64"
    [[ "${ARCH:-x86_64}" == "arm64"   ]] && docker_arch="arm64v8"
    [[ "${ARCH:-x86_64}" == "riscv64" ]] && docker_arch="riscv64"

    # Source packages are always built in debian/bookworm (upstream convention)
    local source_image="liquorix_amd64/debian/bookworm"
    local binary_image="liquorix_${docker_arch}/${distro}/${release}"

    local artifacts_dir="${REPO_ROOT}/artifacts/debian/${release}"
    mkdir -p "$artifacts_dir"

    # ── Stage 1: source build ─────────────────────────────────────────────────

    if ! docker image inspect "$source_image" &>/dev/null; then
        log WARN "Source build image ${source_image} not found. Run: make bootstrap-debian"
        exit 1
    fi

    log INFO "Building source package for ${distro}/${release}"
    docker run --rm \
        --net=host \
        --tmpfs /build:exec \
        --ulimit nofile=524288:524288 \
        -v "${REPO_ROOT}:/liquorix-package:ro" \
        -v "${artifacts_dir}:/liquorix-package/artifacts/debian/${release}" \
        -e DISTRO="$distro" \
        -e RELEASE="$release" \
        -e BUILD="$build_num" \
        "$source_image" \
        /liquorix-package/packaging/debian/build-source-inside.sh

    log INFO "Source packages written to ${artifacts_dir}"

    # ── Stage 2: binary build ─────────────────────────────────────────────────

    if ! docker image inspect "$binary_image" &>/dev/null; then
        log WARN "Binary build image ${binary_image} not found. Run: make bootstrap-${distro}"
        exit 1
    fi

    log INFO "Building binary packages for ${distro}/${release} (jobs=${procs})"
    docker run --rm \
        --net=host \
        --ulimit nofile=524288:524288 \
        -v "${REPO_ROOT}:/liquorix-package:ro" \
        -v "${artifacts_dir}:/liquorix-package/artifacts/debian/${release}" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="$docker_arch" \
        -e DISTRO="$distro" \
        -e RELEASE="$release" \
        "$binary_image" \
        /liquorix-package/packaging/debian/build-inside.sh

    log INFO "Binary packages written to ${artifacts_dir}"
}
