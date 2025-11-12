# ZTODO: Should handle mulitple remotes.
function_redefine gdb
function gdb() {
  if [ -z "$1" ]; then
    echo "Branch name is required!"
    return
  fi
  git branch -D "$1"
  git push origin ":$1"
}
