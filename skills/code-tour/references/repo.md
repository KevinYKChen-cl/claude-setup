# repo: how a repository works

The result is one entry page, `tour.html`:

- a source-backed architecture overview
- key nodes that drill down into one sequence diagram per main path, each with a Back control
- a story attached to the overview, which plays from its 講解 button and shows the key code

## 1. Scope

- Freeze the identity of the repository: `git rev-parse HEAD`, the origin without credentials, and `git status --short`. Evidence is checked against the committed bytes at that commit, so name any uncommitted paths in your reply.
- Find the main paths from the README, the entry points and the routes. A path is one thing a user does, followed from request to result (for example "load a tool page, then Generate" and "one agent turn"). Usually two or three paths are enough.
- If I gave a focus, cover that. Otherwise cover the whole repository and say what you left out.

## 2. Read the code

- Read only. Follow each path from its entry to its side effects, such as an external call, a write or a billed request. Record the file and the inclusive line range of every claim as you read.
- For a large repository, give one read-only sub-agent per path. Ask each for `file:start-end` on every step, caller → callee with the call-site line, the conditions that refuse or skip a step, and two or three short excerpts.
- Before citing a sub-agent's line, open it yourself. Check at least the lines the story will show.

## 3. Overview (architecture)

- `"layout": {"mode": "auto"}`, with 8–12 components: the user, the entry, the parts of each path, external services and stores.
- Give each component `sources`, at most three ranges. An external service may have none.
- Add a `region` boundary for the process or repository when it answers "what runs here".
- Label connections with the action, such as `POST /prompt` or `fetch(pack, variant)`.
- Use cards for the limits and the shared parts. Write each card as a claim, not a heading.
- On the component where each path starts, put `drilldowns: [{"href": "<path>.html", "label": "..."}]`.

## 4. One sequence diagram per path

- Participants are the parts the path crosses, each with `sources`.
- Write messages in the order the code runs them. Put a refusal, a condition or a retry in the message's `note`, with its status code or limit.
- Divide the path into stages with `segments`.
- Use cards for what changes the outcome and where state lives.
- `meta.parentHref: "tour.html"` gives the Back control.

## 5. Story on the overview

1. Run `archify story draft overview.html tour.brief.json --json`. Read `tour.brief.source.json` for the real node ids, edge ids and each node's `sources` order.
2. Write the brief (`version: 2`):
   - one scene per path, plus an opening or a shared ending when it helps
   - points with `anchor`, `via` (edge ids), `title`, `text` and `caption`
   - `code: {source, fromLine, toLine, emphasis}` on the points where the mechanism is in a few lines: a check, an injection, a submit, a dispatch
3. Run `archify story attach overview.html tour.brief.json tour.html --repo-root <repo> --json`.
4. Check it as SKILL.md says: open `tour.html`, click each drilldown and Back, and jump the story to its code points.

## 6. Hand over

Open `tour.html`. List its chapters in one line each. Say what it does not cover, for example tests, CI, build or deploy scripts.
