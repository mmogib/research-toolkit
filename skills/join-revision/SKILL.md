---
name: join-revision
description: Join a fully developed manuscript in its review-and-revision phase and take it to submission
  quality without running any code. Sets up the working system through /init-project adopt and /channels,
  then drives an eight-step review - proofs, literature, consistency, adversarial numerics audit, front
  matter, mechanical passes, style - delegating each procedure to its own skill while owning the order and
  the arrangement. Numerical experiments are audited and specified for a collaborator, never run.
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
| **`/join-revision`** | Owns the whole revision phase of a finished manuscript: the order of the work, and the arrangement every other skill runs under. Writes no code and runs nothing. |
| `/init-project adopt` | Scaffolding and the hub. Invoked at Phase 2. |
| `/channels` | External-reviewer correspondence. Invoked at Phase 4. |
| `/review-paper` | Builds the item checklist. Invoked `checklist-only` at step 1. |
| `/litrev` | Cite-with-confidence audit. Invoked at step 3. |
| `/numerics-audit` | Adversarial numerics audit. Invoked at step 5. |
| `/ai-slop` | Deep multi-agent prose sweep. Invoked last, at step 8. |
| `/math-research-writer` | Writing a paper from scratch or drafting new theory. Different job. |
| `/optimization-research-workflow` | Code-first projects where you implement and run the algorithm. The opposite of this skill. |

This skill is an orchestrator. When a procedure lives in another skill, invoke it and supply the
arrangement — do not restate the procedure here, or the two copies drift and the one in front of you
wins.

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
   ways. If no, skip Phase 4 and drop every helper step from the workflow; verification then rests on your
   own derivations plus independent Opus agents.
3. *Where do reference PDFs live?* Default: `refs/`. Ask for the actual subdirectory and whether a `.bib`
   index sits there whose `file = {...}` fields give relative paths.

**Round 2 — manuscript state:**

4. *First submission or resubmission?* A resubmission means reviewer-response framing has probably leaked
   into the prose — flag it for step 8 and tell `/ai-slop` to weight those categories.
5. *Is a revision macro already in the preamble?* If `\rev` or an equivalent exists, use it and skip the
   macro insertion in Phase 5. If a different name is already in use, keep the project's name.
6. *Confirm the review focus areas.* Default set: consistency; correctness; complete literature review;
   solid and coherent introduction; plain human language; aggressive scrutiny of the numerical experiments
   — do the experiments actually serve the paper's claims? Let Mohammed add or drop.

Record the answers; you pass them to `/init-project adopt` in Phase 2, which writes the hub's Roles
block from them. Do not let it ask the same questions again.

## Phase 2 — Scaffold with `/init-project adopt`

The manuscript exists, so this is an adoption, not a new project. Invoke `/init-project adopt`. It
owns the root `CLAUDE.md` hub and the migration — you do not write one by hand.

**Pass in what you already know**, so nothing is asked twice: the arrangement from Round 1 (who owns
code, whether an external reviewer is in the loop, the helper's name), and these two constraints,
which are yours as the host:

- **Never touch or overwrite anything under `paper/`.** `main.tex` and `references.bib` exist and are
  authoritative.
- **Keep `jcode/` scaffolding minimal or absent.** That folder belongs to the code collaborator. You
  will never work in it, so nothing may be scaffolded into it.

Verify the result: `paper/` untouched, `jcode/` unchanged, and the hub carrying the Roles block for
the arrangement you supplied. If a legacy `CLAUDE.md` was migrated, review the extracted notes before
continuing — they were derived from a file you did not write.

## Phase 3 — Notes discipline

`/init-project adopt` creates `notes/`, `notes/done/`, and `notes/litrev/`. The discipline —
flat, topical, **undated** filenames, one note per open topic, updated in place — is in
`<toolkit>/guides/project-hub.md`. Date individual decisions inline where ordering matters.

Create these two beyond what adopt scaffolds:

- `notes/review-checklist.md` — the checklist from step 1, tracked to completion.
- `notes/review-findings.md` — findings as they accumulate, especially while `main.tex` is frozen.

Both get a line in the hub's `## Active notes`.

Spec notes for the code collaborator are `notes/spec-<topic>.md`, from
`<toolkit>/templates/spec-note.md`.

## Phase 4 — Create `channels/`

Skip if there is no external AI reviewer in the loop.

**Invoke `/channels`** to scaffold. Supply the two values it needs, which are yours to decide:

- **Frozen artifact:** `paper/main.tex`
- **Findings destination:** `notes/review-findings.md`

That skill owns the protocol, message composition, and the reply lifecycle. What matters here is the
consequence for your workflow: **while an exchange is open, `main.tex` is frozen.** Findings
accumulate in `notes/review-findings.md` and are applied in one batch after the reply lands.

A helper verdict is input to your verification, never a substitute for it. Adversarial exchanges go
out without sharing your suspicions.

## Phase 5 — Add `\rev` and use it for everything

Unless the manuscript already has a revision macro, add the `\rev` setup from
`<toolkit>/guides/latex-conventions.md` § Revision Markup to the preamble, near the other macros.
That guide owns the convention and the three integrity checks — brace balance, dangling references,
duplicate labels.

What this skill adds: **every** textual change you make to `main.tex` is wrapped, and **you run all
three integrity checks after every batch of edits.** Not occasionally, not when something looks off.
Mohammed tracks the whole review trail in blue and compiles it; a broken group means a manuscript
that does not build, found by him rather than you.

## Phase 6 — Report and propose

Only now: the baseline full read (step 1 below). Then report to Mohammed:

- The manuscript map — sections, main results, what each theorem claims, what the experiments cover.
- First-pass observations, separated into "certain" and "needs checking".
- The proposed review checklist, with a request to confirm the order and add anything missing.

## The review workflow

Run `/review-paper checklist-only` to build the checklist, carrying the Phase 1 focus areas into it.
That mode returns the checklist and stops — this skill owns the order in which the work happens, and
a full `/review-paper` run would start executing items (including the style sweep reserved for step 8)
at step 1. Track the checklist in
`notes/review-checklist.md` and findings in `notes/review-findings.md`. Then work this order.

**1. Baseline full read.** Read `main.tex` end to end and build the manuscript map. Trust nothing you have
not read. This is Phase 6.

**2. Proofs first.** Re-derive every proof from scratch, including ones that "were verified before" —
rewrites reintroduce gaps. Triangulate three ways: your own derivation, independent Opus verification
agents, and a Codex adversarial exchange, run in parallel **without sharing your suspicions**. Independence
is the whole point; compare afterwards. Any repair is chosen with Mohammed, second-opinioned by Codex,
applied in one `\rev` batch, then re-verified end to end by a fresh Codex pass.

**3. Literature.** **Invoke `/litrev` in `audit-manuscript` mode.** It inventories every cited key
against `notes/litrev/`, reads the gaps, verifies every characterization and every benchmark
parameter attribution against the source, and checks the reverse direction for uncited lineage. A
missing PDF is a request to Mohammed, never a guess.

**4. Consistency sweep.** Notation unified, theorem counters correct, terminology stable, claims aligned
across abstract ↔ introduction ↔ theorems ↔ numerics, every cross-reference resolving.

**5. Numerics audit, adversarial.** **Invoke `/numerics-audit`** in the mode matching the Round 1
answer:

| Who owns the experiments | Mode |
|---|---|
| A named collaborator, available | `collaborator-owned` |
| Nobody available | `no-runner` |

Supply the arrangement values: evidence lookup `notes/litrev/<Key>.md`, findings sink
`notes/review-findings.md`, markup policy `\rev{...}` batch, experiment handoff
`<toolkit>/templates/spec-note.md` → `notes/spec-<topic>.md`, decision owner Mohammed.

Findings come back in three buckets. Text-only fixes you apply in a `\rev` batch — softening a claim
to match the data is the correct move, not a concession. Anything needing runs becomes a spec note.
Scope changes go to Mohammed with one recommendation.

**Never write a claim about a run you cannot verify.**

**6. Conclusion, title, abstract.** Draft whatever is missing or weak. Naming decisions are Mohammed's —
offer options with one recommendation. `/title-abstract` covers the title and abstract patterns.

**7. Mechanical passes.** Section transitions, redundancy, algorithm-box completeness, captions and orphan
labels, bibliography integrity (every cited key resolves; orphan entries reported for Zotero cleanup).
The semantic half of bibliography integrity was already done at step 3 by `/litrev` — this pass is the
mechanical remainder.

**8. Style pass, then `/ai-slop` last.** Run it after all other text has stabilized, including any late
experiment write-ups, so it sweeps everything once. A resubmission needs the reviewer-response and
revision-tracking categories weighted heavily.

After each major batch of your edits, send Codex a "validate and add your own recommendations" exchange
before moving on. Expect it to catch your long sentences.

## Rules (non-negotiable)

1. **No code, whatsoever.** Never run or write code of any kind. Use Edit and Write for file changes only.
   When the revision needs experiments, write a spec note — `notes/spec-<topic>.md` from
   `<toolkit>/templates/spec-note.md`, math-first, confirmed against the manuscript before drafting.
   Mohammed compiles specs to PDF and forwards them.
2. **No LaTeX compilation.** Mohammed compiles on Overleaf. If he reports errors, you fix them.
3. **Never edit `paper/references.bib`** — it is Zotero-managed. New references go to
   `paper/temp_refs_to_add.bib` as an unverified lead with the reason. Never generate a bib entry from
   memory; AI-generated references pair real authors with fabricated titles, journals, and DOIs. Mohammed
   verifies and imports through Zotero. Wait for confirmation before citing a new key. `/litrev` owns the
   flow.
4. **Cite with confidence.** Before citing or characterizing any paper, check `notes/litrev/<Key>.md`. No
   note means you have not read it. PDF missing → ask Mohammed to download it. Never invent a citation.
   `/litrev` owns the procedure; this rule stays here because it binds every session, invoked or not.
5. **Freeze rule.** While a `channels/` exchange is open, `main.tex` is FROZEN. Findings accumulate in
   `notes/review-findings.md`; edits are applied in one batch after the reply lands. This skill owns
   both values and supplies them to `/channels`.
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

## What this skill delegates

It owns the order and the arrangement. Five skills own the procedures.

| Where | Skill | This skill supplies |
|---|---|---|
| Phase 2 | `/init-project adopt` | The Round 1 answers, and the `paper/` and `jcode/` constraints |
| Phase 4 | `/channels` | Frozen artifact (`paper/main.tex`), findings destination |
| Step 1 | `/review-paper checklist-only` | The Phase 1 focus areas |
| Step 3 | `/litrev` | Mode `audit-manuscript` |
| Step 5 | `/numerics-audit` | Mode `collaborator-owned` or `no-runner`, and all five values |
| Step 8 | `/ai-slop` | Resubmission weighting for the revision-cycle categories |

## Reference files

- `../../guides/project-hub.md` — hub shape and notes discipline (Phases 2–3).
- `../../guides/latex-conventions.md` — `\rev` convention and the three integrity checks (Phase 5),
  plus writing style, theorem environments, notation, cross-references.
- `../../guides/paper-review-checklist.md` — the 14-item universal checklist.
- `../../templates/spec-note.md` — experiment specification for the code collaborator (step 5).
