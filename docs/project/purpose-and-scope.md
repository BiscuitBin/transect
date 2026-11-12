---
title: "Purpose and scope"
kind: "project"
audience: ["user", "contributor", "maintainer", "agent"]
canonical_for: ["project_purpose", "project_non_goals"]
requires: []
---

# Purpose and scope

## What Transect is

Transect is an observability tool that captures information about an application, its
runtime and its state, and publishes it so it can be queried.

## What this repository is

This repository holds Transect's in-application client: the library a host application
links or imports. It has three parts, one per crate:

- `libtransect`, the core, where every behaviour of the client will live;
- `transect`, the Rust client API that Rust hosts use;
- `transectpy`, the Python client, published as the `transectpy` package.

Today it is a scaffold. Each part exposes one thing, its version. Its quality gate, CI,
handbook and agent contract are complete; the client's behaviour has not started.

## What this repository does not do

- It does not decide the client's design beyond the three crates. The open questions
  are on the [open-decisions register](open-decisions.md) until a decision is recorded.
- It does not provide a query engine, a server, or a command-line tool.
- It does not support Windows ([decision 0007](../decisions/0007-supported-platforms.md)).

## Related pages

- [Repository map](repository-map.md)
- [Glossary](glossary.md)
- [Open decisions](open-decisions.md)
