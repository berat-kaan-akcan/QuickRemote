#!/bin/sh
# Packs a `flutter build linux --release` bundle into the release tarball:
#
#   quickremote-pc/                  the bundle (quick_remote_pc, lib/, data/)
#   quickremote-pc/share/            the .desktop file, the icon and
#                                    install-uinput-rule.sh
#
# The .deb (deb/build-deb.sh) and the AUR package (aur/PKGBUILD) are made from
# this layout.
#
# Usage: make-tarball.sh BUNDLE_DIR VERSION OUT_DIR [NAME_SUFFIX]
#   BUNDLE_DIR  build/linux/x64/release/bundle
#   VERSION     0.2.0 (the tag without its v)
#   NAME_SUFFIX e.g. -noupdate for the build made with UPDATE_CHECK=false
# Prints the tarball's path.
set -eu

if [ $# -lt 3 ]; then
  echo "usage: $0 BUNDLE_DIR VERSION OUT_DIR [NAME_SUFFIX]" >&2
  exit 2
fi
bundle=$1
version=$2
out=$3
suffix=${4:-}

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
app_id=com.quickremote.quick_remote_pc

if [ ! -x "$bundle/quick_remote_pc" ]; then
  echo "error: $bundle/quick_remote_pc not found (run flutter build linux --release)" >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
root=$work/quickremote-pc
mkdir -p "$root/share"
cp -a "$bundle/." "$root/"
cp "$here/$app_id.desktop" "$root/share/"
cp "$repo/brand/logo/app-icon.svg" "$root/share/$app_id.svg"
cp "$here/install-uinput-rule.sh" "$root/share/"
chmod 755 "$root/share/install-uinput-rule.sh"

mkdir -p "$out"
out=$(cd "$out" && pwd)
name="quickremote-pc-$version-linux-x64$suffix.tar.gz"
tar -C "$work" --owner=0 --group=0 --numeric-owner -czf "$out/$name" quickremote-pc
echo "$out/$name"
