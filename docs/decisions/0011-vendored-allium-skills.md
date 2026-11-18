---
title: "Decision 0011: The vendored Allium skills stand outside the gates"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_vendored_skills"]
requires: []
---

# Decision 0011: The vendored Allium skills stand outside the gates

## Context

Seven skills come from the GitHub repository `juxt/allium`: `allium`, `distill`,
`elicit`, `propagate`, `tend`, `weed` and `witness`. The skills CLI vendored them, and
`skills-lock.json` records each one's source. They arrive in upstream's shape: a
`SKILL.md` under `.agents/skills/<name>/`, reference material beside it for three of
them, and a symbolic link at `.claude/skills/<name>` where this repository's own skills
have a bridge file.

Three gates read those files as if this repository had written them, and failed:
markdownlint on upstream's Markdown style, ruff's format check on the Python inside
upstream's Markdown examples, and the agent contract, which expects one `SKILL.md` per
skill with a bridge for each provider and nothing else. rove and the repositories it
descends from met the same failures and answered by moving the reference material and
adapting each skill. That edits a dependency to suit its consumer's linters.

## Decision

The vendored skills are a dependency, and a dependency is not tested as this
repository's own text. They stay where the skills CLI puts them, byte for byte, and
these checks leave them out:

- markdownlint, through `ignores` in `.markdownlint-cli2.jsonc`;
- ruff, through `extend-exclude` in `ruff.toml`;
- taplo, through `exclude` in `taplo.toml`, although upstream ships no TOML today;
- every fixer `just fix` runs, through `exclude` in `.pre-commit-fix.yaml`, so that no
  repair rewrites upstream's text;
- the agent contract, through `scripts/check_agents.py`.

The shared validator, `bg-validate-agents`, has no ignore list. The script reads
`skills-lock.json`, removes the skills it names from the two things the validator
reads, the skill names and the managed files, and then runs the validator unchanged.
`just check-agents` and the `validate-agents` hook both run the script. A skill the lock
does not name is held to the whole contract, and `tests/scripts/test_check_agents.py`
proves both halves.

The other hooks in the read-only gate still read the vendored files: the builtin file
checks, EditorConfig, typos, the offline link check and the secret scan. They pass, and
the secret scan is worth having over any text that enters the repository.

## Consequences

A finding in a vendored skill is fixed upstream and arrives with the next vendoring. The
seven names are written in four configuration files as well as in the lock, because
those tools cannot read it: a skill added to or removed from the lock changes all four
in the same commit. The script reaches two private functions of the tooling package, so
moving that package's tag means re-running its tests. One of the hooks that still read
the files may fail after an upstream update; the answer then is an exclude for that
hook, not an edit to upstream's text.

## What would reopen this

The tooling package's validator gaining an ignore list of its own, which retires the
script; or the skills being supplied by the Allium plugin alone, which removes the
vendored files and every exclude with them.

## Related pages

- [Quality gates](../reference/quality-gates.md)
- [Repository map](../project/repository-map.md)
- [Decision 0009: A read-only hook gate and a separate fixer](0009-hooks.md)
