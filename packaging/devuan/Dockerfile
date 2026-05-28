# Build environment for Devuan Liquorix packages.
#
# Uses devuan/devuan base images. Build system is identical to
# packaging/debian — Devuan is binary-compatible with Debian.
#
# Build args:
#   ARCH    - Docker arch prefix (e.g. amd64, arm64v8)
#   DISTRO  - debian | ubuntu
#   RELEASE - release codename (e.g. trixie, noble)
#
# Usage (via scripts/bootstrap.sh or make bootstrap-debian):
#   docker buildx build \
#     --build-arg ARCH=amd64 \
#     --build-arg DISTRO=debian \
#     --build-arg RELEASE=trixie \
#     -t liquorix_amd64/debian/trixie \
#     -f packaging/debian/Dockerfile .

ARG ARCH
ARG DISTRO
ARG RELEASE
# Devuan images: docker.io/devuan/devuan:<release>
# Set ARCH='' for devuan (images are not arch-prefixed on Docker Hub)
FROM devuan/devuan:${RELEASE}

ENV DEBIAN_FRONTEND=noninteractive

# eatmydata bypasses fsync calls inside the container, significantly speeding
# up apt operations that are not writing to persistent storage.
RUN apt-get update && \
    apt-get install -y --no-install-recommends eatmydata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libeatmydata.so

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        devscripts \
        equivs \
        wget \
        gnupg \
        schedtool && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
