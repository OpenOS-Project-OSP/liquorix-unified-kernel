#!/bin/bash
# Build Liquorix .pkg.tar.zst for Arch Linux via Docker.
# Sourced by build.sh — do not execute directly.
#
# The upstream container_build-binary.sh expects the damentz repo layout
# mounted at /liquorix-package, including linux-lqx.zip at the repo root.
# We mount the upstream cache and bind-mount our artifacts dir over it.
#
# Requires: Docker, upstream cache populated by scripts/bootstrap.sh

build_arch() {
    local procs=$1

    local image="liquorix_amd64/archlinux/latest"
    local out_dir="${REPO_ROOT}/artifacts/arch"
    local cache_dir="${REPO_ROOT}/.upstream-cache"
    mkdir -p "$out_dir"

    if [[ ! -d "${cache_dir}/.git" ]]; then
        log ERROR "Upstream cache not found at ${cache_dir}. Run: make bootstrap-arch"
        exit 1
    fi

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-arch"
        exit 1
    fi

    log INFO "Building Arch Linux package (jobs=${procs})"
    # shellcheck disable=SC2046
    docker run --rm \
        --net=host \
        --ulimit nofile=524288:524288 \
        $(gpg_docker_flags /home/builder) \
        -v "${cache_dir}:/liquorix-package" \
        -v "${out_dir}:/liquorix-package/artifacts/archlinux/latest" \
        "$image" \
        /liquorix-package/scripts/archlinux/container_build-binary.sh \
            "amd64" "archlinux" "latest"

    log INFO "Package written to ${out_dir}"
}
