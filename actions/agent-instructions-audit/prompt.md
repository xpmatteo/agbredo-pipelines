Audit this repo's agent instructions, CLAUDE.md and README.md, by working
through the checklist in .audit/checks.md. Each `##` section is one check,
with its goal, criteria, how to check, and what to do if it fails.

For each check, in order, one at a time:
1. Do the check. Verify before acting; act only on real failures.
2. On a failure, either fix it by editing CLAUDE.md or README.md (keep them
   brief), or, when the check says to ask, or the fix needs a person or a
   file other than these two, append a question to .audit/questions.md: one
   `- ` bullet with the question, the evidence, and the check's title.
3. Append one line to .audit/results.md:
   `- <check title>: pass`, `- <check title>: fixed: <what>` or
   `- <check title>: asked: <what>`.

Edit no file but CLAUDE.md, README.md and the .audit/ files you are told to
write.

When the list is done and you changed CLAUDE.md or README.md, write the PR
text: .audit/title.txt (one line, under 70 chars) and .audit/body.md, which
explains to a reviewer, per change: the check, what was wrong, the evidence,
what you changed. Leave the questions out of body.md; they are added to it.

Tools: read files with Read, Grep and Glob. Keep each Bash call to one plain
command, with no pipes, `;`, `&&`, redirects, variables or `$(...)`;
anything else is refused.
