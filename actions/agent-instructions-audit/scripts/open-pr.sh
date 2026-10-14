#!/usr/bin/env bash
# Opens a PR with Claude's edits to CLAUDE.md and README.md, if any.
# Env: BRANCH (the PR branch), BASE_BRANCH, DENIED (from check.sh).
set -e
denied=${DENIED:-0}
if git diff --quiet; then
  if [ "$denied" != 0 ] && [ ! -s .audit/questions.md ]; then
    echo "::error::no findings, but Claude was blocked; the audit is not trustworthy"
    exit 1
  fi
  echo "No changes to the agent instructions."
  exit 0
fi
run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
title=$(head -n1 .audit/title.txt 2>/dev/null || true)
[ -n "$title" ] || title="Agent instructions audit $(date -u +%F)"
{
  cat .audit/body.md 2>/dev/null
  echo
  echo "---"
  echo "_[Run $GITHUB_RUN_ID]($run_url) at ${GITHUB_SHA::7}; $denied tool calls refused._"
} > .audit/pr.md
git switch -C "$BRANCH"
git add -- CLAUDE.md README.md
git commit -q -m "$title" -m "Nightly agent instructions audit, run $GITHUB_RUN_ID."
git push -f origin "$BRANCH"
gh label create agent-instructions-audit --color 0e8a16 \
  --description "Found by the nightly agent instructions audit" 2>/dev/null || true
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$title" \
  --label agent-instructions-audit --body-file .audit/pr.md
