---
title: "Release to PyPI"
kind: "how-to"
audience: ["maintainer", "agent"]
canonical_for: ["release_procedure"]
requires: []
---

# Release to PyPI

`.github/workflows/release-pypi.yml` builds, smokes and checks every `transectpy`
artefact a release would upload, and publishes them to PyPI by trusted publishing. No
PyPI token is stored anywhere. Nothing has been published yet, the project name is not
registered on PyPI, and the trusted publisher and the `pypi` environment do not exist:
until a maintainer creates them, only the dry run below can succeed.

Each step below is marked **local** (the worktree only), **CI** (a workflow does it) or
**authorised** (changes something outside the worktree; ask first, and approval for one
step is not approval for the next).

## What the workflow does

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
- **`guards`.** Downloads the seven files and checks that the commit is on `main` and is
  the one the tag names, that the tag equals `[project] version`, that `CHANGELOG.md`
  has a non-empty `## [<version>] - <date>` section, and that `dist/` holds exactly six
  abi3 wheels and one sdist, each carrying the version. A run that publishes fails on
  any of them; a dry run reports the commit and changelog guards as warnings, since a
  dry run from a branch or before the changelog is dated is expected.
- **`publish`.** Runs only when the run publishes: a tag push, or a dispatch with
  `publish` true. It waits at the `pypi` environment, attests every file and uploads
  with `uv publish --trusted-publishing always`. A dry run skips it, so it never reaches
  the environment and never holds an OIDC token.

## The dry run

**authorised**. The workflow must be on the default branch before GitHub offers
`workflow_dispatch`.

```sh
gh workflow run release-pypi.yml --ref main -f publish=false
gh run list --workflow release-pypi.yml --event workflow_dispatch --limit 1 \
  --json databaseId,url,createdAt,headSha
gh run watch <id>
```

Confirm `createdAt` is after the dispatch and `headSha` is `main`'s head. Every build
job and `guards` end green and `publish` shows as skipped. Download the artefacts with
`gh run download <id> -D ai_tmp/release/dry-run` and list them: six `cp311-abi3` wheels
and one sdist.

## Before the first release (maintainer only)

**authorised**, each once:

1. Create the `pypi` environment in the repository settings, with a required reviewer
   and deployment rules that admit only `v*` tags and `main`, the refs a publishing run
   starts from. On GitHub Free, Pro or Team, required reviewers exist for public
   repositories only.
2. On PyPI, register a pending trusted publisher for the project `transectpy`: owner
   `BiscuitBin`, repository `transect`, workflow `release-pypi.yml`, environment `pypi`.

## Cutting a release

1. **local** On a release branch, move the version as
   [decision 0006](../decisions/0006-single-version.md) requires: the workspace
   `version`, the `libtransect` and `transect` entries in `[workspace.dependencies]`, and
   `[project] version` in `crates/transectpy/pyproject.toml`.
2. **local** In `CHANGELOG.md`, rename `## [Unreleased]` to `## [<version>] - <UTC date>`
   and add a new empty `## [Unreleased]` above it. The changelog guard reads the lines
   under that heading up to the next heading or the link lines, so the prefix must be
   exact.
3. **local** `just version-check`, then `just check`, which must end with
   `All checks passed and the worktree is unchanged.`
4. **authorised** Push the branch, open a pull request and merge it once `ci-ok` is green.
5. **authorised** Run the dry run above on `main` if the workflow or the matrix changed
   since the last green one.
6. **authorised** On `main` at the merge commit, `git tag -a v<version> -m 'transectpy
   <version>'` and `git push origin v<version>`. **CI** builds and smokes again, the
   guards run as errors, and `publish` waits at the `pypi` environment.
7. **authorised** Approve the `pypi` deployment. This approval is the publish.

If a job is red before the approval, nothing has reached PyPI. Fix the workflow through
a pull request, then, separately authorised, delete the tag and tag the new merge commit.
A PyPI version can never be uploaded twice.

## Not decided here

- Free-threaded (`cp314t`) wheels are not built; whether to add them is on the
  [open-decisions register](../project/open-decisions.md).
- How a tag also releases the Rust crates, and whether a GitHub Release is created, is
  settled with the crates.io release process.

## Related pages

- [Decision 0006: one version](../decisions/0006-single-version.md)
- [Decision 0007: supported platforms](../decisions/0007-supported-platforms.md)
- [Maintenance](../operations/maintenance.md)
