# The Project Hub — root `CLAUDE.md` and the notes discipline

The root `CLAUDE.md` is a **hub**. It answers two questions for a session that has just started:
*where does this project stand*, and *where do I look next*. Nothing else belongs in it.

This guide is the single source of truth for the hub's shape and the notes discipline that supports
it. `templates/CLAUDE.md.template` is the artifact; `/init-project` writes it.

## Scope: the root file only

This applies to the **root** `CLAUDE.md`. It does **not** apply to `jcode/CLAUDE.md`, which is
implementation reference material — parameter tables, usage examples, ARGS references — and is
expected to be long. Do not trim it to match the hub.

## Hard limits

No session history. No summaries of notes. No findings. No changelog. No per-section status tables.

- If it is a **finding**, it goes in a note.
- If it is a **decision**, it goes in the topic note that owns the decision.
- If it is **content of the paper**, it is already in `paper/main.tex` — the hub does not restate it.

The hub only points. If it grows past roughly one screen, something that belongs in a note has leaked
into it; move it out.

The reason is not tidiness. A hub that accumulates findings becomes a second, stale copy of the
project, and a session that reads it will believe things that stopped being true weeks ago. The
manuscript and the notes are the memory.

## Anatomy

| Section | Holds | Rots? |
|---|---|---|
| Title + one paragraph | What the project is, present tense. No history of how it got here. | No |
| Authors, affiliations, emails | Stable metadata | No |
| `## Status` | Exactly three lines: **Phase**, **Now**, **Next** | Updated, never appended |
| `## Active notes` | One line per *open* note. Pointers, not summaries. | Updated on open/close |
| `## Structure` | Directory tree, one line per top-level folder | Rarely |
| `## Roles` | Who does what, and what Claude may not do | Rarely |
| `## Rules` | Numbered constraints, enforced | Rarely |
| `## Toolkit` | Path to the research toolkit | No |

### `## Status`

```markdown
## Status

- **Phase:** Review & revision — proofs verified, literature in progress
- **Now:** Lemma 3.2 monotonicity gap
- **Next:** Literature inventory against notes/litrev/
```

Three lines. **Now** and **Next** are each a single thing. If either needs a list, the list belongs in
a note and the hub points at it.

### `## Active notes`

The index, and the mechanism the whole discipline hangs on.

```markdown
## Active notes

- `notes/review-checklist.md` — checklist state, item by item
- `notes/review-findings.md` — open findings not yet applied to main.tex
- `notes/litrev/` — one note per reference read from its PDF, by citation key
```

One line each, and the line is a **pointer, not a summary**. Settled notes are not listed — they live
in `notes/done/`. A note leaves this index in the same edit that moves it.

## The notes discipline

`notes/` is **flat**, with topical, **undated** filenames. One note per open topic, updated in place.

- `notes/review-findings.md` — yes
- `notes/review_findings_20260810.md` — no
- `notes/session-2026-08-10.md` — no

Dated filenames produce one file per session and no file per topic, which is the opposite of useful:
the reader has to reconstruct the current state by reading every file in order. Where ordering
matters, date the individual decision inline within its topic note.

Settled or superseded notes move to `notes/done/`. Subdirectories exist only where a note is really a
collection keyed by something — `notes/litrev/` keyed by citation key is the standard example.

## Keeping it current

**Finishing a task means updating the hub.** Not a separate chore, not optional:

1. Update `## Status` — all three lines, if they changed.
2. Update `## Active notes` — if a note opened or closed.

A note that moved to `notes/done/` leaves the index in the same edit that moves it.

## Migration: an existing project

For projects whose root predates this shape. `/init-project adopt` performs it; this is the
procedure it follows.

**Extract, then trim.** Nothing is deleted before it has a home.

| Old content | Destination |
|---|---|
| `## Paper Key Elements` (title, core problem, contributions, per-section status) | `notes/manuscript-map.md` |
| Known issues / WIP | Open topic notes in `notes/` |
| Session history, changelogs, completed-item logs | Summarized into the relevant topic note, or dropped with a one-line summary if superseded |
| Key findings with numbers | The note that owns that experiment or analysis |
| Authors, affiliations, structure, roles, rules | Carried into the new hub |

Safety requirements, all mandatory:

1. **Verbatim backup first** — copy the existing root to `notes/done/CLAUDE_pre_hub.md` before
   writing anything. Many projects are not git repositories; for those this backup plus an external
   snapshot is the only rollback that exists.
2. **Never overwrite an existing backup.** On collision write a numbered one and report both. A
   second or interrupted run must not replace the verbatim original with an already-trimmed hub.
3. **No-op when the root already matches the hub.** Detect `## Active notes` and stop.
4. **Never scaffold into existing code.** If `jcode/` has content, skip architecture, storage-backend,
   and domain questions entirely.
5. **Propose before writing.** Show the extraction and the root diff; write only on approval.
6. **Merge into an existing `notes/manuscript-map.md` only after showing a diff** and receiving
   approval.

Verification after adoption — a syntactically valid hub is not evidence of success:

- The backup's hash equals the pre-adoption root's hash.
- A recursive hash comparison of `jcode/` is empty.
- Every heading and content block from the old root appears either in the new hub or in a named note.

Start a fresh session afterwards. An already-loaded `CLAUDE.md` may still be in the conversation.

## Detecting an unmigrated project

A root carrying `## Paper Key Elements`, or no `CLAUDE.md` at all, has not been migrated. Any skill
that can be the first thing run in a directory should notice and suggest `/init-project adopt` rather
than proceeding on a stale or absent hub.

This is a safety trigger, not migration coverage — a project that runs none of those skills will
never see it. Migration is tracked deliberately, not opportunistically.
