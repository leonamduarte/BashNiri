#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable avengemedia/dms || true

dnf5 install -y \
	niri \
	dms \
	quickshell \
	git \
	neovim \
	fish \
	cups-pk-helper \
	gnome-terminal \
	alacritty \
	cava \
	chezmoi \
	lazygit \
	yazi \
	eza \
	bat \
	fzf \
	zoxide \
	podman \
	docker \
	nodejs \
	npm \
	rust \
	kubectl \
	helm

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

# Clone and apply dotfiles
if [ -d /run/host ]; then
	mkdir -p /root
	cd /root
	git clone https://github.com/leonamduarte/dotfiles.git .local/share/chezmoi
	HOME=/root chezmoi apply
fi

# Set fish as default shell
if [ -f /usr/bin/fish ]; then
	echo /usr/bin/fish | tee -a /etc/shells
	for user in $(awk -F: '/\/bin\/bash/ {print $1}' /etc/passwd); do
		chsh -s /usr/bin/fish "$user" 2>/dev/null || true
	done
fi
