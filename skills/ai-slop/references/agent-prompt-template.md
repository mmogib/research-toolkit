# Agent Prompt Template — `/ai-slop`

Copy this template when launching a sub-agent for one chunk of the manuscript. Replace every `<PLACEHOLDER>` with the project-specific value. The prompt is self-contained — the agent has no access to the conversation history, so all context must come from the prompt itself.

## Template

```text
**Mission:** AI-slop / revision-language sweep on <SECTION RANGE> of an academic manuscript. Read-only — write a report, do NOT edit any file.

**Context:** Manuscript "<TITLE>" is at stage <STAGE — e.g., "first submission", "major revision", "second-round revision"> at <VENUE>. <REVISION INFO IF APPLICABLE — e.g., "Revisions are wrapped in a revision-tracking macro marking content added/changed in this cycle.">. Some text was drafted with AI assistance. We're doing a final pass before <SUBMISSION/RESUBMISSION> to scrub reviewer-response framing, AI-slop tells, and padding.

**File:** `<PATH TO MANUSCRIPT FILE>`

**Range:** Lines **<START> through <END>** (<DESCRIPTIVE SECTION LIST — e.g., "§3 Proposed Method including subsections on theory, algorithm, and complexity">).

**CRITICAL RULE: Do NOT edit the manuscript or any other file in the manuscript directory. Your only output is a single markdown report at the path below.** The user reviews your report and decides which fixes to apply.

**Flag these four categories. Rank confidence high/medium for each instance. Skip "low" confidence.**

**Category 1 — Reviewer-response framing** (reads as addressing a reviewer, not a reader):
- "to address concerns/comments", "as suggested by", "as recommended", "in response to", "following the reviewer", "we have added/included/revised", "newly added", "newly introduced"

**Category 2 — Revision-tracking language** (betrays a revision rather than a finished paper):
- "the revised manuscript", "in this revision", "now includes", "this paper now", "refreshed", "updated to" (re: our own changes), "has been added", "the new X" (re: our additions, not the literature's)

**Category 3 — AI-slop tells:**
- Sentence starters when overused: "It is worth noting", "It should be noted", "Notably,", "Furthermore,", "Moreover," (when signaling continuation rather than logical contrast)
- Word choices: "delve into", "deep dive", "valuable insights", "play a crucial/vital/key role", "various", "myriad", "leverage" (verb), "robust" (non-technical), "comprehensive" / "extensive" (when un-quantified), "multifaceted", "underscore", "encompass", "in the realm of", "navigate" (figurative), "shed light on"
- Constructions: "not only X, but also Y" (when X and Y aren't a tight pair), "X is essential for Y" (vague), "X plays a vital role in Y"

**Category 4 — Padding / empty intensifiers / wordy phrasing:**
- "In order to" → "to"
- "It is important to note that" → drop or rephrase
- "very/quite/rather" when meaningless
- "the fact that" → drop where possible
- "due to the fact that" → "because"
- "in the process of" → drop
- "a number of" → specific count or "several"
- "with regards to" / "with respect to" (when loose)
- "in terms of" (when loose)

**Skip / do not flag:**
- Citations (`\cite{...}`)
- Equation/table/figure labels (`\label{...}`, `\ref{...}`, `\eqref{...}`, `\Cref{...}`)
- Numbers in tables/equations
- Mathematical expressions in math mode
- Section/subsection titles
- LaTeX commands and macros
- Author names and venue names
- Standard back-matter declarations — formulaic, shouldn't be flagged unless egregious

<INSERT SECTION-SPECIFIC NOTES — pick the relevant ones below>

[For math-heavy sections:]
**Special note:** This section is heavily mathematical. Be conservative in math-proof contexts — phrases like "It follows that", "Note that", "Suppose", "We may write", "Hence", "Therefore" are conventional mathematical writing, NOT slop. Only flag prose-level slop, not proof-flow connectives.

[For results-heavy sections:]
**Special note:** This section heavily reports numerical/empirical results. "is observed", "yields", "indicates", "confirms", "demonstrates" — these are conventional results-section verbs, NOT slop unless used as vague filler. Be conservative; only flag genuine padding or AI tells, not conventional results-section reporting.

[If certain patterns have already been fixed in a prior pass:]
**Special note:** The following patterns were already fixed in a prior pass and should NOT be re-flagged: <LIST OF FIXED PHRASES>. Check the rest of those paragraphs for OTHER slop.

**Confidence calibration:**
- **High:** Pattern is unmistakable AI-slop / reviewer-talk in this context. Almost certainly should be fixed.
- **Medium:** Pattern is suspicious but might be defensible in context. Worth review.
- **Low:** Skip — do not include in report.

**Output format:** Markdown report at `<PATH TO REPORT FILE>`.

Structure:

```markdown
# AI-Slop Sweep — <SECTION DESCRIPTION>

**Range:** <FILE> lines <START>–<END>
**Generated:** <YYYY-MM-DD>
**Total flags:** N (high: X, medium: Y)

## Category 1 — Reviewer-response framing

| Line | Context (5–10 words) | Flag | Suggested rewrite | Confidence |
|------|---------------------|------|--------------------|------------|

## Category 2 — Revision-tracking language
(table; same columns)

## Category 3 — AI-slop tells
(table; same columns)

## Category 4 — Padding / empty intensifiers
(table; same columns)

## Meta-observations
- Recurring patterns worth a unified rewrite, etc.
- Subsections where slop is concentrated.
- Phrases that recur within this chunk (cross-chunk recurrence is the user's job to spot).
```

**Length:** Quality over quantity. <30–80 depending on chunk size> flags is plenty; if the text is genuinely clean, 5 flags is fine. Don't pad the report.

Use the `Write` tool to save the report. Read the manuscript with the `Read` tool. Do not run shell commands or edit any file.
```

## Adapting per chunk

**Chunk-A (Introduction + Background / Related Work):** prose-heavy, conventions follow normal academic writing. No section-specific note needed.

**Chunk-B (Method / Theory / math-heavy):** add the math-heavy special note so the agent doesn't flag conventional proof connectives.

**Chunk-C (Results / Experiments / Conclusion):** add the results-heavy special note. If the user has already manually fixed certain patterns in this chunk, list them in the "fixed-in-prior-pass" special note so the agent doesn't re-flag.
