# ZTODO: Needs a style pass for consistency.

# Defines the root of the search context.
ZK_CODE_ROOT="${HOME}/code"

function_redefine
function sr() {
  local quick_select_none='none'
  local quick_select_root='-'

  function isRootSet() {
    if ! [ -z "${ZK_CODE_ROOT}" ]; then
      return 0
    fi

    return 1
  }

  function isInteger() {
    if [[ "${1}" =~ '^[0-9]+$' ]]; then
      return 0
    fi

    return 1
  }

  function printUnsupportedArgumentError() {
    zk_log_error "Unsupported argument '${1}' at position '${2}'."
  }

  function validateArguments() {
    case $# in
    0|1)
      return 0
      ;;
    2)
      if ! isInteger "${1}"; then
        printUnsupportedArgumentError "${1}" 1
        return 1
      elif ! isInteger "${2}"; then
        printUnsupportedArgumentError "${2}" 2
        return 1
      fi

      return 0
      ;;
    *)
      zk_log_error "Invalid number of arguments."
      # ZTODO: Make a usage function.
      return 1
      ;;
    esac
  }

  function parseQuickSelectArgument() {
    if [ -z "${1}" ]; then
      echo "${quick_select_none}"
    else
      echo "${1}"
    fi
  }

  function statOrgs() {
    local orgs=()

    for fd in "${ZK_CODE_ROOT}"/*; do
      if [ ! -d "${fd}" ]; then
        zk_log_warn "File is not a directory: '${fd}'."
        continue
      fi

      local org="$(basename "${fd}")"
      orgs+=("${org}")
    done

    echo "${orgs[@]}"
  }

  function statRepos() {
    local repos=()
    local org_path="${ZK_CODE_ROOT}/${1}"

    for fd in "${org_path}"/*; do
      if [ ! -d "${fd}" ]; then
        zk_log_warn "File is not a directory: '${fd}'."
        continue
      fi

      local repo="$(basename "${fd}")"
      repos+=("${repo}")
    done

    echo "${repos[@]}"
  }

  function echoFormattedPromptLine() {
    echo "  ${1}): ${2}" >&2
  }

  function echoFormattedPromptArray() {
    local array=(${@})
    local count="${#}"
    local i=1

    for element in $array; do
      echoFormattedPromptLine "${i}" "${element}"
      i=$((i+1))
    done
  }

  function readSelectionInputFromArray() {
    local array=(${@})
    local count="${#}"
    local selection=''
    local input=''

    while [ -z "${selection}" ]; do
      printf "Enter selection [1-${count}]: " >&2

      read input

      case "${input}" in
      ''|*[!0-9]*)
        echo "Not a number. Try again." >&2
        ;;
      *)
        if [ "${input}" -lt 1 ] || [ "${input}" -gt "${count}" ]; then
          echo "Out of bounds. Try again." >&2
        else
          selection="${input}"
        fi
        ;;
      esac
    done

    echo "${array["${selection}"]}"
  }

  function produceSelectionIndex() {
    local quick_select_index="${1}"
    local section_header="${2}"

    shift 2

    local array=(${@})
    local count="${#}"

    if [ "${quick_select_index}" = "${quick_select_none}" ]; then
      if [ "${count}" -eq 1 ]; then
        echo "${array[1]}"
        return 0
      fi

      echo -e "${section_header}" >&2
      echoFormattedPromptArray "${array[@]}"
      echo "$(readSelectionInputFromArray "${array[@]}")"
    elif isInteger "${quick_select_index}" && ([ "${quick_select_index}" -lt 1 ] || [ "${quick_select_index}" -gt "${count}" ]); then
      zk_log_error "Quick select org index '${quick_select_index}' out of bounds '[1, ${count}]."
      return 1
    else
      echo "${array["${quick_select_index}"]}"
    fi
  }

  function attempt_regex_lookup() {
    local term="${1}"
    local orgs=($(statOrgs))

    for org in "${orgs[@]}"; do
      local repos=($(statRepos "${org}"))

      for repo in "${repos[@]}"; do
        if [[ "${org}/${repo}" =~ "^.*${term}.*$" ]]; then
          # ZTODO: I don't like that the `cd` happens in the lookup function. I think it's a SRP violation.
          cd "${ZK_CODE_ROOT}/${org}/${repo}"
          return 0
        fi
      done
    done

    return 1
  }

  # ZTODO: Tie usage into this error.
  if ! isRootSet; then
    zk_log_error "Environment variable 'ZK_CODE_ROOT' is not defined."
    return 1
  fi

  if ! validateArguments "${@}"; then
    zk_log_error "Invalid arguments: '${@}'."
    return 1
  fi

  if [ "${1}" = "${quick_select_root}" ]; then
    # ZTODO: Should the exit codes of `cd` be returned here rather than just `0`?
    cd "${ZK_CODE_ROOT}"
    return 0
  fi

  if [ $# -eq 1 ] && ! isInteger "${1}"; then
    if attempt_regex_lookup "${@}"; then
      return 0
    else
      zk_log_error "Could not find a repository matching pattern: '${1}'."
      return 1
    fi
  fi

  local quick_select_org_index="$(parseQuickSelectArgument "${1}")"
  if [ -z "${quick_select_org_index}" ]; then
    zk_log_error "Index '${1}' not found."
    return 1
  fi

  local quick_select_repo_index="$(parseQuickSelectArgument "${2}")"
  if [ -z "${quick_select_repo_index}" ]; then
    zk_log_error "Index '${2}' not found."
    return 1
  fi

  local orgs=($(statOrgs))
  local orgs_section_header='-----Orgs-----'
  local selected_org="$(produceSelectionIndex "${quick_select_org_index}" "${orgs_section_header}" "${orgs[@]}")"
  if [ -z "${selected_org}" ]; then
    return 1
  fi

  local repos=($(statRepos "${selected_org}"))
  local repo_section_header='\n-----Repos-----'
  local selected_repo="$(produceSelectionIndex "${quick_select_repo_index}" "${repo_section_header}" "${repos[@]}")"
  if [ -z "${selected_repo}" ]; then
    return 1
  fi

  cd "${ZK_CODE_ROOT}/${selected_org}/${selected_repo}"
}