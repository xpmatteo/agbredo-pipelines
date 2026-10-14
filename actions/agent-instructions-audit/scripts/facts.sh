#!/usr/bin/env bash
# Writes facts for Claude to .audit/: dead references and churn.
set -e
here=$(dirname "$0")
mkdir -p .audit
"$here/agent-instructions-refs.sh" > .audit/dead-refs.txt || true
{
  echo "Commits in the last 90 days: $(git rev-list --count --since=90.days HEAD)"
  for f in CLAUDE.md README.md; do
    echo "$f: $(wc -l < "$f") lines, changed by $(git rev-list --count --since=90.days HEAD -- "$f") of them"
  done
} > .audit/churn.txt
