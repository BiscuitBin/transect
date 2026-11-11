---
name: fix-quality
description: Diagnose and repair a failing quality gate at its root instead of suppressing the finding.
---

# Fix a failing gate

1. Read `AGENTS.md`, then reproduce with the narrowest recipe: `just check` names the
   failed recipe; run that one alone and read its first failure.
2. Dispatch on which gate failed:
   - `check-toolchain`: cargo is not rustup's proxy, an override outranks the pin, or
     `RUSTC` is set. `docs/operations/troubleshooting.md` has each message.
   - `lock-check`: run `just lock`, a network recipe needing explicit authorization,
     and read the lockfile diff before accepting it.
   - `lint`: a hook failed. Hooks named after a recipe (`fmt-check`, `toml-check`,
     `deps-unused`, `py-lint`, `py-typecheck`, `check-undecided`) go to that recipe's
     line below; `validate-docs` goes to `check-docs`, `validate-agents` to
     `check-agents`. For the rest (Markdown, typos, links, shell, workflows, secrets,
     whitespace), run `just fix`, then repair the remainder by hand. Remove a secret
     ripsecrets found; never allowlist it.
   - `fmt-check` or `toml-check`: run `just fix`; never hand-format to match.
   - `clippy`: fix the code. A lint wrong for one item gets
     `#[expect(lint, reason = "...")]` there; never `allow`, never an inner `#![allow`.
     A panic path is fixed by returning an error (decision 0001), not by suppressing.
   - `fuzz-build`: the fuzz target no longer builds; on Apple silicon, check Rosetta.
   - `metrics`: lower the complexity, cohesion or coupling rustqual reports; never raise
     a threshold in `rustqual.toml`. A version mismatch means `just install-tools`, a
     network recipe needing explicit authorization, has not run here.
   - `features`: fix the `cfg` for the failing combination; keep the whole powerset.
   - `test-doc`: fix the example or the item it documents; doc examples are tests.
   - `coverage` below the floor: add the missing test; never lower `coverage_floor`.
     Remove unreachable defensive code instead of inventing an input to cover it.
   - `doc`: fix a missing doc comment or broken intra-doc link; warnings are errors.
   - `deny` or `deps-unused`: fix the licence, ban, source or unused dependency. A new
     dependency needs its decision-0005 note.
   - `py-lint`: `just fix` runs ruff's fixers. A rule wrong for one line gets
     `# noqa: RULE` with a reason. Preserve the fixture's positive control.
   - `py-typecheck`: fix the type; never loosen `strict`, never `# type: ignore` without
     a code and a reason. Preserve the positive control.
   - `py-test`: fix the binding or the test; `just py-test` rebuilds the extension.
   - `py-stubtest`: the stub and module disagree: change whichever is wrong.
   - `wheel-smoke` or `wheel-smoke-floor`: the wheel must be one `cp311-abi3` file and
     install offline; a missing floor interpreter means `just install-tools`.
   - `version-check`: two copies of the one version disagree; the message names both.
   - `check-docs`: frontmatter must equal the manifest entry, list order included.
   - `check-undecided`: a marker and the register disagree; change both together, and
     only as part of a recorded decision.
   - `check-agents`: inventory, required guidance and exact bridge content.
   - `snapshots-check`: if the change is intended, run `just snapshots-accept` and
     explain every resulting diff.
3. Never disable a gate to make a run green. A suppression is a last resort: one rule,
   one line, with a stated reason.
4. A recipe that changes the worktree is defective; repair the recipe.
5. Run the narrow recipe, then `just check` to confirm nothing else moved.
