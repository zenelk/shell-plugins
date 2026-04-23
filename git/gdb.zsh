# ZTODO: Should handle multiple remotes.
function_redefine gdb
function gdb() {
  if [ -z "${1}" ]; then
    zk_log_error "Branch name is required."
    return
  fi
  git branch -D "${1}"
  git push origin ":${1}"
}
