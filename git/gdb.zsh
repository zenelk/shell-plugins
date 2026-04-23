# ZTODO: Should handle multiple remotes.
function_redefine gdb
function gdb() {
  if [ -z "${1}" ]; then
    zk_log_error "Branch name is required."
    return
  fi

  local branch="${1}"
  local confirmation

  printf "Delete local and remote branch '%s'? [y/N] " "${branch}" >&2
  read -r confirmation

  case "${confirmation}" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Deletion cancelled." >&2
      return
      ;;
  esac

  git branch -D "${branch}"
  git push origin ":${branch}"
}

if (( $+functions[compdef] )) && (( $+functions[_git] )); then
  compdef _git gdb=git-branch
fi
