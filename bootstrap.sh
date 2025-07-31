#!/usr/bin/env bash
set -euo pipefail

REPO="git@github.com:WilliamAppleton/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

echo "🚀 Bootstrapping dotfiles and environment"

# 1. Detect OS and install essential packages
echo "📦 Detecting OS and installing packages (requires sudo)..."

install_arch() {
    sudo pacman -Syu --needed --noconfirm \
        git base-devel kitty alacritty btop remmina mako psensor code \
        brave-bin bitwarden protonmail-bridge fastfetch wget curl
}

install_debian() {
    sudo apt update && sudo apt install -y \
        git build-essential kitty alacritty btop remmina \
        mako-notifier psensor code wget curl

    echo "⚠️ Some packages (brave, protonmail-bridge, bitwarden) require manual or APT repo setup on Debian."
}

if command -v pacman &>/dev/null; then
    echo "🟢 Arch Linux detected"
    install_arch
elif command -v apt &>/dev/null; then
    echo "🟠 Debian/Ubuntu detected"
    install_debian
else
    echo "🔴 Unsupported distribution. Exiting."
    exit 1
fi

# 2. Clone bare dotfiles repo
if [ -d "$DOTFILES_DIR" ]; then
    echo "✅ Dotfiles repo already exists at $DOTFILES_DIR"
else
    echo "📥 Cloning dotfiles repo..."
    git clone --bare "$REPO" "$DOTFILES_DIR"
fi

# 3. Setup dotgit alias
alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# 4. Configure Git to hide untracked files
dotgit config status.showUntrackedFiles no

# 5. Backup and restore dotfiles
echo "📂 Backing up any pre-existing dotfiles..."
mkdir -p "$HOME/.dotfiles-backup"
dotgit checkout || {
    echo "⚠️  Some files would be overwritten. Moving them to ~/.dotfiles-backup/"
    conflicted_files=$(dotgit checkout 2>&1 | grep '\s\.\w' | awk '{print $1}')
    for file in $conflicted_files; do
        mkdir -p "$(dirname "$HOME/.dotfiles-backup/$file")"
        mv "$HOME/$file" "$HOME/.dotfiles-backup/$file"
    done
    dotgit checkout
}

# 6. Set excludesfile
dotgit config core.excludesfile ~/.gitignore

# 7. Final alias persistence
echo "🔧 Adding 'dotgit' alias to your shell config..."
SHELL_RC="$HOME/.bashrc"
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_RC="$HOME/.zshrc"
fi
if ! grep -q "dotgit" "$SHELL_RC"; then
    echo "alias dotgit='/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> "$SHELL_RC"
fi

echo "🎉 Environment setup complete!"
echo "✅ Dotfiles restored"
echo "✅ Packages installed"
echo "💡 Tip: restart your shell or run 'source $SHELL_RC' to use dotgit"


