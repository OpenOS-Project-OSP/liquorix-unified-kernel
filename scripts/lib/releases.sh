#!/bin/bash
# GitHub Releases download helpers.
# Source this file; do not execute directly.

RELEASES_API="https://api.github.com/repos/OSPF1896/liquorix-unified-kernel/releases/latest"
RELEASES_BASE="https://gitlab.com/OSPF1896/liquorix-unified-kernel/releases/latest/download"

# latest_release_version prints the latest release tag (e.g. v6.12.1-lqx1),
# or empty string if the API is unreachable or no releases exist yet.
latest_release_version() {
    curl -fsSL --max-time 10 "$RELEASES_API" 2>/dev/null \
        | grep -oP '"tag_name":\s*"\K[^"]+' \
        || true
}

# download_release_asset downloads a named asset from the latest GitHub Release
# into the given destination path.
#
# Usage: download_release_asset <filename> <dest_path>
download_release_asset() {
    local filename=$1
    local dest=$2
    local url="${RELEASES_BASE}/${filename}"

    log INFO "Downloading ${filename}"
    if ! curl -fsSL --max-time 300 -o "$dest" "$url"; then
        log ERROR "Failed to download ${url}"
        return 1
    fi
}
