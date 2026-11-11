---
title: "Scheduled maintenance"
kind: "operations"
audience: ["maintainer", "operator", "agent"]
canonical_for: ["scheduled_workflows", "api_reference_site"]
requires: []
---

# Scheduled maintenance

Four workflows look after the repository between changes. None is a required check:
`ci-ok` in `ci.yml` does not need them, so a red run is a finding for a maintainer, not a
blocked merge.

| Workflow | Runs | What it does | A red run means |
| --- | --- | --- | --- |
| `audit.yml` | Every pull request, Mondays 06:00 UTC, on demand | `just audit`: RustSec advisories for the workspace and the fuzz crate, and yanked releases. | An advisory or a yanked release affects `Cargo.lock` or `fuzz/Cargo.lock`. |
| `fuzz.yml` | Mondays 07:00 UTC, on demand | `just fuzz <target> 300` for each fuzz target, five minutes each. | A crash; the failing input is uploaded as the `fuzz-<target>` artefact for 28 days. |
| `mutants.yml` | Mondays 07:00 UTC, on demand | `just mutants` over `libtransect` and `transect`. | A mutant survived; the `mutants` artefact (28 days) says which. |
| `pages.yml` | Every push to `main`, on demand | `just site`, the API reference built by `just doc` with a root index, uploaded as the Pages artefact. | The site did not build. |

All four use the shared setup action, SHA-pinned actions, read-only default permissions,
a concurrency group and a timeout. The Pages deploy job alone holds `pages: write` and
`id-token: write`, has no checkout, and runs only for `main` in a public repository: while
the repository is private or internal, the build runs and uploads, and the deploy is
skipped rather than failed.

## Running one by hand

Each workflow has a `workflow_dispatch` trigger, which GitHub offers only for workflow
files on the default branch:

```sh
gh workflow run audit.yml --ref main
gh workflow run fuzz.yml --ref main
gh workflow run mutants.yml --ref main
gh workflow run pages.yml --ref main
```

## What to do with a finding

- **Advisory:** update the affected crate within its range (`just lock`), or record why
  the advisory does not apply.
- **Fuzz crash:** reproduce with `just fuzz smoke` locally on the downloaded input, fix it
  in the core, and add a regression test.
- **Surviving mutant:** add the test that kills it.

## Related pages

- [Maintain dependencies](../how-to/maintain-dependencies.md)
- [Quality gates](../reference/quality-gates.md)
