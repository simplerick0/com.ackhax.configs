#!/bin/bash
# ===========================================
# VSCode/Cursor Machine Config Setup Script
# ===========================================
# Creates symlinks for machine-level configs on remote servers.
# User and profile configs are client-side only (not handled here).
#
# Usage:
#   ./setup.sh [options]
#
# Options:
#   --copy              Copy files instead of symlinks
#   --machine <name>    Setup a specific machine config (default: hostname)
#
# Directory structure:
#   machines/<name>/    -> ~/.cursor-server/data/Machine/
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME=$(hostname)
USE_COPY=false
TARGET_MACHINE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --copy) USE_COPY=true; shift ;;
        --machine) TARGET_MACHINE="$2"; shift 2 ;;
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

main() {
    echo "=========================================="
    echo "VSCode/Cursor Machine Config Setup"
    echo "=========================================="
    echo "Host: $HOSTNAME"
    echo "Mode: $(if $USE_COPY; then echo 'copy'; else echo 'symlink'; fi)"

    SERVER_DIR=$(detect_server_dir) || {
        error "Could not find .cursor-server or .vscode-server"
        exit 1
    }
    info "Server: $SERVER_DIR"

    # Machine configs (user/profile configs are client-side only)
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
