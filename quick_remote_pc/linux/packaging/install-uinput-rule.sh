#!/bin/sh
# Grants the logged-in user access to /dev/uinput so QuickRemote PC can act as
# a virtual keyboard/mouse (works on X11 and Wayland). Same steps as the
# "İzin ver" button in the app. Run with: sudo ./install-uinput-rule.sh
set -e
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' \
  > /etc/udev/rules.d/70-quickremote-uinput.rules
echo uinput > /etc/modules-load.d/quickremote-uinput.conf
modprobe uinput
udevadm control --reload-rules
udevadm trigger --action=change --sysname-match=uinput
udevadm settle
echo "OK: /dev/uinput is now accessible to the active user."
