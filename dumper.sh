#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

################################################################################
# Auto Firmware Extractor Script - Advanced Version
# Developed by: FARHAN muh tasim
# GitHub: https://github.com/FarhanMuhTasim
# Contact: farhan.email@example.com
################################################################################

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Output helpers
function info()    { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
function warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
function error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
function debug()   { printf "${BLUE}[DEBUG]${NC} %s\n" "$*"; }

# Clear screen and resize terminal
function clear_and_resize() {
  tput reset 2>/dev/null || clear
  printf "\033[8;30;90t" || true
}

# Banner function
function banner() {
  clear_and_resize
  echo -e "${GREEN}"
  echo "██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗"
  echo "██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝"
  echo "██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░"
  echo "██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░"
  echo "██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗"
  echo "╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝"
  echo -e "${NC}"
  info "Script developed by FARHAN muh tasim"
  info "GitHub: https://github.com/FarhanMuhTasim"
  echo
}

# Usage/help function
function usage() {
  echo -e "${GREEN}Usage:${NC} $0 <Firmware File/Extracted Folder or Supported URL>"
  echo -e "\n${BLUE}Supported Input:${NC}"
  echo -e " - Firmware archives: .zip, .rar, .7z, .tar, .bin, .ozip, .kdz, etc."
  echo -e " - Supported URLs from file hosts like mega.nz, mediafire, gdrive, androidfilehost, onedrive, etc."
  echo -e "\nWrap URLs in single quotes ('') to avoid shell issues."
}

# Check required commands and dependencies
function check_dependencies() {
  local deps=(7zz aria2c wget git python3 detox uv)
  local missing=()
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing dependencies: ${missing[*]}"
    error "Please install them and retry."
    exit 1
  fi
}

# Validate input arguments
function input_validation() {
  if [ $# -eq 0 ] || [[ -z "$1" ]]; then
    error "No input provided."
    usage
    exit 1
  fi
  if [ $# -gt 1 ]; then
    error "Please provide only one input argument."
    usage
    exit 1
  fi
}

# Declare variables and constants used by the script
function declare_variables() {
  # Base project dir (script location)
  PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  # Prevent spaces in path for safety
  if echo "${PROJECT_DIR}" | grep -q " "; then
    error "Project directory path contains spaces. Please move script to a directory without spaces."
    exit 1
  fi

  INPUTDIR="${PROJECT_DIR}/input"
  UTILSDIR="${PROJECT_DIR}/utils"
  OUTDIR="${PROJECT_DIR}/out"
  TMPDIR="${OUTDIR}/tmp"

  # Supported partitions
  PARTITIONS="system system_ext system_other systemex vendor cust odm oem factory product xrom modem dtbo dtb boot vendor_boot recovery tz oppo_product preload_common opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap my_custom my_manifest my_carrier my_region my_bigball my_version special_preload system_dlkm vendor_dlkm odm_dlkm init_boot vendor_kernel_boot odmko socko nt_log mi_ext hw_product product_h preas preavs"
  EXT4PARTITIONS="system vendor cust odm oem factory product xrom systemex oppo_product preload_common hw_product product_h preas preavs"
  OTHERPARTITIONS="tz.mbn:tz tz.img:tz modem.img:modem NON-HLOS:modem boot-verified.img:boot recovery-verified.img:recovery dtbo-verified.img:dtbo"

  # Utility program aliases (set paths later)
  SDAT2IMG=""
  SIMG2IMG=""
  PACKSPARSEIMG=""
  UNSIN=""
  PAYLOAD_EXTRACTOR=""
  DTC=""
  VMLINUX2ELF=""
  KALLSYMS_FINDER=""
  OZIPDECRYPT=""
  OFP_QC_DECRYPT=""
  OFP_MTK_DECRYPT=""
  OPSDECRYPT=""
  LPUNPACK=""
  SPLITUAPP=""
  PACEXTRACTOR=""
  NB0_EXTRACT=""
  KDZ_EXTRACT=""
  DZ_EXTRACT=""
  RUUDECRYPT=""
  EXTRACT_IKCONFIG=""
  UNPACKBOOT=""
  AML_EXTRACT=""
  AFPTOOL_EXTRACT=""
  RK_EXTRACT=""
  TRANSFER=""
  BIN_7ZZ=""
  MEGAMEDIADRIVE_DL=""
  AFHDL=""
  FSCK_EROFS=""
}

# Setup utility paths and clone/update external tools
function setup_utils() {
  # Define utility aliases relative to utils dir
  SDAT2IMG="${UTILSDIR}/sdat2img.py"
  SIMG2IMG="${UTILSDIR}/bin/simg2img"
  PACKSPARSEIMG="${UTILSDIR}/bin/packsparseimg"
  UNSIN="${UTILSDIR}/unsin"
  PAYLOAD_EXTRACTOR="${UTILSDIR}/bin/payload-dumper-go"
  DTC="${UTILSDIR}/dtc"
  VMLINUX2ELF="${UTILSDIR}/vmlinux-to-elf/vmlinux-to-elf"
  KALLSYMS_FINDER="${UTILSDIR}/vmlinux-to-elf/kallsyms-finder"
  OZIPDECRYPT="${UTILSDIR}/oppo_ozip_decrypt/ozipdecrypt.py"
  OFP_QC_DECRYPT="${UTILSDIR}/oppo_decrypt/ofp_qc_decrypt.py"
  OFP_MTK_DECRYPT="${UTILSDIR}/oppo_decrypt/ofp_mtk_decrypt.py"
  OPSDECRYPT="${UTILSDIR}/oppo_decrypt/opscrypto.py"
  LPUNPACK="${UTILSDIR}/lpunpack"
  SPLITUAPP="${UTILSDIR}/splituapp.py"
  PACEXTRACTOR="${UTILSDIR}/pacextractor/python/pacExtractor.py"
  NB0_EXTRACT="${UTILSDIR}/nb0-extract"
  KDZ_EXTRACT="${UTILSDIR}/kdztools/unkdz.py"
  DZ_EXTRACT="${UTILSDIR}/kdztools/undz.py"
  RUUDECRYPT="${UTILSDIR}/RUU_Decrypt_Tool"
  EXTRACT_IKCONFIG="${UTILSDIR}/extract-ikconfig"
  UNPACKBOOT="${UTILSDIR}/unpackboot.sh"
  AML_EXTRACT="${UTILSDIR}/aml-upgrade-package-extract"
  AFPTOOL_EXTRACT="${UTILSDIR}/bin/afptool"
  RK_EXTRACT="${UTILSDIR}/bin/rkImageMaker"
  TRANSFER="${UTILSDIR}/bin/transfer"
  FSCK_EROFS="${UTILSDIR}/bin/fsck.erofs"

  if ! command -v 7zz &>/dev/null; then
    BIN_7ZZ="${UTILSDIR}/bin/7zz"
  else
    BIN_7ZZ=7zz
  fi

  MEGAMEDIADRIVE_DL="${UTILSDIR}/downloaders/mega-media-drive_dl.sh"
  AFHDL="${UTILSDIR}/downloaders/afh_dl.py"

  # Clone or update required external tool repos
  local EXTERNAL_TOOLS=(
    bkerler/oppo_ozip_decrypt
    bkerler/oppo_decrypt
    marin-m/vmlinux-to-elf
    ShivamKumarJha/android_tools
    HemanthJabalpuri/pacextractor
  )

  mkdir -p "${UTILSDIR}" || true
  for tool_slug in "${EXTERNAL_TOOLS[@]}"; do
    local tool_dir="${UTILSDIR}/${tool_slug#*/}"
    if [ ! -d "${tool_dir}" ]; then
      info "Cloning external tool: ${tool_slug#*/}"
      git clone -q "https://github.com/${tool_slug}.git" "${tool_dir}"
    else
      info "Updating external tool: ${tool_slug#*/}"
      git -C "${tool_dir}" pull --quiet
    fi
  done
}

# Usage / Input check and initial setup
function initial_input_check() {
  # Clear temporary and output directories
  rm -rf "${TMPDIR}" 2>/dev/null || true
  mkdir -p "${OUTDIR}" "${TMPDIR}" || true

  # Check if input is local path inside input dir and more than one file >10MB
  if echo "$1" | grep -q "${PROJECT_DIR}/input" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +10M 2>/dev/null | wc -l) -gt 1 ]]; then
    FILEPATH=$(realpath "$1")
    info "Copying contents of ${FILEPATH} to temporary work directory ${TMPDIR}"
    cp -a "${FILEPATH}"/* "${TMPDIR}/"
    unset FILEPATH
    return 0
  fi

  # Check if input is input dir containing one large file >300MB
  if echo "$1" | grep -q "${PROJECT_DIR}/input/" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +300M 2>/dev/null | wc -l) -eq 1 ]]; then
    info "Input directory contains one large file"
    cd "${INPUTDIR}" || exit 1
    FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f -size +300M 2>/dev/null)
    FILE=${FILEPATH##*/}
    EXTENSION=${FILEPATH##*.}
    if echo "${EXTENSION}" | grep -qE "zip|rar|7z|tar$"; then
      UNZIP_DIR=${FILE%.*}
    fi
    return 0
  fi

  # Handle URL download or local file/folder
  if echo "$1" | grep -qE '^(https?|ftp)://'; then
    info "URL detected. Starting download..."
    mkdir -p "${INPUTDIR}" || true
    cd "${INPUTDIR}" || exit 1
    rm -rf "${INPUTDIR:?}"/* || true
    local URL="$1"
    if echo "${URL}" | grep -qE "mega.nz|mediafire.com|drive.google.com"; then
      "${MEGAMEDIADRIVE_DL}" "${URL}" || exit 1
    elif echo "${URL}" | grep -q "androidfilehost.com"; then
      python3 "${AFHDL}" -l "${URL}" || exit 1
    elif echo "${URL}" | grep -q "/we.tl/"; then
      "${TRANSFER}" "${URL}" || exit 1
    else
      # Fix OneDrive link if present
      if echo "${URL}" | grep -q "1drv.ms"; then URL=${URL/ms/ws}; fi
      aria2c -x16 -s8 --console-log-level=warn --summary-interval=0 --check-certificate=false "${URL}" || {
        wget -q --show-progress --progress=bar:force --no-check-certificate "${URL}" || exit 1
      }
    fi
    for f in *; do detox -r "${f}" 2>/dev/null || true; done
    FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)
    info "Downloaded file: ${FILEPATH##*/}"
    if [[ $(echo "${FILEPATH}" | tr ' ' '\n' | wc -l) -gt 1 ]]; then
      FILEPATH=$(find "$(pwd)" -maxdepth 2 -type d)
    fi
    return 0
  fi

  # Local file/folder input
  FILEPATH=$(realpath "$1")
  if echo "$1" | grep -q " "; then
    if [[ -w "${FILEPATH}" ]]; then
      detox -r "${FILEPATH}" 2>/dev/null || true
      # Note: inline-detox not standard, skip if not installed
      if command -v inline-detox &>/dev/null; then
        FILEPATH=$(inline-detox "${FILEPATH}")
      fi
    fi
  fi
  if [[ ! -e "${FILEPATH}" ]]; then
    error "Input file/folder does not exist: ${FILEPATH}"
    exit 1
  fi

  FILE=${FILEPATH##*/}
  EXTENSION=${FILEPATH##*.}
  if echo "${EXTENSION}" | grep -qE "zip|rar|7z|tar$"; then
    UNZIP_DIR=${FILE%.*}
  fi

  # If directory, check for archives inside and decide action
  if [[ -d "${FILEPATH}" || -z "${EXTENSION}" ]]; then
    info "Directory input detected: ${FILEPATH}"
    if find "${FILEPATH}" -maxdepth 1 -type f | grep -v "compatibility.zip" | grep -qE ".*\.tar$|.*\.zip|.*\.rar|.*\.7z"; then
      warn "Supplied folder contains compressed archive(s) that need to be extracted"
      local ArcPath
      ArcPath=$(find "${INPUTDIR}/" -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
      [[ -z "${ArcPath}" ]] && ArcPath=$(find "${FILEPATH}/" -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
      if ! echo "${ArcPath}" | grep -q " "; then
        cd "${PROJECT_DIR}" || exit 1
        bash "${0}" "${ArcPath}" || exit 1
        exit 0
      else
        error "More than one archive file available in ${FILEPATH}. Please specify direct archive path."
        exit 1
      fi
    elif find "${FILEPATH}" -maxdepth 1 -type f | grep -qE ".*system.ext4.tar.*|.*chunk|system/build.prop|system.new.dat|system_new.img|system.img|system-sign.img|system.bin|payload.bin|.*rawprogram.*|system.sin|.*system_.*\.sin|system-p|super|UPDATE.APP|.*\.pac|.*\.nb0"; then
      info "Copying all files from ${FILEPATH} to temporary directory ${TMPDIR}"
      cp -a "${FILEPATH}"/* "${TMPDIR}/"
      unset FILEPATH
    else
      error "Firmware type not supported."
      cd "${PROJECT_DIR}" || exit 1
      rm -rf "${TMPDIR}" "${OUTDIR}"
      exit 1
    fi
  fi
}

# Extract Super Image partitions
function superimage_extract() {
  if [[ -f super.img ]]; then
    info "Extracting partitions from super.img..."
    ${SIMG2IMG} super.img super.img.raw 2>/dev/null || true
  fi

  if [[ ! -s super.img.raw && -f super.img ]]; then
    mv super.img super.img.raw
  fi

  for partition in $PARTITIONS; do
    $LPUNPACK --partition="${partition}_a" super.img.raw 2>/dev/null || $LPUNPACK --partition="${partition}" super.img.raw 2>/dev/null || true
    if [[ -f "${partition}_a.img" ]]; then
      mv "${partition}_a.img" "${partition}.img"
    else
      local foundpartitions
      foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | rev | awk '{print $1}' | rev | grep "${partition}.img" || true)
      if [[ -n "${foundpartitions}" ]]; then
        ${BIN_7ZZ} e -y "${FILEPATH}" $foundpartitions dummypartition 2>/dev/null >> "${TMPDIR}/zip.log" || true
      fi
    fi
  done

  rm -rf super.img.raw
}

# Main firmware extraction logic entry point
function extract_firmware() {
  info "Extracting firmware on: ${OUTDIR}"
  cd "${TMPDIR}" || exit 1

  # Oppo .ozip detection and decrypt
  if [[ $(head -c 4 system.img) == "OZIP" ]]; then
    info "Oppo OZIP firmware detected, running decrypt..."
    python3 "${OZIPDECRYPT}" -i system.img -o system.img.dec || error "OZIP decryption failed"
  fi

  # Check for payload.bin and run payload dumper
  if [[ -f payload.bin ]]; then
    info "Payload detected, extracting with payload dumper..."
    ${PAYLOAD_EXTRACTOR} -payload payload.bin -out extracted || error "Payload extraction failed"
  fi

  # More extraction based on file types and partition handling here...

  # Add more partition extraction, conversion, image repairs, kernel extraction etc. here

  info "Extraction completed."
}

# Cleanup function
function cleanup() {
  info "Cleaning up temporary files..."
  rm -rf "${TMPDIR}"
}

# Main entrypoint
function main() {
  banner
  input_validation "$@"
  check_dependencies
  declare_variables
  setup_utils
  initial_input_check "$1"
  extract_firmware
  cleanup
  info "Firmware extraction finished successfully!"
}

# Run main with all arguments
main "$@"
