#!/usr/bin/env bash
# Writes to .audit/ what Claude works from: the checklist and the dead
# references.
set -e
here=$(dirname "$0")
mkdir -p .audit
cp "$here/../../checks.md" .audit/checks.md
"$here/../agent-instructions-refs.sh" > .audit/dead-refs.txt || true
