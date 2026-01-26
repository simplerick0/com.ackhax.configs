#!/bin/bash
# ===========================================
# VSCode/Cursor Config Setup Script
# ===========================================
# Creates symlinks from Cursor config locations to this repository.
#
# Usage:
#   ./setup.sh [options]
#
# Options:
#   --copy              Copy files instead of symlinks
#   --profile <name>    Setup only a specific profile
#   --machine <name>    Setup only a specific machine
#   --no-user           Skip user-level config
#
# Directory structure:
#   user/               -> ~/.cursor-server/data/User/ (default profile)
#   profiles/<name>/    -> ~/.cursor-server/data/User/profiles/<id>/
#   machines/<name>/    -> ~/.cursor-server/data/Machine/
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME=$(hostname)
USE_COPY=false
TARGET_PROFILE=""
TARGET_MACHINE=""
SKIP_USER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --copy) USE_COPY=true; shift ;;
        --profile) TARGET_PROFILE="$2"; shift 2 ;;
        --machine) TARGET_MACHINE="$2"; shift 2 ;;
        --no-user) SKIP_USER=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}=== $1 ===${NC}"; }

detect_server_dir() {
    if [[ -d "$HOME/.cursor-server/data" ]]; then
        echo "$HOME/.cursor-server/data"
    elif [[ -d "$HOME/.vscode-server/data" ]]; then
        echo "$HOME/.vscode-server/data"
    else
        return 1
    fi
}

link_or_copy() {
    local src="$1"
    local dest="$2"

    [[ ! -f "$src" ]] && return

    mkdir -p "$(dirname "$dest")"

    if [[ -f "$dest" && ! -L "$dest" ]]; then
        warn "Backing up $dest"
        mv "$dest" "${dest}.backup"
    fi

    [[ -L "$dest" ]] && rm "$dest"

    if [[ "$USE_COPY" == "true" ]]; then
        cp "$src" "$dest"
        info "Copied $(basename "$src") -> $dest"
    else
        ln -s "$src" "$dest"
        info "Linked $(basename "$dest") -> $src"
    fi
}

setup_dir() {
    local src_dir="$1"
    local dest_dir="$2"

    for file in settings.json keybindings.json tasks.json; do
        if [[ -f "$src_dir/$file" ]]; then
            link_or_copy "$src_dir/$file" "$dest_dir/$file"
        fi
    done
}

get_profile_id() {
    local profile_name="$1"
    local storage_file="$SERVER_DIR/User/globalStorage/storage.json"

    [[ ! -f "$storage_file" ]] && return

    if command -v jq &> /dev/null; then
        jq -r --arg name "$profile_name" \
            '.userDataProfiles[] | select(.name == $name) | .location // empty' \
            "$storage_file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json, sys
with open('$storage_file') as f:
    data = json.load(f)
for p in data.get('userDataProfiles', []):
    if p.get('name') == '$profile_name':
        print(p.get('location', ''))
        break
" 2>/dev/null
    fi
}

main() {
    echo "=========================================="
    echo "VSCode/Cursor Config Setup"
    echo "=========================================="
    echo "Host: $HOSTNAME"
    echo "Mode: $(if $USE_COPY; then echo 'copy'; else echo 'symlink'; fi)"

    SERVER_DIR=$(detect_server_dir) || {
        error "Could not find .cursor-server or .vscode-server"
        exit 1
    }
    info "Server: $SERVER_DIR"

    # User-level config (default profile)
    if [[ "$SKIP_USER" != "true" && -z "$TARGET_PROFILE" ]]; then
        section "User (Default Profile)"
        setup_dir "$SCRIPT_DIR/user" "$SERVER_DIR/User"
    fi

    # Profile configs
    if [[ -d "$SCRIPT_DIR/profiles" ]]; then
        for profile_dir in "$SCRIPT_DIR/profiles"/*/; do
            [[ ! -d "$profile_dir" ]] && continue

            profile_name=$(basename "$profile_dir")

            if [[ -n "$TARGET_PROFILE" && "$profile_name" != "$TARGET_PROFILE" ]]; then
                continue
            fi

            profile_id=$(get_profile_id "$profile_name")
            if [[ -z "$profile_id" ]]; then
                warn "Profile '$profile_name' not found in Cursor, skipping"
                continue
            fi

            section "Profile: $profile_name ($profile_id)"
            setup_dir "$profile_dir" "$SERVER_DIR/User/profiles/$profile_id"
        done
    fi

    # Machine configs
    if [[ -d "$SCRIPT_DIR/machines" ]]; then
        machine_name="${TARGET_MACHINE:-$HOSTNAME}"
        machine_dir="$SCRIPT_DIR/machines/$machine_name"

        if [[ -d "$machine_dir" ]]; then
            section "Machine: $machine_name"
            setup_dir "$machine_dir" "$SERVER_DIR/Machine"
        elif [[ -n "$TARGET_MACHINE" ]]; then
            warn "Machine config '$TARGET_MACHINE' not found"
        fi
    fi

    echo ""
    echo "=========================================="
    echo "Setup complete! Reload window to apply."
    echo "=========================================="
}

main "$@"
