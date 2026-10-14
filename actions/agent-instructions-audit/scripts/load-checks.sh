#!/usr/bin/env bash
# Loads the checks file next to this action into the local bw: one issue per
# `##` section, aginstaudit-01, -02, ..., each blocked by the one before, so
# bw hands them out in order.
set -e
checks="$(dirname "$0")/../checks.md"
mkdir -p .audit
# Split into tab-separated id, blocker, title, body...
awk '
  function flush() { if (t != "") printf "%s\t%s\t%s\t%s\n", id(n), (n > 1 ? id(n - 1) : ""), t, d }
  function id(i) { return sprintf("aginstaudit-%02d", i) }
  /^## / { flush(); n++; t = substr($0, 4); d = ""; next }
  n { d = d (d == "" && $0 == "" ? "" : $0 "\\n") }
  END { flush() }
' "$checks" > .audit/checks.tsv
# ...then into the JSONL that `bw import` reads.
jq -Rc 'split("\t") | {
    id: .[0], title: .[2], status: "open", priority: 2,
    issue_type: "task", labels: ["aginstaudit"],
    description: (.[3] | gsub("\\\\n"; "\n") | sub("\n+$"; ""))
  } + if .[1] == "" then {} else
    {dependencies: [{issue_id: .[0], depends_on_id: .[1], type: "blocks"}]}
  end' .audit/checks.tsv > .audit/checks.jsonl
bw import .audit/checks.jsonl
bw list --label aginstaudit --limit 100
