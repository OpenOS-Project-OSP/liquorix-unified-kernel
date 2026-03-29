# Build environment for openSUSE Liquorix RPM packages.
#
# Build args:
#   DISTRO  - opensuse/tumbleweed | opensuse/leap
#   RELEASE - tumbleweed | 15.6 | etc.
#
# Usage (via scripts/bootstrap.sh or make bootstrap-opensuse):
#   docker buildx build \
#     --build-arg RELEASE=tumbleweed \
#     -t liquorix_amd64/opensuse/tumbleweed \
#     -f packaging/opensuse/Dockerfile .

ARG RELEASE=tumbleweed
FROM opensuse/${RELEASE}

RUN zypper --non-interactive refresh && \
    zypper --non-interactive dist-upgrade && \
    zypper --non-interactive install \
        bc \
        bison \
        cpio \
        dwarves \
        flex \
        gcc \
        gcc-c++ \
        gnupg2 \
        kernel-devel \
        kmod \
        make \
        openssl-devel \
        patch \
        perl \
        python3 \
        rpm-build \
        rpmdevtools \
        rust \
        schedtool \
        sudo \
        wget \
        xz \
        zstd \
        elfutils-devel \
        libelf-devel && \
    zypper clean --all

RUN useradd -ms /bin/bash builder && \
    mkdir -p /etc/sudoers.d && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-builder

USER builder
WORKDIR /home/builder

RUN rpmdev-setuptree
