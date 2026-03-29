# Liquorix kernel RPM spec.
#
# Version variables are injected by the build system via rpmbuild --define:
#   version_upstream  e.g. 6.12.1
#   version_build     e.g. 1
#   fedora_release    e.g. 42
#
# For local builds:
#   rpmbuild -bb \
#     --define "version_upstream 6.12.1" \
#     --define "version_build 1" \
#     --define "fedora_release 42" \
#     kernel-liquorix.spec

# Disable frame pointers and LTO (not applicable to kernel builds)
%undefine _include_frame_pointers
%global _lto_cflags %{nil}

%global lqxversion lqx1
%global kversion %{version_upstream}.%{lqxversion}-%{version_build}

# Derive major version (e.g. 6.12.1 -> 6.12) for tarball name
%global kmajor %(echo %{version_upstream} | grep -oP '^\d+\.\d+')

Name:           kernel-liquorix
Version:        %{version_upstream}.%{lqxversion}
Release:        %{version_build}%{?dist}
Summary:        Liquorix kernel — Zen-based desktop-optimized kernel
License:        GPL-2.0-only
URL:            https://liquorix.net
ExclusiveArch:  x86_64

Source0:        linux-%{kmajor}.tar.xz
Source1:        v%{version_upstream}-%{lqxversion}.patch
Source2:        config-x86_64-liquorix

BuildRequires:  bc bison cpio dwarves elfutils-devel flex gcc gcc-c++
BuildRequires:  kmod make openssl-devel patch perl python3
BuildRequires:  rpm-build rust rust-src xz zstd bindgen-cli

Provides:       installonlypkg(kernel)
Provides:       kernel-uname-r = %{kversion}
Requires:       %{name}-modules = %{version}-%{release}
Requires(pre):  coreutils systemd /usr/bin/kernel-install dracut
Requires(preun): systemd
Recommends:     linux-firmware
AutoReq:        no
AutoProv:       yes

%define debug_package %{nil}
%define _binary_payload w3.zstdio

%description
The Liquorix kernel is a desktop-optimized kernel built from the Zen kernel
sources. It is tuned for throughput, latency, and interactivity on desktop
and gaming workloads.

%package devel
Summary:        Development files for Liquorix kernel %{kversion}
Provides:       installonlypkg(kernel)
Provides:       kernel-devel-uname-r = %{kversion}
Requires:       %{name} = %{version}-%{release}
Requires:       findutils perl-interpreter openssl-devel elfutils-libelf-devel
Requires:       bison flex make gcc
AutoReqProv:    no

%description devel
Kernel headers and build files for compiling out-of-tree modules against
the Liquorix kernel %{kversion}.

%package modules
Summary:        Kernel modules for Liquorix kernel %{kversion}
Provides:       installonlypkg(kernel-module)
Provides:       kernel-modules-uname-r = %{kversion}
Provides:       kernel-modules-core-uname-r = %{kversion}
Requires:       %{name} = %{version}-%{release}
AutoReq:        no
AutoProv:       yes

%description modules
Loadable kernel modules for the Liquorix kernel %{kversion}.

# ── Prep ──────────────────────────────────────────────────────────────────────

%prep
%setup -q -n linux-%{kmajor}

# Apply Liquorix patch
patch -p1 < %{SOURCE1}

# Clear EXTRAVERSION set by the zen patch — we control the full version string
sed -i 's/^EXTRAVERSION = .*/EXTRAVERSION =/' Makefile

cp %{SOURCE2} .config

# Use XZ module compression to match mainline Fedora
scripts/config --disable MODULE_COMPRESS_ALL
scripts/config --disable MODULE_COMPRESS_ZSTD
scripts/config --enable  MODULE_COMPRESS_XZ

make olddefconfig

# ── Build ─────────────────────────────────────────────────────────────────────

%build
make %{?_smp_mflags} LOCALVERSION=.%{lqxversion}-%{version_build} bzImage modules

# ── Install ───────────────────────────────────────────────────────────────────

%install
mkdir -p %{buildroot}/boot
mkdir -p %{buildroot}/lib/modules/%{kversion}
mkdir -p %{buildroot}/usr/src/kernels/%{kversion}
mkdir -p %{buildroot}/usr/share/licenses/%{name}

# Kernel image (canonical location for kernel-install)
install -m755 arch/x86/boot/bzImage %{buildroot}/lib/modules/%{kversion}/vmlinuz

# Supporting files
install -m644 System.map  %{buildroot}/lib/modules/%{kversion}/System.map
install -m644 .config     %{buildroot}/lib/modules/%{kversion}/config
install -m644 modules.builtin          %{buildroot}/lib/modules/%{kversion}/modules.builtin
install -m644 modules.builtin.modinfo  %{buildroot}/lib/modules/%{kversion}/modules.builtin.modinfo

# Compressed symvers
xz --check=crc32 --lzma2=dict=1MiB --stdout < Module.symvers \
    > %{buildroot}/lib/modules/%{kversion}/symvers.xz

# Initramfs placeholder for RPM disk space accounting
dd if=/dev/zero of=%{buildroot}/boot/initramfs-%{kversion}.img bs=1M count=40

# License
cp COPYING %{buildroot}/usr/share/licenses/%{name}/COPYING-%{version}-%{release}

# Modules
make INSTALL_MOD_PATH=%{buildroot} modules_install INSTALL_MOD_STRIP=1 \
    KERNELRELEASE=%{kversion} mod-fw=

# Generate module category lists
find %{buildroot}/lib/modules/%{kversion} -name "*.ko" -type f > modnames
grep -F /drivers/ modnames | xargs --no-run-if-empty nm -upA | \
    sed -n 's,^.*/\([^/]*\.ko\): *U \(.*\)$,\1 \2,p' > drivers.undef

collect_modules_list() {
    sed -r -n -e "s/^([^ ]+) \.?($2)\$/\1/p" drivers.undef \
        | LC_ALL=C sort -u > %{buildroot}/lib/modules/%{kversion}/modules.$1
    [ -n "${3:-}" ] && \
        sed -r -e "/^($3)\$/d" -i %{buildroot}/lib/modules/%{kversion}/modules.$1
}
collect_modules_list networking \
    'register_netdev|ieee80211_register_hw|usbnet_probe|phy_driver_register'
collect_modules_list block \
    'ata_scsi_ioctl|scsi_add_host|blk_alloc_queue|blk_init_queue' \
    'pktcdvd.ko|dm-mod.ko'
collect_modules_list drm 'drm_open|drm_init'
collect_modules_list modesetting 'drm_crtc_init'

# Compress modules with XZ
find %{buildroot}/lib/modules/%{kversion} -type f -name '*.ko' | \
    xargs -n16 -P${RPM_BUILD_NCPUS} -r xz --check=crc32 --lzma2=dict=1MiB

# Extra module dirs
mkdir -p %{buildroot}/lib/modules/%{kversion}/{updates,weak-updates,systemtap}

# Remove depmod-generated files (regenerated at install time)
pushd %{buildroot}/lib/modules/%{kversion}/
rm -f modules.{alias,alias.bin,builtin.alias.bin,builtin.bin,dep,dep.bin,devname,softdep,symbols,symbols.bin,weakdep}
popd

# Remove build/source symlinks (replaced by devel package)
rm -f %{buildroot}/lib/modules/%{kversion}/build
rm -f %{buildroot}/lib/modules/%{kversion}/source

# VDSO
make ARCH=x86 INSTALL_MOD_PATH=%{buildroot} vdso_install KERNELRELEASE=%{kversion}
rm -rf %{buildroot}/lib/modules/%{kversion}/vdso/.build-id

# ── Devel package ─────────────────────────────────────────────────────────────

%define DevelDir %{buildroot}/usr/src/kernels/%{kversion}

cp --parents $(find -type f -name "Makefile*" -o -name "Kconfig*") %{DevelDir}
cp .config Module.symvers System.map %{DevelDir}
cp -a scripts %{DevelDir}
rm -rf %{DevelDir}/scripts/tracing
mkdir -p %{DevelDir}/security/selinux/include
cp -a --parents security/selinux/include/*.h %{DevelDir}
cp -a --parents tools/include %{DevelDir}
cp -a --parents arch/x86/include %{DevelDir}
cp -a arch/x86/Makefile %{DevelDir}/arch/x86/
cp -a include %{DevelDir}

find %{DevelDir}/scripts \( -iname "*.o" -o -iname "*.cmd" \) -exec rm -f {} +
find %{DevelDir}/tools   \( -iname "*.o" -o -iname "*.cmd" \) -exec rm -f {} +

touch -r %{DevelDir}/Makefile \
    %{DevelDir}/include/generated/uapi/linux/version.h \
    %{DevelDir}/include/config/auto.conf

ln -sf /usr/src/kernels/%{kversion} %{buildroot}/lib/modules/%{kversion}/build
ln -sf /usr/src/kernels/%{kversion} %{buildroot}/lib/modules/%{kversion}/source

# ── Scriptlets ────────────────────────────────────────────────────────────────

%post
mkdir -p %{_localstatedir}/lib/rpm-state/%{name}
touch %{_localstatedir}/lib/rpm-state/%{name}/installing_core_%{kversion}

%posttrans
rm -f %{_localstatedir}/lib/rpm-state/%{name}/installing_core_%{kversion}
/bin/kernel-install add %{kversion} /lib/modules/%{kversion}/vmlinuz || exit $?
if [ ! -e /boot/symvers-%{kversion}.xz ]; then
    cp /lib/modules/%{kversion}/symvers.xz /boot/symvers-%{kversion}.xz
fi

%preun
/bin/kernel-install remove %{kversion} || exit $?

%post modules
/sbin/depmod -a %{kversion}

%postun modules
[ -d /lib/modules/%{kversion} ] && /sbin/depmod -a %{kversion}

%posttrans modules
if [ -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{kversion} ]; then
    rm -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{kversion}
    dracut -f --kver %{kversion} /boot/initramfs-%{kversion}.img || exit $?
fi

%post devel
if [ -f /etc/sysconfig/kernel ]; then
    . /etc/sysconfig/kernel || exit $?
fi
if [ "$HARDLINK" != "no" ] && [ -x /usr/bin/hardlink ] && [ ! -e /run/ostree-booted ]; then
    (cd /usr/src/kernels/%{kversion} && \
     /usr/bin/find . -type f | while read f; do
         hardlink -c /usr/src/kernels/*%{?dist}.*/$f $f > /dev/null 2>&1
     done) || true
fi

# ── File lists ────────────────────────────────────────────────────────────────

%files
%license /usr/share/licenses/%{name}/COPYING-%{version}-%{release}
/lib/modules/%{kversion}/vmlinuz
/lib/modules/%{kversion}/System.map
/lib/modules/%{kversion}/config
/lib/modules/%{kversion}/symvers.xz
/lib/modules/%{kversion}/modules.builtin*
%dir /lib/modules
%dir /lib/modules/%{kversion}
%ghost %attr(0755,root,root) /boot/vmlinuz-%{kversion}
%ghost %attr(0644,root,root) /boot/System.map-%{kversion}
%ghost %attr(0644,root,root) /boot/config-%{kversion}
%ghost %attr(0644,root,root) /boot/symvers-%{kversion}.xz
%ghost %attr(0600,root,root) /boot/initramfs-%{kversion}.img

%files modules
%dir /lib/modules
%dir /lib/modules/%{kversion}
%dir /lib/modules/%{kversion}/kernel
/lib/modules/%{kversion}/kernel
/lib/modules/%{kversion}/updates
/lib/modules/%{kversion}/weak-updates
/lib/modules/%{kversion}/systemtap
/lib/modules/%{kversion}/vdso
/lib/modules/%{kversion}/modules.order
/lib/modules/%{kversion}/modules.block
/lib/modules/%{kversion}/modules.drm
/lib/modules/%{kversion}/modules.modesetting
/lib/modules/%{kversion}/modules.networking
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.alias
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.alias.bin
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.builtin.alias.bin
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.builtin.bin
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.dep
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.dep.bin
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.devname
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.softdep
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.symbols
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.symbols.bin
%ghost %attr(0644,root,root) /lib/modules/%{kversion}/modules.weakdep
%exclude /lib/modules/%{kversion}/build
%exclude /lib/modules/%{kversion}/source

%files devel
%defverify(not mtime) /usr/src/kernels/%{kversion}
/lib/modules/%{kversion}/build
/lib/modules/%{kversion}/source
