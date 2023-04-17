#!/data/data/com.termux/files/usr/bin/bash

packages=(
  proot-distro
  termux-api
  termux-exec
  termux-gui-bash
  termux-gui-package
  termux-gui-pm
  tsu
)

pkg install ${packages[@]}
