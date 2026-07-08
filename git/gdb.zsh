# ZTODO: Should handle multiple remotes.
function_redefine gdb
function gdb() {
  if (( $# == 0 )); then
    zk_log_error "At least one branch name is required."
    return 1
  fi

  local -a branches=("$@")
  local confirmation

  printf "Delete the following local and remote branches?\n" >&2
  for branch in "${branches[@]}"; do
    printf "  - %s\n" "${branch}" >&2
  done
  printf "[y/N] " >&2
  read -r confirmation

  case "${confirmation}" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Deletion cancelled." >&2
      return
      ;;
  esac

  for branch in "${branches[@]}"; do
    git branch -D "${branch}"
  done

  local -a refspecs=("${(@)branches/#/:}")
  git push origin "${refspecs[@]}"
}

function _gdb_branches() {
  local -a all_branches excluded current_word
  all_branches=(${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"})

  current_word="${words[$CURRENT]}"
  excluded=("${(@)words[2,-1]:#${current_word}}")

  local -a filtered=()
  for b in "${all_branches[@]}"; do
    if (( ! ${excluded[(Ie)${b}]} )); then
      filtered+=("${b}")
    fi
  done

  compadd -a filtered
}

function _gdb() {
  _arguments '*:branch:_gdb_branches'
}

if (( $+functions[compdef] )); then
  compdef _gdb gdb
fi
