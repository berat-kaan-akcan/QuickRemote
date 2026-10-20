#!/bin/sh
# Builds quickremote-pc_VERSION_amd64.deb from the release tarball
# (../make-tarball.sh):
#
#   /opt/quickremote-pc/                       the Flutter bundle
#   /usr/bin/quick_remote_pc                   -> /opt/quickremote-pc/quick_remote_pc
#   /usr/share/applications/com.quickremote.quick_remote_pc.desktop
#   /usr/share/icons/hicolor/scalable/apps/com.quickremote.quick_remote_pc.svg
#   /usr/lib/udev/rules.d/70-quickremote-uinput.rules  the /dev/uinput rule
#   /usr/lib/modules-load.d/quickremote-uinput.conf    (as LinuxSetup and
#                                                       install-uinput-rule.sh
#                                                       write them to /etc)
#
# The rule is a package file, so dpkg removes it with the package; postinst
# only applies it now.
#
# Usage: build-deb.sh TARBALL VERSION OUT_DIR
# Needs dpkg-deb. Prints the package's path.
set -eu

if [ $# -ne 3 ]; then
  echo "usage: $0 TARBALL VERSION OUT_DIR" >&2
  exit 2
fi
tarball=$1
# Debian sorts "~" before anything, so 0.2.0~beta.1 comes before 0.2.0.
version=$(printf '%s' "$2" | tr '-' '~')
out=$3

here=$(cd "$(dirname "$0")" && pwd)
app_id=com.quickremote.quick_remote_pc

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -C "$work" -xzf "$tarball"
src=$work/quickremote-pc
pkg=$work/pkg

mkdir -p "$pkg/DEBIAN" "$pkg/opt" "$pkg/usr/bin" \
  "$pkg/usr/share/applications" \
  "$pkg/usr/share/icons/hicolor/scalable/apps" \
  "$pkg/usr/lib/udev/rules.d" "$pkg/usr/lib/modules-load.d"

install -m 644 "$src/share/$app_id.desktop" "$pkg/usr/share/applications/"
install -m 644 "$src/share/$app_id.svg" "$pkg/usr/share/icons/hicolor/scalable/apps/"
# The rule line is the one in install-uinput-rule.sh (and LinuxSetup).
rule=$(grep -o "KERNEL==\"uinput\".*static_node=uinput\"" "$src/share/install-uinput-rule.sh")
[ -n "$rule" ] || { echo "error: no udev rule in install-uinput-rule.sh" >&2; exit 1; }
printf '%s\n' "$rule" > "$pkg/usr/lib/udev/rules.d/70-quickremote-uinput.rules"
echo uinput > "$pkg/usr/lib/modules-load.d/quickremote-uinput.conf"
chmod 644 "$pkg/usr/lib/udev/rules.d/70-quickremote-uinput.rules" "$pkg/usr/lib/modules-load.d/quickremote-uinput.conf"
rm -rf "$src/share"
mv "$src" "$pkg/opt/quickremote-pc"
# Flutter finds data/ and lib/ next to the resolved /proc/self/exe, so a
# symlink on the PATH works.
ln -s /opt/quickremote-pc/quick_remote_pc "$pkg/usr/bin/quick_remote_pc"

size=$(du -sk --exclude=DEBIAN "$pkg" | cut -f1)
sed -e "s/@VERSION@/$version/" -e "s/@SIZE@/$size/" "$here/control.in" > "$pkg/DEBIAN/control"
install -m 755 "$here/postinst" "$here/postrm" "$pkg/DEBIAN/"

mkdir -p "$out"
out=$(cd "$out" && pwd)
deb="$out/quickremote-pc_${version}_amd64.deb"
dpkg-deb --root-owner-group -Zxz --build "$pkg" "$deb" > /dev/null
echo "$deb"
