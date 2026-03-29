# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This ebuild is a skeleton. It is not yet in the Gentoo tree.
# To use it locally:
#   mkdir -p /etc/portage/repos.conf
#   # Add a local overlay pointing to this repo
#   emerge linux-liquorix

EAPI=8

inherit kernel-build

MY_P="linux-${PV%.*}"
LQX_REL="1"
LQX_BRANCH="${PV%.*}-${LQX_REL}"

DESCRIPTION="Liquorix kernel — Zen-based desktop-optimized kernel"
HOMEPAGE="https://liquorix.net"

SRC_URI="
    https://cdn.kernel.org/pub/linux/kernel/v${PV%%.*}.x/${MY_P}.tar.xz
    https://github.com/damentz/liquorix-package/archive/${LQX_BRANCH}.tar.gz
        -> liquorix-package-${LQX_BRANCH}.tar.gz
"

LICENSE="GPL-2"
KEYWORDS="~amd64"
IUSE="debug"

BDEPEND="
    sys-devel/bc
    dev-lang/perl
    sys-apps/coreutils
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
    local patch_dir="${WORKDIR}/liquorix-package-${LQX_BRANCH}/linux-liquorix/debian/patches"

    einfo "Applying Liquorix patch series"
    grep -P '^(zen|lqx)/' "${patch_dir}/series" | while IFS= read -r p; do
        eapply "${patch_dir}/${p}"
    done

    # Apply Liquorix kernel config
    local config_src="${WORKDIR}/liquorix-package-${LQX_BRANCH}/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
    cp "${config_src}" "${S}/.config"

    kernel-build_src_prepare
}

pkg_setup() {
    kernel-build_pkg_setup
}

src_configure() {
    kernel-build_src_configure
}

src_compile() {
    kernel-build_src_compile
}

src_install() {
    kernel-build_src_install
}

pkg_postinst() {
    kernel-build_pkg_postinst
}
