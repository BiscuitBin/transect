# Copyright 2026 Steven Cutting
"""The package imports and reports the workspace version, and nothing else."""

import importlib.metadata
import tomllib
from pathlib import Path

import transectpy
import transectpy._transectpy as native

ROOT = Path(__file__).resolve().parents[3]


def workspace_version() -> str:
    """The version Cargo.toml declares once for every crate."""
    manifest = tomllib.loads((ROOT / "Cargo.toml").read_text(encoding="utf-8"))
    version: str = manifest["workspace"]["package"]["version"]
    return version


def test_the_package_reports_the_workspace_version() -> None:
    """`transectpy.__version__` is the workspace version, read independently."""
    assert transectpy.__version__ == workspace_version()


def test_the_version_comes_from_the_native_module() -> None:
    """The package re-exports the Rust client's version, not a Python literal."""
    assert transectpy.__version__ is native.__version__


def test_the_distribution_metadata_agrees() -> None:
    """The installed distribution's metadata says the same version."""
    assert importlib.metadata.version("transectpy") == workspace_version()


def test_nothing_but_the_version_is_public() -> None:
    """No table, column or write API has leaked into either module."""
    assert transectpy.__all__ == ["__version__"]
    assert [name for name in dir(transectpy) if not name.startswith("_")] == []
    assert [name for name in dir(native) if not name.startswith("_")] == []
