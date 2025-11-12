export ZSH="${HOME}/.oh-my-zsh"

# Update automatically without confirmation. Other modes are:
# - reminder: Post a reminder every time the shell starts when it's time to update.
# - disabled: Do not notify for updates or update automatically.
zstyle ':omz:update' mode auto

# Manual theme installation
# ZTODO: I should try doing this with `zgen` instead of manually.

# ZSH_THEME='candy' # ZTODO: I like this one, but I live having more Git information in my prompt.
ZSH_CUSTOM="${ZSH}/custom"
ZSH_THEME_LOCATION="${ZSH_CUSTOM}/themes"
if [ ! -d "${ZSH_THEME_LOCATION}" ]; then
	echo "No theme location found. Creating one at '${ZSH_THEME_LOCATION}'..."
  mkdir -p "${ZSH_THEME_LOCATION}"
fi
if [ ! -e "${ZSH_THEME_LOCATION}/git-taculous.zsh-theme" ]; then
  echo "Git-taculous theme not found. Downloading..."
  # ZTODO: I should fork / copy this and maintain it myself.
  curl -so "${ZSH_THEME_LOCATION}/git-taculous.zsh-theme" 'https://raw.githubusercontent.com/brandon-fryslie/rad-plugins/refs/heads/master/git-taculous-theme/git-taculous.zsh-theme'
fi
ZSH_THEME='git-taculous'

# Manual syntax highlighting installation
# ZTODO: I should try doing this with `zgen` instead of manually and copy-pasting.

ZSH_SYNTAX_HIGHLIGHTING_LOCATION="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
if [ ! -e "${ZSH_SYNTAX_HIGHLIGHTING_LOCATION}" ]; then
  echo "No clone of zsh-syntax-highlighting found. Cloning to '${ZSH_SYNTAX_HIGHLIGHTING_LOCATION}'..."
  git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_SYNTAX_HIGHLIGHTING_LOCATION}"
fi
plugins=(zsh-syntax-highlighting)

# Manual lazyload installation
# ZTODO: I should try doing this with `zgen` instead of manually and copy-pasting.

ZSH_LAZYLOAD_LOCATION="${ZSH_CUSTOM}/plugins/zsh-lazyload"
if [ ! -e "${ZSH_LAZYLOAD_LOCATION}" ]; then
  echo "No clone of zsh-lazyload found. Cloning to '${ZSH_LAZYLOAD_LOCATION}'..."
  git clone "httys://github.com/qoomon/zsh-lazyload.git"
fi
plugins+=(zsh-lazyload)

source "${ZSH}/oh-my-zsh.sh"
