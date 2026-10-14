# Agent instructions checks

The agent instructions audit pipeline loads each `##` section below into the
runner's local bw as one item, `aginstaudit-NN`, in order, each blocked by the
one before. Claude works them one at a time; the items never leave the runner.
Each section: Goal, Criteria, How, If it fails. "Fix" means edit CLAUDE.md or
README.md; "Ask" means append a question to .audit/questions.md.

## Dead references

Goal: every path, package and link in the files resolves.
Criteria: a reference an agent follows and finds nothing at costs a wasted search.
How: confirm each line of .audit/dead-refs.txt with ls, Glob or `go list`.
If it fails: fix the reference, or drop it. Ask if the target should exist
but doesn't (a generated file, a missing doc).

## Commands

Goal: every command shown runs as written.
Criteria: commands are the most copied lines; one wrong flag misleads every agent.
How: for each command, check the binary, package, script, flags and test
names exist (`go list`, `go doc`, ls, Grep in the script or the test).
If it fails: fix the command. Ask if you can't tell which form is right.

## Rules match enforcement

Goal: each rule that claims a tool, hook or test enforces it is true.
Criteria: invariants and boundaries a change must respect are named, and real.
How: find the enforcer (pre-commit hook, linter configuration, tests,
checker programs) with Grep and Read.
If it fails: fix the wording to match the enforcer. Ask if the rule itself
seems wrong or unenforced on purpose.

## bw conventions

Goal: what the files say about bw matches how the tracker is used.
Criteria: the files say how to use bw; bw holds the work.
How: `bw label list`, `bw list --label <label>` for each label described;
compare meanings and priorities with real items.
If it fails: fix the description. Ask if a label in use is undescribed and
its meaning isn't clear from its items.

## No tracking

Goal: no fact about specific work items: issue IDs, which goals or epics
exist, what blocks what, status ("X is in progress", "Y was done").
Criteria: tracking facts go stale; they belong in bw even when accurate.
How: Grep the files for issue IDs (the prefix `bw list` shows), "in
progress", "done", "TODO", "next", dates, enumerations of goals or epics.
If it fails: fix by replacing the fact with the bw command that finds it
(e.g. `bw list --label goal`). Ask if the fact isn't in bw yet.

## Missing knowledge

Goal: an agent with only these files can start the next real tasks.
Criteria: the files hold context an agent won't see in the code.
How: take the top 3 of `bw ready`; for each, `bw show` it and ask what an
agent would get wrong with only CLAUDE.md, README.md and the pointers they
give.
If it fails: fix by adding a line or a pointer, if the knowledge is durable
and you can verify it. Ask otherwise.

## Principles, not summaries

Goal: the files state the choices that produced the code, not a summary of it.
Criteria: a summary of code is learnable from the code and goes stale.
How: read each section; for each paragraph ask whether `go doc`, the code or
docs/ already says it.
If it fails: fix by replacing the summary with a pointer, keeping any
principle it carried.

## Where things live

Goal: the files say where things live by kind and convention.
Criteria: point at a command for live lists instead of enumerating files.
How: look for lists of files, packages or tests; check each against the
convention that would let an agent find them.
If it fails: fix by replacing the list with the convention or command.

## Validation

Goal: the files say how to validate a change and what can't be validated.
Criteria: an agent must know when it is done and when it needs a human or
the real machine.
How: compare the files with the test layout, the pre-commit hook and
the docs on testing and on checking against real systems.
If it fails: fix if the answer is in the repo. Ask otherwise.

## Design boundaries

Goal: the files say which changes need a design conversation.
Criteria: complexity and risk boundaries are explicit, not discovered in review.
How: read the architecture section, any design docs and the package doc
comments (`go doc`) for boundaries the files omit.
If it fails: fix if a boundary is written down elsewhere and missing here.
Ask if you suspect one that nobody wrote down.

## Direction

Goal: CLAUDE.md says where the codebase is going: the major changes ahead,
as broad direction ("eventually we will be multitenant"), not features.
Criteria: an agent that knows the direction doesn't build against it.
Direction is not tracking: it changes rarely and is not a list of items.
How: read CLAUDE.md for statements of direction; judge whether one is
missing, vague or contradicted by the code. Don't derive it from bw.
If it fails: Ask. Only people know where the project is going.

## Context only people know

Goal: audience, client, people and their roles are current.
Criteria: the files carry context absent from the code.
How: read what the files say about who uses this, who decides (`question`
label), and the client; check against recent `git log` and bw.
If it fails: Ask. Only people can confirm this.

## Duplication and churn

Goal: nothing is said twice, and the files rarely change with feature work.
Criteria: one home per fact; a file edited often holds the wrong things.
How: compare the two files with each other and with docs/; read
.audit/churn.txt and `git log -p --since=90.days -- CLAUDE.md README.md`
for lines edited repeatedly.
If it fails: fix by keeping one copy and pointing at it. Ask if the right
home is outside these files.

## Brevity

Goal: the files are as short as they can be.
Criteria: every line must earn its place; the files are a directory, not a manual.
How: read both files end to end, after your edits.
If it fails: fix by cutting or tightening.
