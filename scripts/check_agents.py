# Copyright 2026 Steven Cutting
"""The agent contract, over the skills this repository authors.

`skills-lock.json` names the skills vendored from upstream. They are a
dependency: upstream's text, shipped with reference material beside each
`SKILL.md` and with links where the contract expects bridges, and not this
repository's to hold to its own contract (decision 0011). The shared validator
has no way to leave a skill out, so this narrows the two things it reads, the
skill names and the managed files, and then runs it unchanged.
"""

import json
import sys
from pathlib import Path

from biscuit_games_tooling import _project, validate_agents

LOCK = "skills-lock.json"
# Where a skill, or a provider's bridge to it, can live.
SKILL_ROOTS = (Path(".agents/skills"), Path(".claude/skills"), Path(".codex/skills"))


def vendored_skills(root: Path) -> frozenset[str]:
    """The skills the lock names; none when the repository has no lock."""
    lock = root / LOCK
    if not lock.is_file():
        return frozenset()
    skills: dict[str, object] = json.loads(lock.read_text(encoding="utf-8"))["skills"]
    return frozenset(skills)


def is_vendored(relative: Path, vendored: frozenset[str]) -> bool:
    """Whether a path is a vendored skill's directory, its link, or anything inside either."""
    return any(
        skill_root / name in (relative, *relative.parents)
        for skill_root in SKILL_ROOTS
        for name in vendored
    )


def main() -> int:
    """Run the shared validator with the vendored skills out of its inventory."""
    vendored = vendored_skills(_project.root())
    # The validator's own two readers, kept so the narrowed ones can call them.
    skill_names = validate_agents._skill_names  # noqa: SLF001 - the validator has no ignore list.
    managed_files = validate_agents._managed_files  # noqa: SLF001 - as above.

    def authored_names(root: Path) -> tuple[str, ...]:
        return tuple(name for name in skill_names(root) if name not in vendored)

    def authored_files(root: Path) -> set[Path]:
        return {path for path in managed_files(root) if not is_vendored(path, vendored)}

    validate_agents._skill_names = authored_names  # noqa: SLF001 - as above.
    validate_agents._managed_files = authored_files  # noqa: SLF001 - as above.
    return validate_agents.main()


if __name__ == "__main__":
    sys.exit(main())
