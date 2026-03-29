#!/bin/bash
# Build Liquorix .deb packages via Docker.
# Sourced by build.sh — do not execute directly.
#
# Mirrors the approach in damentz/liquorix-package scripts/debian/.
# Requires: Docker

build_deb() {
    local distro=$1   # debian | ubuntu
    local release=$2  # trixie | noble | etc.
    local procs=$3
    local build_num=$4

    log INFO "Building .deb for ${distro}/${release} (jobs=${procs}, build=${build_num})"

    # Image tag format matches damentz/liquorix-package: liquorix_<arch>/<distro>/<release>
    local docker_arch="amd64"
    [[ "$arch" == "arm64"   ]] && docker_arch="arm64v8"
    [[ "$arch" == "riscv64" ]] && docker_arch="riscv64"

    local image="liquorix_${docker_arch}/${distro}/${release}"
    local out_dir="${REPO_ROOT}/artifacts/debian/${release}"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-${distro}"
        exit 1
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="$docker_arch" \
        -e DISTRO="$distro" \
        -e RELEASE="$release" \
        "$image" \
        /build/packaging/debian/build-inside.sh

    log INFO "Packages written to ${out_dir}"
}
