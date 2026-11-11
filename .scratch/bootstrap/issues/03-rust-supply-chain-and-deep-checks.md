# 03: Rust supply chain and deep checks

**What to build:** A dependency with an unacceptable licence, source or advisory cannot enter the workspace unnoticed, and the slower verification tools are wired and proven to run even though there is nothing substantial for them to find yet. This carries the models' dependency policy (licence allow-list, crates.io as the only source, wildcard versions denied, yanked crates denied), the unused-dependency check, snapshot-test recipes, a separate fuzz workspace with one smoke target against the core, a benchmark stub, and a mutation-testing recipe.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the dependency policy would really reject a bad licence, git source or wildcard; whether the fuzz target and mutation run exercise anything; which check silently skips the fuzz workspace.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The dependency policy file matches the models, with the target list reduced to the Linux and macOS triples this project ships
- [ ] A recipe checks licences, bans and sources offline; a separate recipe checks advisories and is documented as needing the network
- [ ] A recipe reports unused dependencies
- [ ] Snapshot recipes (check, review, accept) exist and the check passes with no snapshots present
- [ ] A fuzz crate outside the workspace, with its own lockfile and a hand-copied lint table, has one smoke target exercising the core's only public item; recipes build it and run it for a bounded time on the stable toolchain
- [ ] The core has one benchmark over its public item, run by a recipe and never part of the gate
- [ ] A mutation-testing recipe runs over the pure-Rust crates and first proves its mutant list is not empty
- [ ] Format, clippy, lock and sync recipes cover the fuzz workspace as well as the root
- [ ] The offline gates (policy, unused dependencies, snapshot check, fuzz build) are in the ordered check list and the check command ends green
- [ ] CI has a `deny` job for the policy check
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
