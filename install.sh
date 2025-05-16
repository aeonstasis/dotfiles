#!/usr/bin/env bash

set -euo pipefail

PYTHON_VERSION=3.13
GO_VERSION=go1.24.3

OS=$(uname)
ARCH=$(uname -m)
SKIP_ZSH_BACKUP=${SKIP_ZSH_BACKUP:-false}

# Font installation
install_fonts() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing Hack Nerd Font with Homebrew..."
    brew tap homebrew/cask-fonts || true
    brew install --cask font-hack-nerd-font || echo "Font already installed or cask not available"
  else
    echo "Installing Hack Nerd Font from source..."
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git ~/.nerd-fonts
    ~/.nerd-fonts/install.sh Hack
  fi
}

# Install Zsh, Oh My Zsh, Powerlevel10k and plugins
setup_zsh() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update
    sudo apt install -y zsh git curl wget unzip
  elif [[ "$OS" == "Darwin" ]]; then
    brew install zsh git curl wget unzip
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    export RUNZSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh already installed, skipping installation."
  fi

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || \
    git -C "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" pull

  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    plugin_path="$HOME/.oh-my-zsh/custom/plugins/$plugin"
    if [[ -d "$plugin_path" ]]; then
      git -C "$plugin_path" pull
    else
      git clone https://github.com/zsh-users/$plugin "$plugin_path"
    fi
  done

  if [[ "$SKIP_ZSH_BACKUP" != "true" ]]; then
    echo "Backing up existing .zshrc and .p10k.zsh if present..."
    [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.backup.$(date +%s)
    [[ -f ~/.p10k.zsh ]] && mv ~/.p10k.zsh ~/.p10k.zsh.backup.$(date +%s)
  fi

  cp .zshrc ~/.zshrc
  cp .p10k.zsh ~/.p10k.zsh
}

# Install Python and virtualenv
install_python() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python${PYTHON_VERSION} python3-pip
  elif [[ "$OS" == "Darwin" ]]; then
    brew install python@${PYTHON_VERSION}
    brew link --overwrite python@${PYTHON_VERSION}
  fi

  python3 -m pip install --upgrade pip virtualenv
}

# Install Go using GVM
install_go() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y bison curl git make
  elif [[ "$OS" == "Darwin" ]]; then
    brew install bison curl git make
  fi

  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

  gvm install ${GO_VERSION}
  gvm use ${GO_VERSION} --default
}

# Install Kubernetes tools
install_kubernetes_tools() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y kubectl helm
  elif [[ "$OS" == "Darwin" ]]; then
    brew install kubectl helm
  fi

  curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.22.0/kind-${OS,,}-${ARCH}"
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
}

# Install utilities
install_utilities() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y jq fzf ripgrep direnv
  elif [[ "$OS" == "Darwin" ]]; then
    brew install jq fzf ripgrep direnv
  fi
}

# Docker setup on macOS
setup_docker_macos() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! docker info &>/dev/null; then
      echo "Docker Desktop not detected, installing Colima..."
      brew install colima
      colima start
    fi
  fi
}

main() {
  install_fonts
  setup_zsh
  install_python
  install_go
  install_kubernetes_tools
  install_utilities
  setup_docker_macos

  echo -e "\n✔️ Dotfiles and environment setup complete. Restart your terminal."
}

main