# 05: Hooks and document linting

**What to build:** A commit that breaks formatting, contains a typo, a dead local link, a malformed workflow, a shell bug or a secret is stopped at commit time and in CI, and one command repairs everything that can be repaired mechanically. This carries the models' two-file hook arrangement: a read-only gate configuration that is installed as the commit hook and may only report, and a separate mutating configuration that is never installed and runs only from the fix recipe.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which hook in the gate configuration can modify files; which hook never matches any file; what a contributor on macOS sees differently; whether the secret scan fires on a planted secret.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The gate configuration runs the models' hooks: the built-in file checks, editor-config check, Markdown lint, typo check (report only), offline link check with an online variant at a manual stage, shell lint, workflow lint, and the secret scan supplied by the shared tooling package
- [ ] Local hooks that wrap repository gates call Justfile recipes; clippy is deliberately not a hook
- [ ] Every remote hook is pinned to a full commit hash with a version comment
- [ ] The fix configuration holds every fixer and nothing in the gate configuration modifies files
- [ ] Markdown lint, typo and link-check configuration match the models, with exclusions for generated, vendored and scratch directories
- [ ] Recipes exist for: lint (all hooks, all files), fix, hook installation (primary checkout only), document checks, and the online link check
- [ ] A deliberately introduced typo, trailing whitespace and broken relative link each fail the lint recipe; the fix recipe repairs what is repairable; evidence quoted in the hand-back
- [ ] The setup action caches and prepares the hook environments
- [ ] Lint is in the ordered check list and the check command ends green
- [ ] CI has a `documents` job running lint and the document checks on Linux
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
