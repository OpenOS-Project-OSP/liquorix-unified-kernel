#!/bin/bash
# Build Liquorix RPM packages for openSUSE via Docker.
# Sourced by build.sh — do not execute directly.
#
# openSUSE uses rpmbuild like Fedora but with different base packages and
# a different release numbering scheme. The same kernel-liquorix.spec is
# reused with openSUSE-specific adjustments applied at build time.
#
# Requires: Docker

build_opensuse() {
    local procs=$1
    local build_num=$2
    local opensuse_release="${OPENSUSE_RELEASE:-tumbleweed}"

    local image="liquorix_amd64/opensuse/${opensuse_release}"
    local out_dir="${REPO_ROOT}/artifacts/opensuse"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-opensuse"
        exit 1
    fi

    log INFO "Building openSUSE RPM (release=${opensuse_release}, jobs=${procs})"
    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="$ARCH" \
        -e RELEASE="$opensuse_release" \
        "$image" \
        /build/packaging/opensuse/build-inside.sh

    log INFO "RPMs written to ${out_dir}"
}
