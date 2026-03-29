#!/bin/bash
# Install Liquorix on openSUSE via local RPM.
# Sourced by install.sh — do not execute directly.
#
# openSUSE uses zypper + RPM. No official Liquorix OBS repo exists yet.
# This installs from a locally built RPM produced by `make build-opensuse`.
# When an OBS repo is published, replace the local-install path with:
#   zypper addrepo <url> liquorix && zypper install kernel-liquorix

install_opensuse() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Liquorix RPM packages are only available for x86_64 on openSUSE."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    local rpm_path
    rpm_path=$(find artifacts/opensuse -name 'kernel-liquorix-*.rpm' \
        ! -name '*.src.rpm' 2>/dev/null | sort -V | tail -n1)

    if [[ -z "$rpm_path" ]]; then
        log ERROR "No openSUSE RPM found under artifacts/opensuse/."
        log WARN  "Build first with: make build-opensuse"
        exit 1
    fi

    log INFO "Installing $rpm_path"
    zypper --non-interactive install "$rpm_path"
    log INFO "Liquorix kernel installed"
}
