#!/usr/bin/env bash

set -euo pipefail

PYTHON_VERSION=3.13
GO_VERSION=go1.24.3

OS=$(uname)
ARCH=$(uname -m)

# Font installation
install_fonts() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing Hack Nerd Font with Homebrew..."
    brew install font-hack-nerd-font || echo "Font already installed or not available"
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

  export RUNZSH=no
  export ZSH="$HOME/.oh-my-zsh"
  rm -rf "$ZSH"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH/custom/themes/powerlevel10k" || \
    git -C "$ZSH/custom/themes/powerlevel10k" pull

  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    plugin_path="$ZSH/custom/plugins/$plugin"
    if [[ -d "$plugin_path" ]]; then
      git -C "$plugin_path" pull
    else
      git clone https://github.com/zsh-users/$plugin "$plugin_path"
    fi
  done

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
    sudo apt install -y python3.13 python3.13-venv python3.13-distutils python3.13-dev python3-pip

    # Symlink python3.13 binary to /usr/local/bin if not exists
    if [[ ! -f /usr/local/bin/python3.13 ]]; then
      sudo ln -s "$(which python3.13)" /usr/local/bin/python3.13
    fi

    # Install pip for python3.13 specifically
    curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.13

    # Use pip3.13 to install virtualenv
    sudo python3.13 -m pip install --upgrade pip virtualenv

    # Optionally create a default virtualenv in ~/.venvs/default
    mkdir -p ~/.venvs
    python3.13 -m virtualenv ~/.venvs/default

  elif [[ "$OS" == "Darwin" ]]; then
    brew install python@3.13
    # Create alias or symlink for python3.13 (Homebrew usually links automatically)
    # Install virtualenv globally
    python3.13 -m pip install --upgrade pip virtualenv
    mkdir -p ~/.venvs
    python3.13 -m virtualenv ~/.venvs/default
  fi
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