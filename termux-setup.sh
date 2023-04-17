#!/data/data/com.termux/files/usr/bin/bash

debian_suite=bookworm

packages=(
  proot-distro
  debootstrap
  termux-api
  termux-exec
  termux-gui-bash
  termux-gui-package
  termux-gui-pm
  tsu
)

pkg install ${packages[@]}

read -p "Generate new Debian tarball for proot-distro? [y/N]: " answer
[[ $answer =~ ^(Y|y)$ ]] && {
  rm -r $PREFIX/tmp/debian-rootfs
  rm $PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz
  debootstrap --arch=arm64  bookworm $PREFIX/tmp/debian-rootfs
  tar czvf $PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz -C $PREFIX/tmp/debian-rootfs $PREFIX/tmp/debian-rootfs/*
  read -p "Enter your desired username to be used during setup: " username
}

cat <<EOF > $PREFIX/etc/proot-distro/debian-${debian_suite}.sh

DISTRO_NAME="Debian ${debian_suite^}"
TARBALL_URL['aarch64']="file://$PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz"
TARBALL_SHA256['aarch64']="$(sha256sum $PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz | awk '{ print $1 }')"

distro_setup() {
  run_proot_cmd adduser $username
  run_proot_cmd apt update
  run_proot_cmd apt upgrade
}

EOF
