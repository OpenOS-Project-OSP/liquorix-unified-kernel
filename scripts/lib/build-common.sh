#!/bin/bash
# Shared build helpers. Source this file; do not execute directly.
#
# Provides:
#   fetch_sources    — download vanilla kernel + liquorix-package archives
#   apply_patches    — apply zen/lqx patch series
#   select_config    — copy the appropriate Liquorix .config into the tree
#   build_bdfs_module — build the btrfs_dwarfs out-of-tree module (ENABLE_BDFS=1)

# fetch_sources downloads the vanilla kernel tarball and the liquorix-package
# archive into $SRCDIR, then extracts them.
#
# Globals used: KERNEL_VERSION, KERNEL_MAJOR, LQX_REL, SRCDIR
fetch_sources() {
    mkdir -p "$SRCDIR"

    local kernel_tar="${SRCDIR}/linux-${KERNEL_MAJOR}.tar.xz"
    local lqx_tar="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}.tar.gz"

    if [[ ! -f "$kernel_tar" ]]; then
        log INFO "Downloading linux-${KERNEL_MAJOR}.tar.xz"
        curl -L --fail \
            "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR%%.*}.x/linux-${KERNEL_MAJOR}.tar.xz" \
            -o "$kernel_tar"
    fi

    if [[ ! -f "$lqx_tar" ]]; then
        log INFO "Downloading liquorix-package-${KERNEL_MAJOR}-${LQX_REL}.tar.gz"
        curl -L --fail \
            "https://github.com/damentz/liquorix-package/archive/${KERNEL_MAJOR}-${LQX_REL}.tar.gz" \
            -o "$lqx_tar"
    fi

    log INFO "Extracting sources"
    tar -xf "$kernel_tar" -C "$SRCDIR"
    tar -xf "$lqx_tar"   -C "$SRCDIR"
}

# apply_patches applies the zen/lqx patch series from the liquorix-package
# archive onto the extracted kernel source tree.
#
# Globals used: KERNEL_MAJOR, LQX_REL, SRCDIR
apply_patches() {
    local patch_dir="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}/linux-liquorix/debian/patches"
    local kernel_dir="${SRCDIR}/linux-${KERNEL_MAJOR}"

    log INFO "Applying Liquorix patch series"
    grep -P '^(zen|lqx)/' "${patch_dir}/series" | while IFS= read -r patch; do
        log INFO "  patch: $patch"
        patch -Np1 -d "$kernel_dir" -i "${patch_dir}/${patch}"
    done
}

# select_config copies the appropriate Liquorix kernel config for the target
# architecture into the kernel source tree as .config, then merges the
# x86-64 microarch level fragment when ARCH=x86_64 and MLEVEL is set.
#
# Globals used: ARCH, MLEVEL, KERNEL_MAJOR, LQX_REL, SRCDIR, REPO_ROOT
select_config() {
    local kernel_dir="${SRCDIR}/linux-${KERNEL_MAJOR}"
    local lqx_pkg_dir="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}"

    local config_src
    case "$ARCH" in
        x86_64)
            # Upstream config from damentz/liquorix-package
            config_src="${lqx_pkg_dir}/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
            ;;
        arm64|riscv64)
            # Local config authored in this repo (see configs/<arch>/config)
            config_src="${REPO_ROOT}/configs/${ARCH}/config"
            if [[ ! -f "$config_src" ]]; then
                log ERROR "No config found for ${ARCH} at ${config_src}"
                log WARN  "See docs/adding-arch.md to author a new architecture config"
                exit 1
            fi
            ;;
        *)
            log ERROR "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    log INFO "Using config: $config_src"
    cp "$config_src" "${kernel_dir}/.config"

    # Merge x86-64 microarch level fragment when requested
    if [[ "$ARCH" == "x86_64" && -n "${MLEVEL:-}" ]]; then
        local mlevel_fragment="${REPO_ROOT}/configs/x86_64/microarch-${MLEVEL}.config"
        if [[ ! -f "$mlevel_fragment" ]]; then
            log ERROR "Unknown MLEVEL '${MLEVEL}'. Valid values: v1 v2 v3 v4"
            exit 1
        fi
        log INFO "Merging microarch fragment: microarch-${MLEVEL}.config"
        # scripts/kconfig/merge_config.sh merges fragments into an existing
        # .config in-place, running olddefconfig to resolve any new symbols.
        "${kernel_dir}/scripts/kconfig/merge_config.sh" \
            -m "${kernel_dir}/.config" "$mlevel_fragment"
        make -C "$kernel_dir" olddefconfig
    fi
}

# build_bdfs_module builds the btrfs_dwarfs out-of-tree kernel module against
# the extracted kernel source tree.  Called after the kernel has been compiled
# so that the Module.symvers file is present.
#
# For Docker-based distros (debian, ubuntu, arch, fedora, opensuse) the kernel
# source is extracted inside the container and is not available on the host
# after the container exits.  In those cases SRCDIR and KERNEL_MAJOR are unset
# on the host, so this function falls back to building against the running
# host kernel headers (/lib/modules/$(uname -r)/build).  This produces a
# module compatible with the host kernel, not the freshly built Liquorix
# kernel — suitable for testing, but the module should be rebuilt after
# rebooting into the new kernel.
#
# For Gentoo (on-host build) SRCDIR and KERNEL_MAJOR are set by build-gentoo.sh
# so the module is built against the correct tree.
#
# Globals used: KERNEL_MAJOR, SRCDIR, REPO_ROOT
# Environment:
#   ENABLE_BDFS   set to 1 to activate (default: 0)
#   BDFS_SRC      path to a btrfs-dwarfs-framework checkout; auto-cloned if absent
build_bdfs_module() {
    local enable_bdfs="${ENABLE_BDFS:-0}"
    [[ "${enable_bdfs}" != "1" ]] && return 0

    local bdfs_src="${BDFS_SRC:-${REPO_ROOT}/.bdfs-src}"
    local bdfs_repo="https://github.com/Interested-Deving-1896/btrfs-dwarfs-framework.git"

    # Determine the kernel tree to build against
    local kernel_dir
    if [[ -n "${SRCDIR:-}" && -n "${KERNEL_MAJOR:-}" && -d "${SRCDIR}/linux-${KERNEL_MAJOR}" ]]; then
        # On-host build (Gentoo): use the extracted source tree
        kernel_dir="${SRCDIR}/linux-${KERNEL_MAJOR}"
        log INFO "Building btrfs_dwarfs against Liquorix source: ${kernel_dir}"
    else
        # Docker-based build: source tree is inside the container; fall back to
        # host kernel headers so the module can at least be compiled and tested.
        kernel_dir="/lib/modules/$(uname -r)/build"
        log WARN "Kernel source not available on host (Docker-based build)."
        log WARN "Building btrfs_dwarfs against running kernel headers: ${kernel_dir}"
        log WARN "Rebuild the module after rebooting into the new Liquorix kernel."
    fi

    if [[ ! -d "${bdfs_src}/kernel/btrfs_dwarfs" ]]; then
        log INFO "Cloning btrfs-dwarfs-framework into ${bdfs_src}"
        git clone --depth=1 "${bdfs_repo}" "${bdfs_src}"
    fi

    log INFO "Building btrfs_dwarfs module"
    make -C "${bdfs_src}/kernel" KDIR="${kernel_dir}"
    log INFO "Module built: ${bdfs_src}/kernel/btrfs_dwarfs/btrfs_dwarfs.ko"

    # Expose the path for install steps
    export BDFS_KO="${bdfs_src}/kernel/btrfs_dwarfs/btrfs_dwarfs.ko"
}
