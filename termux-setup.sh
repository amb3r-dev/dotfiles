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

debootstrap --make-tarball=$PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz bookworm $PREFIX/tmp/debian-rootfs

read -p "Enter your desired username to be used during setup: " username

cat <<EOF > $PREFIX/etc/proot-distro/debian-${debian_suite}.sh

DISTRO_NAME="Debian ${debian_suite^}"
TARBALL_URL['aarch64']="file://$PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz"
TARBALL_SHA256['aarch64']="$(sha256sum $PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz)"

distro_setup() {
  run_proot_cmd adduser $username
  run_proot_cmd apt update
  run_proot_cmd apt upgrade
}

EOF
