# liquorix-unified-kernel

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/liquorix-unified-kernel)

<!-- AI:start:what-it-does -->
This project provides a unified build and installation system for the Liquorix kernel, designed to work across multiple Linux distributions and architectures. It simplifies the process of building and deploying the kernel by offering a consistent interface for tasks such as specifying target distributions, releases, architectures, and kernel versions. It is intended for developers and system administrators who need to build and install the Liquorix kernel in diverse environments.
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
The Liquorix Unified Kernel build system consists of modular components designed for distro-agnostic and architecture-agnostic kernel builds. The `Makefile` defines build targets for various distributions (e.g., Debian, Ubuntu, Arch, Fedora, Gentoo) and supports configurable parameters such as `ARCH`, `RELEASE`, and `KERNEL_VERSION`. The build process is orchestrated through shell scripts located in the `scripts` directory. Workflow automation is managed via GitHub Actions YAML files in the `.github/workflows` directory. Configuration files for specific distributions and kernel versions are stored in the `configs` directory.

Directory structure:
```plaintext
.
├── .github/
│   └── workflows/          # CI/CD workflows
├── configs/                # Distro and kernel-specific configurations
├── docs/                   # Documentation files
├── packaging/              # Packaging scripts and metadata
├── remixes/                # Custom kernel remixes
├── scripts/                # Build and utility scripts
├── Makefile                # Main build system entry point
├── README.md               # Project documentation
├── LICENSE                 # License information
└── VERSION                 # Current version of the project
```

Key interactions include invoking `make` targets to trigger builds, which rely on scripts and configuration files to generate kernel packages tailored to the specified distribution and architecture.
<!-- AI:end:architecture -->

## Install

<!-- Add installation instructions here. This section is yours — the AI will not modify it. -->

```bash
git clone https://github.com/Interested-Deving-1896/liquorix-unified-kernel.git
cd liquorix-unified-kernel
```

## Usage

<!-- Add usage examples here. This section is yours — the AI will not modify it. -->

## Configuration

<!-- Document configuration options here. This section is yours — the AI will not modify it. -->

## CI

<!-- AI:start:ci -->
The repository uses GitHub Actions for continuous integration and automation. Below are the workflows and their purposes:

- **build.yml**: Builds the Liquorix kernel for supported distributions and architectures. No secrets required.
- **release.yml**: Handles the release process, including tagging and publishing artifacts. Requires `GITHUB_TOKEN`.
- **validate-config.yml**: Validates configuration files for correctness. No secrets required.
- **cleanup-branches.yml**: Removes stale branches from the repository. Requires `GITHUB_TOKEN`.
- **mirror-releases.yml**: Mirrors release artifacts to external storage. Requires `MIRROR_STORAGE_KEY`.
- **sync-to-gitlab.yml**: Synchronizes the repository with a GitLab mirror. Requires `GITLAB_TOKEN`.
- **rate-limit-status.yml**: Monitors GitHub API rate limits. Requires `GITHUB_TOKEN`.
- **rotate-token.yml**: Rotates access tokens for security. Requires `ADMIN_TOKEN`.

Refer to `.github/workflows/` for detailed workflow configurations. Ensure required secrets are added in the repository settings under "Secrets and variables."
<!-- AI:end:ci -->

## Mirror chain

<!-- AI:start:mirror-chain -->
This repo is maintained in [`Interested-Deving-1896/liquorix-unified-kernel`](https://github.com/Interested-Deving-1896/liquorix-unified-kernel) and mirrored through:

```
Interested-Deving-1896/liquorix-unified-kernel  ──►  OpenOS-Project-OSP/liquorix-unified-kernel  ──►  OpenOS-Project-Ecosystem-OOC/liquorix-unified-kernel
```

Changes flow downstream automatically via the hourly mirror chain in
[`fork-sync-all`](https://github.com/Interested-Deving-1896/fork-sync-all).
Direct commits to OSP or OOC are detected and opened as PRs back to `Interested-Deving-1896`.
<!-- AI:end:mirror-chain -->

## Contributors

<!-- AI:start:contributors -->
- [@Interested-Deving-1896](https://github.com/Interested-Deving-1896): 247 commits  
- [@web-flow](https://github.com/web-flow): 1 commit  
- [@ona-agent](https://github.com/ona-agent): 1 commit  

*Note: This repository appears to be a mirror. Please refer to the upstream source for additional contributions and details.*
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->
_Original project — no upstream fork._
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
_No additional resource files found._
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
<!-- License not detected — add a LICENSE file to this repo. -->
<!-- AI:end:license -->
