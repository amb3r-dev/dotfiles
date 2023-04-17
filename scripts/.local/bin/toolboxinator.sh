#!/bin/bash

cat <<"EOF"
 _              _ _               _             _             
| |_ ___   ___ | | |__   _____  _(_)_ __   __ _| |_ ___  _ __ 
| __/ _ \ / _ \| | '_ \ / _ \ \/ / | '_ \ / _` | __/ _ \| '__|
| || (_) | (_) | | |_) | (_) >  <| | | | | (_| | || (_) | |   
.\__\___/.\___/|_|_.__/.\___/_/\_\_|_|.|_|\__,_|\__\___/|_|.. 
::..:...:::...:....:..:::...:.::......:...:..:..:..:...:...:: 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 

EOF

# Installinator: Amber's opinionated dev setup installation script!
# Tested on Debian Bookworm (x86_64)
# Theoretically can be adapted to most distros/package managers

###################
### CONFIG AREA ###
###################

### Config inserts
# Add lines to system configurations like this:
# "/etc/path/to/config;# This line will be added to the end of the given file"
config_lines=(
  # Example entry, which sets the locale
  #"/etc/default/locale;LANG=en_US.UTF-8"
)

### Manual installers:
# Add manual programs like this: 
# "ProgramName;commandname;$icon;$(tput setaf $color)"
_manual_installers=(
  # Install Rust tools using rustup instead of using debian's outdated rust
  "rustup;rustup;;$(tput setaf 1)"
  # makedeb is like makepkg from Arch, but for Debian
  "makedeb;makedeb;🌧️;$(tput setaf 15)"
  # A NeoVim framework that lets me declare my whole setup from one lua file
  "LunarVim;lvim;;$(tput setaf 12)"
)
# After that, define the following function:
#   install_${name} (install the program manually)
# You can also optionally define this one to have this script handle updates:
#   update_${name} (update the program in the standard way)

install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}
update_rustup() { rustup update; }

install_makedeb() {
  sudo apt install git libapt-pkg-dev -y
  # Install makedeb
  if ! hash "makedeb" 2> /dev/null; then
    export MAKEDEB_RELEASE='makedeb'
    bash -c "$(wget -qO - 'https://shlink.makedeb.org/install')"
  fi
}

install_LunarVim() {
  # Github doesn't have a way to grab the latest build with a consistent link
  # nightly.link is here to rescue us from this fact of life
  url="https://nightly.link/LunarVim/LunarVim-mono/workflows/release/master/lvim-linux64.zip"
  wget -O /tmp/lvim-linux64.zip $url
  sudo apt install unzip -y # Just in case we don't already have it
  unzip /tmp/lvim-linux64.zip -d /tmp/
  sudo apt install /tmp/lvim-linux64.deb -y
  rm /tmp/lvim-linux64.*
}

### Package managers:
# Add package managers like this:
# "$name;$icon;$(tput setaf $color)"
_package_managers=(
  "Debian;;$(tput setaf 9)"
  "pipx;;$(tput setaf 14)"
  "Cargo;;$(tput setaf 1)"
  # The MPR is like the AUR but for Debian
  "MPR;;$(tput setaf 14)"
)
# After that, define the following functions:
#   ${name}_check_cmd $1 (check a single package)
#   ${name}_install_cmd $@ (install a list of packages)
#   ${name}_update_cmd (update all packages)
# Then just make an array of packages to install called ${name}_packages

Debian_check_cmd() { dpkg -s $1; }
Debian_install_cmd() { sudo apt install $@ -y; }
Debian_update_cmd() { sudo apt update -y && sudo apt upgrade -y; }
Debian_packages=(
  # CLI Utilities
  man-db tealdeer stow bash-completion fd-find ripgrep htop screen file exa
  # Dev tools
  git-all git-extras gitweb make cmake
  # Languages/Engines
  python3 python3-pip pipx python-is-python3
  # Archive stuff
  atool pbzip2 unzip zip xz-utils p7zip-full
  # Deps
  locales pkgconf openssl libssl-dev
  # Fun stuff
  neofetch
)

MPR_check_cmd() { Debian_check_cmd $1; }
MPR_install_cmd() {
  for package in "$@"; do
    git clone "https://mpr.makedeb.org/$package" /tmp/makedeb_$package
    cd /tmp/makedeb_$package && makedeb -si --no-confirm
  done
  cd && rm -rf /tmp/makedeb_*
}
MPR_update_cmd() { MPR_install_cmd $MPR_packages; }
MPR_packages=(
  # Like Vim but it has lua so it's not slow
  neovim
)

pipx_check_cmd() { [[ -d $HOME/.local/pipx/venvs/$1 ]] && echo $1; }
pipx_install_cmd() { pipx install $@; }
pipx_update_cmd() { pipx upgrade-all; }
pipx_packages=(
  # Editor utility
  neovim-remote
)

Cargo_check_cmd() { cargo install --list | grep $1; }
Cargo_install_cmd() { rustup default nightly && cargo install $@; }
Cargo_update_cmd() { rustup default nightly && cargo install-update -a; }
Cargo_packages=(
  # We need this to update all cargo packages at once
  cargo-update
  # CLI Utilities
  bottom starship 
)

### Finish up commands
# Add finishing commands to this array
finish_commands=(
  "sudo dpkg-reconfigure locales"
)

#######################
### END CONFIG AREA ###
#######################

# Function to check for missing packages and install them.
# Requires $1 to be a single string argument with three fields separated by ";"
__process_package_manager() {
  # Split up the string
  IFS=';' read name icon color <<< "$1"
  packages="${name}_packages[@]"
  for package in ${!packages}; do
    # Check if package is missing
    if [[ -z "$(${name}_check_cmd $package 2> /dev/null)" ]]; then
      [[ $ASSUME_YES != 1 ]] && read -p "You're missing some $name packages. Install now? [Y/n]: " answer || answer=Y
      [[ $answer =~ ^(Y|y|"")$ ]] && ${name}_install_cmd ${!packages} || return
    fi
  done
  bold=$(tput bold && tput smul)
  echo "$color$icon$(tput sgr0) All $bold$color$name$(tput sgr0) packages are installed!"
}

# Function to check for missing non-packaged software and install it.
# Requires $1 to be a single string argument with five fields separated by ";"
__process_manual_installer() {
  bold=$(tput bold && tput smul)
  # Split up the string
  IFS=';' read name executable icon color <<< "$1"
  # Check if executable file is missing
  if ! hash "$executable" 2> /dev/null; then
    [[ $ASSUME_YES != 1 ]] && read -p "You're missing $name. Install now? [Y/n]: " answer || answer=Y
    [[ $answer =~ ^(Y|y|"")$ ]] && install_$name || return
  fi 
  echo "$color$icon $bold$name$(tput sgr0) is installed!"
}

## Checker Functions

# Function to loop through config lines to add
_config_lines_check() {
  echo "Setting system configurations..."
  for cl in ${config_lines[@]}; do
    [[ $ASSUME_YES != 1 ]] && read -p "Check for missing configuration lines? [Y/n]: " answer || answer=Y
    [[ $answer =~ ^(Y|y|"")$ ]] || return
    IFS=';' read path config_line <<< "$cl"
    if ! grep -q "$config_line" "$path"; then
      echo "1 line missing from path $path"
      sudo echo "$config_line" | sudo tee -a $path
    else
      echo "1 line already in $path"
    fi
  done
}

# Function to loop through package managers to check
_package_managers_check() { 
  echo "Checking package managers..."
  for pm in ${_package_managers[@]}; do
    __process_package_manager $pm
  done
}

# Function to loop through manually installed programs to check
_manual_installers_check() {
  echo "Checking manual installers..."
  for mi in ${_manual_installers[@]}; do
    __process_manual_installer $mi
  done
}

# Function to loop through finishing commands to run at the end
_finishing_commands_check() {
  [[ $ASSUME_YES != 1 ]] && read -p "Do you want to run post-install setup commands? [y/N]: " answer || answer=Y
  [[ $answer =~ ^(Y|y)$ ]] || return
  for fc in "${finish_commands[@]}"; do
    $fc
  done
}

_reinstall_non_updateable() {
  for mi in ${_manual_installers[@]}; do
    IFS=';' read name executable icon color <<< "$mi"
    # Only run for manual installers with no update function
    if ! hash "update_${name}" 2> /dev/null; then
      [[ $ASSUME_YES != 1 ]] && read -p "Reinstall $name? [Y/n]: " answer || answer=Y
      [[ $answer =~ ^(Y|y|"")$ ]] && install_$name || continue
    fi
  done && echo "Manual packages reinstalled!"
}

_update_all() {
  [[ $ASSUME_YES != 1 ]] && read -p "Run all updates too? [Y/n]: " answer || answer=Y
  [[ $answer =~ ^(Y|y|"")$ ]] && ${name}_install_cmd ${!packages} || return
  for pm in ${_package_managers[@]}; do
    IFS=';' read name icon color <<< "$pm"
    ${name}_update_cmd
  done
  for mi in ${_manual_installers[@]}; do
    IFS=';' read name executable icon color <<< "$mi"
    if hash update_${name} 2> /dev/null; then
      update_${name}
    fi
  done
  echo "All updates are installed!"
}

##########################
### MAIN PROGRAM START ###
##########################

for opt in $(getopt -o "hury" --long "help,update,reinstall,assume-yes" -- $@); do
  case ${opt} in
    -h | --help ) HELP=1 ;;	    
    -u | --update ) UPDATE=1;;
    -r | --reinstall ) REINSTALL=1 ;;	    
    -y | --assume-yes ) ASSUME_YES=1 ;;
  esac
done

help_text="\
USAGE:
    toolboxinator.sh [flags]

FLAGS:
    -h/--help
        Display this help text.
    -u/--update
        Update all packages, and all manual programs which have an update function.
    -r/--reinstall
        Reinstall & update manual programs with no update function.
        (Programs with an update funciton are skipped.)
    -y/--assume-yes
        Skips all confirmation prompts.
"

[[ $HELP == 1 ]] && echo "$help_text" && exit

# Manual installers first, because rustup is required for Cargo
_config_lines_check
_manual_installers_check 
_package_managers_check
[[ $UPDATE == 1 ]] && _update_all
[[ $REINSTALL == 1 ]] && _reinstall_non_updateable
_finishing_commands_check
