# Copyright 2026 Steven Cutting
"""The UNDECIDED markers and the open-decisions register name the same files."""

import importlib.util
from collections.abc import Callable
from pathlib import Path
from types import ModuleType

import pytest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "check_undecided.py"
REGISTER = "docs/project/open-decisions.md"


def load() -> ModuleType:
    """Import scripts/check_undecided.py, which is a script, not a package module."""
    spec = importlib.util.spec_from_file_location("check_undecided", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


Repository = Callable[..., Path]


@pytest.fixture
def repository(tmp_path: Path) -> Repository:
    """Build a repository with the given marked modules and register entries."""

    def build(
        marked: tuple[str, ...] = (),
        unmarked: tuple[str, ...] = (),
        undecided: tuple[str, ...] = (),
        open_points: tuple[str, ...] = (),
    ) -> Path:
        for relative in marked:
            path = tmp_path / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("//! UNDECIDED: an area.\n//!\n//! Responsibility only.\n")
        for relative in unmarked:
            path = tmp_path / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("//! NOT YET IMPLEMENTED: something.\n")
        entries = "".join(f"### Area\n\n- **Placeholder:** `{p}`\n\n" for p in undecided)
        points = "".join(f"- **Point.** See `{p}`.\n" for p in open_points)
        register = tmp_path / REGISTER
        register.parent.mkdir(parents=True)
        register.write_text(
            f"# Open decisions\n\n## Undecided areas\n\n{entries}## Open points\n\n{points}"
        )
        return tmp_path

    return build


def test_a_marker_with_its_entry_is_no_problem(repository: Repository) -> None:
    """One marked module, named once in the undecided section."""
    queue = "crates/core/src/queue.rs"
    assert load().check(repository(marked=(queue,), undecided=(queue,))) == []


def test_a_marker_without_an_entry_is_named(repository: Repository) -> None:
    """A module marked UNDECIDED that the register does not list."""
    problems = load().check(repository(marked=("crates/core/src/queue.rs",)))
    assert problems == [
        (
            "crates/core/src/queue.rs is marked UNDECIDED but not listed under"
            " 'Undecided areas' in docs/project/open-decisions.md"
        )
    ]


def test_an_entry_without_a_marker_is_named(repository: Repository) -> None:
    """A registered area whose module has lost its marker, or never existed."""
    problems = load().check(
        repository(
            unmarked=("crates/core/src/queue.rs",),
            undecided=("crates/core/src/queue.rs", "crates/core/src/gone.rs"),
        )
    )
    assert problems == [
        (
            "docs/project/open-decisions.md lists crates/core/src/gone.rs under"
            " 'Undecided areas' but its first line is not the UNDECIDED marker"
        ),
        (
            "docs/project/open-decisions.md lists crates/core/src/queue.rs under"
            " 'Undecided areas' but its first line is not the UNDECIDED marker"
        ),
    ]


def test_a_path_under_open_points_does_not_count(repository: Repository) -> None:
    """Only the 'Undecided areas' section pairs with markers."""
    queue = "crates/core/src/queue.rs"
    problems = load().check(repository(marked=(queue,), open_points=(queue,)))
    assert problems == [
        f"{queue} is marked UNDECIDED but not listed under 'Undecided areas' in {REGISTER}"
    ]


def test_an_entry_listed_twice_is_named(repository: Repository) -> None:
    """Two entries for one marked module would let them disagree."""
    queue = "crates/core/src/queue.rs"
    problems = load().check(repository(marked=(queue,), undecided=(queue, queue)))
    assert problems == [f"{REGISTER} lists {queue} under 'Undecided areas' more than once"]
