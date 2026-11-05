#!/usr/bin/env bash
# Render the AUR .SRCINFO for a package directory in this repository.
#
# Usage: scripts/gen-srcinfo.sh [package-dir]
#   package-dir defaults to the repository root (the `satur8` package).
#
# AUR requires a .SRCINFO next to the PKGBUILD. makepkg --printsrcinfo is the
# canonical generator, but the update workflows run on Ubuntu where makepkg is
# not available. This small renderer covers the fields these packages use and
# is kept byte-for-byte compatible with `makepkg --printsrcinfo` (see
# `make check`).
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repo_root"

package_dir="${1:-.}"
if [[ ! -f "${package_dir}/PKGBUILD" ]]; then
    echo "error: no PKGBUILD in ${package_dir}" >&2
    exit 1
fi
cd -- "${package_dir}"

# PKGBUILD is trusted repository data.
# shellcheck disable=SC1091
source ./PKGBUILD

if [[ "$(declare -p pkgname 2>/dev/null)" == "declare -a"* ]]; then
    echo "error: split packages are not supported by scripts/gen-srcinfo.sh" >&2
    exit 1
fi

print_scalar() {
    printf '\t%s = %s\n' "$1" "$2"
}

print_array() {
    local field="$1"
    local -n values="$2"
    local value
    for value in "${values[@]}"; do
        print_scalar "$field" "$value"
    done
}

printf 'pkgbase = %s\n' "$pkgname"
print_scalar pkgdesc "$pkgdesc"
print_scalar pkgver "$pkgver"
print_scalar pkgrel "$pkgrel"
[[ -n "${epoch:-}" ]] && print_scalar epoch "$epoch"
print_scalar url "$url"
[[ -n "${install:-}" ]] && print_scalar install "$install"
[[ -n "${changelog:-}" ]] && print_scalar changelog "$changelog"
print_array arch arch
[[ -n "${groups[*]:-}" ]] && print_array groups groups
print_array license license
[[ -n "${checkdepends[*]:-}" ]] && print_array checkdepends checkdepends
print_array makedepends makedepends
print_array depends depends
[[ -n "${optdepends[*]:-}" ]] && print_array optdepends optdepends
[[ -n "${provides[*]:-}" ]] && print_array provides provides
[[ -n "${conflicts[*]:-}" ]] && print_array conflicts conflicts
[[ -n "${replaces[*]:-}" ]] && print_array replaces replaces
[[ -n "${noextract[*]:-}" ]] && print_array noextract noextract
[[ -n "${options[*]:-}" ]] && print_array options options
[[ -n "${backup[*]:-}" ]] && print_array backup backup
print_array source source
[[ -n "${validpgpkeys[*]:-}" ]] && print_array validpgpkeys validpgpkeys
print_array sha256sums sha256sums

printf '\npkgname = %s\n' "$pkgname"
