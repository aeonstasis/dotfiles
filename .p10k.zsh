# ~/.p10k.zsh: Powerlevel10k configuration file.

# Enable instant prompt
[[ ! -f ~/.p10k.zsh ]] && return

# Prompt segments
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)

# Colors and style
POWERLEVEL9K_TIME_FOREGROUND=7
POWERLEVEL9K_TIME_BACKGROUND=4

POWERLEVEL9K_STATUS_OK_BACKGROUND=2
POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1

# Use patched font icons
POWERLEVEL9K_MODE='nerdfont-complete'

# Silence 'Powerlevel10k' prompt
POWERLEVEL9K_DISABLE_RPROMPT=true
