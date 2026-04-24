function_redefine nuke
function nuke() {
  local force=0
  while getopts ":f" opt; do
    case "${opt}" in
    f)
      force=1
      ;;
    *)
      zk_log_usage "nuke [-f]"
      return 1
      ;;
    esac
  done

  if ! git rev-parse --git-dir &>/dev/null; then
    zk_log_error "Not inside a Git repository."
    return 2
  fi

  local preview
  preview="$(git clean -ndx)"
  if [ -n "${preview}" ]; then
    echo "Files that will be removed:" >&2
    echo "${preview}" >&2
  fi

  if [ "${force}" -eq 0 ]; then
    local confirmation
    printf "This will reset you to a fresh checkout state. Continue? [y/N] " >&2
    read -r confirmation
    case "${confirmation}" in
      y|Y|yes|YES)
        ;;
      *)
        echo "Nuke cancelled." >&2
        return
        ;;
    esac
  fi

  git reset --hard HEAD
  local reset_exit="${?}"
  if [ "${reset_exit}" -ne 0 ]; then
    zk_log_error "Reset failed with exit code '${reset_exit}'."
    return "${reset_exit}"
  fi

  git clean -fdx
  local clean_exit="${?}"
  if [ "${clean_exit}" -ne 0 ]; then
    zk_log_error "Clean failed with exit code '${clean_exit}'."
    return "${clean_exit}"
  fi

  zk_log_success "Repository reset to a clean checkout state."
}
