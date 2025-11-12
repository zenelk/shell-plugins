function_redefine repeat_until_fail
function repeat_until_fail() {
  local RED='\033[0;31m'
  local CYAN='\033[0;36m'
  local NO_COLOR='\033[0m'

  local iteration=0
  local last_code=0

  while [ "${last_code}" -eq 0 ]; do
    iteration=$((iteration+1))
    echo -e "${CYAN}--- Starting iteration ${iteration} ---${NO_COLOR}"
    eval "${1}"
    last_code=$?
  done

  echo -e "${RED}--- Last command failed with code '${last_code}' on iteration '${iteration}' ---${NO_COLOR}"
}
