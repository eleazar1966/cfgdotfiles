#! bash oh-my-bash.module
# zork-datetime: based on the stock "zork" theme.
# Identical to zork, except the first prompt line ends with the date and time.

SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

SCM_THEME_PROMPT_DIRTY=" ${_omb_prompt_bold_brown}✗${_omb_prompt_normal}"
SCM_THEME_PROMPT_CLEAN=" ${_omb_prompt_bold_green}✓${_omb_prompt_normal}"
SCM_GIT_CHAR="${_omb_prompt_bold_green}±${_omb_prompt_normal}"
SCM_SVN_CHAR="${_omb_prompt_bold_teal}⑆${_omb_prompt_normal}"
SCM_HG_CHAR="${_omb_prompt_bold_brown}☿${_omb_prompt_normal}"

#Mysql Prompt
export MYSQL_PS1="(\u@\h) [\d]> "

case $TERM in
xterm*)
  TITLEBAR="\[\033]0;\w\007\]"
  ;;
*)
  TITLEBAR=""
  ;;
esac

PS3=">> "

function __my_rvm_ruby_version {
  local gemset=$(awk -F'@' '{print $2}' <<< "$GEM_HOME")
  [[ $gemset ]] && gemset=@$gemset
  local version=$(awk -F'-' '{print $2}' <<< "$MY_RUBY_HOME")
  local full=$version$gemset
  [[ $full ]] && _omb_util_print "[$full]"
}

function is_vim_shell {
  if [[ $VIMRUNTIME ]]; then
    _omb_util_print "[${_omb_prompt_teal}vim shell${_omb_prompt_normal}]"
  fi
}

function modern_scm_prompt {
  local CHAR=$(scm_char)
  if [[ $CHAR == "$SCM_NONE_CHAR" ]]; then
    return
  else
    _omb_util_print "[$(scm_char)][$(scm_prompt_info)]"
  fi
}

# show chroot if exist
function chroot {
  if [[ $debian_chroot ]]; then
    local my_ps_chroot=$_omb_prompt_bold_teal$debian_chroot$_omb_prompt_normal
    _omb_util_print "($my_ps_chroot)"
  fi
}

# show virtualenvwrapper
function my_ve {
  if [[ $VIRTUAL_ENV ]]; then
    local ve=$(basename "$VIRTUAL_ENV")
    local my_ps_ve=$_omb_prompt_bold_purple$ve$_omb_prompt_normal
    _omb_util_print "($my_ps_ve)"
  fi
  _omb_util_print ""
}

# Penguin right after the ┌─ corner. The colour emoji is used on purpose: it
# fills two cells and reads bigger than the single-cell Nerd Font Tux, which
# Iosevka draws small. Kitty renders it through Noto Color Emoji.
OMB_ZORK_DT_TUX=$'\U0001F427'

# Right-aligned date (dd-mm-yyyy, bold yellow) and time (12h with AM/PM, bold
# cyan), each in its own bracket and closed by a box corner (─┐) that answers
# the ┌─ at the start of the line. LC_TIME=C forces the English AM/PM marker
# even though the session locale is Spanish. The cursor is saved, pushed to the
# right margin and stepped back by the exact visible width of the segment, so
# it lands flush with the screen edge without measuring the left-hand side.
function datetime_prompt {
  local ts_date ts_time plain REPLY
  printf -v ts_date '%(%d-%m-%Y)T' -1
  LC_TIME=C printf -v ts_time '%(%I:%M:%S %p)T' -1
  plain="[${ts_date}][${ts_time}]"
  # the +1 is ${#plain} + 2 cells of "─┐" - 1, so the corner ends on the last column
  printf -v REPLY '\[\e7\]\[\e[999C\]\[\e[%dD\]%s[%s]%s%s[%s]%s─┐\[\e8\]' \
    "$((${#plain} + 1))" \
    "$_omb_prompt_bold_yellow" "$ts_date" "$_omb_prompt_normal" \
    "$_omb_prompt_bold_cyan" "$ts_time" "$_omb_prompt_normal"
  _omb_util_print "$REPLY"
}

function _omb_theme_PROMPT_COMMAND {
  local my_ps_host="${_omb_prompt_green}\h${_omb_prompt_normal}"
  # yes, these are the the same for now ...
  local my_ps_host_root="${_omb_prompt_green}\h${_omb_prompt_normal}"

  local my_ps_user="${_omb_prompt_bold_green}\u${_omb_prompt_normal}"
  local my_ps_root="${_omb_prompt_bold_brown}\u${_omb_prompt_normal}"

  # nice prompt
  case $(id -u) in
  0) PS1="${TITLEBAR}┌─${OMB_ZORK_DT_TUX}$(my_ve)$(chroot)[$my_ps_root][$my_ps_host_root]$(modern_scm_prompt)$(__my_rvm_ruby_version)[${_omb_prompt_teal}\w${_omb_prompt_normal}]$(is_vim_shell)$(datetime_prompt)
└─▪ "
     ;;
  *) PS1="${TITLEBAR}┌─${OMB_ZORK_DT_TUX}$(my_ve)$(chroot)[$my_ps_user][$my_ps_host]$(modern_scm_prompt)$(__my_rvm_ruby_version)[${_omb_prompt_teal}\w${_omb_prompt_normal}]$(is_vim_shell)$(datetime_prompt)
└─▪ "
     ;;
  esac
}

PS2="└─▪ "

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
