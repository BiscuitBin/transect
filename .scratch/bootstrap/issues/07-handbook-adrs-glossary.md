# 07: Handbook, ADRs and glossary

**What to build:** A newcomer or an agent can read what Transect's application client is, which rules are fixed, which questions are still open, and what each domain word means, and a validator keeps those pages honest. This carries the models' handbook: a documentation tree organised by purpose (project, tutorials, how-to, explanation, reference, operations, decisions), per-page front matter, and a manifest in which every topic is owned by exactly one page, enforced by the shared tooling's documentation validator.

The decisions record what is already settled; an open-decisions page is the single register of what is not, and it must list exactly the stubs created in ticket 06 without proposing answers.

**Adversarial review:** Key moments: after the decisions and the open-decisions page are drafted, before the rest of the handbook; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which page states as decided something that is undecided, or the reverse; which page describes something that does not exist; whether the two shaping rules are stated precisely enough to test against; whether the register and the stubs match.

**Blocked by:** 01, 06

**Status:** ready-for-agent

- [ ] The handbook tree, index page and manifest exist in the models' shape and the documentation validator passes
- [ ] Project pages cover purpose and scope (what the client is, that the collector lives elsewhere, what this repository does not do) and a repository map
- [ ] The glossary defines at least: table, state table, time series table, column, row, ingest queue, data writer, local database, collector, host application; and names words to avoid
- [ ] A decision records the never-raise, never-block rule: the client must not raise into or block the host application, in line with established practice for loggers and metrics clients
- [ ] A decision records the fork-safety rule: correct behaviour under forked worker pools such as gunicorn is a requirement, with the mechanism left open
- [ ] Decisions record crate layering (core, Rust client, Python binding, and the allowed dependency direction), the lint policy as enforcement of never-raise, the dependency policy, single shared versioning, and the supported platforms (Linux and macOS)
- [ ] An open-decisions page lists the ingest queue mechanism, the local database format and schema evolution as undecided, states what each blocks, and offers no design; it also records the open point of whether fork handling will need unsafe code
- [ ] Every UNDECIDED marker in the core corresponds to one entry on the open-decisions page and the reverse
- [ ] Decisions follow the models' numbered format and are indexed
- [ ] Reference and how-to pages exist for what already works (commands, quality gates, local development) and describe nothing that does not exist
- [ ] The documentation validator is a recipe, a hook, part of the ordered check list, and the check command ends green
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
