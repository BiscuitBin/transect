# Copyright 2026 Steven Cutting
"""One version everywhere it is written."""

import json
import os
import subprocess
import sys
import tomllib
from pathlib import Path

WHEEL_MANIFEST = "crates/transectpy/pyproject.toml"
VENV = "target/wheel-smoke/venv"
# Run with -I in the venv wheel-smoke built, so nothing in the worktree shadows
# the installed package: the module's own version, then the wheel's metadata.
INSTALLED = (
    "import importlib.metadata, transectpy;"
    " print(transectpy.__version__); print(importlib.metadata.version('transectpy'))"
)


def member_versions(root: Path) -> dict[str, str]:
    """Each workspace member's version as cargo resolves it.

    Cargo, not a glob over crates/, decides membership. RUSTUP_AUTO_INSTALL=0
    makes an override naming an uninstalled toolchain fail instead of download.
    """
    metadata = subprocess.run(
        [  # noqa: S607 - check-toolchain proves PATH's cargo is rustup's proxy.
            "cargo",
            "metadata",
            "--no-deps",
            "--format-version=1",
            "--locked",
            "--offline",
            "--manifest-path",
            str(root / "Cargo.toml"),
        ],
        capture_output=True,
        text=True,
        check=True,
        env={**os.environ, "RUSTUP_AUTO_INSTALL": "0"},
    )
    packages = json.loads(metadata.stdout)["packages"]
    return {package["name"]: package["version"] for package in packages}


def installed_versions(root: Path) -> tuple[str, str] | None:
    """The installed wheel's module and metadata versions, or None with no venv."""
    python = root / VENV / "bin" / "python"
    if not python.is_file():
        return None
    result = subprocess.run(
        [str(python), "-I", "-c", INSTALLED], capture_output=True, text=True, check=True
    )
    module, metadata = result.stdout.split()
    return module, metadata


def check(root: Path) -> list[str]:
    """Every disagreement between the places the version is written."""
    workspace = tomllib.loads((root / "Cargo.toml").read_text())["workspace"]["package"]["version"]
    wheel = tomllib.loads((root / WHEEL_MANIFEST).read_text())["project"]["version"]
    problems = [
        f"crate {name} says {version}, the workspace version is {workspace}"
        for name, version in sorted(member_versions(root).items())
        if version != workspace
    ]
    if wheel != workspace:
        problems.append(
            f"wheel manifest {WHEEL_MANIFEST} says {wheel}, the workspace version is {workspace}"
        )
    installed = installed_versions(root)
    if installed is None:
        problems.append(f"no installed wheel at {VENV}; run just wheel-smoke first")
        return problems
    module, metadata = installed
    for label, version in (
        ("installed transectpy.__version__", module),
        ("installed wheel metadata", metadata),
    ):
        if version != workspace:
            problems.append(f"{label} says {version}, the workspace version is {workspace}")
    return problems


def main() -> int:
    """Print every disagreement, or the one version, and exit accordingly."""
    root = Path(__file__).resolve().parents[1]
    problems = check(root)
    for problem in problems:
        print(f"version-check: {problem}", file=sys.stderr)
    if problems:
        return 1
    print("version-check: one version everywhere")
    return 0


if __name__ == "__main__":
    sys.exit(main())
