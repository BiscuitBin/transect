---
title: "Decision 0010: The release process"
kind: "decision"
audience: ["maintainer", "agent"]
canonical_for: ["decision_release_process"]
requires: []
---

# Decision 0010: The release process

## Context

[Decision 0006](0006-single-version.md) gives every crate and the wheel one version. Two
registries receive it: PyPI the `transectpy` wheel and sdist, crates.io the `libtransect`
core and the `transect` client. Neither model repository publishes to crates.io;
pachinko's tag-driven release workflow and its cargo-release configuration are the
nearest shape, with per-crate versions and tags that a single version replaces here.

## Decision

**What is published.** `libtransect` and `transect` go to crates.io with full registry
metadata and their licence text; `transectpy` is `publish = false`, because its
distributable is the wheel `release-pypi.yml` builds.

**Preparing a release.** cargo-release 1.1.7, pinned in `tools.txt` because conda-forge
lacks it, runs on a `release/*` branch with `shared-version` and one consolidated commit.
It moves `[workspace.package] version` and the `[workspace.dependencies]` requirements on
the two crates, and its replacements, held on the `transect` crate so they run once and
each required to match exactly once, move the wheel manifest's version, the excluded fuzz
crate's requirement on the core, and the changelog's `## [Unreleased]` into a dated
`## [<version>] - <date>` heading. `tag`, `push` and `publish` are off: preparing a release
changes the branch and nothing else. The fuzz crate is outside cargo-release's reach, so
its lockfile is refreshed by `just lock` before `just check`. `just version-check` fails
when any of these places disagree, including the requirements and the newest dated
changelog heading.

**Verifying without publishing.** `just package-dry-run` runs
`cargo publish --dry-run --workspace --locked`: it packages both crates in dependency
order and builds `transect` against the freshly packaged, unpublished core through
cargo's temporary local registry. It reads the crates.io index, so it needs the network
and stays outside `just check`.

**One tag, two workflows.** A maintainer tags the release merge commit on `main` with an
annotated `v<version>` by hand. The tag starts `release-pypi.yml` and
`release-crates.yml`, which are independent: the wheel builds from source and needs no
crate on crates.io, and the crates need no wheel. Each runs on tags and on demand, with a
`publish` input that defaults off; each applies the same guards (commit on `main`, the
tag naming the commit and equal to the version, a non-empty changelog section, fatal only
when the run publishes); and each publishes only from a job that runs when publishing,
behind its own environment (`pypi`, `crates-io`) with a required reviewer, that re-checks
the tag after approval. `release-crates.yml` runs the whole gate and the packaging dry run
before its guards. The maintainer approves `crates-io` first, then `pypi`; the order is
written in the how-to rather than enforced, so one registry's failure cannot block the
other's publish.

**Credentials.** crates.io publishes by trusted publishing through
`rust-lang/crates-io-auth-action`; no token is stored. Trusted publishing can only be
configured for a crate that exists, so the first publish of each crate is done by hand by
a maintainer, after which trusted publishing is configured and the token revoked. The
workflow has no token path.

**Partial releases.** The crates publish job publishes the core, then the client, and
skips a version the crates.io index already holds, so re-running it finishes a release
that stopped part-way. A tag is moved only while neither registry holds the version. Once
either does, the tag stays; a change of content ships as the next version of everything.

**Not decided here.** API compatibility checks (cargo-semver-checks) and a GitHub Release
for the tag are deferred, each on the
[open-decisions register](../project/open-decisions.md).

## Consequences

A release costs the PyPI matrix and a full gate run. The maintainer owns release timing
and approves two deployments. Nothing prevents a tag on an unreleased commit of `main`:
the reviewers are the only stop. Until the repository is public, or the organisation is on
GitHub Enterprise, the environments' required reviewers do not hold, so the release
how-to's pre-flight stops a release.

## What would reopen this

A crate or the wheel needing its own release rhythm (decision 0006), a need for
release notes on GitHub or binary assets, automated release pull requests, or the first
API-changing release, which brings the semver question back.

## Related pages

- [Release](../how-to/release.md)
- [Decision 0006: One version](0006-single-version.md)
- [Decision 0005: Dependency policy](0005-dependency-policy.md)
