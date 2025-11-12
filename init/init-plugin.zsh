# Allows for functions to be reloaded when used like so:
#   function_redefine foo
#   function foo() { ... }
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

# Hook for tying into ZSH process for adding to history. Does not add failed commands and specified commands to history.
function_redefine zshaddhistory
function zshaddhistory() {
	function read_ignored_commands() {
		local result=()

		while IFS= read -r line; do
			if [[ "${line}" =~ '^#' ]] || [ -z "${line}" ]; then
				continue
			fi
			result+=("${line}")
		done < "${0:a:h}/ignored_commands"
	}

	function is_ignored_command() {
		local ignored_commands=($(read_ignored_commands))
		local ignored_regex="^($(echo "${ignored_commands[@]}" | tr ' ' '|'))"

		return [[ "${1}" =~ $ignored_regex ]]
	}

	emulate -L zsh

	if ! whence ${${(z)1}[1]} >| /dev/null; then
		echo "[ZK] Command does not exist on the system. Not adding to history."
		return 1
	fi

	if [[ "${1}" =~ "^[[:space:]]+" ]]; then
		echo "[ZK] Command starts with whitespace. Not adding to history."
		return 1
	fi

	if is_ignored_command "${1}"; then
		echo "[ZK] Command is in ignore list. Not adding to history."
		return 1
	fi

	print -sr -- "${1%%$'\n'}"
	fc -p
}
