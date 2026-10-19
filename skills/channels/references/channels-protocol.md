# `channels/README.md` — the protocol text

Copy the block below into `channels/README.md`. Substitute `<helper>` throughout with the reviewer's
name (default: Codex) and `<main>` with the main agent's name (default: Claude); directory names use
their lowercase labels. Create `channels/<main>_to_<helper>/` and `channels/<helper>_to_<main>/`
alongside it. With the defaults the result is as before: `claude_to_codex/` and `codex_to_claude/`.

**Two placeholders are supplied by the host, not by this protocol.** Fill both before writing the
file:

| Placeholder | Meaning | Typical value |
|---|---|---|
| `<frozen artifact>` | What may not change while an exchange is open | `paper/main.tex`; the module under review |
| `<findings destination>` | Where findings accumulate meanwhile | `notes/review-findings.md` |

An unfilled freeze rule is not a rule. If the host has not said what is frozen, ask.

**Optional host additions.** If the host supplies a reading scope or extra constraints (for example
confidentiality, or no execution), append each as a further numbered item under "Standing
constraints for <helper>". If it supplies neither, add nothing.

---

```markdown
# Channels — correspondence with <helper>

<helper> runs inside this project with read access to all files. It has no channel to <main>
directly: the user relays messages both ways by hand. This directory is the whole conversation.

## Directories

- `<main>_to_<helper>/` — messages <main> writes for <helper>.
- `<helper>_to_<main>/` — replies <helper> writes back.

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
<One paragraph. What <helper> is being asked to do, and what "done" looks like.>

## Context
<Files and line ranges. Quote the exact statement, equation, or table under review. <helper> can read
the files, but the message must stand alone: it says where to look and what is being asked about.>

## Deliverable
<Exactly what the reply must contain. A verdict? A derivation? A ranked list? Say the form, and name
the sections.>

## Constraints
See `channels/README.md`. <Add anything specific to this message here.>
```

## Immutability

Once a file is relayed it is frozen. No edits, no corrections in place. A follow-up is a new number
whose title carries `Re: NNN`. A message not yet relayed is not yet frozen.

## Standing constraints for <helper>

1. Its only output is the reply file in `<helper>_to_<main>/`. Nothing else.
2. It never edits project files unless a message explicitly grants it permission for that message.
3. It never fabricates citations. Anything it suggests from memory is flagged **UNVERIFIED**.
4. It does not run code and does not compile LaTeX.
5. When it disagrees, it says so with a derivation, not a verdict.

## Standing constraints on <main>'s side

1. A <helper> verdict is input to <main>'s own verification, never a substitute for it. "<helper>
   confirmed it" settles nothing.
2. Adversarial exchanges are sent **without** sharing <main>'s suspicions. Independence is the point;
   compare afterwards.
3. **Freeze rule.** While an exchange is open, `<frozen artifact>` does not change. Findings
   accumulate in `<findings destination>` and are applied in one batch after the reply lands.
4. A reply landing is not a decision. Receipt, verification, and adoption are three separate steps;
   the outcome field below is filled only after the user accepts.
5. Decisions adopted from an exchange are recorded in the relevant topic note with a pointer — "per
   003 reply". This directory is correspondence, not the record. Nobody should have to read the
   channel to know what was decided.

## Index

| NNN | Title | Sent | Replied | Outcome recorded in |
|-----|-------|------|---------|---------------------|
| 001 | ... | | | |
```

---

## Keeping the index honest

The `Outcome` column is the one that rots. A row with a `Replied` date and an empty outcome means one
of two things — the reply is still being verified, or it was read and quietly forgotten. Write
`pending verification` while it is genuinely in flight, so the difference is visible.

`adopted` / `rejected` / `partially adopted` are the only closing values, and each points at the note
where the reasoning lives.
