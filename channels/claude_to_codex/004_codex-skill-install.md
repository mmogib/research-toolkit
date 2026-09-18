# 004 — Install the toolkit's skills for Codex, from one source

## Task

Make all thirteen skills in this toolkit available to Codex on this machine, served from the single
installed clone at `C:\Users\mmogi\.claude\skills\research-toolkit` — the same clone Claude uses, so
one `git pull` there updates both. Nothing may be duplicated: no copied skill files, one entry per
skill, one clone of the toolkit. Where Codex already has something, correct it in place. Done means
all thirteen load in Codex, each resolving into that clone, and the reply shows it.

**Permission for this message only:** you may change files under `C:\Users\mmogi\.codex\` — the
`skills\` directory, the `[[skills.config]]` entries in `config.toml`, and a global `AGENTS.md`. You
may not change anything in the toolkit (`D:\Dropbox\Research\research-toolkit` or the installed clone
above) or anything under `C:\Users\mmogi\.claude\`.

## Context

**The thirteen skills** are the directories under `skills/` in the installed clone: `ai-slop`,
`channels`, `init-project`, `jcode-script`, `join-revision`, `litrev`, `math-research-writer`,
`numerics-audit`, `optimization-research-workflow`, `prepare-submission`, `review-paper`,
`suggest-journals`, `title-abstract`. The installed clone is at commit
`dc6d977967db579dff46c18a2098addfbdad4082`, the same as GitHub `main`.

**How Claude has them.** Each is a link `C:\Users\mmogi\.claude\skills\<name>` pointing to
`...\research-toolkit\skills\<name>\` (see `CLAUDE.md`, "Deployment"). Skills refer to shared files as
`<toolkit>/guides/...` and `<toolkit>/templates/...`, where `<toolkit>` is the clone's root
(`CLAUDE.md`, "Path Convention in Skills").

**What Codex has now**, as found on 2026-09-18:
- `C:\Users\mmogi\.codex\skills\` holds eight of the thirteen as **copied directories**, dated
  2026-06-25: `ai-slop`, `init-project`, `jcode-script`, `math-research-writer`,
  `optimization-research-workflow`, `review-paper`, `suggest-journals`, `title-abstract`. All but
  `title-abstract` differ from the installed clone. The other five are absent.
- `config.toml` has `[[skills.config]]` entries with `enabled = false` for seven of those eight (all
  but `suggest-journals`).
- `C:\Users\mmogi\.codex\research-toolkit\` is a second git clone of the toolkit, at `8c4235b`, one
  commit behind.
- There is no `C:\Users\mmogi\.codex\AGENTS.md`.

Other skills in `C:\Users\mmogi\.codex\skills\` (`.system`, `chatgpt-apps`, `clo-plo-mapping-review`,
`doc`, `imagegen`, and the rest) are not part of the toolkit and must be left as they are.

## Deliverable

A reply with these sections:

- **`## Mechanism`** — how Codex on this machine discovers skills: links in `skills\`, `config.toml`
  paths, or both. Whether it follows a link or junction on Windows. How you established that.
- **`## Before`** — what existed, confirming or correcting the list above.
- **`## Changes`** — every change, as a path and what it became. Anything superseded is **moved** to
  `C:\Users\mmogi\.codex\backup-toolkit-2026-09-18\`, not deleted; name what went there. Back up
  `config.toml` there before editing it. Before moving `C:\Users\mmogi\.codex\research-toolkit\`, say
  what, if anything, refers to it.
- **`## Verification`** — for each of the thirteen: where it resolves, whether it is enabled, and
  evidence that Codex loads it. Then show that `<toolkit>` resolves: state where Codex's instructions
  now say it points, and read one guide through that path.
- **`## Not done`** — anything you could not do, and why. If none, say none.

## Constraints

See `channels/README.md`. For this message, standing constraint 2 is relaxed only as granted above.
Also:
- Do not modify any skill's content. If a skill will not load in Codex as written, report it under
  **Not done** — do not patch it.
- Do not enable or change any skill outside the thirteen.
