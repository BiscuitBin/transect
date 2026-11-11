---
title: "Purpose and scope"
kind: "project"
audience: ["user", "contributor", "maintainer", "agent"]
canonical_for: ["project_purpose", "project_non_goals"]
requires: []
---

# Purpose and scope

## What Transect is

Transect captures data from inside running applications as tables, of two kinds: state
tables and time series tables. Once published, those tables can be queried with SQL.

## What this repository is

This repository holds Transect's in-application client: the library a host application
links or imports to record its data. It has three parts, one per crate:

- `libtransect`, the core, where every behaviour of the client will live;
- `transect`, the Rust client API that Rust hosts use;
- `transectpy`, the Python client, published as the `transectpy` package.

Today it is a scaffold. Each part exposes one thing, its version, and the places where
the ingest queue, the local database, schema evolution and the data writer will live are
documentation-only placeholders. Its quality gate, CI, handbook and agent contract are
complete; its client behaviour has not started.

Two rules shape everything the client will do: it never raises into or blocks the host
application ([decision 0001](../decisions/0001-never-raise-never-block.md)), and it
behaves correctly when the host forks
([decision 0002](../decisions/0002-fork-safety.md)).

## What this repository does not do

- It does not contain the collector. The collector, which gathers and publishes the
  tables, lives elsewhere; nothing here assumes how it works.
- It does not decide the ingest queue mechanism, the local database format or schema
  evolution. Those are on the [open-decisions register](open-decisions.md) until a
  decision is recorded.
- It does not provide a query engine, a server, or a command-line tool.
- It does not support Windows ([decision 0007](../decisions/0007-supported-platforms.md)).

## Related pages

- [Repository map](repository-map.md)
- [Glossary](glossary.md)
- [Open decisions](open-decisions.md)
