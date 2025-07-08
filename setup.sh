#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

################################################################################
# Auto Firmware Dumper + Dependency Installer Script
# Developed by: Farhan muh tasim
# GitHub: https://github.com/frnwot
# Contact: ffjisan804@gmail.com
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NORMAL='\033[0m'

# Abort Function
function abort(){
    [ ! -z "$@" ] && echo -e "${RED}${@}${NORMAL}"
    exit 1
}

# Clear Screen and Banner
function clear_and_banner() {
    tput reset 2>/dev/null || clear
    echo -e "${GREEN}"
    echo "██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗"
    echo "██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝"
    echo "██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░"
    echo "██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░"
    echo "██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗"
    echo "╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝"
    echo -e "${NORMAL}"
    echo -e "${GREEN}Script developed by Farhan muh tasim${NORMAL}"
    echo -e "${GREEN}GitHub: https://github.com/frnwot${NORMAL}"
    echo -e "${GREEN}Contact: ffjisan804@gmail.com${NORMAL}"
    echo
}

# Dependency installer
function install_dependencies() {
    clear_and_banner
    sleep 1

    echo -e "${PURPLE}Detecting your OS and package manager...${NORMAL}"
    sleep 1

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt > /dev/null 2>&1; then
            echo -e "${PURPLE}Ubuntu/Debian Based Distro Detected${NORMAL}"
            sleep 1
            echo -e "${BLUE}>> Updating apt repos...${NORMAL}"
            sleep 1
            sudo apt -y update || abort "Setup Failed!"
            sleep 1
            echo -e "${BLUE}>> Installing Required Packages...${NORMAL}"
            sleep 1
            sudo apt install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract device-tree-compiler liblzma-dev python3-pip brotli liblz4-tool axel gawk aria2 detox cpio rename liblz4-dev jq git-lfs || abort "Setup Failed!"
        elif command -v dnf > /dev/null 2>&1; then
            echo -e "${PURPLE}Fedora Based Distro Detected${NORMAL}"
            sleep 1
            echo -e "${BLUE}>> Installing Required Packages...${NORMAL}"
            sleep 1
            sudo dnf install -y unace unrar zip unzip sharutils uudeview arj cabextract file-roller dtc python3-pip brotli axel aria2 detox cpio lz4 python3-devel xz-devel p7zip p7zip-plugins git-lfs || abort "Setup Failed!"
        elif command -v pacman > /dev/null 2>&1; then
            echo -e "${PURPLE}Arch or Arch Based Distro Detected${NORMAL}"
            sleep 1
            echo -e "${BLUE}>> Installing Required Packages...${NORMAL}"
            sleep 1
            sudo pacman -Syyu --needed --noconfirm >/dev/null || abort "Setup Failed!"
            sudo pacman -Sy --noconfirm unace unrar p7zip sharutils uudeview arj cabextract file-roller dtc brotli axel gawk aria2 detox cpio lz4 jq git-lfs || abort "Setup Failed!"
        else
            abort "Unsupported Linux distribution or missing package manager."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${PURPLE}macOS Detected${NORMAL}"
        sleep 1
        echo -e "${BLUE}>> Installing Required Packages...${NORMAL}"
        sleep 1
        brew install protobuf xz brotli lz4 aria2 detox coreutils p7zip gawk git-lfs || abort "Setup Failed!"
    else
        abort "Unsupported OS: $OSTYPE"
    fi

    sleep 1
    echo -e "${BLUE}>> Installing uv for python packages...${NORMAL}"
    sleep 1
    bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "Setup Failed!"

    echo -e "${GREEN}Setup Complete!${NORMAL}"
    echo
}

# Function to check required binaries (you can expand this as needed)
function check_required_commands() {
    local cmds=(7zz aria2c wget git python3 detox)
    local missing=()
    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NORMAL}"
        echo -e "${RED}Please run this script with 'install' argument to install dependencies:${NORMAL}"
        echo -e "${BLUE}  $0 install${NORMAL}"
        exit 1
    fi
}

# Banner and usage
function usage() {
    clear_and_banner
    echo -e "${GREEN}Usage:${NORMAL} $0 [install|extract] <input_file_or_url>"
    echo -e "\nOptions:"
    echo -e "  install              Install all required dependencies"
    echo -e "  extract <input>      Run firmware extraction with the given input file or URL"
    echo -e "\nExample:"
    echo -e "  $0 install"
    echo -e "  $0 extract 'https://example.com/firmware.zip'"
    exit 1
}

# --- Firmware Extraction Logic Stub ---
function firmware_extraction() {
    local input="$1"
    check_required_commands
    clear_and_banner
    echo -e "${GREEN}Starting firmware extraction for: ${input}${NORMAL}"
    sleep 1

    # TODO: Paste your full extraction logic here, or call other functions.
    # For now just a placeholder:
    echo -e "${BLUE}Pretending to extract firmware from ${input}...${NORMAL}"
    sleep 2

    echo -e "${GREEN}Extraction completed successfully.${NORMAL}"
}

# --- Main Entrypoint ---
if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    install)
        install_dependencies
        ;;
    extract)
        if [[ $# -lt 2 ]]; then
            usage
        fi
        firmware_extraction "$2"
        ;;
    *)
        usage
        ;;
esac

exit 0
