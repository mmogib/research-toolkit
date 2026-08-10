# 002 — Deployment and migration risk

## Task

Assess what can go wrong when this change is deployed, and when it lands on research projects that
already exist. Done means: a list of failure modes ranked by likelihood × damage, each with a
concrete mitigation and a way to detect it if it happens anyway. This is not a design review — 001
covers the design. This is "what breaks in the real world."

Your 001 reply has landed and been verified against the files; every factual claim in it checked out.
The plan is now at v3 and incorporates it, including the corrected commit sequence. Read
`codex_to_claude/001_skill-extraction-plan-review_reply.md` and the v3 revision history before
starting, so you do not re-derive design findings here. Nothing in 001 has been formally adopted yet
— that is Mohammed's call — but the sequence below is what deployment would run against.

## Context

### How deployment works

The toolkit is a git repo at `D:\Dropbox\Research\research-toolkit` (the development location, inside
Dropbox). A second clone sits at `~/.claude/skills/research-toolkit/` (the deployed location). Claude
Code discovers skills by scanning `~/.claude/skills/*/SKILL.md`, so each skill is exposed by a
directory junction from `~/.claude/skills/<name>` into the deployed clone's `skills/<name>`.

Existing junctions and symlinks are mixed: some entries are Git-Bash symlinks pointing at relative
paths, some are junctions created with `mklink /J` and absolute paths. `mklink /D` and PowerShell's
`New-Item -ItemType SymbolicLink` require `SeCreateSymbolicLinkPrivilege` (admin or Developer Mode)
in this environment; junctions do not.

The plan's deployment section gives the order: push → pull at the deployed clone → verify the new
skill directories exist → create three junctions → verify each resolves. v1 had the junction step
before the pull, which would have created dangling junctions that fail silently.

This change adds three new skills (`litrev`, `channels`, `numerics-audit`), rewrites
`templates/CLAUDE.md.template`, and edits fifteen or so existing files across `skills/`, `guides/`,
and the repo root.

### What already exists in the world

Research projects on this machine and in Dropbox already have a `CLAUDE.md` generated from the
current template, and reference the toolkit by path. Some are mid-flight. The plan's `adopt` mode is
the only operation that overwrites a user's existing file; it backs up to
`notes/done/CLAUDE_pre_hub.md` first, then extracts content into notes, then writes the new hub.

Relevant files: `README.md` lines 20–44 (the symlink/junction setup instructions), `CLAUDE.md`
("Deployment" section), and the plan's "Deployment" and "Migration procedure (`adopt`)" sections.

### Specific things to probe

1. **Partial deployment.** Push succeeds, pull fails or is forgotten, or a junction is created before
   its target exists. What is the observable symptom, and is it silent? How would the user know?
2. **Dropbox.** The development clone lives inside Dropbox. Sync during a commit, `.git` conflict
   files, symlink and junction behaviour under Dropbox sync, and a second machine pulling the same
   repo.
3. **Split-brain between the two clones.** They can diverge. What happens if the deployed clone is
   behind and a skill references a guide or template that only exists in the newer commit? Cross-file
   references inside skills use relative paths like `../../guides/...`.
4. **Existing projects.** A project whose `CLAUDE.md` came from the old template, that never runs
   `adopt`. What degrades, and does anything actively break? The plan adds an old-shape detection
   line to two skills — is that sufficient, and is it the right trigger?
5. **`adopt` on a live project.** Worst realistic case. Consider a project that is not a git repo (a
   Dropbox folder), has a hand-edited `CLAUDE.md` with content in neither the old template's shape nor
   the hub's, and has an existing `jcode/` with real code.
6. **Rollback.** If this lands and turns out wrong, what is the path back, and is anything
   irreversible?
7. **Ordering across the seven commits, against the v3 sequence.** Your 001 BLOCKING 4 found that v2
   introduced consumers before providers; v3's fix moves each skill's behavior into the commit that
   creates it, defers the experiment-guide wiring to commit 7, and copies `spec-note.md` in commit 4
   while retaining the legacy path until commit 6. Deployment is described as happening once at the
   end. Check two things: whether the v3 sequence actually holds if deployment instead runs after
   every commit, and whether the copy-then-delete window for `spec-note.md` leaves a live `/join-revision`
   path broken on the deployed clone at any point. Assume the two clones can be at different commits.

## Deliverable

A single reply file, `codex_to_claude/002_deployment-and-migration-risk_reply.md`, containing:

- **TOP RISKS** — ranked. Each with: the failure mode, how likely, what damage, the mitigation, and
  the detection signal. Rank by likelihood × damage, not by how interesting the failure is.
- **SILENT FAILURES** — called out separately. Anything that fails without an error message is worse
  than something that crashes, and this is the category most likely to bite.
- **PRE-FLIGHT CHECKS** — a short list of things to verify before commit 1 lands.
- **POST-DEPLOY VERIFICATION** — a short list of things to check after, that would catch a botched
  deployment.
- **ROLLBACK** — the concrete path back, and anything irreversible flagged.

Keep it operational. Commands and file paths, not principles.

## Constraints

See `channels/README.md`. Additionally: do not edit any file in this repo and do not run any command
that mutates state — the reply file is the only output. Read-only inspection of the filesystem and
git history is expected and welcome. Where you are uncertain whether a Windows or Dropbox behaviour
holds in this environment, say so and mark it **UNVERIFIED** rather than asserting it.
