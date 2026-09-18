# Proposal to the research-toolkit: mechanical attribution checking in `/litrev`

**From:** the VNQEP project session, 2026-09-18
**To:** the Claude instance that maintains `D:\Dropbox\Research\research-toolkit`
**Status:** reviewed by the toolkit session, 2026-09-18 — see §9 (decisions) and §10 (test results). Nothing in the toolkit has been modified yet.

Revised after adversarial review, which found eight blocking errors in the first draft. The
corrections weakened the result substantially; what survives is below. Read §7 before acting on
anything else.

---

## 1. Summary

An experiment against the TypeSafe System One API (`jev-1.13.0`, 2026-09-18) found a **narrow,
reproducible failure mode** in the question framing that `docs.typesafe.ai/cookbooks/citation_check.md`
recommends, and a candidate fix that worked on the two cases that failed.

The honest strength of this result is **"worth a pilot"**, not "validated". The failure rests on
n = 2 within a single request; the fix was not pre-registered. Accordingly:

- **Proposal 2 (a reference file recording the framing caution) is cheap and I recommend it.** It
  costs nothing to be wrong about and prevents a silent failure that returns a *defensible* answer
  rather than an error.
- **Proposal 1 (a mechanical check step in `/litrev`) is not yet justified by this evidence.** It is
  written out in full because the design work is done and the failure it addresses is real, but it
  should be piloted on a manuscript before being written into the skill.

---

## 2. What was measured

20 judgments, 5 requests, 6,816 input + 749 output tokens. Sources: Al-Homidan, Alshahrani & Ansari,
Optimization 64(5) (2015), pp. 1211–1216 (read in full); Lin & Ansari, JMAA 296 (2004), §4,
pp. 465–470 (rest skimmed).

### Round 1 — the cookbook's Choice frame, pre-registered

Ground truth was frozen before any call. `supports` / `contradicts` / `says_nothing`.

| Question | Shape | Expected | Got | Conf |
|---|---|---|---|---|
| VNEP is defined with `−int C_i` | characterization | supports | supports | 1.00 |
| VNEP is defined with `int C_i`, no minus | characterization | contradicts | contradicts | 1.00 |
| The paper writes `K^i` for the other players' product | characterization | supports | supports | 1.00 |
| The paper proves a linear convergence rate | characterization | says_nothing | says_nothing | 1.00 |
| Prop. 3.6 assumes `C*`-quasiconcavity | requirement | supports | supports | 1.00 |
| Prop. 3.6 assumes `C*`-pseudoconvexity | requirement | contradicts | contradicts | 1.00 |
| Prop. 3.5 assumes `K_i` convex | requirement | supports | supports | 1.00 |
| Cor. 4.4 assumes `X_i` convex in a TVS | requirement | supports | supports | 1.00 |
| **Cor. 4.4 requires `Q` to be Φ-condensing** | requirement | contradicts | **says_nothing** | 0.79 |
| Cor. 4.4 requires `Q_i^{-1}(y_i)` compactly open | requirement | supports | supports | 0.75 |

**By shape: characterization 4/4, requirement 5/6.** Overall 9/10.

> **The pre-registered pass criterion FAILED.** It required three specific cases correct; the
> Φ-condensing case missed. This is stated here because the first draft omitted it.

### The failure mechanism is narrower than "requirement claims"

The obvious reading — *Choice handles characterization claims and fails on requirement claims* — is
wrong, and was an artefact of classifying cases by whether the model got them right. Choice handled
**5 of 6** requirement claims at confidence 1.00.

The two it did not handle (Φ-condensing; and an unscored Hausdorff case, `says_nothing` at 0.99) are
distinguished from the five it did by one thing: **the hypothesis term appears nowhere in the passage
at all.** "Pseudoconvex" appears in the passage attached to a *different* proposition, so the model
can contrast and answer `contradicts`. "Φ-condensing" and "Hausdorff" have nothing to contrast
against, so absence reads as *not addressed*.

So the predictive rule is lexical, not structural:

> Choice fails when the claimed hypothesis is **absent from the passage's vocabulary entirely**.
> Then `says_nothing` is technically defensible and useless for auditing.

**n = 2, both in one request.** That is the entire evidential basis for the failure.

Mitigating: `supports` scored **0.00** on the miss — the model never confirmed the false claim, it
under-detected. And 0.79 sits below the cookbook's own `AUTO_ACCEPT = 0.8`, so the case would already
have routed to a human under the published recipe.

### A flaw in our own ground truth

The Φ-condensing case (scored decisive) and the Hausdorff case (scored *ambiguous — either answer
defensible*) are structurally identical from the passage alone: a hypothesis absent from the stated
list, with the proof appealing to a Theorem 4.4 whose hypotheses are not shown. The only thing
separating them is our outside knowledge that Φ-condensing appears elsewhere in Lin2004 — which the
model could not see. Either both are ambiguous or both are `contradicts`. **The pre-registered pass
hinged on a case our own ground truth's logic treats as arguable.**

### Round 2 — membership Noul, NOT pre-registered

Designed after seeing Round 1 fail; expected values recorded after the responses. Treat as
exploratory. *"Is X among the hypotheses stated for Y in this passage?"*

| Question | Expected | `noul` | |
|---|---|---|---|
| Φ-condensing listed for Cor. 4.4 | false | **0.06** | *the Round-1 miss* |
| Hausdorff listed for Cor. 4.4 | false | 0.10 | *the other absent-term case* |
| Compactly-open listed for Cor. 4.4 | true | 0.98 | *was 0.75 under Choice* |
| Coercivity condition (d) listed for Cor. 4.4 | true | 0.99 | |
| `C*`-pseudoconvexity listed for Prop. 3.4 | true | 0.99 | |
| `C*`-pseudoconvexity listed for Prop. 3.5 | false | 0.10 | Choice already handled this shape |
| `C*`-quasiconcavity listed for Prop. 3.6 | true | 0.96 | |
| `K_i` convex listed for Prop. 3.6 | false | 0.12 | Choice already handled this shape |

8/8, every true ≥ 0.96, every false ≤ 0.12, nothing in 0.3–0.7. But **only the first two rows test
the case Choice actually failed.** The rest confirm the Noul frame does not break what Choice already
did. The improvement on `compactly_open` (0.75 → 0.98) is a genuine secondary gain on a weak hit.

### A result the first draft oversold

A Noul asking whether Prop. 3.6's printed proof justifies choosing `ω_i*` independently of `y_i`
returned 0.11 — "no", which is correct.

The first draft called this a discovery "found from the proof text alone, with no hint in the question
about where to look". **That was false.** The question itself spelled the gap out in full — it
described the per-`y_i` quantifier, stated that the conclusion needs a uniform multiplier, and asked
only whether the proof addresses it. Further, the counterexample establishing the gap was written
2026-09-14, **four days before** the experiment, and the ground truth for this case was authored with
explicit knowledge of it.

It is a correct answer to a leading question about a known gap. It demonstrates nothing about
discovering omissions.

---

## 3. Proposal 1 — a mechanical attribution re-check (pilot first)

### How it relates to what the skill already does

**The skill already has a drift-catching mechanism**, and the first draft wrongly claimed it did not.
`references/litrev-notes.md:101–103` says: *"Record the setting even when it matches. The value of
'Assumptions and setting' is that it makes a mismatch visible later, when the manuscript's own
hypotheses change and a citation that was fine quietly stops being fine."* `SKILL.md:93–100` ties
Step 3's second bullet to that section.

So this proposal **mechanizes an existing comparison**. It does not create the record and does not
introduce the idea. That is a smaller contribution than the first draft claimed, and it means the
cost/benefit is correspondingly tighter.

### Which bullets it touches

| Step 3 bullet | Shape | Frame | Evidence |
|---|---|---|---|
| "Does the manuscript describe what the paper actually does?" | characterization | Choice | 4/4 |
| "Is a theorem cited inside the setting it was proved in?" | requirement | Choice 5/6; Noul 8/8 on the reframe | mixed — see §2 |
| "Benchmark parameter attributions" | requirement / value | presumed Noul | **untested** |
| "Anything claimed as new that the cited work already does?" | open-ended | neither | not mechanizable |

One bullet measured under both frames, one under Choice only, one untested, one out of scope.

### The contract — corrected

The first draft's contract was **wrong in a way that would have made the check useless**. It paired
the note's *recorded* attribution against the note's *stored* passage — a static pair, already
verified when the note was written, which cannot drift. Implemented as written it would return
"agrees" forever.

To catch drift the pairing must be:

- **Left side:** the manuscript's **current** sentence about the key, re-extracted at re-audit time.
  `SKILL.md:80–83` already performs this extraction and hands it to reading agents.
- **Right side:** the note's stored source evidence.
- **Question:** framed by claim shape per §4.
- **Output:** three outcomes — agrees / disagrees / low confidence.
- **Authority: none.** A disagreement is a flag. **Verified** marks are set by whoever read the PDF —
  a human or a reading agent — and are not downgraded by this check.

### When it would run

Not on first write: the PDF was just read, so the model adds nothing. On **re-audit**, where it
*would* catch drift — no re-audit was simulated in this experiment, so that benefit is argued, not
measured.

### Batching

Attributions sharing one passage go in one request as parallel questions. `cookbooks/parallel_questions.md`
reports **12.2x cheaper and 10.0x faster** for 13 questions batched versus 13 single-question calls,
where a large shared document dominates request size — the same shape as ours. We ran no
single-question baseline, so that figure is theirs, not ours. Our 4-question requests cost 1,097–1,648
input tokens each.

### Thresholds

From our separation (0.96 / 0.12). **Re-derive on your own data; n = 20, one subfield.**

- Noul `≥ 0.90` → stated; `≤ 0.15` → not stated; otherwise review.
- Choice → adopt the cookbook's `AUTO_ACCEPT = 0.8`; below it, review.
- **Any disagreement with the note, at any confidence → review.**

### What it does not do

Both rounds were fed passages a human had already located and transcribed from the PDF. Steps 1 and 2
of `/litrev` — finding and reading — are untouched. It cannot verify a reference *exists*, so the
never-fabricate-an-entry rule (`SKILL.md`, "Requesting a reference that is not in the bibliography")
is entirely unaffected.

---

## 4. Proposal 2 — a reference file for the framing caution (recommended)

Suggested path: `skills/litrev/references/attribution-checks.md`.

This is the part worth adopting now. It is cheap, it costs nothing if the effect turns out to be
smaller than measured, and it documents a failure that is **invisible until it bites**: the wrong
frame returns a defensible answer, not an error. Anyone starting from the published cookbook will
start with Choice.

Contents:

1. **The rule, stated lexically** — Choice is fine for characterization claims and for requirement
   claims whose hypothesis term appears in the passage. It degrades to `says_nothing` when the
   claimed term is absent from the passage's vocabulary entirely. With the Φ-condensing case worked
   through.
2. **Verbatim templates.**

   **Characterization claim —**
   > `"type": "choice"`
   > instructions: `How does the passage relate to the following claim about the source? CLAIM: '<claim>'`
   > criteria: `supports` = "The passage states the claim or directly implies that it is true";
   > `contradicts` = "The passage states the opposite of the claim or implies it is false";
   > `says_nothing` = "The passage does not address what the claim asserts, either way"

   **Requirement claim —**
   > `"type": "noul"`
   > instructions: `The passage states <result> together with its complete list of hypotheses. Is the condition '<hypothesis>' among the hypotheses that <result> requires, as stated in this passage?`
   > criteria: `true` = "That condition appears among the stated hypotheses of <result> in this passage";
   > `false` = "That condition does not appear among the stated hypotheses of <result> in this passage"

   The closed-world phrasing ("complete list of hypotheses", "as stated in this passage") is intended
   to license reading absence as a negative. **This was not ablated.** The Round-2 variant that omitted
   "complete list of hypotheses" separated equally well (0.99 / 0.10 / 0.96 / 0.12). Treat the
   phrasing as a hypothesis, not a measured effect.
3. **The numbers from §2**, including the failed pre-registration, so a reader can see what was and
   was not established.

**A second consumer.** `/numerics-audit` lens C checks baseline parameters against a litrev note —
the same claim shape. If the rule holds up, that skill should reference this file rather than
reinvent the framing.

---

## 5. A smaller note-format gap than first claimed

The first draft proposed a new `## Source passages` section, on the grounds that notes record only a
page pointer. **That overstated the gap.** The existing skeleton already asks for attributions
*"quoted or equation-referenced from the source"* (`litrev-notes.md:62–63`), records hypothesis lists
in *"Assumptions and setting"* (`:68–71`), and records values in the parameter table (`:73–80`). This
project's own `notes/litrev/Lin2004.md:25–42` transcribes Corollary 4.4 in full under that section.

For requirement claims and parameter claims, a new section would duplicate what exists. The genuine
gap is narrower: **verbatim passage text for characterization claims**, where the skeleton asks for a
quote but the surrounding prose does not insist on one. Strengthening the existing "What we cite it
for" wording is a smaller and better fix than adding a fifth section.

---

## 6. Reproducing this

`POST https://api.typesafe.ai/v1/systemone`, `Authorization: Bearer $TYPESAFE_API_KEY`.

```json
{
  "model": "jev-latest",
  "state": { "source": "<full citation and page>", "passage": "<transcribed text>" },
  "questions": {
    "phi_condensing_listed": {
      "type": "noul",
      "instructions": "The passage states Corollary 4.4 together with its complete list of hypotheses. Is the condition 'the multivalued map Q defined by Q(x) = the product of the Q_i(x) is Phi-condensing' among the hypotheses that Corollary 4.4 requires, as stated in this passage?",
      "criteria": {
        "true": "That condition appears among the stated hypotheses of Corollary 4.4 in this passage",
        "false": "That condition does not appear among the stated hypotheses of Corollary 4.4 in this passage"
      }
    }
  }
}
```

Choice answers return `choice` + `probabilities` + `confidence`; Noul answers return a bare `noul`
probability with **no** confidence field.

**Exact reproduction requires re-transcribing the five source passages** from the page ranges in §2 —
they are not reproduced here, and the originals live in a session scratchpad that will be cleaned up.
The claim strings are recoverable from the §2 tables and the §4 templates. Mathematics was
transliterated to ASCII words ("is NOT in -int C_i") rather than LaTeX, which avoided JSON escaping
and did not appear to hurt: the model separated `int C_i` from `-int C_i` at probability 1.00.

---

## 7. What is *not* claimed

- **The pre-registered criterion failed.** Round 1 did not pass the bar set before it ran.
- **Round 2 was not pre-registered.** It was designed after seeing Round 1 fail.
- **The failure rests on n = 2**, both cases in a single request, and the Noul frame's advantage over
  Choice is demonstrated on exactly those two.
- **The phrasing was not ablated** (§4).
- **No re-audit was simulated**, so the drift benefit — the entire motivation for Proposal 1 — is
  argued, not measured.
- **No cost baseline was run.** The batching figure is the vendor's.
- **The parameter-attribution bullet was not tested.**
- **n = 20**, two sources, one subfield (nonsmooth vector optimization).
- Round 1's 1.00 confidences are less impressive than they look — most were near-verbatim lookups.
- **Two of the Round-1 cases were errors that really occurred in this manuscript** (the missing minus
  sign; `K_i` for `K^i`). The other two adversarial cases were *plausible* errors modelled on the
  source's structure, not errors anyone committed — an earlier draft, and the chat summary that
  preceded it, wrongly described the Φ-condensing case as an error we had made. It was flagged as an
  open question and resolved by reading the PDF.
- **This reduces re-reading, not reading.**

## 8. Disposition

If adopted, this note moves to `notes/done/` in the VNQEP project. It is a handoff, not an open
VNQEP topic.

---

## 9. Toolkit response (2026-09-18)

Reviewed by the toolkit session. Every reference this note makes into the toolkit was checked and is
accurate.

### Adopt now

1. **Notes quote the source.** Strengthen "What we cite it for" in `references/litrev-notes.md` so a
   characterization claim carries the source's own words, not only a page number. This stands on its
   own: without the quote, any later re-check means reopening the PDF.
2. **Reword Step 3 of `SKILL.md` as complete-list questions.** Instead of "Is a theorem cited inside
   the setting it was proved in?", ask: for each hypothesis in the note's list, is it in the
   manuscript's statement, and does the manuscript state anything not on the list? Same for
   parameter values against the parameter table. This is the lesson of §2 that carries over to any
   reader, and it needs no API.
3. **Proposal 2, led by the wording lesson.** `skills/litrev/references/attribution-checks.md` opens
   with the rule — ask whether a condition is on the complete list, not whether the passage
   supports the claim — and keeps the TypeSafe templates as one worked example. `/numerics-audit`
   lens C points to it.

### Not now: Proposal 1

- **The experiment never asked Claude.** Claude already does this comparison in Step 3. If Claude
  answers the Φ-condensing case correctly, the step adds no accuracy (see speed and tokens below). If
  it does not, rewording the question fixes it without an API.
- **The toolkit uses no outside service today.** A paid API inside `/litrev` is a bigger change than
  one added step.
- **The mitigation in §2 is weaker than it looks.** For a re-check, a missed flag is the case nobody
  reopens. The miss reached review by 0.01 (0.79 against 0.8).
- **In its favor: speed and tokens.** Jev answers a batch of four yes/no questions in about
  1,100–1,650 input tokens (§3), far lighter than a Claude agent re-reading notes. If its answers
  match Claude's, it is the cheaper and faster way to get them. Not yet measured against Claude.

### Before any pilot

- **Test first.** Give a Claude subagent the Cor. 4.4 passage and the Φ-condensing claim, in both
  the original wording and the complete-list wording. Write the expected answers down before
  running it.
- **Pilot site:** VNQEP's next re-audit, with a Claude arm run alongside TypeSafe.
- **Measure cost too.** Record tokens and time for the Jev arm and the Claude arm. If the answers
  match, the cheaper one wins.

### Action for VNQEP

Save the five source passages into the project before the scratchpad is cleaned. Cor. 4.4 is already
safe in `notes/litrev/Lin2004.md:25–42`.

### Disposition in the toolkit

The three edits landed 2026-09-18, reworked per the 003 reply (§11–12). This note stays open for the
Jev trial at VNQEP's next re-check (§9, §10), then moves to `notes/done/`.

---

## 10. Test: does Claude fall into the same trap, and what does each cost? (2026-09-18)

### Written before running

**Passage.** Corollary 4.4 as stated in VNQEP `notes/litrev/Lin2004.md:25–42`, rewritten once as
plain text (no LaTeX) and given identically to every run. The note's next section, which names the
answers, is left out.

**Claims and expected answers.**

| Claim | Old wording (supports / contradicts / says nothing) | New wording (on the complete list?) |
|---|---|---|
| Q is Φ-condensing | contradicts | no |
| Each E_i is Hausdorff | contradicts | no |
| Q_i⁻¹(y_i) is compactly open | supports | yes |
| Compactness condition (d) | supports | yes |

Under the old wording, "says nothing" on the two missing conditions counts as the trap. §2 notes it
is defensible from the passage alone; that is why it is useless for checking.

**Runs.**
- Claude: Opus and Haiku, 3 runs per wording per model. Each run is a fresh subagent with no tools,
  given only the passage and the four questions of one wording.
- Jev (`jev-latest`): the four questions of one wording in one request, 3 requests per wording.
- Recorded for every run: answers, tokens, time.

A model passes a wording only if all 3 runs get all four right.

**Decision.**
- Claude falls into the trap under the old wording → the rewording edit (§9, item 2) is confirmed.
- Claude passes both wordings → the rewording is still sound, but this test does not show Claude
  needs it.
- Jev passes the new wording, and uses fewer tokens and less time than the cheapest Claude model
  that also passes it → full trial at VNQEP's next re-check.
- Jev gets something wrong that Claude gets right → drop Jev for this job.

### Results

Jev reported itself as `jev-1.13.0`. Each Claude model gave identical answers across its three runs.

| Claim | Expected (old / new) | Opus old | Haiku old | Jev old | Opus new | Haiku new | Jev new |
|---|---|---|---|---|---|---|---|
| Φ-condensing | contradicts / no | contradicts | says nothing | says nothing (0.76–0.81) | no | no | 0.07 |
| Hausdorff | contradicts / no | says nothing | says nothing | says nothing (0.98) | no | no | 0.09 |
| Compactly open (c) | supports / yes | supports | supports | supports (0.91–0.92) | yes | yes | 0.98 |
| Condition (d) | supports / yes | supports | supports | supports (1.00) | yes | yes | 0.99 |

Jev's new-wording numbers were identical across all three requests.

**Cost of one set of four questions:**

| | Tokens | Time |
|---|---|---|
| Jev | 1,163 in + 72 out (new wording); 1,225 + 179 (old) | 0.8–0.9 s |
| Haiku subagent | 32,100–32,400 | 16–19 s |
| Opus subagent | 41,000–43,000 | 7.5–8.7 s new wording; 22–27 s old |

**What it shows.**
1. **All three fell into the old-wording trap.** Opus on Hausdorff only; its reason was that the
   passage "cannot rule out a paper-wide Hausdorff convention". Haiku and Jev on both.
2. **Under the new wording all three got all four right, every run.**
3. **The §2 near-miss was luck.** Jev's Φ-condensing miss scored 0.81 in one run of three — above the
   cookbook's 0.8 auto-accept line. In that run the wrong answer would have been accepted without
   review.
4. **Jev used about 1/26 of Haiku's tokens and was about 20 times faster.** Caveat: most of a
   subagent's tokens are a fixed startup cost (its instructions and tool list), not the question. A
   re-check agent handling many papers in one run spreads that cost, so the gap per question is
   smaller than these numbers show. The trial should measure that.

**Against the rules written before running.**
- Claude fell into the trap under the old wording → **rewording edit confirmed.**
- Jev passed the new wording, cheaper and faster than Haiku, the cheapest Claude model that also
  passed → **full trial at VNQEP's next re-check.**
- "Jev gets something wrong that Claude gets right": under the old wording, Opus got Φ-condensing
  right and Jev did not. The rule did not say which wording it meant. The check would only ever use
  the new wording, where they tie, so it is read that way here — but that reading was chosen after
  seeing the results, and is flagged for Mohammed to confirm.

**Limits.** One passage, four claims, one subfield. Enough to decide the trial is worth running, not
to show Jev works in general.

---

## 11. Codex review

The three §9 edits were sent to Codex as `channels/claude_to_codex/003_litrev-attribution-design.md`
(2026-09-18). That message also holds the only surviving copy of the §10 test materials. **Reply
pending.** Until it lands, no edits to `skills/`, `templates/` or `guides/`.

**Reply received 2026-09-18:** `channels/codex_to_claude/003_litrev-attribution-design_reply.md`.
Every file and line it cites was checked and is accurate. Verdict: all three edits *adopt with
change*, plus five missing items.

**Decision (Mohammed, 2026-09-18): adopted with changes, per 003 reply.**
- Edits 1–3 in the reply's changed form, worded more lightly; the Scope field in Edit 1 is optional.
- Missing items 1–4 go into the edits.
- Missing item 5 — five hard cases — is run as a test before commit (§12).

---

## 12. Test: five hard cases for the new Step 3 (2026-09-18)

Codex's missing item 5 (003 reply). Run on the edited `skills/litrev/SKILL.md` Step 3 before commit.

### Written before running

**Readers.** Claude Opus and Haiku subagents, 3 runs each, no tools. Each run is given the new Step 3
section verbatim, then all five cases, and answers per condition with a one-line reason and a
verdict per case. Sources in cases 1, 2, 4 and 5 are invented, so no reader can answer from memory;
case 3 uses the real Corollary 4.4 of Lin and Ansari (2004).

**Case 1 — standing assumption the manuscript breaks.**
Note, Smith2020 Theorem 3.2, p. 9. Complete: yes — statement read in full; §3's opening assumptions
checked. Standing assumptions: throughout §3, H is a real Hilbert space and C ⊆ H is nonempty, closed
and convex. Requires all of: (A1) F : C → H is monotone; (A2) F is L-Lipschitz continuous; (A3) the
solution set S is nonempty. Alternatives: none.
Manuscript standing assumption: "Throughout, E is a real Banach space and C ⊆ E is nonempty, closed
and convex." At the point of use: "Since F is monotone and L-Lipschitz on C and the solution set is
nonempty, Theorem 3.2 of [Smith2020] gives weak convergence of the sequence."
**Expected:** Hilbert space — Violated. C, A1, A2, A3 — Satisfied. **Case: Violated.**

**Case 2 — a stronger condition that implies the source's.**
Note, Chen2019 Theorem 2.4, p. 6. Complete: yes. Standing assumptions: throughout, H is a real
Hilbert space. Requires all of: (H1) f : H → ℝ is convex and differentiable; (H2) ∇f is L-Lipschitz;
(H3) f is bounded below. Alternatives: none.
Manuscript standing assumption: "H is a real Hilbert space." At the point of use: "Because f is
μ-strongly convex and differentiable with L-Lipschitz gradient, Theorem 2.4 of [Chen2019] applies."
**Expected:** all Satisfied — H1 because strong convexity implies convexity, H3 because a
differentiable strongly convex function is bounded below. **Case: no finding.**

**Case 3 — an allowed alternative.**
Note, Lin2004 Corollary 4.4, p. 468. Complete: yes — statement read in full; §4 has no standing
assumptions beyond the statement. Standing assumptions: none. Requires all of: each X_i is a nonempty
convex subset of a topological vector space E_i; (a) co Q_i(x) ⊆ T_i(x); (b) x_i ∉ T_i(x);
(c) Q_i^{-1}(y_i) is compactly open in X; (d) the compactness condition with K and C_i. Alternatives:
(c) may be replaced by "Q_i^{-1} is transfer compactly open valued on X_i" (Remark 4.6).
Manuscript: "Each X_i is a nonempty convex subset of a topological vector space E_i; the maps satisfy
(a), (b) and (d) of [Lin2004, Corollary 4.4], and Q_i^{-1} is transfer compactly open valued on X_i.
Hence, by [Lin2004, Corollary 4.4], there is x̄ with Q_i(x̄) = ∅ for all i."
**Expected:** (c) Satisfied through the alternative; everything else Satisfied. **Case: no finding.**

**Case 4 — an incomplete record.**
Note, Park2021 Theorem 4.1, p. 14. Complete: no — only the statement on p. 14 was copied; §4's opening
assumptions were not checked. Standing assumptions: not recorded. Requires all of: (B1) T is firmly
nonexpansive; (B2) Fix T ≠ ∅. Alternatives: not recorded.
Manuscript: "T is firmly nonexpansive with a fixed point, so by [Park2021, Theorem 4.1] the iterates
converge strongly."
**Expected:** **Case: Unverifiable** — reopen the PDF. Marking B1 and B2 Satisfied is acceptable only if
the case verdict is still Unverifiable.

**Case 5 — a value the source tested but did not recommend.**
Note, Wang2022, parameter table:

| Parameter | Value | Status | Method / variant | Where |
|---|---|---|---|---|
| σ | 0.5 | tested only — one of 0.1, 0.5, 0.9 in Table 3 | Algorithm 1, monotone equations | Table 3, p. 18 |
| σ | 0.1 | recommended — §6: "we recommend σ = 0.1" | Algorithm 1, monotone equations | §6, p. 21 |
| ρ | 0.8 | recommended | Algorithm 1, monotone equations | §6, p. 21 |

Manuscript: "For the competitor, Algorithm 1 of [Wang2022], we use σ = 0.5 and ρ = 0.8, the parameters
recommended in [Wang2022]."
**Expected:** σ — Altered (0.5 was only tested; 0.1 is recommended). ρ — Match. **Case: Altered.**

**Pass.** A model passes if every run gets all five case verdicts right.

### Results

| Case | Expected | Opus (3 runs) | Haiku (3 runs) |
|---|---|---|---|
| 1 — standing assumption broken | Violated | Violated ×3 | Violated ×3 |
| 2 — stronger condition implies the source's | no finding | no finding ×3 | **Unclear ×3** |
| 3 — allowed alternative | no finding | no finding ×3 | no finding ×3 |
| 4 — incomplete record | Unverifiable | Unverifiable ×3 | Unverifiable ×3 |
| 5 — tested, not recommended | Altered | Altered ×3 | Altered ×3 |

Cost per run: Opus about 48,000 tokens and 48–53 s; Haiku 35,600–36,200 tokens and 35–40 s.

**Opus passes. Haiku fails case 2.** In every run Haiku marked "f bounded below" Unclear, not seeing
that a differentiable strongly convex function is bounded below; one run said outright that it
"cannot be inferred". All three Opus runs gave the one-line proof. The failure is in the safe
direction — Unclear sends the citation to a reader, it does not pass a bad one — but it is a false
alarm on every run.

Nothing in the Step 3 wording caused it: the wording names "implied by a stronger condition", and
Haiku applied the gate, the alternative and the parameter status correctly. It is the step that needs
mathematics. `references/attribution-checks.md` now says to give that step to a reader who can do it.

Opus also added unprompted points worth keeping: in case 4, one run noted that iterating a firmly
nonexpansive map converges only weakly in general, so an unrecorded assumption is probably doing the
work behind the "strong convergence" claim; in case 5, two runs noted the manuscript sentence does not
restate the problem class the recommendation was made for.
