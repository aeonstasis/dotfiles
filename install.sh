#!/usr/bin/env bash

set -euo pipefail

PYTHON_VERSION=3.13
GO_VERSION=go1.24.3

OS=$(uname)
ARCH=$(uname -m)

install_fonts() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if brew list --cask font-hack-nerd-font &>/dev/null; then
      echo "Hack Nerd Font already installed."
    else
      echo "Installing Hack Nerd Font with Homebrew..."
      brew install --cask font-hack-nerd-font
    fi
  else
    if [[ -d "$HOME/.nerd-fonts" ]]; then
      echo "Nerd Fonts repo already cloned."
    else
      echo "Cloning Nerd Fonts repo..."
      git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git ~/.nerd-fonts
    fi
    echo "Installing Hack Nerd Font..."
    ~/.nerd-fonts/install.sh Hack
  fi
}

setup_zsh() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update
    sudo apt install -y zsh git curl wget unzip
  elif [[ "$OS" == "Darwin" ]]; then
    brew install zsh git curl wget unzip || true
  fi

  export RUNZSH=no
  export ZSH="$HOME/.oh-my-zsh"

  if [[ -d "$ZSH" ]]; then
    echo "Removing existing Oh My Zsh at $ZSH"
    rm -rf "$ZSH"
  fi

  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Powerlevel10k theme
  if [[ -d "$ZSH/custom/themes/powerlevel10k" ]]; then
    echo "Updating powerlevel10k theme..."
    git -C "$ZSH/custom/themes/powerlevel10k" pull
  else
    echo "Installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH/custom/themes/powerlevel10k"
  fi

  # Plugins
  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    plugin_path="$ZSH/custom/plugins/$plugin"
    if [[ -d "$plugin_path" ]]; then
      echo "Updating plugin $plugin..."
      git -C "$plugin_path" pull
    else
      echo "Installing plugin $plugin..."
      git clone https://github.com/zsh-users/$plugin "$plugin_path"
    fi
  done

  echo "Copying .zshrc and .p10k.zsh configuration files..."
  cp -f .zshrc ~/.zshrc
  cp -f .p10k.zsh ~/.p10k.zsh
}

install_python() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update
    sudo apt install -y software-properties-common || true
    if ! python3 --version 2>&1 | grep -q "Python ${PYTHON_VERSION}"; then
      sudo add-apt-repository -y ppa:deadsnakes/ppa || true
      sudo apt update
      sudo apt install -y python${PYTHON_VERSION} python3-pip || true
    else
      echo "Python ${PYTHON_VERSION} already installed."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    if brew list python@${PYTHON_VERSION} &>/dev/null; then
      echo "Python@${PYTHON_VERSION} already installed."
    else
      brew install python@${PYTHON_VERSION}
    fi
    brew link --overwrite python@${PYTHON_VERSION} || true
  fi

  # Make sure pip is available and upgrade
  if ! command -v pip3 &>/dev/null; then
    echo "pip3 not found, attempting to install..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
  fi

  python3 -m pip install --upgrade pip virtualenv
}

install_go() {
  if ! command -v gvm &>/dev/null; then
    echo "Installing gvm..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  else
    echo "gvm already installed."
  fi

  if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.gvm/scripts/gvm"
  else
    echo "gvm script not found, skipping Go install."
    return 1
  fi

  (
    set -e
    if ! gvm list | grep -q "${GO_VERSION}"; then
      echo "Installing Go ${GO_VERSION}..."
      gvm install "${GO_VERSION}"
    else
      echo "Go ${GO_VERSION} already installed."
    fi

    gvm use "${GO_VERSION}" --default
  )
}

install_kubernetes_tools() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y kubectl helm || true
  elif [[ "$OS" == "Darwin" ]]; then
    brew install kubectl helm || true
  fi
}

install_utilities() {
  if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y jq fzf ripgrep direnv || true
  elif [[ "$OS" == "Darwin" ]]; then
    brew install jq fzf ripgrep direnv || true
  fi
}

main() {
  install_fonts
  setup_zsh
  install_python
  install_go
  install_kubernetes_tools
  install_utilities

  echo -e "\n✔️ Dotfiles and environment setup complete."
  echo "Please restart your terminal or run 'source ~/.zshrc' to activate all changes."
}

main
