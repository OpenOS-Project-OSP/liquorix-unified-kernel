# Liquorix Unified Build System
#
# Usage:
#   make                          # show available targets
#   make build-debian RELEASE=trixie
#   make build-ubuntu RELEASE=noble
#   make build-arch
#   make build-fedora
#   make KERNEL_VERSION=6.12.1 build-gentoo
#   make install
#
# Variables:
#   PROCS          parallel jobs (default: nproc/2, min 2)
#   BUILD          build number (default: 1)
#   DISTRO         distro name — required for per-release targets
#   RELEASE        release codename — required for Debian/Ubuntu targets
#   ARCH           target architecture: x86_64|arm64|riscv64 (default: host)
#   MLEVEL         x86-64 microarch level: v1|v2|v3|v4 (default: auto-detect)
#   KERNEL_VERSION kernel version for Gentoo/generic builds (e.g. 6.12.1)
#   ENABLE_BDFS    set to 1 to build + install the btrfs_dwarfs module
#   BDFS_SRC       path to btrfs-dwarfs-framework checkout (auto-cloned if unset)

NPROC  := $(shell nproc 2>/dev/null || echo 4)
PROCS  := $(shell echo $$(( $(NPROC) / 2 > 2 ? $(NPROC) / 2 : 2 )))
BUILD  := 1
DISTRO         :=
RELEASE        :=
ARCH           := $(shell uname -m | sed 's/aarch64/arm64/')
FEDORA_RELEASE   := 42
OPENSUSE_RELEASE := tumbleweed
ENABLE_BDFS      := 0
BDFS_SRC         :=
MLEVEL           :=

SCRIPTS := scripts

require-release = \
	$(if $(DISTRO),,$(error DISTRO is required)) \
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ DISTRO=debian RELEASE=trixie))

.PHONY: help \
	install \
	build-debian build-ubuntu build-arch build-fedora build-gentoo build-generic build \
	build-bdfs \
	bootstrap-debian bootstrap-ubuntu bootstrap-arch bootstrap-fedora \
	clean

help: ## Show available targets
	@echo "Liquorix Unified Build System"
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "Variables:"
	@printf "  %-18s %s\n" "PROCS=$(PROCS)"  "parallel jobs (nproc/2, min 2)"
	@printf "  %-18s %s\n" "BUILD=$(BUILD)"  "build number"
	@printf "  %-18s %s\n" "ARCH=$(ARCH)"    "target architecture"
	@printf "  %-18s %s\n" "RELEASE="           "release codename (Debian/Ubuntu)"
	@printf "  %-18s %s\n" "FEDORA_RELEASE=42"          "Fedora release number"
	@printf "  %-18s %s\n" "OPENSUSE_RELEASE=tumbleweed" "openSUSE release"
	@printf "  %-18s %s\n" "MLEVEL="            "x86-64 microarch level: v1|v2|v3|v4 (auto-detect)"
	@printf "  %-18s %s\n" "KERNEL_VERSION="    "kernel version (Gentoo/generic)"
	@printf "  %-18s %s\n" "ENABLE_BDFS=0"      "build + install btrfs_dwarfs module"
	@printf "  %-18s %s\n" "BDFS_SRC="          "path to btrfs-dwarfs-framework checkout"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-z][a-z-]+:.*##' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{ printf "  %-22s %s\n", $$1, $$2 }'

# ── Install ───────────────────────────────────────────────────────────────────

install: ## Install Liquorix on the current system (auto-detects distro)
	sudo KERNEL_VERSION=$(KERNEL_VERSION) ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) $(SCRIPTS)/install.sh

# ── Build — per distro ────────────────────────────────────────────────────────

# _MLEVEL_FLAG passes --mlevel only when MLEVEL is explicitly set (otherwise auto-detect runs).
_MLEVEL_FLAG = $(if $(MLEVEL),--mlevel $(MLEVEL),)
# _BDFS_FLAG is appended when ENABLE_BDFS=1.
_BDFS_FLAG = $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)
# Common env prefix for all build.sh invocations.
_BUILD_ENV = ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) $(if $(MLEVEL),MLEVEL=$(MLEVEL),)

build-debian: ## Build .deb packages (needs RELEASE=<codename>, e.g. trixie)
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ RELEASE=trixie))
	$(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro debian --release $(RELEASE) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-ubuntu: ## Build .deb packages for Ubuntu (needs RELEASE=<codename>, e.g. noble)
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ RELEASE=noble))
	$(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro ubuntu --release $(RELEASE) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-arch: ## Build Arch Linux .pkg.tar.zst
	$(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro arch --arch $(ARCH) --jobs $(PROCS) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-fedora: ## Build Fedora RPM packages (FEDORA_RELEASE=42)
	FEDORA_RELEASE=$(FEDORA_RELEASE) $(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro fedora --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-opensuse: ## Build openSUSE RPM packages (OPENSUSE_RELEASE=tumbleweed)
	OPENSUSE_RELEASE=$(OPENSUSE_RELEASE) $(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro opensuse --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-gentoo: ## Build Gentoo kernel with genkernel (needs KERNEL_VERSION=x.y.z)
	$(if $(KERNEL_VERSION),,$(error KERNEL_VERSION is required, e.g. make $@ KERNEL_VERSION=6.12.1))
	KERNEL_VERSION=$(KERNEL_VERSION) $(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro gentoo --arch $(ARCH) --jobs $(PROCS) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-generic: ## Build + install via plain make install — no packaging, any distro (needs KERNEL_VERSION=x.y.z)
	$(if $(KERNEL_VERSION),,$(error KERNEL_VERSION is required, e.g. make $@ KERNEL_VERSION=6.12.1))
	KERNEL_VERSION=$(KERNEL_VERSION) $(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro generic --arch $(ARCH) --jobs $(PROCS) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build: ## Build for a single release (needs DISTRO= and RELEASE= for deb targets)
	$(_BUILD_ENV) \
	  $(SCRIPTS)/build.sh --distro $(DISTRO) $(if $(RELEASE),--release $(RELEASE),) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(_MLEVEL_FLAG) $(_BDFS_FLAG)

build-bdfs: ## Build only the btrfs_dwarfs module (requires a prior kernel build in SRCDIR)
	ENABLE_BDFS=1 $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro $(if $(DISTRO),$(DISTRO),generic) $(if $(RELEASE),--release $(RELEASE),) --arch $(ARCH) --jobs $(PROCS) --bdfs

# ── Bootstrap Docker images ───────────────────────────────────────────────────
# bootstrap-* targets fetch upstream Dockerfiles + container scripts from
# damentz/liquorix-package, then build the Docker images.

bootstrap-debian: ## Fetch upstream scripts and build Debian Docker images
	$(SCRIPTS)/bootstrap.sh debian

bootstrap-ubuntu: ## Fetch upstream scripts and build Ubuntu Docker images
	$(SCRIPTS)/bootstrap.sh ubuntu

bootstrap-arch: ## Fetch upstream scripts and build Arch Linux Docker image
	$(SCRIPTS)/bootstrap.sh arch

bootstrap-fedora: ## Fetch upstream scripts and build Fedora Docker images
	$(SCRIPTS)/bootstrap.sh fedora

bootstrap-opensuse: ## Build openSUSE Docker images
	$(SCRIPTS)/bootstrap.sh opensuse

bootstrap-all: ## Bootstrap all distros
	$(SCRIPTS)/bootstrap.sh

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean: ## Remove build artifacts and Liquorix Docker images
	rm -rf artifacts/
	docker images --format '{{.Repository}}:{{.Tag}}' \
		| grep '^liquorix-build-' \
		| xargs -r docker rmi || true
