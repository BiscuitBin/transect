---
title: "Decision 0009: A read-only hook gate and a separate fixer"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_hooks"]
requires: []
---

# Decision 0009: A read-only hook gate and a separate fixer

Carried from alliumpy decision 0002 and pachinko's equivalent.

## Context

A commit hook that rewrites files hides the defect it found and stages a change nobody
reviewed. A gate that only reports leaves the repair to a person, unless something else
does it on request.

## Decision

prek runs two configurations. `.pre-commit-config.yaml` is the gate: installed as the
commit hook by `just install-hooks` and run whole by `just lint`, it may only report. It
holds the builtin file checks, EditorConfig, markdownlint, typos, the offline link check
(with an online variant at a manual stage), shellcheck, actionlint, the secret scan from
biscuit-games-tooling, and local hooks that call Justfile recipes. Clippy is deliberately
not a hook, because a cold build would block every commit for minutes.
`.pre-commit-fix.yaml` holds every fixer, is never installed, and runs only from
`just fix`. Every remote hook is pinned to a full commit hash with a version comment.
Hooks are installed only from the primary checkout, because every worktree shares one
hooks directory.

## Consequences

A contributor sees what is wrong at commit time and repairs it with one command, and the
diff shows every repair.

## What would reopen this

A hook runner that can prove a fixer changed nothing, which would let the two merge.

## Related pages

- [Quality gates](../reference/quality-gates.md)
- [Commands](../reference/commands.md)
