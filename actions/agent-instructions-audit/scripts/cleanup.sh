#!/usr/bin/env bash
# Rewinding the local beadwork ref to the remote deletes the checklist and
# every commit it made (import, closes) from this clone, so a later `bw sync`
# can never push them.
set -e
git branch -f beadwork origin/beadwork
left=$(bw list --label aginstaudit --all --json | jq length)
if [ "$left" != 0 ]; then
  echo "::error::$left aginstaudit items survived the cleanup"
  exit 1
fi
