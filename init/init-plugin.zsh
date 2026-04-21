# ---
# Function Redefinition
# ---
#
# Allows for functions to be reloaded when used like so:
#   function_redefine foo
#   function foo() { ... }
#
# All other plugins use this pattern to allow for functions to be overridden by other plugins if needed.
# This is especially useful for development, as it allows for functions to be reloaded without needing
# to restart the shell.
#
# NOTE: `function_redefine` itself cannot be reloaded and will need a shell restart to pick up changes.

function function_redefine() {
  function function_exists() {
    declare -f "${1}" > /dev/null
  }

  while (( $# )); do
    if function_exists "${1}"; then
      unfunction "${1}"
    fi

    autoload -U "${1}"
    shift
  done
}

# ---
# Logging
# ---
# All diagnostic output goes to stderr, keeping stdout clean for functional output.
# Set ZK_COLOR_ENABLED=1 before sourcing plugins to enable colored log output.
# Set ZK_DEBUG=1 to enable debug-level output.

ZK_COLOR_RESET=$'\033[0m'
ZK_COLOR_RED=$'\033[0;31m'
ZK_COLOR_GREEN=$'\033[0;32m'
ZK_COLOR_YELLOW=$'\033[0;33m'
ZK_COLOR_CYAN=$'\033[0;36m'
ZK_COLOR_DIM=$'\033[2m'

function_redefine _zk_log
function _zk_log() {
  local color="${1}"
  shift

  local use_echo_e=0
  if [[ "${1}" == '-e' ]]; then
    use_echo_e=1
    shift
  fi

  local message=""
  if [[ -n "${ZK_COLOR_ENABLED}" && -n "${color}" ]]; then
    message="${color}${*}${ZK_COLOR_RESET}"
  else
    message="${*}"
  fi

  if (( use_echo_e )); then
    echo -e "${message}" >&2
  else
    echo "${message}" >&2
  fi
}

function_redefine zk_log_status
function zk_log_status() {
  _zk_log "${ZK_COLOR_CYAN}" "$@"
}

function_redefine zk_log_success
function zk_log_success() {
  _zk_log "${ZK_COLOR_GREEN}" "$@"
}

function_redefine zk_log_warn
function zk_log_warn() {
  _zk_log "${ZK_COLOR_YELLOW}" "$@"
}

function_redefine zk_log_error
function zk_log_error() {
  _zk_log "${ZK_COLOR_RED}" "$@"
}

function_redefine zk_log_debug
function zk_log_debug() {
  if [[ -z "${ZK_DEBUG}" ]]; then
    return 0
  fi

  _zk_log "${ZK_COLOR_DIM}" "$@"
}

function_redefine zk_log_usage
function zk_log_usage() {
  _zk_log "" "$@"
}
