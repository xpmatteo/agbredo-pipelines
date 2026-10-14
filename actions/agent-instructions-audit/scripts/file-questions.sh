#!/usr/bin/env bash
# Files .audit/questions.md, if any, as one bw issue (label `question`, P1)
# and syncs the tracker.
set -e
if [ ! -s .audit/questions.md ]; then
  echo "No questions."
  exit 0
fi
cat .audit/questions.md
desc=$(printf '%s\n\nFrom the agent instructions audit, run %s.\n' \
  "$(cat .audit/questions.md)" \
  "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID")
id=$(bw create "Agent instructions audit: questions $(date -u +%F)" \
  -p 1 -d "$desc" --silent)
bw label "$id" +question
bw sync
echo "::notice::Questions filed as $id"
