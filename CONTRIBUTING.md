# Contributing

## Prerequisites

- Docker (for build pipeline)
- `git`, `make`, `rsync`, `curl`
- `shellcheck` (for linting)

## Getting started

```bash
git clone https://gitlab.com/openos-project/linux-kernel_filesystem_deving/liquorix-unified-kernel
cd liquorix-unified-kernel

# Fetch upstream build infrastructure and build Docker images
./scripts/bootstrap.sh debian   # or arch, fedora, opensuse

# Run the full pipeline end-to-end
./scripts/test-build.sh -d debian -r bookworm
```

## Branch strategy

| Branch | Purpose |
|---|---|
| `main` | Stable — all PRs target this branch |
| `update/liquorix-*` | Auto-created by the upstream watcher workflow |

## Making changes

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run shellcheck: `find scripts/ packaging/ -name '*.sh' | xargs shellcheck --severity=warning`
4. Run a test build: `./scripts/test-build.sh`
5. Open a pull request against `main`

## Types of contributions

### Adding a new distro
Follow [docs/adding-distro.md](docs/adding-distro.md). The minimum required:
- Detection in `scripts/lib/detect.sh`
- Install handler in `scripts/lib/install-<family>.sh`
- Dispatch case in `scripts/install.sh`
- Entry in the README distro table

### Adding a new architecture
Follow [docs/adding-arch.md](docs/adding-arch.md). Use the
`gen-arch-config` GitHub Actions workflow to generate a candidate config,
review it, then open a PR adding it to `configs/<arch>/config`.

### Fixing a build pipeline bug
- Reproduce with `./scripts/test-build.sh`
- The build scripts are in `scripts/lib/build-*.sh`
- Container entry points are in `packaging/*/build-inside.sh`
- The upstream container scripts live in `.upstream-cache/` after bootstrap

### Updating to a new kernel version
The upstream watcher workflow opens a PR automatically when a new
`damentz/liquorix-package` branch appears. To update manually:

```bash
echo "6.20.1-lqx1" > VERSION
git add VERSION
git commit -m "Update to Liquorix 6.20.1-lqx1"
git push origin update/liquorix-6.20.1-lqx1
# open PR, merge, then tag:
git tag v6.20.1-lqx1
git push origin v6.20.1-lqx1
```

Pushing the tag triggers the release workflow which builds and publishes
packages for all supported distros.

## GPG signing

See [docs/gpg-signing.md](docs/gpg-signing.md) for how to set up signing
for local builds and CI.

## Commit messages

- One subject line, imperative mood, ≤72 characters
- Body explains *why*, not *what* (the diff shows what)
- Reference issues where relevant: `Fixes #42`

## Code style

- Shell scripts: `bash`, `set -euo pipefail`, 4-space indent
- All scripts must pass `shellcheck --severity=warning`
- Functions named `verb_noun` (e.g. `install_debian`, `build_deb`)
- Log with `log INFO/WARN/ERROR` from `scripts/lib/log.sh`
