# Later rounds — checking a revision

A later round asks one question first: **did the authors answer the referee's earlier report
acceptably?** It then asks whether the revision introduced new problems. It is not a fresh review
of the whole paper, unless the revision changed so much that one is needed; then say so to the
user and plan it.

## Inputs

- `paper/round-N/`, read-only: the revised manuscript, the response letter, any marked-up
  version, the editor's letter, other referees' reports if shared, and any new supplementary
  material or code.
- **The baseline:** the referee's own submitted report(s) from earlier rounds. Use
  `report/round-k/` where it exists. Otherwise ask the user for a copy of the report as it was
  submitted, and record its path in the brief. The baseline is never edited.
- Earlier notes, if they exist (`notes/done/…-round-k.md`, `notes/litrev/`): leads only. Check
  everything again against the revised files.

The earlier round need not have been done with this skill. Never ask the user to recreate an
earlier project.

## Procedure

1. **Phases 1–3 for round N.** Inventory and the journal's terms (Phase 1). With a referee hub,
   Phase 2 asks only what is not already settled, and Phase 3 creates only the missing round
   folders, updates the hub's Status for round N, and checks an existing `channels/` against the
   current arrangement; without a hub, both run in full. An exchange still open from an earlier
   round is finished first.
2. **Read the revision in full** (Phase 4), with the response letter beside it. Make
   `notes/manuscript-round-N.txt` from the revised file if an installed converter can, under
   Phase 1's rules on document tools and Python; otherwise work from the original, or ask the user
   for an accessible version. Rebuild `notes/manuscript-map.md` for round N: re-map the proofs
   that changed, and give the revised claims new ledger entries.
3. **Build the request list** in `notes/round-N-check.md`: one row for every item of the baseline
   report (Major, Minor, and Typo), with a stable ID made of the round and the item label (R1-M3,
   R1-m2, R1-t4), plus every request still open from older rounds under its original ID.
4. **Judge each row against the revised manuscript, not the letter.**
   - The response's claim (quoted from the letter), and where the change is said to be.
   - The evidence in the revised file: a quotation, a re-derivation, a recomputed number.
   - A judgment: **addressed**, **partly addressed**, **not addressed**, or **pending** (the
     evidence is not available yet). Missing evidence is pending, not a failure to address.
   - A rebuttal instead of a change is judged on its merits. A correct argument addresses the
     request.
5. **New problems** introduced by the revision go to `notes/review-findings.md` as findings, under
   the usual tracks: typically B for changed proofs, E for new or re-run experiments, and F for
   new claims.
6. **Literature.** Reference numbers may have changed. Update the per-round source map, and redo
   the applicability check wherever the citing argument changed. An unchanged sentence does not
   carry over a verdict if the result's hypotheses or the surrounding argument changed.
7. **Other referees and the editor.** Their reports and the editor's letter are read for context.
   Note where they overlap with this referee's points; do not take their requests on as this
   referee's checklist. Questions the editor puts to this referee go in the deliverables map.
8. **Synthesis** (Phase 7): what remains open, with severity and repair burden; the user decides
   the recommendation.
9. **Deliverables** (Phase 8) in `report/round-N/`, following `report-conventions.md`:
   - a short summary of the revision;
   - the response to each earlier request, by its stable ID, with the judgment and the evidence;
   - new comments, numbered afresh for this round (M1, m1, t1), with the round in their IDs when
     a later round refers back to them;
   - the recommendation where the form puts it.
10. **Revise, validate, submit, archive** (Phases 9–10). The round's notes are archived with
    `-round-N` in the filename. An earlier submitted report is never replaced.

## `notes/round-N-check.md`

```markdown
# Round N check — <journal>, <manuscript ID>

Baseline: <path to the earlier submitted report(s)>. Revised manuscript: <path>. Response
letter: <path>.

| ID | Request (short) | Response's claim | Revised location | Evidence | Judgment | Notes |
|---|---|---|---|---|---|---|
| R1-M1 | | | | | | |
```
