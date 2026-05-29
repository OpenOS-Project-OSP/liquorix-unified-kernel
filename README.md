# liquorix-unified-kernel

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/liquorix-unified-kernel)

<!-- AI:start:what-it-does -->
This project provides a unified build and installation system for the Liquorix kernel, designed to work across multiple Linux distributions and architectures. It simplifies the process of building and installing the kernel by offering a consistent interface for developers and system administrators, regardless of the target environment.
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
The Liquorix Unified Kernel project consists of a modular build system designed to support multiple Linux distributions and architectures. The key components include a `Makefile` that defines build and installation targets, a `scripts` directory containing helper scripts, and configuration files for specific distributions and architectures. The `Makefile` handles build logic, parallelization, and variable management, allowing users to specify parameters such as target architecture, kernel version, and distribution-specific settings. Workflow automation files in `.github` facilitate CI/CD processes. The directory structure is organized as follows:

```plaintext
.
├── .github                 # CI/CD workflows and automation scripts
├── config                  # General configuration files
├── configs                 # Distribution-specific configuration files
├── docs                    # Documentation files
├── packaging               # Packaging scripts for various distributions
├── remixes                 # Custom kernel remixes
├── scripts                 # Helper scripts for build and install processes
├── Makefile                # Main build system entry point
├── README.md               # Project documentation
├── LICENSE                 # License information
├── VERSION                 # Current version of the project
├── fastci.config.json      # Configuration for fast CI builds
└── .gitignore              # Git ignore rules
```

Components interact through the `Makefile`, which invokes scripts and uses configuration files to execute tasks such as building, packaging, and installing the Liquorix kernel across supported distributions and architectures.
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
- **cleanup-branches.yml**: Removes stale branches from the repository. Requires `GITHUB_TOKEN`.
- **mirror-releases.yml**: Mirrors release artifacts to external storage. Requires `MIRROR_STORAGE_KEY`.
- **sync-forks.yml**: Synchronizes forks with upstream repositories. Requires `GITHUB_TOKEN`.
- **validate-config.yml**: Validates configuration files for consistency. No secrets required.
- **rate-limit-status.yml**: Monitors API rate limits for GitHub. Requires `GITHUB_TOKEN`.

Refer to the `.github/workflows` directory for detailed configurations of each workflow.
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
| File | Description |
|---|---|
| [config/gitlab-subgroups.yml](https://github.com/Interested-Deving-1896/liquorix-unified-kernel/blob/main/config/gitlab-subgroups.yml) | GitLab subgroup map |
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
<!-- License not detected — add a LICENSE file to this repo. -->
<!-- AI:end:license -->
