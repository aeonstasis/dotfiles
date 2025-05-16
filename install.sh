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
  # Check if pyenv installed
  if ! command -v pyenv &>/dev/null; then
    echo "Installing pyenv..."
    if [[ "$OS" == "Darwin" ]]; then
      brew update
      brew install pyenv
    else
      # Linux installation dependencies
      sudo apt update
      sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev \
        python3-openssl git
      curl https://pyenv.run | bash
    fi
  else
    echo "pyenv already installed."
  fi

  # Setup pyenv environment for current shell
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  if command -v pyenv &>/dev/null; then
    eval "$(pyenv init -)"
  fi

  # Install Python if not already installed
  if ! pyenv versions --bare | grep -q "^${PYTHON_VERSION}\$"; then
    echo "Installing Python $PYTHON_VERSION via pyenv..."
    pyenv install "$PYTHON_VERSION"
  else
    echo "Python $PYTHON_VERSION already installed via pyenv."
  fi

  pyenv global "$PYTHON_VERSION"

  # Symlink python3-latest to pyenv python executable for convenience
  ln -sf "$(pyenv which python3)" "$HOME/.local/bin/python3-latest" || true

  # Ensure ~/.local/bin is in PATH
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo "Upgrading pip and installing virtualenv..."
  python3-latest -m pip install --upgrade pip virtualenv

  echo "Python $PYTHON_VERSION setup complete via pyenv."
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
