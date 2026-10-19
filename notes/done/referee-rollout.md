# `/referee` rollout

The release record for adding `/referee` and the four sibling changes it needs. The procedure is
`notes/new-skill/handoff-prompt.md`; this note records what happened. Never staged in the six
release commits.

## Starting point

- Starting SHA, both clones: `42466c7b8f3874b3f27bc679b59f9f8471320ea3`
  (development `D:\Dropbox\Research\research-toolkit`, installed `C:\Users\mmogi\.claude\skills\research-toolkit`).
- Installed clone: empty `git status --porcelain=v1 --untracked-files=all --ignored`.
- Development clone: tracked files clean; the only untracked path was `notes/new-skill/`.
- No Dropbox conflicted copies in either clone, before applying.
- Absent before applying: `skills/referee/`, `templates/CLAUDE-referee.md.template`,
  `~/.claude/skills/referee`, and `skills/referee/` in the installed clone.
- Codex exposure: `C:\Users\mmogi\.agents\skills\research-toolkit` is a junction to
  `C:\Users\mmogi\.claude\skills\research-toolkit\skills` (thirteen directories). `~/.codex/skills/`
  holds no toolkit skill.
- Global instructions: `~/.claude/CLAUDE.md` does not exist. `~/.codex/AGENTS.md` assigns ownership
  as the handoff and this repository's `CLAUDE.md` do. No conflict found.

### Package (`notes/new-skill/`), SHA-256

```
37a55b394eb450b1da8ee6bb354a0ae6cd9ef9520333d24406aa101028188bb8  referee/SKILL.md
9c0cbdfe4f54b16945d11579ff5a927f9724800529da73c09f43b21b10dca6bf  referee/references/review-plan-template.md
4c744f20369ce57f710a8a84e27c0d6e969c429fb45b1cd280716afd2d7b6c5e  referee/references/report-conventions.md
af32260720efd0506f5decb6cc2537979d56cf274b04fc4646c1552251924b2d  referee/references/report-template.tex
89834f510eaed24fae03523366e0f02127f53a9a96978809e6e6f8b4e022e096  referee/references/journals/aims.md
2e05999e494de799469615b7e1c7a4a9406d07c5c1fda37c95d150a504aadde6  referee/references/later-rounds.md
57a62fb67ff5bb9f6b56acf963fe31cc0f807e67e84df3b1f9002aa80efe1df6  templates/CLAUDE-referee.md.template
cb0b5a9572348af6033284fce9151b6a8ebfab69873ce0e534cb0f711bbe0689  sibling-changes.md
c3800863a7c9f47de09496d98f117d33bcd26628c88f98d73bef95582ae70741  handoff-prompt.md
```

## Apply (step 1)

- **Old texts, at `42466c7`:** all 43 edits in `sibling-changes.md` (IP-1–12, CH-1a/b, CH-2–4,
  PR-1–5, PR-6a/b, LR-1, LR-2, LR-3a/b, LR-4, LR-5, LN-1, LN-2a/b, LN-3, NA-1a–c, NA-2a/b, NA-3–6)
  occur exactly once in their files. Counted literally with awk from a transcription that was itself
  checked against `sibling-changes.md`.
- **Applied** in order: `/litrev`, `/channels`, `/numerics-audit`, `/init-project`. Afterwards all 43
  `New:` texts, extracted mechanically from `sibling-changes.md`, occur exactly once in the edited
  files. Every replaced old text is gone. The 13 still present are the ones whose new text contains
  the old (insertions after an anchor).
- **"Mohammed" in the four skills** after applying: only the two exclusions remain
  (`init-project/SKILL.md` identity string and "(Mohammed only)").
- **Copied** `templates/CLAUDE-referee.md.template` and `referee/` → `skills/referee/`. Byte-identical
  to the package.
- **Wiring:** `CLAUDE.md` (four counts thirteen → fourteen; `/referee` entry after `/join-revision`;
  one referee clause each in the `/init-project`, `/numerics-audit`, `/channels`, `/litrev` entries;
  `/channels` "with the user relaying"; template row). `README.md` (mklink line, templates tree,
  skills tree, Skills table). `skills/join-revision/SKILL.md` (one row, with backticks to match its
  table).
- **Extra paths:** none. Live counts exist only in `CLAUDE.md`. The other "what this is not" tables
  (`/channels`, `/litrev`, `/numerics-audit`, `/prepare-submission`) list alternatives to their own
  job; `/referee` is not one. `/numerics-audit`'s table does not list its hosts (`/join-revision` is
  absent too). `/review-paper` has no such table. Historical counts in `channels/` and `notes/done/`
  left as they are.
- **Counts after wiring:** 14 skill directories; 14 entries in `CLAUDE.md`'s list, 14 README table
  rows, 14 tree entries, 14 mklink lines; names identical to `skills/`.

## Static checks (step 2)

- `skills/referee/SKILL.md` frontmatter: opening and closing `---`; `name: referee` matches the
  directory; description is a plain multi-line scalar with no `: ` inside, the same shape as the
  siblings. **Pass.**
- Every path the skill names exists: its five `references/` files,
  `<toolkit>/templates/CLAUDE-referee.md.template`, `<toolkit>/guides/project-hub.md`, the four sibling
  `SKILL.md` files and the sibling references they use. No `../` paths in the new skill or template.
  **Pass.**
- Each edited sibling file read in context around every edit (full diff). **Pass.**
- **`invocation: user`:**
  - *Claude Code:* not a recognized field. The skills docs (code.claude.com/docs/en/skills) list
    `disable-model-invocation` (true: only the user can invoke; description removed from context) and
    `user-invocable` (false: hidden from the `/` menu, model-only). Unrecognized fields are ignored
    without error. Behaviour on this machine agrees: every toolkit skill carries `invocation: user`, and
    their descriptions are in the model's available-skills list in this session, so the model can
    invoke them. Caveat: the docs wording came through a summarizing fetch and was not read verbatim.
  - *Codex:* not recognized. `codex-rs/skills/src/parser.rs` (tag `rust-v0.163.0`, matching the
    installed `codex-cli 0.163.0`) reads only `name`, `description`, and `metadata.short-description`,
    without `deny_unknown_fields`; upstream test `repairs_unrecognized_frontmatter_fields_that_need_quotes`
    shows extra keys dropped. Codex's control is `agents/openai.yaml` →
    `policy: allow_implicit_invocation: false` (explicit `$skill` still works). UNVERIFIED: a live Codex
    session showing no message for the field.
  - No change made (toolkit-wide convention). Recorded under *For later*.

## Candidate identity

### v1 — as applied, before tests (SHA-256)

```
07713d7ebe3b722d4fa6d4bce55c05eaf5e1eff68a1c8ed4f3b1f3efcb86f877  skills/litrev/SKILL.md
5deceec101979877d3ed506d880773824c6640b4792fab26486b360ed88e231f  skills/litrev/references/litrev-notes.md
1e85cac072aed4e4f2af674c3feb23f3aa29d6ebecc7ea526af2bf2ffeb12ddd  skills/channels/SKILL.md
aa55109150ad8baf716df28c9e19a53c23bb7a57812e72a332e2f91814a4592d  skills/channels/references/channels-protocol.md
8c0a60afd23234ff5a89e33f5ab4e8250ada0188736f467452a361a29d2db334  skills/numerics-audit/SKILL.md
a12d29cce8221d93d39cc6500936befdbd7241e12901b8a5f34b267489f8ac0e  skills/numerics-audit/references/audit-procedure.md
b56f8ce9d31f8df967e1046843ff4d5f7948d4904483f0ab9c936992527ca8b7  skills/init-project/SKILL.md
57a62fb67ff5bb9f6b56acf963fe31cc0f807e67e84df3b1f9002aa80efe1df6  templates/CLAUDE-referee.md.template
37a55b394eb450b1da8ee6bb354a0ae6cd9ef9520333d24406aa101028188bb8  skills/referee/SKILL.md
9c0cbdfe4f54b16945d11579ff5a927f9724800529da73c09f43b21b10dca6bf  skills/referee/references/review-plan-template.md
4c744f20369ce57f710a8a84e27c0d6e969c429fb45b1cd280716afd2d7b6c5e  skills/referee/references/report-conventions.md
af32260720efd0506f5decb6cc2537979d56cf274b04fc4646c1552251924b2d  skills/referee/references/report-template.tex
2e05999e494de799469615b7e1c7a4a9406d07c5c1fda37c95d150a504aadde6  skills/referee/references/later-rounds.md
89834f510eaed24fae03523366e0f02127f53a9a96978809e6e6f8b4e022e096  skills/referee/references/journals/aims.md
e42734fbddfc55a6ccbdb6b9536e127c8ec2e5f39f42e6e8ad64a8ed9a8c8b61  CLAUDE.md
1a8a74a9138a7ab8c87ea6819d03a1ce4f0d1b531746c9fd3cbd5e9c65994dad  README.md
27e615771cc2e1442d4e2f8a18c7ab809199307f7ad21fa037baf3468f8c88a3  skills/join-revision/SKILL.md
```

### v2 — after T3, approved by the user (SHA-256)

Only `skills/referee/SKILL.md` changes; the other sixteen files are as v1.

```
5b643e12c0bd770328863ddd276d0a48ff095f59d151c9f775b7cedcc912a41b  skills/referee/SKILL.md
```

Two sentences reworded for T3's two failures:
- Phase 1, step 2: "raise it with the user before the affected step" → "raise it with the user and
  wait for their answer before the affected step. When the terms restrict AI tools, even reading
  the title or abstract counts."
- Phase 3, `/channels` paragraph: "Every value is stated for the current round, so …" → "Write every
  value with `N` (`report/round-N/`, `paper/round-N/`), never a fixed round number, so …".

Affected checks rerun on fresh copies: E1 (Claude main, Codex reviewer; both sentences) and T3
(Codex main, Claude Code reviewer; run by the user). Guard re-baselined with v2.

### v3 — after Codex review 005, approved by the user (SHA-256)

`skills/referee/SKILL.md` and `CLAUDE.md` change; the other fifteen files are as v1.

```
b605ad7955b30ca71b7b67e20b7039b0ea76c18ea5bf57e69f75b2078dfd4b2a  skills/referee/SKILL.md
57e50a8757a5e88b0b67ebc104e211c88285dc89fdb3747df8446bd57cb5f2b1  CLAUDE.md
```

- `skills/referee/SKILL.md`, Phase 1 "Document operations": adds "Everything they produce from the
  manuscript (text copies, page images, a tool's working or configuration files) stays inside the
  review project under `notes/`, never in a system temporary folder; remove intermediates when
  done."
- `skills/referee/SKILL.md`, Phase 3 `/channels` paragraph: adds "and write the round bindings below
  into the protocol itself, not only the hub"; the reading-scope value becomes "the submitted
  material in `paper/round-N/` for the round N the message names, plus the files and source PDFs
  that message names".
- `CLAUDE.md`, `/channels` entry: "no direct link to Claude" → "no direct link to the main agent".

Guard re-baselined with v3.

## Tests (step 3)

### Setup

- **Location** (given by the user): `D:\Dropbox\Research\Reveiwing\2507.00617v2`, holding one public
  arXiv preprint in `paper/`. That folder is left untouched (PDF SHA-256 `41383668…10ec`). Each test
  runs in its own copy under `…\2507.00617v2\_tests\`. The neighbouring folders in `Reveiwing\` look
  like real reviews; they are never opened, and every test session has explicit read-deny rules for
  them.
- **Material:** the public preprint is the round-1 manuscript (copied as `AIC-2026-0417.pdf`).
  Everything else is invented: the journal (*Annals of Iterative Computation*), ID, emails, form text,
  the round-2 response letter, the earlier report, mid-review notes for tests 7–8, and all test-10
  projects (invented papers Alpha2019, Beta2021, Gamma2015). PDFs rendered by headless Edge with an
  isolated profile. Test 9 uses a DjVu stand-in (DjVu header, random body): no installed tool reads
  DjVu (ImageMagick lists the format with no coder), while Word would convert a `.docx` and Python is
  installed.
- **Sessions** (user's choice): headless `claude -p`, Claude Code 2.1.302, working directory = the
  test copy, `--permission-mode dontAsk` with an allowlist: read the copy and both toolkit roots;
  write only inside the copy; Bash limited to listing, hashing, `mkdir`, and installed document tools.
  Denied: the Skill tool (so no installed sibling loads by discovery), web, subagents, PowerShell,
  the real review folders, writes to either toolkit root or global configuration. Smoke-tested on
  dummy targets: dummy read/write denials held; a write into the development clone was refused;
  `python -c`, `pip`, `julia`, `cp` refused (`python --version` passes as a read-only probe).
  Follow-up turns via `--resume`. Harness and logs: scratchpad `harness/`, `runs/`.
- **Authentication** (user's choice after the API key ran out): from the re-runs on, each test
  command runs with `ANTHROPIC_API_KEY` unset, so headless sessions use the user's claude.ai login
  (`claude auth status`: `claude.ai`, Max). It also unsets the variables inherited from the
  maintenance session (`CLAUDECODE`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SESSION_ID`, the
  messaging socket and token, `CLAUDE_PID`, `CLAUDE_EFFORT`, …), which had marked the first runs as
  children of this session. No configuration changed. T5 and T7 ran before this change.
- **Guard** after every test: candidate files, installed clone HEAD and status, `~/.claude/settings.json`,
  `~/.codex/config.toml`, `~/.codex/AGENTS.md`, `~/.claude/skills/` and `~/.agents/skills/` entries,
  `~/.codex/skills/` — compared with a baseline taken before the first test.
- **Prompt** for tests 2–9: the handoff's text verbatim, with `<development clone>` =
  `D:\Dropbox\Research\research-toolkit`, then the user's request.
- **Scripted user answers** (given only when asked): no referee identity; journal, ID, type and due
  date as in the email; PDFs in `…\_tests\library\` (empty); Claude Code main agent; external
  reviewer none (Codex in E1); form as in `review-form.txt`; LaTeX compiled by the user on Overleaf;
  no first impressions; the accounts used do not retain or train on the manuscript.

### Expected outcomes (written before running)

- **T2 — new first round (Claude; again with Codex as main agent).** Phase 0 finds no root
  `CLAUDE.md`, reports *new review, round 1*, and confirms before acting. Phase 1 reads the email and
  form, raises the AI terms before the manuscript is processed, and reads only title, abstract, and
  headings. Phase 2 asks for the PDF locations rather than assuming one. Phase 3 follows
  `/init-project`'s referee arrangement from the development clone, takes a `paper/` inventory before
  writing, and creates only: the referee hub (with a `**Review**:` line; Phase "Round 1 — preparing";
  no Referee line; Review form line naming the email's folder, no link; no unused overlay; no template
  comments; no `[…]` placeholder left — `<toolkit>` tokens are conventions, not placeholders),
  `report/round-1/`, `notes/`, `notes/done/`, and `notes/litrev/README.md` (referee variant, location
  and request list substituted). Not created: `channels/`, `refs/`, `jcode/`, `main.tex`, any `.bib`,
  anything under `paper/`; `AGENTS.md` only in the Codex run. `paper/` inventory unchanged. Skills
  read from the development clone only.
- **T3 — Codex main, Claude reviewer (Codex).** As T2, plus `channels/` with `codex_to_claude/`
  (Codex's messages) and `claude_to_codex/` (Claude's replies); README roles: main Codex, helper
  Claude; reply destination `claude_to_codex/`; reading scope, confidentiality, and no-execution as
  numbered standing constraints for Claude; frozen artifact = the round's deliverables with the round
  binding; findings destination `notes/review-findings.md`. Hub overlays applied with these names.
  `AGENTS.md` holding the one-line hub pointer.
- **T4 — no external reviewer.** As T2. No `channels/`, no Rule 10, no reviewer Roles entry, no
  channels Structure line, no `AGENTS.md`.
- **E1 (extra) — Claude main, Codex reviewer.** As T2, plus `channels/` with the default labels
  `claude_to_codex/` and `codex_to_claude/` and the same protocol content as T3 with the roles
  reversed; hub overlays applied; no `AGENTS.md`.
- **T5 — root `CLAUDE.md` that is not a referee hub** (an unrelated research hub that does have
  `## Active notes`). Phase 0 reads it, reports that it is not a referee hub (no `**Review**:` line),
  and stops to ask. Nothing is written; the whole copy's inventory is unchanged.
- **T6 — later round, only an earlier report.** Phase 0 reports *later round, N = 2*, with no hub and
  no `paper/round-1/`, and confirms. Phases 1–3 run in full for round 2. Created: hub (Phase
  "Round 2 — preparing"), `report/round-2/`, `notes/`, `notes/done/`, `notes/litrev/README.md`.
  `report/round-1/` and `paper/` unchanged; no `paper/round-1/` created. The brief names
  `report/round-1/referee-report-AIC-2026-0417.pdf` as the baseline. Reviewer 2's requests are
  context only.
- **T7 — freeze.** Continuing state, round 1. The session checks the channels index, finds 001 open,
  and does not edit `report/round-1/report.tex` (hash unchanged). The requested M2 change is recorded
  as pending in `notes/review-findings.md`, to be applied in one batch once 001's reply is verified
  and decided. No file under `channels/` changes.
- **T8 — `/numerics-audit` under the referee arrangement.** Reads `/numerics-audit` and its
  `audit-procedure.md` from the development clone; runs `referee` mode with the host arrangement.
  New Track E findings go to `notes/review-findings.md` as pending and anchored; verdicts are given
  against ledger IDs C1–C14 (a new claim gets a new ID marked new), not a fresh inventory; sources it
  cannot open ([14], [36]) are pending evidence and requested, not findings against the authors;
  quoted speedups recomputed. `report/round-1/report.tex` unchanged; no numbered report points;
  `paper/` unchanged; nothing run.
- **T9 — no usable converter, Python declined.** The session cannot read the DjVu file. It may
  inspect it with installed document tools; it asks before any Python; when Python is declined, it
  asks for an accessible version (or page images). No install attempt, no Python run, `paper/`
  unchanged.
- **T10 — provider regression** (installed root vs development root, same inputs). Outputs match
  except "the user" for "Mohammed" in the texts the edits name:
  - `/init-project` new: same tree and hub shape; `paper/temp_refs_to_add.bib` header comment differs
    as IP-6. Adopt: same backup, hub, extracted notes, directories; `jcode/` untouched. Already a
    hub: both stop.
  - `/channels` default: `claude_to_codex/`, `codex_to_claude/`; README identical except PR-3 and
    PR-6's "the user". Development only: main Codex/helper Claude gives `codex_to_claude/` and
    `claude_to_codex/` with roles reversed; both labelled `codex` is refused and nothing is created.
  - `/litrev` `audit-manuscript`: same discovery table, three-key inventory, reading list, notes for
    Alpha2019 and Beta2021, a download request for Gamma2015, request file
    `paper/temp_refs_to_add.bib`; README from the default block. Both should flag Beta2021's
    "without any Lipschitz assumption" and "recommended" σ values. `build-from-reading`: only
    Alpha2019 and Beta2021 cited; Gamma2015 blocked.
  - `/numerics-audit`, four modes each: sinks, edit policies, handoffs, and disposition formats as
    the mode table; decision owner "the user" (development) vs "Mohammed" (installed) for three
    modes; standalone `referee` gives numbered report points and edits nothing.

### Results

- **T5 — PASS.** Session `36675ba1…`, 1 turn. Read the dev-clone `referee/SKILL.md` and the root
  `CLAUDE.md`; reported it is a research hub without a `**Review**:` line; stopped and offered a fresh
  folder or an explicit migration, never an overwrite. Whole-copy inventory before and after
  identical. (It also flagged a possible conflict of interest between the hub's topic and the review —
  sensible, unprompted.)
- **T7 — PASS.** Session `7113a739…`, 1 turn. Read `channels/README.md` and the index, found 001 open
  for round 1, and did not edit `report/round-1/report.tex` (hash unchanged, by its own check and by
  inventory). Recorded the request as F9 in `notes/review-findings.md`, added a "Pending batch" to
  `notes/review-synthesis.md`, updated the hub's Next line, and offered the user the choice of
  lifting the freeze. Changed files: those three only; `channels/`, `report/`, `paper/` byte-identical.
  Dev-clone hashes it reported match candidate v1. Its remark that the notes carry dates later than
  today is a fixture artefact.
- **T5 clean re-run (claude.ai login, no inherited variables) — PASS.** Session `749ef4ad…`. Same
  behaviour: stopped at the unrelated hub, proposed a new folder or an approved migration plan.
  Whole-copy inventory unchanged.
- **T7 clean re-run, fresh copy `t07r-claude` — PASS.** Session `0c120f07…`. Found 001 open; queued
  the M2 change (now split into (a) and (b), per the report conventions) in
  `notes/review-synthesis.md` and F2 in `notes/review-findings.md`; hub Next line updated; offered to
  lift the freeze only on the user's word. Changed: `CLAUDE.md`, `notes/review-findings.md`,
  `notes/review-synthesis.md`. `report/`, `channels/`, `paper/` byte-identical. Read `referee/SKILL.md`,
  `referee/references/report-conventions.md`, `channels/SKILL.md` from the dev clone (v1 hashes
  `37a55b39…`, `4c744f20…`, `1e85cac0…`); it could not hash them itself after one refused compound
  command. (The first T7 copy, `t07-claude`, was removed after its run; Dropbox briefly held one
  empty folder.)
- **T2 (Claude) — PASS.** Session `d2d07e34…`, 2 turns. Turn 1: new review, round 1, confirmed
  first; the journal's AI terms raised before the manuscript was opened; setup questions asked (PDF
  location asked, not assumed). Turn 2 (confirmation + scripted answers): scaffold through
  `/init-project`'s referee arrangement, then the full read, text copy, brief, map, and plan draft;
  stopped for plan approval (Phase 5). Created: `CLAUDE.md`, `report/round-1/`, `notes/done/`,
  `notes/litrev/README.md` (referee variant, library folder substituted), and the Phase 4–5 notes.
  Hub: `**Review**:` line, Phase "Round 1 — preparing", no Referee line, Review form line without a
  link, no template comments, no `[…]` placeholder, no overlay. Absent: `AGENTS.md`, `channels/`,
  `refs/`, `jcode/`, `main.tex`, `.bib`. `paper/` unchanged (inventory). Dev-clone files only
  (16 toolkit files, hashes listed in its brief).
- **T4 — PASS.** Session `de7b45a5…`, 2 turns. As T2. No `channels/`, no Rule 10, no reviewer Roles
  entry, no channels Structure line, no `AGENTS.md`. `paper/` unchanged.
- **E1 (extra) — PASS.** Session `e111d890…`, 2 turns. As T2, plus `channels/` with
  `claude_to_codex/`, `codex_to_claude/`, and a README whose standing constraints for Codex add the
  reading scope (6), confidentiality (7), and no execution (8); freeze bound to the round each message
  names, with "nothing is frozen until the deliverables exist"; findings to `notes/review-findings.md`
  (`notes/round-N-check.md` in a later round). Hub overlays applied: channels Structure line, Codex
  Roles entry, Rule 4 exception, Rule 10. No `AGENTS.md`. `paper/` unchanged. A leftover
  `notes/manuscript-round-1.raw.txt` is a harness artefact (its `rm` was refused).
- **T6 — PASS.** Session `4507f484…`, 2 turns. Later round, N = 2, no hub, no `paper/round-1/`.
  Created: hub (Phase "Round 2 — preparing"), `report/round-2/`, `notes/done/`, referee litrev README,
  brief with a "Baseline (the referee's own submitted report)" section, `notes/round-2-check.md` with
  rows R1-M1 … R1-t2, map, plan, findings. `report/round-1/` and `paper/` unchanged; no
  `paper/round-1/` created. It judged each request against the revised file, not the letter, and
  found none of the promised changes (correct: the fixture's "revision" is the original PDF), and it
  re-checked the baseline itself, catching three inaccuracies in the invented round-1 report.
  Reviewer 2's requests used as context only.
- **T8 — PASS.** Session `4ad6b016…`, 1 turn. Read `/numerics-audit` and `audit-procedure.md` from
  the dev clone. Ten Track E findings (F5–F15) written to `notes/review-findings.md` as open, anchored,
  with proposed severities left to the user; a verdict for each of C1–C14, and C15–C26 added to the
  ledger marked "new"; [14] and [36] recorded in the plan's "PDFs needed" as pending evidence; all 84
  table rows recomputed. No numbered report points. Changed: `CLAUDE.md`, `notes/manuscript-map.md`,
  `notes/review-findings.md`, `notes/review-plan.md`. `report/round-1/report.tex` and `paper/`
  byte-identical. (It also found that my fixture's page anchors are off by one; fixture artefact.)
- **T9 — PASS.** Session `21f4e5a5…`, 2 turns. Could not read the DjVu file; probed only installed
  tools (`which`, `file`, `magick identify` → "no decode delegate"); never proposed or ran Python;
  with Python declined (turn 2), asked for a PDF or page images and stopped before writing anything.
  No install or Python command in either turn's log. Whole-copy inventory unchanged. Dev-clone
  hashes reported = candidate v1.
- **Guard** after all referee tests: OK.
- **Observation for the review (all three scaffolding runs, T2, T4, E1; T2 with Codex too):** none paused separately at
  `/init-project`'s "Detect, report, and confirm with the user" before writing the hub; each treated
  `/referee`'s Phase 0 confirmation and the setup answers as that confirmation. No file existed to be
  overwritten, so no expected outcome failed, but the two skills' wording does not say whether one
  confirmation covers both.
- **T10 `/channels` — PASS (4 cases).** Default scaffold (no host values; user answers: reviewer
  Codex, frozen `paper/main.tex`, findings `notes/review-findings.md`): installed and dev roots both
  create `channels/README.md`, `claude_to_codex/`, `codex_to_claude/`; the two READMEs differ in
  exactly two lines, PR-3 ("the user relays") and PR-6 ("after the user accepts"). Dev only: main
  Codex, helper Claude → `codex_to_claude/` (Codex's messages), `claude_to_codex/` (Claude's
  replies), every role line reversed; both labelled `codex` → refused, nothing created. Each session
  read only its own root (`channels/SKILL.md`, `channels-protocol.md`, `project-hub.md`).
- **T10 `/init-project` already a hub — PASS.** Both roots stop at Adopt's safety requirement 1;
  copies unchanged.
- **T10 `/init-project` new project — PASS.** Identical file trees (14 files). Differences: the
  `paper/temp_refs_to_add.bib` header ("the user" vs "Mohammed", IP-6) and `notes/litrev/README.md`
  (two lines, LN-2), as expected; each hub names its own root; the wording of the blank Now/Next and
  overview placeholders varies. Generated Julia files vary from run to run (e.g. `benchmark.jl`), but
  the edits change no code-generation instruction (Steps 4–5 differ only in IP-10's tree comment and
  IP-11's `refs/` wording), so this is ordinary generation variance. "Mohammed" in both hubs comes
  from `templates/CLAUDE.md.template`'s authorship default, out of scope by design.
- **T10 `/init-project` adopt — PASS.** Both roots stop at the approval gate with nothing written
  and ask the same three questions; given the same answers (approve; A. Tester as lead; no template
  copy), both write a verbatim backup `notes/done/CLAUDE_pre_hub.md` (byte-identical to the legacy
  root), a hub with `## Active notes`, `notes/manuscript-map.md`, two topic notes,
  `notes/litrev/README.md`, `refs/`; `jcode/` and `paper/` unchanged. Differences: the litrev README
  (installed: the released "Mohammed" replaced by "A. Tester", as its approved plan listed; dev: "the
  user" from LN-2), the hub title, and one topic note's name (`convergence-proofs` vs
  `convergence-analysis`) — generation variance.
- **T10 `/litrev` `audit-manuscript` — PASS.** Both roots: discovery from `paper/main.tex`, three
  keys, reading list of three; Alpha2019 and Beta2021 read from `refs/` via the `.bib` index and
  noted; Gamma2015 not found, no note written, requested from the user; README created from the
  default block; coverage leads written to `paper/temp_refs_to_add.bib` as UNVERIFIED LEADs. Both flag
  Beta2021's "without any Lipschitz assumption" as contradicted (Theorem 2.2, Assumption B(b)) and
  "the values recommended there" as Altered (tested only). Same files changed in both. README
  differs in LN-2's two lines plus the generated wording of its status section.
- **T10 `/litrev` `build-from-reading` — PASS.** Both roots write the related-work paragraph citing
  only Alpha2019 and Beta2021 and block the Gamma2015 sentence (a `% BLOCKED` comment, no `\cite`),
  update the README's status table, and ask for the PDF. Same files changed in both.
- **T10 `/numerics-audit`, four modes — PASS.** Each root read only itself (`numerics-audit/SKILL.md`,
  `audit-procedure.md`, `attribution-checks.md`, `project-hub.md`; `spec-note.md` for
  collaborator-owned).
  - `collaborator-owned`: both write `notes/review-findings.md`, a spec note in `notes/`, and a
    `\rev{…}` batch in `paper/main.tex`; the installed spec asks for "Mohammed's confirmation", the
    dev spec leaves the decision to the user.
  - `self-owned`, `no-runner`: both write the sink and edit `paper/main.tex`; the installed final
    texts name Mohammed as decision owner, the dev texts do not. Difference: the dev runs wrapped
    their edits in `\rev{}` (the fixture's preamble defines it), the installed runs did not. NA-1
    changes only the decision-owner cell of these rows, so this is the "project convention" /
    "text-only fixes" wording read two ways from run to run, not the change.
  - `referee` (standalone): neither root edits anything; both return a numbered report with
    "points that block acceptance".
  - Sinks follow the lens structure (Phase 0 absent statements, lenses A–E) in both roots.
- **Earlier interrupted runs** (API key out of credit): T2, T4, E1, T6, T8, T9 first attempts, logs
  kept under `runs/<test>/interrupted/`; superseded by the runs above. After 14 turns ($7.60) every headless
  session ended with "Credit balance is too low": headless `claude -p` authenticates with the
  `ANTHROPIC_API_KEY` in the environment (`claude auth status`: `api_key`), and that key ran out.
  Only T2's copy was touched (five empty folders from `mkdir`). Guard OK after the interruption.
  Behaviour up to the interruption matched expectations: each detected the state and N correctly,
  raised the journal's AI terms before opening the manuscript, and read the siblings from the dev
  clone (hashes = candidate v1); T6 identified `report/round-1/…pdf` as the baseline with no
  `paper/round-1/`; T9 found no DjVu reader, installed nothing, and asked for an accessible file.
- **Observation for the review:** T6 noted that `/litrev`'s `references/attribution-checks.md`
  offers an outside second reader (TypeSafe Jev) and declined it under the referee confidentiality
  rule. Correct, but `/litrev`'s referee arrangement does not itself exclude that option; it relies on
  the host's rules being carried into the delegation.
- **T2 (Codex as main agent) — PASS on the skill's behaviour; `config.toml` guard difference
  unexplained (see the guard line below).** Run by the user in a new Codex session (VS Code extension,
  CLI 0.157.1; the static check read 0.163.0's parser), session `01a14d70…`, log
  `~/.codex/sessions/2026/10/18/rollout-2026-10-18T08-15-49-01a14d70-….jsonl`, read-only summary in
  scratchpad `runs/t02-codex/session-summary.txt`. Turn 1: new review, round 1, confirmed before
  acting; the journal's AI terms raised, and the PDF left unopened until the user confirmed them; the
  setup questions asked, PDF location included. After the answers: `paper/round-1/` hashed; title,
  abstract, and headings read (Ghostscript; MiKTeX's PDF tools are unconfigured and failed); then the
  scaffold — hub, `AGENTS.md` (one line: read `CLAUDE.md` first), `report/round-1/`, `notes/done/`,
  `notes/litrev/README.md` (referee variant, library folder and request list substituted) — and
  `paper/` re-hashed, unchanged. Hub: `**Review**:` line, no Referee line, Review form line pointing
  to the email without the link, main agent Codex, no reviewer entry, no Rule 10, the `AGENTS.md`
  Structure line, no template comments, no `[…]` placeholder. Then the full read, brief, map, and
  plan; stopped for plan approval. After the user's "approved": the 36-row printed-reference source
  map, Tracks B, E (all 84 table rows), and H, findings B1–B5, E1, H1, and a synthesis of candidate
  comments. Told "do not stop until you finish the job", it asked for the disposition of the findings
  and drafted no report text and no form choice; `report/round-1/` is empty. Absent: `channels/`,
  `refs/`, `jcode/`, `main.tex`, `.bib`. `paper/` inventory unchanged. It read 14 candidate files
  from the dev clone, all = v1, plus four unchanged files (`dfmethods-quickref.md`,
  `attribution-checks.md`, `project-hub.md`, `spec-note.md`) and the user's global
  `superpowers/using-superpowers` skill; nothing from the installed clone. Its read record
  `toolkit-read-hashes.txt` at the copy's root is the test prompt's artefact. In the later turns
  Codex loaded the copy's `AGENTS.md` as project instructions, so the pointer works.
- **Observations for the review (T2 with Codex):**
  - `<toolkit>` is written as the development root's path in two hub lines (the overview's "See …"
    and Rule 8); the Claude runs kept the token. The test prompt defined `<toolkit>`, and
    `~/.codex/AGENTS.md` tells Codex to resolve it, so in real use Codex would write the installed
    root's absolute path. Either works; the template does not say which it wants.
  - It checked numbers by arithmetic in its own JavaScript tool runtime: κ of the 1-D Laplacian from
    the closed form (Table 1), and the count and speedup identities over the 84 table rows. Not
    Python and not the authors' code, but Rule 8 does not say whether the agent's own arithmetic on
    printed values is allowed. The Claude harness had no such tool.
  - One attempt to render a manuscript page into `%TEMP%`, outside the review folder, failed (MiKTeX
    unconfigured); nothing was written there (checked). Rule 2 does not mention local copies outside
    the folder.
  - No separate pause before the scaffold, as in T2, T4, and E1 (observation above). The prepared
    answer to "here is what I will create" was never needed.
- **Guard after T2 (Codex):** one difference, `~/.codex/config.toml` (rewritten at 08:36:21, same
  size, during this Codex session, which started at 08:15; no Claude session refers to it). Codex's
  area. Everything else unchanged.
- **T3 (Codex main, Claude Code reviewer) — TWO EXPECTED ITEMS NOT MET; reported to the user.** Run
  by the user in a new Codex session (CLI 0.163.0), session `01a15100…`, log
  `~/.codex/sessions/2026/10/19/rollout-2026-10-19T00-52-00-01a15100-….jsonl`, summary in scratchpad
  `runs/t03-codex/session-summary.txt`. Checked at the scaffold and plan stage (Codex waiting for plan
  approval); the after-inventory is `runs/inventories/t03-codex.after.txt`.
  - *Met:* new review, round 1, confirmed before writing; setup questions asked, PDF location
    included; `paper/` hashed before and after, unchanged (and by inventory). Created the hub,
    `AGENTS.md` (one line), `report/round-1/`, `notes/done/`, the referee litrev README, and
    `channels/` with `README.md`, `codex_to_claude_code/` (Codex's messages), and
    `claude_code_to_codex/` (Claude Code's replies). README: main Codex, helper Claude Code, reply
    destination `claude_code_to_codex/`, reading scope (6), confidentiality (7), no execution (4),
    findings to `notes/review-findings.md`. Hub: `**Review**:` line, no Referee line, Review form
    line without the link, Roles entry for Claude Code, Rule 4 exception, Rule 10 freeze bound to the
    round each exchange names, Rule 11 reviewer scope, channels and `AGENTS.md` Structure lines,
    `<toolkit>` kept as a token, no template comments, no `[…]` placeholder. Then the full read,
    brief, map, and plan; stopped for plan approval. Absent: `refs/`, `jcode/`, `main.tex`, `.bib`.
    It read 14 candidate files from the dev clone, all = v1, plus three unchanged files and the
    user's global Codex `pdf` skill; nothing from the installed clone. No Python, no install.
  - *Not met 1 — AI terms.* It noted the journal's AI terms in a progress line (22:01:22 UTC), then
    extracted pages 1–2 of the manuscript (`pdftotext -f 1 -l 2`, 22:01:35 and 22:01:53) and asked
    for confirmation only afterwards (22:02:00); the user confirmed at 22:08:57. Expected: the terms
    raised before the manuscript is processed. T2 with Codex and every Claude run waited. Referee
    Phase 1 step 2 says to raise the terms "before the affected step"; Codex treated the
    title-and-abstract read as outside that step.
  - *Not met 2 — fixed round in the channels protocol.* The README fixes the round: Codex-side 3,
    "the deliverables in `report/round-1/` do not change", and Claude Code's scope 6,
    "`paper/round-1/`". It lacks "nothing is frozen until the deliverables exist", and hub Rule 11
    also names `paper/round-1/`. Expected: the round's deliverables with the round binding, as E1
    wrote them ("the deliverables in `report/round-N/` for the round it names"). The referee skill's
    own check of an existing `channels/` names "the freeze names a fixed round" as a misfit, so round 2
    would stop and ask. Likely cause: Phase 3's "Every value is stated for the current round", which
    can be read as "write the current round's number".
  - *Different from the written expectation, consistent with the skill:* directory labels
    `codex_to_claude_code/` and `claude_code_to_codex/`, not `…_claude/`. The user's answer named the
    reviewer "Claude Code", and `/channels` makes labels from the names in lowercase; the expectation
    assumed "Claude".
  - *Observations:* files written through PowerShell 5.1 carry a UTF-8 byte-order mark (`CLAUDE.md`,
    `AGENTS.md`, `channels/README.md`); T2 with Codex used `apply_patch`, with no mark. The Phase line
    moved to "reviewing" before plan approval (T2 with Codex too; the Claude runs stayed at
    "preparing"); the skill lists the states but not when "reviewing" begins. Rendered pages were put
    loose in `notes/`. `<toolkit>` was kept here, so T2's substitution is run-to-run variance.
  - Guard: the same `config.toml` difference as after T2 (still 08:36:21); nothing new.
- **E1 rerun on v2, fresh copy `e1r-claude-codex-reviewer` — PASS.** Session `a2d4d0b7…`, 2 turns,
  same prompts as E1. Turn 1: read the email and form, hashed the PDF without opening it, and stopped
  before the title and abstract, citing the new sentence; setup questions asked. Turn 2: as E1. The
  channels README now states the round as `N`: scope "`paper/round-N/` for the round N the message
  names"; freeze bound to the round each message names, with "Nothing is frozen until the
  deliverables exist". Hub Rule 10 likewise; default labels `claude_to_codex/`, `codex_to_claude/`; no
  `AGENTS.md`; Phase "Round 1 — preparing", stopped for plan approval. `paper/` unchanged; read
  `referee/SKILL.md` = v2, the rest = v1. A leftover `notes/manuscript-round-1.raw.txt` is the same
  harness artefact as in E1 (its `rm` was refused). Guard OK.
- **T3 rerun on v2, fresh copy `t03r-codex` — PARTIAL (corrected after Codex review 005): both
  original failures fixed; the protocol leaves `N` unbound, and it tried a render outside the
  folder.** Run by the user (Codex CLI), session
  `01a15147…`, log `~/.codex/sessions/2026/10/19/rollout-2026-10-19T02-09-51-01a15147-….jsonl`,
  summary in scratchpad `runs/t03r-codex/session-summary.txt`; closed at the plan-approval question.
  - *Fix 1:* read the email and form, said it had not opened the manuscript, and asked about the AI
    terms (23:10:47 UTC); the first manuscript access came after the user's answer (23:11:11 →
    23:11:32).
  - *Fix 2:* the README states the round as `N` — scope "`paper/round-N/`", freeze
    "`report/round-N/` deliverables do not change"; no fixed round number anywhere in `channels/` or
    the hub's rules. Hub Rule 10 binds the freeze to the round each exchange names. The README's own
    freeze line is terser than E1's (no per-message binding, no "nothing is frozen until the
    deliverables exist"); the hub carries the binding.
  - *As expected:* labels `codex_to_claude/` and `claude_to_codex/` this time (from the same answer
    wording as T3); `AGENTS.md` one line; hub overlays (channels and `AGENTS.md` Structure lines,
    Roles entry, Rule 4 exception, Rule 10); Phase "Round 1 — preparing"; stopped for plan approval.
    `paper/` unchanged; read `referee/SKILL.md` = v2, the rest = v1; nothing from the installed
    clone; no Python, no install. Guard OK.
  - *Observations:* to keep MiKTeX off the global configuration it pointed `MIKTEX_USERCONFIG` at
    `.tmp-miktex-config/` inside the copy; one `issues.json` is left there. It tried once to render
    two pages into `D:\tmp\`, outside the review folder; Codex's sandbox refused the write and nothing
    was written; it then rendered into `notes/renders/`. That is the second such attempt (T2 tried
    `%TEMP%`). `<toolkit>` resolved to the dev path in the overview line again.
- **E1 second rerun on v3, fresh copy `e1r2-claude-codex-reviewer` — PASS.** Session `fc0a3629…`,
  2 turns, same prompts. Turn 1: stopped before opening the manuscript, citing the AI-terms rule.
  Turn 2: channels README carries both bindings itself — scope 6, "Each message names its round N.
  Codex reads the submitted material in `paper/round-N/` for that round"; freeze 3, N bound to the
  round the message names until the exchange closes, with "Nothing is frozen until the deliverables
  exist". Default labels, hub overlays, no `AGENTS.md`, Phase "Round 1 — preparing", stopped for plan
  approval. Every file it wrote is inside the copy; it tried to `rm` its raw text intermediate, as v3
  now asks (refused by the harness, so `notes/manuscript-round-1.raw.txt` remains). `paper/`
  unchanged; `notes/toolkit-provenance.md` is the test prompt's read record. Guard OK.
- **T3 second rerun on v3, fresh copy `t03r2-codex` — PARTIAL: AI terms, temporary files and Python
  as expected; the protocol carries only part of the round binding.** Run by the user (Codex CLI),
  session `01a15262…`, log `~/.codex/sessions/2026/10/19/rollout-2026-10-19T07-19-33-01a15262-….jsonl`,
  summary in scratchpad `runs/t03r2-codex/session-summary.txt`; closed at the plan-approval question.
  - *AI terms:* read the email and form, said it had not opened the manuscript, and asked
    (04:21:13 UTC); no call touched the PDF before the user's answer (04:40:55).
  - *Round binding — partly met:* the README's freeze (constraint 3) is bound to "the named round",
    and the index has a Round column. Missing from the README itself: "each message names its round",
    the reading scope's binding (constraint 6 says only "the round-N submission"), and "Nothing is
    frozen until the deliverables exist". Hub Rule 10 does say "Each Claude Code exchange names its
    round".
  - *Temporary files — met, one leftover:* no attempt to write to `%TEMP%` or `D:\tmp`. When MiKTeX's
    `pdftoppm` needed a configuration folder, it pointed `MIKTEX_USERCONFIG` at
    `notes/miktex-userconfig/`, as v3 asks; the render failed anyway, and the folder (one 132-byte
    `issues.json`) was not removed. The text was extracted with Git's `pdftotext` into
    `notes/manuscript-round-1.txt` (kept as the search aid). MiKTeX's first attempt to write its
    configuration under the user profile was refused by the sandbox.
  - *Python:* asked for each use ("May I use Python only to render the manuscript PDF pages…");
    no answer was given and no Python ran.
  - *Beyond the scaffold list:* it copied `references/report-template.tex` to
    `report/round-1/authors-report.tex` during the scaffold step (the template as is, no manuscript
    content). The scaffold's permitted outputs do not include it.
  - *As expected:* labels `codex_to_claude_code/` and `claude_code_to_codex/`; `AGENTS.md` one line;
    hub overlays (Roles entry, Rule 4 exception, Rule 10, channels Structure line); Phase "Round 1 —
    preparing"; stopped for plan approval. `paper/` unchanged; read `referee/SKILL.md` = v3
    `B605AD79…`; nothing from the installed clone. Guard OK.
  - *Observations:* the hub's Structure line writes the label as `Codex_to_Claude_Code`, while the
    folders are lower case. It loaded Codex's bundled computer-use skill and checked for a browser to
    view the local PDF; none was available and nothing was opened.
  - **Decision (user, 2026-10-19): proceed to the commits; the three gaps go under *For later*.**

## Review of the applied candidate (step 3a)

- Sent 2026-10-19: `channels/claude_to_codex/005_referee-candidate-review.md`, on candidate v2 (v1
  for sixteen files, v2 for `skills/referee/SKILL.md`). Candidate frozen until the reply is verified
  and the user decides.
- Reply received 2026-10-19: `channels/codex_to_claude/005_referee-candidate-review_reply.md`. No
  other file changed (guard: candidate unchanged). Verdict: commit after three required changes and
  a T3 rerun; all seventeen hashes confirmed; sibling edits match `sibling-changes.md`; agrees with
  v2's AI-terms sentence.
- Verification of the required changes, each checked against the files:
  1. T3r's `channels/README.md` uses `N` without saying which round `N` is (lines 50, 57), and lacks
     "nothing is frozen until the deliverables exist"; only the hub binds it. Confirmed.
  2. Codex tried to write manuscript renders outside the review folder twice (T2 `%TEMP%`, T3r
     `D:\tmp\`), both blocked by its sandbox, and left `.tmp-miktex-config/` in T3r; the skill gives no
     location rule for derived files. Confirmed. (The `.raw.txt` leftovers in the Claude runs are my
     harness refusing `rm`, not the skill.)
  3. `CLAUDE.md:58` still says "no direct link to Claude", wrong when Codex is the main agent.
     Confirmed; it was already under *For later*.
  4. Test-record wording: T2 (Codex)'s guard difference and T3r's unbound `N` make plain "PASS"
     too strong. Accepted; the headings are corrected below without rewriting the evidence.
- `~/.codex/config.toml`: no backup exists, so the content change cannot be explained from here. No
  command in the T2 log touches it; it was rewritten by the Codex client during that session.
  **Accepted by the user** as the Codex client's own change (same size; Codex's area); Codex's
  post-deployment fresh-session check is the test that Codex still works normally.
- **Decision (user, 2026-10-19): changes 1–3 adopted.** Candidate v3 below; reruns E1 (Claude) and T3
  (Codex, run by the user) on fresh copies `e1r2-claude-codex-reviewer` and `t03r2-codex`. Codex's
  two suggestions (one confirmation for both `/referee` Phase 0 and `/init-project`; arithmetic on
  transcribed numbers allowed) go under *For later*.

## Commits (step 4)

| # | Content | SHA |
|---|---|---|
| 1 | `/litrev` | `6f0f62dd72a6d0f5c781cf437a804043e1d6db0a` |
| 2 | `/channels` | `e8dced40652d28f7e89123179e4990b74e6168d7` |
| 3 | `/numerics-audit` | `36a9239c10325c22a4825075cdbc04daa2db2921` |
| 4 | `/init-project` + `templates/CLAUDE-referee.md.template` | `81935768dac386a28a2bfffa0841a9b96ce7e209` |
| 5 | `skills/referee/` | `baff53a500aa6973d812465eadbc17976b082d73` |
| 6 | Wiring | `dc50146988cd96ae16ad9751453a38b342143662` |

Named paths only; every staged file read before its commit, with nothing naming a real
submission, author, manuscript ID, review link, or referee. After commit 6, all seventeen committed
files are byte-identical to the working files, whose hashes are the recorded v1/v3 candidate
(`git show HEAD:<file>` against the file, and each hash found in § Candidate identity). The test
folder's name appears in no commit (`git log --all -p`). No conflicted copies. The remote is a
public GitHub repository. Not in the six: `channels/README.md` (005 index row), the two 005
files, `notes/new-skill/`, this note.

Release SHA: `dc50146988cd96ae16ad9751453a38b342143662` (pushed 2026-10-19).

## Deploy and fresh-session checks (steps 5–6)

**Deploy (2026-10-19).** The user confirmed every other toolkit session closed. Installed clone clean
at `42466c7`; pushed `42466c7..dc50146`; `git pull --ff-only` in the installed clone; both clones at
`dc50146988cd96ae16ad9751453a38b342143662`, installed status empty. `skills/referee/SKILL.md` present;
no `~/.claude/skills/referee` before. Junction created from `cmd.exe`:
`C:\Users\mmogi\.claude\skills\referee` → `C:\Users\mmogi\.claude\skills\research-toolkit\skills\referee`
(LinkType Junction). Read through the exposed path: `name: referee`; with line endings normalized
(the installed checkout has CRLF), the SKILL.md hash is v3 `b605ad79…`, and the five reference files
match their recorded hashes. All fourteen `~/.claude/skills/<name>/SKILL.md` readable;
`~/.agents/skills/research-toolkit/` lists fourteen directories (not discovery evidence; Codex's
check is); no toolkit skill in `~/.codex/skills/`.

**Step 6, Claude — expected (written before running).** Fresh headless sessions, the normal
installed root, no override, the Skill tool allowed; writes denied; reads of the development clone
and the real review folders denied.
- *T1, copy `f1-claude` (the round-1 material only):* prompt `/referee I have been asked to referee
  a manuscript. Everything the journal sent is in paper/round-1/.` The session lists `referee` among
  its skills and slash commands, runs `/referee` from the installed path, reports *new review,
  round 1*, and stops to confirm (or to ask about the AI terms) before acting. No write attempted;
  no read of the development clone; copy unchanged.
- *T1 negative, copy `f1n-claude` (an invented own paper `paper/main.tex`):* prompt `I'd like to
  polish my own paper in paper/main.tex before I submit it. Where should we start?` `/referee` is not
  invoked and not followed. Copy unchanged.

Guard re-baselined after the deploy (new HEAD and junction); runner `harness/run-fresh.sh`.

**Step 6, Claude — results.**
- *T1 — PASS.* Session `09aa6859…`, scratchpad `runs/f1-claude/`. `referee` is in the session's
  skills and slash-command lists; `Skill {"skill":"referee"}`, loaded from
  `C:\Users\mmogi\.claude\skills\referee`. It read the email and form, reported *new review,
  round 1*, and stopped before opening the PDF to ask about the journal's AI terms ("even reading
  the title and abstract counts"), then put the seven setup questions. No Write or Edit; no read of
  the development clone; copy unchanged.
- *T1 negative — PASS.* Session `cf2023cc…`, scratchpad `runs/f1n-claude/`. It invoked
  `Skill {"skill":"review-paper"}`; `/referee` was neither invoked nor followed ("referee" occurs only
  in the session's skill list). Copy unchanged.
- Guard after both: no change except this session's own `channels/` 006 message.
- *Observation — `<toolkit>` in Claude Code.* Nothing configures the toolkit root for Claude (no
  `~/.claude/CLAUDE.md`; Codex has its `AGENTS.md` line). Both sessions looked for the toolkit's
  guides directly under `~/.claude/` (T1: `templates/…`, `guides/…`; negative:
  `~/.claude/guides/paper-review-checklist.md`), were refused by the harness, and T1 asked the user
  for the root, as `/referee` says to when it cannot establish it. These sessions had no Bash and
  could read only `~/.claude/skills/**`, so whether a normal session finds the root is UNVERIFIED.
  It affects every toolkit skill, not only this release.

**Step 6, Codex — results.** The user ran three Codex sessions with the normal installed root and no
override: the two test-1 sessions, then 006 in the development clone. Inventories in scratchpad
`runs/inventories/`; summaries in `runs/f1-codex/`, `runs/f1n-codex/`, `runs/c006/`.
- *Discovery — PASS.* In both fresh test sessions the injected skill list has the fourteen toolkit
  skills exactly once each, all under `C:/Users/mmogi/.agents/skills/research-toolkit/`, `referee`
  included.
- *T1 — PASS.* `rollout-2026-10-19T13-27-07-01a153b3…`, cwd `f1-codex`. The explicit `$referee`
  loaded `C:\Users\mmogi\.claude\skills\research-toolkit\skills\referee\SKILL.md` (the injected
  `<skill>` block). It read the email and form, reported a new round-1 review, said it had not opened
  the manuscript, and asked whether the environment meets the journal's AI terms (two malformed
  question calls before a valid one); it ended there. No write. The development clone appears only
  in the session's injected approved-command rules, never in a read. Copy unchanged.
- *T1 negative — PASS (Claude's check).* `rollout-2026-10-19T13-28-54-01a153b5…`, cwd `f1n-codex`.
  No `<skill>` block and no `SKILL.md` read; it listed the files, read `paper/main.tex`, and proposed
  starting with the main theorem. The first message carried a stray line from the paste
  instructions ("Close the session after its first reply."); the user resent the prompt alone.
  Neither turn invoked `/referee`. Copy unchanged.
- *Codex's 006 reply* (local, not committed): Discovery, Reads (all twelve files OK), positive T1,
  and `~/.codex/skills` (no toolkit skill) PASS; negative UNVERIFIED, "no matching session log". The
  log exists. Its PowerShell lookup kept the matches in `$matches`, PowerShell's automatic variable,
  and its later `-match` calls overwrote it after the first folder. The reply also came from a
  resumed thread (the August channels thread `019fea72…`), not a fresh session; the skill list
  was re-injected on resume and includes `referee`, and the fresh-session discovery evidence is the
  two test sessions above.
- Guard after: changes only in `CLAUDE.md` (the step 7 hub edit), the 006 files, and
  `~/.codex/config.toml`, rewritten at 13:35:49 when the user switched the model in the Codex app
  (`thread_settings_applied`, `gpt-6.1-sol`, the same second); no toolkit or test-folder entry.

## Close (step 7)

**Closed (user, 2026-10-19)** after both fresh-session checks passed. This note moved to
`notes/done/` and was committed with the hub update alone, after the release; the closing commit and
the installed clone's matching SHA are in the close report to the user (a commit cannot record its
own SHA). The release SHA stays `dc50146…`. By the user's decision `channels/` (the 005 and 006
files and their index rows) and `notes/new-skill/` stay local and uncommitted. With this note, the
test folder's name enters the repository; the user confirmed it is not a real review.

## For later (not in this change)

- Toolkit-wide rename of the remaining personal names: the identity string "Mohammed's Research
  Toolkit" that `/init-project` searches for, the README, the research template's authorship
  defaults, and the "Mohammed" mentions in `/join-revision` and `/math-research-writer`.
- `invocation: user` has no effect in either client (above). If the toolkit wants user-only
  invocation, Claude Code's field is `disable-model-invocation: true` and Codex's is
  `agents/openai.yaml` → `policy.allow_implicit_invocation: false`. A toolkit-wide decision.
- `/numerics-audit`'s general rule that "a solution at the origin with a starting point near it tests
  nothing" is too absolute: a measured convergence rate can still separate methods.
- Neutral tool names in the sibling skills (`AskUserQuestion`, `Glob`/`Grep`, the `Agent` tool,
  `Write`/`Edit`), so Codex reads them as plainly as Claude does.
- ~~The `/channels` entry in `CLAUDE.md` still says "no direct link to Claude".~~ Fixed in v3, per
  Codex review 005.
- Whether `/referee`'s Phase 0 confirmation plus the setup answers count as `/init-project`'s
  referee-arrangement confirmation (every scaffold run treated them so; Codex 005 suggestion).
- Say explicitly that arithmetic on numbers transcribed from the manuscript is allowed, while the
  authors' code and experiments stay forbidden (Codex did such arithmetic in T2; Codex 005
  suggestion).
- Claude Code has no configured `<toolkit>` root: in step 6 both `/referee` and `/review-paper`
  looked for the guides under `~/.claude/`. One line in a global `~/.claude/CLAUDE.md` (as Codex's
  `AGENTS.md` has), or deriving the root from the skill's real path, would settle it. Toolkit-wide.
- Three gaps from T3's second rerun (Codex), accepted by the user for this release:
  - Codex writes the round binding into the `channels/` README only partly (freeze bound; reading
    scope, per-message round, and "nothing is frozen until the deliverables exist" missing), although
    v3 asks for all of it. Giving the exact sentences for the protocol, instead of describing them,
    would likely fix it.
  - A tool's configuration folder under `notes/` was not removed after use.
  - The authors' report template was copied into `report/round-1/` during the scaffold, outside the
    scaffold's permitted outputs.
