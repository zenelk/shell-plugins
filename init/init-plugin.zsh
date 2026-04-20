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
