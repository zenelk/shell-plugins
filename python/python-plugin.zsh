export PYENV_ROOT="${HOME}/.pyenv"

ZK_VENV_ROOT="${HOME}/.venv"

if ! command -v pyenv >/dev/null; then
  local input

  printf "Pyenv is not installed and is required for the 'python' plugin! Do you want to install? [y/n] " >&2
  read input

  if [ "${input}" != 'y' ]; then
    zk_log_status "Cancelling loading the plugin."
    return 1
  fi

  # ZTODO: This won't work for Arch.
  zk_log_status "Running 'brew install pyenv'..."
  brew install pyenv

  if ! command -v pyenv >/dev/null; then
    zk_log_error "Could not verify Pyenv installation. Cancelling loading the plugin."
    return 1
  fi

  zk_log_success "Pyenv installed successfully."
  printf "Do you want to install latest '3.x.x' Python? [y/n] "
  read input

  if [ "${input}" = 'y' ]; then
    zk_log_status "Installing latest '3.x.x' Python with Pyenv. This may take a while..."
    pyenv install 3
    pyenv global 3
    zk_log_success "Install complete. Continuing loading the rest of the plugin..."
  else
    zk_log_status "Skipping Python install. Make sure default your Python version is set up."
  fi
fi


# Initialize pyenv only when first needed, then remove wrappers so `venv` can own Python paths.
function_redefine _python_init
function _python_init() {
  if [[ -n "${ZK_PYENV_INITIALIZED}" ]]; then
    return 0
  fi

  if [[ -d "${PYENV_ROOT}/bin" ]]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
  fi

  if ! command -v pyenv >/dev/null 2>&1; then
    zk_log_error "Command 'pyenv' is not available. Cannot initialize Python plugin."
    return 1
  fi

  # Skip rehash at shell startup. Shims can be rebuilt manually with `pyenv rehash` when needed.
  # Many `pyenv` operations rehash automatically. If you install a tool with `pip` and it's not found in a venv,
  # it probably means that you need to rehash.
  eval "$(pyenv init - --no-rehash zsh)"
  ZK_PYENV_INITIALIZED=1
}

function_redefine _python_lazy_exec
function _python_lazy_exec() {
  local command_name="${1}"
  shift

  if ! _python_init; then
    return 1
  fi

  _python_remove_lazy_wrappers
  rehash
  command "${command_name}" "$@"
}

function_redefine _python_remove_lazy_wrappers
function _python_remove_lazy_wrappers() {
  # Remove wrappers after first successful initialization so command resolution follows PATH.
  unfunction python python3 pip pip3 pydoc idle >/dev/null 2>&1
}

function_redefine python
function python() {
  _python_lazy_exec python "$@"
}

function_redefine python3
function python3() {
  _python_lazy_exec python3 "$@"
}

function_redefine pip
function pip() {
  _python_lazy_exec pip "$@"
}

function_redefine pip3
function pip3() {
  _python_lazy_exec pip3 "$@"
}

function_redefine pydoc
function pydoc() {
  _python_lazy_exec pydoc "$@"
}

function_redefine idle
function idle() {
  _python_lazy_exec idle "$@"
}

function_redefine venv
function venv() {
  function _venv_usage() {
    zk_log_usage "Usage: venv <verb> [options]"
    zk_log_usage "  <verb> (default: list) is one of:"
    zk_log_usage "    activate   (a)"
    zk_log_usage "    create     (c)"
    zk_log_usage "    deactivate (da)"
    zk_log_usage "    destroy    (d)"
    zk_log_usage "    help       (h)"
    zk_log_usage "    list       (l)"
    zk_log_usage "    recreate   (r)"
    zk_log_usage "  [options] are arguments defined in their respective verbs"
  }

  # This is a ZSH-specific associative array. The keys must exactly match when accessing values, including quotation. Careful!
  typeset -A verb_functions
  verb_functions=(
    # Primary function keys
    'activate'   '_venv_activate'
    'create'     '_venv_create'
    'destroy'    '_venv_destroy'
    'deactivate' '_venv_deactivate'
    'help'       '_venv_usage'
    'list'       '_venv_list'
    'recreate'   '_venv_recreate'

    # Aliases
    'a'  '_venv_activate'
    'c'  '_venv_create'
    'd'  '_venv_destroy'
    'da' '_venv_deactivate'
    'h'  '_venv_usage'
    'l'  '_venv_list'
    'r'  '_venv_recreate'
  )

  local verb="${1:-l}"

  if [ -n "${1}" ]; then
    shift
  fi

  eval "${verb_functions[${verb}]} ${@}"
}

function_redefine _inside_venv
function _inside_venv() {
  if [[ "$(command -v python)" =~ ${ZK_VENV_ROOT}/.* ]]; then
    return 0
  fi

  return 1
}

function_redefine _current_venv_name
function _current_venv_name() {
  if _inside_venv; then
    command -v python | sed "s|${ZK_VENV_ROOT}/||" | cut -d '/' -f 2
  else
    echo
  fi
}

function_redefine _python_version
function _python_version() {
  _python_init || return 1
  python --version | cut -d ' ' -f 2
}

function_redefine _venv_deactivate_if_inside
function _venv_deactivate_if_inside() {
  if ! _inside_venv; then
    return 0
  fi

  local current_venv_name="$(_current_venv_name)"
  zk_log_status "Already inside Python virtual environment '${current_venv_name}'. Deactivating..."
  _venv_deactivate
}

function_redefine _venv_activate
function _venv_activate() {
  function _venv_activate_usage() {
    zk_log_usage "Usage: venv activate <venv_name>"
  }

  _venv_deactivate_if_inside

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    zk_log_error "Missing target virtual environment name."
    _venv_activate_usage
    return 1
  fi

  zk_log_status "Activating Python virtual environment '${target_venv_name}'..."

  _python_init || return 2

  local python_version="$(_python_version)"
  if ! source "${ZK_VENV_ROOT}/${python_version}/${target_venv_name}/bin/activate"; then
    zk_log_error "Failed to activate Python virtual environment '${target_venv_name}."
    return 2
  fi

  _python_remove_lazy_wrappers
  rehash
}

function_redefine _venv_create
function _venv_create() {
  function _venv_create_usage() {
    zk_log_usage "Usage: venv create <venv_name>"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    zk_log_error "Missing target virtual environment name."
    _venv_create_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"
  if [ -d "${venv_path}" ]; then
    zk_log_success "Python virtual environment '${target_venv_name}' already exists."
    return 2
  fi

  zk_log_status "Creating Python virtual environment '${target_venv_name}'..."
  if ! python -m venv "${venv_path}"; then
    zk_log_error "Failed to create Python virtual environment '${target_venv_name}'."
    return 3
  fi
}

function_redefine _venv_deactivate
function _venv_deactivate() {
  local current_venv_name="$(_current_venv_name)"
  zk_log_status "Deactivating Python virtual environment '${current_venv_name}'..."
  if ! deactivate; then
    zk_log_error "Failed to deactivate Python virtual environment '${current_venv_name}'."
    return 1
  fi

  rehash
}

function_redefine _venv_destroy
function _venv_destroy() {
  function _venv_destroy_usage() {
    zk_log_usage "Usage: venv destroy <venv_name>"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    zk_log_error "Missing target virtual environment name."
    _venv_destroy_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"

  zk_log_status "Destroying Python virtual environment: '${target_venv_name}'..."
  if ! rm -rf "${venv_path}"; then
    zk_log_error "Failed to destroy Python virtual environment '${target_venv_name}'."
    return 3
  fi
}

function_redefine _venv_list
function _venv_list() {
  local python_version="$(_python_version)"
  local venvs_path="${ZK_VENV_ROOT}/${python_version}"
  zk_log_status "Python virtual environments for Python version '${python_version}':"
  # ZTODO: There is most certainly a better way to do this.
  for venv in $(ls -1 "${venvs_path}" | grep -v -e '^\.$' -e '^\.\.$'); do
    echo "  ${venv}"
  done
}

function_redefine _venv_recreate
function _venv_recreate() {
  # ZTODO: For when I get reloading working again, do these usage functions get swapped out as expected?
  function _venv_recreate_usage() {
    zk_log_usage "Usage: venv recreate <venv_name>"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    zk_log_error "Missing target virtual environment name."
    _venv_recreate_usage
    return 1
  fi

  _venv_destroy "${target_venv_name}"
  _venv_create "${target_venv_name}"
}
