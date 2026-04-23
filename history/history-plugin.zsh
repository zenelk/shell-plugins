_ZK_INIT_LOAD_PATH="${0:a:h}"

# Array of commands to exclude from history in addition to those listed in ignored_commands.
# Plugins loaded before this one may pre-populate this array.
(( ${+ZK_HISTORY_IGNORED_COMMANDS} )) || ZK_HISTORY_IGNORED_COMMANDS=()

# Register one or more commands to be excluded from history at runtime.
# Usage: zk_history_register_ignored <command> [<command> ...]
function_redefine zk_history_register_ignored
function zk_history_register_ignored() {
  ZK_HISTORY_IGNORED_COMMANDS+=("$@")
}

function_redefine _zk_history_read_ignores_from_file
function _zk_history_read_ignores_from_file() {
  while IFS= read -r line; do
    if [[ "${line}" =~ '^#' ]] || [[ -z "${line}" ]]; then
      continue
    fi
    print -- "${line}"
  done < "${_ZK_INIT_LOAD_PATH}/ignored_commands"
}

function_redefine _zk_history_is_ignored
function _zk_history_is_ignored() {
  local -a all_ignored
  all_ignored=($(_zk_history_read_ignores_from_file) "${ZK_HISTORY_IGNORED_COMMANDS[@]}")

  if (( ${#all_ignored} == 0 )); then
    return 1
  fi
  local ignored_regex="^($(echo "${all_ignored[@]}" | tr ' ' '|'))"
  [[ "${1}" =~ $ignored_regex ]]
}

# Hook into zsh's history system. Should not be invoked directly.
function_redefine zshaddhistory
function zshaddhistory() {
  emulate -L zsh

  if [[ "${1}" =~ "^[[:space:]]+" ]]; then
    zk_log_debug "Command starts with whitespace. Not adding to history."
    return 1
  fi

  if ! whence ${${(z)1}[1]} >|/dev/null; then
    zk_log_debug "Command does not exist on the system. Not adding to history."
    return 1
  fi

  if _zk_history_is_ignored "${1}"; then
    zk_log_debug "Command is in ignore list. Not adding to history."
    return 1
  fi
}
