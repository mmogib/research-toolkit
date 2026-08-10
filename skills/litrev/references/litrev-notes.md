# `notes/litrev/` — the record and the note skeleton

Two copy-into-place texts: the directory README, and the per-key note skeleton.

---

## `notes/litrev/README.md`

Copy this in when creating the directory. Substitute the discovered PDF root for
`<PDF root>`.

```markdown
# Literature review notes

One note per reference read from its PDF, named by citation key (`Ibrahim2026.md` for
`\cite{Ibrahim2026}`).

## The rule

Before citing a paper, or writing any sentence that characterizes one, check for its note here. If
there is no note, read the PDF and write one first. Never characterize a paper from memory — a
reference appearing in the bibliography proves nothing about its contents.

## Finding a PDF

Reference PDFs live in `<PDF root>`. Locate a key through the `.bib` index there — its `file = {...}`
fields give paths relative to that directory. If that fails, match by title and author. If the PDF is
not there, ask Mohammed to download it; do not proceed on memory.

## Requesting a new reference

A reference not in the bibliography is requested as an **unverified lead** in
`paper/temp_refs_to_add.bib` — never as a fabricated entry. Mohammed verifies and imports through
Zotero. Do not cite the key until it appears in the bibliography.

## Status

| Key | Read | Cited in | Note |
|-----|------|----------|------|
| | | | |

Keys cited in the manuscript with no note here are the open list.
```

---

## Per-key note skeleton

```markdown
# <Key> — <Author(s), Year>

**Full reference:** <as it appears in the bib entry>
**PDF:** <path relative to the PDF root>
**Read:** <YYYY-MM-DD>

## What the paper does

<Two or three sentences. The actual contribution, in your words, from the PDF.>

## What we cite it for

<The specific claim, method, theorem, or parameter our manuscript attributes to this paper — quoted
or equation-referenced from the source. One line per attribution. This is the part that gets
checked.>

- Cited at `<manuscript>` §<n> for <claim>. Source: <section / equation / page in the PDF>. **Verified.**

## Assumptions and setting

<The hypotheses under which their result holds. Manuscripts routinely cite a theorem outside the
setting it was proved in — record the setting so that mismatch is visible.>

## Parameters (if used as a benchmark baseline)

| Parameter | Value | Where in the source |
|-----------|-------|---------------------|
| | | |

<Benchmark parameter attributions get verified against this table. "The parameters recommended in
[X]" requires knowing what [X] actually recommends.>

## Relation to our work

<Predecessor, competitor, or tool? What our paper improves on or borrows. Anything they already do
that we claim as new — flag it loudly here.>

## Concerns

<Anything that affects how we may cite it: a gap in their proof, a limited experiment, a claim
stronger in the abstract than in the theorem, an erratum.>
```

---

## Notes on filling it in

**"What we cite it for" is the section that does the work.** It is not a summary — it is the list of
attributions this manuscript makes, each with the place in the source that supports it. An
attribution with no source location has not been verified, however confident it looks.

**Record the setting even when it matches.** The value of "Assumptions and setting" is that it makes
a mismatch visible later, when the manuscript's own hypotheses change and a citation that was fine
quietly stops being fine.

**The parameter table only appears for baselines.** Skip it for papers cited for context. Fill it
completely for any method reimplemented as a competitor — that table is what an unattributed
parameter claim gets checked against.

**Write concerns down even if they seem minor.** "Their Theorem 4 is stated for the strongly monotone
case only" is the sort of thing that decides, months later, whether a sentence is defensible.
