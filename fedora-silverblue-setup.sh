#!/bin/bash

packages=(
  distrobox
  openssl
  lm_sensors
)

sudo rpm-ostree install ${packages[@]}
