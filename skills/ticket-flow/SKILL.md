---
name: ticket-flow
description: Guide for my Pocock + beads + Scotty workflow. Sets the current repo up in personal mode (beads stealth, personal files kept out of git), then tells me which step I am at and the exact command to type next.
disable-model-invocation: true
---

# Ticket flow

My workflow: Pocock skills for grilling, spec, tickets and parallel implementation; beads (`bd`) holds the tickets; Scotty shows them as a board. The Pocock steps are user-invoked only, so this skill never runs them: it sets the repo up and points at the next command.

## 1. Is the repo set up?

From the git repo root, check both:

- `.beads/` exists
- `CLAUDE.local.md` contains `<!-- ticket-flow -->`

If either is missing, tell me in two or three short lines what setup does, then ask before running it:

- `bd init --stealth`: tickets live only on this machine, no commit, team git hooks untouched
- adds the personal files to `.git/info/exclude`: `CLAUDE.local.md`, `.beads/`, `.claude/`, `docs/agents/`, `docs/adr/`, `GLOSSARY.md`, `CONTEXT.md`
- writes `CLAUDE.local.md` and `docs/agents/` from the templates, so `/setup-matt-pocock-skills` isn't needed

After I agree, run `bash ~/.claude/skills/ticket-flow/init.sh` and show its result. If it stops because a personal path is already tracked by the repo, tell me which one and stop. The next step is then `/grill-with-docs <what I want to build>`.

## 2. Where am I?

Read the state:

- `bd list --all -t epic --json`: one epic per spec
- for each epic that isn't closed: `bd list --all --parent <epic> --json`
- `git branch --show-current` and `git status --short`

Pick the step for each open epic:

| State | Next command |
|---|---|
| no open epic | `/grill-with-docs <what I want to build>`; if grilling already happened in this session, `/to-spec` |
| epic with no child tickets | `/to-tickets <epic>` |
| child tickets, none closed | `/implement-spec <epic>` |
| some closed, some open or in progress | implementation is running or stopped halfway; if no session is running it, `/implement-spec <epic>` again |
| all child tickets closed | finish by hand (below) |

Finishing by hand, after all tickets are closed:

1. Run the result myself on the integration branch; tests passing is not enough.
2. Read the diff, especially changes to files the team owns.
3. Push the branch and open a PR; `/code_review_pr` reviews it on GitHub.
4. I merge it myself. Then `bd close <epic>`.

## 3. Reply

Short, in this shape:

- **目前**: the epic (id and title) and its tickets' state, or "not set up"
- **下一步**: the exact command to type
- **看進度**: `scotty` in a terminal at the repo root, then http://127.0.0.1:3197

Only add a note when something needs attention, for example uncommitted changes before `/implement-spec`, or more than one open epic (list each with its next command).

## Rules

- Don't run the Pocock skills (`/grill-with-docs`, `/to-spec`, `/to-tickets`, `/implement-spec`) yourself; tell me to type them.
- Don't run `bd prime`.
- Never commit, force-add or push the personal files.

## The whole flow, for reference

| Step | Command | What I do |
|---|---|---|
| Setup (once per repo) | `/ticket-flow` | agree to setup |
| Requirements and design | `/grill-with-docs <what I want>` | answer each round; it settles modules and interfaces and writes ADRs |
| Spec | `/to-spec` | confirm the test seams; the spec becomes a beads epic |
| Tickets | `/to-tickets <epic>` | check the split; tickets and blocking edges go into beads |
| Board | `scotty` | watch http://127.0.0.1:3197 |
| Build | `/implement-spec <epic>` | wait: parallel implementers, merges, code review and fixes, tickets closed |
| Finish | by hand | run it, read the diff, PR, merge myself |
