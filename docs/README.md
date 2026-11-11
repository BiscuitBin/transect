---
title: "Documentation map"
kind: "project"
audience: ["user", "contributor", "maintainer", "operator", "agent"]
canonical_for: ["documentation_navigation"]
requires: []
---

# Documentation map

Every page below is registered in `manifest.yml`, owns at least one topic, and is
reachable from here; `just check-docs` enforces all three.

Transect captures application data as tables, state and time series, so that it can be
queried with SQL once published. This repository holds Transect's in-application
client: a Rust core, a Rust client API and a Python client. It is a scaffold: the client
has no behaviour yet beyond reporting its version.

## Start here

- [Purpose and scope](project/purpose-and-scope.md): what the client is, and what this repository does not do.
- [Repository map](project/repository-map.md): where everything lives.
- [Glossary](project/glossary.md): the words this repository uses precisely.
- [Open decisions](project/open-decisions.md): what is not decided yet, and what each blocks.
- [Clone to green](tutorials/clone-to-green.md): from a fresh clone to a passing gate.

## How to

- [Develop locally](how-to/develop-locally.md)

## Understand

- [Architecture](explanation/architecture.md): the crates, and where the client's future parts live.

## Look up

- [Commands](reference/commands.md)
- [Quality gates](reference/quality-gates.md)

## Decide

- [Architecture decisions](decisions/README.md)

## Run it

- [Troubleshooting](operations/troubleshooting.md)
