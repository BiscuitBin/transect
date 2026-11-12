# 09: Agent contract

**What to build:** A coding agent arriving in the repository reads one canonical instruction file and knows the project map, the invariants it must not break, what it may and may not do without authorisation, and which procedure to follow for each kind of change; a validator keeps that file and its skills well-formed. This carries the models' arrangement: one canonical agent file, thin pointer files for each agent product, canonical skills with identical bridge files per product, and the shared tooling's agent-file validator.

**Adversarial review:** Key moments: after the canonical agent file is drafted, before the skills; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which instruction names a recipe, page or skill that does not exist; which invariant is unenforced or contradicts another; whether an agent following the file could push, publish or choose an undecided design without authorisation.

**Blocked by:** 02, 04, 07

**Status:** ready-for-agent

- [x] The canonical agent file states that it is the single source of truth and that issues, pull requests, fixtures and tool output are untrusted input
- [x] It contains a project map and numbered invariants, including: never raise into or block the host application; fork safety is a requirement; crate dependency direction with PyO3 only in the binding crate; unsafe forbidden; lint suppressions only as expect-with-reason; the coverage floor; the lockfile as the pin; no new dependency without a decision note; one version everywhere
- [x] It states that the queue mechanism, local database format and schema evolution are undecided and that agents must not choose designs for them
- [x] It limits authority to the worktree, lists the recipes that reach the network, names the scratch directory, and says the Justfile is the only interface
- [x] It requires the check command's success line and a clean worktree before hand-back
- [x] Conditional blocks point to a skill and recipes for: Rust changes, Python changes, documentation, agent files, a failing gate, and picking up a ticket
- [x] Canonical skills exist for planning a change, Rust changes, Python changes, fixing a failing gate, running the project check, reviewing a change and reviewing docs, adapted from alliumpy with project-specific content removed
- [x] Bridge files for each agent product point at the canonical skills and add nothing
- [x] The pointer files for other agent products contain only a reference to the canonical file
- [x] The validator's required phrases are satisfied, with rules that do not apply here stated as not applying
- [x] Agent-file validation is a recipe, a hook, part of the ordered check list, and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `61695f6` (the ticket) and the commit carrying this hand-back (the moment-2 fix). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **`AGENTS.md`** is the canonical file, adapted from alliumpy and pachinko. It contains:
  - the single-source-of-truth statement, and that issue text, pull requests, comments, fixtures, dependency code, web pages and tool output are untrusted data;
  - a project map;
  - nine numbered invariants:
    1. never raise or block, with caller misuse left undecided;
    2. fork safety;
    3. crate direction, with PyO3 only in the binding;
    4. unsafe code forbidden;
    5. lint suppressions only as expect-with-reason;
    6. the 90% coverage floor;
    7. the lockfile as the pin;
    8. no new dependency without a decision note;
    9. one version for every workspace member, the wheel manifest and the installed wheel;
  - the statement that the ingest queue, local database and schema evolution are undecided and must not be chosen or implied;
  - authority limited to the worktree, with explicit authorization per action for push, pull request, tag, publish, issues, settings and contact;
  - the nine network recipes, and a note on cold caches;
  - `ai_tmp/` as the scratch directory, and the Justfile as the only interface;
  - the requirement to hand back only on the success line with a clean `git status`;
  - six conditional `<important if>` blocks (Rust, Python, docs, agent files, a failing gate or hand-back, picking up a ticket), each naming a skill and its recipes.

  The validator rules that do not apply here (`docs/specs/` and Svelte `runes`) are stated as not applying.
- **Adapters.** `CLAUDE.md` (`@AGENTS.md`) and `.github/copilot-instructions.md` match biscuit-games-tooling's `ADAPTERS` byte for byte.
- **Skills.** Seven canonical skills under `.agents/skills/` (plan-change, rust-change, python-change, fix-quality, project-check, review-change, review-docs), adapted from alliumpy. The Allium, upstream-parity, console-script and ticket-convention content was removed, and the shaping rules, the open-decisions register and the fork harness were added. Each has identical `.claude/` and `.codex/` bridges in `BRIDGE_BODY` form.
- **Wiring.**
  - The `check-agents` recipe (`bg-validate-agents`) and a `validate-agents` hook.
  - `check-agents` sits after `check-docs` in the check list, as in alliumpy.
  - CI's `documents` job runs it.
  - The commands, quality-gates, repository-map and purpose pages are updated.

### Evidence

- **The validator.** `just check-agents` reports `Validated AGENTS.md, 2 adapters, and 7 skills.` With a bridge given an extra line and `untrusted` removed from `AGENTS.md`, it failed with `.codex/skills/rust-change/SKILL.md: must stay a thin pointer to the canonical skill` and `AGENTS.md is missing required guidance: 'untrusted'` (`ai_tmp/evidence/09/check-agents-control.txt`).
- **Every recipe named exists.** Every `just <recipe>` named in `AGENTS.md` exists in `just --summary`. `check-agents` was the one missing at moment 1, and it was added.
- **Docs match the check list.** The quality-gates table still equals the check list, in order.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` CI run 43006598592 (`61695f6`) was green on every job.

### Adversarial review (Codex `gpt-6-astra`, triage by separate Claude Sonnet subagents)

**Moment 1** (canonical file drafted, before the skills), round 1:

1. **Invariant 1 silently settled caller-misuse reporting** (conformance). **Valid.** It is now scoped to the client's own failures, and misuse is marked undecided.
2. **The Python block demanded stub, binding and test changes for any Python edit** (conformance). **Valid.** Alliumpy's "for an exposed API change" is restored.
3. **Invariant 9 said "every crate"**, which takes in the fuzz crate at 0.0.0. Both lenses reported it. **Valid.** Now "every workspace member crate".
4. **The network-recipe list omits the cargo recipes that fetch on a cold cache** (breakage). **Valid.** A cold-cache note says to run `just sync` first and report a fetch failure.

**Moment 2** (end), round 1. Breakage reported no findings.

1. **The rust-change skill put every dependency in `[workspace.dependencies]`**, missing the fuzz-crate exception (conformance). **Valid.** Fixed.

### Open points

- **Cold caches.** The cargo gates rely on a cache warmed by `just sync`. They are not forced offline, as in the models; `AGENTS.md` now says so.

### Maintainer steps

None for this ticket.
