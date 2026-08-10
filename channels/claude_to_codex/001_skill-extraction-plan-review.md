# 001 — Skill extraction plan, design review

## Task

Review `notes/skill-extraction-plan.md` (v2) as a design about to be implemented in seven commits,
and report whether it is sound enough to build. Done means: a verdict, plus a prioritized list of
defects, each naming the file and line it applies to and giving a concrete alternative rather than a
concern.

Two independent reviews already ran against v1. Their findings are folded into v2 and marked `v2`
inline. **Do not re-derive them.** Judge the revised design: whether each v2 fix actually resolves
what it claims to, and what neither review caught.

## Context

The repo is a personal research toolkit for a mathematics researcher. It ships Claude Code "skills"
— markdown files at `skills/<name>/SKILL.md` with YAML frontmatter, invoked as slash commands. They
are prompts for a future Claude session, not code. Judge them as such: reading this file, does a
session do the right thing?

The plan does four things:

1. Extracts three workflows out of `skills/join-revision/` into their own skills — `/numerics-audit`,
   `/channels`, `/litrev`. The source material is in `skills/join-revision/references/`.
2. Resolves three mutually contradictory `CLAUDE.md` doctrines — `templates/CLAUDE.md.template`,
   `skills/join-revision/references/claude-md-hub.md`, and
   `skills/optimization-research-workflow/references/claude-md-guide.md` — in favour of the lean hub,
   which becomes the template.
3. Adds an `adopt` mode to `/init-project` for existing projects, and deletes `/join-revision`
   Phase 3.
4. Rewires the delegations between skills (the invocation matrix in the plan).

Read, at minimum: the plan; `CLAUDE.md`; `skills/join-revision/SKILL.md` and all five files in its
`references/`; `skills/init-project/SKILL.md`; `skills/review-paper/SKILL.md`;
`templates/CLAUDE.md.template`; `skills/optimization-research-workflow/references/claude-md-guide.md`;
and `skills/ai-slop/SKILL.md` as the closest existing analogue in shape to the new skills.

Specific questions, in descending order of how much they would cost to get wrong:

1. **The extraction contract** — "the extracted skill owns the procedure, the host supplies the
   arrangement" (plan, "The extraction contract"). v2 enumerates the leak points in
   `numerics-audit.md` and claims parameterizing the intro plus lenses A and C closes it. Does it?
   Does the same contract hold for `/channels` and `/litrev`, or does one of them leak somewhere the
   plan has not looked?
2. **`/channels` as a skill.** The plan gives it a four-step runtime procedure (Part 3) after one
   reviewer argued the content is a template rather than a slash command. Is the procedure real work,
   or is this justifying a skill that should be a template plus a guide section?
3. **Ordering and re-entrancy.** The plan adds delegations from `/review-paper` to `/litrev` and
   `/numerics-audit`, while `/join-revision` invokes `/review-paper` at step 1 and the two extracted
   skills at steps 3 and 5. v2's fix is a checklist-only mode. Are there remaining paths where a
   delegation fires at the wrong time, twice, or recursively?
4. **The hub.** Is the entry-point inventory now complete? Two reviews each found one missed entry
   point that the other did not. Assume a third exists and go looking.
5. **Commit order.** Each commit is claimed to leave the toolkit in a working state. Verify that,
   particularly commits 1 and 6.
6. **Over- or under-specification.** This is one researcher's personal toolkit. Flag anything
   over-engineered for that, and anything so under-specified that implementation would be guesswork.

## Deliverable

A single reply file, `codex_to_claude/001_skill-extraction-plan-review_reply.md`, containing:

- **VERDICT** — one paragraph: build it / build it with changes / rethink a named part.
- **BLOCKING** — numbered. Defects that must be fixed before commit 1. Each with `file:line`, the
  specific problem, and the concrete alternative. If none, say so plainly.
- **WORTH FIXING** — numbered, same form.
- **WHAT THE TWO REVIEWS MISSED** — the part with the most value. Anything you found that is not
  already marked `v2` in the plan.
- **WHAT SURVIVES** — brief. Only decisions you actively endorse after checking them against the
  files, so we know what held up.

## Constraints

See `channels/README.md`. Additionally: do not edit any file in this repo — the reply file is the
only output. Where you disagree with a decision, give the alternative, not just the objection. If a
claim in the plan cites a line number, check it; two of v1's citations were wrong.
