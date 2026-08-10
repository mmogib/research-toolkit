# Channels — correspondence with Codex

Codex (OpenAI) runs Codex CLI inside this project with read access to all files. It has no channel to
Claude directly: Mohammed relays messages both ways by hand. This directory is the whole conversation.

This is the **research-toolkit repo itself**, not a manuscript project. The artifact under review is
the toolkit's own `skills/`, `templates/`, and `guides/`.

## Directories

- `claude_to_codex/` — messages Claude writes for Codex.
- `codex_to_claude/` — replies Codex writes back.

## Naming

- Message: `NNN_short-title.md` (e.g. `003_lemma-3-2-monotonicity.md`)
- Reply: `NNN_short-title_reply.md` — same number, same title, `_reply` appended.

`NNN` is a zero-padded counter over the whole exchange, not per direction.

## One task per message

Each message asks for one thing and states a definite done-state. If you want two things verified,
write two messages. A message without a done-state cannot be answered and will come back as a
discussion.

## Message anatomy

```
# NNN — <short title>

## Task
<One paragraph. What Codex is being asked to do, and what "done" looks like.>

## Context
<Files and line ranges. Quote the exact statement under review. Codex can read the files, but the
message must stand alone: it says where to look and what is being asked about.>

## Deliverable
<Exactly what the reply must contain. A verdict? A derivation? A list of counterexamples? Say the form.>

## Constraints
See `channels/README.md`. <Add anything specific to this message here.>
```

## Immutability

Once a file is relayed it is frozen. No edits, no corrections in place. A follow-up is a new number
whose title carries `Re: NNN`.

## Standing constraints for Codex

1. Its only output is the reply file in `codex_to_claude/`. Nothing else.
2. It never edits project files unless a message explicitly grants it permission for that message.
3. It never fabricates citations. Anything it suggests from memory is flagged **UNVERIFIED**.
4. It does not run code and does not compile LaTeX.
5. When it disagrees, it says so with a derivation, not a verdict.

## Standing constraints on Claude's side

1. A Codex verdict is input to Claude's own verification, never a substitute for it. "Codex confirmed
   it" settles nothing.
2. Adversarial exchanges are sent **without** sharing Claude's suspicions. Independence is the point;
   compare afterwards.
3. **Freeze rule.** While an exchange is open, **no implementation commits land against
   `skills/`, `templates/`, or `guides/`**. Findings accumulate in
   `notes/skill-extraction-plan.md` and are applied in one batch after the reply lands.
4. Decisions adopted from an exchange are recorded in the relevant topic note with a pointer — "per
   003 reply". This directory is correspondence, not the record. Nobody should have to read the
   channel to know what was decided.

## Index

| NNN | Title | Sent | Replied | Outcome recorded in |
|-----|-------|------|---------|---------------------|
| 001 | Skill extraction plan — design review | 2026-08-10 | 2026-08-10 | **adopted** → `notes/skill-extraction-plan.md` v3 |
| 002 | Deployment and migration risk | 2026-08-10 | 2026-08-10 | **adopted** → `notes/skill-extraction-plan.md` v4 + `notes/migration-register.md` |
