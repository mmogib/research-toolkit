# Lean hub `CLAUDE.md` — skeleton

Replaces whatever `/init-project` generated. The hub answers two questions for a future session: where does
the project stand, and where do I look next. Nothing else belongs in it.

**Hard limits:** no session history, no summaries of notes, no findings, no changelog. If it is a finding it
goes in a note. If it is a decision it goes in the topic note that owns the decision. The hub only points.

---

```markdown
# <Project title>

<One paragraph, written from your own read of `paper/main.tex`. What problem the paper solves, what the
method is, what the main results claim, what the experiments cover. Present tense. No history of how the
paper got here.>

## Status

- **Phase:** <e.g. Review & revision — proofs verified, literature in progress>
- **Now:** <the single thing being worked on right now>
- **Next:** <the single thing that follows it>

## Active notes

- `notes/review-checklist.md` — checklist state, item by item
- `notes/review-findings.md` — open findings not yet applied to `main.tex`
- `notes/<topic>.md` — <one line, a pointer not a summary>
- `notes/litrev/` — one note per reference read from its PDF, named by citation key

<Settled notes are not listed. They live in `notes/done/`.>

## Structure

```
paper/          main.tex (authoritative), references.bib (Zotero-managed), imgs/, submissions/
jcode/          <collaborator>'s domain — code and numerical experiments. Off limits.
notes/          flat, topical, undated. done/ for settled. litrev/ for reference records.
channels/       correspondence with <helper>. claude_to_codex/, codex_to_claude/, README.md
refs/           reference PDFs + .bib index
```

## Roles

- **Mohammed** — direction, and the lead. Compiles LaTeX on Overleaf, relays <helper> messages, liaison to
  co-authors, downloads reference PDFs. Never assume his approval; ask when a decision is his.
- **<Collaborator>** — all code and numerical experiments; owns `jcode/`. Claude never runs, writes, or
  edits code. Experiments are requested through a spec note.
- **Claude** — review, proofs, writing, editing. Math, proofs, and writing stay with Claude and Mohammed,
  never delegated to collaborators.
- **<Helper, e.g. Codex (OpenAI)>** — independent reviewer with read access to the project, corresponding
  through `channels/`. Mohammed relays both ways. Its verdicts are input to Claude's verification, never a
  substitute for it.

## Rules

1. No code, whatsoever. Experiments needed → `notes/spec-<topic>.md`.
2. No LaTeX compilation. Mohammed compiles; Claude fixes reported errors.
3. Never edit `paper/references.bib`. New refs → `paper/temp_refs_to_add.bib` with a reason.
4. Cite with confidence — check `notes/litrev/<Key>.md` first; no note means read the PDF and write one.
5. Freeze rule — while a <helper> exchange is open, `main.tex` is frozen.
6. Every textual change to `main.tex` is wrapped in `\rev{...}`.
7. Human tone. Short, direct sentences. No AI-slop vocabulary.
8. `jcode/` is <collaborator>'s domain.

## Toolkit

See `<path-to-research-toolkit>` for coding style, templates, and workflow guides.
```

---

## Keeping it current

Finishing a task means: update **Status** (all three lines if they changed), and update **Active notes** if
a note opened or closed. A note that moved to `notes/done/` leaves the index in the same edit that moves it.

If the hub grows past roughly one screen, something that belongs in a note has leaked into it. Move it out.
