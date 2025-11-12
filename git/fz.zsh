function_redefine fz
function fz() {
  function find_git_repo_root() {
    local current_dir="$(pwd)"
    local git_dir="$(git rev-parse --show-toplevel 2>/dev/null)"

    if [ -n "${git_dir}" ]; then
      echo "${git_dir}"
    else
      # ZTODO: I'm pretty sure this will make the finding the `.gitignore` file go haywire since there's not a code I'm checking.
      echo "Not inside a Git repository!"
    fi
  }

  function convert_gitignore_to_grep_excludes() {
    local gitignore_file="$(find_git_repo_root)/.gitignore"
    local exclude_options=()

    if [ -f "${gitignore_file}" ]; then
      while IFS= read -r line; do
        # Skip empty lines and comments.
        if [[ -z "${line}" || "${line}" == \#* ]]; then
          continue
        fi

        # Remove leading and trailing whitespace.
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        exclude_options+=("--exclude=${line}")
      done < "${gitignore_file}"
    else
      echo "No .gitignore file found!" >&2
    fi

    echo "${exclude_options[@]}"
  }

  grep \
    -E "ZTODO|ZLOG" \
    --exclude-dir '.git' \
    $(convert_gitignore_to_grep_excludes) \
    -I \
    -r \
    ${1:-.}
}
