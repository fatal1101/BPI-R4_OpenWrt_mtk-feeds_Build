#!/bin/bash
# ==================================================================================
# BPI-R4 - OpenWrt with MTK-Feeds Build Script (Two-Stage Autobuild + Make)
# ==================================================================================
# This script uses list files to manage custom content.
# - To add/overwrite a file: Place it in 'openwrt-patches' or 'mtk-patches'.
#   For most files, list the destination path in the 'add-patch' file.
#   For filename conflicts, use the 'source_filename:destination_path' format.
# - To remove a file: Add its path to the corresponding 'remove' file.
# - Custom runtime configs (uci-defaults, etc.) go in the 'files' directory.
#
# Build system Install Note  - Run on Ubuntu 24.04 or later
#                            - sudo apt update
#                            - sudo apt install dos2unix rsync patch
# Usage:
#
#   ./mtk-openwrt_build.sh
#   ./mtk-openwrt_build.sh -b openwrt-24.10
#
# ==================================================================================

set -euo pipefail

# --- Dependency Check ---
if ! command -v dos2unix &> /dev/null || ! command -v rsync &> /dev/null || ! command -v patch &> /dev/null; then
    echo "ERROR: One or more dependencies (dos2unix, rsync, patch) are not installed." >&2
    echo "Please run 'sudo apt update && sudo apt install dos2unix rsync patch'." >&2
    exit 1
fi


# --- Main Configuration ---

# OpenWrt Source Details
# --- Use this line for remote cloning ---
readonly OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
# --- Use this line for local testing (uncomment and set your path) ---
#readonly OPENWRT_REPO="/home/user/repos/openwrt"

OPENWRT_BRANCH="openwrt-24.10"
readonly OPENWRT_COMMIT=""

# Mediatek Feeds Source Details
# --- Use this line for remote cloning ---
readonly MTK_FEEDS_REPO="https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds"
# --- Use this line for local testing (uncomment and set your path) ---
#readonly MTK_FEEDS_REPO="/home/user/repos/mtk-openwrt-feeds"

readonly MTK_FEEDS_BRANCH="master"
readonly MTK_FEEDS_COMMIT=""

# --- Directory and File Configuration ---
readonly SOURCE_DEFAULT_CONFIG_DIR="config"
readonly SOURCE_OPENWRT_PATCH_DIR="openwrt-patches"
readonly SOURCE_MTK_FEEDS_PATCH_DIR="mtk-patches"
readonly SOURCE_CUSTOM_FILES_DIR="files"
readonly OPENWRT_ADD_LIST="$SOURCE_OPENWRT_PATCH_DIR/openwrt-add-patch"
readonly MTK_ADD_LIST="$SOURCE_MTK_FEEDS_PATCH_DIR/mtk-add-patch"
readonly OPENWRT_REMOVE_LIST="$SOURCE_OPENWRT_PATCH_DIR/openwrt-remove"
readonly MTK_REMOVE_LIST="$SOURCE_MTK_FEEDS_PATCH_DIR/mtk-remove"

readonly OPENWRT_DIR="openwrt"
readonly MTK_FEEDS_DIR="mtk-feeds"
readonly SCRIPT_EXECUTABLE_NAME=$(basename "$0")


# --- Functions ---

show_usage() {
    echo "Usage: $SCRIPT_EXECUTABLE_NAME [-b <branch_name>]"
    echo "  -b <branch_name>  Specify the OpenWrt branch to build."
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
    fi

    log "Cloning $repo_name repository from branch '$branch'..."
    git clone --branch "$branch" "$repo_url" "$target_dir"
    log "Clone complete. Checking out specific $repo_name commit: $commit_hash"
    (cd "$target_dir" && git checkout "$commit_hash")
    log "Successfully checked out $repo_name commit."
}

prepare_source_directory() {
    local source_dir=$1
    local dir_name=$2
    log "--- Preparing source directory: '$source_dir' ($dir_name) ---"
    if [ ! -d "$source_dir" ]; then return; fi
    log "($dir_name) Cleaning and setting permissions..."
    find "$source_dir" -type f -name ".gitkeep" -delete
    find "$source_dir" -type f -exec dos2unix {} +
    find "$source_dir" -type d -exec chmod 755 {} +
    find "$source_dir" -type f -exec chmod 644 {} +
    local uci_defaults_dir="$source_dir/etc/uci-defaults"
    if [ -d "$uci_defaults_dir" ]; then
         log "($dir_name) Making all uci-defaults scripts executable..."
         find "$uci_defaults_dir" -type f -exec chmod 755 {} +
    fi
    log "($dir_name) Preparation complete."
}

remove_files_from_list() {
    local list_file=$1
    local target_dir=$2
    local name=$3
    log "--- Checking for $name files to remove from list '$list_file' ---"
    if [ ! -f "$list_file" ]; then
        log "Remove list '$list_file' not found. Skipping."
        return
    fi
    local lines_processed=0
    while IFS= read -r relative_path; do
        relative_path=$(echo "$relative_path" | tr -d '\r' | sed 's|^/||')
        if [ -z "$relative_path" ]; then continue; fi
        
        local target_pattern="$target_dir/$relative_path"
        lines_processed=$((lines_processed + 1))

        if [[ "$relative_path" == *'*'* ]]; then
            log "($name) Removing files matching pattern: $relative_path"
            
            shopt -s nullglob
            local files_to_delete=($target_pattern)
            shopt -u nullglob

            if [ ${#files_to_delete[@]} -gt 0 ]; then
                rm -f "${files_to_delete[@]}"
                log "($name) Removed ${#files_to_delete[@]} file(s)."
            else
                log "($name) No files found matching the pattern."
            fi
        else
            if [ -f "$target_pattern" ]; then
                log "($name) Removing: $relative_path"
                rm -f "$target_pattern"
            else
                log "($name) Warning: File to remove not found at '$target_pattern'. Skipping."
            fi
        fi
    done < <(grep -v -E '^\s*#|^\s*$' "$list_file")

    if [ "$lines_processed" -eq 0 ]; then
        log "No files listed for removal in '$list_file'."
    fi
}

# --- Applies files from a source directory based on a hybrid list file ---
apply_files_from_list() {
    local list_file=$1
    local source_dir=$2
    local target_dir=$3
    local name=$4

    log "--- Applying $name files and patches from list '$list_file' ---"
    if [ ! -f "$list_file" ]; then
        log "Add list '$list_file' not found. Skipping."
        return
    fi

    local lines_processed=0
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^\s*# ]] || [ -z "$line" ] && continue
        
        lines_processed=$((lines_processed + 1))

        local source_filename
        local dest_relative_path

        # Check if the line uses the 'source:destination' format
        if [[ "$line" == *":"* ]]; then
            source_filename=$(echo "$line" | cut -d':' -f1 | tr -d '[:space:]')
            dest_relative_path=$(echo "$line" | cut -d':' -f2- | tr -d '[:space:]' | sed 's|^/||')
        else
            # Fallback to the old format (destination only)
            dest_relative_path=$(echo "$line" | tr -d '[:space:]' | sed 's|^/||')
            source_filename=$(basename "$dest_relative_path")
        fi

        if [ -z "$source_filename" ] || [ -z "$dest_relative_path" ]; then
            log "($name) Warning: Malformed line found in '$list_file': '$line'. Skipping."
            continue
        fi

        local source_file="$source_dir/$source_filename"
        local dest_file="$target_dir/$dest_relative_path"

        if [ ! -f "$source_file" ]; then
            log "($name) ERROR: Source file '$source_filename' not found in '$source_dir'. Skipping."
            continue
        fi

        log "($name) Copying '$source_filename' to '$dest_relative_path'..."
        
        local dest_dir
        dest_dir=$(dirname "$dest_file")
        mkdir -p "$dest_dir"

        cp "$source_file" "$dest_file"

    done < <(grep -v -E '^\s*#|^\s*$' "$list_file")

    if [ "$lines_processed" -eq 0 ]; then
        log "No files listed for application in '$list_file'."
    fi
}


copy_custom_files() {
    local source_dir="$SOURCE_CUSTOM_FILES_DIR"
    local target_dir="$OPENWRT_DIR/files"
    log "--- Copying custom runtime files from '$source_dir' ---"
    if [ ! -d "$source_dir" ]; then
        log "Source directory '$source_dir' not found. Skipping."
        return
    fi
    mkdir -p "$target_dir"
    rsync -a "$source_dir/" "$target_dir/"
    log "Custom files have been copied successfully."
}

configure_build() {
    log "--- Configuring Mediatek Build ---"
    local defconfig_src="$SOURCE_DEFAULT_CONFIG_DIR/defconfig"
    if [ -f "$defconfig_src" ]; then
        cp "$defconfig_src" "$MTK_FEEDS_DIR/autobuild/unified/filogic/24.10/"
    else
        log "Warning: Main defconfig not found. MTK autobuild may use its default."
    fi
    log "Disabling 'perf' package in configs..."
    local perf_configs=(
        "$MTK_FEEDS_DIR/autobuild/unified/filogic/mac80211/24.10/defconfig"
        "$MTK_FEEDS_DIR/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config"
        "$MTK_FEEDS_DIR/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config"
    )
    for config_file in "${perf_configs[@]}"; do
        if [ -f "$config_file" ]; then
            sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' "$config_file"
        fi
    done
}

prompt_for_custom_build() {
    log "--- Optional: Custom Image Creation ---"
    echo "The base image has been built successfully."
    echo "Would you like to create a custom image?"
    echo "You have 10 seconds to answer. The default is 'no'."
    local custom_choice=""
    read -t 10 -p "Enter (yes/no): " custom_choice || true

    case "${custom_choice,,}" in
        y|yes)
            log "User chose 'yes'. Preparing for custom build..."
            
            log "Running feeds update and install for custom build..."
            ./scripts/feeds update -a
            ./scripts/feeds install -a
            log "Feeds updated and installed."

            log "Launching 'make menuconfig' for customization..."
            make menuconfig
            log "Configuration saved."

            log "--- Build Confirmation for Custom Image ---"
            echo "Would you like to build the custom image with the new configuration?"
            echo "You have 10 seconds to answer. The default is 'no'."
            local build_choice=""
            read -t 10 -p "Enter (yes/no): " build_choice || true

            case "${build_choice,,}" in
                y|yes)
                    log "Removing old images from the output directory..."
                    local image_dir="bin/targets/mediatek/filogic"
                    if [ -d "$image_dir" ]; then
                        rm -f "$image_dir"/*
                        log "Old images removed."
                    fi
                    
                    log "Starting the custom build with 'make -j\$(nproc)'..."
                    make -j"$(nproc)"
                    log "--- Custom build process finished successfully! ---"
                    log "--- You can find the custom images in 'bin/targets/mediatek/filogic/' ---"
                    ;;
                *)
                    log "User chose 'no' or timed out. Custom build skipped."
                    log "Your custom configuration has been saved in '$OPENWRT_DIR/.config'."
                    ;;
            esac
            ;;
        *)
            log "User chose 'no' or timed out. Skipping custom image creation."
            ;;
    esac
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
    require_command "git" "awk" "make" "dos2unix" "rsync" "patch"

    # --- Step 1: Repo Setup ---
    openwrt_commit=$( [ -n "$OPENWRT_COMMIT" ] && echo "$OPENWRT_COMMIT" || get_latest_commit_hash "$OPENWRT_REPO" "$OPENWRT_BRANCH" )
    setup_repo "$OPENWRT_REPO" "$OPENWRT_BRANCH" "$openwrt_commit" "$OPENWRT_DIR" "OpenWrt"
    mtk_feeds_commit=$( [ -n "$MTK_FEEDS_COMMIT" ] && echo "$MTK_FEEDS_COMMIT" || get_latest_commit_hash "$MTK_FEEDS_REPO" "$MTK_FEEDS_BRANCH" )
    setup_repo "$MTK_FEEDS_REPO" "$MTK_FEEDS_BRANCH" "$mtk_feeds_commit" "$MTK_FEEDS_DIR" "MTK Feeds"

    # --- Step 2: Initialize Feeds ---
    (
        cd "$OPENWRT_DIR"
        log "Adding local Mediatek feeds to feeds configuration..."
        if ! grep -q "src-link mtk" feeds.conf.default; then
            echo "src-link mtk ../$MTK_FEEDS_DIR" >> feeds.conf.default
        fi
        log "Updating and installing feeds to prepare the source tree..."
        ./scripts/feeds update -a
        ./scripts/feeds install -a
    )

    # --- Step 3: Prepare all custom source directories ---
    prepare_source_directory "$SOURCE_OPENWRT_PATCH_DIR" "OpenWrt Patches"
    prepare_source_directory "$SOURCE_MTK_FEEDS_PATCH_DIR" "MTK Patches"
    prepare_source_directory "$SOURCE_CUSTOM_FILES_DIR" "Custom Files"

    # --- Step 4: Remove and Apply Source Files ---
    remove_files_from_list "$OPENWRT_REMOVE_LIST" "$OPENWRT_DIR" "OpenWrt"
    remove_files_from_list "$MTK_REMOVE_LIST" "$MTK_FEEDS_DIR" "MTK"
    apply_files_from_list "$OPENWRT_ADD_LIST" "$SOURCE_OPENWRT_PATCH_DIR" "$OPENWRT_DIR" "OpenWrt"
    apply_files_from_list "$MTK_ADD_LIST" "$SOURCE_MTK_FEEDS_PATCH_DIR" "$MTK_FEEDS_DIR" "MTK"
    
    # --- Step 5: Copy Custom Runtime Files ---
    copy_custom_files

    # --- Step 6: Configure and Run Base Build ---
    configure_build
    
    log "--- Starting the MediaTek autobuild script for the base image... ---"
    (
        cd "$OPENWRT_DIR"
        bash "../$MTK_FEEDS_DIR/autobuild/unified/autobuild.sh" filogic-mac80211-mt7988_rfb-mt7996 log_file=make
    )
    log "--- Base build process finished successfully! ---"
    log "--- You can find the base images in '$OPENWRT_DIR/bin/targets/mediatek/filogic/' ---"

    # --- Step 7: Offer the optional custom build ---
    (
        cd "$OPENWRT_DIR"
        prompt_for_custom_build
    )
    
    log "--- Script finished. ---"
}

main "$@"

exit 0