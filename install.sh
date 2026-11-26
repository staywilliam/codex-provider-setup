#!/usr/bin/env bash
set -euo pipefail

codex_home="${CODEX_HOME:-$HOME/.codex}"
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$codex_home" ]; then
  printf 'error: %s does not exist\n' "$codex_home" >&2
  printf 'Create it first, or set CODEX_HOME to an existing writable directory.\n' >&2
  exit 1
fi

if [ ! -w "$codex_home" ]; then
  printf 'error: %s is not writable\n' "$codex_home" >&2
  printf 'Fix its ownership/permissions, or set CODEX_HOME to a writable directory.\n' >&2
  exit 1
fi

# Keep the catalog path absolute even when CODEX_HOME is given as a relative path.
codex_home="$(cd -- "$codex_home" && pwd -P)"

# Include the PID so repeated installs in the same second cannot overwrite a backup.
backup_dir="$codex_home/backups/$(date +%Y%m%d-%H%M%S)-$$"
install -d -m 700 "$backup_dir"

for file in config.toml openrouter.config.toml zenmux.config.toml official.config.toml zenmux-models.json; do
  if [ -e "$codex_home/$file" ]; then
    cp -p "$codex_home/$file" "$backup_dir/$file"
  fi
done

install -m 600 "$source_dir/config.toml" "$codex_home/config.toml"
install -m 600 "$source_dir/openrouter.config.toml" "$codex_home/openrouter.config.toml"
install -m 600 "$source_dir/official.config.toml" "$codex_home/official.config.toml"
install -m 600 "$source_dir/zenmux-models.json" "$codex_home/zenmux-models.json"

for profile in openrouter zenmux; do
  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "${line//__CODEX_HOME__/$codex_home}"
  done < "$source_dir/$profile.config.toml" > "$codex_home/$profile.config.toml"
  chmod 600 "$codex_home/$profile.config.toml"
done

printf 'Installed Codex profiles into %s\n' "$codex_home"
printf 'Backup: %s\n' "$backup_dir"
printf '\nAPI keys are not installed by this script. Set them in your shell, for example:\n'
printf '  export OPENROUTER_API_KEY="sk-or-v1-..."\n'
printf '  export ZENMUX_API_KEY="sk-ss-v1-..."   # subscription, or sk-ai-v1-... for PAYG\n'
printf 'Then restart the shell (or source your shell config).\n\n'
printf 'Default:    codex            # uses the built-in OpenAI provider\n'
printf 'Official:   codex -p official   # requires ChatGPT login\n'
printf 'OpenRouter: codex -p openrouter\n'
printf 'ZenMux:     codex -p zenmux\n'
printf 'ZenMux model catalog: %s/zenmux-models.json\n' "$codex_home"
