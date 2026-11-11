# Copyright 2026 Steven Cutting
"""The version-drift check, run against a miniature repository."""

import importlib.util
import subprocess
from collections.abc import Callable
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


Repository = Callable[..., Path]


@pytest.fixture
def repository(tmp_path: Path) -> Repository:
    """Build a repository whose versions can each be set apart."""

    def build(
        workspace: str = "1.2.3",
        member: str | None = None,
        wheel: str = "1.2.3",
        installed: tuple[str, str] | None = ("1.2.3", "1.2.3"),
    ) -> Path:
        # The repository's own toolchain pin, so cargo is the pinned one here too.
        (tmp_path / "rust-toolchain.toml").write_text((ROOT / "rust-toolchain.toml").read_text())
        (tmp_path / "Cargo.toml").write_text(
            '[workspace]\nresolver = "3"\nmembers = ["crates/*"]\n\n'
            f'[workspace.package]\nversion = "{workspace}"\nedition = "2024"\n'
        )
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
    problems = load().check(repository(wheel="1.2.2"))
    assert problems == [
        (
            "wheel manifest crates/transectpy/pyproject.toml says 1.2.2,"
            " the workspace version is 1.2.3"
        )
    ]


def test_a_member_crate_with_its_own_version_is_named(repository: Repository) -> None:
    """A member that writes its own version instead of inheriting the workspace's."""
    problems = load().check(repository(member="2.0.0"))
    assert problems == ["crate core says 2.0.0, the workspace version is 1.2.3"]


def test_a_missing_wheel_smoke_venv_is_a_problem(repository: Repository) -> None:
    """Without the venv wheel-smoke leaves, the installed version cannot be read."""
    problems = load().check(repository(installed=None))
    assert problems == ["no installed wheel at target/wheel-smoke/venv; run just wheel-smoke first"]


def test_an_installed_wheel_reporting_another_version_is_named(repository: Repository) -> None:
    """The built module and the wheel's metadata each report their version."""
    problems = load().check(repository(installed=("1.2.4", "1.2.5")))
    assert problems == [
        "installed transectpy.__version__ says 1.2.4, the workspace version is 1.2.3",
        "installed wheel metadata says 1.2.5, the workspace version is 1.2.3",
    ]
