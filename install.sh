#!/bin/bash
set -e

PYTHON_VERSION="3.13"
GO_VERSION="go1.24.3"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
ZSHRC="$HOME/.zshrc"

install_fonts() {
  echo "Installing Nerd Fonts (MesloLGS)..."
  mkdir -p ~/.local/share/fonts
  cd ~/.local/share/fonts
  curl -fLo "MesloLGS NF Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGS%20NF%20Regular.ttf
  curl -fLo "MesloLGS NF Bold.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGS%20NF%20Bold.ttf
  curl -fLo "MesloLGS NF Italic.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Italic/MesloLGS%20NF%20Italic.ttf
  curl -fLo "MesloLGS NF Bold Italic.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/BoldItalic/MesloLGS%20NF%20Bold%20Italic.ttf
  fc-cache -fv || true
  echo "Fonts installed."
}

install_zsh() {
  echo "Installing Zsh and Oh My Zsh..."
  if ! command -v zsh >/dev/null; then
    if [ "$(uname)" = "Darwin" ]; then
      brew install zsh
    else
      sudo apt update && sudo apt install -y zsh
    fi
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_powerlevel10k() {
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k || true
  if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
  else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
  fi
  grep -q '^[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' "$ZSHRC" || echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$ZSHRC"
}

install_plugins() {
  echo "Installing Zsh plugins..."
  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true
  git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions || true

  if grep -q '^plugins=' "$ZSHRC"; then
    sed -i.bak 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC"
  else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)' >> "$ZSHRC"
  fi
}

setup_zshrc() {
  echo "Copying custom .zshrc from dotfiles directory..."
  if [ -f "$DOTFILES_DIR/.zshrc" ]; then
    cp "$DOTFILES_DIR/.zshrc" "$ZSHRC"
  else
    echo "Warning: No .zshrc found in dotfiles directory."
  fi
  mkdir -p ~/.kube
}

setup_docker_backend_mac() {
  echo "Checking Docker environment on macOS..."
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      echo "Docker is installed and running."
      if docker system info | grep -q "Docker Desktop"; then
        echo "Docker Desktop detected — skipping Colima installation."
      else
        echo "Docker found but not Docker Desktop. You may want to install Colima for better kind support."
      fi
    else
      echo "Docker command found but daemon not running."
      echo "Please start Docker Desktop or install and start Colima."
      exit 1
    fi
  else
    echo "Docker not found. Installing Colima..."
    brew install colima
    colima start
  fi
}

install_dev_tools() {
  echo "Installing development tools..."

  if [ "$(uname)" = "Darwin" ]; then
    brew update

    # Install Python 3.13 - Note: Homebrew usually points `python` to latest stable.
    brew install python@${PYTHON_VERSION}

    # Install kubectl, helm, jq, fzf, ripgrep, direnv, kind, go
    brew install kubectl kubectx helm jq fzf ripgrep direnv kind go

    setup_docker_backend_mac

  else
    sudo apt update

    # Add deadsnakes PPA for bleeding edge python
    if ! grep -q deadsnakes /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      sudo apt install -y software-properties-common
      sudo add-apt-repository -y ppa:deadsnakes/ppa
      sudo apt update
    fi

    sudo apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python3-pip kubectl helm jq fzf ripgrep direnv kind golang-go
  fi

  # Upgrade pip and install virtualenv using the specific python version
  if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
    python${PYTHON_VERSION} -m pip install --upgrade --user pip virtualenv
  else
    echo "Warning: python${PYTHON_VERSION} not found, skipping virtualenv install."
  fi

  # Install gvm and Go version
  if [ ! -d "$HOME/.gvm" ]; then
    echo "Installing gvm (Go Version Manager)..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    # shellcheck disable=SC1090
    source "$HOME/.gvm/scripts/gvm"
    gvm install ${GO_VERSION} -B
    gvm use ${GO_VERSION} --default
  else
    source "$HOME/.gvm/scripts/gvm"
  fi
}

main() {
  echo "Starting dotfiles setup..."

  install_fonts
  install_zsh
  install_powerlevel10k
  install_plugins
  setup_zshrc
  install_dev_tools

  echo "Setup complete! Please restart your terminal session."
}

main "$@"
