---
name: numerics-audit
description: Adversarially audit a paper's numerical experiments against its claims. Extracts every
  empirical claim and tests it against the tables, derives the mathematical character of each test
  problem to ask whether it can exercise the paper's selling points, and checks stopping-criterion
  comparability, evaluation accounting, timing credibility, baseline fairness, and figure-table
  agreement. Runs in one of four modes depending on who can run experiments — including a referee
  mode for auditing someone else's paper. Use before submission, when auditing a manuscript's
  numerics, or when refereeing. Not for producing experiments or writing the results section.
invocation: user
---

# /numerics-audit — Adversarial Audit of Numerical Experiments

The question is not "do the tables look fine." It is **"does a hostile referee find the paper's
numbers supporting the paper's claims."**

Assume the experiments were prepared as submission-ready and audit them as such. Everything here is
done by reading the manuscript against itself; no run is required to find most of what is wrong.

**Never write a claim about a run you cannot verify.**

## What this is not

| | |
|---|---|
| `/ai-slop` | Audits the prose. Same adversarial posture, different subject. |
| `/review-paper` | Builds and tracks the item checklist; invokes this skill for its audit item. |
| `/jcode-script` | Produces the experiments. This skill only judges them. |
| **this skill** | **Do the reported numbers support the stated claims?** |

## The four modes

The host declares a mode, or you ask. Every mode supplies all five values, and the lenses read them
by name — nothing below is hardcoded.

| Mode | Evidence lookup | Findings sink | Markup / edit policy | Experiment handoff | Decision owner |
|---|---|---|---|---|---|
| `collaborator-owned` | `notes/litrev/<Key>.md` | `notes/review-findings.md` | `\rev{...}` batch in the manuscript | `templates/spec-note.md` → `notes/spec-<topic>.md` | Mohammed |
| `self-owned` | litrev note, else the cited PDF | `notes/review-findings.md` | direct edit, project convention | a new or modified script via `/jcode-script` | Mohammed |
| `no-runner` | litrev note, else the cited PDF | `notes/review-findings.md` | text-only fixes | **none** — every gap becomes a note | Mohammed |
| `referee` | the cited paper directly | the referee report itself | **no edits at all** | none | the referee |

Choosing:

- **`collaborator-owned`** — someone else owns the code and is available. Gaps become a spec.
- **`self-owned`** — the code is ours and runs can be commissioned. A gap found here is cheap: it
  becomes a script.
- **`no-runner`** — nobody can run anything. Every gap becomes a recorded finding, and claims that
  rest on missing runs get softened or dropped rather than supported.
- **`referee`** — someone else's paper. There is no `notes/`, no litrev record, and nothing to edit.
  Findings become numbered report points.

In `referee` mode, lens C cannot check baseline parameters against a litrev note because there is
none. Check attributions against the cited paper directly where you have it, and otherwise **mark
them unverifiable and say so in the report** — an unverifiable attribution is itself a referee point.

## Phase 0 — Establish the mode and the scope

1. Confirm the mode and record the five values explicitly. Do not start until all five are known.
2. Locate the manuscript, the experiment section, and every table and figure it contains.
3. Note whether the paper states its stopping criterion, its failure convention, and its evaluation
   accounting. If any is absent, that is already a finding — record it before reading a single table.

## Phase 1 — Run the five lenses

Full procedure in `references/audit-procedure.md`.

| Lens | Question |
|---|---|
| **A** | Claim inventory — every empirical claim, with a verdict against the tables |
| **B** | Do the test problems exercise the paper's selling points? |
| **C** | Is the comparison comparable? |
| **D** | Do the reported artifacts agree with each other? |
| **E** | Could a reader reproduce this? |

Sequential by default. The lenses cross-reference: C reads the evidence lookup, and D re-checks
numbers B flagged.

### Optional fan-out

For a large experiment section. Fan out **by lens, not by chunk** — unlike `/ai-slop`, each lens
needs the whole section, so splitting by section would break every one of them.

Order matters, and so does write isolation:

1. **The parent builds lens A first.** The claim inventory is the shared artifact everything else
   refers to.
2. **B, C, E run in parallel**, each writing its **own read-only report**. No subagent writes the
   findings sink and no subagent edits the manuscript.
3. **D runs after B** and after the table inventory exists — it re-checks what B flagged.
4. **The parent alone** consolidates the reports and performs disposition.

Without this, parallel lenses clobber the shared findings file and D can run before B has produced
anything to check.

## Phase 2 — Disposition

Sort every finding into one of three buckets and record it in the findings sink.

1. **Text fix.** The numbers are right; the prose overstates, mislabels, or omits a condition. Apply
   it under the mode's markup policy. **Softening a claim to match the data is the correct move, not
   a concession.**
2. **Needs a run.** The paper needs numbers that do not exist — a missing baseline, a larger
   dimension, a problem that actually exercises the selling point, a re-run under a common stopping
   rule. Route it through the mode's experiment handoff. Say plainly what claim currently rests on
   nothing.
3. **The decision owner's call.** Replacing an experiment, dropping a claim, adding a competitor,
   anything that changes the paper's scope. Present options with one recommendation and ask.

Report the buckets together with the claim inventory attached.

### `referee` mode output

No buckets — a numbered report instead. Each point states the claim, the evidence that fails to
support it, and what the authors would need to do. Separate points that block acceptance from points
that would improve the paper, and mark anything you could not verify from the manuscript alone rather
than asserting it.

## Rules

1. **Never write a claim about a run you cannot verify.**
2. **Never edit anything in `referee` mode.**
3. **A finding is a quotation plus a number**, not an impression. Cite the claim's location and the
   table cell that contradicts it.
4. **Recompute rather than trust.** Percentages, speedups, averages, and win tallies are all
   recomputed from the table, including the direction and the denominator.
5. **An absent statement is a finding.** A stopping criterion the paper never states cannot be
   checked, and that is the point.
6. Subagents in a fan-out are read-only. Only the parent writes.

## Reference files

- `references/audit-procedure.md` — the five lenses in full.
- `templates/spec-note.md` — the experiment specification, for the `collaborator-owned` handoff.
- `<toolkit>/guides/project-hub.md` — notes discipline for the findings sink.
