---
name: ai-slop
description: Multi-agent AI-slop and revision-language sweep for academic manuscripts. Chunks the paper, dispatches parallel agents to flag reviewer-response framing, revision-tracking language, AI-slop tells, and padding (with confidence ratings), consolidates into Tier 1 / Tier 2 fixes, and applies them in batches. Use before submission or resubmission, especially after AI-assisted revision cycles.
invocation: user
---

# /ai-slop — Multi-Agent AI-Slop & Revision-Language Sweep

A deeper pass than `/review-paper` item 14. Used for revision cycles or AI-drafted manuscripts where reviewer-response framing and revision-tracking language need to be scrubbed in addition to the standard banned-words list. Agents flag and report; the user (with Claude's help) triages and applies.

## When to Use

- Manuscript is approaching submission or resubmission.
- A revision cycle has added new content (often in response to reviewer comments) and you want to confirm the new prose doesn't read as reviewer-response.
- The draft used AI assistance and you want a defensible "we cleaned the prose" pass before shipping.
- `/review-paper` item 14 found surface slop, but you want the deeper multi-agent treatment with reviewer-response and revision-tracking categories.

Don't use for: line-by-line copy-editing of grammar/typos, or technical-correctness review (different tasks).

## Workflow Overview

```
Phase 1. Context discovery       ← read CLAUDE.md, locate main file
Phase 2. Define chunks            ← split manuscript by section
Phase 3. Launch parallel agents   ← one per chunk, read-only, write reports
Phase 4. Consolidate findings     ← read reports, identify cross-chunk patterns
Phase 5. Triage into tiers        ← Tier 1 + recurring, Tier 2 grouped
Phase 6. Apply Tier 1 batch       ← unambiguous fixes, no further discussion
Phase 7. Apply Tier 2 group-by-group ← user approves each thematic group
Phase 8. Final verification grep  ← confirm zero hits in body text
```

**Key rule:** Agents do NOT edit the manuscript. They only write reports. The author decides which fixes to apply.

## Phase 1 — Context Discovery

1. Read the project's `CLAUDE.md` to find the manuscript file path, paper topic, structure, and any revision context (revision cycle? AI-drafted?). **If it is missing or contains a `## Paper Key Elements` block, it predates the project hub** — say so and suggest `/init-project adopt` before continuing (`../../guides/project-hub.md`). Under the hub, the paper's detail lives in `notes/manuscript-map.md`; read that too when it exists.
2. Locate the main `.tex` file and any `\input` / `\include` structure.
3. If the project uses a revision-tracking macro (`\rev{...}` for blue-coloring revisions — the convention and its integrity checks are in `../../guides/latex-conventions.md`), note it. Patterns inside such wraps are typically the highest-density slop targets.
4. Check `notes/` for a prior `ai-slop*` report — if a sweep already ran, focus on newly added content rather than re-flagging.

## Phase 2 — Define Chunks

Split the manuscript by major sections. Three chunks is the sweet spot — fewer means agents run out of attention; more means consolidation gets messy.

| Paper type | Suggested chunks |
|---|---|
| Math/CS with proofs | A: Intro + Background, B: Method/Theory (math-heavy), C: Experiments + Discussion + Conclusion |
| Empirical / ML | A: Intro + Related Work + Setup, B: Method + Experimental Design, C: Results + Analysis + Conclusion |
| Survey | One agent per major thematic section, capped at 4 |
| Thesis | One per chapter, or group thematic chapters |

For each chunk, record: line range (or chapter ID), descriptive section list (used in the agent prompt).

## Phase 3 — Launch Parallel Agents

Use the agent prompt template at `references/agent-prompt-template.md`. For each chunk:

1. Replace every `<PLACEHOLDER>` with the project-specific value (range, file path, section list, output report path).
2. Add the relevant section-specific note (math-heavy / results-heavy / fixed-in-prior-pass) — see template.
3. Save report to `notes/ai-slop-<chunk>.md` (e.g., `notes/ai-slop-intro.md`).

Launch all chunk agents in parallel (single message, multiple Agent tool calls). They run concurrently and each writes its own report. Use `subagent_type: general-purpose` unless the project has a more specific agent type.

The agent prompt enforces:
- Read-only (no edits).
- Four categories with confidence ratings (skip "low").
- Markdown table output grouped by category.
- Skip rules for citations, equation labels, math mode, LaTeX commands, etc.

## Phase 4 — Consolidate Findings

Read each report. Look for patterns **across reports**:

- A word/phrase used in multiple sections is a "recurring pattern" (highest leverage — fix once, propagate).
- Reports often agree on the worst offenders → those go in Tier 1.
- Reports with concentrated flags in one subsection signal a draft hot-spot (often the most recently rewritten section).

Build a consolidated view organized by **theme**, not by chunk.

## Phase 5 — Triage into Priority Tiers

| Tier | Definition | Examples |
|---|---|---|
| **Recurring patterns** | Same phrase used 2+ times across the manuscript | "robust" non-technically, repeated closing phrases, duplicated transition flourishes |
| **Tier 1** | High-confidence, unambiguous AI tell or reviewer-talk in a single location | "Notably," opener; "A particularly notable finding is that"; "underscores"; "leverage" (verb); "fundamentally changes the landscape"; "to address concerns about" |
| **Tier 2** | Medium-confidence stylistic fixes | Empty intensifiers ("generally", "very"), wordy constructions, soft openers ("Notice that..."), pre-section transition phrases, count mismatches (says "Three" then has four items) |

**Out of scope / skip:**
- LaTeX `%` comments (invisible to readers).
- Conventional math-prose ("It follows that", "Hence", "Suppose") in proofs.
- Standard back-matter declarations (formulaic).
- Citations, labels, table cell values, model/author names.
- Established technical terms (e.g., "robust optimization" is a term of art).

For the canonical banned-words list and wordy-phrase replacement table, see `../../guides/paper-review-checklist.md` item 14. The skill extends that list with the two revision-cycle categories (reviewer-response framing and revision-tracking language).

## Phase 6 — Apply Tier 1 + Recurring (Batch)

Apply all Tier 1 fixes and recurring-pattern fixes in one pass without further discussion (this tier is pre-approved). Use parallel `Edit` calls where changes are on different paragraphs.

Watch for:
- **Cross-references** — verify any new `\ref{...}` resolves to an existing label.
- **Revision-tracking macro wraps** (e.g., `\rev{...}`) — surgical edits inside such a wrap keep the wrap; replacements that delete the wrapped text need new wrapping.
- **Math-mode boundaries** — don't accidentally edit text inside `$...$` or display environments.
- **Recurring patterns** — when varying a repeated word/phrase, vary the closest pair first (large gaps tolerate repetition).

## Phase 7 — Apply Tier 2 Group-by-Group

Present Tier 2 in **thematic groups** (e.g., "wordy/intensifiers" group, "transition phrases" group, "soft openers" group). For each group:

1. List all proposed changes (current → proposed) in a table.
2. Ask the user to approve, veto, or modify each.
3. Apply the approved subset in parallel.

Tier 2 is where author voice lives, so author approval matters more here than in Tier 1.

## Phase 8 — Final Verification Grep

Run a single `Grep` across the manuscript for the canonical reviewer-talk and AI-slop patterns. The grep should return zero hits in body text (LaTeX comments and macro definitions in the preamble are OK).

Baseline pattern (extend with project-specific tokens — see "Adapting the verification grep" below):

```
[Tt]o address (concerns|the (concern|practical))|[Aa]s (suggested|recommended) by|[Ff]ollowing the reviewer|[Nn]ewly added|[Nn]ewly introduced|the revised manuscript|in this revision|now includes|[Nn]otably,|particularly notable|underscores that|delve into|leverage(d|s)? (the|our|a|to)|valuable insights|play a (crucial|vital|key) role|shed light on|in the realm of|navigate (the|a)|comprehensive review
```

If hits remain, decide each: false positive (technical context, leave) or residual fix.

## Notes Convention

- During execution: reports go to `notes/ai-slop-<chunk>.md`.
- After all fixes are applied and the user is satisfied: consolidate the chunk reports into a single `notes/ai-slop.md` and move it to `notes/done/` (manual step — the skill does not auto-archive). A later sweep reopens and updates that topic note rather than creating a dated hierarchy.
- Flat, topical, undated — see `../../guides/project-hub.md`. Dated directories give one folder per session and none per topic, so the current state has to be reconstructed by reading every folder in order.

## Common Pitfalls

1. **Over-flagging in math-heavy sections.** Use the math-heavy section-specific note in the agent prompt.
2. **Technical-term collisions.** "Robust" in robust optimization is a term of art; "comprehensive examination" is sometimes literal. Only flag in non-technical contexts.
3. **Confidence calibration drift.** Agents over-flag at first. Require high/medium ratings and skip low automatically.
4. **Cross-reference breakage.** When dropping a sentence, check that you don't break a `\ref{...}` or remove a label used elsewhere.
5. **Recurring-pattern blindness.** Single agents can't see across chunks — the user must look at all reports together.
6. **Counting mismatches.** Lists that say "Three Xs" and then have four items are a common AI tell.
7. **Over-aggressive stripping.** Some hedging is legitimate. Preserve author voice; don't strip everything.
8. **Agent context limits.** Don't give a single agent more than ~700 lines.

## Adapting the Verification Grep

The baseline grep covers a generic taxonomy. Extend the right-hand side of each alternation with patterns specific to the manuscript's domain:

- ML/AI papers: tokens that paired with non-technical "robust" in the draft (e.g., "robust to noise", "robust to perturbations").
- Optimization papers: tokens that paired with "comprehensive" or "extensive" (e.g., "comprehensive analysis").
- Survey papers: tokens that paired with "various" or "myriad" (e.g., "various approaches", "myriad of methods").
- Empirical papers: tokens that paired with "leverage" (verb), "delve into", "shed light on".

Run the grep, eyeball the hits, decide each.

## Reference Files

- `references/agent-prompt-template.md` — parameterized prompt for the chunk agents (Phase 3).
- `../../guides/paper-review-checklist.md` — canonical banned-words list, wordy-phrase table, structural patterns (item 14). This skill extends item 14 with the revision-cycle categories.
- `../../skills/review-paper/SKILL.md` — single-pass review skill. `/review-paper` references this skill as the deeper option for revision cycles.
- `../../skills/join-revision/SKILL.md` — full revision-phase workflow; invokes this skill as its last step, after all other text has stabilized. Projects set up by it use the `\rev{...}` macro noted in Phase 1.
