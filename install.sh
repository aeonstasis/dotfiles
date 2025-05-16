#!/usr/bin/env bash

set -euo pipefail

PYTHON_VERSION=3.13.0
GO_VERSION=go1.24.3

OS=$(uname)
ARCH=$(uname -m)

install_fonts() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)" # for Apple Silicon
    fi
    echo "Installing Hack Nerd Font with Homebrew..."
    brew tap homebrew/cask-fonts || true
    brew install --cask font-hack-nerd-font || echo "Font already installed or not available"
  else
    echo "Installing Hack Nerd Font from source..."
    if [[ ! -d ~/.nerd-fonts ]]; then
      git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git ~/.nerd-fonts
      ~/.nerd-fonts/install.sh Hack
    else
      echo "Nerd Fonts repo already cloned."
    fi
  fi
}

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

install_pyenv() {
  # pyenv install for Python version management
  if ! command -v pyenv &>/dev/null; then
    echo "Installing pyenv..."
    if [[ "$OS" == "Darwin" ]]; then
      brew install pyenv
    else
      curl https://pyenv.run | bash
      # Add pyenv to shell
      export PATH="$HOME/.pyenv/bin:$PATH"
      eval "$(pyenv init --path)"
      eval "$(pyenv init -)"
    fi
  fi

  # Install Python version if not installed
  if ! pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
    pyenv install ${PYTHON_VERSION}
  fi

  pyenv global ${PYTHON_VERSION}
  pyenv rehash

  # Upgrade pip and install virtualenv
  pip install --upgrade pip virtualenv
}

install_go() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y bison curl git make
  elif [[ "$OS" == "Darwin" ]]; then
    brew install bison curl git make
  fi

  # Install gvm
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

  # Define missing env vars to avoid unbound variable errors with set -u
  export ZSH_VERSION=${ZSH_VERSION:-}
  export GVM_DEBUG=${GVM_DEBUG:-0}

  [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

  if ! gvm list | grep -q "$GO_VERSION"; then
    gvm install ${GO_VERSION}
  fi
  gvm use ${GO_VERSION} --default
}

install_utilities() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y jq fzf ripgrep direnv
  elif [[ "$OS" == "Darwin" ]]; then
    brew install jq fzf ripgrep direnv
  fi
}

main() {
  install_fonts
  setup_zsh
  install_pyenv
  install_go
  install_utilities

  echo -e "\n✔️ Dotfiles and environment setup complete. Restart your terminal or run 'exec zsh'."
}

main
