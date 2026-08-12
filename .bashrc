export PATH="/usr/bin:$PATH"
# Iniciar automáticamente tmux
#if [ -z "$TMUX" ]; then
# Verificar si existe una sesión llamada 'default', si no, crearla
#  tmux attach-session -t default 2>/dev/null || tmux new-session -s default
#fi
# Enable the subsequent settings only in interactive sessions
#case $- in
#  *i*) ;;
#    *) return;;
#esac

# Path to your oh-my-bash installation.
export OSH='/home/eleazar/.oh-my-bash'

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
#OSH_THEME="font"
OSH_THEME="powerline-multiline"

# If you set OSH_THEME to "random", you can ignore themes you don't like.
# OMB_THEME_RANDOM_IGNORED=("powerbash10k" "wanelo")
# You can also specify the list from which a theme is randomly selected:
# OMB_THEME_RANDOM_CANDIDATES=("font" "powerline-light" "minimal")

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you don't want the repository to be considered dirty
# if there are untracked files.
# SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

# Uncomment the following line if you want to completely ignore the presence
# of untracked files in the repository.
# SCM_GIT_IGNORE_UNTRACKED="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.  One of the following values can
# be used to specify the timestamp format.
# * 'mm/dd/yyyy'     # mm/dd/yyyy + time
# * 'dd.mm.yyyy'     # dd.mm.yyyy + time
# * 'yyyy-mm-dd'     # yyyy-mm-dd + time
# * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
# * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
# * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
# If not set, the default value is 'yyyy-mm-dd'.
# HIST_STAMPS='yyyy-mm-dd'

# Uncomment the following line if you do not want OMB to overwrite the existing
# aliases by the default OMB aliases defined in lib/*.sh
# OMB_DEFAULT_ALIASES="check"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

# To disable the uses of "sudo" by oh-my-bash, please set "false" to
# this variable.  The default behavior for the empty value is "true".
OMB_USE_SUDO=true

# To enable/disable display of Python virtualenv and condaenv
# OMB_PROMPT_SHOW_PYTHON_VENV=true  # enable
# OMB_PROMPT_SHOW_PYTHON_VENV=false # disable

# To enable/disable Spack environment information
# OMB_PROMPT_SHOW_SPACK_ENV=true  # enable
# OMB_PROMPT_SHOW_SPACK_ENV=false # disable

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
completions=(
  git
  composer
  ssh
)

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant composer git-avh)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
  general
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bashmarks
)

# Which plugins would you like to conditionally load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(tmux-autoattach)
#  fi

# If you want to reduce the initialization cost of the "tput" command to
# initialize color escape sequences, you can uncomment the following setting.
# This disables the use of the "tput" command, and the escape sequences are
# initialized to be the ANSI version:
#
#OMB_TERM_USE_TPUT=no

source "$OSH"/oh-my-bash.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

export XCURSOR_THEME="Dracula-cursors"
export XCURSOR_SIZE=5

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-bash libs,
# plugins, and themes. Aliases can be placed here, though oh-my-bash
# users are encouraged to define aliases within the OSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias bashconfig="mate ~/.bashrc"
# alias ohmybash="mate ~/.oh-my-bash"
alias actualizar="~/.local/bin/actualizar.sh"
alias kernel=~/.local/bin/kernel-do.sh
alias respaldo=~/.local/bin/respaldo.sh
export VDPAU_DRIVER=radeonsi
export LANG=es_VE.UTF-8
alias cfg='/usr/bin/git --git-dir=$HOME/.cfgdotfiles/ --work-tree=$HOME'
alias grabavideo="~/.local/bin/graba_video.sh"
alias update-git="~/.local/bin/actualiza_git.sh"
alias crrcsim='SDL_VIDEODRIVER=x11 crrcsim'
alias zstat='watch -n 1 "zramctl && echo --- && df -h /var/tmp/portage"'
alias eclean-dist='sudo eclean-dist --deep'
alias winbox='QT_QPA_PLATFORM=xcb /home/eleazar/Documentos/Mikrotik/Winbox_Linux/WinBox'
alias ventoy='xhost +SI:localuser:root > /dev/null 2>&1; QT_QPA_PLATFORM=xcb /home/eleazar/Documentos/Linux/Gentoo/ventoy-1.1.17/VentoyGUI.x86_64'
alias gparted='pkexec --user root gparted'
alias moc="~/.local/bin/kitty-moc"
alias niri-help="~/.local/bin/ayuda-niri.sh"
alias qemuvm='~/.local/bin/qemu-creator.sh'
export RUSTICL_ENABLE=amdgpu
source -- ~/.local/share/blesh/ble.sh
alias gentle-ai='/home/eleazar/.local/bin/gentle-ai'
alias mikrotik='~/.local/bin/conectar.sh'
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"


# opencode
export PATH=/home/eleazar/.opencode/bin:$PATH
export PATH="${HOME}/.npm-global/bin:${PATH}"
export TMPDIR=/var/tmp/tmpfs

# OpenCode Free Models - API Keys (set these with your keys)
export OPENROUTER_API_KEY="key_CdWoao6yuYdikPeiNqReX"
# export GEMINI_API_KEY="AIza..."
# # export GROQ_API_KEY="gsk_..." (blocked in your region)

export TOGETHER_API_KEY="tgp_..."  # https://api.together.xyz/settings/api-keys

# MikroTik (conectar.sh)
export MIKROTIK_USER='eleazar'
export MIKROTIK_PASS='Eleazar-1966'

# Podman rootless: socket Docker-compatible (compose/tools)
export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
