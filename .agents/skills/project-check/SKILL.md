---
name: project-check
description: Bring a workspace to a state where the full gate runs, and interpret what it reports.
---

# Run the full gate

1. Read `AGENTS.md`. The `Justfile` is the only interface to the checks; use its recipes
   rather than assembling an equivalent pipeline by hand.
2. Check prerequisites: rustup's cargo first on `PATH` (`just check-toolchain` proves
   it), the pixi environment at `.pixi/envs/default`, `.tools/bin` with cargo-hack,
   cargo-fuzz and rustqual, `.tools/python` with the floor interpreter, a C++ compiler,
   and Rosetta on Apple silicon. `just initialize` creates what is missing; it downloads,
   so it needs explicit authorization unless the task already grants it.
3. Run `just check`. It runs the gates `docs/reference/quality-gates.md` lists, in that
   order, snapshotting the worktree between them, then `check-clean`.
4. Read only the first failure and rerun the named recipe. Later failures often follow
   from earlier ones.
5. A recipe that changes the worktree is defective: checks are read-only; `just fix` is
   where mutation belongs.
6. Hand a failing gate to `fix-quality` rather than working around it.
7. Report success only when `just check` ends with
   `All checks passed and the worktree is unchanged.` and `git status --short` prints
   nothing after the commit. Quote outputs against the commit actually tested.
