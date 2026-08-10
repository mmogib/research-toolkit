# 002 — Deployment and migration risk reply

## Observed baseline (2026-08-10)

- The development and deployed clones are both on
  `6b620fb382a1ab03b68a2d03ac3a21f7ba2f3e96`; both `origin/main` refs match it, the deployed clone is
  clean, and `git fsck --full` reports no errors in either clone.
- All ten installed skill entries resolve to
  `C:\Users\mmogi\.claude\skills\research-toolkit\skills\<name>`. Seven are relative directory
  symlinks and three are absolute junctions. None points into the Dropbox development clone. The
  three proposed entries do not yet exist.
- Claude Code is 2.1.226. Current documentation says directory-symlink skills require 2.1.203 or
  later and are watched live, but it also says an invoked `SKILL.md` remains in the conversation and
  is not reread on later turns. See the [Claude Code skills documentation](https://code.claude.com/docs/en/slash-commands).
- A read-only inventory under `D:\Dropbox\Research` found 12 root `CLAUDE.md` files with the old
  `## Paper Key Elements` marker. All 12 projects have a `jcode\`; eight have no `.git`; their root
  files range from 77 to 290 lines (median 125). Three other roots already have an `## Active notes`
  hub marker.
- The development worktree currently has untracked `channels\`, `notes\skill-extraction-plan.md`,
  and `session_ids.txt`. Nothing is staged. A recursive conflicted-copy-name scan found none.

Likelihood and damage below are qualitative: High, Medium, or Low; Catastrophic is reserved for
plausible research-data/code loss.

## TOP RISKS

### 1. `adopt` silently loses or misclassifies hand-edited project instructions

- **Likelihood:** High once migration begins. The machine already has 12 eligible legacy roots, with
  substantial variation; eight have no Git rollback.
- **Damage:** Catastrophic in the worst case. A plausible failure is a valid-looking new hub that
  omits bespoke constraints, overwrites an approved existing `notes\manuscript-map.md`, or touches a
  real `jcode\`. The planned `CLAUDE_pre_hub.md` protects the old root, but not an existing note that
  is later merged, nor any accidental code edit.
- **Mitigation:** Never bulk-adopt. First forward-test on a byte-for-byte copy of one of the messiest
  live projects (prefer the 290-line nonstandard case) and one non-Git project. For every real
  adoption: make a full project snapshot outside the working folder; inventory all headings and
  linked paths; hash `CLAUDE.md`, any pre-existing note that may be merged, and every file below
  `jcode\`; require the proposed extraction and root diff to be approved; then write. Record the
  backup chosen, before/after hashes, files created, and files modified in an adoption receipt. The
  transaction must abort before writing if the backup cannot be read back byte-for-byte.
- **Detection:** After adoption, the backup hash must equal the pre-adopt root hash; a recursive
  `jcode\` hash comparison must be empty; every old heading/content block must appear either in the
  new hub or a named note; and any existing manuscript-map change must match its separately approved
  diff. A syntactically valid hub is not success evidence.

Useful read-only inventory:

```powershell
$project = 'D:\Dropbox\Research\<project>'
Get-FileHash -LiteralPath "$project\CLAUDE.md"
rg -n '^#{1,6} ' "$project\CLAUDE.md"
Get-ChildItem -LiteralPath "$project\jcode" -Recurse -File |
  Sort-Object FullName | Get-FileHash
```

### 2. An active Claude session becomes a mixed-version runtime

- **Likelihood:** High if deployment occurs while mid-flight projects remain open.
- **Damage:** High. An already-invoked old host skill can stay in conversation while a newly invoked
  provider comes from the new checkout. Editing a project's `CLAUDE.md` with `adopt` in the same
  session may likewise leave the session acting on old instructions (**CLAUDE.md reload behavior is
  UNVERIFIED**). This is harder to recognize than a missing command.
- **Mitigation:** Treat deployment as a maintenance window: finish or pause running workflows, close
  every Claude Code session, update and verify the deployed clone and links, then start fresh
  sessions. Also start a fresh session after each real `adopt`; do not resume a pre-adopt session for
  that project.
- **Detection:** Any session created before the deployed SHA changed is suspect. There is no current
  per-response toolkit-SHA signal, so session age is the practical signal. If behavior conflicts with
  the deployed files, reproduce in a fresh session before diagnosing the skill text.

### 3. The runtime clone is stale or locally edited

- **Likelihood:** High over time. `README.md:55` currently permits editing “the `~/.claude` copy
  itself,” while deployment is a manual pull.
- **Damage:** High. A forgotten pull silently leaves old behavior; a dirty deployed worktree can
  block the pull or produce a partially resolved hybrid. A user may create the new junctions anyway.
- **Mitigation:** Make the deployed clone read-only by policy: edit only
  `D:\Dropbox\Research\research-toolkit`. Deploy an exact pushed SHA, use `git pull --ff-only`, and
  stop on any dirty status, divergence, or pull error. Do not create links until every target
  `SKILL.md` exists in that exact checkout. Correct `CLAUDE.md:21` as part of the documented rollout:
  its check names nonexistent `~/.claude/skills/mohammed-research-skills/` and cannot verify this
  deployment.
- **Detection:** Compare the two full SHAs, not branch names or timestamps, and require an empty
  deployed porcelain status:

```powershell
$dev    = 'D:\Dropbox\Research\research-toolkit'
$deploy = "$env:USERPROFILE\.claude\skills\research-toolkit"
git -C $dev rev-parse HEAD
git -C $dev rev-parse origin/main
git -C $deploy rev-parse HEAD
git -C $deploy rev-parse origin/main
git -C $deploy status --porcelain=v1
```

**Correction to the split-brain premise:** with the inspected topology, clone divergence by itself
cannot combine a new skill with an old guide: all installed entries and their shared files come from
the deployed clone. It causes coherent but silent staleness. A true file-level hybrid requires a
dirty/interrupted deployed checkout, links aimed at different roots, copied “symlinks,” or the active
session cache in Risk 2.

### 4. Dropbox and Git race on the development worktree

- **Likelihood:** Medium; higher if a second machine edits or runs Git against the same
  Dropbox-synchronized `.git` directory.
- **Damage:** High. Dropbox may create conflicted copies of Git refs, the index, or working files;
  the result can be lost commits, misleading status, or repository repair work. Dropbox documents
  that simultaneous/offline edits create conflicted copies; it does not provide Git-object
  transaction semantics. See [Dropbox conflicted copies](https://help.dropbox.com/organize/conflicted-copy).
- **Mitigation:** Only one machine may mutate this Dropbox worktree at a time. Prefer an independent
  ordinary Git clone per machine and use the remote—not Dropbox's synchronized `.git`—as the Git
  transport. Before the seven-commit sequence, wait for Dropbox to report fully synced and ensure
  the other machine is idle. Whether the displayed Windows sync icon is a sufficient durability
  barrier is **UNVERIFIED**.
- **Detection:** Before and after the sequence, scan for conflict names, run `git status`, inspect
  recent refs/reflog, and run `git fsck --full`:

```powershell
Get-ChildItem -LiteralPath 'D:\Dropbox\Research\research-toolkit' -Recurse -Force -File |
  Where-Object Name -Match '(?i)conflicted copy|selective sync conflict'
git -C 'D:\Dropbox\Research\research-toolkit' status --short --branch
git -C 'D:\Dropbox\Research\research-toolkit' fsck --full
```

The installed links are outside Dropbox and target the non-Dropbox deployed clone, so Dropbox does
not need to sync them. Do not move those links into Dropbox: Dropbox says Windows junctions and
symlinks are not supported/synced. See [Dropbox symlink and junction behavior](https://help.dropbox.com/sync/symlinks).

### 5. Deploying after every commit exposes a bad commit-5 runtime

- **Likelihood:** Medium only if deployment departs from v3's “once at the end” rule.
- **Damage:** High for an in-progress `/join-revision`. Commits 1–4 are provider-safe. At commit 5,
  `/review-paper` gains `checklist-only` and its new direct-run delegations, but the installed old
  `/join-revision` still calls plain `/review-paper` (`skills/join-revision/SKILL.md:178`). Therefore
  Phase 7 can run the full review workflow and new delegations instead of returning after checklist
  construction. Commit 6 fixes the invocation, but commit 5 is not operationally safe for that host.
- **Mitigation:** Deploy only after commit 7. If every commit must be deployed, move the one-line
  `/join-revision` change to `/review-paper checklist-only` into commit 5; keep the rest of the host
  rewrite in commit 6. Do not run `/join-revision` while either checkout is changing.
- **Detection:** At a commit-5 checkpoint, inspect the installed host invocation; plain
  `/review-paper` is the failure signal. A throwaway `/join-revision` forward-test must stop after
  checklist creation.

The `spec-note.md` copy/delete sequence is sound across complete clean commits: commits 4 and 5 keep
the legacy path used by the old host; commit 6 changes the host and deletes the legacy copy together.
Different clones may safely be on either side. It becomes unsafe only during an interrupted/dirty
checkout or an active-session mix; avoid both as above.

### 6. `git add .` publishes unrelated local material

- **Likelihood:** High if the current README command is followed literally.
- **Damage:** Medium. Today it would stage the channel correspondence, plan, and `session_ids.txt` in
  addition to implementation. A session ID/resume command is operational metadata and should not be
  published accidentally.
- **Mitigation:** Decide the intended tracked manifest before commit 1; ignore or exclude
  `session_ids.txt`; stage named paths per commit. Replace the README's blanket `git add .` example.
- **Detection:** Require review of both untracked and staged names before every commit:

```powershell
git status --short --untracked-files=all
git diff --cached --name-status
git ls-files session_ids.txt
```

### 7. Legacy projects never adopt and quietly follow two doctrines

- **Likelihood:** High. Adoption is opt-in and existing projects can continue indefinitely.
- **Damage:** Medium, cumulative rather than immediate. Old projects do not gain the hub, active-note
  routing, or extracted-skill entry points; usually nothing crashes. They drift from new-project
  behavior and may keep writing duplicate or dated status material.
- **Mitigation:** Maintain an explicit migration register and adopt one project at a time when it is
  inactive enough to review. Do not auto-adopt on opening a project. V3's preflight on every listed
  entry-point skill is the right safety trigger, but it is not migration coverage: a project that
  runs no such skill, or only unrelated skills, will never see it.
- **Detection:** Re-run the marker inventory after each migration wave; the old list should shrink
  only by reviewed adoptions:

```powershell
rg -l '^## Paper Key Elements$' 'D:\Dropbox\Research' -g CLAUDE.md
rg -l '^## Active notes$' 'D:\Dropbox\Research' -g CLAUDE.md
```

### 8. Junction creation succeeds but discovery or shared references do not

- **Likelihood:** Medium-Low with the prescribed checks; Medium if commands are copied from the wrong
  working directory.
- **Damage:** Medium. `mklink /J` can report success for a dangling target; the new command then
  simply does not appear. Relative and absolute existing links also behave differently if the
  skills directory is moved.
- **Mitigation:** Use absolute source and target paths, test the target first, fail on any existing
  destination name, then read `SKILL.md` through the junction. On this machine Claude Code 2.1.226
  meets the documented symlink-support floor. Run one end-to-end reference test through both a
  relative symlink and a junction before rollout.
- **Detection:** `Test-Path` plus `Get-Item` catches dangling/wrong targets; command discovery and a
  reference-read smoke test catch the runtime layer.

Literal filesystem evaluation of
`C:\Users\mmogi\.claude\skills\review-paper\..\..\guides` and the equivalent junction paths is
false—the lexical result is `C:\Users\mmogi\.claude\guides`. Claude Code documents following a
skill-directory symlink to its target, but does not explicitly document how model-issued
`../../guides/...` reads are based after that resolution. Whether every current cross-repository
reference is therefore canonicalized correctly is **UNVERIFIED**. Do not infer success from
`SKILL.md` readability; ask a fresh installed session to resolve and read one actual shared guide.

## SILENT FAILURES

| Silent condition | Observable signal if deliberately checked |
|---|---|
| Push succeeds, deployed pull is forgotten | Development and deployed `HEAD` differ; old commands still behave normally |
| Dangling junction reports successful creation | `Test-Path <entry>\SKILL.md` is false; command absent from discovery |
| Active session retains an invoked pre-deploy skill | Fresh session behaves differently from the old session |
| Old project never invokes an entry-point preflight | Old marker remains; no adopt prompt and no error |
| Adopt omits bespoke content | Backup differs semantically from the union of hub plus extracted notes, but all Markdown is valid |
| Adopt accidentally changes `jcode\` | Recursive before/after hashes differ |
| Shared `../../guides` path is based lexically at the exposed entry | Skill loads, but later reference reads fail or are guessed unless explicitly tested |
| Deployed clone is behind but internally coherent | No Git or Claude error; only the SHA and behavior reveal staleness |

A failed `git pull`, an existing junction name, and a merge conflict are noisy failures. The procedure
must stop on them; they become dangerous only when ignored.

## PRE-FLIGHT CHECKS

1. **Freeze the intended file manifest.** Do not use `git add .`. Resolve whether `channels\`, the
   plan, and especially `session_ids.txt` are publishable; confirm an empty index before commit 1.
2. **Capture the known-good SHA** (`6b620fb...` today) and tag or record it outside the working tree.
   Verify both clones are clean, at that SHA, and pass `git fsck --full`.
3. **Enforce one-writer Dropbox use.** Confirm Dropbox appears fully synced (**UNVERIFIED** as a
   durability guarantee), close the repo on other machines, and scan for conflict files.
4. **Lock deployment policy.** No edits in the deployed clone; no deployment before commit 7; all
   active Claude sessions closed before the final pull. If per-commit deployment is required, repair
   the commit-5 `/review-paper checklist-only` boundary first.
5. **Validate the installed runtime.** Confirm Claude Code is at least 2.1.203; this machine is
   2.1.226. Through an existing relative symlink and an existing junction, have a fresh disposable
   session read the linked skill plus one `../../guides/...` file and report the resolved paths.
6. **Reserve the three names.** `litrev`, `channels`, and `numerics-audit` must be absent at
   `C:\Users\mmogi\.claude\skills\`; never replace an unexpected file/directory/link automatically.
7. **Create a migration register.** Record the 12 detected legacy roots, Git/no-Git status, snapshot
   location, `CLAUDE.md` hash, `jcode\` hash manifest, and planned owner/date. Forward-test `adopt` on
   copies of at least one large hand-edited non-Git project and one project with an existing
   manuscript map.
8. **Pass implementation gates before pushing:** repository-wide reference/filename sweep, all three
   written skill scenarios, `/review-paper checklist-only` stopping behavior, `spec-note.md` path at
   commits 4–6, and the live-copy adopt test from v3.

## POST-DEPLOY VERIFICATION

Run this only after commit 7 is pushed and all Claude sessions are closed:

```powershell
$dev    = 'D:\Dropbox\Research\research-toolkit'
$deploy = "$env:USERPROFILE\.claude\skills\research-toolkit"
$skills = "$env:USERPROFILE\.claude\skills"
$new    = 'litrev','channels','numerics-audit'

git -C $deploy status --porcelain=v1
git -C $deploy pull --ff-only
$expected = git -C $dev rev-parse HEAD
$actual   = git -C $deploy rev-parse HEAD
if ($expected -ne $actual) { throw "Deployment SHA mismatch: $expected != $actual" }
if (git -C $deploy status --porcelain=v1) { throw 'Deployed clone is dirty' }

foreach ($name in $new) {
  $target = Join-Path $deploy "skills\$name\SKILL.md"
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "Missing provider before junction creation: $target"
  }
}
```

Create the junctions with absolute paths from `cmd.exe`; do not continue after any error:

```cmd
mklink /J "%USERPROFILE%\.claude\skills\litrev" "%USERPROFILE%\.claude\skills\research-toolkit\skills\litrev"
mklink /J "%USERPROFILE%\.claude\skills\channels" "%USERPROFILE%\.claude\skills\research-toolkit\skills\channels"
mklink /J "%USERPROFILE%\.claude\skills\numerics-audit" "%USERPROFILE%\.claude\skills\research-toolkit\skills\numerics-audit"
```

Verify filesystem resolution and content through each exposed path:

```powershell
foreach ($name in $new) {
  $entry = Join-Path $skills $name
  $item  = Get-Item -LiteralPath $entry -Force
  [pscustomobject]@{ Name=$name; LinkType=$item.LinkType; Target=($item.Target -join ';') }
  if (-not (Test-Path -LiteralPath (Join-Path $entry 'SKILL.md') -PathType Leaf)) {
    throw "Unreadable installed skill: $name"
  }
  Get-Content -LiteralPath (Join-Path $entry 'SKILL.md') -TotalCount 5
}
```

Then start a **fresh** Claude Code session in a disposable project copy and verify:

1. `/litrev`, `/channels`, and `/numerics-audit` appear and each can state its modes without writing.
2. One installed skill reached through a relative symlink and one reached through a junction can read
   an actual shared guide/template and report the correct deployed absolute path.
3. `/review-paper checklist-only` creates/confirms only the checklist and returns before distribution,
   delegation, or manuscript edits.
4. `/join-revision` reaches the extracted providers once each and does not execute the old embedded
   phases.
5. `adopt` on the saved live-project copy preserves every custom instruction, leaves `jcode\` hashes
   unchanged, produces a byte-identical root backup, and is a no-op on its second invocation.
6. Re-run `git status --porcelain=v1` in both toolkit clones and the legacy-marker inventory. No
   project is considered migrated merely because the toolkit deployed successfully.

## ROLLBACK

### Toolkit and installed commands

1. Close all Claude sessions; a code rollback cannot remove already-loaded instructions from an
   existing conversation.
2. In the development clone, verify a clean tree. Revert commits 7 through 1 **newest to oldest**,
   one at a time, resolving and reviewing each revert. Do not rewrite published history:

```powershell
git -C 'D:\Dropbox\Research\research-toolkit' revert <commit-7-sha>
git -C 'D:\Dropbox\Research\research-toolkit' revert <commit-6-sha>
# Continue explicitly through <commit-1-sha>, then:
git -C 'D:\Dropbox\Research\research-toolkit' push
git -C "$env:USERPROFILE\.claude\skills\research-toolkit" pull --ff-only
```

3. Confirm the deployed SHA equals the reverted development/origin SHA. The revert should restore
   the legacy `skills\join-revision\references\spec-note.md`; verify that path and the old host
   reference together.
4. Inspect each new top-level entry and its target, then remove **only** the three junction objects;
   never recursively delete their targets. `rmdir` on a verified junction removes the link, not the
   target (**Windows behavior should still be verified on the actual entries before execution**):

```cmd
dir /AL "%USERPROFILE%\.claude\skills"
rmdir "%USERPROFILE%\.claude\skills\litrev"
rmdir "%USERPROFILE%\.claude\skills\channels"
rmdir "%USERPROFILE%\.claude\skills\numerics-audit"
```

5. Start a fresh Claude session and verify the three commands are absent and an existing command can
   still read its `SKILL.md` and shared guide.

### An adopted project

1. Stop work and preserve the failed post-adopt state; do not delete generated notes in bulk.
2. Identify the exact receipt and `notes\done\CLAUDE_pre_hub*.md` whose hash matches the recorded
   pre-adopt hash. Save the current hub separately, then copy that verified backup back to
   `CLAUDE.md`.
3. Restore every pre-existing note modified during adoption from its separate snapshot. New notes can
   remain for manual comparison; archive/remove them only after their contents are accounted for.
4. Compare `jcode\` against the pre-adopt hash manifest. Any difference violates the contract; restore
   from Git or the full project snapshot, not by guessing individual reversions.
5. Start a fresh Claude session on the restored project and re-run the old/new marker and path checks.

The root rewrite is reversible if the backup is complete and readable. These are not automatically
reversible: an approved edit to an existing note without its own snapshot; an accidental `jcode\`
change in a non-Git project without a full snapshot; messages or files already sent to collaborators;
and downstream manuscript/code changes made under faulty skill instructions. Dropbox version history
may provide another recovery source, but its availability and retention for each affected path are
**UNVERIFIED** and must not be the primary rollback plan.
