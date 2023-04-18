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

### Debian proot-distro setup
debian_tarball_location=$PREFIX/etc/proot-distro/debian-${debian_suite}-rootfs.tar.gz
debian_tmp_rootfs=$PREFIX/tmp/debian-rootfs

# Create the Debian tarball
read -p "Generate new Debian ${debian_suite^} tarball for proot-distro? [y/N]: " answer
[[ $answer =~ ^(Y|y)$ ]] && {
  # Clear out the old stuff
  rm -r $debian_tmp_rootfs
  rm $debian_tarball_location
  # Make the tarball
  debootstrap --arch=arm64  bookworm $debian_tmp_rootfs
  cd $debian_tmp_rootfs && tar czvf $debian_tarball_location ./*
}

# Create the proot-distro plugin script
read -p "Generate new Debian ${debian_suite^} script for proot-distro? [y/N]: " answer
[[ $answer =~ ^(Y|y)$ ]] && {
  # Get the default user's name
  read -p "Enter your desired username to be used during setup: " username
  cat << EOF > $PREFIX/etc/proot-distro/debian-${debian_suite}.sh
DISTRO_NAME="Debian ${debian_suite^}"
TARBALL_URL['aarch64']="file://$debian_tarball_location"
TARBALL_SHA256['aarch64']="$(sha256sum $debian_tarball_location | awk '{ print $1 }')"

distro_setup() {
  # Needed for some reason
  run_proot_cmd apt reinstall passwd
  run_proot_cmd useradd -m $username -G sudo
}
EOF
}
