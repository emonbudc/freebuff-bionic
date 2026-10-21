# Freebuff for Termux / Android

Native **Bionic aarch64** build of [Freebuff](https://freebuff.com), the free
terminal coding agent. No proot, no glibc shim, no npm launcher.

This repository is a build kit: it pins an upstream Freebuff snapshot, applies a
small Android port patch, compiles with the patched Bun runtime from
[`bd-loser/bun-termux`](https://github.com/bd-loser/bun-termux), and packages the
result as a Termux `.deb`.

> **Status:** compiles, installs from `.deb`, and launches the Freebuff TUI on
> Termux aarch64 (validated 2026-10-21). Authenticated agent runs have not been
> exhaustively tested yet. This is an independent port, not affiliated with
> Codebuff or Freebuff.

## Install

Requirements: Termux on Android aarch64, plus `curl`, `dpkg`, `git`, and
`ripgrep`.

```bash
pkg install curl git ripgrep
curl -fsSL https://raw.githubusercontent.com/emonbudc/freebuff-bionic/main/install.sh | bash
```

Or install a specific release:

```bash
bash install.sh 0.2.32
```

The package installs:

| Path | Purpose |
| --- | --- |
| `$PREFIX/bin/freebuff` | symlink to the binary |
| `$PREFIX/lib/freebuff/freebuff` | compiled executable |
| `$PREFIX/lib/freebuff/tree-sitter.wasm` | required sibling asset |

Run it inside a project:

```bash
cd ~/my-project
freebuff
```

## Build locally

Install the known-good Bun runtime, then run the build:

```bash
pkg install git python curl dpkg ripgrep
curl -fL -o bun.deb \
  https://github.com/bd-loser/bun-termux/releases/download/v1.3.14-patched/bun_1.3.14-patched_aarch64.deb
dpkg -i bun.deb

git clone https://github.com/emonbudc/freebuff-bionic.git
cd freebuff-bionic
bash termux/ci/build-local.sh
```

The `.deb` and checksums land in `dist/`. The first build downloads the pinned
upstream tree and dependencies; later builds rebuild it from scratch.

## How the port works

| Change | Reason |
| --- | --- |
| `@opentui/core` / `@opentui/react` → `@androidtui/*` `0.5.1` aliases | Upstream OpenTUI has no Android native package. AndroidTUI publishes the Bionic `libopentui.so` and matching JS. |
| Add `android-arm64` target to `cli/scripts/build-binary.ts` | Upstream only knows linux/darwin/win32. `bun-linux-arm64` reuses the running bun-termux runtime. |
| Skip OpenTUI's native-bundle installer on Android | The installer assumes the `@opentui` scope and glibc/musl packages; Bun embeds the AndroidTUI `.so` directly. |
| Build SDK declarations with `--no-types` | Upstream's public snapshot currently has type drift in its AI SDK dependency graph. Declarations are not needed for the executable. |
| Use system `rg` on Android | The vendored Linux `rg` is dynamically linked against glibc and cannot execute on Bionic. The package depends on Termux's `ripgrep`. |
| Ship `tree-sitter.wasm` beside the binary | Freebuff resolves it from `dirname(process.execPath)`. |
| Remove `canvas`, `gif-encoder-2`, and the `evals` workspace | They are not needed for the CLI and would drag native glibc/npm artifacts into the install. |

The exact upstream revision, AndroidTUI versions, and Bun version are pinned in
[`versions.json`](versions.json). The dependency lock is
[`termux/bun.lock`](termux/bun.lock).

## Verify an artifact

```bash
sha256sum -c freebuff_0.2.32-1_aarch64.deb.sha256
dpkg-deb --info freebuff_0.2.32-1_aarch64.deb
dpkg-deb --contents freebuff_0.2.32-1_aarch64.deb
```

The binary should print `0.2.32`:

```bash
freebuff --version
```

## CI

`.github/workflows/build.yml` builds on GitHub's `ubuntu-24.04-arm` runner inside
`termux/termux-docker:aarch64`. Tag pushes (`v0.2.32-1`) publish the `.deb` and
its SHA-256 to a GitHub Release. Manual runs upload a workflow artifact.

## Version policy

- `freebuff.version` is the upstream CLI version compiled into the binary.
- `freebuff.debRevision` is the port's package revision.
- Release tags are `v<version>-<revision>`, e.g. `v0.2.32-1`.
- Upstream is pinned by full commit, not by a moving branch.

## Known limitations

- aarch64 only (no armv7 or x86_64 Termux builds yet).
- The upstream npm launcher and its self-updater are not used. Update through a
  new `.deb`.
- The PostHog and Stripe public keys are upstream CI placeholders. Analytics and
  paid-plan links are therefore not fully configured in this build.
- Login opens the browser through Termux's `xdg-open`; a device without a
  browser or URL handler will need the URL copied manually.
- Android background-process limits and Termux wake-locks still apply to long
  agent sessions.

## License

The build kit is licensed under Apache-2.0. Freebuff itself is Apache-2.0,
copyright Codebuff. The package includes the upstream `LICENSE` and `NOTICE` in
`/usr/share/doc/freebuff/copyright`.

Freebuff, Codebuff, AndroidTUI, and Termux are the property of their respective
owners. This repository is an independent, community build.
