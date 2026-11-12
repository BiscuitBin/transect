# Security policy

## Reporting a vulnerability

Report suspected vulnerabilities privately through
[GitHub's private vulnerability reporting](https://github.com/BiscuitBin/transect/security/advisories/new)
on `BiscuitBin/transect`. Please do not open a public issue for anything you believe is
exploitable.

Include the affected commit, what you did, what happened and what you expected. A small
program or sequence of commands that reproduces the problem helps us investigate.

## Supported versions

Nothing has been released, so only `main` is supported. Fixes land on `main`, with no
backports.

## What is in scope

- Vulnerabilities in `libtransect`, `transect` or the `transectpy` binding and package.
- Credential material committed to this repository.
- A tampered dependency, tool binary or GitHub Action, or a lockfile that disagrees with
  its manifest.

## Out of scope

Any service maintained outside this repository is outside this policy. A vulnerability
originating in these crates or their build tooling is still in scope when discovered
through a consumer.

## What this project already does

- Every crate forbids unsafe code through its lint table
  ([decision 0004](docs/decisions/0004-lint-policy.md)).
- `Cargo.lock`, `fuzz/Cargo.lock` and `pixi.lock` are committed, the cargo gates that
  resolve dependencies pass `--locked` (the snapshot and fuzz recipes check the locks
  first and run offline), and wheel builds use maturin's `locked = true`
  ([decision 0005](docs/decisions/0005-dependency-policy.md)).
- `cargo deny` checks licences, bans and sources in every `just check`; the audit
  workflow checks the locked Rust dependencies against RustSec advisories on pull
  requests and weekly.
- The compiler and tools are pinned, and remote hooks and GitHub Actions are pinned to
  commit SHAs.
- The hook gate scans for secrets, with matched values redacted from its output.
