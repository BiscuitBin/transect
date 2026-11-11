# 12: Maintainer docs

**What to build:** The entry points a visitor reads first describe what exists rather than what was planned. The README says what Transect is (application data captured as tables, state and time series, queryable with SQL once published), what this repository holds (the in-application client: Rust core, Rust client API, Python client), that it is a scaffold with no implementation yet, how to get from clone to green, and where the handbook is. The changelog, security policy and per-crate READMEs follow the models, with a single changelog for the single shared version.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which sentence describes a feature, command, badge or link that does not exist on main; whether a reader could mistake the scaffold for a working client.

**Blocked by:** 10

**Status:** ready-for-agent

- [x] The README covers: what Transect is, what this repository is and is not (the collector is elsewhere), current status as scaffold only, the two shaping rules, quick start, handbook and API docs links, licence
- [x] The README shows no install command, usage example or badge for anything that does not exist yet
- [x] The changelog is in Keep a Changelog form with one unreleased section describing the foundation in a few lines, in the single-version shape of alliumpy
- [x] The security policy says how to report a vulnerability privately, what is supported and what is in scope; the reporting contact is confirmed with the maintainer
- [x] Each crate has a README saying what it is for and that its API is one item today; the binding crate's README is the PyPI long description for `transectpy` and describes only what the wheel does
- [x] Every link in these files resolves, checked online with authorisation
- [x] The stub entry files from ticket 01 are gone and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `6d34884` and the commit carrying this hand-back, on `complete-bootstrap`, draft PR #2.

### What was built

- **`README.md`** covers:
  - what Transect is, and what this repository is and is not (the collector lives elsewhere);
  - its status as a scaffold, with the open decisions;
  - the two shaping rules (decisions 0001 and 0002) and the supported platforms;
  - a quick start (`just initialize`, `just check`);
  - links to the handbook and the tutorial;
  - how to build the API reference locally, with a note that the Pages workflow publishes it only once the repository is public;
  - the licence.

  It has no badge, install command or usage example.
- **`CHANGELOG.md`** follows Keep a Changelog. It has one `## [Unreleased]` section for the single shared version (decision 0006).
- **`SECURITY.md`**, after pachinko's and alliumpy's:
  - reports go through GitHub private vulnerability reporting, the route the maintainer settled;
  - only `main` is supported;
  - it sets out what is in scope and what is out of scope;
  - it lists the controls the project already has.
- **Crate READMEs.** Each crate has one: `crates/libtransect/README.md`, `crates/transect/README.md` and `crates/transectpy/README.md`.
  - Each states that the API is one item today.
  - Each manifest sets `readme = "README.md"`.
  - `crates/transectpy/pyproject.toml` sets `readme`, so the transectpy README is the wheel's long description.
- **Repository map.** The repository map now describes the entry files and the crate READMEs. The ticket-01 stub wording is gone.

### Evidence

- **Long description.** `just wheel` produced METADATA with `Description-Content-Type: text/markdown` and the transectpy README as its body.
- **Links.** `just check-links-online` (authorised) passed with `Lychee online (manual)....Passed`. A verbose run reported `🔍 114 Total 🔗 28 Unique ✅ 114 OK 🚫 0 Errors`.
- **Gate.** `just check`: `All checks passed and the worktree is unchanged.`

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

The review ran once, at the end, round 1. The reviewers were asked two questions:

- **Does any sentence describe something absent from main?** Neither lens reported a feature, command, badge or link that does not exist.
- **Could a reader mistake the scaffold for a working client?** Neither lens reported this.

Findings:

1. **Conformance 1.** `SECURITY.md` said every dependency-resolving cargo gate passes `--locked`. It omitted the snapshot and fuzz exceptions. **Valid (low).** The exceptions are now stated, as decision 0005 states them.
2. **Breakage 1.** GitHub private vulnerability reporting is a public-repository feature, so the only reporting route is unusable while the repository is internal. **Invalid as a defect of this change**: the maintainer settled the route, and enabling it was already a maintainer step. It is handed back as an open point.

### Open points

- **No working reporting route yet.** `SECURITY.md` routes reports to GitHub private vulnerability reporting, which exists only for public repositories. Until the repository is public and the feature is enabled, the policy has no usable channel. An interim internal route is the maintainer's decision.

### Maintainer steps

- When the repository becomes public, enable private vulnerability reporting. Until then, decide on an interim route for internal reporters.
