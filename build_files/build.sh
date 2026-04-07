#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable avengemedia/dms

dnf5 install -y \
	niri \
	dms \
	git \
	neovim \
	fish

dnf5 -y copr disable avengemedia/dms
