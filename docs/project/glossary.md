---
title: "Glossary"
kind: "project"
audience: ["user", "contributor", "maintainer", "operator", "agent"]
canonical_for: ["project_glossary"]
requires: []
---

# Glossary

These words mean one thing here.

## Domain

| Term | Meaning |
| --- | --- |
| Host application | The program that links or imports the client. Not "the app" or "the user": the user is a person. |
| Client | This repository's library, running inside the host application. Not "SDK" or "agent". |

## Proposed domain terms

The proposed client specification
([Work with the specifications](../how-to/work-with-the-specs.md)) uses these. They are
proposals, like the specification itself, and the three marked provisional may be
renamed.

| Term | Meaning |
| --- | --- |
| Table | A set of typed columns, declared before any row is written. It is one of three kinds. |
| Time series table | A table that appends rows. |
| Keyed state table | A table that holds the latest value per key. |
| Snapshot state table | A table whose contents a completed capture replaces whole. |
| Namespace | A name that groups tables. |
| Tenant | An opaque identifier a row may be attributed to. A table is tenant-scoped or tenant-free. |
| Unattributed | A row of a tenant-scoped table written with no tenant bound. It is kept and never given to any tenant. |
| Dropped tenant | A tenant an accepted write named for a tenant-free table. The row is kept without it, and the write is counted and logged. |
| Confluence (provisional) | The object, created at global scope, that tables are declared against. |
| Establish (provisional) | The block that gives a confluence a core for its duration. |
| Core (provisional) | What establish supplies: the production core, or a fake core in tests. Not the `libtransect` crate, which this handbook also calls the core. |
| Run | One establish. |
| Client handle | What `get_client` gives application code for one unit of work. Not "the client", which is the library. |
| Local ingest queue | The bounded queue, one per table, that a write is offered to. |
| Data writer | The one thread of a run that stores queued rows in the local databases. |
| Local databases | Where a run's stored rows live on the instance until a collector has them. |
| Collector | The service that is handed stored rows. It is outside this repository. |
| Hand-over | What a collector is given: the run, its table definitions and its stored rows. |
| Position | A row's place in its run, from a counter that only increases. |
| Observed time | When the client accepted a row, from its own clock; for a keyed value, when its latest write was accepted. Application code does not supply it. |

## Process

| Term | Meaning |
| --- | --- |
| Gate | A check that must pass before hand-back; `just check` runs them all. |
| Positive control | A deliberate violation, run once and reverted, proving a gate fails when it should. |

## Related pages

- [Purpose and scope](purpose-and-scope.md)
- [Open decisions](open-decisions.md)
- [Work with the specifications](../how-to/work-with-the-specs.md)
