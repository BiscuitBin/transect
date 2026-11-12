# Copyright 2026 Steven Cutting
"""The version-drift check, run against a miniature repository."""

import importlib.util
import subprocess
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "version_check.py"


def load() -> ModuleType:
    """Import scripts/version_check.py, which is a script, not a package module."""
    spec = importlib.util.spec_from_file_location("version_check", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@dataclass(frozen=True)
class Layout:
    """Where each version is written; every place says 1.2.3 unless set apart."""

    workspace: str = "1.2.3"
    member: str | None = None
    wheel: str = "1.2.3"
    installed: tuple[str, str] | None = ("1.2.3", "1.2.3")
    requirement: str | None = None
    fuzz: str | None = None
    changelog: str = "## [Unreleased]\n"


# Every place agrees; a test passes a Layout of its own to set one apart.
AGREEING = Layout()

Repository = Callable[..., Path]


@pytest.fixture
def repository(tmp_path: Path) -> Repository:
    """Build a repository whose versions can each be set apart."""

    def build(layout: Layout = AGREEING) -> Path:
        workspace, member, wheel = layout.workspace, layout.member, layout.wheel
        installed, requirement, fuzz = layout.installed, layout.requirement, layout.fuzz
        changelog = layout.changelog
        # The repository's own toolchain pin, so cargo is the pinned one here too.
        (tmp_path / "rust-toolchain.toml").write_text((ROOT / "rust-toolchain.toml").read_text())
        (tmp_path / "Cargo.toml").write_text(
            '[workspace]\nresolver = "3"\nmembers = ["crates/*"]\n\n'
            f'[workspace.package]\nversion = "{workspace}"\nedition = "2024"\n\n'
            "[workspace.dependencies]\n"
            f'core = {{ path = "crates/core", version = "{requirement or workspace}" }}\n'
        )
        (tmp_path / "fuzz").mkdir()
        (tmp_path / "fuzz" / "Cargo.toml").write_text(
            '[package]\nname = "core-fuzz"\nversion = "0.0.0"\n\n[dependencies]\n'
            f'core = {{ path = "../crates/core", version = "{fuzz or workspace}" }}\n'
        )
        (tmp_path / "CHANGELOG.md").write_text(f"# Changelog\n\n{changelog}")
        crate = tmp_path / "crates" / "core"
        (crate / "src").mkdir(parents=True)
        own = f'"{member}"' if member is not None else None
        version_line = f"version = {own}" if own else "version.workspace = true"
        (crate / "Cargo.toml").write_text(
            f'[package]\nname = "core"\n{version_line}\nedition.workspace = true\n'
        )
        (crate / "src" / "lib.rs").write_text("")
        binding = tmp_path / "crates" / "transectpy"
        (binding / "src").mkdir(parents=True)
        (binding / "src" / "lib.rs").write_text("")
        (binding / "Cargo.toml").write_text(
            '[package]\nname = "transectpy"\nversion.workspace = true\nedition.workspace = true\n'
        )
        (binding / "pyproject.toml").write_text(
            f'[project]\nname = "transectpy"\nversion = "{wheel}"\n'
        )
        subprocess.run(
            ["cargo", "generate-lockfile", "--offline"],
            cwd=tmp_path,
            check=True,
            capture_output=True,
        )
        if installed is not None:
            python = tmp_path / "target" / "wheel-smoke" / "venv" / "bin" / "python"
            python.parent.mkdir(parents=True)
            python.write_text(f"#!/bin/sh\nprintf '%s\\n' '{installed[0]}' '{installed[1]}'\n")
            python.chmod(0o755)
        return tmp_path

    return build


def test_one_version_everywhere_is_no_problem(repository: Repository) -> None:
    """Workspace, member, wheel manifest and installed wheel all say 1.2.3."""
    assert load().check(repository()) == []


def test_a_wheel_manifest_behind_the_workspace_is_named(repository: Repository) -> None:
    """The wheel manifest still says 1.2.2 after the workspace moved to 1.2.3."""
    problems = load().check(repository(Layout(wheel="1.2.2")))
    assert problems == [
        (
            "wheel manifest crates/transectpy/pyproject.toml says 1.2.2,"
            " the workspace version is 1.2.3"
        )
    ]


def test_a_member_crate_with_its_own_version_is_named(repository: Repository) -> None:
    """A member that writes its own version instead of inheriting the workspace's."""
    problems = load().check(repository(Layout(member="2.0.0")))
    assert problems == ["crate core says 2.0.0, the workspace version is 1.2.3"]


def test_a_missing_wheel_smoke_venv_is_a_problem(repository: Repository) -> None:
    """Without the venv wheel-smoke leaves, the installed version cannot be read."""
    problems = load().check(repository(Layout(installed=None)))
    assert problems == ["no installed wheel at target/wheel-smoke/venv; run just wheel-smoke first"]


def test_an_installed_wheel_reporting_another_version_is_named(repository: Repository) -> None:
    """The built module and the wheel's metadata each report their version."""
    problems = load().check(repository(Layout(installed=("1.2.4", "1.2.5"))))
    assert problems == [
        "installed transectpy.__version__ says 1.2.4, the workspace version is 1.2.3",
        "installed wheel metadata says 1.2.5, the workspace version is 1.2.3",
    ]


def test_a_path_requirement_behind_the_workspace_is_named(repository: Repository) -> None:
    """[workspace.dependencies] still requires 1.2.2 of a member now at 1.2.3."""
    problems = load().check(repository(Layout(requirement="1.2.2")))
    assert problems == [
        "Cargo.toml [workspace.dependencies] requires core 1.2.2, the workspace version is 1.2.3"
    ]


def test_a_fuzz_requirement_behind_the_workspace_is_named(repository: Repository) -> None:
    """The excluded fuzz crate, which cargo-release cannot reach, still requires 1.2.2."""
    problems = load().check(repository(Layout(fuzz="1.2.2")))
    assert problems == ["fuzz/Cargo.toml requires core 1.2.2, the workspace version is 1.2.3"]


def test_the_newest_dated_changelog_heading_must_be_the_version(repository: Repository) -> None:
    """A release section for 1.2.4 above 1.2.3's means the bump did not happen."""
    changelog = "## [Unreleased]\n\n## [1.2.4] - 2026-11-12\n\n## [1.2.3] - 2026-11-11\n"
    problems = load().check(repository(Layout(changelog=changelog)))
    assert problems == [
        "CHANGELOG.md's newest release heading is 1.2.4, the workspace version is 1.2.3"
    ]


def test_a_changelog_whose_newest_heading_is_the_version_is_no_problem(
    repository: Repository,
) -> None:
    """After a release, the bump and its dated heading agree."""
    changelog = (
        "## [Unreleased]\n\n## [1.2.3] - 2026-11-11\n\n- Added.\n\n## [1.2.2] - 2026-10-01\n"
    )
    assert load().check(repository(Layout(changelog=changelog))) == []
