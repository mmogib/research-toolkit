---
name: review-paper
description: Paper review and polish checklist for academic papers before submission.
  Walks through a 14-item universal checklist (notation, proofs, assumptions, abstract,
  introduction, numerics, style, etc.), then adds project-specific items interactively. Distributes
  tasks between Claude and the user, then Claude executes its assigned items, delegating the
  bibliography, numerics, and style items to their own skills. Accepts a checklist-only mode that
  builds the checklist and stops. Use when reviewing, polishing, or doing a final pass on a paper
  before submission.
invocation: user
---

# /review-paper — Paper Review & Polish

Walk through a structured review of an academic paper before submission. Produces a tracked checklist note and systematically works through each item.

## Modes

| Invocation | Runs | Use |
|---|---|---|
| `/review-paper` | Phases 1–5. Builds the checklist **and executes** Claude's items. | Direct use. |
| `/review-paper checklist-only` | Phases 1–3, then returns the checklist. **Stops before task distribution and execution.** | When another skill needs the checklist but owns the ordering of the work itself. |

**Item delegations fire only in Phase 5.** Building a checklist never triggers `/litrev`,
`/numerics-audit`, or `/ai-slop`. A host skill that invokes this one to obtain a checklist and then
sequences the work itself must get a checklist and nothing else — otherwise item 14 kicks off a full
prose sweep at the moment the checklist is created, which is the opposite of what it asked for.

## Item identity

Items have **stable canonical numbers and slugs**, listed in
`<toolkit>/guides/paper-review-checklist.md`. An item that does not apply is marked `N/A` and **keeps its
number**. Never renumber the survivors: dispatch is by slug, and a renumbered list makes "item 12"
mean different things in different papers.

## Workflow

### Phase 1: Context Discovery

Before asking questions, gather project context:

1. Read the project's `CLAUDE.md` to understand: paper topic, structure, LaTeX setup.
   **If it is missing, or contains a `## Paper Key Elements` block, it predates the project hub** —
   say so and suggest `/init-project adopt` before continuing. See `<toolkit>/guides/project-hub.md`.
   If a `notes/manuscript-map.md` exists, read it too; under the hub the paper's detail lives there
   rather than in `CLAUDE.md`.
2. Locate `.tex` files — identify the main file and any `\input`/`\include` structure
3. Scan the paper to note what it contains:
   - Proofs? (`proof-review`, `assumptions-audit` apply)
   - Named assumptions like (A1)–(An)? (`assumptions-audit` applies)
   - Core mathematical derivations? (`core-derivation` applies)
   - A statement that computed quantities were validated? (`computational-verification` applies)
   - Benchmark results — tables of iterations, times, comparisons? (`numerics-audit` applies)
   - Algorithm box / pseudocode? (`algorithm-presentation` applies)
   - Figures and tables? (`captions` applies)
4. Check for existing review notes in `notes/`

### Phase 2: Universal Checklist

Generate `notes/review-checklist.md` with the items from `<toolkit>/guides/paper-review-checklist.md`.
Flat, topical, undated — one checklist per project, updated in place across review cycles. See
`<toolkit>/guides/project-hub.md`.

Format — canonical number, slug, and status, with inapplicable items kept and marked `N/A`:

```markdown
# Review Checklist

| # | Slug | Item | Assigned | Status |
|---|---|---|---|---|
| 1 | `notation-style` | Notation & LaTeX style consistency | Claude | [ ] |
| 2 | `proof-review` | Proof review | Claude flags → User | [ ] |
| 4 | `core-derivation` | Core derivation completeness | — | N/A |
| 13 | `numerics-audit` | Numerical experiments audit | Claude | [ ] |
| 14 | `style-pass` | Style pass (LAST) | Claude | [ ] |
```

Items marked "(if any)" that do not apply based on Phase 1 findings are marked `N/A`. **They keep
their numbers.** Do not renumber.

Add a line to `## Active notes` in the project hub pointing at the checklist.

Present the checklist to the user for confirmation.

### Phase 3: Project-Specific Items

Ask: "Any project-specific review tasks to add?"

Examples of what the user might add:
- "Verify (A1)–(A5) are all cited correctly"
- "Check that Theorem 4.1 proof handles the boundary case"
- "Ensure the Signal Recovery discussion isn't redundant across sections"

Append these as numbered items after the universal ones.

### Phase 4: Task Distribution

Go through each item with the user using AskUserQuestion. For each, propose one of:

| Label | Meaning |
|-------|---------|
| **Claude** | Automatable — Claude does it fully (grep for patterns, diff bib entries, search banned words) |
| **Claude flags → User reviews** | Claude scans and flags potential issues, user makes final judgment |
| **User** | Needs human judgment (proof correctness, mathematical insight) |

Default assignments:

| Item | Default |
|------|---------|
| 1. Notation & LaTeX style | Claude |
| 2. Proof review | Claude flags → User reviews |
| 3. Assumptions audit | Claude flags → User reviews |
| 4. Core derivation completeness | User |
| 5. Computational verification mention | Claude flags → User reviews |
| 6. Abstract polish | Claude flags → User reviews |
| 7. Introduction tightening | Claude flags → User reviews |
| 8. Section transitions | Claude flags → User reviews |
| 9. Redundancy check | Claude flags → User reviews |
| 10. Algorithm/method presentation | Claude flags → User reviews |
| 11. Figure/table captions | Claude |
| 12. Bibliography integrity | Claude (delegates to `/litrev`) |
| 13. Numerical experiments audit | Claude (delegates to `/numerics-audit`) |
| 14. Style pass | Claude (may delegate to `/ai-slop`) |

Present defaults and let user adjust. User may also reassign project-specific items.

**`checklist-only` stops here.** Return the checklist note and do not run Phase 4 or Phase 5.

### Phase 5: Execute

**This is the only phase in which item delegations fire.**

Work through Claude's assigned items in checklist order:

1. **Before each item**: Mark it `in_progress` in the checklist note
2. **During**: Read the relevant `.tex` files, grep for patterns, report findings
3. **After**: Update the checklist note with findings and mark `[x]` with a brief status summary
4. **For "Claude flags" items**: List findings, then pause for user to confirm fixes

For items assigned to the user, skip them and note "Assigned to user" in the status.

After completing all Claude items, print a summary of remaining user tasks.

## Execution Guidelines Per Item

### 1. Notation & LaTeX style
- Grep for `\text{` (should be `\operatorname` or `\mathrm` for operators)
- Grep for `\( ` and `\)` (should use `$...$`)
- Grep for `\rightarrow` (should be `\to`)
- Grep for inconsistent bold/mathbb patterns
- Check theorem environment counters in preamble

### 5. `computational-verification` — Computational verification mention
- Search for "finite difference", "numerical verification", "gradient check" or similar
- If absent, flag the gap
- **This is not the numerics audit.** It asks whether the paper *states* that computed quantities were
  validated. Whether the benchmark results support the claims is item 13.

### 11. Figure/table captions
- List all `\caption{...}` and check self-containedness
- Cross-reference all `\ref{fig:` and `\ref{tab:` with actual labels
- Flag any orphan figures/tables

### 12. `bibliography-integrity` — Bibliography integrity
- Extract all `\cite{...}` keys from `.tex` files
- Compare against `.bib` file entries
- Report: undefined references, orphan bib entries, duplicate authors
- The above is mechanical. **For the semantic layer — is what the paper *says* about each cited work
  actually true? — invoke `/litrev` in `audit-manuscript` mode.** It checks every characterization
  and every benchmark-parameter attribution against the source, and checks the reverse direction for
  uncited lineage. A bibliography where every key resolves can still misdescribe every paper in it.
- Never edit the Zotero-managed `.bib`. New references go to `paper/temp_refs_to_add.bib` as
  unverified leads; `/litrev` owns that flow.

### 13. `numerics-audit` — Numerical experiments audit
- **Invoke `/numerics-audit`.** Declare the mode first — who can run experiments determines where a
  gap goes, and the audit will not start without it.
- Applies to any paper reporting benchmark results. `N/A` otherwise.
- Findings return in three buckets: text fix, needs-a-run, and scope decisions for the user.

### 14. `style-pass` — Style pass
- Grep for each banned word from the checklist
- Grep for weak openings ("It is ", "There are ")
- Grep for wordy phrases from the replacement table
- Report with line numbers and suggested replacements
- **For revision cycles or AI-drafted manuscripts**: invoke `/ai-slop` for the deeper multi-agent sweep that adds reviewer-response framing and revision-tracking language as separate categories with confidence-rated triage. Item 14 catches surface AI tells; `/ai-slop` adds the categories specific to revision cycles.
- Runs **last**, after every other item has settled the text — including any late numerics rewrites
  from item 13.

## Reference Files

- `<toolkit>/guides/paper-review-checklist.md` — Full universal checklist, canonical numbers and slugs
- `<toolkit>/guides/project-hub.md` — Hub shape and notes discipline; the source of the undated checklist filename
- `../litrev/SKILL.md` — Cite-with-confidence audit (item 12's semantic layer)
- `../numerics-audit/SKILL.md` — Adversarial numerics audit (item 13)
- `../ai-slop/SKILL.md` — Multi-agent deep sweep for revision cycles (complements item 14)
- `../join-revision/SKILL.md` — Owns the whole revision phase of a finished manuscript (system setup, collaborator roles, `\rev` markup, adversarial numerics audit) and invokes this skill to build the checklist. If the paper is finished and the job is to take it to submission, start there instead of here.
