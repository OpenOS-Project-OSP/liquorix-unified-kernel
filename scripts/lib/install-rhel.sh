#!/bin/bash
# Install Liquorix on RHEL-family distros via local RPM.
# Covers: RHEL, AlmaLinux, Rocky Linux, Oracle Linux, CentOS Stream, Nobara,
#         Bazzite, Ultramarine, and any other dnf/rpm-based distro.
# Sourced by install.sh — do not execute directly.
#
# No official Liquorix COPR exists yet. This installs from a locally built
# RPM produced by `make build-fedora`. When a COPR is published, replace
# the local-install path with:
#   dnf copr enable damentz/liquorix && dnf install kernel-liquorix

install_rhel() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Liquorix RPM packages are only available for x86_64."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    # Accept either fedora/ or rhel/ artifact dirs
    local rpm_path
    rpm_path=$(find artifacts/fedora artifacts/rhel -name 'kernel-liquorix-*.rpm' \
        ! -name '*.src.rpm' 2>/dev/null | sort -V | tail -n1)

    if [[ -z "$rpm_path" ]]; then
        log ERROR "No RPM found under artifacts/fedora/ or artifacts/rhel/."
        log WARN  "Build first with: make build-fedora"
        exit 1
    fi

    log INFO "Installing $rpm_path"
    dnf install -y "$rpm_path"
    log INFO "Liquorix kernel installed"
}
