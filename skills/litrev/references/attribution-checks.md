# Attribution checks — which question to ask

Used by `/litrev` Step 3, and by `/numerics-audit` lens C for parameter values. It covers how to word
a check once the evidence is in hand. It does not cover finding or reading the source, and it never
sets **Verified** — only a check against the PDF does that.

## Why the wording matters

Ask "does the passage support this claim?" about a condition the passage never mentions, and the
honest answer is "it says nothing about it". That answer is defensible and useless. It reads the same
whether the condition is missing from a complete list of hypotheses — so the claim is false — or the
passage simply does not cover it. No error is returned, so nothing tells you the check failed.

Ask instead "is this condition on the complete list?" and absence means "no" — but only if the list
really is complete. Hence the rule: open questions for descriptions, list questions only for lists
known to be complete.

## 1. Choose the check by the kind of claim

| The manuscript says… | Check | Outcomes |
|---|---|---|
| what the paper does or shows | does the source excerpt state or directly imply it? | supports / contradicts / does not settle it |
| a cited result applies here | where the manuscript meets each source condition; whether each condition it attributes to the source is on the record | Satisfied / Violated / Unclear / Unverifiable |
| a value comes from the source | value, units, variant, status against the parameter record | Match / Altered / Unverifiable |
| something is new | open review — no fixed question | finding, or none |

## 2. The complete-list gate

A list question is only as good as the list. Before asking one, confirm the record:

- says **Complete: yes**, and how that was established;
- records the standing assumptions — section- or paper-wide conventions that the statement does not
  repeat;
- records alternatives — "(c) may be replaced by …";
- keeps the logical shape — "(a) and either (b) or (b′)" is not a list of three.

If any of these is missing, an absent condition is **Unverifiable**, never "not required". Reopen the
PDF.

## 3. The questions

Give the reader the evidence and the question, nothing else. Do not hint at the expected answer.

**What the paper does.**

> Here is an excerpt from <source, location>. Does it state or directly imply the following claim?
> CLAIM: "<manuscript sentence>"
> - supports — the excerpt states the claim or directly implies it
> - contradicts — the excerpt states the opposite, or implies the claim is false
> - does not settle it — the excerpt does not address the claim either way

"Does not settle it" is not a pass. It sends the claim back to the PDF.

**Result applicability, step 1 — each condition the source requires.**

> <Result> requires the conditions below, including its standing assumptions; allowed alternatives
> are marked. Here are the manuscript's statement and its standing assumptions. For each condition,
> where does the manuscript meet it — at the point of use, by a standing assumption, by an allowed
> alternative, or through a stronger condition that implies it? Give the manuscript location and
> answer Satisfied, Violated, or Unclear.

This step needs mathematical judgment — whether one condition implies another. It is a reader's job,
not a lookup. Give it to a reader who can do the mathematics: in the hard-case test (§4), Haiku marked
a correct implication Unclear in all three runs, where Opus proved it in one line every time.

**Result applicability, step 2 — each condition the manuscript attributes to the source.**

> The record below gives <result>'s complete list of hypotheses. Is "<condition>" among them?
> - yes — that condition appears among the recorded hypotheses of <result>
> - no — that condition does not appear among them

A "no" is a finding when the manuscript says the source requires the condition. A condition the
manuscript assumes on its own account, without attributing it, is fine.

**Parameter attribution.**

> The source's parameter record is below. The manuscript says: "<sentence>". For each value it
> attributes to the source, do the value, units, method or problem variant, and status (recommended /
> default / admissible / only tested) match the record? Answer Match, Altered, or Unverifiable, and
> say which part differs.

## 4. The tests behind this

Both tests are small. Read them as evidence that the wording matters, not as a measured effect size.
The full record is in the toolkit repo's `notes/toolkit-litrev-proposal.md` (§2, §10, §12).

**Membership test (step 2).** One passage — Lin and Ansari (2004), Corollary 4.4: hypotheses (a)–(d),
with Remark 4.6 allowing (c) to be replaced. Two claims named conditions the passage never mentions
(Φ-condensing, Hausdorff); two named conditions it states ((c) and (d)).

| Reader | Old wording: support / contradict / says nothing | New wording: on the complete list? |
|---|---|---|
| Claude Opus | missed Hausdorff | 4/4, three runs |
| Claude Haiku | missed both | 4/4, three runs |
| Jev (TypeSafe) | missed both | 4/4, three requests |

In one of three requests, Jev's wrong "says nothing" on Φ-condensing came with confidence 0.81 —
above the 0.8 auto-accept line in TypeSafe's published recipe. Under the old wording a confident
wrong answer can pass unreviewed.

**Hard cases (step 1, the gate, parameters).** Five cases, with Step 3 as written; four use invented
sources so no reader can answer from memory. Three runs per model.

| Case | Expected | Opus | Haiku |
|---|---|---|---|
| a standing assumption the manuscript breaks (Hilbert source, Banach manuscript) | Violated | 3/3 | 3/3 |
| a stronger condition that implies the source's (strongly convex ⇒ bounded below) | no finding | 3/3 | 0/3 — Unclear |
| an allowed alternative (Corollary 4.4 with Remark 4.6) | no finding | 3/3 | 3/3 |
| a record marked incomplete | Unverifiable | 3/3 | 3/3 |
| a value the source tested but did not recommend | Altered | 3/3 | 3/3 |

Haiku's miss is a false alarm, not a false pass: Unclear sends the citation to a reader.

## 5. Jev as an optional second reader

Jev is TypeSafe's System One model. No skill calls it; any use is by hand until a trial settles
whether it earns a place. On the membership test it matched Claude at about 1,200 tokens and under a
second per four questions, against 32,000–43,000 tokens and 8–27 seconds for a Claude subagent. Most
of the subagent cost is fixed startup, so the gap per question is smaller than that.

Use it only for the membership question (step 2) and descriptions of what a paper does — not for
step 1, which needs judgment.

`POST https://api.typesafe.ai/v1/systemone`, header `Authorization: Bearer $TYPESAFE_API_KEY`, body
`{"model": "jev-latest", "state": {"source": "<citation, page>", "passage": "<excerpt>"},
"questions": {...}}`. Use neutral question keys (`q1`, `q2`, …) so the key names do not hint at the
answer.

Membership:

```json
"q1": {
  "type": "noul",
  "instructions": "The passage states <result> together with its complete list of hypotheses. Is the condition '<condition>' among the hypotheses that <result> requires, as stated in this passage?",
  "criteria": {
    "true": "That condition appears among the stated hypotheses of <result> in this passage",
    "false": "That condition does not appear among the stated hypotheses of <result> in this passage"
  }
}
```

What the paper does:

```json
"q1": {
  "type": "choice",
  "instructions": "How does the passage relate to the following claim about the source? CLAIM: '<claim>'",
  "criteria": {
    "supports": "The passage states the claim or directly implies that it is true",
    "contradicts": "The passage states the opposite of the claim or implies it is false",
    "says_nothing": "The passage does not address what the claim asserts, either way"
  }
}
```

A `noul` answer is a probability that the answer is yes, with no confidence field. Starting
thresholds: 0.90 or above is yes, 0.15 or below is no, anything between goes to a reader. They come
from fewer than thirty answers — re-derive them on your own cases. A `choice` answer carries a
confidence; below 0.8 goes to a reader, and so does any `says_nothing`.

Not established: whether the words "complete list" matter — the one version tried without them did
equally well; Jev on parameter claims; Jev on step 1.
