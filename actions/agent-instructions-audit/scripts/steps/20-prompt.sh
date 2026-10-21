#!/usr/bin/env bash
# Writes Claude's prompt and tool allowlist to $GITHUB_OUTPUT, as prompt and
# allowed-tools. The prompt is prompt.md followed by EXTRA.
# Env: EXTRA (the caller's extra-instructions).
set -e
dir="$(dirname "$0")/../.."
{
  echo "prompt<<END_OF_PROMPT"
  cat "$dir/prompt.md"
  if [ -n "$EXTRA" ]; then
    echo
    echo "$EXTRA"
  fi
  echo "END_OF_PROMPT"
  # One tool per line in the file; Claude Code wants them comma separated.
  echo "allowed-tools=$(grep -v '^#' "$dir/allowed-tools.txt" | grep . | paste -sd, -)"
} >> "$GITHUB_OUTPUT"
