# agbredo-pipelines

The central repository of pipelines watched by
[Agbredo](https://github.com/xpmatteo/agbredo). The words below are those of
Agbredo's [glossary](https://github.com/xpmatteo/agbredo/blob/main/docs/00-glossary.md).

- A **pipeline** is one agent implementation, kept here as a reusable
  workflow under `.github/workflows/`. Its path names it.
- A target repository uses a pipeline through a **caller workflow**: a small
  file that holds the triggers and permissions and calls exactly one
  pipeline. The repository plus the pipeline is a **deployment**.
- Each GitHub run attempt of a deployment is a **run**; each Claude Code
  invocation inside it is an **agent run**.

Target repositories copy nothing from here but their caller workflow.

## Calling a pipeline

```yaml
# .github/workflows/agent-instructions-audit.yml in the target repository
name: Agent instructions audit

on:
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:

# A pipeline can only narrow these; grant what its job asks for.
permissions:
  contents: write
  pull-requests: write
  actions: read
  id-token: write

concurrency:
  group: agent-instructions-audit
  cancel-in-progress: false

jobs:
  audit:
    uses: xpmatteo/agbredo-pipelines/.github/workflows/agent-instructions-audit.yml@v2
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

`secrets: inherit` instead of the `secrets:` map passes all of the caller's
secrets; naming them passes only what the pipeline needs.

Agbredo sees a run through the `workflow_run` webhook of Agbredo's GitHub
App, installed on the target repository. Claude Code sends its telemetry to
`https://www.agbredo.com/api/otlp` with a GitHub OIDC token, which needs
`id-token: write`. Agbredo accepts the token because the job runs a pipeline
from this repository, so the target repository needs no telemetry secret or
variable.

## Versions

Callers pin a pipeline by tag (`@v2`), never `@main`. The tag is the
pipeline's version; GitHub reports it in the run's identity token
(`job_workflow_ref`), so a run cannot misstate it.

Inside a reusable workflow, `actions/checkout` and `./` paths refer to the
caller's repository. So a pipeline ships its scripts, prompts and checklists
in a composite action under `actions/`, and calls it by its full name at the
same tag: `xpmatteo/agbredo-pipelines/actions/<name>@v2`. A pipeline and its
actions are bumped together: a release changes the `@vN` references in the
pipeline, then tags that commit `vN`. Moving an existing tag changes what
every caller of that tag runs on its next run.

A caller that pins a branch or a SHA, for example to test a change, still
gets the actions at `@v2`, because the pipeline names them by tag. To test
a branch end to end, point the pipeline's `@v2` references at that branch
for the duration of the test.

## Telemetry

Before each Claude Code step, a pipeline gets a GitHub OIDC token with
audience `agbredo` and puts it in `OTEL_EXPORTER_OTLP_HEADERS` through
`$GITHUB_ENV`; claude-code-action hides the OIDC variables from Claude, so
Claude Code cannot get it itself. The Claude Code step turns on telemetry in
its `settings` and sets `OTEL_RESOURCE_ATTRIBUTES` with the repository, run
id, run attempt, job and `github.step`, a name unique in the job. Agbredo
lists a run's agents by `github.step`. See the agent instructions audit for
an example.

Agbredo forwards telemetry only from pipelines in the repositories it lists
in `AGBREDO_PIPELINE_REPOS`, which includes this one.

## Marking escalations for Agbredo

A pipeline that opens a PR adds one line at the very end of the PR body:

```
Agbredo-Run: $GITHUB_RUN_ID/$GITHUB_RUN_ATTEMPT
```

Put a blank line before it. Skip the line if either variable is not set.

Do the same for an Issue. Agbredo reads the marker from the `opened` event
of the `pull_request` or `issues` webhook, and links the PR or Issue to that
run. Without the marker, it does not link it. An agent writes the text; a
deterministic step opens the PR or Issue and adds the marker.

Label PRs and Issues opened by a pipeline `ai-agent-generated`.

## Pipelines

### Agent instructions audit

`.github/workflows/agent-instructions-audit.yml`, with its steps in
`actions/agent-instructions-audit/`.

Audits a repository's agent instructions, CLAUDE.md and README.md. If the
base branch or the bw tracker moved since the caller's last successful run
(or on any run not started by the schedule), it loads the checklist
`actions/agent-instructions-audit/checks.md` into a local bw, and Claude works
through it. Edits become one PR on branch `agent-instructions-audit`;
questions become one bw issue labelled `question`, synced to the tracker.
While the audit's PR is open, runs skip.

The target repository needs:

- a Go module (`go.mod`), used to install bw;
- a `beadwork` branch, the bw tracker; the pipeline never creates it;
- the secret `CLAUDE_CODE_OAUTH_TOKEN`, from `claude setup-token`;
- under Settings > Actions > General, "Allow GitHub Actions to create and
  approve pull requests";
- Agbredo's GitHub App, for Agbredo to see its runs and PRs.

Inputs:

| Input | Default | Meaning |
| --- | --- | --- |
| `extra-instructions` | empty | Text appended to Claude's prompt: what to know about this repository to apply the checks, such as its issue ID prefix, where its test and design docs are, and files absent on purpose. |
| `pr-branch` | `agent-instructions-audit` | The branch fixes are pushed to and the PR comes from. While a PR from it is open, the audit skips. |
| `base-branch` | `main` | The branch audited and targeted by the PR. A scheduled caller runs on its default branch; the pipeline checks out this branch. |
| `workflow-file` | the caller's | The caller's workflow file name, whose last successful run is the baseline. Taken from `github.workflow_ref` when empty. |

Secrets: `CLAUDE_CODE_OAUTH_TOKEN` (required).

Permissions the caller grants: `contents: write`, `pull-requests: write`,
`actions: read`, `id-token: write`.

The dead-reference finder runs outside the pipeline too: from inside a
checkout of the target repository, run
`actions/agent-instructions-audit/scripts/agent-instructions-refs.sh` from a
checkout of this one.
