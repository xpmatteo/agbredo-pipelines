#!/usr/bin/env bash
# Installs bw (beadwork) and points a local `beadwork` ref at the tracker.
# Needs Go on the PATH (actions/setup-go) and a full clone (fetch-depth: 0).
set -e
if ! command -v bw >/dev/null; then
  go install github.com/jallum/beadwork/cmd/bw@v0.13.3
  echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"
fi
# bw reads only a local `beadwork` ref: point one at the existing
# remote branch, in this runner's clone only. Nothing here pushes.
git branch beadwork origin/beadwork
# bw commits to it; so do the questions and the PR in later steps.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
