---
name: prepare-submission
description: Package a finished manuscript for submission to a specific journal. Creates
  paper/submissions/[JOURNAL_NAME]/[cycle]_submission_[Month]_[Year]/ holding a flattened,
  upload-ready source_files/ and an empty journal_files/, transforms main.tex onto the journal's
  template, trims the bibliography to cited keys only, and scaffolds cover letter, response to
  reviewers, and manifest on approval. paper/main.tex is frozen - the transformation restructures
  and reformats, never changes content. Supports refresh (re-derive after the manuscript changed)
  and status modes.
invocation: user
---

# /prepare-submission — Journal Submission Packaging

Take a manuscript that is already submission-quality and package it for one journal, one cycle.
This skill moves files and reformats LaTeX. It does not write, revise, or improve the paper.

## The invariant that governs everything

**`paper/main.tex` is frozen and authoritative. `source_files/` is derived and regenerable.**

| | |
|---|---|
| `paper/main.tex` | The single source of truth for content. Never edited by this skill. |
| `source_files/main.tex` | A *derivation* of it: restructured, reformatted, re-pathed for the journal. Content identical. |

If the transformation reveals that the content itself must change — a sentence must be reworded for
a blinded version, a section must be cut for a page limit, an author block needs different
information — **stop, change `paper/main.tex`, then re-derive** with `refresh`. Never fix it
downstream in `source_files/`. A downstream fix is silently lost on the next refresh and puts the
frozen manuscript out of sync with what the journal actually received.

Corollary: `source_files/` is never derived from another journal's `source_files/`. Every derivation
starts from `paper/main.tex`.

## When to use this, and what it is not

| Skill | Job |
|---|---|
| `/suggest-journals` | Decides *which* journal. Runs before this. |
| `/review-paper`, `/ai-slop` | Get the manuscript to submission quality. Run before this. |
| **`/prepare-submission`** | Packages the finished manuscript for one journal, one cycle. Moves and reformats only. |
| `/join-revision` | Owns the revision phase between cycles. Produces the content this skill later re-packages. |

Do not use this skill to write the paper, fix prose, add results, or respond to reviewers on the
merits. It drafts the *scaffolding* of a cover letter and response document; the arguments in them
are yours.

## Modes

- `/prepare-submission` — start a new cycle, or continue an incomplete one
- `/prepare-submission refresh` — re-derive `source_files/` after `paper/main.tex` changed
- `/prepare-submission status` — inventory every journal, cycle, and blocking item; change nothing

## Canonical layout

```
paper/
├── main.tex                              ← FROZEN. Source of truth.
├── references.bib                        ← Zotero-managed. Never edited, never moved.
├── imgs/
└── submissions/
    ├── journals_templates/
    │   └── [JOURNAL_NAME]/               ← YOU download the publisher template here
    │       ├── elsarticle.cls
    │       ├── elsarticle-template.tex
    │       └── elsarticle-num.bst
    └── [JOURNAL_NAME]/
        ├── first_submission_August_2026/
        │   ├── source_files/             ← derived, flat, upload-ready
        │   ├── journal_files/            ← YOURS. Never written to by Claude.
        │   ├── cover_letter.tex
        │   └── submission_manifest.md
        ├── second_submission_January_2027/
        │   ├── source_files/
        │   ├── journal_files/
        │   ├── cover_letter.tex
        │   ├── response_to_reviewers.tex
        │   └── submission_manifest.md
        └── accepted_April_2027/
            ├── source_files/
            └── journal_files/
```

`journal_files/` belongs to the user: journal-produced PDFs, proofs, reviewer reports, portal
downloads, correspondence. Create it empty and never write into it. Never read from it unless the
user points at a specific file.

### Naming rules

- `[JOURNAL_NAME]` — the journal's standard abbreviation, uppercase: `AMC`, `JCAM`, `SIOPT`,
  `JOTA`, `COAP`. Confirm the abbreviation with the user; do not invent one.
- Cycle word — `first`, `second`, `third`, `fourth`, `fifth`, `sixth`, `seventh`, `eighth`,
  `ninth`, `tenth`. Spelled out, lowercase.
- `[Month]` — full English month name, capitalized. `[Year]` — four digits.
- Acceptance folder drops the word `submission`: `accepted_April_2027`.
- A rejection followed by a new journal resets the cycle: a new `[JOURNAL_NAME]/` folder starting
  at `first_submission_...`.

---

## Phase 0 — Context discovery

Do this before asking anything. Report a compact inventory, then ask.

1. Read the project `CLAUDE.md`.
2. Read `paper/main.tex` and record:
   - `\documentclass` and its options
   - every `\input` / `\include` and the file each resolves to
   - `\graphicspath`, every `\includegraphics` path, every asset extension
   - bibliography backend: biblatex (`\addbibresource`, `\printbibliography`) vs BibTeX/natbib
     (`\bibliographystyle`, `\bibliography`)
   - theorem environment declarations (`\newtheorem`, `amsthm` vs `ntheorem` vs class-provided)
   - custom macros in the preamble
   - `\rev`-style change markup left over from `/join-revision`
   - any local `.sty` / `.cls` the project ships
3. List `paper/submissions/` as it stands: which journals, which cycles, which are incomplete.
4. Check for a `paper/main.pdf` or similar and note its date relative to `main.tex` — a stale PDF
   means the user has not compiled since the last edit.

State plainly what you found, including anything that will make the transformation awkward
(a homemade `.cls`, deeply nested `\input`, assets outside `paper/`).

## Phase 1 — Journal and cycle

Ask, in one batch:

1. **Journal name and folder abbreviation.** Full name for the cover letter, abbreviation for the folder.
2. **Cycle.** Scan `paper/submissions/[JOURNAL_NAME]/` and propose the next one. Confirm rather
   than assume — a resubmission to the same journal after a *reject-and-resubmit* is a `first`
   submission again by some editors' reckoning and a `second` by others. The user decides.
3. **Month and year.** Default to the current date; the user may be preparing ahead.
4. **Template required?** Some journals accept any readable PDF for initial review and only demand
   their class at revision stage. If none is required, `source_files/main.tex` is the flattened,
   re-pathed manuscript with its own preamble intact — that is a legitimate and complete outcome.
5. **Blinded version required?** (double-blind review)

Create the journal folder and the cycle folder, plus `source_files/` and an empty `journal_files/`.

## Phase 2 — Template acquisition (a pause point)

Create `paper/submissions/journals_templates/[JOURNAL_NAME]/` if missing.

If a template is required and that folder is empty, **stop and hand off**. Tell the user exactly
what to download and where to put it:

- the class file (`.cls`)
- the publisher's sample/template `.tex`
- the bibliography style (`.bst`) if the journal uses BibTeX
- any required `.sty` shipped with the bundle
- the guide-for-authors, if it carries formatting rules not encoded in the class

Then wait. Do not proceed on a remembered version of the class.

**Never reconstruct a publisher class, its options, or its front-matter macros from memory.** Class
files change; author guidelines change more often. `references/publisher-templates.md` records what
each major publisher's bundle typically looks like — treat it as a map for reading the download, not
as a substitute for it. Every claim in it must be checked against the actual `.cls` and sample file
before you use it.

Once the files are present: read the `.cls` preamble and the sample `.tex` end to end. The sample
file is the specification. Note the exact front-matter macro names, the abstract and keyword
environments, the class options, and how the sample handles the bibliography.

## Phase 3 — Flattening decision

Ask which flattening the journal wants:

- **Flat directory, `\input` structure preserved** (default) — every file becomes a direct sibling in
  `source_files/`; no subdirectories; all paths rewritten to bare filenames. Multi-file manuscript.
- **Flat directory, `\input` inlined** — additionally splice every `\input`/`\include` body into
  `main.tex`, leaving one self-contained `.tex` plus assets.

Elsevier and Springer accept either; some portals and some copy-editing pipelines want one file.
When the guide-for-authors is silent, default to preserving `\input`.

Then list the exact file inventory you intend to copy, and get it confirmed before copying.

## Phase 4 — Build `source_files/`

File operations go through PowerShell (`Copy-Item`, `New-Item -ItemType Directory -Force`). Content
edits go through Edit/Write. Never Python.

**Copy rules**

- Copy only assets actually referenced by the manuscript. List unreferenced files in `paper/imgs/`
  as skipped — do not copy them, do not delete them.
- Flattening collisions: if two source files share a basename, prefix the copy with its source
  directory joined by an underscore (`imgs/convergence.pdf` and `imgs/extra/convergence.pdf` →
  `convergence.pdf` and `extra_convergence.pdf`). Record every rename in the manifest.
- Copy any local `.sty`/`.cls` the manuscript needs and the journal does not supply.
- Copy the journal class and `.bst` from `journals_templates/[JOURNAL_NAME]/` into `source_files/`
  only if the publisher's instructions say to include them. Most portals already have them; some
  require them in the upload. Check the guide-for-authors.

**Path rewrites in the copied `main.tex`**

- `\graphicspath{{imgs/}}` → delete (everything is a sibling now)
- `\includegraphics[...]{imgs/fig}` → `\includegraphics[...]{fig}`
- `\input{sections/theory}` → `\input{theory}`
- bibliography resource paths → bare filename

**Trimmed bibliography**

Build `source_files/references.bib` containing only the entries actually cited:

1. Collect keys from every citation command present — `\cite`, `\citep`, `\citet`, `\citealt`,
   `\citeauthor`, `\citeyear`, `\parencite`, `\textcite`, `\autocite`, `\footcite`, `\nocite` —
   across `main.tex` and every `\input` file. Split comma-separated key lists.
2. If `\nocite{*}` appears, the trimmed file is the whole bibliography; copy it verbatim.
3. Extract each key's entry verbatim from `paper/references.bib`. Carry along everything an entry
   depends on: `crossref` parents, `xdata` entries, and any `@string` macro definitions the file uses.
4. Report the count (`58 of 214 entries carried`) and list keys cited but absent from
   `references.bib`. **A missing key is a blocking error, not a warning** — it means the manuscript
   currently cites something the bibliography cannot resolve. Surface it and stop.

`paper/references.bib` is Zotero-managed and is never edited or moved. The trimmed file is a derived
artifact living only inside `source_files/`.

## Phase 5 — Template transformation

Content-preserving, and the boundary is not negotiable.

| May change | Must not change |
|---|---|
| `\documentclass` and options | Any sentence of body text |
| Package list (drop what the class provides, add what it requires) | Any mathematical expression |
| Front-matter macros: title, authors, affiliations, corresponding author, keywords, MSC/JEL codes | Any numeric result or table value |
| Abstract and keyword environments | Any citation key |
| Theorem environment *declarations* | Any theorem, lemma, or proof statement |
| Bibliography backend, style, and citation command spelling | Section order or sectioning depth |
| Float placement specifiers, table/figure environment wrappers | Table structure or figure content |
| Geometry, spacing, font packages (the journal class owns these — strip yours) | Labels and cross-references |
| Section command spelling where the class differs | Anything that adds or removes meaning |

Work through `references/transformation-checklist.md` in order. It covers the preamble mapping,
front-matter mapping, biblatex→natbib citation command translation, float and theorem handling, and
the breakages that show up most often.

**Change markup.** If `\rev` (or similar) markup survives from `/join-revision`, ask before touching
it. Many journals want two files at revision stage: a clean manuscript and one with changes marked.
If both are wanted, produce `main.tex` (clean) and `main_marked.tex` (markup retained), and say so in
the manifest. Otherwise strip the markup commands while leaving the text they wrap untouched.

**Blinding.** Removing the author block, affiliations, acknowledgments, and funding statements is
structural and belongs here. Self-identifying prose — "in our earlier work [12] we showed" — is
*content*. Flag every such sentence with its line number and hand it back for the user to reword in
`paper/main.tex`; do not silently rewrite it in the derived copy.

**Custom macros.** Keep the user's macro definitions in the preamble rather than expanding them,
unless the class or the publisher forbids custom macros. If a macro name collides with one the class
defines, rename the user's macro throughout the derived copy and log the rename.

Every change goes into the manifest's transformation log, in order, specific enough that `refresh`
reproduces it exactly. "Adapted front matter" is not a log entry. "Replaced `\author{...}\date{}`
block (lines 88–94) with `\begin{frontmatter}` block using `\author[inst1]` + `\affiliation[inst1]`;
moved abstract inside frontmatter; added `\begin{keyword}` from the `\keywords` line" is.

## Phase 6 — Approval-gated extras

Propose the full list, create only what the user approves. Nothing appears unasked.

| Artifact | When | Source |
|---|---|---|
| `submission_manifest.md` | Every cycle. Propose first — the rest of the workflow writes into it. | Built as you go |
| `cover_letter.tex` | Every cycle | `references/cover-letter-template.tex` |
| `response_to_reviewers.tex` | Cycle 2 and later | `references/response-to-reviewers-template.tex` |
| `highlights.tex` | Only if the journal requires (Elsevier: 3–5 bullets, ≤85 characters each) | Contributions in the introduction |
| `declaration_of_interest.tex` | Only if required as a separate file | Template stub |
| `data_availability.tex` | Only if required as a separate file | Template stub |
| `suggested_reviewers.md` | Only if the portal asks for names | User supplies; never invent names |

These live in the cycle base folder, not in `source_files/`, unless the journal wants them uploaded
as part of the LaTeX source.

Draft from actual manuscript content — the real title, the real contributions, the real methods.
Anything only the user knows goes in as an ALL-CAPS placeholder: `[MANUSCRIPT NUMBER]`,
`[EDITOR NAME]`, `[SUBMISSION DATE]`. Never invent an editor's name, a manuscript number, or a
reviewer suggestion.

For `response_to_reviewers.tex`, scaffold the structure — one block per reviewer, one sub-block per
comment, the comment quoted verbatim and the reply beneath it, each reply pointing at where the
change landed in the manuscript. The replies themselves are the user's; leave them as placeholders
unless the user dictates content.

## Phase 7 — Handoff

Close with a plain statement of what remains, because most of it is not yours to do.

**You cannot compile LaTeX, so you cannot claim the package builds.** Say that outright. What you
verified is that the files are present, the paths are internally consistent, and the transformation
is content-preserving. Whether it typesets is unverified until the user compiles.

Blocking items to list explicitly:

- compile `source_files/main.tex` and confirm it builds under the journal class
- generate `main.bbl` and drop it into `source_files/` (most publishers require the `.bbl`;
  `refresh` will preserve it)
- check the page limit, if the journal has one
- check figure resolution and format requirements
- fill every ALL-CAPS placeholder in the cover letter and response document
- after submission, save the portal PDF, confirmation email, and manuscript number into
  `journal_files/`, and record the manuscript number in the manifest

## `refresh` mode

For when `paper/main.tex` changed after the package was built.

1. Identify the target cycle folder. If more than one exists, ask — refreshing an already-submitted
   cycle rewrites the record of what was sent. Confirm the user means the in-progress one.
2. Re-read `paper/main.tex` from scratch. Do not trust the previous derivation.
3. Replay the transformation log from `submission_manifest.md` over the fresh content.
4. **Preserve non-derived files.** Anything in `source_files/` not listed in the manifest's derived
   inventory — `main.bbl`, a compiled PDF, a file the user dropped in — survives untouched. Only
   derived files are regenerated. Flag any preserved file that is now stale (a `.bbl` built from an
   older bibliography is worse than no `.bbl`).
5. Never touch `journal_files/` or the hand-authored cycle base files.
6. Report a diff: which derived files changed, which citation keys entered or left the trimmed
   bibliography, which assets were added or dropped, which transformation steps no longer applied
   cleanly.
7. Append the refresh to the manifest's history.

If a transformation step no longer applies — the log says "replace lines 88–94" and those lines now
say something else — stop and re-derive that step from the checklist rather than forcing it.

## `status` mode

Read-only. For each journal under `paper/submissions/`: every cycle, its date, whether
`source_files/` is complete, whether a `.bbl` is present, whether the manifest has unfilled
placeholders, whether `paper/main.tex` is newer than the derivation (a refresh is due), and what
sits in `journal_files/`. Change nothing.

## Rules

Inherited from the project and non-negotiable here:

1. **Never compile LaTeX.** No `pdflatex`, `latexmk`, `bibtex`, `biber`.
2. **Never edit `paper/main.tex` as part of a transformation.** Content changes are a separate,
   explicit decision by the user, made upstream and followed by `refresh`.
3. **Never edit or move `paper/references.bib`.** The trimmed copy is derived and lives only in
   `source_files/`.
4. **Never use Python.** File operations via PowerShell; content edits via Edit/Write.
5. **Never write into `journal_files/`.** Create it empty; it is the user's.
6. **Never fabricate** a class file, a class option, a publisher requirement, an editor's name, a
   manuscript number, a reviewer suggestion, or a bibliography entry.
7. **Never derive from another journal's `source_files/`.** Always from frozen `paper/main.tex`.

## Reference files

| File | Contents |
|---|---|
| `references/publisher-templates.md` | Per-publisher map: class names, front-matter macros, bib style, options, known gotchas. A map for reading the download — verify against the actual `.cls`. |
| `references/transformation-checklist.md` | The ordered content-preserving transformation: preamble, front matter, bibliography, floats, theorems, cross-references, post-compile verification. |
| `references/cover-letter-template.tex` | Cover letter, first-submission and resubmission variants. |
| `references/response-to-reviewers-template.tex` | Point-by-point response scaffold for cycle 2+. |
