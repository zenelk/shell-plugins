export PYENV_ROOT="${HOME}/.pyenv"

ZK_VENV_ROOT="${HOME}/.venv"

if ! command -v pyenv > /dev/null; then
  local input

  printf "Pyenv is not installed and is required for the 'python' plugin! Do you want to install? [y/n] "
  read input

  if [ "${input}" != 'y' ]; then
    echo "Cancelling loading the plugin!"
    return 1
  fi

  # ZTODO: This won't work for Arch.
  echo "Running 'brew install pyenv'..."
  brew install pyenv

  if ! command -v pyenv; then
    echo "Could not verify Pyenv installation! Cancelling loading the plugin!"
    return 1
  fi

  printf "Pyenv verified. Do you want to install latest '3.x.x' Python? [y/n] "
  read input

  if [ "${input}" = 'y' ]; then
    echo "Installing latest '3.x.x' Python with Pyenv. This may take a while..."
    pyenv install 3
    echo "Install complete! Continuing loading the rest of the plugin..."
  else
    echo "Skipping Python install. Make sure default your Python version is set up!"
  fi
fi

lazyload pyenv python python3 pip pip3 venv -- '[[ -d "${PYENV_ROOT}/bin" ]] && export PATH="${PYENV_ROOT}/bin:${PATH}"; eval "$(pyenv init - zsh)"'

function_redefine venv
function venv() {
  function _venv_usage() {
    echo "Usage: venv [verb] [options]"
    echo "  [verb] (default: list) is one of:"
    echo "    activate   (a)"
    echo "    create     (c)"
    echo "    deactivate (da)"
    echo "    destroy    (d)"
    echo "    help       (h)"
    echo "    list       (l)"
    echo "    recreate   (r)"
    echo "  [options] are arguments defined in their respective verbs"
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
  python --version | cut -d ' ' -f 2
}

function_redefine _venv_deactivate_if_inside
function _venv_decactivate_if_inside() {
  if ! _inside_venv; then
    return 0
  fi

  local current_venv_name="$(_current_venv_name)"
  echo "Already inside Python virtual environment '${current_venv_name}'. Deactivating..."
  _venv_deactivate
}

function_redefine _venv_activate
function _venv_activate() {
  function _venv_activate_usage() {
    echo "Usage: venv activate VENV_NAME"
  }

  _venv_decactivate_if_inside

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_activate_usage
    return 1
  fi

  echo "Activating Python virtual environment '${target_venv_name}'..."

  local python_version="$(_python_version)"
  if ! source "${ZK_VENV_ROOT}/${python_version}/${target_venv_name}/bin/activate"; then
    echo "Failed to activate Python virtual environment '${target_venv_name}!"
    return 2
  fi
}

function_redefine _venv_create
function _venv_create() {
  function _venv_create_usage() {
    echo "Usage: venv create VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_create_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"
  if [ -d "${venv_path}" ]; then
    echo "Python virtual environment '${target_venv_name}' already exists!"
    return 2
  fi

  echo "Creating Python virtual environment '${target_venv_name}'..."
  if ! python -m venv "${venv_path}"; then
    echo "Failed to create Python virtual environment '${target_venv_name}'!"
    return 3
  fi
}

function_redefine _venv_deactivate
function _venv_deactivate() {
  local current_venv_name="$(_current_venv_name)"
  echo "Deactivating Python virtual environment '${current_venv_name}'..."
  if ! deactivate; then
    echo "Failed to deactivate Python virtual environment '${current_venv_name}'!"
    return 1
  fi
}

function_redefine _venv_destroy
function _venv_destroy() {
  function _venv_destroy_usage() {
    echo "Usage: venv destroy VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_destroy_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"

  echo "Destroying Python virtual environment: '${target_venv_name}'..."
  if ! rm -rf "${venv_path}"; then
    echo "Failed to destroy Python virutal environment '${target_venv_name}'!"
    return 3
  fi
}

function_redefine _venv_list
function _venv_list() {
  local python_version="$(_python_version)"
  local venvs_path="${ZK_VENV_ROOT}/${python_version}"
  echo "Python virtual environments for Python version '${python_version}':"
  # ZTODO: There is most certainly a better way to do this.
  for venv in $(ls -1 "${venvs_path}" | grep -v -e '^\.$' -e '^\.\.$'); do
    echo "  ${venv}"
  done
}

function_redefine _venv_recreate
function _venv_recreate() {
  # ZTODO: For when I get reloading working again, do these usage functions get swapped out as expected?
  function _venv_recreate_usage() {
    echo "Usage: venv recreate VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_recreate_usage
    return 1
  fi

  _venv_destroy "${target_venv_name}"
  _venv_create "${target_venv_name}"
}
