# Adversarial review procedure

Every ticket in `issues/` names its **key moments** and the questions to put to the reviewers. At each key moment, follow this procedure. It is the short form of the adversarial review rule in the model repositories' ticket conventions.

## 1. Request the review from Codex

- The implementing agent does not review its own work. It requests an adversarial review from Codex, preferably running the Astra model (the model repositories name it `gpt-6-astra`). If Astra is not available, use Codex's default model and say so in the hand-back.
- Use subagents for the review: two Codex reviewers in parallel, each with one lens.
  - **Conformance:** does the work do what the ticket, the settled decisions and the model repositories require? What is missing, misnamed or described but absent?
  - **Breakage:** how does it fail? Gates that pass vacuously, platform differences between Linux and macOS, anything that could raise into or block a host application, anything unsafe under fork, anything that quietly chooses a design for an undecided area.
- Give each reviewer the ticket, the diff or commit range, and the ticket's questions. Do not give them the author's conclusions or a summary of why the work is correct.
- Reviewers are read-only. Each writes numbered findings (claim, evidence, location, suggested severity) to the agent scratch directory, under a folder named for the ticket and the round.

## 2. Triage the findings with other subagents

- Hand the findings to separate subagents that were neither the author nor the reviewers. Each judges findings independently: **valid**, **invalid** (with the evidence that refutes it) or **out of scope** (with the ticket that owns it).
- For every valid finding, the triage subagent produces a concrete solution.
- A finding is not dismissed because it is inconvenient; it is dismissed only with evidence.

## 3. Apply and re-verify

- Apply the solutions for the valid findings, then re-run the gates the ticket names.
- If the fixes were substantial, run one more round. Two rounds at most per key moment; whatever is still open after that goes to the hand-back as an open point.

## 4. Record

- The hand-back lists each finding with its verdict and resolution, and names the model that reviewed.
- If Codex could not be reached at all, do not skip silently: say so in the hand-back and run the same two lenses with subagents on a different model from the author's.
