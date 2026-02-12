#!/bin/bash

# Config sync setup script
# Creates symlinks for tool configs across macOS, Ubuntu, Kali, RedHat, and WSL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Respect XDG_CONFIG_HOME if set, otherwise use ~/.config
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# Tools to sync (tool:command pairs)
TOOLS="btop:btop yazi:yazi powerline:powerline-daemon git:git glow:glow devcontainer:devcontainer"

# Detect OS and distribution
detect_platform() {
    OS="$(uname -s)"
    DISTRO=""
    IS_WSL=false

    case "$OS" in
        Darwin)
            PLATFORM="macos"
            ;;
        Linux)
            PLATFORM="linux"
            # Check for WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                IS_WSL=true
            fi
            # Detect distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO="$ID"
            fi
            ;;
        *)
            PLATFORM="unknown"
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get the appropriate config path for a tool
get_config_path() {
    local tool="$1"

    case "$tool" in
        btop)
            # macOS btop can use either location; prefer XDG for consistency
            if [ "$PLATFORM" = "macos" ] && [ -d "$HOME/Library/Application Support/btop" ] && [ ! -d "$CONFIG_DIR/btop" ]; then
                echo "$HOME/Library/Application Support/btop"
            else
                echo "$CONFIG_DIR/btop"
            fi
            ;;
        yazi)
            echo "${YAZI_CONFIG_HOME:-$CONFIG_DIR/yazi}"
            ;;
        powerline)
            echo "$CONFIG_DIR/powerline"
            ;;
        git)
            echo "$CONFIG_DIR/git"
            ;;
        glow)
            # macOS glow uses ~/Library/Preferences/glow
            if [ "$PLATFORM" = "macos" ]; then
                echo "$HOME/Library/Preferences/glow"
            else
                echo "$CONFIG_DIR/glow"
            fi
            ;;
        devcontainer)
            echo "$CONFIG_DIR/devcontainer"
            ;;
    esac
}

# Print colored output
print_header() { printf "\n\033[1;34m%s\033[0m\n" "$1"; }
print_success() { printf "\033[0;32m  ✓ %s\033[0m\n" "$1"; }
print_warning() { printf "\033[0;33m  ! %s\033[0m\n" "$1"; }
print_error() { printf "\033[0;31m  ✗ %s\033[0m\n" "$1"; }
print_info() { printf "  %s\n" "$1"; }

# Main setup
main() {
    detect_platform

    echo "========================================"
    echo "  Config Sync Setup"
    echo "========================================"
    echo ""
    echo "Platform:    $PLATFORM"
    [ -n "$DISTRO" ] && echo "Distro:      $DISTRO"
    [ "$IS_WSL" = true ] && echo "Environment: WSL"
    echo "Config dir:  $CONFIG_DIR"
    echo "Source dir:  $SCRIPT_DIR"

    # WSL warning
    if [ "$IS_WSL" = true ]; then
        print_header "WSL Notice"
        print_warning "Git config is separate from Windows Git"
        print_warning "Windows apps won't see these configs"
    fi

    # Create config directory if needed
    mkdir -p "$CONFIG_DIR"

    # Check installed tools
    print_header "Checking installed tools"

    for pair in $TOOLS; do
        tool="${pair%%:*}"
        cmd="${pair##*:}"
        if command_exists "$cmd"; then
            print_success "$tool (found: $(which "$cmd"))"
        else
            print_warning "$tool not installed - will still create symlink"
        fi
    done

    # Backup and symlink
    print_header "Setting up symlinks"

    BACKUP_DIR="$CONFIG_DIR/config-sync-backup-$(date +%Y%m%d-%H%M%S)"
    backup_created=false

    for pair in $TOOLS; do
        tool="${pair%%:*}"
        target_path=$(get_config_path "$tool")
        source_path="$SCRIPT_DIR/$tool"

        # Check if source exists in our sync folder
        if [ ! -e "$source_path" ]; then
            print_error "$tool: source not found in config-sync"
            continue
        fi

        # Handle existing config (not a symlink)
        if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            if [ "$backup_created" = false ]; then
                mkdir -p "$BACKUP_DIR"
                backup_created=true
            fi
            mv "$target_path" "$BACKUP_DIR/"
            print_info "$tool: backed up existing config"
        fi

        # Remove existing symlink
        if [ -L "$target_path" ]; then
            rm "$target_path"
        fi

        # Create parent directory if needed
        mkdir -p "$(dirname "$target_path")"

        # Create symlink
        ln -s "$source_path" "$target_path"
        print_success "$tool: $target_path -> $source_path"
    done

    if [ "$backup_created" = true ]; then
        print_header "Backup location"
        print_info "$BACKUP_DIR"
    fi

    # Git-specific setup
    print_header "Git configuration"

    if command_exists git; then
        current_excludes=$(git config --global core.excludesfile 2>/dev/null || echo "")
        expected_excludes="$CONFIG_DIR/git/ignore"

        if [ "$current_excludes" != "$expected_excludes" ]; then
            printf "  Set git core.excludesfile to %s? [Y/n] " "$expected_excludes"
            read -r REPLY
            if [ "$REPLY" != "n" ] && [ "$REPLY" != "N" ]; then
                git config --global core.excludesfile "$expected_excludes"
                print_success "Set core.excludesfile"
            else
                print_warning "Skipped - global gitignore may not work"
            fi
        else
            print_success "core.excludesfile already configured"
        fi
    fi

    # Platform-specific notes
    print_header "Notes"

    case "$PLATFORM" in
        macos)
            print_info "macOS: XDG_CONFIG_HOME not set by default"
            print_info "Add to ~/.zshrc: export XDG_CONFIG_HOME=\"\$HOME/.config\""
            ;;
        linux)
            if [ "$DISTRO" = "kali" ]; then
                print_info "Kali: Same paths as Debian/Ubuntu"
            fi
            ;;
    esac

    echo ""
    echo "========================================"
    echo "  Setup complete!"
    echo "========================================"
}

main "$@"
