---
name: review-change
description: Review a change in this repository against its invariants, open decisions, tests, and documentation contract.
---

# Review a change

1. Read `AGENTS.md`, `docs/project/open-decisions.md` and
   `crates/transectpy/python/transectpy/_transectpy.pyi`. Review the whole diff.
2. Check the seven invariants in `AGENTS.md` one at a time, and ask of every new panic
   path whether the lint policy (decision 0004) rejects it.
3. Check that no undecided design was chosen: no type, trait, function, dependency or
   feature for a product question the register lists as open, and no wording that
   implies an answer, without a decision record.
4. Check evidence: a unit test or doctest asserts each behaviour; a pytest case exercises
   each exposed item; stubtest covers a stub change. A test that only asserts a function
   was called is insufficient.
5. Check boundaries: the crate direction, PyO3 only in the binding, and a stub change
   matched by the Rust binding and a pytest case.
6. Check documentation ownership: durable facts go on the page owning their topic in
   `docs/manifest.yml`.
7. Check scope: unrelated refactors, new dependencies and speculative abstractions are
   findings in themselves.
8. Report findings by severity with `file:line`, what breaks and the smallest fix. Run
   `just check` before concluding.
