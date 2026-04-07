#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable --never avengemedia/dms

dnf5 install -y \
	niri \
	dms \
	quickshell \
	git \
	neovim \
	fish

mkdir -p /etc/systemd/user
cat >/etc/systemd/user/dms.service <<'EOF'
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

systemctl --user enable dms.service || true
