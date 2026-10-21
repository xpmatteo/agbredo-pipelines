#!/usr/bin/env bash
# Checks Claude's work: refused tool calls (denied=N to $GITHUB_OUTPUT),
# checks without a result, and files changed outside CLAUDE.md, README.md,
# .audit/.
# Env: EXEC (claude-code-action's execution_file).
set -e
denied=$(jq -r '[if type == "array" then .[] else . end | select(.type? == "result")]
  | last | (.permission_denials_count // (.permission_denials | length) // 0)' \
  "$EXEC" 2>/dev/null || echo 0)
echo "denied=$denied" >> "$GITHUB_OUTPUT"
if [ "$denied" != 0 ]; then
  echo "::warning::Claude was refused $denied tool calls; see the claude-transcript artifact"
  # Name each refused call, so the allowlist can be fixed from the log.
  jq -r '.[]? | select(.type? == "system" and .subtype? == "permission_denied")
    | "::warning::refused \(.tool_name): \(.message)"' "$EXEC" 2>/dev/null || true
fi
# Every check in the checklist has a result line "- <title>: ...".
cat .audit/results.md 2>/dev/null || true
missing=0
while IFS= read -r title; do
  if ! grep -qF -- "- $title:" .audit/results.md 2>/dev/null; then
    echo "::error::no result for the check '$title'"
    missing=$((missing + 1))
  fi
done < <(sed -n 's/^## //p' .audit/checks.md)
if [ "$missing" != 0 ]; then
  echo "::error::Claude left $missing checks without a result; the audit is incomplete"
  exit 1
fi
# Claude may touch only the instruction files.
stray=$(git status --porcelain --untracked-files=all \
  | grep -vE '^.. (CLAUDE|README)\.md$|^.. \.audit/' || true)
if [ -n "$stray" ]; then
  echo "::error::Claude changed files outside its scope:"
  echo "$stray"
  exit 1
fi
