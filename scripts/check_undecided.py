# Copyright 2026 Steven Cutting
"""The UNDECIDED markers in the code and the open-decisions register agree."""

import re
import sys
from pathlib import Path

REGISTER = "docs/project/open-decisions.md"
MARKER = "//! UNDECIDED:"


def marked(root: Path) -> set[str]:
    """Every Rust file under crates/ whose first line is the UNDECIDED marker."""
    found: set[str] = set()
    for path in (root / "crates").rglob("*.rs"):
        lines = path.read_text(encoding="utf-8").splitlines()
        if lines and lines[0].startswith(MARKER):
            found.add(path.relative_to(root).as_posix())
    return found


def registered(root: Path) -> list[str]:
    """Every crates/ path named in the register's 'Undecided areas' section, in order."""
    text = (root / REGISTER).read_text(encoding="utf-8")
    section = re.search(r"^## Undecided areas$(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
    body = section.group(1) if section else ""
    return re.findall(r"`(crates/[^`]+\.rs)`", body)


def check(root: Path) -> list[str]:
    """Every file marked but not registered, or registered but not marked."""
    code, listed = marked(root), registered(root)
    register = set(listed)
    return (
        [
            f"{path} is marked UNDECIDED but not listed under 'Undecided areas' in {REGISTER}"
            for path in sorted(code - register)
        ]
        + [
            f"{REGISTER} lists {path} under 'Undecided areas' but its first line is not the"
            " UNDECIDED marker"
            for path in sorted(register - code)
        ]
        + [
            f"{REGISTER} lists {path} under 'Undecided areas' more than once"
            for path in sorted(path for path in register if listed.count(path) > 1)
        ]
    )


def main() -> int:
    """Print every disagreement, or the agreed count, and exit accordingly."""
    root = Path(__file__).resolve().parents[1]
    problems = check(root)
    for problem in problems:
        print(f"check-undecided: {problem}", file=sys.stderr)
    if problems:
        return 1
    print(f"check-undecided: {len(marked(root))} UNDECIDED markers match the register")
    return 0


if __name__ == "__main__":
    sys.exit(main())
