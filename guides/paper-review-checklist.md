# Paper Review & Polish Checklist

Battle-tested 13-item checklist for final paper polish before submission. Complete items in order.

## The Checklist

### 1. Notation & LaTeX Style
- [ ] Consistent use of `\mathbb{R}`, `\subseteq`, operators throughout
- [ ] Theorem/Lemma/Proposition/Remark environments use shared counter (`\newtheorem{lemma}[theorem]{Lemma}`)
- [ ] All math operators defined via `\DeclareMathOperator` (not ad hoc `\text{...}`)
- [ ] Consistent notation for: inner product, norm, partial order, cone, Jacobian
- [ ] No bare `i` or `j` in subscripts — use `_i` not `_ i` (space issues)

### 2. Proof Review
For each theorem, lemma, proposition:
- [ ] All assumptions explicitly cited (e.g., "By (A3), ...")
- [ ] Every inequality chain is justified (triangle inequality, Cauchy-Schwarz, etc.)
- [ ] No hidden assumptions (e.g., using continuity that hasn't been assumed)
- [ ] Limit arguments are rigorous (subsequences, compactness invoked explicitly)
- [ ] Upper semicontinuity vs. lower semicontinuity used correctly
- [ ] Convergence mode specified (pointwise, uniform, in norm)

### 3. Assumptions Audit
- [ ] All assumptions (A1), (A2), ... are used somewhere in the paper
- [ ] No assumption is redundant (implied by another)
- [ ] Each theorem/lemma states exactly which assumptions it needs
- [ ] No hidden additional assumptions in proofs

### 4. Subdifferential Construction (for nonsmooth papers)
- [ ] Clarke subgradient formulas stated for each nonsmooth operation (max, abs, norm)
- [ ] Chain rules cited or derived
- [ ] Regularity conditions verified (Clarke regularity if needed)

### 5. Gradient/Subgradient Verification
- [ ] Mention finite difference verification in the paper
- [ ] State the step size used (e.g., h = 10^{-7})
- [ ] Note which problems fail at nondifferentiability points (expected behavior)

### 6. Abstract Polish
- [ ] States the problem class
- [ ] Lists key contributions (matching the introduction)
- [ ] Mentions experimental scope (number of problems, key findings)
- [ ] No forward references or citations
- [ ] Under journal word limit

### 7. Introduction Tightening
- [ ] No paragraphs longer than 8-10 lines
- [ ] Each paragraph has one clear purpose
- [ ] Literature review is organized (not a list dump)
- [ ] Contributions list matches what the paper actually delivers
- [ ] No repetition between intro subsections

### 8. Section Transitions
- [ ] Each section begins with a brief contextual sentence connecting to previous section
- [ ] Reader can follow the logical flow without backtracking
- [ ] No abrupt topic changes

### 9. Redundancy Check
- [ ] Same information not stated in multiple sections
- [ ] If material is discussed in detail later, use a brief mention + forward reference earlier
- [ ] No circular cross-references (A → B → A)

### 10. Algorithm Presentation
- [ ] Algorithm environment is self-contained (all notation defined or referenced)
- [ ] Input/output clearly stated
- [ ] Step numbering is unambiguous
- [ ] Termination criterion explicitly stated
- [ ] Line search / subproblem clearly specified

### 11. Figure & Table Captions
- [ ] Captions are self-contained (reader understands without reading main text)
- [ ] Tables have units where applicable
- [ ] Figures have axis labels
- [ ] All figures/tables are referenced in the text
- [ ] No orphan figures/tables (referenced but not present, or present but not referenced)

### 12. Bibliography
- [ ] All `\cite` keys resolve (no undefined references)
- [ ] No orphan bib entries (in .bib but never cited) — optional cleanup
- [ ] Author names consistent (no duplicate entries for same paper)
- [ ] Year, journal, volume, pages present for published papers
- [ ] Preprints marked as such

### 13. Style Pass
- [ ] No AI-sounding prose: "robust", "crucial", "comprehensive", "streamline", "leverage", "fundamental", "notably"
- [ ] No named-paragraphs with bold labels
- [ ] No excessive hedging ("it is worth noting that", "it should be mentioned that")
- [ ] Sentences are direct and specific
- [ ] No repeated words in close proximity
- [ ] Consistent tense (present for math, past for experiments)
- [ ] Final proofread for: missing periods, incomplete sentences, double spaces, missing colons before lists/displays

## How to Execute

1. Read the entire paper once for overall impression
2. Work through items 1-13 in order
3. For each item, search systematically (grep for patterns, read line-by-line where needed)
4. Track findings and fixes in a checklist note (`notes/review_checklist_YYYYMMDD.md`)
5. After all items complete, do one final read-through for anything missed
