#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS and distribution
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            DISTRO_VERSION=$VERSION_ID
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            DISTRO=$DISTRIB_ID
            DISTRO_VERSION=$DISTRIB_RELEASE
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="windows"
    elif grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        OS="wsl"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            DISTRO="ubuntu"
        fi
    else
        OS="unknown"
        DISTRO="unknown"
    fi

    print_info "Detected OS: $OS"
    print_info "Distribution: $DISTRO"
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Install dependencies based on OS
install_dependencies() {
    print_info "Checking and installing dependencies..."

    case $DISTRO in
        ubuntu|debian)
            # Check Neovim version and install/upgrade if needed
            local needs_nvim_install=false
            if ! command_exists nvim; then
                needs_nvim_install=true
            else
                local nvim_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
                local major=$(echo "$nvim_version" | cut -d. -f1)
                local minor=$(echo "$nvim_version" | cut -d. -f2)

                if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
                    print_warning "Neovim $nvim_version is too old (requires 0.10+)"
                    print_info "Remove old version and build latest Neovim from source? (Y/n)"
                    read -r upgrade_nvim
                    upgrade_nvim=${upgrade_nvim:-y}
                    if [[ "$upgrade_nvim" =~ ^[Yy]$ ]]; then
                        print_info "Removing old Neovim..."
                        sudo apt remove -y neovim
                        needs_nvim_install=true
                    else
                        print_warning "Keeping old Neovim (dotfiles config requires 0.10+)"
                    fi
                fi
            fi

            if [ "$needs_nvim_install" = true ]; then
                print_info "Building Neovim from source (this will take a few minutes)..."

                # Install build dependencies
                sudo apt update
                sudo apt install -y ninja-build gettext cmake unzip curl build-essential

                # Get latest stable version
                local nvim_version=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

                if [ -z "$nvim_version" ]; then
                    print_error "Failed to fetch latest Neovim version"
                    return 1
                fi

                print_info "Building Neovim $nvim_version..."

                # Clone and build
                cd /tmp
                rm -rf neovim
                git clone https://github.com/neovim/neovim.git
                cd neovim
                git checkout "$nvim_version"

                make CMAKE_BUILD_TYPE=Release
                sudo make install

                cd ~
                rm -rf /tmp/neovim

                print_success "Neovim $nvim_version built and installed from source to /usr/local"
            fi

            if ! command_exists git; then
                print_info "Git is not installed. Install it? (Y/n)"
                read -r install_git
                install_git=${install_git:-y}
                if [[ "$install_git" =~ ^[Yy]$ ]]; then
                    print_info "Installing Git..."
                    sudo apt install -y git
                else
                    print_warning "Skipping Git installation (required for dotfiles)"
                fi
            fi
            ;;
        arch|manjaro)
            # Arch usually has latest versions, but check anyway
            if ! command_exists nvim; then
                print_info "Installing Neovim..."
                sudo pacman -S --noconfirm neovim
            else
                local nvim_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
                local major=$(echo "$nvim_version" | cut -d. -f1)
                local minor=$(echo "$nvim_version" | cut -d. -f2)

                if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
                    print_warning "Neovim $nvim_version is too old, upgrading..."
                    sudo pacman -S --noconfirm neovim
                fi
            fi
            if ! command_exists git; then
                print_info "Git is not installed. Install it? (Y/n)"
                read -r install_git
                install_git=${install_git:-y}
                if [[ "$install_git" =~ ^[Yy]$ ]]; then
                    print_info "Installing Git..."
                    sudo pacman -S --noconfirm git
                else
                    print_warning "Skipping Git installation (required for dotfiles)"
                fi
            fi
            ;;
        fedora|rhel|centos)
            # Check Neovim version and install/upgrade if needed
            local needs_nvim_install=false
            if ! command_exists nvim; then
                needs_nvim_install=true
            else
                local nvim_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
                local major=$(echo "$nvim_version" | cut -d. -f1)
                local minor=$(echo "$nvim_version" | cut -d. -f2)

                if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
                    print_warning "Neovim $nvim_version is too old (requires 0.10+)"
                    print_info "Remove old version and install latest Neovim? (Y/n)"
                    read -r upgrade_nvim
                    upgrade_nvim=${upgrade_nvim:-y}
                    if [[ "$upgrade_nvim" =~ ^[Yy]$ ]]; then
                        print_info "Removing old Neovim..."
                        sudo dnf remove -y neovim
                        needs_nvim_install=true
                    else
                        print_warning "Keeping old Neovim (dotfiles config requires 0.10+)"
                    fi
                fi
            fi

            if [ "$needs_nvim_install" = true ]; then
                print_info "Installing latest Neovim from GitHub releases..."

                # Get latest release info from GitHub API
                local release_info=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest)
                local nvim_version=$(echo "$release_info" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                local download_url=$(echo "$release_info" | grep "browser_download_url.*linux-x86_64.tar.gz" | cut -d '"' -f 4)

                if [ -z "$nvim_version" ] || [ -z "$download_url" ]; then
                    print_error "Failed to fetch Neovim download information"
                    return 1
                fi

                local filename=$(basename "$download_url")
                local dirname=$(basename "$filename" .tar.gz)

                print_info "Downloading Neovim $nvim_version..."
                curl -fL -o "$filename" "$download_url"

                sudo rm -rf "/opt/$dirname"
                sudo tar -C /opt -xzf "$filename"
                rm "$filename"

                # Add to PATH if not already there
                if ! grep -q "/opt/$dirname/bin" ~/.bashrc; then
                    echo "export PATH=\"/opt/$dirname/bin:\$PATH\"" >> ~/.bashrc
                    export PATH="/opt/$dirname/bin:$PATH"
                fi

                # Create symlink for system-wide access
                sudo ln -sf "/opt/$dirname/bin/nvim" /usr/local/bin/nvim

                print_success "Neovim $nvim_version installed at /opt/$dirname"
            fi

            if ! command_exists git; then
                print_info "Git is not installed. Install it? (Y/n)"
                read -r install_git
                install_git=${install_git:-y}
                if [[ "$install_git" =~ ^[Yy]$ ]]; then
                    print_info "Installing Git..."
                    sudo dnf install -y git
                else
                    print_warning "Skipping Git installation (required for dotfiles)"
                fi
            fi
            ;;
        macos)
            if ! command_exists brew; then
                print_warning "Homebrew not found. Please install Homebrew first:"
                print_info "https://brew.sh"
                exit 1
            fi
            if ! command_exists nvim; then
                print_info "Installing Neovim..."
                brew install neovim
            fi
            if ! command_exists git; then
                print_info "Git is not installed. Install it? (Y/n)"
                read -r install_git
                install_git=${install_git:-y}
                if [[ "$install_git" =~ ^[Yy]$ ]]; then
                    print_info "Installing Git..."
                    brew install git
                else
                    print_warning "Skipping Git installation (required for dotfiles)"
                fi
            fi
            if [ ! -d "/Applications/Hammerspoon.app" ]; then
                print_info "Installing Hammerspoon..."
                brew install --cask hammerspoon
            fi
            ;;
        *)
            print_warning "Automatic dependency installation not supported for $DISTRO"
            print_warning "Please ensure neovim and git are installed manually"
            ;;
    esac

    print_success "Dependencies checked"
}

# Clone or update repository
setup_repo() {
    local repo_url="https://github.com/ronilaukkarinen/dotfiles.git"
    local dotfiles_dir="$HOME/Projects/dotfiles"

    # Create Projects directory if it doesn't exist
    if [ ! -d "$HOME/Projects" ]; then
        print_info "Creating ~/Projects directory..."
        mkdir -p "$HOME/Projects"
    fi

    # Check if we're already in the dotfiles directory
    if [ "$(pwd)" = "$dotfiles_dir" ]; then
        print_info "Already in dotfiles directory, pulling latest changes..."
        git pull
        return 0
    fi

    # Clone or update repository
    if [ -d "$dotfiles_dir" ]; then
        print_info "Dotfiles directory exists, pulling latest changes..."
        cd "$dotfiles_dir"
        git pull
    else
        print_info "Cloning dotfiles repository..."
        git clone "$repo_url" "$dotfiles_dir"
        cd "$dotfiles_dir"
    fi

    print_success "Repository ready at $dotfiles_dir"
}

# Setup configuration files
setup_configs() {
    local dotfiles_dir="$HOME/Projects/dotfiles"

    print_info "Setting up configuration files..."

    # Determine config paths based on OS
    if [ "$OS" = "windows" ] || [ "$OS" = "wsl" ]; then
        NVIM_CONFIG_DIR="$HOME/AppData/Local/nvim"
        WEZTERM_CONFIG_DIR="$HOME/.config/wezterm"
    else
        NVIM_CONFIG_DIR="$HOME/.config/nvim"
        WEZTERM_CONFIG_DIR="$HOME/.config/wezterm"
    fi

    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"

    # Setup WezTerm symlink
    if [ -L "$WEZTERM_CONFIG_DIR" ]; then
        print_info "WezTerm config symlink already exists"
    elif [ -d "$WEZTERM_CONFIG_DIR" ]; then
        print_warning "WezTerm config directory exists at $WEZTERM_CONFIG_DIR"
        print_info "Backup and replace with symlink? (y/N)"
        read -r replace_wezterm
        if [[ "$replace_wezterm" =~ ^[Yy]$ ]]; then
            mv "$WEZTERM_CONFIG_DIR" "${WEZTERM_CONFIG_DIR}.backup.$(date +%s)"
            ln -sf "$dotfiles_dir/wezterm" "$WEZTERM_CONFIG_DIR"
            print_success "WezTerm config symlinked (old config backed up)"
        else
            print_info "Skipping WezTerm config"
        fi
    else
        ln -sf "$dotfiles_dir/wezterm" "$WEZTERM_CONFIG_DIR"
        print_success "WezTerm config symlinked"
    fi

    # Setup Neovim symlink
    if [ -L "$NVIM_CONFIG_DIR" ]; then
        print_info "Neovim config symlink already exists"
    elif [ -d "$NVIM_CONFIG_DIR" ]; then
        print_warning "Neovim config directory exists at $NVIM_CONFIG_DIR"
        print_info "Backup and replace with symlink? (y/N)"
        read -r replace_nvim
        if [[ "$replace_nvim" =~ ^[Yy]$ ]]; then
            mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup.$(date +%s)"
            ln -sf "$dotfiles_dir/nvim" "$NVIM_CONFIG_DIR"
            print_success "Neovim config symlinked (old config backed up)"
        else
            print_info "Skipping Neovim config"
        fi
    else
        # Create parent directory if needed
        mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
        ln -sf "$dotfiles_dir/nvim" "$NVIM_CONFIG_DIR"
        print_success "Neovim config symlinked"
    fi

    # Setup secrets.lua
    if [ ! -f "$dotfiles_dir/nvim/lua/secrets.lua" ]; then
        print_info "Creating secrets.lua from example..."
        cp "$dotfiles_dir/nvim/lua/secrets.lua.example" "$dotfiles_dir/nvim/lua/secrets.lua"
        print_warning "Please edit ~/Projects/dotfiles/nvim/lua/secrets.lua and add your Code::Stats API key"
    else
        print_info "secrets.lua already exists"
    fi

    # Setup Hammerspoon symlink (macOS only)
    if [ "$OS" = "macos" ]; then
        if [ -L "$HOME/.hammerspoon" ]; then
            print_info "Hammerspoon config symlink already exists"
        elif [ -d "$HOME/.hammerspoon" ]; then
            print_warning "Hammerspoon config directory exists at ~/.hammerspoon"
            print_info "Backup and replace with symlink? (y/N)"
            read -r replace_hammerspoon
            if [[ "$replace_hammerspoon" =~ ^[Yy]$ ]]; then
                mv "$HOME/.hammerspoon" "${HOME}/.hammerspoon.backup.$(date +%s)"
                ln -sf "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
                print_success "Hammerspoon config symlinked (old config backed up)"
            else
                print_info "Skipping Hammerspoon config"
            fi
        else
            ln -sf "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
            print_success "Hammerspoon config symlinked"
        fi
    fi
}

# Setup Claude Code integration
setup_claude_code() {
    local dotfiles_dir="$HOME/Projects/dotfiles"
    local claude_hooks_dir="$HOME/.claude/hooks"

    print_info "Setting up Claude Code integration..."

    # Create hooks directory
    mkdir -p "$claude_hooks_dir"

    # Setup hook symlink
    if [ -L "$claude_hooks_dir/codestats-hook.sh" ]; then
        print_info "Claude Code hook symlink already exists"
    else
        ln -sf "$dotfiles_dir/claude-code/codestats-hook.sh" "$claude_hooks_dir/codestats-hook.sh"
        print_success "Claude Code hook symlinked"
    fi

    # Setup secrets
    if [ ! -f "$dotfiles_dir/claude-code/secrets.sh" ]; then
        print_info "Creating Claude Code secrets.sh from example..."
        cp "$dotfiles_dir/claude-code/secrets.sh.example" "$dotfiles_dir/claude-code/secrets.sh"
        print_warning "Please edit ~/Projects/dotfiles/claude-code/secrets.sh and add your Code::Stats API key"
    else
        print_info "Claude Code secrets.sh already exists"
    fi

    # Check if settings.json needs updating
    local settings_file="$HOME/.claude/settings.json"
    if [ -f "$settings_file" ]; then
        if grep -q "codestats-hook.sh" "$settings_file"; then
            print_info "Claude Code settings.json already configured"
        else
            print_warning "Please add the hooks configuration to ~/.claude/settings.json"
            print_info "See README.md section 'Configure Claude code hooks' for details"
        fi
    else
        print_warning "~/.claude/settings.json not found"
        print_info "You'll need to create it and add the hooks configuration"
        print_info "See README.md section 'Configure Claude code hooks' for details"
    fi
}

# Optional: install Syncthing
install_syncthing() {
    if command_exists syncthing; then
        print_info "Syncthing already installed"
        return 0
    fi

    print_info "Would you like to install Syncthing for syncing gamify data? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Skipping Syncthing installation"
        return 0
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y syncthing
            systemctl --user enable syncthing.service
            systemctl --user start syncthing.service
            print_success "Syncthing installed and started"
            print_info "Access web UI at http://127.0.0.1:8384"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm syncthing
            systemctl --user enable syncthing.service
            systemctl --user start syncthing.service
            print_success "Syncthing installed and started"
            print_info "Access web UI at http://127.0.0.1:8384"
            ;;
        macos)
            brew install syncthing
            brew services start syncthing
            print_success "Syncthing installed and started"
            print_info "Access web UI at http://127.0.0.1:8384"
            ;;
        *)
            print_warning "Automatic Syncthing installation not supported for $DISTRO"
            print_info "Please install Syncthing manually"
            ;;
    esac
}

# Print final instructions
print_final_instructions() {
    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo ""
    echo "1. Add your Code::Stats API key to Neovim secrets:"
    echo "┌────────────────────────────────────────────────┐"
    echo "│ nvim ~/Projects/dotfiles/nvim/lua/secrets.lua │"
    echo "└────────────────────────────────────────────────┘"
    echo ""
    echo "2. Add your Code::Stats API key to Claude Code secrets:"
    echo "┌──────────────────────────────────────────────────┐"
    echo "│ nvim ~/Projects/dotfiles/claude-code/secrets.sh │"
    echo "└──────────────────────────────────────────────────┘"
    echo ""
    echo "3. Configure Claude Code hooks:"
    echo "┌──────────────────────────────┐"
    echo "│ nvim ~/.claude/settings.json │"
    echo "└──────────────────────────────┘"
    echo "See README.md section 'Configure Claude code hooks'"
    echo ""
    echo "4. Restart Neovim to install plugins"
    echo "5. Reload WezTerm configuration (Ctrl+Shift+R)"
    echo ""
    print_info "For more details, see: ~/Projects/dotfiles/README.md"
}

# Main installation flow
main() {
    echo -e "${YELLOW}"
    echo "┌──────────────────────────────┐"
    echo "│ Rolle's dotfiles - Installer │"
    echo "└──────────────────────────────┘"
    echo -e "${NC}"

    detect_os

    if [ "$OS" = "unknown" ]; then
        print_error "Unsupported operating system"
        exit 1
    fi

    # Prompt for installation options
    print_info "Install dependencies (Neovim, Git, etc.)? (Y/n)"
    read -r install_deps
    install_deps=${install_deps:-y}

    print_info "Setup Claude Code integration? (Y/n)"
    read -r setup_claude
    setup_claude=${setup_claude:-y}

    echo ""

    # Run installation steps
    if [[ "$install_deps" =~ ^[Yy]$ ]]; then
        install_dependencies
    fi

    setup_repo
    setup_configs

    if [[ "$setup_claude" =~ ^[Yy]$ ]]; then
        setup_claude_code
    fi

    # Only ask about Syncthing on Linux/macOS
    if [ "$OS" = "linux" ] || [ "$OS" = "macos" ]; then
        install_syncthing
    fi

    print_final_instructions
}

# Run main function
main
