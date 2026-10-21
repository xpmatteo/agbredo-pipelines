#!/usr/bin/env bash
# Publishes Claude's findings, as one PR or one issue, never both: a PR when
# Claude edited CLAUDE.md or README.md, with its questions in the PR body;
# an issue when it only asked questions; nothing when it found nothing.
# Env: BRANCH (the PR branch), BASE_BRANCH, DENIED (from 30-check.sh).
set -e
denied=${DENIED:-0}
has_questions=false
[ -s .audit/questions.md ] && has_questions=true
if git diff --quiet && [ "$has_questions" = false ]; then
  if [ "$denied" != 0 ]; then
    echo "::error::no findings, but Claude was blocked; the audit is not trustworthy"
    exit 1
  fi
  echo "No findings."
  exit 0
fi
run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
footer() {
  echo
  echo "---"
  echo "_[Run $GITHUB_RUN_ID]($run_url) at ${GITHUB_SHA::7}; $denied tool calls refused._"
  # The trailer tells Agbredo which run opened this. It is the last line.
  # Skip it if the run id or attempt is missing, so it is never half written.
  if [ -n "${GITHUB_RUN_ID:-}" ] && [ -n "${GITHUB_RUN_ATTEMPT:-}" ]; then
    printf '\nAgbredo-Run: %s/%s\n' "$GITHUB_RUN_ID" "$GITHUB_RUN_ATTEMPT"
  fi
}
gh label create agent-instructions-audit --color 0e8a16 \
  --description "Found by the nightly agent instructions audit" 2>/dev/null || true
gh label create ai-agent-generated --color BFD4F2 \
  --description "Written by an AI agent, opened by automation" 2>/dev/null || true

if git diff --quiet; then
  {
    cat .audit/questions.md
    footer
  } > .audit/issue.md
  gh issue create --title "Agent instructions audit: questions $(date -u +%F)" \
    --label agent-instructions-audit --label ai-agent-generated --body-file .audit/issue.md
  exit 0
fi

title=$(head -n1 .audit/title.txt 2>/dev/null || true)
[ -n "$title" ] || title="Agent instructions audit $(date -u +%F)"
{
  cat .audit/body.md 2>/dev/null
  if [ "$has_questions" = true ]; then
    echo
    echo "## Questions"
    echo
    cat .audit/questions.md
  fi
  footer
} > .audit/pr.md
git switch -C "$BRANCH"
git add -- CLAUDE.md README.md
git commit -q -m "$title" -m "Nightly agent instructions audit, run $GITHUB_RUN_ID."
git push -f origin "$BRANCH"
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$title" \
  --label agent-instructions-audit --label ai-agent-generated --body-file .audit/pr.md
