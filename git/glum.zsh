function_redefine glum
function glum() {
  if ! git rev-parse --git-dir &>/dev/null; then
    zk_log_error "Not inside a Git repository."
    return 1
  fi

  if ! git remote get-url upstream &>/dev/null; then
    zk_log_error "Remote 'upstream' is not configured."
    return 2
  fi

  local git_dir
  git_dir="$(git rev-parse --git-dir)"

  if git rev-parse --verify MERGE_HEAD &>/dev/null; then
    zk_log_error "A merge is already in progress. Resolve it first."
    return 10
  fi

  if [ -d "${git_dir}/rebase-merge" ] || [ -d "${git_dir}/rebase-apply" ]; then
    zk_log_error "A rebase is already in progress. Resolve it first."
    return 11
  fi

  if git rev-parse --verify CHERRY_PICK_HEAD &>/dev/null; then
    zk_log_error "A cherry-pick is already in progress. Resolve it first."
    return 12
  fi

  local upstream_branch
  upstream_branch="$(git symbolic-ref --quiet --short refs/remotes/upstream/HEAD 2>/dev/null)"

  if [ -n "${upstream_branch}" ]; then
    upstream_branch="${upstream_branch#upstream/}"
  else
    upstream_branch="$(git remote show upstream 2>/dev/null | sed -n 's/.*HEAD branch: //p' | head -n1)"
  fi

  if [ -z "${upstream_branch}" ]; then
    zk_log_error "Could not determine primary branch from upstream."
    return 1
  fi

  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"

  zk_log_status "Pulling upstream/${upstream_branch} into ${current_branch}..."

  git pull upstream "${upstream_branch}" --no-edit
  local pull_exit="${?}"

  if [ "${pull_exit}" -ne 0 ]; then
    if git rev-parse --verify MERGE_HEAD &>/dev/null; then
      zk_log_warn "Merge conflict detected. Repo left in merge state."
    else
      zk_log_error "Pull failed with exit code '${pull_exit}'."
    fi
    return "${pull_exit}"
  fi

  zk_log_success "Successfully pulled 'upstream/${upstream_branch}' into '${current_branch}'."
}
