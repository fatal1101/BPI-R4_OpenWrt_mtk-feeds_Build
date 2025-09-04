#!/bin/bash
# ==================================================================================
# BPI-R4 - OpenWrt with MTK-Feeds Build Script (Modular)
# ==================================================================================
# This script clones OpenWrt and the Mediatek feeds into separate directories,
# allowing for specific commits to be used for each. It then applies patches
# from dedicated 'openwrt-patches' and 'mtk-patches' directories.
#
# Build system Install Note  - Run on Ubuntu 24.04 or later
#                            - sudo apt update
#                            - sudo apt install dos2unix rsync
# Usage:
#
#   ./build_mtk.sh
#   ./build_mtk.sh -b openwrt-24.10
#
# ==================================================================================

set -euo pipefail

# --- Dependency Check ---
if ! command -v dos2unix &> /dev/null; then
    echo "ERROR: 'dos2unix' is not installed. Please run 'sudo apt update && sudo apt install dos2unix'." >&2
    exit 1
fi
if ! command -v rsync &> /dev/null; then
    echo "ERROR: 'rsync' is not installed. Please run 'sudo apt update && sudo apt install rsync'." >&2
    exit 1
fi

# --- Main Configuration ---

# OpenWrt Source Details
readonly OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
OPENWRT_BRANCH="openwrt-24.10"
# To build a specific commit, paste the full hash here. Leave empty for the latest.
readonly OPENWRT_COMMIT=""

# Mediatek Feeds Source Details
readonly MTK_FEEDS_REPO="https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds"
readonly MTK_FEEDS_BRANCH="master"
# To build a specific commit, paste the full hash here. Leave empty for the latest.
readonly MTK_FEEDS_COMMIT=""

# --- Directory Configuration ---
readonly SOURCE_DEFAULT_CONFIG_DIR="config"
readonly SOURCE_OPENWRT_PATCH_DIR="openwrt-patches"
readonly SOURCE_MTK_FEEDS_PATCH_DIR="mtk-patches"
readonly SOURCE_OPENWRT_REVERT_DIR="openwrt-patches-revert"
readonly SOURCE_MTK_REVERT_DIR="mtk-patches-revert"

readonly OPENWRT_DIR="openwrt"
readonly MTK_FEEDS_DIR="mtk-feeds"
readonly SCRIPT_EXECUTABLE_NAME=$(basename "$0")


# --- Functions ---

show_usage() {
    echo "Usage: $SCRIPT_EXECUTABLE_NAME [-b <branch_name>]"
    echo "  -b <branch_name>  Specify the OpenWrt branch to build (e.g., openwrt-23.05). Defaults to '$OPENWRT_BRANCH'."
    exit 1
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

require_command() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            log "Error: Required command '$cmd' is not installed. Please install it and try again."
            exit 1
        fi
    done
}

get_latest_commit_hash() {
    local repo_url=$1
    local branch=$2
    log "Querying remote repository for the latest commit on branch '$branch'..."
    local commit_hash
    commit_hash=$(git ls-remote "$repo_url" "refs/heads/$branch" | awk '{print $1}')
    if [ -z "$commit_hash" ]; then
        log "Error: Could not retrieve the commit hash for branch '$branch'."
        log "Please check the repository URL and branch name."
        exit 1
    fi
    echo "$commit_hash"
}

setup_repo() {
    local repo_url=$1
    local branch=$2
    local commit_hash=$3
    local target_dir=$4
    local repo_name=$5

    if [ -d "$target_dir" ]; then
        log "Directory '$target_dir' for $repo_name already exists. Removing it for a fresh clone."
        rm -rf "$target_dir"
        log "Old directory removed."
    fi

    log "Cloning $repo_name repository from branch '$branch'..."
    git clone --branch "$branch" "$repo_url" "$target_dir"
    log "Clone complete. Checking out specific $repo_name commit: $commit_hash"
    (cd "$target_dir" && git checkout "$commit_hash")
    log "Successfully checked out $repo_name commit."
}

prompt_for_menuconfig() {
    log "--- Configuration Choice ---"
    echo "Would you like to run 'make menuconfig' to modify the configuration?"
    echo "You have 10 seconds to answer. The default is 'no' (use existing config)."
    read -t 10 -p "Enter (yes/no): " user_choice || true

    case "${user_choice,,}" in
        y|yes)
            log "User chose 'yes'. Running 'make menuconfig'..."
            make menuconfig
            log "Saving a copy of the new configuration to '../$SOURCE_DEFAULT_CONFIG_DIR/defconfig.new'..."
            cp .config "../$SOURCE_DEFAULT_CONFIG_DIR/defconfig.new"
            log "New configuration saved."
            ;;
        n|no)
            log "User chose 'no'. Skipping 'make menuconfig'."
            ;;
        *)
            log "No input received within 10 seconds. Defaulting to 'no'. Skipping 'make menuconfig'."
            ;;
    esac
}

# --- Reverts patches from the target repository using patch files ---
revert_patches() {
    local source_dir=$1
    local target_dir=$2
    local revert_name=$3

    log "--- Checking for $revert_name patches to revert from '$source_dir' ---"

    if [ ! -d "$source_dir" ]; then
        log "No revert directory ('$source_dir') found for $revert_name. Skipping."
        return
    fi

    local patch_files
    patch_files=$(find "$source_dir" -not -path '*/\.*' -type f -name "*.patch")

    if [ -z "$patch_files" ]; then
        log "No .patch files found in '$source_dir'. Nothing to revert."
        return
    fi

    log "Found patches to revert. Applying them in reverse..."
    (
        cd "$target_dir"
        for patch_file in $patch_files; do
            local relative_patch_path="../$patch_file"
            log "($revert_name) Reverting patch: $(basename "$patch_file")"
            if patch -p1 -R < "$relative_patch_path"; then
                log "Successfully reverted $(basename "$patch_file")."
            else
                log "==================================================================="
                log "  WARNING: Failed to revert patch: $(basename "$patch_file")"
                log "  This can happen if the codebase has changed significantly."
                log "  The build will continue, but the result may be unexpected."
                log "==================================================================="
            fi
        done
    )
}

# --- Prepares source files and applies custom patches and file replacements ---
prepare_files_and_apply_patches() {
    local source_dir=$1
    local target_dir=$2
    local patch_name=$3

    log "--- Preparing and applying $patch_name files and patches from '$source_dir' ---"

    if [ ! -d "$source_dir" ]; then
        log "No source directory ('$source_dir') found for $patch_name. Skipping."
        return
    fi

    # --- Step 0: Prepare all files in the source directory ---
    log "($patch_name) Preparing all source files..."
    find "$source_dir" -type f -name ".gitkeep" -delete
    find "$source_dir" -type f -exec dos2unix {} +
    find "$source_dir" -type d -exec chmod 755 {} +
    find "$source_dir" -type f -exec chmod 644 {} +
    
    local uci_defaults_dir="$source_dir/files/etc/uci-defaults"
    if [ -d "$uci_defaults_dir" ]; then
         log "($patch_name) Making all uci-defaults scripts executable..."
         find "$uci_defaults_dir" -type f -exec chmod 755 {} +
    fi

    # --- Step 1: Copy all non-patch files (direct replacements) ---
    log "($patch_name) Copying direct replacement files..."
    (
        cd "$source_dir"
        if rsync -aR --exclude="*.patch" . "../$target_dir/"; then
            log "($patch_name) Direct replacement files copied successfully."
        else
            log "ERROR: Failed to copy replacement files for $patch_name. Stopping build."
            exit 1
        fi
    )
    
    # --- Step 2: Apply all .patch files ---
    local patch_files
    patch_files=$(find "$source_dir" -type f -name "*.patch")

    if [ -z "$patch_files" ]; then
        log "($patch_name) No custom .patch files found to apply."
        return
    fi
    
    log "($patch_name) Applying custom patches..."
    (
        cd "$target_dir"
        for patch_file in $patch_files; do
            local relative_patch_path="../$patch_file"
            log "($patch_name) Applying custom patch: $(basename "$patch_file")"
            if patch -p1 < "$relative_patch_path"; then
                log "Successfully applied $(basename "$patch_file")."
            else
                log "==================================================================="
                log "  ERROR: Failed to apply custom patch: $(basename "$patch_file")"
                log "  This patch may be outdated or incorrect. Stopping build."
                log "==================================================================="
                exit 1 # Stop the script if a custom patch fails
            fi
        done
    )
    log "($patch_name) All custom patches applied successfully."
}

# --- Applies specific Mediatek configurations after patching ---
configure_mtk_build() {
    log "--- Applying specific Mediatek configurations ---"

    local defconfig_src="$SOURCE_DEFAULT_CONFIG_DIR/defconfig"
    local mtk_config_dest_dir="$MTK_FEEDS_DIR/autobuild/unified/filogic/24.10/"

    if [ -f "$defconfig_src" ]; then
        log "Copying defconfig to MTK autobuild directory..."
        mkdir -p "$mtk_config_dest_dir"
        cp "$defconfig_src" "$mtk_config_dest_dir"
    else
        log "Warning: No defconfig found at '$defconfig_src'. Skipping copy to MTK autobuild dir."
    fi

    log "Disabling 'perf' package in specific MTK configs..."
    local perf_configs=(
        "$MTK_FEEDS_DIR/autobuild/unified/filogic/mac80211/24.10/defconfig"
        "$MTK_FEEDS_DIR/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config"
        "$MTK_FEEDS_DIR/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config"
    )

    for config_file in "${perf_configs[@]}"; do
        if [ -f "$config_file" ]; then
            sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' "$config_file"
        else
            log "Warning: Config file for perf disable not found, skipping: $config_file"
        fi
    done
}

run_openwrt_build() {
    log "--- Starting OpenWrt Build Process ---"
    (
        cd "$OPENWRT_DIR"

        log "Adding local Mediatek feeds to feeds configuration..."
        if ! grep -q "src-link mtk" feeds.conf.default; then
            echo "src-link mtk ../$MTK_FEEDS_DIR" >> feeds.conf.default
            log "Local Mediatek feed added."
        else
            log "Local Mediatek feed already exists in feeds.conf.default."
        fi

        log "Updating and installing feeds..."
        ./scripts/feeds update -a
        ./scripts/feeds install -a

        log "Applying custom build configuration from '../$SOURCE_DEFAULT_CONFIG_DIR'..."
        if [ -f "../$SOURCE_DEFAULT_CONFIG_DIR/defconfig" ]; then
            log "Copying main defconfig file..."
            cp "../$SOURCE_DEFAULT_CONFIG_DIR/defconfig" .config
        else
            log "Warning: No 'defconfig' found in '$SOURCE_DEFAULT_CONFIG_DIR'. You will get a default configuration."
        fi

        log "Validating and expanding final .config..."
        make defconfig

        prompt_for_menuconfig

        log "Starting the build... This could take a very long time."
        make "-j$(nproc)" V=s
    )
    log "--- Build process finished successfully! ---"
}

main() {
    while getopts ":b:" opt; do
        case ${opt} in
            b) OPENWRT_BRANCH=$OPTARG ;;
            \?|:) show_usage ;;
        esac
    done
    shift "$((OPTIND -1))"

    log "--- Starting Full Build Setup ---"
    require_command "git" "awk" "make" "dos2unix" "rsync"

    # --- OpenWrt Repo Setup ---
    local openwrt_commit
    if [ -n "$OPENWRT_COMMIT" ]; then
        openwrt_commit="$OPENWRT_COMMIT"
        log "Using specified OpenWrt commit hash: $openwrt_commit"
    else
        openwrt_commit=$(get_latest_commit_hash "$OPENWRT_REPO" "$OPENWRT_BRANCH")
        log "Latest commit for OpenWrt '$OPENWRT_BRANCH' is: $openwrt_commit"
    fi
    setup_repo "$OPENWRT_REPO" "$OPENWRT_BRANCH" "$openwrt_commit" "$OPENWRT_DIR" "OpenWrt"

    # --- MTK Feeds Repo Setup ---
    local mtk_feeds_commit
    if [ -n "$MTK_FEEDS_COMMIT" ]; then
        mtk_feeds_commit="$MTK_FEEDS_COMMIT"
        log "Using specified MTK Feeds commit hash: $mtk_feeds_commit"
    else
        mtk_feeds_commit=$(get_latest_commit_hash "$MTK_FEEDS_REPO" "$MTK_FEEDS_BRANCH")
        log "Latest commit for MTK Feeds '$MTK_FEEDS_BRANCH' is: $mtk_feeds_commit"
    fi
    setup_repo "$MTK_FEEDS_REPO" "$MTK_FEEDS_BRANCH" "$mtk_feeds_commit" "$MTK_FEEDS_DIR" "MTK Feeds"

    # --- Revert Unwanted Patches ---
    revert_patches "$SOURCE_OPENWRT_REVERT_DIR" "$OPENWRT_DIR" "OpenWrt"
    revert_patches "$SOURCE_MTK_REVERT_DIR" "$MTK_FEEDS_DIR" "MTK"

    # --- Apply Custom Patches and Files ---
    prepare_files_and_apply_patches "$SOURCE_OPENWRT_PATCH_DIR" "$OPENWRT_DIR" "OpenWrt"
    prepare_files_and_apply_patches "$SOURCE_MTK_FEEDS_PATCH_DIR" "$MTK_FEEDS_DIR" "MTK"
    
    # --- Configure MTK specifics after patching ---
    configure_mtk_build

    # --- Run Build ---
    run_openwrt_build
    
    log "--- You can find the output images in '$OPENWRT_DIR/bin/targets/mediatek/filogic/' ---"
}

main "$@"

exit 0
