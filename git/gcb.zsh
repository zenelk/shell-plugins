# Interactive local branch switcher. Lists branches with the repo's primary branch pinned first,
# followed by configured special branches (alphabetical), then all other branches (alphabetical).
# Accepts a numeric selection as an argument, or prompts interactively when none is given.

# Per-repo overrides for special branches, keyed by repo directory basename.
# Plugins sourced after this one may append entries, e.g.:
#   ZK_GIT_SPECIAL_BRANCHES_BY_REPO[my-repo]="develop release/24.1"
typeset -gA ZK_GIT_SPECIAL_BRANCHES_BY_REPO=()

# Exact-equality membership test. Returns 0 if $1 is in the remaining args, 1 otherwise.
function_redefine _zk_gcb_in_array
function _zk_gcb_in_array() {
  local needle="${1}"
  shift

  local candidate
  for candidate in "$@"; do
    if [ "${candidate}" = "${needle}" ]; then
      return 0
    fi
  done

  return 1
}

# Detects the repo's primary branch. Echoes the branch name on stdout when found.
# Prefers origin/HEAD; falls back to local main/master with a warning. Returns 1 if none found.
function_redefine _zk_gcb_primary_branch
function _zk_gcb_primary_branch() {
  local primary
  primary="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  if [ -n "${primary}" ]; then
    echo "${primary#origin/}"
    return 0
  fi

  local candidate
  for candidate in main master; do
    if git show-ref --verify --quiet "refs/heads/${candidate}"; then
      zk_log_warn "origin/HEAD not set; using local '${candidate}' as primary branch."
      echo "${candidate}"
      return 0
    fi
  done

  zk_log_warn 'Could not determine primary branch (no origin/HEAD and no local main/master).'
  return 1
}

# Resolves the special-branches list for the current repo: per-repo override if set,
# else the global ZK_GIT_SPECIAL_BRANCHES. Echoes one branch name per line.
function_redefine _zk_gcb_special_branches
function _zk_gcb_special_branches() {
  local repo_key
  repo_key="$(basename "$(git rev-parse --show-toplevel)")"

  local override="${ZK_GIT_SPECIAL_BRANCHES_BY_REPO[${repo_key}]}"
  if [ -n "${override}" ]; then
    local branch
    for branch in ${=override}; do
      echo "${branch}"
    done

    return 0
  fi

  local branch
  for branch in "${ZK_GIT_SPECIAL_BRANCHES[@]}"; do
    echo "${branch}"
  done
}

function_redefine gcb
function gcb() {
  local force=0
  while getopts ":f" opt; do
    case "${opt}" in
      f)
        force=1
        ;;
      *)
        zk_log_usage 'gcb [-f] [<index>]'
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  if ! git rev-parse --git-dir &>/dev/null; then
    zk_log_error 'Not inside a Git repository.'
    return 2
  fi

  local branch
  local all_branches=()
  while IFS= read -r branch; do
    all_branches+=("${branch}")
  done < <(git for-each-ref --sort=refname --format='%(refname:short)' refs/heads/)

  if [ "${#all_branches[@]}" -eq 0 ]; then
    zk_log_error 'No local branches found.'
    return 1
  fi

  local primary=''
  primary="$(_zk_gcb_primary_branch)"

  local special_branches=()
  while IFS= read -r branch; do
    [ -n "${branch}" ] && special_branches+=("${branch}")
  done < <(_zk_gcb_special_branches)

  local ordered=()
  if [ -n "${primary}" ] && _zk_gcb_in_array "${primary}" "${all_branches[@]}"; then
    ordered+=("${primary}")
  fi

  for branch in "${special_branches[@]}"; do
    if [ "${branch}" = "${primary}" ]; then
      continue
    fi

    if _zk_gcb_in_array "${branch}" "${all_branches[@]}" \
      && ! _zk_gcb_in_array "${branch}" "${ordered[@]}"; then
      ordered+=("${branch}")
    fi
  done

  for branch in "${all_branches[@]}"; do
    if ! _zk_gcb_in_array "${branch}" "${ordered[@]}"; then
      ordered+=("${branch}")
    fi
  done

  local branch_count="${#ordered[@]}"
  local selection="${1}"

  if [ -z "${selection}" ]; then
    local i=1
    for branch in "${ordered[@]}"; do
      echo "${i}) ${branch}" >&2
      i=$((i + 1))
    done

    local input
    while [ -z "${selection}" ]; do
      printf "Enter number to switch to [1-%d]: " "${branch_count}" >&2
      read -r input
      case "${input}" in
        ''|*[!0-9]*)
          echo "Not a number. Try again." >&2
          ;;
        *)
          if [ "${input}" -lt 1 ] || [ "${input}" -gt "${branch_count}" ]; then
            echo "Out of bounds. Try again." >&2
          else
            selection="${input}"
          fi
          ;;
      esac
    done
  else
    case "${selection}" in
      ''|*[!0-9]*)
        zk_log_error "Selection '${selection}' is not a number."
        return 1
        ;;
    esac

    if [ "${selection}" -lt 1 ] || [ "${selection}" -gt "${branch_count}" ]; then
      zk_log_error "Selection '${selection}' is out of bounds [1-${branch_count}]."
      return 1
    fi
  fi

  local target="${ordered[${selection}]}"
  if [ "${force}" -eq 1 ]; then
    git checkout -f "${target}"
  else
    git checkout "${target}"
  fi
}
