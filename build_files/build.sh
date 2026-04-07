#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable avengemedia/dms

dnf5 install -y \
	niri \
	dms \
	quickshell \
	git \
	neovim \
	fish

mkdir -p /usr/lib/systemd/user
cat >/usr/lib/systemd/user/dms.service <<'EOF'
[Unit]
Description=DankMaterialShell
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/dms run
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF
