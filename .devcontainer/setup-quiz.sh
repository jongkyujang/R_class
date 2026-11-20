#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
quiz_commands="$repo_root/tools/quiz_commands.bash"

if [[ ! -r "$quiz_commands" ]]; then
  printf '퀴즈 명령어 파일을 읽을 수 없습니다: %s\n' "$quiz_commands" >&2
  exit 1
fi

printf -v source_line 'source %q' "$quiz_commands"

if ! grep -Fqx -- "$source_line" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n%s\n' "$source_line" >> "$HOME/.bashrc"
fi
