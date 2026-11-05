# satur8 — AUR packaging

AUR packages for [Satur8](https://github.com/NtrpyDev/satur8): per-game digital
vibrance for Linux.

Two packages are published:

| Package | Build | AUR |
| --- | --- | --- |
| `satur8` | Builds from the upstream source archive on your machine | https://aur.archlinux.org/packages/satur8 |
| `satur8-bin` | Downloads CI-built binaries from this repository's GitHub Releases | https://aur.archlinux.org/packages/satur8-bin |

`satur8-bin` provides and conflicts with `satur8`, so install one or the other.

## Install

No compiling:

```sh
yay -S satur8-bin
# or
paru -S satur8-bin
```

Build from source:

```sh
yay -S satur8
```

Manual installation works the same way:

```sh
git clone https://aur.archlinux.org/satur8-bin.git
cd satur8-bin
makepkg -si
```

The source package builds the Rust workspace and the KWin effect against your
local KWin/Qt ABI. `satur8-bin` uses a prebuilt tree produced in a current
`archlinux:base-devel` container.

Optional backends are declared as `optdepends`:

| Package | Backend |
| --- | --- |
| `kwin` | KDE Plasma Wayland saturation effect |
| `gnome-shell` | GNOME Shell extension |
| `gamescope` | universal fallback shader |
| `nvidia-settings` | NVIDIA X11 Digital Vibrance |

## Automated updates

### `satur8` (source package)

[`.github/workflows/aur-update.yml`](.github/workflows/aur-update.yml) runs every
6 hours and on manual dispatch. It:

1. Reads the latest upstream release.
2. Reads the currently published AUR version via cgit (the AUR RPC index can lag
   for new packages).
3. Verifies the release source archive against its `.sha256` asset, GitHub's
   asset digest, and the downloaded file.
4. Updates `pkgver`, resets `pkgrel`, updates `sha256sums`, and regenerates
   `.SRCINFO`.
5. Builds the package in an Arch container before publishing; a build failure
   blocks the update.
6. Commits here and pushes to `ssh://aur@aur.archlinux.org/satur8.git`.

### `satur8-bin` (prebuilt package)

[`.github/workflows/build-bin.yml`](.github/workflows/build-bin.yml) runs after
the source workflow completes, daily as a fallback, and on manual dispatch.

When the AUR `satur8` version is newer than `satur8-bin` (or `satur8-bin` does
not exist yet), it:

1. Builds the source package in an `archlinux:base-devel` container.
2. Repacks the installed file tree as
   `satur8-bin-vX.Y.Z-REL-x86_64.tar.gz`.
3. Publishes that tarball and its checksum as a GitHub Release in this
   repository. AUR does not host binary artifacts, so GitHub Releases is the
   download host, as is standard for `-bin` AUR packages.
4. Updates `satur8-bin/PKGBUILD` (version, `pkgrel`, checksum), regenerates its
   `.SRCINFO`, and pushes both to `ssh://aur@aur.archlinux.org/satur8-bin.git`.
5. Creates the AUR repository on the first push if it does not exist yet.

### Why polling instead of an upstream release trigger?

A GitHub Actions workflow in this repository can only receive events from this
repository. GitHub does not let a workflow subscribe to another account's
`release` events, and upstream has no webhook or dispatch setup for us. Polling
the releases API on a schedule is therefore the supported way to detect upstream
releases without upstream cooperation.

Latency is roughly one to six hours depending on which workflow catches the
release. Trigger either workflow manually when you want it immediately.

## Manual runs

```sh
# Source package update check
gh workflow run aur-update.yml -R NasirA1991/satur8-aur

# Source dry run: render the diff without pushing anywhere
gh workflow run aur-update.yml -R NasirA1991/satur8-aur -f dry_run=true

# Publish a specific upstream release tag
gh workflow run aur-update.yml -R NasirA1991/satur8-aur -f tag=v0.3.3

# Build satur8-bin if it is missing or behind (safe no-op when current)
gh workflow run build-bin.yml -R NasirA1991/satur8-aur

# Force a rebuild and pkgrel bump, e.g. after a KWin upgrade
gh workflow run build-bin.yml -R NasirA1991/satur8-aur -f force=true
```

The `force` rebuild is the binary-package path after the KWin effect ABI moves:
the new tarball is built against current Arch KWin, published under
`satur8-bin-vX.Y.Z-<new pkgrel>`, and the AUR package is updated.

## Required repository secrets

| Secret | Purpose |
| --- | --- |
| `AUR_SSH_PRIVATE_KEY` | Private SSH key authorized on the AUR account (`nasir91`) |
| `AUR_KNOWN_HOSTS` | Pinned AUR SSH host keys, used with `StrictHostKeyChecking=yes` |

Both AUR packages use the same two secrets.

Set or rotate them with:

```sh
gh secret set AUR_SSH_PRIVATE_KEY -R NasirA1991/satur8-aur < ~/.ssh/aur_rawm

ssh-keyscan -t ed25519,rsa aur.archlinux.org > /tmp/aur-known-hosts
gh secret set AUR_KNOWN_HOSTS -R NasirA1991/satur8-aur < /tmp/aur-known-hosts
```

Verify the host keys against the published fingerprints before pinning them:

```sh
ssh-keygen -lf /tmp/aur-known-hosts
# AUR publishes its fingerprints at https://aur.archlinux.org/
```

## Scheduled workflow keepalive

GitHub disables scheduled workflows after 60 days without repository activity.
When there has been no release to publish for about 30 days, the source workflow
commits a timestamp to `.github/last-check` so the schedule stays enabled. The
commit says `chore: keep the scheduled AUR update workflow active` and does not
touch the AUR.

## Local development

```sh
make check      # compare both .SRCINFO files with makepkg --printsrcinfo
make srcinfo    # regenerate both .SRCINFO files
makepkg -si     # build/install the source package (Arch/CachyOS)
(cd satur8-bin && makepkg -si)  # build/install the binary package
```

`makepkg` is required for `make check`; CI uses the small, dependency-free
renderer in `scripts/gen-srcinfo.sh` because GitHub's Ubuntu runners do not ship
`makepkg`.

## Notes

- Architecture: `x86_64` only, matching the upstream release artifacts and the
  CI-built binary tarball.
- Both packages install `satur8`, `satur8-daemon`, `satur8-tray`, and
  `satur8-gui`, the KWin effect plugin and focus script, the GNOME extension,
  the gamescope shader, the app icon, a systemd user unit, and the desktop
  entry.
- KWin's effect ABI is not stable. `satur8` builds the effect against your
  installed KWin (`kwin>=6.8.0` at build time); `satur8-bin` includes an effect
  built against Arch's KWin when CI produced it. After a KWin major upgrade,
  rebuild `satur8` locally or run the `force` binary rebuild above.
- Upstream v0.3.3 predates KWin 6.8. The source PKGBUILD's `prepare()` applies a
  compatibility change for the new `OffscreenEffect::drawWindow` signature and
  adds Qt6 Qml's include path for KWin 6.8 headers. The change is skipped
  automatically once upstream ships the fix. `satur8-bin` is built from that
  same patched source.
- Upstream v0.3.3's KWin focus script ships `metadata.json` without
  `KPackageStructure`, which KWin 6.x rejects with `does not match requested
  format "KWin/Script"`. The script then never loads, so per-game profiles never
  follow focus. `prepare()` adds the key and skips the change once upstream
  ships the fix.
- The GUI's "Add running game" list is built from `/proc/<pid>/exe`, so
  Proton/Wine titles appear as `wine64-preloader` instead of their `.exe` name.
  Add those from the CLI, for example
  `satur8 profile add juvio 1.5 --exe juvio.exe --window-class juvio.exe`.
- Enable the per-game daemon with:

  ```sh
  systemctl --user enable --now satur8-daemon
  ```

## Maintainer

Nasir A. — [@NasirA1991](https://github.com/NasirA1991)
