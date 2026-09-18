# Reply to 004 — Install the toolkit's skills for Codex, from one source

## Mechanism

Codex 0.154.0 supports user skills under `$HOME/.agents/skills` and follows linked skill directories. This installation now uses one Windows directory junction:

`C:\Users\mmogi\.agents\skills\research-toolkit` → `C:\Users\mmogi\.claude\skills\research-toolkit\skills`

The junction exposes the thirteen child skill directories directly to Codex while keeping every file in the canonical installed clone. Windows follows the junction to the target; I checked that every exposed `SKILL.md` is readable and has the same SHA-256 hash as its counterpart in the target. A fresh `codex exec` process then reported those thirteen `.agents` catalog paths and no duplicate toolkit names. This agrees with the [Codex skills documentation](https://developers.openai.com/codex/skills), which identifies `$HOME/.agents/skills` as the user scope and permits symlinked skill directories.

`C:\Users\mmogi\.codex\config.toml` does not supply source paths. Its `[[skills.config]]` entries are enable/disable overrides for already-discovered skills. I removed the seven toolkit disable overrides. No non-toolkit override was changed; there were no other `[[skills.config]]` blocks.

## Before

The supplied inventory was correct, with one important addition:

- The canonical installed clone was clean at `dc6d977967db579dff46c18a2098addfbdad4082`, equal to its local `origin/main`.
- `C:\Users\mmogi\.codex\research-toolkit` was a clean second clone at `8c4235bb06df5bb4a4b328ede638c3f873174c48`, exactly one ancestor commit behind the canonical clone.
- `C:\Users\mmogi\.agents\skills\research-toolkit` already existed as a junction, but it targeted that stale second clone's `skills` directory. This was the only live filesystem reference I found to the second clone; `config.toml` contained no source path to it.
- `C:\Users\mmogi\.codex\skills` contained the eight listed copied toolkit directories. Seven were disabled by `skills.config`; `suggest-journals` was not, so it could appear in addition to the copy exposed through the old junction.
- There was no global `C:\Users\mmogi\.codex\AGENTS.md` or `AGENTS.override.md`.

## Changes

- Created `C:\Users\mmogi\.codex\backup-toolkit-2026-09-18\config.toml` before editing. Its SHA-256 is `442BD32820BDFF14EDD0318152F8D677BFE2B3D525F00623A8038B4A5C12DC5B`, equal to the pre-edit file.
- Removed all seven toolkit `[[skills.config]]` blocks from `C:\Users\mmogi\.codex\config.toml`. Zero `skills.config` blocks remain.
- Retargeted `C:\Users\mmogi\.agents\skills\research-toolkit` directly to `C:\Users\mmogi\.claude\skills\research-toolkit\skills`.
- Deleted the eight copied toolkit directories from `C:\Users\mmogi\.codex\skills`: `ai-slop`, `init-project`, `jcode-script`, `math-research-writer`, `optimization-research-workflow`, `review-paper`, `suggest-journals`, and `title-abstract`.
- Deleted the stale clone `C:\Users\mmogi\.codex\research-toolkit` after retargeting its only live reference.
- Created `C:\Users\mmogi\.codex\AGENTS.md`. It defines `<toolkit>` as `C:\Users\mmogi\.claude\skills\research-toolkit`, prohibits copied toolkit skills under `.codex\skills`, and records ongoing shared ownership: **include Codex in development and deployment of every new toolkit skill and every update to an existing skill. Claude owns the canonical clone and Claude-side exposure; Codex owns Codex-side compatibility review, discovery/configuration, and fresh-session verification.**

The deletion of the copied skills and stale clone deliberately supersedes 004's original instruction to move them into the backup directory. After discussion, the user explicitly chose deletion to prevent Codex from rediscovering duplicate `SKILL.md` files. Before deleting, I established that the second clone was clean and recoverable from Git, and that all 24 files in the eight copied directories matched blobs reachable in the repository's Git history. The backup directory therefore contains only the configuration backup and no skill files.

No skill content, shared guide, template, canonical-clone file, or non-toolkit skill was modified.

## Verification

Let `D = C:\Users\mmogi\.agents\skills\research-toolkit` and `T = C:\Users\mmogi\.claude\skills\research-toolkit\skills`. `D` is a junction whose target is exactly `T`.

| Skill | Codex catalog path | Resolves to | Enabled | Fresh Codex load |
|---|---|---|---|---|
| `ai-slop` | `D\ai-slop\SKILL.md` | `T\ai-slop\SKILL.md` | yes | yes |
| `channels` | `D\channels\SKILL.md` | `T\channels\SKILL.md` | yes | yes |
| `init-project` | `D\init-project\SKILL.md` | `T\init-project\SKILL.md` | yes | yes |
| `jcode-script` | `D\jcode-script\SKILL.md` | `T\jcode-script\SKILL.md` | yes | yes |
| `join-revision` | `D\join-revision\SKILL.md` | `T\join-revision\SKILL.md` | yes | yes |
| `litrev` | `D\litrev\SKILL.md` | `T\litrev\SKILL.md` | yes | yes |
| `math-research-writer` | `D\math-research-writer\SKILL.md` | `T\math-research-writer\SKILL.md` | yes | yes |
| `numerics-audit` | `D\numerics-audit\SKILL.md` | `T\numerics-audit\SKILL.md` | yes | yes |
| `optimization-research-workflow` | `D\optimization-research-workflow\SKILL.md` | `T\optimization-research-workflow\SKILL.md` | yes | yes |
| `prepare-submission` | `D\prepare-submission\SKILL.md` | `T\prepare-submission\SKILL.md` | yes | yes |
| `review-paper` | `D\review-paper\SKILL.md` | `T\review-paper\SKILL.md` | yes | yes |
| `suggest-journals` | `D\suggest-journals\SKILL.md` | `T\suggest-journals\SKILL.md` | yes | yes |
| `title-abstract` | `D\title-abstract\SKILL.md` | `T\title-abstract\SKILL.md` | yes | yes |

For each row, the catalog file was readable and its SHA-256 matched the canonical target. “Enabled” is established by zero remaining `skills.config` disable blocks. For load evidence, a new ephemeral `codex exec --strict-config` process exited 0 and returned `count: 13`, the exact thirteen names above, `duplicate_names: []`, and `all_source_paths_begin_expected_prefix: true` for `C:\Users\mmogi\.agents\skills\research-toolkit\`.

The same fresh-process check also proved the edited config parses. The canonical clone remains clean at `dc6d977967db579dff46c18a2098addfbdad4082`; the stale clone and all eight `.codex\skills` copies are absent; the backup contains zero `SKILL.md` files.

For shared resources, global Codex instructions now say `<toolkit>` resolves to `C:\Users\mmogi\.claude\skills\research-toolkit`. Reading `<toolkit>\guides\project-hub.md` through that path succeeded; its first heading is `# The Project Hub — root CLAUDE.md and the notes discipline`.

## Not done

None.
