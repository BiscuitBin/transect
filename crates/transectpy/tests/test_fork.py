# Copyright 2026 Steven Cutting
"""transectpy under fork: imported in the parent, used in an explicitly forked child.

Decision 0002 makes correct behaviour under fork a requirement. The client has no
behaviour yet, so the child can only check the import and the version; the
placeholder below is where real fork-safety assertions go.
"""

import os

import transectpy
from forking import run_in_fork, run_in_fork_pool

# Set after the import, in the parent only. A child started fresh (spawn or
# forkserver) would re-import this module and see the initial value; a forked child
# inherits the parent's memory and sees the updated one.
SENTINEL = {"value": "initial"}


def sentinel_and_version() -> tuple[str, str, int]:
    """What a child sees: the sentinel, the package's version, and its own pid."""
    return SENTINEL["value"], transectpy.__version__, os.getpid()


def test_the_child_is_forked_not_started_fresh() -> None:
    """The child sees state the parent set after importing transectpy."""
    SENTINEL["value"] = f"set by {os.getpid()} after import"
    try:
        for seen, _, pid in (
            run_in_fork(sentinel_and_version, timeout=10),
            run_in_fork_pool(sentinel_and_version, timeout=10),
        ):
            assert seen == SENTINEL["value"]
            assert pid != os.getpid()
    finally:
        SENTINEL["value"] = "initial"


def test_the_package_imported_before_the_fork_works_in_the_child() -> None:
    """The child uses the parent's import and reports the parent's version."""
    for _, version, _ in (
        run_in_fork(sentinel_and_version, timeout=10),
        run_in_fork_pool(sentinel_and_version, timeout=10),
    ):
        assert version == transectpy.__version__


# FORK-SAFETY PLACEHOLDER: when the client gains behaviour, the assertions that it
# obeys decision 0001 in a forked child (records without raising or blocking, and its
# data writer runs) go here, through run_in_fork and run_in_fork_pool. Today the
# client has only its version, which the tests above already cover. Referenced from
# docs/project/open-decisions.md.
def test_fork_safety_placeholder() -> None:
    """Holds the place of the client's fork-safety assertions; the version for now."""
    assert run_in_fork(lambda: transectpy.__version__, timeout=10) == transectpy.__version__
