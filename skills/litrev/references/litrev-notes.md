# `notes/litrev/` — the record and the note skeleton

Copy-into-place texts: the directory README, its referee variant, and the per-key note skeleton.

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
not there, ask the user to download it; do not proceed on memory.

## Requesting a new reference

A reference not in the bibliography is requested as an **unverified lead** in
`paper/temp_refs_to_add.bib` — never as a fabricated entry. The user verifies and imports through
Zotero. Do not cite the key until it appears in the bibliography.

## Status

| Key | Read | Cited in | Note |
|-----|------|----------|------|
| | | | |

Keys cited in the manuscript with no note here are the open list.
```

---

## `notes/litrev/README.md` — referee variant

For the referee arrangement (`/litrev` § Referee arrangement). Substitute the PDF locations, in
search order, for `<PDF locations>` and the host's request note for `<request list>`.

```markdown
# Literature review notes — referee

One note per source read from its PDF, named by source ID (`Smith2019.md`). The manuscript under
review is read-only; these notes record what the sources it cites, and any uncited sources the
review needs, actually say.

## The rule

Before any deliverable characterizes a paper (what it proves, assumes, or recommends), check for its
note here. If there is no note, read the PDF and write one first. Never characterize a paper from
memory.

## Finding a PDF

PDFs are searched in this order: <PDF locations>. Match by title and authors, and record the exact
path in the note. If the PDF is not found, add it to <request list> and ask the user; do not proceed
on memory.

## Source map

| Round | Printed ref | Source ID | Note |
|-------|-------------|-----------|------|
| | | | |

## Status

| Source ID | Read | Cited in (round: printed refs) | Note |
|-----------|------|--------------------------------|------|
| | | | |

Sources in the map with no note here are the open list.
```

In the referee arrangement, the per-key skeleton below changes in four places: the heading uses
the source ID; **Full reference** is taken from the PDF itself; **PDF** is the exact path read;
"What we cite it for" becomes "What the manuscript cites it for — round N" (one block per round),
and "Relation to our work" becomes "Relation to the manuscript".

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

<Every claim, method, theorem, or parameter our manuscript attributes to this paper. One record per
attribution. This is the part that gets checked.>

- **Manuscript:** "<the citing sentence, verbatim>" — `<manuscript>` §<n>
  **Source:** "<the shortest exact excerpt that settles the claim>", or <the exact equation, theorem
  statement, or table row>
  **Where:** <section / theorem / equation / table / page in the PDF>
  **Scope:** <optional — a definition, version, or nearby qualifier the excerpt depends on>
  **Checked:** <YYYY-MM-DD> — **Verified** / **PDF re-check required**

<For a hypothesis or parameter attribution, **Source** may point to the result's entry under
"Assumptions and setting" or to the parameter row, instead of repeating it.>

## Assumptions and setting

<The hypotheses under which each result we cite holds. Manuscripts routinely cite a theorem outside
the setting it was proved in — record the setting so that mismatch is visible. One block per result.>

**<Theorem / Corollary n>, p. <n>**
- **Complete:** yes — <how you know, e.g. "statement read in full; §n's standing assumptions
  checked"> / no — <what is missing>
- **Standing assumptions:** <section- or paper-wide conventions that apply, e.g. "throughout §4, E
  is Hausdorff" — or "none">
- **Requires all of:** <(a) …; (b) …>
- **Alternatives:** <e.g. "(c) may be replaced by … (Remark 4.6)" — or "none">

## Parameters (if used as a benchmark baseline)

| Parameter | Value (units) | Status | Method / problem variant | Where in the source |
|-----------|---------------|--------|--------------------------|---------------------|
| | | recommended / default / admissible range / tested only | | |

<Benchmark parameter attributions get verified against this table. "The parameters recommended in
[X]" requires knowing what [X] actually recommends — the Status column, not just the value.>

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
attributions this manuscript makes, each with the source's own words or equation beside it. An
attribution with no source location has not been verified, however confident it looks.

**A page number is a locator, not evidence.** The **Source** field must be enough to test the
manuscript sentence without reopening the PDF. If a short excerpt cannot carry that — the claim
depends on a definition twenty pages back, say — mark the record **PDF re-check required**. Copy the
manuscript sentence verbatim: a later audit compares it with the current manuscript, and a sentence
that has not changed since it was verified needs no second look.

**Record the setting even when it matches.** The value of "Assumptions and setting" is that it makes
a mismatch visible later, when the manuscript's own hypotheses change and a citation that was fine
quietly stops being fine.

**Mark a result complete only after checking its standing assumptions.** A section may open with
"throughout, E is Hausdorff" and never repeat it. A condition missing from a complete record is not
required; a condition missing from an incomplete record is unknown. Record alternatives too — a
remark that lets one hypothesis be swapped for another changes what a manuscript may assume.

**The parameter table only appears for baselines.** Skip it for papers cited for context. Fill it
completely for any method reimplemented as a competitor — that table is what an unattributed
parameter claim gets checked against. Fill Status carefully: a value the source only tested is not a
value it recommends.

**Write concerns down even if they seem minor.** "Their Theorem 4 is stated for the strongly monotone
case only" is the sort of thing that decides, months later, whether a sentence is defensible.
