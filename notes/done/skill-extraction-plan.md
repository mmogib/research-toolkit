# Skill extraction plan — three skills out of `/join-revision`, plus the project hub

Status: **agreed, revised twice under review, not yet implemented.** This note is the spec the
implementation commits check themselves against.

**Revision history**

- **v1** — settled interactively.
- **v2** — after two independent agent reviews (Opus and Fable, same brief, no shared context,
  neither told where the author suspected weakness).
- **v3 (current)** — after Codex reply `channels/codex_to_claude/001_skill-extraction-plan-review_reply.md`.
  Every factual claim in that reply was verified against the files before acceptance. Codex's
  accuracy was higher than either agent's: no phantom citations, no miscounts.
- **v4 (current)** — after Codex reply `channels/codex_to_claude/002_deployment-and-migration-risk_reply.md`,
  which inspected the actual machine. Its empirical claims were re-verified independently: the twelve
  legacy roots and their Git status match exactly; the count of already-hub projects is **4**, not 3.
  Migration tracking moved to `notes/migration-register.md`.

**Both exchanges are answered, verified, and adopted.** The freeze is lifted. While an exchange was
open the rule was: no implementation commits against `skills/`, `templates/`, or `guides/`.

---

## Why

`/join-revision` accumulated three self-contained workflows that have nothing to do with joining a
manuscript in revision — the adversarial numerics audit (118 lines), the `channels/` correspondence
protocol (104 lines), and the litrev cite-with-confidence system (102 lines). Each is reachable today
only by invoking a skill about revision phases.

A fourth item is not an extraction but a defect fix: the toolkit ships **three mutually contradictory
`CLAUDE.md` doctrines**.

## The extraction contract

> **The extracted skill owns the procedure. The host skill supplies the arrangement.**

**v2 correction:** v1 claimed only disposition needed parameterizing. Wrong — the arrangement leaks
into the intro and lenses A and C too.

**v3 correction:** v2's "three host-supplied slots" was still wrong. Lens C's `notes/litrev/<Key>.md`
is an **evidence source**, not a findings sink; the two were conflated. And v2 silently dropped an
arrangement that already exists in `join-revision:53-55` — *nobody available to run experiments*.
Loosely typed slots do not cover this. Replaced by four named modes (Part 2).

---

## Part 1 — The project hub

### Three competing doctrines

| File | Doctrine |
|---|---|
| `templates/CLAUDE.md.template` | Free-text `## Status` "updated after each session"; `## Paper Key Elements` with per-section status |
| `join-revision/references/claude-md-hub.md` | Lean hub: no session history, no findings — the hub only points |
| `optimization-research-workflow/references/claude-md-guide.md` | "Current Status (date) → Completed / Key findings / Next steps"; key principle *"Include key findings with numbers"* (verified `:36-56`) |

Dependents: `optimization-research-workflow/references/template-usage.md:28-38` and
`guides/experiment-workflow.md:20-21`.

The hub wins and becomes the template.

### Entry points

An entry point is a skill that can be the first thing run in a directory. Each review round found one
more; assume the list is still incomplete and re-check before commit 1.

| Skill | Situation | Found in |
|---|---|---|
| `/init-project` | Empty directory → full scaffold | v1 |
| `/join-revision` | Existing manuscript, no toolkit structure | v1 |
| `/optimization-research-workflow` | Phase 0 | v1 |
| `/math-research-writer` | `:40-68` instructs manual `mkdir` / `touch main.tex`, no `CLAUDE.md` at all | v2 (Fable) |
| `/suggest-journals` | Usable for "a new paper", reads root `CLAUDE.md` `:20-38` | v3 (Codex) |
| *(was a gap)* | Existing project, old or no structure, not a revision | v1 → `/init-project adopt` |

**Old-hub preflight.** Every entry point, plus `/ai-slop` and `/prepare-submission` (both can be the
first skill run in an existing manuscript directory), gets the same check: if the root `CLAUDE.md` is
missing or carries a `## Paper Key Elements` block, suggest `/init-project adopt` before proceeding.
A manuscript-map pointer alone is not sufficient (v3).

The preflight is a safety trigger, **not migration coverage** (v4) — a project that runs none of
those skills never sees it. Migration is tracked deliberately in `notes/migration-register.md`.
Four projects are already hub-shaped, so `adopt`'s no-op path runs against real projects on day one,
not just in tests.

### Where the hub lives

| Artifact | Holds | Owner |
|---|---|---|
| `templates/CLAUDE.md.template` (rewritten) | The hub shape | `/init-project` |
| `guides/project-hub.md` (new) | The discipline: hard limits, Active-notes rule, flat undated notes, `notes/done/`, migration procedure | Referenced by init-project, join-revision, channels, workflow |

The guide states the discipline applies to the **root** `CLAUDE.md` only. `jcode/CLAUDE.md` is
implementation reference material and stays long.

### The template merge

| Current template | Fate |
|---|---|
| Authors, affiliations, emails | **Keep.** v2: the v1 rationale ("`/prepare-submission` consumes it") is false — that skill derives front matter from `main.tex`. Keep the block; fix the reason. |
| `## Structure` tree | Keep. Absorbs `## Delegation` (`:46`). |
| `## Roles`, `## Rules`, `## Toolkit` | Keep, as arrangement variants. |
| Rule 5, refs/-PDF request workflow (`:61`) | Must survive — `/litrev` depends on it. |
| DFMethods block (`:94-110`) | **v3: replace with a one-line pointer.** v2 said "keep unchanged," which contradicts the lean-hub rule the plan is built on — the block is a detailed implementation summary (adapter, callbacks, sweep helpers). Detail moves to `templates/jcode-CLAUDE.md.template`. |
| `**Paper status**:` and free-text `## Status` | Replace with Phase / Now / Next. |
| `## Paper Key Elements` | Drop. On `adopt`, migrates to `notes/manuscript-map.md`. |
| — | **Add `## Active notes`** — the index the discipline hangs on. |

### Arrangement variants

`/init-project`'s interview asks who owns code and whether an external reviewer is in the loop, then
writes **only the matching block**. Solo; collaborator owns code; external reviewer (composes with
either). The `channels/` opt-in runs only in `adopt` and manuscript-flavor runs.

### `adopt`

Detect → propose → approve → backup → write.

| Old content | Destination |
|---|---|
| `## Paper Key Elements` | `notes/manuscript-map.md` |
| Known issues / WIP | Open topic notes |
| Session history, changelogs | Summarized into the relevant topic note |
| Authors, affiliations, structure, roles, rules | Carried into the new hub |

**Twelve real projects are waiting for this** — eight of them with no Git at all, every one with a
`jcode/`. Per-adoption procedure, hashes, forward tests, and rollback live in
`notes/migration-register.md`. Never bulk-adopt.

Requirements:

1. **Verbatim backup to `notes/done/CLAUDE_pre_hub.md`** before overwriting. This is the only
   operation in the plan that overwrites a user's file, and eight of the twelve target projects have
   no Git, so the backup plus snapshot is the only rollback that exists.
2. **Re-entrancy (v3, promoted to blocking).** A second or interrupted run must not overwrite the
   backup with an already-trimmed hub — that destroys the only verbatim copy. `adopt` is a no-op when
   the root already matches the hub; it never overwrites an existing backup; on collision it writes a
   numbered backup and reports both. An existing `notes/manuscript-map.md` is merged only after
   showing a proposed diff and receiving approval.
3. **Never scaffold code templates into an existing `jcode/`.** Skip architecture, storage-backend,
   and DFMethods questions when code exists.
4. **The host supplies its constraints** — `/join-revision`'s "never touch `paper/`" and "keep
   `jcode/` minimal" are passed in.
5. **No double interview.** A host invoking `adopt` passes its Phase 1 answers; `adopt` skips those
   questions.
6. `init-project/SKILL.md:272-279`'s closing summary needs an `adopt` variant.

---

## Part 2 — `/numerics-audit`

Five lenses: **A** claim inventory · **B** do the test problems exercise the selling points ·
**C** comparability · **D** consistency of reported artifacts · **E** reproducibility ·
**F** disposition.

### Four modes (v3 — replaces v2's three slots)

The host declares a mode. Every mode supplies all five values.

| Mode | Evidence lookup (lens C) | Findings sink | Markup / edit policy | Experiment handoff (lens F) | Decision owner |
|---|---|---|---|---|---|
| `collaborator-owned` | `notes/litrev/<Key>.md` | `notes/review-findings.md` | `\rev{...}` batch | `templates/spec-note.md` → `notes/spec-<topic>.md` | Mohammed |
| `self-owned` | litrev note, else the cited PDF | `notes/review-findings.md` | direct edit, project convention | new/modified script via `/jcode-script` | Mohammed |
| `no-runner` | litrev note, else the cited PDF | `notes/review-findings.md` | text-only fixes | none — every gap becomes a note | Mohammed |
| `referee` | the cited paper directly; flag unverifiable | the referee report itself | **no edits at all** | none | the referee |

`no-runner` restores the arrangement that already exists at `join-revision:53-55` and that v2 lost.

Verified leak points to parameterize in `numerics-audit.md`: `:7-9` (intro — "cannot run", `\rev`
batch, spec-note path), `:9` (**the relative path `references/spec-note.md` breaks on the move**),
`:17` (lens A findings destination), `:74-79` (lens C evidence source).

`spec-note.md` moves to `templates/spec-note.md`. **Copied in commit 4 with the legacy path retained;
the legacy copy is deleted in commit 6** once `/join-revision` is rewired — otherwise the live path
breaks for two commits.

### Fan-out (v3 — write isolation and dependency order)

v2 said "optional, by axis, sequential default" and stopped there. That is unsafe: lenses A and F
both write the shared findings note, and D re-checks numbers B flagged. Parallel axes would clobber
each other and D could run before B produced anything.

Order: the **parent** builds claim inventory A first → **B, C, E** run in parallel, each writing its
own read-only axis report → **D** runs after B and the table inventory → the **parent alone**
consolidates and performs F. No subagent edits the manuscript or the shared findings file.

## Part 3 — `/channels`

v1 shipped "the middle" — neither a template nor a skill. Resolved: a real runtime procedure.

1. Scaffold `channels/` with the protocol README, substituting the helper's name.
2. **Compose message N** — enforce one task, a definite done-state, the anatomy
   (Task / Context / Deliverable / Constraints), and for adversarial exchanges that no hint of the
   author's suspicion is included.
3. **Maintain the index table.**
4. **Three-state reply lifecycle (v3).** v2 collapsed receipt, verification, and adoption into one
   event, which contradicts the protocol's own rule that a helper verdict is input to verification,
   never a substitute for it. Correct sequence:
   - **Receipt** — update `Replied` in the index; link the reply from the owning topic note as
     *pending*.
   - **Verification** — check the reply's claims independently against the files.
   - **Adoption** — only after Mohammed accepts, record `adopted` / `rejected` /
     `partially adopted` in the topic note and the index outcome field.

**Freeze rule — single owner.** It is arrangement, so the host owns it. The README ships with
placeholders: "while an exchange is open, `<frozen artifact>` is frozen; findings accumulate in
`<findings destination>`."

## Part 4 — `/litrev`

### Two modes (v3)

| Mode | Question | Discovery |
|---|---|---|
| `audit-manuscript` | What is cited but unread? | manuscript file, bibliography, PDF root + index, note root — all discovered, not assumed |
| `build-from-reading` | What have I read that I can safely cite? | same discovery, reversed inventory |

v2 parameterized the *direction* but left `main.tex`, the `.bib` index, the refs directory, and
`notes/litrev/` hardcoded (`litrev.md:28-40,92-102`).

### The refs flow cannot be absorbed

Skills load only when invoked, so a session that never calls `/litrev` would lose the
never-fabricate-references rule. v1 said the flow appears in three places. **Verified: seven files.**

| File | Line(s) | Fate |
|---|---|---|
| `CLAUDE.md` | 102 | **Canonical.** Stays in full. |
| `templates/CLAUDE.md.template` | 24, 60 | Stays in full — a hub must be self-contained. |
| `guides/latex-conventions.md` | 25 | Pointer |
| `guides/paper-review-checklist.md` | 97, 106 | Pointer |
| `skills/init-project/SKILL.md` | 42, 145 | Keeps file creation; pointer for the rule |
| `skills/join-revision/SKILL.md` | 227 | Pointer |
| `join-revision/references/claude-md-hub.md` | 59 | File removed |

The note must say which copies are load-bearing so a future session does not delete one.

### `math-research-writer` §11 — a live hazard, independent of this plan (v3)

`math-research-writer/SKILL.md:708-744` "Citation Management for Mathematics" shows fully-formed
reference entries — Beck & Teboulle 2009, Rockafellar & Wets, Boyd et al., with volumes and pages —
as a model output pattern. That is a skill teaching a session to emit bibliography entries from
memory, in a toolkit whose Rule 4 forbids exactly that. Rewiring only the Literature Review section
would leave the hazard one section away.

**Fix:** §11 and both literature sections hand off to `/litrev`. Candidate references may be recorded
as unverified leads; never emitted as bibliography entries.

---

## Invocation matrix

| Host | `/numerics-audit` | `/channels` | `/litrev` |
|---|---|---|---|
| `/join-revision` | step 5, mode `collaborator-owned` | Phase 5 | Phase 4 + step 3, `audit-manuscript` |
| `/review-paper` | item slug `numerics-audit` | — | item slug `bibliography-integrity` |
| `/optimization-research-workflow` | phase 9, mode `self-owned` | optional, phases 1 and 9–11 | phase 10 and phase 1 |
| `/math-research-writer` | Numerical Experiments | proof checks, **conditional on `channels/` existing** | Lit Review **and §11**, `build-from-reading` |
| `/init-project` | — | opt-in, adopt/manuscript runs only | scaffold `notes/litrev/` by default |
| `/prepare-submission` | **no** | — | — |

### `/review-paper` — three defects

**1. Item 5 is the wrong hook (v2).** Item 5 checks whether the paper *mentions* finite-difference or
gradient validation — derivative validation, not benchmark auditing. v1 chose it by size.

**2. Number-based dispatch is unstable (v3 — the sharpest finding).** `review-paper/SKILL.md:55`
skips inapplicable items and **renumbers the survivors**, while `:82-96,122-141` dispatch by fixed
number. After any skip, "item 12" need not be Bibliography Integrity. v2's fix — add an item and
renumber — makes this worse.

**Fix:** canonical stable IDs. Inapplicable items are marked `N/A`, never renumbered. Insert
*Numerical Experiments Audit* as canonical item **13**; Style Pass becomes **14**. All dispatch is by
slug, never by display number:

`notation-style` · `proof-review` · `assumptions-audit` · `core-derivation` ·
`computational-verification` · `abstract-polish` · `introduction` · `section-transitions` ·
`redundancy` · `algorithm-presentation` · `captions` · `bibliography-integrity` ·
`numerics-audit` · `style-pass`

Repo-wide sweep required for literal "13-item" and "item 13" references: `CLAUDE.md`, `README.md`,
`join-revision`, `ai-slop`, `guides/paper-review-checklist.md`.

**3. Delegations fire during checklist construction (v2).** Phase 5 (`:100-111`) *executes* assigned
items. `/join-revision:178` invokes `/review-paper` at step 1 and it runs straight through — item 13
already delegates to `/ai-slop`, which join-revision reserves for step 8. Live bug today; v1 would
have tripled it.

**Fix:** checklist-only mode defined precisely as **Phases 1–3** — discover context, create/confirm
the checklist, add project-specific items — returning **before** task distribution and execution.

**4. Notes filename clash (v2).** `:34` writes `notes/review_checklist_YYYYMMDD.md`; the discipline
is flat, topical, undated.

---

## Other items entering the manifest

- **`\rev` integrity checks → `guides/latex-conventions.md`** (brace balance, dangling references,
  duplicate labels, `join-revision:160-166`). `/ai-slop` handles `\rev{...}` with no reachable
  definition of the convention. A guide section, not a fourth skill.
- **`/ai-slop` notes discipline (v3)** — `:61` writes `notes/ai_slop_<chunk-id>.md`, `:130-133`
  archives into `notes/done/ai_slop_<YYYYMMDD>/`. Replace with undated topical files, consolidated
  into `notes/ai-slop.md`, moved directly to `notes/done/`.
- **`/suggest-journals` (v3)** — `:90-99` writes `notes/journal_suggestions_YYYYMMDD.md`. Replace
  with one undated `notes/journal-suggestions.md` updated in place. Add
  `references/output-template.md` to the manifest.
- **Frontmatter sweep (v3)** — the three new skills need deliberate descriptions (`/litrev`'s
  narrowly, or it fires on any mention of a citation). `/init-project`'s current description says
  "new research projects" only and must gain existing-project/adopt triggers.
- **`guides/experiment-workflow.md`** — phase 9's gate (`:293`), phase 10 step 1 (`:302`), phase 11
  step 5 (`:320`). Deferred to commit 7 (v3), since the touchpoints name skills created in 2–4.

## Evaluation gate (v3, scoped)

Codex asked for baseline scenarios plus forward-tests for all three skills as a commit condition —
roughly nine fresh-session runs. Accepted in principle, scoped down: the artifact under construction
is prompt behavior, and prose review does not demonstrate it, but a full matrix is disproportionate
for a personal toolkit.

- **Scenarios written into this note** for all three skills.
- **Forward-tested for real**, on the two highest-risk paths only:
  1. `/numerics-audit` in `referee` mode — no `notes/`, no litrev, no `\rev`; every value at its
     unusual setting.
  2. `/init-project adopt` on a copy of a live project — non-git, hand-edited `CLAUDE.md`, existing
     `jcode/`.

## Settled decisions

| Question | Chosen |
|---|---|
| Which workflows to extract | All three |
| Referee mode | Yes |
| Fan-out | Optional, by axis, sequential default, **two-wave with write isolation** (v3) |
| `notes/litrev/` in `/init-project` | Default |
| `channels/` in `/init-project` | Opt-in, adopt/manuscript runs only |
| Channels skill name | `/channels` |
| Hub discipline location | Template + `guides/project-hub.md` |
| Adopting an existing project | Mode on `/init-project` |
| Migration | Extract to notes **and** verbatim backup, **re-entrant** (v3) |
| Roles/Rules variants | Interview emits the matching block |
| `/channels` shape | Real runtime procedure, **three-state reply lifecycle** (v3) |
| `/numerics-audit` arrangement | **Four named modes** (v3), not three slots |
| `/review-paper` dispatch | **Canonical slugs, never renumber** (v3) |
| Root DFMethods block | **Pointer only** (v3) |

## What stays in `/join-revision`

Setup interview, the freeze rule (as arrangement owner), the eight-step order, and `\rev` as applied
to a revision. Integrity checks move to `guides/latex-conventions.md`; `spec-note.md` moves to
`templates/`. Delegates to five skills instead of two, and loses a phase.

---

## File manifest (v3)

**New**

```
skills/litrev/SKILL.md, references/litrev-notes.md
skills/channels/SKILL.md, references/channels-protocol.md
skills/numerics-audit/SKILL.md, references/audit-procedure.md
guides/project-hub.md
templates/spec-note.md
```

**Rewritten**

```
templates/CLAUDE.md.template
skills/optimization-research-workflow/references/claude-md-guide.md   gutted to a pointer
```

**Edited**

```
skills/init-project/SKILL.md          adopt (re-entrant), variants, :187-192, :272-279,
                                      frontmatter triggers, scaffolding defaults
skills/join-revision/SKILL.md         Phase 3 deleted; Phases 2/4/5 and steps 3/5 delegate
skills/join-revision/references/      4 removed; spec-note.md deleted in commit 6
skills/review-paper/SKILL.md          canonical slugs, N/A not renumber, item 13 inserted,
                                      checklist-only mode, :34 undated, old-hub preflight
skills/optimization-research-workflow/SKILL.md            phases 0/1/9/10; Rules 4 and 5
skills/optimization-research-workflow/references/template-usage.md   :28-38
skills/math-research-writer/SKILL.md  :40-68 setup → init; Lit Review → litrev; §11 rewrite
skills/ai-slop/SKILL.md               notes discipline; \rev pointer; old-hub preflight
skills/prepare-submission/SKILL.md    manuscript-map pointer; old-hub preflight
skills/suggest-journals/SKILL.md      undated note; old-hub preflight
skills/suggest-journals/references/output-template.md
templates/jcode-CLAUDE.md.template    receives the DFMethods detail
guides/paper-review-checklist.md      item 13 inserted, slugs, refs pointer
guides/latex-conventions.md           \rev integrity checks; refs pointer
guides/experiment-workflow.md         phases 9/10/11 pointers
CLAUDE.md                             ten → thirteen skills; 13-item → 14-item
README.md                             four places
```

## Commit order (v3)

v2 still introduced consumers before providers. Corrected: **each skill's behavior lands with that
skill, never before it.**

0. **Process safety (v4)** — three pre-existing defects that make the rollout itself unsafe, fixed
   before any of the seven. `README.md:55` blesses editing the deployed clone (that is how the clones
   silently diverge); `README.md:58` says `git add .` (today it would stage `channels/`, the plan, and
   `session_ids.txt`); `CLAUDE.md:21`'s "verify symlinks still resolve" names
   `~/.claude/skills/mohammed-research-skills/`, which does not exist, so the documented check has
   never worked. Add `.gitignore` for `session_ids.txt`.

1. **Foundation, hub/adopt only** — `guides/project-hub.md`, rewritten template (DFMethods → pointer),
   `templates/jcode-CLAUDE.md.template`, `/init-project` (adopt with re-entrancy, variants,
   instruction fixes), `claude-md-guide.md` gutted, `template-usage.md`.
   **No litrev default, no channels opt-in** — those skills do not exist yet.
2. `/litrev` **+ `/init-project` litrev-by-default**
3. `/channels` **+ `/init-project` channels opt-in**
4. `/numerics-audit` — four modes; `templates/spec-note.md` **copied, legacy path retained**
5. `/review-paper` — canonical slugs, item 13, checklist-only mode, undated filename, preflight.
   **Plus the one-line `/join-revision:178` change to `/review-paper checklist-only` (v4).** Without
   it, commit 5 is safe only by the deploy-at-the-end policy: the installed old host would still call
   plain `/review-paper` and run the full workflow plus both new delegations at step 1. One line moves
   the boundary from safe-by-policy to safe-by-construction.
6. `/join-revision` — Phase 3 deleted, remaining four delegations, **legacy `spec-note.md` deleted**
7. Remaining wiring — `math-research-writer`, workflow phases and rules, `experiment-workflow.md`,
   `latex-conventions.md`, `ai-slop`, `prepare-submission`, `suggest-journals`,
   `paper-review-checklist.md`, `CLAUDE.md`, `README.md`, repo-wide 13→14 sweep

## Deployment (v4 — verified procedure)

**Deploy once, after commit 7.** Treat it as a maintenance window: finish or pause running workflows,
close every Claude Code session, deploy, then start fresh sessions. An already-invoked `SKILL.md`
stays in its conversation and is not reread, so a session that spans the deployment is a mixed-version
runtime — harder to recognize than a missing command. Session age is the only practical signal.

**Policy:** the deployed clone at `~/.claude/skills/research-toolkit/` is read-only. Edit only
`D:\Dropbox\Research\research-toolkit`. Stage named paths per commit; never `git add .`.

**Dropbox:** only one machine may mutate the development worktree at a time. Confirm Dropbox is fully
synced and other machines idle before starting. Never move the installed links into Dropbox — it does
not sync junctions or symlinks.

1. Push from the development clone. Compare **full SHAs**, not branch names.
2. `git pull --ff-only` at the deployed clone. Stop on any dirty status, divergence, or error.
3. Verify all three `skills/<name>/SKILL.md` exist in that exact checkout **before** creating links —
   `mklink /J` to a nonexistent target succeeds and creates a dangling junction that fails silently.
4. Confirm `litrev`, `channels`, `numerics-audit` are absent from `~/.claude/skills/`. Never replace
   an unexpected entry automatically.
5. Create the three junctions from `cmd.exe` with absolute source and target paths.
6. Verify each resolves, then read its `SKILL.md` through the exposed path.
7. Fresh session in a disposable copy: each new command appears and can state its modes without
   writing; `/review-paper checklist-only` returns before distribution; `/join-revision` reaches each
   provider once; `adopt` is a no-op on second invocation.

**Resolved (v4):** whether `../../guides/...` references survive the exposed symlink was flagged
UNVERIFIED. Tested — `~/.claude/guides` does not exist, yet reading
`~/.claude/skills/review-paper/../../guides/latex-conventions.md` returns the file. The filesystem
follows the link before applying `..`. The end-to-end model-issued read is still worth one check.

**Corrected premise (v4):** clone divergence alone cannot pair a new skill with an old guide — all
installed entries and their shared files come from the deployed clone, so divergence produces coherent
but silent staleness. A true file-level hybrid needs a dirty checkout, links aimed at different roots,
or the mixed-session case above.

## Rollback

**Toolkit:** close all sessions first — a code rollback cannot unload instructions from an open
conversation. Revert commits 7 → 0 newest to oldest, one at a time, reviewing each. Do not rewrite
published history. Push, pull at the deployed clone, confirm SHAs match, verify the legacy
`spec-note.md` path is restored alongside the old host reference. Then remove **only** the three
junction objects with `rmdir` — never recursively delete their targets.

**An adopted project:** see `notes/migration-register.md`.

## Known risks

- **`adopt` losing hand-edited instructions** — the top risk, and the only one that can destroy
  research material. Twelve waiting projects, eight without Git. Never bulk-adopt; forward-test on
  copies first.
- **Mixed-version sessions** — deploy in a maintenance window; start a fresh session after each adopt.
- **Stale or dirty deployed clone** — compare full SHAs and require an empty porcelain status.
- **Dropbox/Git race on the development worktree** — one writer at a time; scan for conflicted copies
  before and after the sequence.
- **Legacy projects never adopting** — the preflight is a trigger, not coverage. The register is.
- **Drift between extracted skill and host** — only mitigated if hosts delegate rather than restate.
- **Entry-point list grew in every review round.** Re-check before commit 1.
- **`/join-revision` thinning** — reread end to end after commit 6.
- **Scope** — ~500–600 lines of net new writing, plus commit 0.
