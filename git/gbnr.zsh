function_redefine gbnr
function gbnr() {
  if [[ "${1}" = '-d' ]]; then
    echo -e "Deleting the following branches locally:"
  fi

  local branches="$(git branch -vv | cut -c 3- | grep ': gone]' | awk '{print $1}')"

  if [[ -z "${branches}" ]]; then
    echo "No branches found locally that are removed from the remote."
    return 1
  else
    echo "${branches}"
  fi

  if [[ "${1}" = '-d' ]]; then
    echo "${branches}" | xargs git branch -D
  fi

  return 0
}
