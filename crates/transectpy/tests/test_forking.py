# Copyright 2026 Steven Cutting
"""The fork harness: a callable runs in an explicitly forked child."""

import os
import secrets
import signal
import threading
import time
import warnings

import pytest
from forking import ForkFailedError, ForkTimeoutError, run_in_fork, run_in_fork_pool

# A failure must surface well within this, however slow the runner.
BOUND_SECONDS = 10


def test_the_callable_runs_in_a_child_and_returns_its_result() -> None:
    """A nonce made in the parent comes back, from a process that is not the parent."""
    nonce = secrets.token_hex(8)
    parent = os.getpid()

    def child() -> tuple[str, int]:
        return nonce, os.getpid()

    returned, pid = run_in_fork(child, timeout=10)
    assert returned == nonce
    assert pid != parent


def test_a_hanging_child_fails_within_the_bound_and_is_reaped() -> None:
    """A child that never returns is killed at the timeout, not waited on forever."""

    def hang() -> None:
        time.sleep(3600)

    started = time.monotonic()
    with pytest.raises(ForkTimeoutError) as failure:
        run_in_fork(hang, timeout=1)
    assert time.monotonic() - started < BOUND_SECONDS
    pid = failure.value.pid
    assert pid is not None
    # Reaped: the parent has no such child left to wait for.
    with pytest.raises(ChildProcessError):
        os.waitpid(pid, os.WNOHANG)


def test_a_child_killed_by_a_signal_fails() -> None:
    """A crash is reported with the signal, not mistaken for a result."""

    def crash() -> None:
        os.kill(os.getpid(), signal.SIGSEGV)

    with pytest.raises(ForkFailedError, match="signal 11"):
        run_in_fork(crash, timeout=10)


def test_a_child_exiting_non_zero_fails() -> None:
    """An exit status other than zero is reported with the status."""

    def leave() -> None:
        os._exit(3)

    with pytest.raises(ForkFailedError, match="exit status 3"):
        run_in_fork(leave, timeout=10)


def test_an_exception_in_the_child_fails_with_its_message() -> None:
    """The callable's exception is reported in the parent."""

    def explode() -> None:
        message = "boom in the child"
        raise RuntimeError(message)

    with pytest.raises(ForkFailedError, match="boom in the child"):
        run_in_fork(explode, timeout=10)


def worker_pid() -> int:
    """A pool task; module level, because a pool pickles the callable by name."""
    return os.getpid()


def worker_hangs() -> None:
    """A pool task that never returns."""
    time.sleep(3600)


def worker_crashes() -> None:
    """A pool task whose worker dies."""
    os.kill(os.getpid(), signal.SIGKILL)


def test_a_forked_pool_worker_runs_the_callable() -> None:
    """The task runs in a worker process forked from this one."""
    assert run_in_fork_pool(worker_pid, timeout=10) != os.getpid()


def test_a_hanging_pool_worker_fails_within_the_bound() -> None:
    """A pool task that never returns fails at the timeout."""
    started = time.monotonic()
    with pytest.raises(ForkTimeoutError):
        run_in_fork_pool(worker_hangs, timeout=1)
    assert time.monotonic() - started < BOUND_SECONDS


def test_a_crashed_pool_worker_fails_within_the_bound() -> None:
    """A pool replaces a dead worker and loses its task; the timeout catches it."""
    started = time.monotonic()
    with pytest.raises(ForkTimeoutError):
        run_in_fork_pool(worker_crashes, timeout=2)
    assert time.monotonic() - started < BOUND_SECONDS


def test_the_harness_survives_a_background_thread_in_the_parent() -> None:
    """A host with a thread running forks anyway; the harness must still work.

    Python 3.12 and later warn when forking a multi-threaded process. The warning
    cannot be made an error (CPython reports it as unraisable), so it is recorded:
    the helpers silence exactly that warning around their own forks.
    """
    running, stop = threading.Event(), threading.Event()

    def background() -> None:
        running.set()
        stop.wait()

    thread = threading.Thread(target=background, daemon=True)
    thread.start()
    assert running.wait(10)
    try:
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            assert run_in_fork(worker_pid, timeout=10) != os.getpid()
            assert run_in_fork_pool(worker_pid, timeout=10) != os.getpid()
    finally:
        stop.set()
        thread.join()
    assert [str(w.message) for w in caught if "fork()" in str(w.message)] == []
