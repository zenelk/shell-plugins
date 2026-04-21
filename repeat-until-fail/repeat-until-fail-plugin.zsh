function_redefine repeat_until_fail
function repeat_until_fail() {
  local iteration=0
  local last_code=0

  while [ "${last_code}" -eq 0 ]; do
    iteration=$((iteration+1))
    zk_log_status "--- Starting iteration ${iteration} ---"
    eval "${1}"
    last_code=$?
  done

  zk_log_status "--- Last command failed with code '${last_code}' on iteration '${iteration}' ---"
}
