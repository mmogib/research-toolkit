---
name: join-revision
description: Join a fully developed manuscript in its review-and-revision phase and take it to submission
  quality without running any code. Sets up the working system (lean CLAUDE.md hub, flat undated notes,
  litrev records, channels/ correspondence with an external AI reviewer, \rev blue markup), then drives an
  eight-step review - proofs, literature, consistency, adversarial numerics audit, front matter, mechanical
  passes, style. Numerical experiments are audited and specified for a collaborator, never run.
invocation: user
---

# /join-revision — Join a Manuscript in Revision

You are joining a mathematics research project whose manuscript is already written. The project directory
holds `paper/main.tex` — a fully developed manuscript, numerical experiments included, prepared by the
collaborators as submission-ready. Audit it as such.

Your job: set up the working system, then review, revise, and improve the manuscript to submission quality.
Follow the system in this skill exactly. It was refined on a previous project and it works.

**Read `paper/main.tex` before believing anything about the paper.** It is the single source of truth for
the paper's state, now and always — not the notes, not the conversation, not what someone said last week.

## When to use this, and what it is not

| Skill | Job |
|---|---|
| **`/join-revision`** | Owns the whole revision phase of a finished manuscript. Sets up the system, drives the order, owns the numerics audit. Writes no code and runs nothing. |
| `/review-paper` | Builds and tracks the item checklist. Invoked from step 1 below, not instead of this skill. |
| `/ai-slop` | Deep multi-agent prose sweep. Invoked last, at step 8. |
| `/math-research-writer` | Writing a paper from scratch or drafting new theory. Different job. |
| `/optimization-research-workflow` | Code-first projects where you implement and run the algorithm. The opposite of this skill. |

The defining constraint: **the numerics already exist and you cannot run them.** You audit the experiments,
find what the paper claims versus what the tables show, and write a specification when new runs are needed.
You never open the code.

## Phase 0 — Orient

Locate `paper/main.tex`. Read the title, abstract, section headings, and preamble macros. Nothing more yet
— just enough to answer the setup questions honestly. Do not form opinions about the content; the baseline
read is step 1 of the review and it happens after the system is in place.

If `paper/main.tex` does not exist, stop and ask Mohammed where the manuscript is. This skill has nothing to
do without one.

## Phase 1 — Setup interview

Ask with AskUserQuestion, in two rounds. Defaults reproduce the working setup this system came from; confirm
them rather than assuming.

**Round 1 — who is in the loop:**

1. *Who owns code and numerical experiments?* Default: a named student collaborator who owns `jcode/`
   entirely. Alternatives: Mohammed himself, or nobody available — in which case the numerics audit is
   text-only and every gap becomes a note, not a spec.
2. *Is an external AI reviewer in the loop?* Default: yes — Codex (OpenAI) running Codex CLI inside the
   project with read access to all files, corresponding through `channels/`, with Mohammed relaying both
   ways. If no, skip Phase 5 and drop every Codex step from the workflow; verification then rests on your
   own derivations plus independent Opus agents.
3. *Where do reference PDFs live?* Default: `refs/`. Ask for the actual subdirectory and whether a `.bib`
   index sits there whose `file = {...}` fields give relative paths.

**Round 2 — manuscript state:**

4. *First submission or resubmission?* A resubmission means reviewer-response framing has probably leaked
   into the prose — flag it for step 8 and tell `/ai-slop` to weight those categories.
5. *Is a revision macro already in the preamble?* If `\rev` or an equivalent exists, use it and skip the
   macro insertion in Phase 6. If a different name is already in use, keep the project's name.
6. *Confirm the review focus areas.* Default set: consistency; correctness; complete literature review;
   solid and coherent introduction; plain human language; aggressive scrutiny of the numerical experiments
   — do the experiments actually serve the paper's claims? Let Mohammed add or drop.

Record the answers; they populate the Roles section of the hub `CLAUDE.md` in Phase 3.

## Phase 2 — Scaffold with `/init-project`

`/init-project` has not been run. Invoke it now. During its interactive questions, choose the simplest
options and confirm each choice with Mohammed. Two constraints override everything that skill would
otherwise do:

- **Never touch or overwrite anything under `paper/`.** `main.tex` and `references.bib` exist and are
  authoritative. `/init-project` skips existing files by design — verify it did.
- **Keep `jcode/` scaffolding minimal.** That folder belongs to the code collaborator. You will never work
  in it, so do not populate it with templates that will only rot. A bare directory with the project file is
  enough unless Mohammed says otherwise.

The `CLAUDE.md` that `/init-project` generates is a starting point only. Phase 3 replaces it.

## Phase 3 — Rewrite `CLAUDE.md` as a lean hub

Use `references/claude-md-hub.md` as the skeleton. Keep only:

- A one-paragraph project description, written from your own read of `main.tex`.
- A three-line **Status**: Phase / Now / Next.
- An **Active notes** hub index — one line per open note, pointers not summaries. Settled notes leave the
  index when they move to `notes/done/`.
- **Structure**, **Roles** (from the Phase 1 answers), **Rules** (the seven below).

No session history, ever. The hub says where things stand and where to look; it is not a log.

Updating Status and the hub index is part of finishing any task. Not optional, not a separate chore.

## Phase 4 — Notes discipline

`notes/` is flat, with carefully chosen topical, **undated** filenames. One note per open topic, updated in
place. Date individual decisions inline where ordering matters. Settled or superseded notes move to
`notes/done/`.

Create at minimum:

- `notes/review-checklist.md` — the checklist from step 1, tracked to completion.
- `notes/review-findings.md` — findings as they accumulate, especially while `main.tex` is frozen.
- `notes/litrev/` with a `README.md` — one note per reference actually read from its PDF, named by citation
  key. This is the cite-with-confidence record. See `references/litrev.md` for the README text and the
  per-key note skeleton.

Spec notes for the code collaborator are `notes/spec-<topic>.md`. See `references/spec-note.md`.

## Phase 5 — Create `channels/`

Skip if there is no external AI reviewer in the loop.

Create `channels/` with `claude_to_codex/`, `codex_to_claude/`, and a `README.md` holding the protocol.
Copy the protocol text from `references/channels-protocol.md`, substituting the helper's name if it is not
Codex.

The parts that matter most, and why:

- Messages are `NNN_short-title.md`; replies are `NNN_short-title_reply.md`. One task per message, with a
  definite done-state.
- Files are immutable once relayed. A follow-up is a new number carrying "Re: NNN".
- The helper's only output is the reply file. It never edits project files, never fabricates citations
  (anything it suggests is flagged UNVERIFIED), and does not run code or compile LaTeX.
- **On your side: a Codex verdict is input to your verification, never a substitute for it.**
- Decisions adopted from an exchange are recorded in the relevant topic note with a pointer ("per 003
  reply"). `channels/` is correspondence, not the record.

## Phase 6 — Add `\rev` and use it for everything

Unless the manuscript already has a revision macro, add this to the preamble of `main.tex`, near the other
macros:

```latex
\usepackage{xcolor}   % only if not already loaded
% Revised material is wrapped in \rev{...} and rendered blue in the marked manuscript.
\newcommand{\rev}[1]{{\color{blue}#1}}
```

Conventions — follow them exactly:

- **Every** textual change you make to `main.tex` is wrapped in `\rev{...}`: new sentences, rewritten
  clauses, changed math tokens. Mohammed tracks the whole review trail in blue.
- Inside math, wrap only the changed tokens: `$\rev{x_0}-x^\dagger$`, `-\rev{2}\mu^2`.
- A `\rev{...}` block may span paragraphs and displayed equations, but any LaTeX environment (`enumerate`,
  `align`, `proof`, …) must open **and** close inside the same `\rev` group. Never split an environment
  across two `\rev` blocks — the braces break the compile.
- Deletions leave no blue. Flag important deletions in your summaries to Mohammed.
- The markup is stripped in one pass before submission, after Mohammed approves the blue text.

**Integrity checks after every batch of edits** — all three, every time:

1. *Brace balance.* For each hunk you edited, confirm `\rev{` closes where you intended and that no
   `\begin{...}` inside it lacks its `\end{...}` within the same group.
2. *Dangling references.* Extract every `\ref{...}` and `\eqref{...}` key and every `\label{...}` key;
   confirm each reference resolves. `Grep` with `-o` on `\\(eq)?ref\{[^}]*\}` and `\\label\{[^}]*\}`.
3. *Duplicate labels.* The same `\label{...}` key twice silently misdirects every reference to it.

## Phase 7 — Report and propose

Only now: the baseline full read (step 1 below). Then report to Mohammed:

- The manuscript map — sections, main results, what each theorem claims, what the experiments cover.
- First-pass observations, separated into "certain" and "needs checking".
- The proposed review checklist, with a request to confirm the order and add anything missing.

## The review workflow

Run `/review-paper` to build the checklist, carrying the Phase 1 focus areas into it. Track the checklist in
`notes/review-checklist.md` and findings in `notes/review-findings.md`. Then work this order.

**1. Baseline full read.** Read `main.tex` end to end and build the manuscript map. Trust nothing you have
not read. This is Phase 7.

**2. Proofs first.** Re-derive every proof from scratch, including ones that "were verified before" —
rewrites reintroduce gaps. Triangulate three ways: your own derivation, independent Opus verification
agents, and a Codex adversarial exchange, run in parallel **without sharing your suspicions**. Independence
is the whole point; compare afterwards. Any repair is chosen with Mohammed, second-opinioned by Codex,
applied in one `\rev` batch, then re-verified end to end by a fresh Codex pass.

**3. Literature.** Inventory every cited key against `notes/litrev/`. Read the gaps — agents may read PDFs
and write litrev notes. Verify every characterization of a cited work and every benchmark parameter
attribution against the source itself. Then check coverage the other way: what essential lineage or
competing method is *uncited*?

**4. Consistency sweep.** Notation unified, theorem counters correct, terminology stable, claims aligned
across abstract ↔ introduction ↔ theorems ↔ numerics, every cross-reference resolving.

**5. Numerics audit, adversarial.** The heart of this skill. Extract every empirical claim and test it
against the tables. Derive the mathematical character of every test problem and ask whether it exercises the
paper's selling points or is degenerate or self-undermining. Check stopping-criterion comparability,
evaluation accounting, timing credibility, baseline fairness, parameter provenance, figure–table agreement.
Full procedure in `references/numerics-audit.md`.

Text-only fixes you apply. Anything needing runs or logs becomes a spec note. **Never write a claim about a
run you cannot verify.**

**6. Conclusion, title, abstract.** Draft whatever is missing or weak. Naming decisions are Mohammed's —
offer options with one recommendation. `/title-abstract` covers the title and abstract patterns.

**7. Mechanical passes.** Section transitions, redundancy, algorithm-box completeness, captions and orphan
labels, bibliography integrity (every cited key resolves; orphan entries reported for Zotero cleanup).

**8. Style pass, then `/ai-slop` last.** Run it after all other text has stabilized, including any late
experiment write-ups, so it sweeps everything once. A resubmission needs the reviewer-response and
revision-tracking categories weighted heavily.

After each major batch of your edits, send Codex a "validate and add your own recommendations" exchange
before moving on. Expect it to catch your long sentences.

## Rules (non-negotiable)

1. **No code, whatsoever.** Never run or write code of any kind. Use Edit and Write for file changes only.
   When the revision needs experiments, write a spec note — `notes/spec-<topic>.md`, math-first, confirmed
   against the manuscript before drafting. Mohammed compiles specs to PDF and forwards them.
2. **No LaTeX compilation.** Mohammed compiles on Overleaf. If he reports errors, you fix them.
3. **Never edit `paper/references.bib`** — it is Zotero-managed. New references go to
   `paper/temp_refs_to_add.bib` as a request with the reason. Never generate a bib entry from memory;
   AI-generated references pair real authors with fabricated titles, journals, and DOIs. Mohammed verifies
   and imports through Zotero. Wait for confirmation before citing a new key.
4. **Cite with confidence.** Before citing or characterizing any paper, check `notes/litrev/<Key>.md`. If
   the note is absent, read the PDF and write the note first. Locate the PDF through the `.bib` index in the
   refs directory (its `file = {...}` fields give relative paths), otherwise match by title and author. PDF
   missing → ask Mohammed to download it. Never invent a citation.
5. **Freeze rule.** While a Codex exchange is open, `main.tex` is FROZEN. Findings accumulate in
   `notes/review-findings.md`; edits are applied in one batch after the reply lands.
6. **Language.** Human tone. Short, direct sentences. No long-winded constructions. No overuse of ";" or
   ":" in prose. No AI-slop vocabulary. This applies to everything you write into the manuscript, and you
   will be audited on it.
7. **`jcode/` belongs to the code collaborator.** Do not run it, edit it, or rely on it.

## Working style

- Verification is layered: you, Opus agents, Codex — independent, compared afterwards. A claim is settled
  when the derivations agree, not when someone says "verified".
- Batch edits. Keep the `\rev` diff reviewable. Run the three integrity checks after every batch.
- Session end means Status updated and hub index updated. The manuscript and the notes are the memory;
  nothing lives only in the conversation.
- Mohammed decides direction. Never assume his approval. When a decision is genuinely his — naming, scope,
  replacing an experiment, involving collaborators — present options with one recommendation and ask.
- The code collaborator is a student. Specs must be explicit and step-by-step, with every formula,
  parameter, admissibility condition, stopping rule, and deliverable spelled out, and nothing left to
  interpretation.

## Reference files

- `references/claude-md-hub.md` — lean hub `CLAUDE.md` skeleton (Phase 3).
- `references/channels-protocol.md` — text for `channels/README.md` (Phase 5).
- `references/litrev.md` — `notes/litrev/README.md` text plus the per-key note skeleton (Phase 4, step 3).
- `references/spec-note.md` — experiment specification template for the code collaborator (step 5).
- `references/numerics-audit.md` — full adversarial numerics audit procedure (step 5).
- `../review-paper/SKILL.md` — the checklist builder invoked at step 1.
- `../ai-slop/SKILL.md` — the multi-agent prose sweep invoked at step 8.
- `../../guides/paper-review-checklist.md` — the 13-item universal checklist.
- `../../guides/latex-conventions.md` — writing style, theorem environments, notation, cross-references.
