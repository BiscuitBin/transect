# 12: Maintainer docs

**What to build:** The entry points a visitor reads first describe what exists rather than what was planned. The README says what Transect is (application data captured as tables, state and time series, queryable with SQL once published), what this repository holds (the in-application client: Rust core, Rust client API, Python client), that it is a scaffold with no implementation yet, how to get from clone to green, and where the handbook is. The changelog, security policy and per-crate READMEs follow the models, with a single changelog for the single shared version.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which sentence describes a feature, command, badge or link that does not exist on main; whether a reader could mistake the scaffold for a working client.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] The README covers: what Transect is, what this repository is and is not (the collector is elsewhere), current status as scaffold only, the two shaping rules, quick start, handbook and API docs links, licence
- [ ] The README shows no install command, usage example or badge for anything that does not exist yet
- [ ] The changelog is in Keep a Changelog form with one unreleased section describing the foundation in a few lines, in the single-version shape of alliumpy
- [ ] The security policy says how to report a vulnerability privately, what is supported and what is in scope; the reporting contact is confirmed with the maintainer
- [ ] Each crate has a README saying what it is for and that its API is one item today; the binding crate's README is the PyPI long description for `transectpy` and describes only what the wheel does
- [ ] Every link in these files resolves, checked online with authorisation
- [ ] The stub entry files from ticket 01 are gone and the check command ends green
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
