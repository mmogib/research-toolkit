---
name: channels
description: Run a `channels/` correspondence with an external AI reviewer that has read access to
  the project but no direct link to Claude, with the user relaying by hand. Scaffolds the protocol,
  composes bounded numbered messages that state one task and a definite done-state, maintains the
  exchange index, and closes the loop when a reply lands through separate receipt, verification, and
  adoption steps. Use when setting up such a reviewer, writing a message to one, or processing a
  reply. Not for subagents, which Claude spawns directly.
invocation: user
---

# /channels — Correspondence with an External Reviewer

An external AI reviewer runs inside the project with read access to all files. It has no channel to
Claude: the user relays messages both ways by hand. `channels/` is the whole conversation.

The value is **independence**. A second model reading the same files, given a bounded question and no
hint of where you suspect the problem, finds things you do not. That only holds if the exchange is
disciplined — one task per message, a definite done-state, no leading, and a verdict that is treated
as input to your own verification rather than a substitute for it.

## What this is not

| | |
|---|---|
| Subagents you spawn and read directly | Use the Agent tool. No relay, no protocol, no files. |
| A place to record decisions | Decisions live in the topic note that owns them. `channels/` is correspondence. |
| **A relayed exchange with an outside reviewer** | **this skill** |

The distinction that matters: a subagent shares your context and framing. An external reviewer has
only the files and the message, which is exactly why it catches what you and your subagents miss.

## What this skill owns

1. **Scaffolding** `channels/` with the protocol, once per project.
2. **Composing message N** — bounded, answerable, and for adversarial checks, unleading.
3. **Maintaining the index** so the exchange has a state.
4. **Closing the loop** when a reply lands — receipt, verification, adoption, as three separate steps.

## Phase 0 — Detect state, then pick the mode

| State | Mode |
|---|---|
| No `channels/` | **Scaffold** |
| `channels/` exists, no unprocessed reply | **Compose** the next message |
| A reply file exists whose index row has no `Replied` date | **Process reply** |

Report which state you found. If more than one applies, process the reply first — an open exchange
blocks new messages under the freeze rule.

## Scaffold

Ask for the helper's name (default: Codex). Then create:

```
channels/
├── README.md                 ← protocol, from references/channels-protocol.md
├── claude_to_<helper>/
└── <helper>_to_claude/
```

Copy the protocol text from `references/channels-protocol.md`, substituting the helper's name
throughout and **filling the two placeholders the host supplies**:

- `<frozen artifact>` — what may not change while an exchange is open. For a manuscript project,
  `paper/main.tex`. For a code project, whatever is under review.
- `<findings destination>` — where findings accumulate meanwhile, usually a topic note.

Those two values are *arrangement*: they belong to whoever invoked this skill, not to the protocol.
Never leave the placeholders unfilled — an unfilled freeze rule is not a rule.

Add a line to `## Active notes` in the project hub pointing at `channels/`.

## Compose a message

The whole skill, in one step. A badly formed message comes back as a discussion instead of an answer,
and the round trip costs the user a manual relay in each direction.

**Before writing, check all four:**

1. **One task.** If you want two things verified, write two messages. Bundled tasks get one answered
   well and the other in passing.
2. **A definite done-state.** "Thoughts on Section 4?" cannot be answered. "Verify Lemma 3.2 as
   stated at lines 412–447; if it holds give the derivation, if it fails give the smallest
   counterexample or the exact step that breaks" can.
3. **Context that stands alone.** The helper can read the files, but the message says where to look
   and what is being asked. Quote the exact statement, equation, or table under review with its
   line range.
4. **A stated deliverable form.** A verdict? A derivation? A ranked list? Say which, and say what
   sections the reply must contain. You will get the shape you asked for.

**For adversarial checks, send no hint of where you think the problem is.** Not in the task, not in
the context selection, not in a "particularly check whether…" aside. Independence is the entire point
of the exchange; leading the reviewer converts a second opinion into an echo. Compare afterwards.

Number the message `NNN_short-title.md` — a zero-padded counter over the whole exchange, not per
direction — write it to the outbound directory, add its index row, and tell the user to relay it.

## Process a reply

**Three states, and collapsing them is the mistake this procedure exists to prevent.** A reply
landing proves only that a reply exists.

### 1. Receipt

Update `Replied` in the index. Link the reply from the topic note that owns the question, marked
**pending**. Nothing is decided yet.

### 2. Verification

Check the reply's claims yourself, against the files. Every line number it cites, every factual
assertion about the project. Reviewers are wrong about something more often than not, and a confident
reply with one fabricated citation is more dangerous than a hedged one.

Where it disagrees with you, re-derive rather than defer. "The reviewer confirmed it" settles
nothing; so does "the reviewer is wrong because I already checked."

### 3. Adoption

**The user decides.** Present what survived verification, what did not, and what you would do. Only
after they accept does the outcome get recorded: `adopted`, `rejected`, or `partially adopted`, in
the owning topic note and the index's outcome field.

Record the decision in the note, not the channel. Nobody should have to read the correspondence to
learn what was decided.

## Message types that work

**Adversarial proof check.** "Verify Lemma 3.2 as stated at lines 412–447. Re-derive it
independently. If it holds, give the derivation. If it fails, give the smallest counterexample or the
exact step that breaks."

**Validate a batch.** After a batch of edits: "Lines 200–340 were revised. Validate the mathematics
and the prose, then add your own recommendations."

**Coverage check.** "Given the method in Section 3, which lineage or competing method is missing from
the literature review? Flag anything you name from memory as UNVERIFIED."

**Re-verification.** After a repair: "Lemma 3.2 was repaired as shown at lines 412–455. Re-verify end
to end, as if you had not seen the earlier exchange."

**Operational review.** "Here is a plan and the files it changes. Rank the failure modes by
likelihood × damage, each with a mitigation and a detection signal."

## Message types that do not work

- Anything without a done-state.
- Bundled tasks. Split them.
- Asking for edits to project files. The reply file is the only output.
- Asking it to check something you have not read yourself first — you cannot verify the answer.

## Rules

1. **Files are immutable once relayed.** A follow-up is a new number carrying "Re: NNN". No edits, no
   corrections in place. A message not yet relayed is not yet frozen.
2. **A helper verdict is input to your verification, never a substitute for it.**
3. **Adversarial exchanges carry no hints.**
4. **Freeze while an exchange is open** — the frozen artifact does not change; findings accumulate in
   the findings destination and are applied in one batch after the reply lands.
5. **The channel is correspondence, not the record.** Decisions go in the owning topic note with a
   pointer ("per 003 reply").
6. **The helper never edits project files** unless a specific message grants it for that message, and
   never fabricates citations — anything from memory is flagged UNVERIFIED.

## Reference files

- `references/channels-protocol.md` — the `channels/README.md` text, with the two host placeholders.
- `<toolkit>/guides/project-hub.md` — where decisions are recorded, and the notes discipline.
