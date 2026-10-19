# Report conventions

How the deliverables are written. They apply to every journal. The journal's form decides which
pieces exist and where each goes (the brief's deliverables map, and `journals/<journal>.md` if it
exists).

## The authors' report

1. **Header:** journal, manuscript ID, title, and the round. Include the recommendation only if the
   journal's form puts it in the authors' report; the user decides, and the brief records it.
2. **Summary:** what the manuscript claims to do, in the referee's words and neutral terms. One
   paragraph.
3. **General assessment:** the main strengths, the main problems, and what a revision would need.
   It ends with the recommendation sentence when the recommendation is included.
4. **Major comments M1, M2, …:** each with a short topic-style heading, most important first
   (correctness and novelty before experiments and presentation).
5. **Minor comments m1, m2, …**
6. **Typos and presentation t1, t2, …**

State once, near the top, what page and reference numbers refer to (for example, the PDF of the
submitted manuscript and its bibliography). Items refer to each other by label: "see M4(a)".

## Every item

- **Anchored:** page and object (section, equation, theorem, algorithm, figure, table).
- **Complete:** the problem, the evidence (a short quotation or derivation), and what the authors
  should do.
- **Accepted and verified:** only findings the user accepted, each re-checked against the original
  file before it enters.
- **Split** into (a), (b), (c) when an item makes several separate requests.

## Requests

- Each Major item ends in a direct request.
- "must" only where the paper is wrong or not reproducible as it stands; "Please …" elsewhere.
- No labels such as "Requested:".
- Ask for what would resolve the point. Prescribe a particular fix only when there is one correct
  fix.
- When a proof fails, say which case it is: the argument is invalid; the statement is false (give
  the counterexample); or the statement's truth is open. If you have a repair, sketch it.

## Tone

- Constructive whatever the recommendation: specific enough to help the authors write a better
  paper.
- Short, direct sentences. No promotional or filler vocabulary, no sarcasm, no guesses about the
  authors' motives.
- Ethics, data, and code requests are the referee's own requests. What the journal's policy
  requires is left to the editor.
- Recommend only references that have been read and recorded. Never invent one.
- Do not ask the authors to cite the referee's own work unless it is essential; if it is, tell the
  editor why.

## Confidentiality and anonymity

- Nothing meant for the editor alone goes in the authors' report or the text box.
- The referee's name, affiliation, and identifying details appear nowhere the authors see. That
  includes the PDF's author field and metadata: leave `\author{}` empty and check the compiled
  PDF's properties.
- The review form's personal link and any account details stay out of every deliverable.

## Comments to the editor

- The reasons for the recommendation, and concerns that should not go to the authors (possible
  overlap with earlier work, ethics, integrity), stated factually and without accusation.
- The form choices, with each field labelled exactly as the form labels it.
- Consistent with the authors' report: nothing in the editor's comments contradicts it.

## A text-box summary (if the form has one)

A short, paste-ready summary of the main points, consistent with the report. The recommendation
appears only if the form asks for it there.

## Track F on the report itself

- No sentence claims more than the evidence: "the proof is invalid" only when shown, "false" only
  with a counterexample.
- Every number in the report is recomputed.
- Every cross-reference resolves.
- After each batch of edits, the summaries match the items.

## Layout

- The user compiles. Never rebuild or overwrite the PDF they provide.
- Use standard packages only, with no files outside the report folder.
- A fixed date in `\date{…}`: `\today` prints the compiling server's date.
- Keep each Major heading with its first lines: `\needspace` before the "Major comments" heading
  (for the first item) and before each later item, never directly after a heading. Check the
  compiled PDF for a heading stranded at the foot of a page.
