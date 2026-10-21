#!/usr/bin/env bash
# Decides whether to run: writes skip=true or skip=false to $GITHUB_OUTPUT.
# Skips while an audit PR or an audit issue is open, and on a schedule when
# the base branch did not move since the caller workflow's last success.
# Env: BRANCH (the PR branch), BASE_BRANCH, WORKFLOW_FILE (the caller's
# workflow file, or its workflow_ref: owner/repo/.github/workflows/x.yml@ref).
set -e
# Inside a reusable workflow, github.workflow_ref names the caller workflow;
# keep only its file name, which `gh run list --workflow` accepts.
workflow=${WORKFLOW_FILE%@*}
workflow=${workflow##*/}
if [ -z "$workflow" ]; then
  echo "::error::no caller workflow file given"
  exit 1
fi
pr=$(gh pr list --head "$BRANCH" --state open --json url -q '.[0].url' || true)
issue=$(gh issue list --label agent-instructions-audit --state open \
  --json url -q '.[0].url' || true)
for waiting in "$pr" "$issue"; do
  if [ -n "$waiting" ]; then
    echo "::notice::Waiting on $waiting; close it first. Skipping."
    echo "skip=true" >> "$GITHUB_OUTPUT"
    exit 0
  fi
done
last=$(gh run list --workflow "$workflow" --branch "$BASE_BRANCH" \
  --status success --limit 1 --json createdAt -q '.[0].createdAt' || true)
new=0
if [ -n "$last" ]; then
  # Ignore the bot's own commits, such as a merged audit PR.
  new=$(git log --since="$last" --format=%an HEAD \
    | grep -vcF 'github-actions[bot]' || true)
fi
if [ -n "$last" ] && [ "$new" = 0 ] && [ "$GITHUB_EVENT_NAME" = schedule ]; then
  echo "Nothing new since $last; skipping."
  echo "skip=true" >> "$GITHUB_OUTPUT"
else
  echo "skip=false" >> "$GITHUB_OUTPUT"
fi
