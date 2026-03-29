#!/bin/bash
# Build Liquorix .pkg.tar.zst for Arch Linux via Docker.
# Sourced by build.sh — do not execute directly.
#
# Requires: Docker

build_arch() {
    local procs=$1

    log INFO "Building Arch Linux package (jobs=${procs})"

    local image="liquorix_amd64/archlinux/latest"
    local out_dir="${REPO_ROOT}/artifacts/arch"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-arch"
        exit 1
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e ARCH="amd64" \
        "$image" \
        /build/packaging/arch/build-inside.sh

    log INFO "Package written to ${out_dir}"
}
