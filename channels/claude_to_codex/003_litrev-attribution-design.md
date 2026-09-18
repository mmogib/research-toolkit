# 003 — `/litrev` attribution-check design: review of three proposed edits

## Task

Review the three edits to the `/litrev` skill proposed in `notes/toolkit-litrev-proposal.md` §9,
under "Adopt now" (lines 323–337), using §10 (lines 371–end) as the evidence offered for them. For
each edit, decide whether it should be adopted as described, adopted with a change, or rejected, and
say what it would break, or fail to catch, in the skill as it stands. Done means one verdict per
edit, with reasons tied to file and line.

## Context

**Where the proposal came from.** §1–§8 of the note were written by the Claude session working on a
separate manuscript project (VNQEP). §9 is the toolkit's response. §10 is a test run on 2026-09-18
to check the reasoning in §9.

**The three edits, as proposed (§9, lines 325–337):**

> 1. **Notes quote the source.** Strengthen "What we cite it for" in `references/litrev-notes.md` so
>    a characterization claim carries the source's own words, not only a page number. This stands on
>    its own: without the quote, any later re-check means reopening the PDF.
> 2. **Reword Step 3 of `SKILL.md` as complete-list questions.** Instead of "Is a theorem cited
>    inside the setting it was proved in?", ask: for each hypothesis in the note's list, is it in the
>    manuscript's statement, and does the manuscript state anything not on the list? Same for
>    parameter values against the parameter table. This is the lesson of §2 that carries over to any
>    reader, and it needs no API.
> 3. **Proposal 2, led by the wording lesson.** `skills/litrev/references/attribution-checks.md`
>    opens with the rule — ask whether a condition is on the complete list, not whether the passage
>    supports the claim — and keeps the TypeSafe templates as one worked example. `/numerics-audit`
>    lens C points to it.

**What the edits would change:**
- `skills/litrev/SKILL.md` — Step 2, lines 76–86 (reading agents and what they are given); Step 3,
  lines 88–102 (the four verification questions).
- `skills/litrev/references/litrev-notes.md` — the per-key note skeleton, lines 47–91, especially
  "What we cite it for" (60–66), "Assumptions and setting" (68–71), the parameter table (73–80); and
  "Notes on filling it in", lines 95–110.
- `skills/numerics-audit/references/audit-procedure.md` — lens C, lines 58–87, especially baseline
  fairness and parameter provenance (76–87).

**The §10 test materials.** They lived in a temporary folder that will not survive, so they are
reproduced here in full. This is the only copy.

The passage — Corollary 4.4 of Lin and Ansari, J. Math. Anal. Appl. 296 (2004), p. 468, as
transcribed in the VNQEP project's `notes/litrev/Lin2004.md:25–42`, rewritten once as plain text:

```
Corollary 4.4. For each i ∈ I, let X_i be a nonempty convex subset of a topological vector space E_i, and let Q_i, T_i : X = ∏_{i∈I} X_i → 2^{X_i} be multivalued maps satisfying:
(a) for each i ∈ I and all x ∈ X, co Q_i(x) ⊆ T_i(x);
(b) for each i ∈ I and all x = (x_i)_{i∈I} ∈ X, x_i ∉ T_i(x), where x_i is the ith projection of x;
(c) for each i ∈ I and all y_i ∈ X_i, Q_i^{-1}(y_i) is compactly open in X;
(d) there exist a nonempty compact subset K of X and a nonempty compact convex subset C_i of X_i for each i ∈ I such that for all x ∈ X ∖ K there is i ∈ I with Q_i(x) ∩ C_i ≠ ∅.
Then there exists x̄ ∈ X such that Q_i(x̄) = ∅ for all i ∈ I.

The corollary is proved from Theorem 4.4 (p. 467) by setting G_i(x) = co Q_i(x).
Remark 4.6: by Proposition 4.1, condition (c) may be replaced by: Q_i^{-1} is transfer compactly open valued on X_i.
```

The old wording, as given to each Claude subagent after the passage:

```
For each claim below, decide how the passage relates to it. Choose exactly one label:
- supports — The passage states the claim or directly implies that it is true
- contradicts — The passage states the opposite of the claim or implies it is false
- says_nothing — The passage does not address what the claim asserts, either way

1. Corollary 4.4 requires that, for each i and each y_i in X_i, Q_i^{-1}(y_i) is compactly open in X.
2. Corollary 4.4 requires the multivalued map Q defined by Q(x) = ∏_i Q_i(x) to be Φ-condensing.
3. Corollary 4.4 requires a nonempty compact subset K of X and nonempty compact convex subsets C_i of X_i such that for every x in X ∖ K some Q_i(x) meets C_i.
4. Corollary 4.4 requires each topological vector space E_i to be Hausdorff.
```

The new wording:

```
The passage states Corollary 4.4 together with its complete list of hypotheses. For each condition below, is it among the hypotheses that Corollary 4.4 requires, as stated in this passage? Answer yes or no:
- yes — That condition appears among the stated hypotheses of Corollary 4.4 in this passage
- no — That condition does not appear among the stated hypotheses of Corollary 4.4 in this passage

1. for each i and each y_i in X_i, Q_i^{-1}(y_i) is compactly open in X
2. the multivalued map Q defined by Q(x) = ∏_i Q_i(x) is Φ-condensing
3. there exist a nonempty compact subset K of X and nonempty compact convex subsets C_i of X_i such that for every x in X ∖ K some Q_i(x) meets C_i
4. each topological vector space E_i is Hausdorff
```

Each subagent was also told to answer from the passage only, use no tools, and give one line per
question with a one-sentence reason. Jev received the same passage and the same claim and condition
strings, with the same label definitions, as a JSON request: `choice` questions for the old wording,
each phrased "How does the passage relate to the following claim about the source? CLAIM: '<claim>'",
and `noul` questions for the new wording, phrased as above one condition at a time. The results are
in §10 of the note.

## Deliverable

A reply with these sections:

- **`## Edit 1`, `## Edit 2`, `## Edit 3`** — each opens with one verdict line: *adopt as described*,
  *adopt with change*, or *reject*. Then the reasons, citing file and line. For *adopt with change*,
  give the replacement wording or structure. Under Edit 2, also say whether §10 supports it —
  *supported*, *partly*, or *not* — and why.
- **`## Missing`** — anything the three edits need, and do not contain, for the design to work in the
  skill as it stands. At most five, ranked by how much each matters. If none, say none.

## Constraints

See `channels/README.md`. Also:
- Out of scope: whether to run the Jev trial, and whether to adopt Proposal 1 (§3). Review the three
  edits only.
- Do not run code and do not call any API. Reason from the files and the materials above.
