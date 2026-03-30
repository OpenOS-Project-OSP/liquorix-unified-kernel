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
#   KERNEL_VERSION kernel version for Gentoo builds (e.g. 6.12.1)
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

SCRIPTS := scripts

require-release = \
	$(if $(DISTRO),,$(error DISTRO is required)) \
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ DISTRO=debian RELEASE=trixie))

.PHONY: help \
	install \
	build-debian build-ubuntu build-arch build-fedora build-gentoo build \
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
	@printf "  %-18s %s\n" "KERNEL_VERSION="    "kernel version (Gentoo)"
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

# _BDFS_FLAGS is appended to every build.sh invocation when ENABLE_BDFS=1.
_BDFS_FLAGS = $(if $(filter 1,$(ENABLE_BDFS)),--bdfs $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),),)

build-debian: ## Build .deb packages (needs RELEASE=<codename>, e.g. trixie)
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ RELEASE=trixie))
	ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro debian --release $(RELEASE) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build-ubuntu: ## Build .deb packages for Ubuntu (needs RELEASE=<codename>, e.g. noble)
	$(if $(RELEASE),,$(error RELEASE is required, e.g. make $@ RELEASE=noble))
	ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro ubuntu --release $(RELEASE) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build-arch: ## Build Arch Linux .pkg.tar.zst
	ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro arch --arch $(ARCH) --jobs $(PROCS) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build-fedora: ## Build Fedora RPM packages (FEDORA_RELEASE=42)
	FEDORA_RELEASE=$(FEDORA_RELEASE) ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro fedora --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build-opensuse: ## Build openSUSE RPM packages (OPENSUSE_RELEASE=tumbleweed)
	OPENSUSE_RELEASE=$(OPENSUSE_RELEASE) ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro opensuse --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build-gentoo: ## Build Gentoo kernel with genkernel (needs KERNEL_VERSION=x.y.z)
	$(if $(KERNEL_VERSION),,$(error KERNEL_VERSION is required, e.g. make $@ KERNEL_VERSION=6.12.1))
	KERNEL_VERSION=$(KERNEL_VERSION) ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro gentoo --arch $(ARCH) --jobs $(PROCS) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

build: ## Build for a single release (needs DISTRO= and RELEASE= for deb targets)
	ENABLE_BDFS=$(ENABLE_BDFS) $(if $(BDFS_SRC),BDFS_SRC=$(BDFS_SRC),) \
	  $(SCRIPTS)/build.sh --distro $(DISTRO) $(if $(RELEASE),--release $(RELEASE),) --arch $(ARCH) --jobs $(PROCS) --build $(BUILD) $(if $(filter 1,$(ENABLE_BDFS)),--bdfs,)

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
