#!/usr/bin/env bash
# Lists references in the agent instructions (CLAUDE.md, README.md)
# that do not resolve: backticked paths, `go run`/`go doc` packages and
# relative markdown links. Prints one "file:line: problem" per miss; exits 1
# if there are any. Run from anywhere inside the repository to check; the
# agent instructions audit pipeline runs it to gather facts for Claude.
# SC2016: the backticks in the patterns are literal. SC2094: miss writes to
# stdout, not to the file being read.
# shellcheck disable=SC2016,SC2094
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

status=0
miss() { echo "$1:$2: $3"; status=1; }

exists() { # a path or glob that matches something in the tree
  local p=${1%/} pre post alt
  p=${p#./}
  if [[ $p == *'{'*','*'}'* ]]; then # one {a,b} group: try each
    pre=${p%%\{*} post=${p#*\}}
    alt=${p#*\{} alt=${alt%%\}*}
    for a in ${alt//,/ }; do exists "$pre$a$post" && return 0; done
    return 1
  fi
  # a bare Go package path like foo/bar lives under internal/ or cmd/
  compgen -G "$p" >/dev/null || compgen -G "internal/$p" >/dev/null ||
    compgen -G "cmd/$p" >/dev/null
}

for f in CLAUDE.md README.md; do
  n=0
  while IFS= read -r line; do
    n=$((n + 1))
    # backticked tokens that look like repo paths
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      for word in $tok; do
        case $word in
          ./*|*/*) ;;
          *.md|*.sh|*.go|*.yml|*.yaml|*.json) ;;
          *) continue ;;
        esac
        case $word in
          /*|http*|*://*|-*|*'<'*|*'>'*|*=*|*@*|*\(*|*\'*) continue ;;
        esac
        exists "$word" || miss "$f" "$n" "path not found: $word"
      done
    done < <(grep -o '`[^`]*`' <<<"$line" | tr -d '`')
    # relative markdown links
    while IFS= read -r link; do
      link=${link%%#*}
      [ -n "$link" ] || continue
      exists "$link" || miss "$f" "$n" "broken link: $link"
    done < <(grep -oE '\]\([^)]+\)' <<<"$line" | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^(https?:|mailto:|#)')
  done < "$f"
done
exit $status
