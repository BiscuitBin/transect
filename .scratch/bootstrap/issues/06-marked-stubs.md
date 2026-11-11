# 06: Marked stubs for the unimplemented areas

**What to build:** Someone opening the core crate sees where each future part of the client will live and can tell at a glance which parts are waiting on a design decision, without any design having been implied. The core gains four placeholder modules that contain only documentation: the ingest queue, the local database and schema evolution, each clearly marked UNDECIDED, and the data writer, marked not yet implemented (its role, a background thread draining the queue into local databases, is settled; what it drains from and writes to is not).

This ticket must not choose or hint at a queue mechanism, a database format or a schema-evolution approach: no types, traits, function signatures, dependencies or feature flags. The lint policy rejects the todo and unimplemented macros, so the stubs are documentation only.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether any wording, name or structure implies a queue mechanism, database format or schema-evolution design; whether anything other than documentation was added.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The core has one placeholder module each for ingest queue, local database, schema evolution and data writer
- [ ] Each of the three undecided modules opens with the same greppable UNDECIDED marker and one or two sentences on the module's responsibility, with no design content
- [ ] The data writer module carries a distinct not-yet-implemented marker and states which undecided areas it waits on
- [ ] The modules contain no items: no types, traits, functions, constants or re-exports, and the core's public API is unchanged
- [ ] The Rust client crate and the Python package gain nothing
- [ ] No dependency or feature is added
- [ ] API docs build without warnings and the check command ends green
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
