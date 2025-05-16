# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

source $ZSH/oh-my-zsh.sh

# Enable Powerlevel10k instant prompt. Should stay close to the top.
if [[ -r ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
fi

# Enable autoenv-like behavior
eval "$(direnv hook zsh)"

# User customizations can go here
export PATH="$HOME/bin:$PATH"
