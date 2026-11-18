# 09: Retire the agent-contract wrapper

**What to build:** The agent-contract gate runs the shared validator directly again, and the vendored Allium skills are still left out of the contract. Today the repository carries its own wrapper script for that gate. The wrapper reads the skills lockfile, removes the vendored skills from what the shared validator checks, and reaches two private functions of the tooling package to do it. Once the shared validator can leave skills out itself, the wrapper and its tests are removed and decision 0011 says so.

Why the wrapper exists: the shared validator in biscuit-games-tooling v0.3.0 has no ignore list. Decision 0011 keeps the vendored skills byte for byte as upstream ships them and leaves them out of the gates, and the wrapper is how the agent contract does that. Reaching into private functions is the cost: a tooling release may rename them without notice.

This is a local note. The change the precondition needs is in another repository, and nothing has been filed there.

**External precondition:** A released version of biscuit-games-tooling whose agent validator has an ignore list, or another supported way to leave named skills out. Asking for it, by filing an issue or opening a pull request in that repository, leaves this worktree and needs the maintainer's explicit authorisation.

**Blocked by:** None in this set.

**Status:** waiting on the maintainer

- [ ] The tooling package is at a version whose agent validator can leave named skills out, with its pinned tag and the lock changed together through an authorised network recipe
- [ ] `just check-agents` and the matching hook call the shared validator directly, configured to leave out the skills the skills lockfile names
- [ ] The wrapper script and its tests are removed, and nothing in the repository reaches a private function of the tooling package
- [ ] The vendored skills are still excluded from the contract and are unchanged, byte for byte
- [ ] A positive control shows the gate still bites: a skill this repository authors that breaks the contract fails `just check-agents`, and the change is reverted
- [ ] Decision 0011 is updated to say how the agent contract leaves the vendored skills out, and every handbook page and agent instruction that names the wrapper is updated in the same change
- [ ] `just check-agents` and `just check-docs` pass, and `just check` ends with `All checks passed and the worktree is unchanged.`
- [ ] Nothing is filed, pushed or published outside the worktree without explicit authorisation for that action
