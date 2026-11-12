---
name: plan-change
description: Plan a change when the scope, affected decisions, risks, or validation need evidence before any code is written.
---

# Plan a change

1. Read `AGENTS.md`, the ticket if there is one, and the decision records the change
   touches. Separate what you read from what you are guessing.
2. Inspect the worktree before proposing anything, and preserve work you did not author.
   Run `just check` on the untouched worktree and quote its last line as the baseline.
3. Write down the observable outcome and explicit non-goals, so the scope can be reviewed.
4. Check `docs/project/open-decisions.md`. If the change needs an answer to an open
   question there, stop: that is a decision for the maintainer, not part of the plan.
5. Identify the boundaries crossed: the crate direction of invariant 1, the Python API's
   shape (`crates/transectpy/python/transectpy/_transectpy.pyi` is canonical), and a new
   topic's owning page in `docs/manifest.yml`. An exposed API change moves the stub, the
   Rust binding and a pytest case together.
6. Name the risks and the evidence that would settle them, and say which actions need
   authorization the agent does not already have.
7. Split into independently verifiable steps, each pairing behaviour, test and
   documentation. Confirm the work runs green with `just check` before treating it as done.
