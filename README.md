# satur8 — AUR packaging

[AUR package](https://aur.archlinux.org/packages/satur8) for
[Satur8](https://github.com/NtrpyDev/satur8): per-game digital vibrance for Linux.

This repository holds the `PKGBUILD` and `.SRCINFO` that are published to the
AUR, plus the GitHub Actions workflow that keeps the package in sync with
upstream releases.

## Install

```sh
yay -S satur8
# or
paru -S satur8
```

Manual installation:

```sh
git clone https://aur.archlinux.org/satur8.git
cd satur8
makepkg -si
```

The package builds the Rust workspace and the KWin effect from the upstream
release source archive. The KWin effect is compiled against your local KWin/Qt
ABI, which is why this is a source package rather than `-bin`.

Optional backends are declared as `optdepends`:

| Package | Backend |
| --- | --- |
| `kwin` | KDE Plasma Wayland saturation effect |
| `gnome-shell` | GNOME Shell extension |
| `gamescope` | universal fallback shader |
| `nvidia-settings` | NVIDIA X11 Digital Vibrance |

## Automated updates

[`.github/workflows/aur-update.yml`](.github/workflows/aur-update.yml) runs:

- every 6 hours (`17 */6 * * *`), and
- on manual dispatch.

Each run:

1. Reads the latest release from `NtrpyDev/satur8` through the GitHub API.
2. Reads the currently published version from the AUR repository. (The AUR RPC
   index can lag for newly created packages, so the workflow reads `.SRCINFO`
   through the AUR's cgit endpoint instead.)
3. If upstream is newer, verifies the release's source archive:
   - the `.sha256` asset matches GitHub's own asset digest, and
   - the downloaded archive matches that checksum.
4. Updates `pkgver`, resets `pkgrel` to `1`, updates `sha256sums` in
   `PKGBUILD`, and regenerates `.SRCINFO`.
5. Commits the packaging change here and pushes the same files to
   `ssh://aur@aur.archlinux.org/satur8.git`.

AUR is treated as the source of truth for what is already published. If a push
to the AUR fails after the GitHub commit succeeds, the next run sees the AUR is
still behind and retries the publish.

### Why polling instead of an upstream release trigger?

A GitHub Actions workflow in this repository can only receive events from this
repository. GitHub does not let a workflow subscribe to `release` events from
another account's repository, and upstream has no webhook or dispatch setup for
us. Polling the releases API on a schedule is therefore the supported way to
detect upstream releases without upstream cooperation.

The trade-off is latency: a new upstream release is picked up within roughly
six hours (scheduled runs can be delayed by GitHub). Trigger the workflow
manually when you want it immediately.

### Manual runs

```sh
# Normal update check
gh workflow run aur-update.yml -R NasirA1991/satur8-aur

# Check and render the diff without pushing to GitHub or the AUR
gh workflow run aur-update.yml -R NasirA1991/satur8-aur -f dry_run=true

# Publish a specific upstream release tag
gh workflow run aur-update.yml -R NasirA1991/satur8-aur -f tag=v0.3.3
```

### Required repository secrets

| Secret | Purpose |
| --- | --- |
| `AUR_SSH_PRIVATE_KEY` | Private SSH key authorized on the AUR account (`nasir91`) |
| `AUR_KNOWN_HOSTS` | Pinned AUR SSH host keys, used with `StrictHostKeyChecking=yes` |

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

To retire the key, remove it from the AUR account and replace the secret; CI
only needs push access to the AUR repository.

### Scheduled workflow keepalive

GitHub disables scheduled workflows after 60 days without repository activity.
When there has been no release to publish for about 30 days, the workflow
commits a timestamp to `.github/last-check` so the schedule stays enabled. The
commit says `chore: keep the scheduled AUR update workflow active` and does not
touch the AUR.

## Local development

```sh
make check      # compare scripts/gen-srcinfo.sh with makepkg --printsrcinfo
make srcinfo    # regenerate .SRCINFO
makepkg -si     # build and install (Arch/CachyOS)
```

`makepkg` is required for `make check`; the CI update path uses the small,
dependency-free renderer in `scripts/gen-srcinfo.sh` because GitHub's Ubuntu
runners do not ship `makepkg`.

## Notes

- Architecture: `x86_64` only, matching the upstream release artifacts.
- The package installs `satur8`, `satur8-daemon`, `satur8-tray`, and
  `satur8-gui`, the KWin effect plugin and focus script, the GNOME extension,
  the gamescope shader, the app icon, a systemd user unit, and the desktop
  entry.
- KWin's effect ABI is not stable. The package builds the effect against your
  installed KWin and requires `kwin>=6.8.0` at build time. Rebuild the package
  after a KWin major upgrade so the plugin matches the running compositor.
- Upstream v0.3.3 predates KWin 6.8. The PKGBUILD's `prepare()` applies a small
  compatibility change for the new `OffscreenEffect::drawWindow` signature and
  adds Qt6 Qml's include path for KWin 6.8 headers. The change is skipped
  automatically once upstream ships the fix.
- Enable the per-game daemon with:

  ```sh
  systemctl --user enable --now satur8-daemon
  ```

## Maintainer

Nasir A. — [@NasirA1991](https://github.com/NasirA1991)
