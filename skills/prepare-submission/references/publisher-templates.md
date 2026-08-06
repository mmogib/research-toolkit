# Publisher Template Map

**Read this as a map for navigating a download you already have — never as a substitute for it.**

Class files and author guidelines change without notice, and publishers rename bundles between
journals. Everything below is a starting point for reading the actual `.cls` and the publisher's
sample `.tex`. Verify every macro name, option, and style file against those two files before using
them. When this document and the download disagree, the download wins.

Never reconstruct a class file, a class option, or a front-matter macro from memory.

---

## Elsevier — `elsarticle`

Applies to: AMC, JCAM, EJOR, Applied Numerical Mathematics, most Elsevier maths journals.

| | |
|---|---|
| Class | `elsarticle.cls` |
| Where | Elsevier's LaTeX instructions page for authors; also on CTAN |
| Common options | `[preprint,12pt]` (submission), `[review,12pt]` (double-spaced review copy), `[final,5p,times,twocolumn]` (journal layout) |
| Bibliography | natbib-based. `.bst` from the bundle: numeric and author-year variants ship together (`elsarticle-num`, `elsarticle-harv`, and `model`-prefixed variants). Take the exact filename from the download. |
| Citation options | `\biboptions{...}` before `\begin{document}` |

Front matter shape — confirm against the sample:

```latex
\begin{frontmatter}
\title{...}
\author[inst1]{...}
\ead{...}
\affiliation[inst1]{organization={...}, city={...}, country={...}}
\begin{abstract}
...
\end{abstract}
\begin{keyword}
kw1 \sep kw2 \sep kw3
\MSC[2020] 65K05 \sep 90C30
\end{keyword}
\end{frontmatter}
```

Gotchas:

- Keywords are separated by `\sep`, not commas.
- The abstract lives *inside* `frontmatter`.
- `\affiliation` takes structured key-value fields in recent versions and a plain string in older
  ones. Check which the downloaded class expects.
- Highlights are a separate file: 3–5 bullets, each ≤85 characters including spaces.
- The `review` option produces the double-spaced copy most editors want at first submission.

---

## Springer Nature — `sn-jnl`

Applies to: newer Springer journals. Older Springer journals still use `svjour3`.

| | |
|---|---|
| Class | `sn-jnl.cls` |
| Where | Springer's LaTeX template page for the specific journal |
| Common options | engine + reference-style pair, e.g. `[pdflatex,sn-mathphys-num]`. The reference-style token is journal-specific — **take it from the journal's own template page, not from another Springer journal**. |
| Bibliography | `.bst` shipped with the bundle, named to match the reference style |

Front matter uses structured name macros (`\fnm`, `\sur`) and `\affil` with numbered links; abstract
and keywords are macros rather than environments in some versions and environments in others. Read
the sample.

Gotchas:

- The reference-style option and the `.bst` must match, or citations render wrong with no error.
- Springer ships a different bundle per journal family (maths/physics vs. life sciences); using the
  wrong one produces a subtly wrong reference format.

### Springer, older — `svjour3`

| | |
|---|---|
| Class | `svjour3.cls` |
| Declaration | `\journalname{...}` required |
| Bibliography | `spmpsci.bst`, `spbasic.bst`, `spphys.bst` — pick per the journal's instructions |
| Front matter | `\title`, `\author`, `\institute`, `\date`, `\maketitle`; `\keywords{}` and `\subclass{}` inside the abstract environment in some configurations |

---

## SIAM — `siamart`

Applies to: SIOPT, SINUM, SIMAX, SIIMS.

| | |
|---|---|
| Class | `siamart` with a date suffix (`siamartYYMMDD.cls`) — the suffix changes with each release, so use exactly the file in the download |
| Where | SIAM's author resources / journal template page |
| Bibliography | `siamplain.bst` typically; confirm from the bundle |
| Companion files | The bundle ships supplementary-material and macro files; read the accompanying documentation `.tex` |

Gotchas:

- SIAM requires `\headers{short title}{short author list}`, and a `\newcommand` block near the top
  that the template pre-populates.
- Funding goes in a dedicated macro, not in acknowledgments.
- SIAM has an explicit supplementary-material mechanism; do not improvise one.

---

## IEEE — `IEEEtran`

| | |
|---|---|
| Class | `IEEEtran.cls` |
| Where | IEEE author center; also CTAN |
| Common options | `[journal]`, `[conference]`, `[10pt,journal,compsoc]` — per publication |
| Bibliography | `IEEEtran.bst` |
| Front matter | `\title`, `\author{... \IEEEmembership{...}}`, `\maketitle`, then `\begin{abstract}` and `\begin{IEEEkeywords}` |

Gotchas:

- Two-column by default: wide floats need `figure*`/`table*`.
- `IEEEtran` has strong opinions about equation and theorem formatting; check its documentation
  (`IEEEtran_HOWTO.pdf`, shipped with the bundle) rather than fighting it.

---

## Taylor & Francis — `interact`

| | |
|---|---|
| Class | `interact.cls` |
| Where | T&F's LaTeX template page for the journal |
| Common options | `[largeformat]` for some journals |
| Bibliography | numeric and author-year `.bst` variants ship with the bundle; the journal's instructions say which |
| Sample files | The bundle ships separate NLM/APA sample `.tex` files — use the one matching the journal's reference style |

---

## Wiley

Wiley has migrated template bundles more than once and the class name varies by journal family.
**Take the class name, options, and `.bst` entirely from the journal's own download.** Do not assume
a class name here.

---

## AMS

| | |
|---|---|
| Class | `amsart` |
| Where | CTAN / AMS author resources |
| Bibliography | `amsplain.bst` or `amsalpha.bst` |
| Front matter | `\title`, `\author`, `\address`, `\email`, `\thanks`, `\subjclass[2020]`, `\keywords`, `\begin{abstract}` before `\maketitle` |

Gotcha: in `amsart` the abstract environment comes *before* `\maketitle`, unlike most classes.

---

## When the journal has no LaTeX template

Legitimate and common — plenty of journals accept a PDF from any readable class for initial review.
In that case `source_files/main.tex` keeps the project preamble, and the only transformation is
flattening and path rewriting. Say so in the manifest so the next cycle knows why no class change
happened.

Still check the guide-for-authors for requirements that are not class-encoded: line numbering,
double spacing, figures at the end vs. in place, page limits, anonymization, reference format.

---

## Per-journal record

As journals are used, append what was actually found in that journal's download — class filename and
version, exact options used, `.bst` name, anything surprising. That record is worth more than
everything above, because it was verified.

| Journal | Class (exact filename) | Options used | `.bst` | Notes |
|---|---|---|---|---|
| | | | | |
