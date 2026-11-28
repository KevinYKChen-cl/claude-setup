# pr: what a branch or pull request changed

The result is an archify PR pack, kept on this machine:

- one or more views that merge the before and after, with the changes marked
- a change table that links each row to its line
- a story that ends on a diff panel of the decisive change

Read `~/.claude/skills/archify/references/pr-review.md` in full first.

## 1. Read the real change

- Ask for the base if I did not name one. Then run `archify pr preflight --repo-root <repo> --base <base> --head <head> --init <pack-dir> --json`.
- Read `git diff --find-renames <baseSha> <headSha>` and the code around each hunk.
- Note three things, because these are what I tend to miss:
  - what stays exactly the same, such as default values and callers that send nothing new
  - in which cases the result is now different
  - what is refused, and where (status code, before or after a billed call)

## 2. Views

- Choose the diagram type by the layer the change touches: `erd` for storage, `architecture` for services, `sequence` for call order, `workflow` for a decision path, `lifecycle` for states. Draw only the layers it touches.
- Merge the before and after into each view. Mark each element `added`, `modified` or `removed`, and keep the unchanged neighbours one hop away.
- Put a request or response body that changes on `messages[].payload` with `before` and `after`.
- Use cards for "unchanged" and "new behaviour".
- Give `meta.repository` both `revision` (the head) and `base_revision` (the merge base).

## 3. Pack manifest

- In `pr-pack.json`, fill in `title`, `summary` and `views`.
- Add `changes[]` with one row per real change (subject, kind, change, detail, path, line). Tests and docs count.
- Add a `story` with `stages`, `focus`, `traces`, `steps` (`path`, `line`, `baseLine`, `change`) and one `detail` with `mode: "diff"`. In the detail, `baseLines` and `lines` are each about 5–10 lines of the decisive hunk.
- Never write a verdict such as SAFE or LOW RISK. archify refuses one, and I own the verdict.

## 4. Build and check

1. Run `archify finalize` on each view, then `archify pr validate pr-pack.json --repo-root <repo> --json`, then `archify pr build pr-pack.json --out-dir out --repo-root <repo> --json`.
2. Open `out/views/<view>.html` and the story `out/views/walkthrough-light.svg`. Look at the diff panel: it must not be cut off.
3. For reading on this machine, write a copy of `out/pr-pack.md` with its asset placeholders replaced by the local SVG paths.

## 5. Attach only when asked

Keep the pack local. If I ask to attach it to a pull request, run `archify pr attach <pr> --manifest out/pr-pack.receipt.json --target <body|comment> --dry-run --json` first and show me the result.
