#!/bin/bash
# Build Liquorix RPM packages for Fedora via Docker.
# Sourced by build.sh — do not execute directly.
#
# Requires: Docker

build_rpm() {
    local procs=$1
    local build_num=$2

    log INFO "Building Fedora RPM (jobs=${procs}, build=${build_num})"

    # Default to latest stable Fedora release
    local fedora_release="${FEDORA_RELEASE:-42}"
    local image="liquorix_amd64/fedora/${fedora_release}"
    local out_dir="${REPO_ROOT}/artifacts/fedora"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-fedora"
        exit 1
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="amd64" \
        -e RELEASE="$fedora_release" \
        "$image" \
        /build/packaging/fedora/build-inside.sh

    log INFO "RPMs written to ${out_dir}"
}
