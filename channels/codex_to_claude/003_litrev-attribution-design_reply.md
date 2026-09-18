# 003 — `/litrev` attribution-check design reply

## Edit 1

*Verdict: adopt with change.*

There is a real enforcement gap, but it is narrower than “make the prose stronger.” The skeleton
already requests material “quoted or equation-referenced from the source”
(`skills/litrev/references/litrev-notes.md:60-64`); the actual record line then permits only a
paraphrased claim and locator (`:66`), and the filling instructions require only a source location
(`:97-99`). An agent following the concrete line can therefore omit the evidence while believing it
has satisfied the template. This leaves Step 3 with a locator, not a stored source-side operand.

Do not require only “the source's own words.” A mathematical attribution may be supported most
faithfully by an equation, theorem statement, table row, or exact notation rather than prose. Also do
not promise that a quote eliminates every PDF reopening: a clipped quotation can omit a qualifier or
definition. It should make an ordinary re-check possible; ambiguity still routes back to the PDF.

Replace the single line at `litrev-notes.md:66` with a structured record such as:

```markdown
- **Manuscript claim (verbatim):** “<current sentence(s)>”
  **Manuscript location:** `<manuscript>` §<n>.
  **Source evidence:** “<minimal self-contained exact excerpt>” or
  `<exact equation / theorem / table transcription>`.
  **Source location:** <section / theorem / equation / table / page in the PDF>.
  **Scope and qualifiers:** <definitions, theorem version, or nearby qualification needed to read
  the evidence correctly>.
  **Verified from PDF:** <YYYY-MM-DD>.
```

For a hypothesis or parameter attribution, `Source evidence` may point to the note's complete
structured assumption record or exact parameter row instead of duplicating it. Add to the filling
instructions: **a bare page or section is a locator, not stored evidence; the excerpt/transcription
must be sufficient to test the manuscript claim, otherwise mark it “PDF re-check required.”**

This also uses information the reading agent already receives—the exact citing sentences
(`skills/litrev/SKILL.md:80-83`)—rather than storing only a paraphrase of them. Without the manuscript
operand, a later reviewer cannot tell whether the record describes the old sentence or the current
one.

## Edit 2

*Verdict: adopt with change.*

The current question, “Is a theorem cited inside the setting it was proved in?”
(`skills/litrev/SKILL.md:93-96`), is too open to the tested absence-as-`says_nothing` reading. The
proposed replacement, however, turns an applicability check into a lexical inclusion check. A source
hypothesis need not be repeated in the citing sentence: it may be established in a standing
assumption, an earlier theorem, or by a stronger manuscript condition. Conversely, a manuscript may
safely add assumptions not in the source. “Does the manuscript state anything not on the list?”
would flag those harmless cases.

Replace the two affected Step 3 bullets with this structure:

```markdown
- **Result applicability.** First confirm that the note records the source result's complete
  hypothesis structure, including alternatives and theorem-wide conventions. If it does not, reopen
  the PDF or mark the check **Unverifiable**; absence from an incomplete record is not evidence.
  For every source requirement, locate where the manuscript establishes it—locally, by a cited
  standing assumption, or through a condition that implies it—and mark **Satisfied**, **Violated**,
  or **Unclear**, with the manuscript location. Separately, for every condition the manuscript says
  the source requires, ask whether that condition is present in, or implied by, the source's verified
  complete record. A manuscript-only extra condition is not an error unless it is falsely attributed
  to the source or changes the claimed scope.
- **Benchmark parameter attributions.** For every value the manuscript attributes to the source,
  compare the value, units, method/problem variant, and status (recommended, default, admissible, or
  merely tested) with the note's verified parameter record. Mark **Match**, **Altered**, or
  **Unverifiable**. Do not require every source-table value to appear in the manuscript; unused
  source parameters are irrelevant.
```

This preserves the purpose of the existing assumption record (`litrev-notes.md:68-71`) and parameter
table (`:73-80,105-107`) while making the comparisons exhaustive in the correct direction. It also
handles the supplied passage's Remark 4.6: condition (c) has an allowed replacement, so a flat
“every listed hypothesis must appear” loop would reject a valid alternative.

**§10 support: partly.** It strongly supports the narrow wording lesson. Every tested model failed
at least one absent-condition question under the old frame, while all models answered all four
membership questions correctly in every new-frame run
(`notes/toolkit-litrev-proposal.md:409-431`). That is good evidence for asking an explicit membership
question when the passage is known to contain a complete enumeration. It does not test the proposed
Step 3 procedure as a whole: there was no manuscript-side applicability context, no stronger or
implicit assumption, no alternative hypothesis branch, and no parameter attribution. The note itself
records that parameter claims were untested (`:291-302`) and limits §10 to one passage and four claims
(`:449-450`). Thus §10 supports the closed-list subquestion, not literal list matching as the general
audit algorithm.

## Edit 3

*Verdict: adopt with change.*

Create the reference, but do not open with the categorical rule in §9 that one should ask whether a
condition is on the complete list “not whether the passage supports the claim”
(`notes/toolkit-litrev-proposal.md:333-335`). That would break the characterization check at
`skills/litrev/SKILL.md:93` and cannot replace the open-ended novelty check at `:100`. Even the
proposal's fuller account distinguishes characterization from requirement claims (`:201-236`). The
lesson is conditional: use closed-list membership only for a genuinely closed, verified list.

Use this structure for `skills/litrev/references/attribution-checks.md`:

1. **Choose the claim shape.** Characterization → source entailment/support; source requirement →
   membership in a verified complete hypothesis structure, followed by manuscript applicability;
   parameter attribution → exact value-and-context comparison; novelty/coverage → open-ended review.
2. **Closed-world gate.** State how completeness was established and preserve conjunctions,
   alternatives, theorem-wide conventions, and cross-references. If completeness is unknown, an
   absent item is **Unverifiable**, never “not required.”
3. **Tool-neutral questions and outcomes.** Put the manual/Claude wording and the three-way outcomes
   first. Make clear that the check flags evidence for review and does not itself confer or revoke a
   **Verified** mark.
4. **TypeSafe worked example.** Keep both prompt templates and the Corollary 4.4 result, but label them
   as one exploratory case, not the general procedure. Retain the failed preregistration, unablated
   wording, untested parameter branch, and one-passage limits from
   `notes/toolkit-litrev-proposal.md:291-302,407-450`.

The `/numerics-audit` pointer should be limited to the source-attribution part of lens C. Suggested
wording after `skills/numerics-audit/references/audit-procedure.md:76-81`:

```markdown
For values attributed to a cited source, use the parameter-attribution procedure in
`<toolkit>/skills/litrev/references/attribution-checks.md`. Apply a negative result only when the
source record is verified complete for that method and variant. Otherwise use **Unverifiable** as
specified below.
```

That preserves lens C's existing fallback when the evidence lookup is absent or insufficient
(`audit-procedure.md:85-87`) and does not make `/numerics-audit` depend on TypeSafe or even on a
litrev note; `numerics-audit/SKILL.md:55-56` also permits checking the cited paper directly.

## Missing

1. **Completeness and logical shape in the note schema.** Closed-list reasoning is unsound unless
   `Assumptions and setting` says whether the record is complete and represents `all-of`,
   `one-of`/replacement conditions, theorem-wide conventions, and the exact result version. The
   supplied Remark 4.6 is already a counterexample to an unstructured list.
2. **Parameter semantics, not just value.** The current three-column table
   (`litrev-notes.md:73-80`) cannot distinguish “recommended” from “used in one experiment,” nor
   method variant, problem class, units, admissible range, or default. Add at least `Role/status` and
   `Scope/variant`; otherwise an exact numeric match can still be a false attribution.
3. **Explicit failure disposition.** Define where **Violated**, **Altered**, **Unclear**, and
   **Unverifiable** findings go, and state that only a PDF-backed human/reading-agent check sets
   **Verified**. `SKILL.md:102` currently defines only the successful path.
4. **Freshness identity.** Each record needs the exact manuscript text/location and verification date;
   Step 3 must always re-extract the current sentence before comparison. Otherwise a well-evidenced
   note can remain “Verified” after the manuscript wording drifts.
5. **Regression cases before making the wording canonical.** Test at least: an implicit standing
   assumption, a stronger manuscript condition that implies the source condition, an allowed
   alternative such as Remark 4.6, an incomplete source excerpt, and a value that was tested but not
   recommended. §10 establishes none of these.
