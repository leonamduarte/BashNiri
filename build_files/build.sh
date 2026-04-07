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
