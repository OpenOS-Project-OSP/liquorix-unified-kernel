# Liquorix Unified

A single build and install system for the [Liquorix kernel](https://liquorix.net)
across all major Linux distributions and CPU architectures.

Liquorix is a Linux kernel built with the Zen patch set and tuned for desktop
responsiveness and low latency. This repo unifies the previously fragmented
packaging efforts into one place.

## Supported distros

### Debian / Ubuntu family (apt)

Pre-built packages from liquorix.net. Covers Debian, Ubuntu, and all
derivatives: Linux Mint, Pop!\_OS, Zorin, elementary, KDE neon, MX Linux,
antiX, Kali, Parrot, Devuan, Proxmox, SparkyLinux, BunsenLabs, Q4OS, Bodhi,
Lite, PikaOS, Endless, AnduinOS, TUXEDO, Rhino, Kodachi, AV Linux, wattOS,
MakuluLinux, BigLinux, Peppermint, Feren, blendOS, Vanilla, and more.

| Distro | Install method | Build method |
|---|---|---|
| Debian | Pre-built `.deb` from liquorix.net | Docker + `dpkg-buildpackage` |
| Ubuntu + flavours | Pre-built `.deb` via PPA | Docker + `dpkg-buildpackage` |

### Arch family (pacman)

Pre-built packages from liquorix.net. Covers Arch Linux, Manjaro,
EndeavourOS, CachyOS, Garuda, Artix, ArchBang, Archcraft, RebornOS,
Parabola, and more.

| Distro | Install method | Build method |
|---|---|---|
| Arch Linux + derivatives | Pre-built package from liquorix.net | Docker + `makepkg` |

### RPM family (dnf / zypper)

| Distro | Install method | Build method |
|---|---|---|
| Fedora, Nobara, Bazzite, Ultramarine | Local RPM (no COPR yet) | Docker + `rpmbuild` |
| RHEL, AlmaLinux, Rocky, Oracle, CentOS Stream | Local RPM | Docker + `rpmbuild` |
| openSUSE Tumbleweed, Leap, Regata | Local RPM (no OBS yet) | Docker + `rpmbuild` |

### Source-based

| Distro | Install method | Build method |
|---|---|---|
| Gentoo + derivatives | `emerge` + `genkernel` | `genkernel` on-host |

### Not supported

| Distro | Reason |
|---|---|
| Alpine Linux | musl libc — Liquorix pre-built packages require glibc |
| NixOS | Fundamentally different kernel management model |
| Void Linux | musl libc variant; glibc variant theoretically possible but untested |
| Slackware family | No Liquorix packages; no package manager integration |
| Solus | eopkg format; no Liquorix packages |
| OpenMandriva / Mageia / PCLinuxOS | No Liquorix packages |
| FreeBSD / GhostBSD / OpenBSD | Not Linux |

## Supported architectures

| Architecture | Status |
|---|---|
| x86_64 | ✅ Full support — pre-built packages available |
| arm64 | 🔧 Build system ready — use `gen-arch-config` workflow to generate config |
| riscv64 | 🔧 Build system ready — use `gen-arch-config` workflow to generate config |

To generate an arm64 or riscv64 config, trigger the
[Generate architecture configs](.github/workflows/gen-arch-config.yml)
workflow manually from GitHub Actions, then follow [docs/adding-arch.md](docs/adding-arch.md).

## Quick install

Detects your distro and installs the appropriate pre-built package:

```bash
sudo ./scripts/install.sh
```

On Gentoo, set `KERNEL_VERSION` first:

```bash
KERNEL_VERSION=6.12.1 sudo ./scripts/install.sh
```

## Building from source

Requires Docker (except Gentoo). Run `make bootstrap-<distro>` once before
building to fetch upstream scripts and build the Docker image.

```bash
# Debian
make bootstrap-debian && make build-debian RELEASE=trixie

# Ubuntu
make bootstrap-ubuntu && make build-ubuntu RELEASE=noble

# Arch Linux
make bootstrap-arch && make build-arch

# Fedora
make bootstrap-fedora && make build-fedora FEDORA_RELEASE=42

# openSUSE
make bootstrap-opensuse && make build-opensuse OPENSUSE_RELEASE=tumbleweed

# Gentoo (no Docker — runs genkernel on the host)
make build-gentoo KERNEL_VERSION=6.12.1
```

Run `make` with no arguments to see all targets and variables.

## Testing the pipeline

To validate the full build pipeline end-to-end:

```bash
./scripts/test-build.sh                          # Debian bookworm (default)
./scripts/test-build.sh -d ubuntu -r noble
./scripts/test-build.sh -d arch
./scripts/test-build.sh -d fedora -r 42
./scripts/test-build.sh -d opensuse -r tumbleweed
./scripts/test-build.sh --skip-bootstrap         # reuse existing Docker images
```

The script bootstraps, builds, and verifies that output packages were produced,
reporting build time and package sizes.

## Repository layout

```
configs/                  Kernel .config files per architecture
  x86_64/                 Pulled from damentz/liquorix-package at build time
  arm64/                  Placeholder — generate with gen-arch-config workflow
  riscv64/                Placeholder — generate with gen-arch-config workflow

packaging/                Distro-specific packaging metadata
  debian/                 Debian/Ubuntu Dockerfile + build scripts
  arch/                   Arch Linux Dockerfile + PKGBUILD + build script
  fedora/                 Fedora Dockerfile + RPM spec + build script
  opensuse/               openSUSE Dockerfile + build script (reuses Fedora spec)
  gentoo/                 Gentoo ebuild skeleton + metadata.xml
  lib.sh                  Shared helpers synced from damentz/liquorix-package

scripts/
  install.sh              Unified installer — auto-detects distro and arch
  build.sh                Unified build entry point
  bootstrap.sh            Fetches upstream scripts, builds Docker images
  test-build.sh           End-to-end pipeline validation script
  lib/
    log.sh                Logging helpers
    detect.sh             Distro + arch detection (covers 8 distro families)
    upstream.sh           Syncs container scripts from damentz/liquorix-package
    install-debian.sh     Debian install via liquorix.net repo
    install-ubuntu.sh     Ubuntu install via PPA
    install-arch.sh       Arch install via liquorix.net pacman repo
    install-fedora.sh     Fedora install from local RPM
    install-rhel.sh       RHEL/AlmaLinux/Rocky/Oracle/CentOS install
    install-opensuse.sh   openSUSE install from local RPM
    install-gentoo.sh     Gentoo source build via genkernel
    install-alpine.sh     Alpine — detected, explains musl incompatibility
    build-common.sh       Shared source fetch + patch + config helpers
    build-deb.sh          Debian/Ubuntu two-stage build (source → binary)
    build-arch.sh         Arch Linux build via makepkg
    build-rpm.sh          Fedora/RHEL RPM build via rpmbuild
    build-opensuse.sh     openSUSE RPM build via rpmbuild
    build-gentoo.sh       Gentoo build via genkernel

docs/
  adding-arch.md          How to author a kernel config for a new architecture

.github/workflows/
  build.yml               CI matrix: Debian/Ubuntu/Arch/Fedora × releases
  gen-arch-config.yml     Manual workflow to generate arm64/riscv64 configs
```

## Relationship to upstream projects

This repo consolidates:

| Source | Contribution absorbed |
|---|---|
| [damentz/liquorix-package](https://github.com/damentz/liquorix-package) | Canonical upstream — patches, configs, Debian/Arch/Fedora build system |
| [archdevlab/linux-lqx](https://github.com/archdevlab/linux-lqx) | Arch PKGBUILD approach |
| [MartinAlejandroOviedo/liquorix4all](https://github.com/MartinAlejandroOviedo/liquorix4all) | Debian installer pattern |
| [GKernelCI/gentoo-sources-build](https://github.com/GKernelCI/gentoo-sources-build) | Gentoo genkernel build approach |

Patches and kernel configs continue to originate from
[damentz/liquorix-package](https://github.com/damentz/liquorix-package) and
the [zen-kernel](https://github.com/zen-kernel/zen-kernel). This repo does not
fork the kernel itself.

## License

GPL-2.0 — same as the Linux kernel.
