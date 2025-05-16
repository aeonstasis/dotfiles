# Dotfiles Setup for WSL2 and macOS

This repository contains dotfiles and an install script to bootstrap a modern, unified development environment for **WSL2 (Ubuntu)** and **macOS (Intel and Apple Silicon)**. It configures:

* **Zsh** with Oh My Zsh and Powerlevel10k prompt
* Nerd fonts (MesloLGS NF)
* Useful Zsh plugins: autosuggestions, syntax highlighting, completions
* Development tooling including:

  * Python 3.13 with virtualenv
  * Go 1.24.3 managed by GVM (Go Version Manager)
  * Kubernetes tooling: kind, kubectl, helm
  * Utilities: jq, fzf, ripgrep, direnv
* Docker backend setup on macOS (Docker Desktop preferred, falls back to Colima)
* Configured `.zshrc` for a consistent shell experience

## Getting Started

### Prerequisites

* **macOS** (Intel or Apple Silicon) or **WSL2 Ubuntu** on Windows
* For macOS:

  * Homebrew installed: [https://brew.sh](https://brew.sh)
* For WSL2 Ubuntu:

  * `sudo` access
  * `curl` installed (`sudo apt install curl`)

### Installation

1. **Clone this repository** (anywhere you like, e.g., `~/.dotfiles`):

   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Run the install script:**

   ```bash
   ./install.sh
   ```

3. **Restart your terminal** or run `exec zsh` to load the new configuration.

### What the script does

* Installs Nerd Fonts (MesloLGS NF) for Powerlevel10k
* Installs Zsh, Oh My Zsh, and Powerlevel10k theme
* Adds recommended Zsh plugins
* Installs Python 3.13 (latest stable bleeding edge) and sets up virtualenv via pip
* Installs Go 1.24.3 via [gvm](https://github.com/moovweb/gvm)
* Installs Kubernetes tools: kind, kubectl, helm
* Installs utilities like jq, fzf, ripgrep, direnv
* On macOS, checks for Docker Desktop; if missing, installs and starts Colima for container backend

### Notes

* **Python version:** The script installs Python 3.13 if available. On some Linux distros or older macOS Homebrew versions, this may not be present yet. Adjust the `PYTHON_VERSION` variable in the script as needed.
* **Go version:** The script uses `go1.24.3` for gvm. Adjust with `GO_VERSION` variable.
* **Docker backend on macOS:** Docker Desktop is preferred. If Docker Desktop is not running or installed, the script installs Colima to provide a lightweight Docker-compatible environment for Kubernetes kind.
* **Windows WSL:** This script assumes Ubuntu on WSL2. Adjust package manager or tools if using different distros.
* **Fonts:** After installation, you may need to configure your terminal emulator (Windows Terminal, iTerm2, etc.) to use the MesloLGS Nerd Font for best Powerlevel10k experience.

### Customization

* The `.zshrc` file is copied from the repository and configures your prompt, plugins, and environment.
* You can edit `.zshrc` or `.p10k.zsh` (Powerlevel10k config) in your home directory to further customize your shell.

### Troubleshooting

* If the Python version is not found, verify if your OS/distribution supports that version or consider installing Python from source or `pyenv`.
* If `gvm` installation fails, check your network connection or manually install from [https://github.com/moovweb/gvm](https://github.com/moovweb/gvm)
* Ensure Docker Desktop or Colima is running before using `kind` or Kubernetes tools.
* Restart your terminal or run `source ~/.zshrc` after installation to apply changes.

### License

MIT License — feel free to reuse and customize as you like.