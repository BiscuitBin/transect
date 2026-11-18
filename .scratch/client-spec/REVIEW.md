# Adversarial review procedure

Every ticket in `issues/` names its **key moments** and the questions to put to the reviewers. At each key moment, follow this procedure. It is adapted from the bootstrap tickets' procedure in `.scratch/bootstrap/REVIEW.md`, with lenses for research and for proposals.

## 1. What must exist before a review starts

- **Web access, for a research ticket.** A reviewer with the sources lens must open every link, so it needs the same web authorisation as the ticket. If the session cannot give it one, stop and report: a reviewer that could not open a source has not checked a quotation.
- **The maintainer's answers, for a proposal ticket and ticket 11.** The ticket records the maintainer's answers verbatim in its hand-back, each under the question that was put, before the first review. That record is what the conformance lens checks the work against.
- **The earlier elicitation.** Its raw record is not tracked in this repository. A reviewer has the verbatim quotations in the tickets and in `CONTEXT.md` and nothing more. A reviewer that cannot check a quotation against them says so and does not assume it is right.

## 2. Request the review

- The agent working the ticket does not review its own work. It requests an adversarial review from Codex or from Claude Code, preferably running Astra on Codex (`gpt-6-astra`) or Opus 5.5 on Claude Code (`claude-opus-5-5`).
- Where both can be reached, prefer the one the author is not running on. The maintainer named the two tools and the two models; the preference between them was added by the agent that wrote this procedure, in a plan the maintainer approved.
- If the preferred model is not available, use that tool's default model and say so in the hand-back.
- Use subagents for the review: two reviewers in parallel, each with one lens from the table below.
- Give each reviewer the ticket, `CONTEXT.md`, the ticket's questions, and the work under review: the research file, or the diff or commit range, or at a proposal ticket's first key moment the recorded answers and the change the agent intends to make from them. Do not give a reviewer the author's conclusions or a summary of why the work is correct.
- A research ticket's first key moment comes before any fit verdict or recommendation is written, so that neither is built on a finding nobody checked. That review covers what each system does, its stated why, the constraints behind it, its costs, and what was missed. Tell the reviewers that fit and recommendation are not written yet: their absence is not a finding, and the questions about them wait for the second key moment.
- Reviewers change no tracked file. A research reviewer may read the web under the ticket's authorisation; no reviewer posts, files or sends anything.
- Each reviewer writes numbered findings to `ai_tmp/client-spec-review/<ticket number>/<key moment>-round-<n>/`, one file per lens. A finding gives a claim, the evidence the reviewer checked itself, a location and a suggested severity. A claim the reviewer could not check goes under "Suspicions I could not confirm", not among the findings.
- Nothing a reviewer or a triage subagent writes goes under `.scratch/client-spec/`. That folder is tracked, and a stray file there leaves the worktree dirty.

| Tickets | Lenses |
| --- | --- |
| Research: 01, 02 and 12 to 17 | Sources and reasoning |
| Proposals, and tickets 09 and 11: 03 to 11 | Conformance and breakage |

### The lenses for research

- **Sources.** Does each source say what the research file claims, and is every quotation verbatim? Is each "why" stated by the system's own authors, or is an inference presented as stated? Is anything given as verified that no primary source confirms? What was missed: a rationale that exists and was not found, a later reversal, a comparable that chose otherwise?
- **Reasoning.** Does each fit argument hold? Which constraint behind a comparable's choice does this client not share, and does the file say so? Is there a counter-example? Is a leaning of the maintainer's used as a fact? Does anything quietly answer an open question, or recommend where the ticket says to report?

### The lenses for proposals and for tickets 09 and 11

- **Conformance.** Does the work say and do what the ticket, the maintainer's recorded answers, `CONTEXT.md`, `AGENTS.md` and the handbook require? What is missing, misquoted, misnamed, or described but absent? Is anything stated without a "Derived" marker that the maintainer did not answer?
- **Breakage.** How does it fail? A rule that contradicts a settled promise, such as a write that never fails and never blocks or a loss counted exactly once. An open question quietly resolved, or an "Until decided" behaviour that decides. A gate that passes vacuously. A count or a name the handbook now states wrongly. A comparable cited as a justification without its stated why and its fit.

## 3. Triage the findings with other subagents

- Hand the findings to separate subagents that were neither the author nor the reviewers. Each judges every finding independently: **valid**, **invalid** (with the evidence that refutes it) or **out of scope** (with the ticket or open question that owns it).
- For every valid finding, the triage subagent produces a concrete solution.
- A solution may not resolve an open question, and may not confirm a "Derived" statement. One that needs the maintainer becomes a question for the maintainer, with the smallest honest edit to make in the meantime.
- A finding is not dismissed because it is inconvenient; it is dismissed only with evidence.

## 4. Apply and re-verify

- Apply the solutions for the valid findings, then re-run the gates the ticket names. A research ticket names none of its own: re-open the links a fix depends on.
- If the fixes were substantial, run one more round. Two rounds at most per key moment; whatever is still open after that goes to the hand-back as an open point.

## 5. Record

- The hand-back lists each finding with its verdict and its resolution, and names the tool and model that reviewed and the model that triaged.
- If neither Codex nor Claude Code could run a reviewer, do not skip silently: say so in the hand-back and run the same two lenses with subagents on a different model from the author's.
