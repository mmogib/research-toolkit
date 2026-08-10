# Migration register — legacy `CLAUDE.md` → project hub

Tracks the projects that predate the lean-hub doctrine and must be migrated with
`/init-project adopt`, one at a time. This register outlives the extraction plan
(`research-toolkit/notes/skill-extraction-plan.md`), which closes when implementation finishes.

**Never bulk-adopt.** Each row is adopted individually, when that project is inactive enough to
review the proposed extraction before anything is written.

## Inventory (2026-08-10)

Scanned `D:\Dropbox\Research` for root `CLAUDE.md` files. Twelve carry the legacy
`## Paper Key Elements` marker; four already carry `## Active notes` and need no migration. No file
carries both.

Ordered by risk — no Git plus a large hand-edited root is the worst case, because there is no
rollback other than the snapshot.

| # | Project | Git | Lines | `jcode/` | Status | Adopted |
|---|---|---|---|---|---|---|
| 1 | `SGM_MixedVIEPS` | **none** | 161 | yes | pending | |
| 2 | `WithSlim/MPINP_paper` | **none** | 142 | yes | pending | |
| 3 | `withMujahid/MixedIntegerMOP` | **none** | 125 | yes | pending | |
| 4 | `VOP-LineSearch` | **none** | 123 | yes | pending | |
| 5 | `CompositeOptimization` | **none** | 99 | yes | pending | |
| 6 | `ConeFunctions` | **none** | 98 | yes | pending | |
| 7 | `Projects/IRC_MOIN/WithFerreira` | **none** | 97 | yes | pending | |
| 8 | `Projects/IRC_MOIN/RVOP` | **none** | 95 | yes | pending | |
| 9 | `VariableMetricQuasiVI` | git | 290 | yes | pending | |
| 10 | `Projects/IRC_MOIN/PCM_ON_VIP_P1` | git | 241 | yes | pending | |
| 11 | `SetOptimizationProblems_ProximalGradient` | git | 192 | yes | pending | |
| 12 | `IntevaleValuedVOP-LineSearch` | git | 77 | yes | pending | |

Already hub-shaped, no action: `StateDependentMetricProjectionNeuralNetwork`,
`VOPApproximationWithApplication`, `Projects/IRC_MOIN/HalpernWithPastExtrapolationForVI`,
`Projects/IRC_MOIN/NewAlgorithm_EPCMMIP`.

Every one of the twelve has a `jcode/`, so every adoption runs against a project with real code.
`adopt` must never scaffold into it.

## Forward tests before any real adoption

Run on **copies**, not the originals:

1. **`VariableMetricQuasiVI`** — 290 lines, the most divergent root. Has Git, so a bad result is
   recoverable. Tests the extraction logic against the messiest input.
2. **`SGM_MixedVIEPS`** — 161 lines and **no Git**. Tests the case where the snapshot is the only
   rollback that exists.

**Status: both forward tests passed, including the second-run no-op. The register is open.**
Adoptions proceed one at a time, each against the per-adoption procedure below. Passing the forward
tests is not a licence to batch — the twelve roots differ from each other more than any of them
differs from the test copy.

## Per-adoption procedure

Before:

1. Full project snapshot outside the working folder.
2. `Get-FileHash` on `CLAUDE.md`, and on any pre-existing note that may be merged
   (`notes/manuscript-map.md` especially).
3. Recursive hash manifest of everything under `jcode/`.
4. Inventory every heading and every linked path in the old root.

During: `adopt` proposes the extraction and the root diff. Nothing is written until it is approved.
The transaction aborts before writing if the backup cannot be read back byte-for-byte.

After — all four must hold:

- Backup hash equals the pre-adopt root hash.
- The recursive `jcode/` hash comparison is empty.
- Every old heading or content block appears either in the new hub or in a named note.
- Any change to a pre-existing manuscript map matches its separately approved diff.

A syntactically valid hub is not evidence of success.

Record in the row above: date adopted, backup path, before/after hashes, files created, files
modified. Start a fresh Claude session afterwards — do not resume a pre-adopt session for that
project.

```powershell
$project = 'D:\Dropbox\Research\<project>'
Get-FileHash -LiteralPath "$project\CLAUDE.md"
rg -n '^#{1,6} ' "$project\CLAUDE.md"
Get-ChildItem -LiteralPath "$project\jcode" -Recurse -File | Sort-Object FullName | Get-FileHash
```

## Rolling back one adoption

1. Stop work; preserve the failed post-adopt state. Do not bulk-delete generated notes.
2. Find the receipt and the `notes/done/CLAUDE_pre_hub*.md` whose hash matches the recorded pre-adopt
   hash. Save the current hub aside, then restore that backup to `CLAUDE.md`.
3. Restore every pre-existing note modified during adoption from its own snapshot.
4. Compare `jcode/` against the pre-adopt manifest. Any difference violates the contract — restore
   from the snapshot, not by guessing individual reversions.
5. Fresh session; re-run the marker checks.

Not automatically reversible: an approved edit to an existing note without its own snapshot, an
accidental `jcode/` change in a non-Git project without a full snapshot, and anything already sent to
a collaborator. Dropbox version history is not a rollback plan — its retention per path is unverified.

## Re-checking the inventory

```powershell
rg -l '^## Paper Key Elements$' 'D:\Dropbox\Research' -g CLAUDE.md
rg -l '^## Active notes$' 'D:\Dropbox\Research' -g CLAUDE.md
```

The legacy list should shrink only by reviewed adoptions. A project is not migrated because the
toolkit deployed successfully.
