# Transformation Checklist

Ordered procedure for deriving `source_files/main.tex` from a frozen `paper/main.tex`. Every step is
content-preserving: structure, formatting, and paths may change; sentences, math, numbers, citation
keys, and section order may not.

Work top to bottom. Log every applied step in `submission_manifest.md` with enough specificity that
`refresh` can replay it.

---

## 0. Before you start

- [ ] The publisher's `.cls` and sample `.tex` are present in `journals_templates/[JOURNAL_NAME]/`
      and you have read the sample end to end.
- [ ] You know, from the sample rather than from memory: the class options, the front-matter macro
      names, the abstract environment, the keyword environment, the bibliography mechanism.
- [ ] The full file inventory to copy has been confirmed with the user.

## 1. Document class

- [ ] Replace `\documentclass[...]{article}` with the journal's class and the options the sample uses.
- [ ] Note which options control review vs. final layout (single-column double-spaced for review is
      common) and pick the one the guide-for-authors asks for at this cycle.
- [ ] If the class needs a `\journalname{...}` or similar declaration, add it.

## 2. Preamble: drop what the class owns

The journal class controls page layout and typography. Yours must not fight it. Remove:

- [ ] `geometry` and any margin/column settings
- [ ] `setspace`, `parskip`, `\linespread`
- [ ] font packages: `mathptmx`, `mathpazo`, `times`, `newtxtext`, `microtype` — unless the sample
      loads them
- [ ] `abstract` package if the class provides its own abstract environment
- [ ] `titlesec` / section-formatting packages
- [ ] `fancyhdr` and header/footer customization
- [ ] `hyperref` **if the class loads it** — double-loading `hyperref` breaks in class-specific ways.
      Check the `.cls` for `\RequirePackage{hyperref}` before deciding.

Keep: `amsmath`, `amssymb`, `mathtools`, `graphicx`, `booktabs`, `algorithm`/`algorithmic`,
`enumitem`, and anything carrying actual content semantics — unless the class already loads it or
explicitly forbids it.

## 3. Preamble: add what the class requires

- [ ] Packages the sample `.tex` loads that your manuscript does not.
- [ ] `lineno` with `\linenumbers` if the journal requires line-numbered review copies.
- [ ] Class-specific option macros (Elsevier's `\biboptions{...}`, for instance).

## 4. Front matter

The single most error-prone step. Map field by field against the sample; never guess a macro name.

- [ ] Title — including any short/running title the class supports
- [ ] Authors, with the class's own author/affiliation linking mechanism
- [ ] Affiliations, in the class's own form
- [ ] Corresponding author marker and email
- [ ] ORCID, if the class supports it
- [ ] Abstract — moved into whatever environment the class expects, at whatever position
- [ ] Keywords — the class's environment, and its separator convention (`\sep` in `elsarticle`,
      commas elsewhere)
- [ ] MSC / AMS classification codes, JEL codes, PACS — the class's macro
- [ ] `\maketitle` or the class equivalent, in the position the sample puts it
- [ ] Funding, acknowledgments — some classes want these in front matter, most want a back section

Content preserved exactly: the title string, every author name, every affiliation string, every word
of the abstract, every keyword. Only the markup around them changes.

## 5. Theorem environments

- [ ] If the class declares its own theorem environments, use them and delete your `\newtheorem`
      declarations. Check whether the class's numbering matches yours — if the class numbers
      theorems within sections and yours numbered continuously (or vice versa), **cross-reference
      text like "by Theorem 3.2" that is written out literally will go wrong**. Search for literal
      numbered references and flag any you find; changing them is a content change and goes upstream.
- [ ] If the class provides none, keep your `amsthm` setup as is.
- [ ] Confirm the proof environment: `amsthm`'s `proof`, the class's own, or a manual one.
- [ ] Check `\qedhere` and QED symbol behaviour if the class overrides it.

## 6. Bibliography

Determine the target mechanism from the sample file, then convert.

**biblatex → BibTeX/natbib** (the common direction; most journals are BibTeX):

| From (biblatex) | To (natbib) |
|---|---|
| `\usepackage[...]{biblatex}` | `\usepackage{natbib}` (or nothing — many classes load it) |
| `\addbibresource{references.bib}` | delete |
| `\printbibliography` | `\bibliographystyle{<journal.bst>}` + `\bibliography{references}` |
| `\parencite{key}` | `\citep{key}` |
| `\textcite{key}` | `\citet{key}` |
| `\autocite{key}` | `\citep{key}` |
| `\cite{key}` | `\cite{key}` (numeric styles) or `\citep{key}` (author-year) |
| `\citeauthor` / `\citeyear` | same names exist in natbib |
| `\footcite{key}` | `\footnote{\citep{key}}` — flag for the user, this changes visual output |

- [ ] Every citation *key* is unchanged. Only the command spelling changes.
- [ ] The `.bst` name comes from the publisher bundle, not from memory.
- [ ] Trimmed `references.bib` carries `crossref` parents, `xdata` entries, and `@string` macros.
- [ ] biblatex-only fields (`date`, `journaltitle`, `location`) are ignored by BibTeX `.bst` files —
      entries may lose year or journal in the output. Check the trimmed entries for `date =` without
      `year =`, and for `journaltitle =` without `journal =`, and report them. **Do not rewrite
      `paper/references.bib`** — the fix is either a Zotero export-style change by the user or a
      field addition confined to the derived copy, and the user decides which.

**BibTeX → biblatex** (rare): reverse the table, and note that `.bst` styles have no biblatex
equivalent — the journal must supply a biblatex style or the direction is wrong.

## 7. Floats

- [ ] Figure and table environments: keep as is unless the class defines its own.
- [ ] Two-column classes break wide floats. Wrap wide figures/tables in `figure*` / `table*` and
      flag anything that will not fit a single column.
- [ ] `\includegraphics` paths rewritten to bare filenames; `\graphicspath` deleted.
- [ ] `[H]` placement (the `float` package) fails in some classes — replace with `[t]`/`[htbp]` if
      the class does not load `float`.
- [ ] `subfig` vs `subcaption` — classes often mandate one; converting between them is markup, not
      content, and is allowed.
- [ ] Table rules: `booktabs` is usually fine; check the class does not ban it.

## 8. Cross-references and labels

- [ ] Every `\label` and `\ref` unchanged.
- [ ] `\eqref` still available (needs `amsmath`).
- [ ] `cleveref` — if used, check load order against `hyperref` in the new preamble; `cleveref` must
      load last.
- [ ] Literal written-out numbers ("as shown in Section 4") are content. Do not touch; flag if the
      class renumbers.

## 9. Macros

- [ ] Keep user macro definitions in the preamble rather than expanding them.
- [ ] Check every macro name against the class for collisions. Common collisions: `\R`, `\N`, `\E`,
      `\P`, `\keywords`, `\email`, `\affiliation`, `\note`, `\proof`.
- [ ] On collision, rename the user's macro throughout the derived copy and log the rename. The
      output is identical; only the internal name changes.

## 10. Change markup and blinding

- [ ] `\rev`-style markup: strip, keep, or produce both clean and marked copies — user's decision.
      Stripping removes the command, never the text it wraps.
- [ ] Blinded version: remove author block, affiliations, acknowledgments, funding, and any
      self-identifying repository/institution URL.
- [ ] Self-identifying *prose* is content. Flag with line numbers; the user rewords it in
      `paper/main.tex`, then `refresh`.

## 11. Final structural sweep

- [ ] No absolute paths anywhere.
- [ ] No `\input`/`\include` pointing outside `source_files/`.
- [ ] Every `\includegraphics` target exists as a sibling file.
- [ ] Every `\cite` key exists in the trimmed `.bib`.
- [ ] No `\todo`, `\marginpar`, commented-out draft blocks, or `\listoftodos` left in.
- [ ] Sectioning depth is within what the class supports.
- [ ] `\end{document}` present and nothing after it.

## 12. Word-for-word content check

The check that justifies calling this content-preserving. Compare the derived body text against
`paper/main.tex`:

- [ ] Section titles identical, in identical order.
- [ ] Theorem/lemma/proposition statements identical.
- [ ] Every numeric value in every table identical.
- [ ] Abstract identical.
- [ ] No sentence added, removed, or reworded.

Report the result explicitly. If anything differs, it is a bug in the derivation unless the user
approved it as a structural change.

## 13. Hand off what only the user can verify

You cannot compile, so these belong to the user. List them as blocking items:

- [ ] Compiles under the journal class without errors
- [ ] `main.bbl` generated and placed in `source_files/`
- [ ] Bibliography renders with correct style, no `[?]` or missing entries
- [ ] All figures appear, at adequate resolution, in the right places
- [ ] No overfull boxes that push text into margins
- [ ] Page count within limit
- [ ] Line numbers present if required
- [ ] Author block, affiliations, corresponding author, ORCID all correct in the PDF
