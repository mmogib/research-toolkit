# `notes/litrev/` — the cite-with-confidence record

One note per reference **actually read from its PDF**, named by citation key: `notes/litrev/Ibrahim2026.md`.

The rule this enforces: before citing or characterizing any paper, check `notes/litrev/<Key>.md`. No note
means you have not read it, which means you do not know what it says. Read the PDF and write the note first.

A reference appearing in `references.bib` proves nothing about its contents. Neither does a plausible memory
of the abstract. AI-generated recollections of papers pair real authors with fabricated claims, and a wrong
characterization in a submitted manuscript is the kind of error a referee notices immediately.

---

## `notes/litrev/README.md`

Copy this into place when creating the directory.

```markdown
# Literature review notes

One note per reference read from its PDF, named by citation key (`Ibrahim2026.md` for `\cite{Ibrahim2026}`).

## The rule

Before citing a paper or writing any sentence characterizing it, check for its note here. If there is no
note, read the PDF and write one first. Never characterize a paper from memory.

## Finding a PDF

Reference PDFs live in `<refs directory>`. Locate a key through the `.bib` index there — its `file = {...}`
fields give paths relative to that directory. If that fails, match by title and author. If the PDF is not
there, ask Mohammed to download it; do not proceed on memory.

## Status

| Key | Read | Cited in | Note |
|-----|------|----------|------|
| | | | |

Keys cited in `main.tex` with no note here are the open list.
```

---

## Per-key note skeleton

```markdown
# <Key> — <Author(s), Year>

**Full reference:** <as it appears in the bib entry>
**PDF:** <path relative to the refs directory>
**Read:** <YYYY-MM-DD>

## What the paper does

<Two or three sentences. The actual contribution, in your words, from the PDF.>

## What we cite it for

<The specific claim, method, theorem, or parameter our manuscript attributes to this paper — quoted or
equation-referenced from the source. One line per attribution. This is the part that gets checked.>

- Cited at `main.tex` §<n> for <claim>. Source: <section / equation / page in the PDF>. **Verified.**

## Assumptions and setting

<The hypotheses under which their result holds. Manuscripts routinely cite a theorem outside the setting it
was proved in — record the setting so that mismatch is visible.>

## Parameters (if used as a benchmark baseline)

| Parameter | Value | Where in the source |
|-----------|-------|---------------------|
| | | |

<Benchmark parameter attributions get verified against this table. "The parameters recommended in [X]"
requires knowing what [X] actually recommends.>

## Relation to our work

<Predecessor, competitor, or tool? What our paper improves on or borrows. Anything they already do that we
claim as new — flag it loudly here.>

## Concerns

<Anything that affects how we may cite it: a gap in their proof, a limited experiment, a claim stronger in
the abstract than in the theorem, an erratum.>
```

---

## Working through the inventory (review step 3)

1. Extract every `\cite{...}` key from `main.tex`.
2. Diff against the notes present in `notes/litrev/`. The difference is the reading list.
3. Read the gaps. Agents may read PDFs and write litrev notes — give each agent the key, the PDF path, this
   skeleton, and the sentences in `main.tex` that cite it, so the "what we cite it for" section gets
   verified rather than invented.
4. Verify every characterization in the manuscript against its note. Every benchmark parameter attribution
   too.
5. Then check coverage the other way: which essential lineage or competing method is *uncited*? That gap is
   what a referee finds first.
