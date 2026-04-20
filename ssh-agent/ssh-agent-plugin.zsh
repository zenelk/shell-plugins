# Adapted from code online. Not entirely sure what the original source is since it's been copied around.

if [[ -e ".ssh-init" ]]; then
  soruce ".ssh-init"
fi

# Note: ~/.ssh/environment should not be used, as it already has a different purpose in SSH.
env=~/.ssh/agent.env

# Note: Don't bother checking SSH_AGENT_PID. It's not used by SSH itself, and it might even be incorrect (for example, when using agent-forwarding over SSH).
function_redefine agent_is_running
function agent_is_running() {
  if [ "$SSH_AUTH_SOCK" ]; then
    # ssh-add returns:
    #   0 = agent running, has keys
    #   1 = agent running, no keys
    #   2 = agent not running
    ssh-add -l >/dev/null 2>&1 || [ $? -eq 1 ]
  else
    false
  fi
}

function_redefine agent_has_keys
function agent_has_keys() {
  ssh-add -l >/dev/null 2>&1
}

function_redefine agent_load_env
function agent_load_env() {
  . "$env" >/dev/null
}

function_redefine agent_start
function agent_start() {
  (umask 077; ssh-agent >"$env")
  . "$env" >/dev/null
}

function_redefine agent_add_keys
function agent_add_keys() {
  emulate -L zsh
  setopt localtraps

  local interrupted=0
  trap 'interrupted=1' INT

  # This only handles keys with default names.
  ssh-add
  local ssh_add_exit=$?

  trap - INT

  if (( interrupted || ssh_add_exit == 130 )); then
    echo "Call to ssh-add was cancelled. Continuing shell initialization..."
    return 0
  fi

  return $ssh_add_exit
}

if ! agent_is_running; then
  agent_load_env
fi

if ! agent_is_running; then
  agent_start
  agent_add_keys
elif ! agent_has_keys; then
  agent_add_keys
fi

unset env
