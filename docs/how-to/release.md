---
title: "Cut a release"
kind: "how-to"
audience: ["maintainer", "agent"]
canonical_for: ["release_procedure"]
requires: []
---

# Cut a release

A release publishes the one version ([decision 0006](../decisions/0006-single-version.md))
to two registries from one annotated `v<version>` tag on `main`:
`.github/workflows/release-pypi.yml` publishes the `transectpy` wheels and sdist to PyPI,
and `.github/workflows/release-crates.yml` publishes `libtransect` and then `transect` to
crates.io. Both use trusted publishing, and no registry token is stored anywhere.
[Decision 0010](../decisions/0010-release-process.md) records why the process has this
shape. Nothing has been published yet, neither registry knows the names, and the
trusted publishers and the `pypi` and `crates-io` environments do not exist: until a
maintainer creates them, only the dry runs below can succeed.

Each step below is marked **local** (the worktree only), **CI** (a workflow does it) or
**authorised** (changes something outside the worktree; ask first, and approval for one
step is not approval for the next).

## What the PyPI workflow does

It runs on a `v<major>.<minor>.<patch>` tag push and on demand. A dispatch has one input,
`publish`, which defaults to false.

- **Build jobs.** One cp311-abi3 wheel for each of
  [decision 0007](../decisions/0007-supported-platforms.md)'s six targets (manylinux and
  musllinux on x86_64 and aarch64, macOS on x86_64 and arm64), built from the locked
  dependency set, plus the sdist. Each wheel is installed into a fresh Python 3.11
  environment and import-smoked with `tests/fixtures/smoke/smoke.py`: on the runner, or
  in a pinned `python:3.11` container (aarch64 under QEMU) where the runner cannot run
  it. The sdist's contents are asserted, and every job runs `twine check --strict` on
  what it built.
- **`guards`.** Downloads the seven files and checks that the commit is on `main`, that a
  run started from a tag (pushed or dispatched) builds the commit the tag names and that
  the tag equals `[project] version`, that `CHANGELOG.md`
  has exactly one `## [<version>] - YYYY-MM-DD` section holding a line that is not a
  heading, and that `dist/` holds exactly six
  abi3 wheels and one sdist, each carrying the version. A run that publishes fails on
  any of them; a dry run reports the commit and changelog guards as warnings, since a
  dry run from a branch or before the changelog is dated is expected.
- **`publish`.** Runs only when the run publishes: a tag push, or a dispatch with
  `publish` true. It waits at the `pypi` environment, then refuses to go on if the tag
  no longer names the commit the guards verified, attests every file and uploads
  with `uv publish --trusted-publishing always`. A dry run skips it, so it never reaches
  the environment and never holds an OIDC token.

## What the crates.io workflow does

The same triggers and `publish` input.

- **`verify`.** Read-only and without an OIDC token: `just initialize`, the whole
  `just check`, then `just package-dry-run`, which packages both crates in dependency
  order and builds `transect` against the freshly packaged, unpublished core. Then the
  same commit, version and changelog guards as the PyPI workflow, against the workspace
  version, fatal only when the run publishes.
- **`publish`.** Runs only when the run publishes, behind the `crates-io` environment. It
  checks out the verified commit, re-checks the tag after approval, exchanges the run's
  OIDC token for a short-lived crates.io token, and publishes `libtransect`, then
  `transect`, skipping a version the crates.io index already holds.

## The dry runs

**authorised**. A workflow must be on the default branch before GitHub offers
`workflow_dispatch`.

```sh
gh workflow run release-pypi.yml --ref main -f publish=false
gh workflow run release-crates.yml --ref main -f publish=false
gh run list --event workflow_dispatch --limit 2 \
  --json databaseId,workflowName,url,createdAt,headSha
gh run watch <id>
```

Confirm `createdAt` is after the dispatch and `headSha` is `main`'s head. In the PyPI run
every build job and `guards` end green and `publish` shows as skipped; download the
artefacts with `gh run download <id> -D ai_tmp/release/dry-run` and list them: six
`cp311-abi3` wheels and one sdist. In the crates.io run `verify` ends green and `publish`
shows as skipped. `just package-dry-run` runs the packaging part locally from a clean
worktree.

## Pre-flight

**read-only network**, before every release. Read the plan, the visibility and both
environments:

```sh
gh api orgs/BiscuitBin --jq .plan.name
gh api repos/BiscuitBin/transect --jq '{visibility, permissions}'
for env in pypi crates-io; do
  gh api "repos/BiscuitBin/transect/environments/$env" \
    --jq '{protection_rules, deployment_branch_policy}'
done
```

A 404 or any other error stops the release; GitHub also answers 404 to a token that may
not read the resource. A plan name of `null` means the token cannot read the plan: stop
and ask an organisation owner rather than infer it. Each environment must show a
`required_reviewers` rule and a deployment policy admitting only `v*` tags and `main`.

Required reviewers and artifact attestations exist only for public repositories unless
the organisation is on GitHub Enterprise. While this repository is private or internal on
another plan, the approval gate would not hold and the attestation would fail, so the
release stops; publishing anyway is a decision to record first.

## Before the first release (maintainer only)

**authorised**, each once:

1. Create the `pypi` environment in the repository settings, with a required reviewer
   and deployment rules that admit only `v*` tags and `main`, the refs a publishing run
   starts from. On GitHub Free, Pro or Team, required reviewers exist for public
   repositories only.
2. Create the `crates-io` environment the same way.
3. On PyPI, register a pending trusted publisher for the project `transectpy`: owner
   `BiscuitBin`, repository `transect`, workflow `release-pypi.yml`, environment `pypi`.
4. crates.io configures trusted publishing only for a crate that exists, so the first
   version of each crate is published by hand: from a clean checkout of the release
   merge commit on `main`, with a crates.io API token scoped to publishing new crates,
   run `cargo publish --locked -p libtransect`, then `cargo publish --locked -p transect`.
   Then, on crates.io, configure trusted publishing for both crates (repository
   `BiscuitBin/transect`, workflow `release-crates.yml`, environment `crates-io`) and
   revoke the token. The workflow has no token path; from the second release on it
   publishes the crates itself.

## Cutting a release

1. **local** `git switch -c release/v<version>` from an up-to-date `main`, then
   `PATH="$PWD/.tools/bin:$PATH" cargo release <level> --workspace --execute` with
   `<level>` `patch`, `minor` or `major` (the pinned binary `just install-tools` installs
   lives in `.tools/bin`, which only recipes put on PATH). In one commit it moves the workspace version, the `[workspace.dependencies]`
   requirements, `[project] version` in `crates/transectpy/pyproject.toml` and the fuzz
   crate's requirement, and inserts `## [<version>] - <UTC date>` below
   `## [Unreleased]` in `CHANGELOG.md`, so the unreleased entries become that version's.
   It does not tag, push or publish. The changelog guards read the lines under that
   heading up to the next heading or the link lines.
2. **read-only network** `just lock`, which refreshes `fuzz/Cargo.lock` for the new
   version (cargo-release cannot reach the excluded fuzz crate), then
   `git commit --amend --no-edit fuzz/Cargo.lock` on the release branch.
3. **local** `just check`, which must end with
   `All checks passed and the worktree is unchanged.` It rebuilds the wheel before
   `version-check` compares every place the version is written.
4. **authorised** Push the branch, open a pull request and merge it once `ci-ok` is green.
   If the merge lands on a later UTC day than the heading, a one-line pull request
   re-dates it before the tag.
5. **read-only network** Run the pre-flight above; it must pass.
6. **authorised** Run the dry runs above on `main` if a release workflow or the matrix
   changed since the last green one.
7. **authorised** On `main` at the merge commit, `git tag -a v<version> -m 'transect
   <version>'` and `git push origin v<version>`. **CI** runs both workflows: the guards
   run as errors, and each `publish` job waits at its environment.
8. **authorised** Approve the `crates-io` deployment, then the `pypi` one. Each approval
   is that registry's publish. The order is a convention, not enforced, so one
   registry's failure never blocks the other.

If a job is red before the approvals, nothing has reached either registry. A tag is moved only while
nothing has been published from it: first reject or cancel every run waiting at an
environment for that tag, fix the workflow through a pull request, then, separately
authorised, delete the tag and tag the new merge commit. Once a registry holds the
version, the tag is never moved or deleted; a retry re-runs the failed `publish` job, and
any change of content ships as a new version of everything. A version can never be
uploaded twice to either registry. If `libtransect` published and `transect` failed,
re-run the crates `publish` job: it skips the published core.

## Not decided here

- Free-threaded (`cp314t`) wheels are not built; whether to add them is on the
  [open-decisions register](../project/open-decisions.md).
- API compatibility checks and a GitHub Release for the tag are deferred; both are on the
  [open-decisions register](../project/open-decisions.md).

## Related pages

- [Decision 0010: the release process](../decisions/0010-release-process.md)
- [Decision 0006: one version](../decisions/0006-single-version.md)
- [Decision 0007: supported platforms](../decisions/0007-supported-platforms.md)
- [Maintenance](../operations/maintenance.md)
