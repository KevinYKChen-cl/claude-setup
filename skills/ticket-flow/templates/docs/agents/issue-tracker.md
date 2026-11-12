# Issue tracker: beads (stealth mode)

Issues and specs for this repo live in beads (`bd`, v1.3+), stored locally under `.beads/` and kept out of git by `.git/info/exclude`. The team's repo never sees them: never commit `.beads/`, never mention bead ids in commit messages or code comments meant for the team.

## Conventions

- **Create an issue**: `bd create "<title>" -t <task|feature|bug|epic> --body-file - --silent` with the body on stdin (heredoc); prints the new id. Use `--acceptance "..."` for acceptance criteria when they are short.
- **Spec**: one issue of type `epic` (`-t epic`); its body is the spec.
- **Ticket under a spec**: `bd create "<title>" --parent <spec-id> ...`. Don't modify or close the parent.
- **Read an issue**: `bd show <id>` (add `--json` for parsing); comments: `bd comments <id>`.
- **List issues**: `bd list` (open), `bd list --parent <id>` for a spec's tickets.
- **Blocking**: native dependencies. `bd dep add <issue> <depends-on>` (the first id waits for the second), or `--deps blocked-by:<id>,<id>` on `bd create`. A ticket is unblocked when every blocker is closed.
- **Startable work**: `bd ready` lists open, unblocked, unclaimed issues; `bd ready --explain` says why something is blocked.
- **Labels**: `--labels <a>,<b>` on create; `bd label add <id> <label>` / `bd label remove <id> <label>` afterwards. When a skill says to apply `ready-for-agent`, add that label.
- **Claim**: `bd update <id> --claim` before any work on the ticket.
- **Comment**: `bd comments add <id> "..."` (or `-f <file>` for long text).
- **Close**: `bd close <id> --reason "..."` once the ticket's work is merged into the integration branch. `--suggest-next` shows what it unblocked.

Work is closed through beads, not PRs: there is no draft PR "closing" tickets. `/implement-spec` resolves each ticket with `bd close` and reports the integration branch.

## When a skill says "publish to the issue tracker"

Create a beads issue as above (an epic for a spec, a child task for a ticket).

## When a skill says "fetch the relevant ticket"

`bd show <id>`. The user normally passes the id directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an epic with child issues as tickets.

- **Map**: `bd create "<effort>" -t epic --labels wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `bd create "<question>" --parent <map-id> --labels wayfinder:<research|prototype|grilling|task>`.
- **Blocking**: see **Blocking** above.
- **Frontier**: `bd ready --parent <map-id>`; first in the list wins.
- **Claim**: `bd update <id> --claim`, the session's first write.
- **Resolve**: `bd comments add <id> "<answer>"`, `bd close <id>`, then append a context pointer (gist + id) to the map's Decisions-so-far (`bd update <map-id> --body-file -`).
