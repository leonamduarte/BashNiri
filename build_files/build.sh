#!/usr/bin/bash

set -ouex pipefail

dnf5 install -y \
	niri \
	git \
	neovim \
	fish
