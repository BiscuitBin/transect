# Copyright 2026 Steven Cutting
"""The agent contract's wrapper, run against a miniature repository."""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path
from types import ModuleType

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "check_agents.py"
# One skill this repository authors, copied with both of its bridges.
AUTHORED = "fix-quality"
# A skill in the shape upstream ships: frontmatter the contract refuses, no
# mention of this repository, reference material beside it and a link for a
# bridge.
VENDORED = "allium"

Repository = Callable[..., Path]


def load() -> ModuleType:
    """Import scripts/check_agents.py, which is a script, not a package module."""
    spec = importlib.util.spec_from_file_location("check_agents", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def repository(tmp_path: Path) -> Repository:
    """Build a repository with one authored skill and one vendored skill."""

    def build(locked: tuple[str, ...] | None = (VENDORED,)) -> Path:
        subprocess.run(["git", "init", "--quiet"], cwd=tmp_path, check=True)
        for relative in (
            ".gitignore",
            "AGENTS.md",
            "CLAUDE.md",
            ".github/copilot-instructions.md",
            f".agents/skills/{AUTHORED}/SKILL.md",
            f".claude/skills/{AUTHORED}/SKILL.md",
            f".codex/skills/{AUTHORED}/SKILL.md",
        ):
            target = tmp_path / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
        skill = tmp_path / ".agents" / "skills" / VENDORED
        (skill / "references").mkdir(parents=True)
        (skill / "SKILL.md").write_text(
            f"---\nname: {VENDORED}\ndescription: Short.\nversion: 3\n---\n\nUpstream's text.\n"
        )
        (skill / "references" / "guide.md").write_text("# Guide\n")
        (tmp_path / ".claude" / "skills" / VENDORED).symlink_to(
            Path("..") / ".." / ".agents" / "skills" / VENDORED
        )
        if locked is not None:
            lock = {"version": 2, "skills": {name: {"source": "juxt/allium"} for name in locked}}
            (tmp_path / "skills-lock.json").write_text(json.dumps(lock))
        return tmp_path

    return build


def run(root: Path) -> subprocess.CompletedProcess[str]:
    """Run the script inside a repository, as the recipe does.

    Git's own variables are dropped: inside a commit hook they name the real
    repository, and the validator asks Git where it is.
    """
    environment = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT)],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )


def test_a_locked_skill_is_left_out_of_the_contract(repository: Repository) -> None:
    """The vendored skill breaks every rule, and the authored one is all that is counted."""
    result = run(repository())
    assert result.stderr == ""
    assert result.stdout == "Validated AGENTS.md, 2 adapters, and 1 skills.\n"
    assert result.returncode == 0


def test_a_skill_the_lock_does_not_name_is_held_to_the_contract(repository: Repository) -> None:
    """Only the lock takes a skill out: the same files without an entry fail."""
    result = run(repository(locked=()))
    assert result.returncode == 1
    assert (
        f"agent validation: unexpected managed file: .agents/skills/{VENDORED}/references/guide.md"
        in result.stderr.splitlines()
    )
    assert (
        f"agent validation: missing managed file: .codex/skills/{VENDORED}/SKILL.md"
        in result.stderr.splitlines()
    )


def test_no_lock_means_no_vendored_skill(repository: Repository) -> None:
    """A repository without skills-lock.json has every skill in the contract."""
    result = run(repository(locked=None))
    assert result.returncode == 1
    assert f".agents/skills/{VENDORED}/SKILL.md" in result.stderr


def test_a_lock_whose_skills_are_not_an_object_fails(repository: Repository) -> None:
    """A list of names is not a lock: the script stops rather than guess what to leave out."""
    root = repository()
    (root / "skills-lock.json").write_text(json.dumps({"version": 2, "skills": [VENDORED]}))
    result = run(root)
    assert result.returncode == 1
    assert result.stderr.splitlines() == [
        'skills-lock.json: "skills" must be an object keyed by skill name'
    ]


def test_an_authored_skill_is_still_checked(repository: Repository) -> None:
    """Leaving the vendored skill out does not loosen the contract for the rest."""
    root = repository()
    bridge = root / ".codex" / "skills" / AUTHORED / "SKILL.md"
    bridge.write_text(bridge.read_text() + "\nAnd one instruction of its own.\n")
    result = run(root)
    assert result.returncode == 1
    problem = (
        f"agent validation: .codex/skills/{AUTHORED}/SKILL.md:"
        " must stay a thin pointer to the canonical skill"
    )
    assert result.stderr.splitlines() == [problem]


@pytest.mark.parametrize(
    "relative",
    [
        ".agents/skills/allium",
        ".agents/skills/allium/SKILL.md",
        ".agents/skills/allium/references/schemas/ledger.schema.json",
        ".claude/skills/allium",
        ".codex/skills/allium/SKILL.md",
    ],
)
def test_a_path_at_or_under_a_vendored_skill_is_vendored(relative: str) -> None:
    """The directory, the link that stands in for a bridge, and everything inside."""
    assert load().is_vendored(Path(relative), frozenset({"allium"}))


@pytest.mark.parametrize(
    "relative",
    [
        ".agents/skills/allium-extra/SKILL.md",
        ".agents/skills/fix-quality/SKILL.md",
        ".claude/settings.json",
        "docs/allium/SKILL.md",
        "AGENTS.md",
    ],
)
def test_any_other_path_is_not_vendored(relative: str) -> None:
    """A name is matched whole, and only under the three skill directories."""
    assert not load().is_vendored(Path(relative), frozenset({"allium"}))
