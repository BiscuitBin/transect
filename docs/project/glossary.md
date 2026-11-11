---
title: "Glossary"
kind: "project"
audience: ["user", "contributor", "maintainer", "operator", "agent"]
canonical_for: ["project_glossary"]
requires: []
---

# Glossary

These words mean one thing here. A term whose design is undecided is defined by its role
only; the [open-decisions register](open-decisions.md) owns the rest.

## Domain

| Term | Meaning |
| --- | --- |
| Table | A named set of rows sharing one set of columns, the unit in which Transect captures application data and in which it is queried once published. |
| State table | A table whose rows describe the current condition of things in the host application. |
| Time series table | A table whose rows record observations made over time. |
| Column | A named field that every row of a table has. |
| Row | One record in a table: a value for each of its columns. |
| Host application | The program that links or imports the client and records data through it. Not "the app" or "the user": the user is a person. |
| Client | This repository's library, running inside the host application. Not "SDK" or "agent". |
| Collector | The separate component that gathers and publishes the tables; it lives outside this repository. |
| Ingest queue | The part of the client that holds recorded rows between the host's call and the data writer. Its mechanism is undecided. |
| Data writer | The client's background thread that drains the ingest queue into local databases. Its role is settled; it is not yet implemented. |
| Local database | Where the data writer keeps tables on the host's machine. What it is and its format are undecided. |
| Schema evolution | What happens to a table already recorded when the host changes its columns. Undecided. |

## Rules and process

| Term | Meaning |
| --- | --- |
| Never raise, never block | The first shaping rule ([decision 0001](../decisions/0001-never-raise-never-block.md)). |
| Fork safety | The second shaping rule ([decision 0002](../decisions/0002-fork-safety.md)). |
| UNDECIDED marker | `//! UNDECIDED:`, the first line of a placeholder module whose design waits on a decision. |
| Gate | A check that must pass before hand-back; `just check` runs them all. |
| Positive control | A deliberate violation, run once and reverted, proving a gate fails when it should. |

## Words to avoid

- "Event" or "metric" for a row: Transect records rows of tables; neither word says which kind of table.
- "Buffer", "channel", "log" or "file" for the ingest queue or local database: each implies an undecided mechanism.
- "Migration" for schema evolution: it implies an approach.
- "SDK", "agent" or "daemon" for the client.
- "Server" for the collector.

## Related pages

- [Purpose and scope](purpose-and-scope.md)
- [Open decisions](open-decisions.md)
