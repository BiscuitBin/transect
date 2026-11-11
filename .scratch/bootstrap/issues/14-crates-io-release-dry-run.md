# 14: crates.io release workflow, dry-run only

**What to build:** A maintainer can trigger the Rust release pipeline and see that `libtransect` and `transect` would package and publish cleanly, in dependency order, under the single shared version, without anything being published. Neither model repository publishes to crates.io, so there is nothing to copy for the publish step itself; pachinko's tag-driven release workflow and release-tooling configuration are the closest shape, and its per-crate tags and changelog sections are replaced here by one version, one tag and one changelog. The binding crate is never published to crates.io.

Because this ticket has no direct model, choices that are not forced (the release tool, how the unpublished core dependency is verified in a dry-run, API compatibility checking) are proposed in the hand-back for the maintainer to confirm.

**Adversarial review:** Key moments: after the publishing arrangement is proposed and before it is built, so the maintainer sees a reviewed proposal; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: any path by which a dry-run or a mistaken tag could publish; where the shared version can drift; what happens when the core publishes and the client fails; how the two release workflows interact on one tag.

**Blocked by:** 10, 12

**Status:** ready-for-agent

- [ ] The two publishable crates carry complete registry metadata (description, readme, keywords, categories, docs settings) and the binding crate is marked unpublishable
- [ ] A recipe performs a packaging dry-run for both crates in dependency order and is documented as needing the network
- [ ] Release-tooling configuration bumps the shared version everywhere it appears (workspace, wheel manifest, changelog heading) and creates one tag, with push and publish off by default
- [ ] A recipe or gate fails when the version differs between any of those places
- [ ] The workflow runs on version tags and on demand, re-runs the full check, and applies the same guards as the Python release: tagged commit on main, tag equals version, non-empty changelog section
- [ ] The publish step sits behind a protected environment and cannot run in a dry-run
- [ ] How this workflow and the Python release workflow share one tag is defined (one workflow or two, and their order) and written down
- [ ] An on-demand dry-run has completed green and is quoted in the hand-back, or the hand-back states that authorisation to run it was not given
- [ ] The release how-to page covers the Rust side, including the maintainer-only steps that remain (registry token or trusted publishing, protected environment)
- [ ] A decision records the publishing arrangement and the check command ends green
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
