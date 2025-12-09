INIT_LOAD_PATH="${0:a:h}"

# Hook for tying into ZSH process for adding to history. Does not add failed commands and specified commands to history.
# ZTODO: This is not working as expected after rad-shell removal and needs some love to register ignored commands.
function_redefine zshaddhistory
function zshaddhistory() {
  function read_ignored_commands() {
    local result=()

    while IFS= read -r line; do
      if [[ "${line}" =~ '^#' ]] || [ -z "${line}" ]; then
        continue
      fi
      result+=("${line}")
    done < "${INIT_LOAD_PATH}/ignored_commands"
  }

  function is_ignored_command() {
    local ignored_commands=($(read_ignored_commands))
    local ignored_regex="^($(echo "${ignored_commands[@]}" | tr ' ' '|'))"

    [[ "${1}" =~ $ignored_regex ]]
  }

  emulate -L zsh

  if ! whence ${${(z)1}[1]} >| /dev/null; then
    echo "[ZK] Command does not exist on the system. Not adding to history."
    return 1
  fi

  if [[ "${1}" =~ "^[[:space:]]+" ]]; then
    echo "[ZK] Command starts with whitespace. Not adding to history."
    return 1
  fi

  if is_ignored_command "${1}"; then
    echo "[ZK] Command is in ignore list. Not adding to history."
    return 1
  fi

  print -sr -- "${1%%$'\n'}"
  fc -p
}
