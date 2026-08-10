---
name: litrev
description: Cite with confidence. Maintains notes/litrev/ — one note per reference actually read
  from its PDF, named by citation key — and audits a manuscript's citations against that record.
  Finds what is cited but unread, checks whether every characterization and benchmark-parameter
  attribution matches the source, and looks for essential lineage that is uncited. Also owns the
  request flow for references not yet in the bibliography. Use when auditing a manuscript's
  literature or building a reading record. Not for discovering new papers to read, and not for
  formatting bibliographies.
invocation: user
---

# /litrev — The Cite-with-Confidence Record

One note per reference **actually read from its PDF**, named by citation key:
`notes/litrev/Ibrahim2026.md` for `\cite{Ibrahim2026}`.

**The rule this enforces:** before citing a paper, or writing any sentence that characterizes one,
check for its note. No note means you have not read it, which means you do not know what it says.
Read the PDF and write the note first.

A reference appearing in the bibliography proves nothing about its contents. Neither does a plausible
memory of its abstract. Recollections of papers pair real authors with fabricated claims, and a wrong
characterization in a submitted manuscript is the kind of error a referee notices immediately — it
costs more credibility than the citation was ever worth.

## What this is not

| Task | Skill |
|---|---|
| Which journal should this go to? | `/suggest-journals` |
| Mechanical bibliography check — undefined keys, orphan entries | `/review-paper`, bibliography item |
| Writing the related-work prose | `/math-research-writer` |
| **Is what we say about each cited paper actually true?** | **this skill** |

## Modes

| Mode | The question | When |
|---|---|---|
| `audit-manuscript` | What is cited but unread, and is every characterization correct? | A manuscript exists. Revision, review, pre-submission. |
| `build-from-reading` | What have I read that I can safely cite? | Writing from scratch; the reading precedes the prose. |

Ask which applies if it is not obvious. The record format is identical; only the direction of the
inventory changes.

## Phase 0 — Discovery

Discover these; do not assume them. Projects differ, and a wrong assumption here silently audits the
wrong file.

| What | How to find it | Common value |
|---|---|---|
| Manuscript | The `.tex` with `\documentclass` and `\begin{document}`; follow `\input`/`\include` | `paper/main.tex` |
| Bibliography | `\addbibresource` / `\bibliography` in the manuscript | `paper/references.bib` |
| PDF root | Ask, or look for a directory of reference PDFs | `refs/` |
| PDF index | A `.bib` in the PDF root whose `file = {...}` fields give relative paths | `refs/*.bib` |
| Note root | Existing directory, else create | `notes/litrev/` |
| Request file | Where unverified reference requests go | `paper/temp_refs_to_add.bib` |

If `notes/litrev/` does not exist, create it with the README from
`references/litrev-notes.md`.

Report what you found before proceeding.

## `audit-manuscript`

### 1. Inventory

Extract every citation key from the manuscript and every `\input` file. Cover all the commands the
project actually uses — `\cite`, `\citep`, `\citet`, `\citealt`, `\citeauthor`, `\citeyear`,
`\parencite`, `\textcite`, `\autocite`, `\footcite`, `\nocite`. Split comma-separated lists.

Diff against the notes present in the note root. **The difference is the reading list.** Report it as
a count and a list, and record it in the status table of `notes/litrev/README.md`.

### 2. Read the gaps

Locate each PDF through the index (its `file = {...}` fields), otherwise match by title and author.

Agents may read PDFs and write notes in parallel. Give each agent: the citation key, the PDF path,
the note skeleton from `references/litrev-notes.md`, and **the sentences in the manuscript that cite
that key** — so the "What we cite it for" section gets verified against the source rather than
invented from the paper's abstract.

If a PDF is absent, ask Mohammed to download it into the PDF root. Do not proceed on memory, and do
not write a note for a paper you have not opened. A note is a claim that you read it.

### 3. Verify every characterization

This is the part that earns the skill. For each cited key, check the manuscript's sentences about it
against the note:

- Does the manuscript describe what the paper actually does?
- Is a theorem cited **inside the setting it was proved in**? Manuscripts routinely cite a result
  under weaker hypotheses than the source assumed. The note's "Assumptions and setting" section
  exists for exactly this comparison.
- **Benchmark parameter attributions.** "The parameters recommended in [X]" requires knowing what [X]
  recommends. Check every value against the note's parameter table. An unattributed or altered
  competitor parameter is the single most effective thing a referee can attack.
- Is anything claimed as new that the cited work already does? Flag it loudly.

Each verified attribution gets marked **Verified** in the note, with the source location.

### 4. Coverage, the other direction

Which essential lineage or competing method is **uncited**? That gap is what a referee finds first,
and no amount of checking the existing citations will surface it.

Work from the method's actual ancestry: the originating paper for each component, the immediate
predecessors the paper improves on, and the competing approaches a reader would expect to see
compared. Anything you name from memory is a **lead, not a citation** — see the request flow below.

## `build-from-reading`

Same record, reversed inventory. The notes are the source of truth for what may be claimed.

1. Inventory the notes that exist. That is the set of papers you may characterize.
2. As the prose is written, every citation must resolve to a note. A citation with no note is
   blocked, not deferred.
3. When a claim needs support you have not read, that is a reading task before it is a writing task.
   Add it to the request flow or the reading list — never write the sentence first and find a
   citation for it afterwards.

## Requesting a reference that is not in the bibliography

**Never generate a bibliography entry from memory.** Fabricated entries pair real authors with
invented titles, journals, volumes, and DOIs, and they are convincing enough to survive casual
review.

What you write is a **lead**, not an entry — enough for Mohammed to find the paper, explicitly marked
unverified, with no invented precision:

```bibtex
% UNVERIFIED LEAD — needs verification and Zotero import before citing.
% Needed for: <the specific claim in §N that requires support>
% Recalled as: <author(s)>, approximately <year>, on <topic>. Venue uncertain.
% Do not cite this key until it appears in references.bib.
```

Write it to the request file. Mohammed verifies via Google Scholar, imports through Zotero, and
updates the bibliography. **Wait for confirmation before citing the key.** Never edit the
Zotero-managed bibliography directly.

If you cannot recall enough to make the lead findable, say that instead of padding it. "There is a
known result on X that we should cite, which I cannot identify precisely" is useful. An invented DOI
is worse than nothing.

## Rules

1. **No note, no citation.** Applies to characterizations too, not just `\cite` commands.
2. **Never characterize a paper from memory**, including one you are confident about.
3. **Never edit the Zotero-managed bibliography.** Requests go to the request file as unverified
   leads.
4. **A note means you read the PDF.** Not the abstract, not a summary, not another paper's
   description of it.
5. **Notes are flat and keyed by citation key**, one per reference. See
   `<toolkit>/guides/project-hub.md` for the surrounding notes discipline.
6. Record the inventory state in `notes/litrev/README.md` so the next session sees the open list
   without recomputing it.

## Reference files

- `references/litrev-notes.md` — the `notes/litrev/README.md` text and the per-key note skeleton.
- `<toolkit>/guides/project-hub.md` — notes discipline and the Active-notes index.
