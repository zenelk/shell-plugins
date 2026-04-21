# shell-plugins

A place to store my personal shell extensions.

## Logging Convention

### Design Philosophy

These are shell extensions that should be unobtrusive to the user, not a long-running process. Output is colorized when `ZK_COLOR_ENABLED` is set, with no textual prefix. Color is the sole differentiator between information subcategories and is a conscious tradeoff.

All output follows a diagnostic tone: **state what happened with enough context to act on it.** Use statements, not exclamations. Include relevant values, paths, or state so the reader can fix the problem without reading the source.

### Output Categories

#### Functional - stdout

Required to make the thing work. Uses raw `echo` / `printf`. `echo` is preferred unless `printf` is required. No color, no helpers.

Examples: repo lists, branch names, virtual environment names, cluster usage reports.

#### Informational - stderr

Messages for the user that don't need a response to continue, including on exit. Uses `zk_log_*` helpers defined in `init/init-plugin.zsh`.

| Subcategory | Color | Gated | Helper | Use |
|---|---|---|---|---|
| Success | Green | No | `zk_log_success` | Completion of a process, or state already matches expected |
| Warning | Yellow | No | `zk_log_warn` | Non-fatal, diversion from the happy path |
| Error | Red | No | `zk_log_error` | Fatal, cannot reasonably continue |
| Status | Cyan | No | `zk_log_status` | Progress or state change during execution |
| Debug | Dim | `ZK_DEBUG` | `zk_log_debug` | Diagnostics, invisible by default |
| Usage | None | No | `zk_log_usage` | POSIX-style synopsis format |

#### Interactive - stderr

Required for the user to make a decision. Includes prompts, menus, section headers, and validation retries. Uses raw `echo >&2` / `printf ... >&2`. No color from the logging system, no helpers.

### Usage Format

Follows POSIX Utility Conventions synopsis format:

- `[]` = optional, `<>` = required
- Options are hyphen-prefixed: `-f`, `-v`
- `...` = repeatable
- Mutually exclusive alternatives use pipe: `[-a | -b]`
- Multiple valid invocations get separate lines
- Synopsis-only unless the command has subcommands

### Notes

- `echo -e` is acceptable since these are specifically zsh plugins.
- Help / usage is recommended for complex commands, but is not mandatory.
