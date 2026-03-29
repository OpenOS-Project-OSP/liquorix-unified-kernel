# Adding a new distribution

This document describes how to add install and build support for a distro
that is not yet covered.

## Determine the package family

First check whether the distro belongs to an already-supported family:

| Family | Package manager | Existing handler |
|---|---|---|
| Debian derivatives | `apt` | `install-debian.sh` or `install-ubuntu.sh` |
| Arch derivatives | `pacman` | `install-arch.sh` |
| Fedora derivatives | `dnf` + RPM | `install-fedora.sh` |
| RHEL derivatives | `dnf` + RPM | `install-rhel.sh` |
| openSUSE derivatives | `zypper` + RPM | `install-opensuse.sh` |
| Gentoo derivatives | `emerge` | `install-gentoo.sh` |

If the distro is a derivative of one of the above, it may already work —
test with `sudo ./scripts/install.sh` and check what `detect_distro` returns.

## Steps for a genuinely new family

### 1. Add detection in `scripts/lib/detect.sh`

Add a new case to `detect_distro()` that matches the distro's `ID` or
`ID_LIKE` from `/etc/os-release`, or its package manager binary.

### 2. Write `scripts/lib/install-<family>.sh`

Source this file in `scripts/install.sh` and add a dispatch case.

The install function signature is:

```bash
install_<family>() {
    local arch=$1   # x86_64 | arm64 | riscv64
    # ...
}
```

If no pre-built packages exist, install from a locally built artifact
(see existing `install-fedora.sh` or `install-opensuse.sh` for the pattern)
and document the build step clearly.

### 3. Write `scripts/lib/build-<family>.sh` (if needed)

If the distro uses a package format not already covered, add a build module
and a corresponding `packaging/<family>/` directory with:

- `Dockerfile` — build environment
- `build-inside.sh` — entry point run inside the container

### 4. Update `scripts/build.sh`

Source the new build module and add a dispatch case.

### 5. Update `scripts/bootstrap.sh`

Add the new distro to `ALL_DISTROS`, `upstream_dir()`, `docker_base_args()`,
and `build_docker_image()`.

### 6. Update the Makefile

Add `build-<family>` and `bootstrap-<family>` targets.

### 7. Update `scripts/test-build.sh`

Add the new distro to the case statement so it can be tested end-to-end.

### 8. Update the README

Add the distro to the supported distros table.

### 9. Open a pull request

Include in the PR:
- Which distro(s) were tested
- How install was verified (screenshot or terminal output)
- Any known limitations
