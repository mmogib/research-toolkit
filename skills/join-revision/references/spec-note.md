# Experiment specification for the code collaborator

When the revision needs numbers you cannot produce, you write a specification. Not a request, not a
description — a document someone can implement without asking a single follow-up question.

File: `notes/spec-<topic>.md`. Mohammed compiles it to PDF and forwards it.

The collaborator is a student. Every formula written out, every parameter given a value and an admissible
range, every stopping rule stated, every deliverable named. Nothing left to interpretation. If a sentence in
the spec could be implemented two ways, it will be implemented the wrong way.

**Before drafting: confirm every formula against the manuscript.** Cite line numbers as you go. A spec that
drifts from `main.tex` produces numbers that do not match the paper, and nobody notices until the referee
does.

---

## Template

```markdown
# Spec — <topic>

**Written:** <YYYY-MM-DD>
**Manuscript reference:** `paper/main.tex`, §<n>, lines <a>–<b>
**Status:** <draft / sent <date> / results received <date>>

## 1. Purpose

<One paragraph. What the paper needs these numbers for, and which claim they support. State the claim in the
manuscript's own words, with its line number. If the answer changes what the paper says, say so.>

## 2. What is being compared

<Every method in the comparison, by name, with the reference it comes from. Say which is ours.>

| Method | Source | Role |
|--------|--------|------|
| | | |

## 3. The iteration

<Written out in full for each method. Every symbol defined at first use, including ones you think are
obvious. Index conventions stated: does $k$ start at 0 or 1?>

For method <name>, given $x_k$:

1. <step, with the formula>
2. <step, with the formula>
3. <update, with the formula>

<Where a step needs a sub-procedure — a line search, an inner solve, a projection — write that out as its
own numbered block. Do not write "use the standard line search".>

## 4. Parameters

| Symbol | Value | Admissible range | Source |
|--------|-------|------------------|--------|
| | | | |

<Every parameter of every method. For competitors, the values recommended in their own papers, with the
section or table those values come from — this is what makes the comparison fair and what a referee checks.
Anything tuned by us is labelled as tuned, with how.>

## 5. Admissibility conditions

<The inequalities that must hold for the method to be well defined or for the convergence theory to apply.
Written as checkable conditions, with what to do if one fails: abort the run, or record and continue?>

- <condition>, checked <when>. If violated: <action>.

## 6. Problem data

<Every test problem: the map $F$, the dimension(s), the feasible set, the starting point(s), and the source
the problem comes from. Write the formulas componentwise where the structure matters.>

### Problem <n> — <name>

- $F(x)$: <formula, componentwise>
- Dimensions: <list>
- Feasible set: <formula>
- Starting points: <named recipes with formulas>
- Source: <citation key + where in that paper>

## 7. Stopping criteria and failure convention

- Success: <exact inequality, exact norm, exact tolerance>
- Iteration cap: <n>. Time cap: <t>.
- A run that hits a cap is recorded as **fail**, not as its last iterate. <State how failures appear in the
  output — a flag column, not a blank.>
- All methods use the same criterion, the same norm, and the same tolerance. <If any method cannot, say
  which and why, because the paper has to disclose it.>

## 8. Metrics recorded per run

<The exact columns, with units and what counts. Ambiguity here is what makes tables incomparable.>

| Column | Meaning | Notes |
|--------|---------|-------|
| `iters` | outer iterations | |
| `fevals` | evaluations of $F$ | **including** those inside the line search |
| `time` | wall-clock seconds | excluding compilation / warm-up |
| `resid` | $\|F(x_k)\|$ at termination | same norm as the stopping rule |
| `status` | success / fail-maxit / fail-time / fail-other | |

## 9. Deliverables

<File names, formats, and layout. What Mohammed receives.>

- `results/<name>.csv` — one row per (method, problem, dimension, starting point), columns as in §8.
- <Any figure, with axes and what is plotted.>
- The log of the run.

## 10. Acceptance checks

<What must be true for the results to be trusted. The collaborator runs these before sending.>

- Every (method, problem, dimension, start) combination appears exactly once.
- No blank cells; failures carry a status.
- <A sanity value that is known in advance, e.g. method X on problem 1 at n=1000 converges in under 50
  iterations.>

## 11. What NOT to change

<The parts that must match the manuscript exactly: the iteration, the parameters, the stopping rule, the
problem set. If something looks wrong, report it back rather than fixing it silently — a silent fix makes
the numbers disagree with the paper.>
```

---

## Common failures in specs

1. **"Use the standard X."** There is no standard. Write it out.
2. **Norm left unstated.** $\|\cdot\|_2$ or $\|\cdot\|_\infty$ changes the tolerance's meaning and makes
   comparisons incomparable.
3. **Function evaluations undefined.** Line-search evaluations counted or not decides who wins the table.
4. **Failure convention missing.** Averaging over successes only, with different success sets per method, is
   the most common way a benchmark table becomes meaningless.
5. **Starting points described, not defined.** "A random point in the feasible set" needs the distribution
   and the seed.
6. **No acceptance check.** Without one, a silently broken run comes back as data.
