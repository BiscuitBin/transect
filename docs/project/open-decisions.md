---
title: "Open decisions"
kind: "project"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["open_decisions"]
requires: []
---

# Open decisions

The single register of what is not yet decided. Nothing here has an answer, a preferred
answer or a shortlist: proposing one is the work of the decision that closes the entry.
Agents and contributors do not choose a design for anything listed here without that
decision.

## Undecided areas

Each entry is one placeholder module in the core whose first line is the marker
`//! UNDECIDED:`. `just check-undecided` fails unless this section and those markers name
exactly the same files.

### The ingest queue

- **Placeholder:** `crates/libtransect/src/ingest_queue.rs`
- **Undecided:** the mechanism that holds recorded rows between the host's call and the
  data writer.
- **Blocks:** any recording API in the Rust client or the Python client, the data writer,
  and the fork-safety mechanism.

### The local database

- **Placeholder:** `crates/libtransect/src/local_database.rs`
- **Undecided:** what the local database is and the format in which it keeps tables on
  the host's machine.
- **Blocks:** the data writer and schema evolution.

### Schema evolution

- **Placeholder:** `crates/libtransect/src/schema_evolution.rs`
- **Undecided:** what happens to a table already recorded when the host changes its
  columns.
- **Blocks:** the data writer, and any API that declares a table's columns.

## Open points

Questions that are not modules of their own.

- **Unsafe code for fork handling.** Whether correct behaviour under fork
  ([decision 0002](../decisions/0002-fork-safety.md)) will need unsafe code, which
  [decision 0004](../decisions/0004-lint-policy-enforces-never-raise.md) forbids in every
  crate. Blocks: the fork-safety mechanism.
- **Caller misuse.** Whether a call the host makes incorrectly is reported to the host,
  and how, within [decision 0001](../decisions/0001-never-raise-never-block.md). Blocks:
  every public API.
- **Data the client cannot accept.** What happens to data the client cannot take without
  raising or blocking. Blocks: the ingest queue's capacity behaviour.
- **Fork-safety assertions.** The test marked `# FORK-SAFETY PLACEHOLDER` in
  `crates/transectpy/tests/test_fork.py` is where the client's behaviour under fork will
  be asserted once the ingest queue, local database and data writer exist; today it
  checks only the version. Blocks: nothing; it waits on the undecided areas.
- **Arithmetic overflow.** Whether overflow in `+`, `-`, `*`, shifts and negation, which
  panics in debug builds and is not linted, gets a lint or a checked-arithmetic rule once
  the client has real arithmetic. Blocks: nothing yet.
- **Free-threaded wheels.** Whether the release workflow also builds `cp314t` wheels for
  free-threaded Python, which the stable ABI does not cover. Blocks: nothing; the abi3
  wheels serve every supported CPython.
- **API compatibility checks.** Whether and when cargo-semver-checks guards the published
  crates' API: proposed as an advisory `just semver` at the first release that changes
  the public API, and a gate before 1.0
  ([decision 0010](../decisions/0010-release-process.md)). Blocks: nothing yet; the API
  is one function.
- **A GitHub Release for the tag.** Whether a release tag also creates a GitHub Release
  from its changelog section, which would give a release job `contents: write`
  ([decision 0010](../decisions/0010-release-process.md)). Blocks: nothing.

## What is already settled

The data writer is not open: its role is a background thread that drains the ingest queue
into local databases. Its placeholder, `crates/libtransect/src/data_writer.rs`, is marked
`NOT YET IMPLEMENTED` because it waits on the three undecided areas above.

## Related pages

- [Architecture decisions](../decisions/README.md)
- [Glossary](glossary.md)
