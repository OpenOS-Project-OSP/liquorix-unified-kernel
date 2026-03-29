#!/bin/bash
# Distro and architecture detection helpers. Source this file; do not execute directly.

# detect_arch prints the normalized kernel architecture string:
#   x86_64 | arm64 | riscv64
detect_arch() {
    local machine
    machine=$(uname -m)
    case "$machine" in
        x86_64)          echo "x86_64" ;;
        aarch64|arm64)   echo "arm64" ;;
        riscv64)         echo "riscv64" ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

# detect_distro prints a normalized distro token used to dispatch install logic:
#
#   debian    — Debian and all derivatives (Ubuntu, Mint, Pop!_OS, Kali, MX,
#               Zorin, elementary, KDE neon, antiX, Parrot, Devuan, Proxmox,
#               SparkyLinux, BunsenLabs, Q4OS, Bodhi, Lite, PikaOS, Endless,
#               Linuxfx, Voyager, Emmabuntüs, DragonOS, AnduinOS, TUXEDO,
#               Rhino, FunOS, Kodachi, AV Linux, wattOS, MakuluLinux, BigLinux,
#               Peppermint, Feren, blendOS, Vanilla, Qubes-Debian, and more)
#
#   ubuntu    — Ubuntu and flavours (Kubuntu, Lubuntu, Xubuntu, Ubuntu MATE,
#               Ubuntu Studio) — detected separately so PPA path is used
#
#   arch      — Arch Linux and derivatives (Manjaro, EndeavourOS, CachyOS,
#               Garuda, Artix, ArchBang, Archcraft, RebornOS, Mabox-Arch,
#               blendOS-Arch, Parabola, Crystal, Hyperbola)
#
#   fedora    — Fedora and close derivatives (Nobara, Bazzite, Ultramarine,
#               Qubes-Fedora)
#
#   rhel      — RHEL-family (Red Hat, AlmaLinux, Rocky Linux, Oracle Linux,
#               CentOS Stream, Scientific Linux, EuroLinux, NaviOS)
#
#   opensuse  — openSUSE Tumbleweed, Leap, and derivatives (Regata OS,
#               GeckoLinux, Slowroll)
#
#   gentoo    — Gentoo and derivatives (Calculate, Funtoo, Sabayon)
#
#   alpine    — Alpine Linux (detected but not supported — musl libc)
#
#   unknown   — anything else (Slackware, Void, NixOS, Solus, Mandrake family,
#               non-Linux OSes)

detect_distro() {
    local id="" id_like="" pretty=""

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release 2>/dev/null || true
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
        pretty="${PRETTY_NAME:-}"
    fi

    # Normalise to lowercase, combine id + id_like for matching
    local all
    all=$(echo "${id} ${id_like}" | tr '[:upper:]' '[:lower:]')

    # ── Gentoo (check before generic rpm to avoid false positives) ────────────
    if echo "$all" | grep -qw 'gentoo'; then
        echo "gentoo"; return
    fi
    command -v emerge &>/dev/null && { echo "gentoo"; return; }

    # ── Alpine ────────────────────────────────────────────────────────────────
    if echo "$all" | grep -qw 'alpine'; then
        echo "alpine"; return
    fi
    command -v apk &>/dev/null && [[ -f /etc/alpine-release ]] && {
        echo "alpine"; return
    }

    # ── Arch family ───────────────────────────────────────────────────────────
    if echo "$all" | grep -qwE 'arch|archlinux|manjaro|endeavouros|cachyos|garuda|artix|parabola'; then
        echo "arch"; return
    fi
    command -v pacman &>/dev/null && { echo "arch"; return; }

    # ── openSUSE family ───────────────────────────────────────────────────────
    if echo "$all" | grep -qwE 'opensuse|suse|sles'; then
        echo "opensuse"; return
    fi
    command -v zypper &>/dev/null && { echo "opensuse"; return; }

    # ── Ubuntu (before debian — Ubuntu sets ID=ubuntu, ID_LIKE=debian) ───────
    if echo "$all" | grep -qw 'ubuntu'; then
        echo "ubuntu"; return
    fi

    # ── Debian family ─────────────────────────────────────────────────────────
    # Covers: debian, linuxmint, pop, zorin, elementary, kdeneon, antix,
    #         kali, sparky, bunsenlabs, q4os, bodhi, pika, endless, proxmox,
    #         devuan, parrot, and hundreds of other debian derivatives
    if echo "$all" | grep -qwE 'debian|linuxmint|mint|raspbian|devuan|kali|parrot|proxmox|antix|sparky|bunsenlabs|elementary|zorin|pop|peppermint|feren|bodhi|lite|pika|endless|anduinos|tuxedo|rhino|kodachi|makululinux|biglinux|blendos|vanilla|qubes'; then
        echo "debian"; return
    fi
    command -v apt-get &>/dev/null && { echo "debian"; return; }

    # ── RHEL family ───────────────────────────────────────────────────────────
    # Covers: rhel, almalinux, rocky, oracle, centos, scientific, eurolinux,
    #         nobara, bazzite, ultramarine (all set ID_LIKE=fedora or rhel)
    if echo "$all" | grep -qwE 'rhel|almalinux|rocky|oracle|centos|scientific|eurolinux|nobara|bazzite|ultramarine'; then
        echo "rhel"; return
    fi
    # Fedora-like but not Fedora itself
    if echo "$all" | grep -qw 'fedora' && ! echo "$id" | grep -qw 'fedora'; then
        echo "rhel"; return
    fi

    # ── Fedora ────────────────────────────────────────────────────────────────
    if echo "$all" | grep -qw 'fedora'; then
        echo "fedora"; return
    fi
    command -v dnf &>/dev/null && [[ -f /etc/fedora-release ]] && {
        echo "fedora"; return
    }

    # ── Generic dnf/rpm fallback → rhel ──────────────────────────────────────
    command -v dnf &>/dev/null && command -v rpm &>/dev/null && {
        echo "rhel"; return
    }

    echo "unknown"
}
