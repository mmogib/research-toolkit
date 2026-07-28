# Adversarial numerics audit

Review step 5, and the part of this skill with the most leverage. The experiments were prepared as
submission-ready. Audit them as such: the question is not "do the tables look fine" but "does a hostile
referee find the paper's numbers supporting the paper's claims".

You cannot run anything. That is a constraint, not a limitation — everything below is done by reading the
manuscript against itself. Text-only fixes you apply in a `\rev` batch. Anything needing runs or logs
becomes a spec note (`references/spec-note.md`).

**Never write a claim about a run you cannot verify.**

---

## A. Claim inventory

Extract every empirical claim in the manuscript into a table in `notes/review-findings.md`. Claims live in
the abstract, the introduction's contribution list, the experiment section's prose, and the conclusion —
the introduction and conclusion are where the overclaims are.

| # | Claim (quoted) | Where | Supporting table/figure | Verdict |
|---|---|---|---|---|

Verdicts: **supported** / **partially supported** (true on a subset — the text has to say which) /
**unsupported** / **contradicted** / **unverifiable without a run**.

Test each claim against the actual numbers:

- Do the numbers quoted in the prose match the table? Transcription drift is common after a revision.
- Superlatives: "outperforms in all cases", "fastest", "best". One losing row falsifies it. Count the rows.
- Averages: is the average over successful runs only? Over a different success set per method? Then it is
  not a comparison.
- "Significantly", "substantially": on what margin, and does the margin survive the failure cases?
- Percentages and speedups: recompute them from the table. Check the direction and the denominator.

## B. Do the test problems exercise the paper's selling points?

Derive the mathematical character of every test problem from its definition in the manuscript. For each:

- Is it monotone? Lipschitz? Is $F$ linear or affine? Is the Jacobian symmetric, sparse, structured?
- Where is the solution — at the origin, at a vertex, in the interior of the feasible set? A solution at the
  origin with a starting point near it tests nothing.
- Is the feasible set active at the solution? If no constraint is active anywhere, a paper about constraint
  handling has demonstrated nothing.
- Do the dimensions span a real range, or does the largest case still fit the small-problem regime?
- Are the starting points feasible? Are they varied, or is every one a scaling of the same vector?

Then the decisive question, per selling point: **the paper claims X — which problem in the set can only be
solved well by a method with property X?** If none, the experiments do not support the claim, whatever the
tables show.

Two failure modes to name explicitly if you find them:

- **Degenerate.** Every method converges in a handful of iterations, so the table measures noise.
- **Self-undermining.** The problems that best match the paper's stated motivation are the ones where the
  proposed method's margin is smallest, or where a competitor wins.

## C. Comparability of the comparison

- **Stopping criteria.** Same inequality, same norm, same tolerance, same iteration cap for every method? A
  method stopping on $\|F(x_k)\| \le \varepsilon$ against one stopping on a relative residual are not
  measured on the same scale. If the manuscript does not state the criterion, that is a finding by itself.
- **Failure handling.** How is a run that hits the cap recorded? Excluded from averages, counted at the cap,
  or silently dropped? Different success sets across methods make the averages meaningless. The paper must
  state the convention.
- **Evaluation accounting.** Does the function-evaluation count include line-search evaluations, inner
  iterations, projections? A derivative-free method's advantage lives entirely in this column, so its
  definition has to be stated and identical across methods.
- **Per-iteration cost.** If iteration counts favor one method and time favors another, the paper must
  address it rather than quoting whichever is convenient in each paragraph.
- **Timing credibility.** Same machine, same language and version, warm-up excluded, repeated runs or a
  single one? Are times consistent with the iteration counts — a method with half the iterations and triple
  the time needs an explanation. Suspiciously round numbers and zero entries are worth flagging.
- **Baseline fairness.** Are competitors run with the parameters recommended in their own papers? Check each
  against `notes/litrev/<Key>.md`. An unattributed or altered competitor parameter is the single most
  effective thing a referee can attack.
- **Parameter provenance.** Every parameter in the experiment section traces to either the manuscript's own
  theory (with its admissibility condition satisfied — check the inequality with the actual numbers) or to a
  cited source. Values with neither are findings.
- **Tuning asymmetry.** Was our method tuned on the test set while competitors used defaults? If so, the
  paper has to disclose it.

## D. Consistency of the reported artifacts

- Every number in the prose matches its table cell.
- Table totals, counts, and win tallies recompute correctly.
- Figures agree with tables: a performance profile's value at $\tau = 1$ is the fraction of problems where
  that method won outright — count the wins in the table and compare. Curves must be non-decreasing and end
  at the fraction solved, not at 1 if there were failures.
- Axis labels, units, and legends match what the caption claims is plotted.
- Every table and figure is referenced in the text, and every reference points to the right one.
- Captions are self-contained: a reader who only reads captions knows what is being compared and under what
  stopping rule.
- Dimensions, problem names, and method names are spelled identically in text, tables, and figures.
- Digit counts are consistent within a column, and precision is not implying accuracy the setup cannot
  deliver.

## E. Reproducibility

- Are random seeds fixed and stated? Is the number of repetitions stated for anything stochastic?
- Is the hardware and software environment stated?
- Could a reader reimplement the experiment from the manuscript alone? Whatever is missing is a finding, and
  usually a cheap one to fix in text.

## F. Disposition

Sort every finding into one of three buckets and record it in `notes/review-findings.md`:

1. **Text fix.** The numbers are right; the prose overstates, mislabels, or omits a condition. Fix it in a
   `\rev` batch. Softening a claim to match the data is the correct move, not a concession.
2. **Spec.** The paper needs a run that does not exist — a missing baseline, a larger dimension, a problem
   that actually exercises the selling point, a re-run under a common stopping rule. Write
   `notes/spec-<topic>.md`. Say plainly in the note what claim currently rests on nothing.
3. **Mohammed's call.** Replacing an experiment, dropping a claim, adding a competitor, or anything that
   changes the paper's scope. Present options with one recommendation and ask.

Report the buckets to Mohammed together, with the claim inventory attached. He decides what goes to the
collaborator.
