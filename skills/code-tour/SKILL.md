---
name: code-tour
description: Explain how a repository works, or what a branch or pull request changed, as one clickable archify page - a source-backed overview that drills down into sequence diagrams, with a guided story that shows the key code. Built on the archify skill installed beside it.
argument-hint: "repo <path> [focus] | pr <branch or PR> [base]"
disable-model-invocation: true
---

# Code tour

Two uses, each with its own steps:

| I say | Read first |
|---|---|
| `repo <path> [focus]`: how a repository (or the focus inside it) works | [references/repo.md](references/repo.md) |
| `pr <branch or PR> [base]`: what a branch, some commits or a pull request changed | [references/pr.md](references/pr.md) |

If the use is unclear, ask which one.

## What every tour must do

1. **I understand without reading every line.** The entry is one clickable page. Its key nodes drill down into diagrams with the detail, and a story walks me through it.
2. **Every claim has evidence.** Diagram nodes cite source files and lines at a pinned commit. The story shows the key code on screen. A change tour shows the before and after diff.
3. **Limits and exceptions are part of the explanation.** Say what gets refused and where, what happens when something upstream changes, and what is left out.
4. **A follow-up question goes where the topic is taught.** Put the answer into that story point, that diagram note or that card. Never add a separate Q&A section.
5. **Write in Traditional Chinese with Taiwan wording.** Keep code identifiers, file paths, commands and product names in English.

## archify

This skill drives archify. archify is installed at `~/.claude/skills/archify` with automatic loading off, so read its files yourself:

- Read `~/.claude/skills/archify/SKILL.md` in full before the first diagram. Then read the references it names for each diagram type you write, and the references that the use's steps name.
- Run its CLI as `node "$HOME/.claude/skills/archify/bin/archify.mjs" ...`. The commands below are written as `archify ...`.
- This skill was written against archify 3.3.2 (`~/.claude/skills/archify/skill-release.json`). On another version, read the references again before writing JSON. A field or command named here may have changed.

Settings for every diagram:

- `meta.locale: "zh-TW"` and `meta.quality_profile: "showcase"`.
- `meta.repository` pins the credential-free origin and the full 40-character commit.
- Run `archify finalize <type> <json> <html> --repo-root <repo> --quality showcase --json`. Read `repositoryReferences` in its output: it must say `verified`.
- Keep each diagram's JSON and the story brief beside its HTML. A later update edits them, never the HTML.

## Known pitfalls, checked before handing over

- **Legend wording.** archify labels dashed lines "非同步追蹤" (async tracing) by default. If a dashed line means anything else, such as a conditional step or a background thread, set `meta.legend.entries.dashed.label` to what it really means.
- **Code and diff panels.** Keep each excerpt to about 10 short lines. Long lines wrap and push the bottom of a panel off the screen. A pull request story has room for only one diff panel.
- **Story code points.** `code.source` is a 0-based index into that node's `sources`. The excerpt lines must lie inside that source's range, at most 20 lines.
- **Sequence notes.** A note of three wrapped lines needs about 66 px before the next message. When finalize reports `sequence/note-overlap`, move the later messages to the y it names.
- **Windows browser check.** `browser-check` sometimes fails with `viewer/temp-cleanup-incomplete` because Chrome closes slowly. Run finalize again with a new `--out-dir`.
- **Look at the result.** Open the page and click every drilldown and its Back control. Jump the story to each code point (`window.Archify.story.seek(<seconds>)` in the page) and look at a screenshot. archify's checks prove the format and the citations, not that the explanation is right or readable.

## Updating an existing tour

When I ask a follow-up or want more detail:

1. Find the tour's JSON files and story brief beside its HTML.
2. Read the code that answers the question, and cite it.
3. Edit every place the topic is taught: the story point, the diagram's note or label, and the card. A new claim cites its source like the rest.
4. Run finalize again for each diagram you changed, then attach the story again. Check the result as above.

## Handing over

Open the entry page for me. Then say in a few lines how to use it (the 講解 button, clicking nodes, drilldowns and Back), what it covers, what it leaves out, and how many citations were verified at which commit.
