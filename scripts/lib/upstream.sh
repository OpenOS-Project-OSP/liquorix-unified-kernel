#!/bin/bash
# Helpers for fetching upstream damentz/liquorix-package build infrastructure.
# Source this file; do not execute directly.
#
# Rather than vendoring the upstream Dockerfiles and container scripts, we
# fetch them at bootstrap time. This keeps us in sync with upstream
# automatically and avoids license/copyright concerns with verbatim copying.

UPSTREAM_REPO="https://github.com/damentz/liquorix-package"

# fetch_upstream_scripts clones or updates the upstream repo into
# .upstream-cache/ and copies the requested distro's Docker build
# infrastructure into packaging/<distro>/.
#
# Usage: fetch_upstream_scripts <distro> <branch>
#   distro: debian | archlinux | fedora
#   branch: e.g. 6.19/master
fetch_upstream_scripts() {
    local distro=$1
    local branch=${2:-$(git ls-remote --heads "$UPSTREAM_REPO" | grep -oP '\d+\.\d+/master' | sort -V | tail -1)}
    local cache_dir="${REPO_ROOT}/.upstream-cache"

    if [[ ! -d "$cache_dir/.git" ]]; then
        log INFO "Cloning damentz/liquorix-package (branch ${branch})"
        git clone --depth=1 --branch "$branch" "$UPSTREAM_REPO" "$cache_dir"
    else
        log INFO "Updating damentz/liquorix-package cache"
        git -C "$cache_dir" fetch --depth=1 origin "$branch"
        git -C "$cache_dir" checkout FETCH_HEAD
    fi

    local src_dir="${cache_dir}/scripts/${distro}"
    local dst_dir="${REPO_ROOT}/packaging/${distro}"

    log INFO "Syncing ${distro} build scripts from upstream"
    # Copy Dockerfile and container scripts; skip host-side docker_*.sh wrappers
    # (we have our own in scripts/lib/build-*.sh)
    rsync -a --include='Dockerfile' \
              --include='container_*.sh' \
              --include='common_bootstrap.sh' \
              --include='env.sh' \
              --include='*.spec' \
              --exclude='*' \
              "${src_dir}/" "${dst_dir}/"

    # Also sync the shared lib.sh
    cp -f "${cache_dir}/scripts/lib.sh" "${REPO_ROOT}/packaging/lib.sh"

    log INFO "Upstream scripts synced to packaging/${distro}/"
}
