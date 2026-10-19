# Review plan template

Copy the block below to `notes/review-plan.md` and tailor it to the paper (Phase 5). Replace every
`<…>`. Delete guidance in *italics* once it has been acted on. Keep the track letters even when a
track is N/A.

---

```markdown
# Review plan — <journal>, <manuscript ID>, round <N>

Status: **draft** | approved <date> by the user. Decisions on the plan are recorded below, dated.

## Decisions

- <date> — <decision> (the user; per <exchange NNN> if one informed it)

## Deliverables, mapped to the review form

| Form field | Where it is prepared | Decided by |
|---|---|---|
| <field, as the form labels it> | <file in report/round-<N>/, or text to paste> | the user |

<The authors' report file> goes to the authors and contains nothing confidential.

## Objects under review (anchors: page of the original file)

- <section, result, algorithm, table, or figure> — pp. <a–b>

## Workflow

### Map (Phase 4)

`notes/manuscript-map.md`, two parts only; detail is added later as tracks need it.
1. **Proof dependencies:** for each main result, each step, the result it invokes, and where.
2. **Claims ledger:** every claim in the abstract, the contributions, the experiment sections,
   the discussions, and the conclusion, each with a stable ID, its location, and the place meant
   to support it. Unassessed until Track F.

Search aid: `notes/manuscript-round-<N>.txt` (the original file is authoritative, especially for
mathematics).

### Tracks, in priority order

**Priority:** <default: A and B jointly first → E → I → F → C → G → D → H>.

*Why the default: novelty and correctness decide most recommendations, so they come first. E and I
come next because they take longest (PDFs to obtain, numbers to recompute). F follows the checks
it grades. C's proof-critical items are done under B. G and D reuse the ledger and Track A. Change
the order when the paper calls for it, and say why here.*

**A. Novelty and contributions** — <who>.
- Extract the claimed contributions verbatim, with their locations.
- Reduce the method or result to its simplest equivalent form: does it become a known scheme or
  theorem after a change of variables, a parameter choice, or a special case?
- Compare the precise increment with the closest cited works first, and with the authors' own
  earlier papers. Widen the search only if those comparisons leave a specific question open.
- Search for close uncited work without quoting the manuscript (Rule 2). A lead stays UNVERIFIED
  until its PDF is read.

**B. Proof correctness** — <who>.
- Line-by-line verification of <each main result>.
- Each invoked result's hypotheses checked at its point of use, with quantifiers and indices
  (whole sequence or subsequence; original or re-indexed).
- The bridge from each lemma's hypotheses to its use: operator assumptions, parameter ranges and
  their endpoints, and which version of a condition is actually needed.
- Well-definedness of any algorithm; joint satisfiability of the parameter conditions.
- Does the result cover what is implemented (exact versus inexact subproblems, fixed inner
  iterations, approximations)?
- Proof-critical items of Track C (definitions and lemmas the proofs rest on) are checked here.
- Record each of these separately where it applies (more than one can): an invalid inference; a
  counterexample to the statement; a complete proof under the printed hypotheses; a repair that
  changes the hypotheses. A gap may stand with the statement's truth open.

**C. Notation, definitions, cited results** — <who>. The rest of C after B: symbol consistency,
definitions before use, attribution of preliminary results. Elementary identities need no
source-hunting.

**D. Introduction and positioning** — <who>. Reuses Track A and the ledger; no second literature
exercise. Is the account of the cited work accurate (through `/litrev`)? Does the motivation match
what is proved and tested?

**E. Numerical experiments** — <who>, through `/numerics-audit` (referee mode, host arrangement).
- Specialize every update of the method for each experiment: the operators, parameters, and
  initializations actually used.
- Theory–experiment correspondence: do the runs satisfy the hypotheses of the results they
  illustrate?
- For each experiment: what the measured endpoint establishes; comparability (stopping rules, work
  per iteration, tuning, the same problem for every method); baseline parameters against their
  sources; recomputation of every derived number; repetitions and uncertainty.
- Data experiments: separation of training, tuning, and evaluation; the unit of observation;
  aggregation across folds or runs; traceability of every reported curve to held-out predictions.
- Supplied code, if any: read only. Does it implement the stated method, parameters, stopping
  rules, and baselines?

**I. Integrity, ethics, reproducibility** — <who>; judgment by the user.
- Identity and provenance of the data; selection and label definitions.
- For human data: ethics approval or waiver, and the consent basis.
- A feasible access route for restricted data (controlled access is acceptable).
- Code and data availability; declarations; overlap with the authors' earlier publications (with
  Track A).

**F. Overstatements** — <who>. Grade the ledger after B, E, and I: supported / partly supported /
unsupported / contradicted / unverifiable. Match each claim to the endpoint actually proved or
measured. Keep theoretical guarantees apart from finite-run performance.

**G. Conclusions** — <who>. Reuses the ledger grades and Tracks B and E.

**H. Readability and language** — <who>; rating by the user. A bounded pass: structure, template
leftovers, and enough representative examples to justify the rating and help the authors. Not a
copyedit.

### Synthesis (Phase 7)

1. Each finding gets a proposed severity: **Major** (correctness, validity of a claim, or
   novelty), **Minor** (clarity, completeness, presentation), or **Typo** (mechanical).
2. Each Major finding gets a **repair burden**: clarification / local correction / restriction of a
   result / new proof or new experiments. The repair burden, not the label, informs the
   recommendation.
3. The user accepts, edits, or drops each finding, and decides the recommendation and every form
   choice.

### Draft, revision, validation (Phases 8–9)

1. Draft per the deliverables map and
   `<toolkit>/skills/referee/references/report-conventions.md`; Track F on the draft.
2. Item-by-item revision with the user.
3. Final factual re-check of the whole report against the original evidence.
4. The user's final read, compilation, and submission.

## Findings pipeline

`notes/review-findings.md`, one entry per finding:
- **ID**, **track**, **location** (page + object)
- **observation** and **evidence** (exact quotation or derivation)
- **proposed severity**, and **repair burden** for a Major one
- **status**: open → verified → accepted / dropped → in report
- **source**: the main agent, a subagent, or external reviewer NNN (after verification)

## External reviewer exchanges

*Only if the user has chosen a reviewer. The user decides each exchange as the review goes.*

| NNN | Task | Status |
|---|---|---|

## Schedule (deadline: <date>)

- <day> — <phases and tracks>

## PDFs needed

*DOIs from metadata, never from memory. Missing PDFs and unverified leads are requested here.*

| Priority | Printed ref and source ID | DOI | Status |
|---|---|---|---|

Unverified leads (not cited by the authors; contents unread):
- UNVERIFIED LEAD — <what it is needed for>; recalled as <authors, approximate year, topic>
```
