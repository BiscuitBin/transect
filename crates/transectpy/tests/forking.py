# Copyright 2026 Steven Cutting
"""Run a callable in an explicitly forked child and bring its result back."""

import multiprocessing
import multiprocessing.pool
import os
import pickle
import select
import signal
import time
import traceback
import warnings
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from typing import TypeVar

T = TypeVar("T")


class ForkTimeoutError(Exception):
    """The child did not finish within the timeout; it was killed and reaped."""

    def __init__(self, timeout: float, pid: int | None = None) -> None:
        """Record which child was killed (None for a pool worker), and after how long."""
        what = "forked pool worker" if pid is None else f"forked child {pid}"
        super().__init__(f"{what} did not finish within {timeout}s; killed")
        self.pid = pid


# Python 3.12+ warns on every fork of a multi-threaded process. Forking such a
# process is exactly what a host does and what these helpers exist to test, so this
# one message is silenced, and only around the helpers' own forks.
_FORK_WITH_THREADS = r"This process \(pid=\d+\) is multi-threaded, use of fork\(\) may lead"


@contextmanager
def _forking() -> Iterator[None]:
    """Silence the fork-with-threads warning, and nothing else, for one fork."""
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", message=_FORK_WITH_THREADS, category=DeprecationWarning)
        yield


class ForkFailedError(Exception):
    """The child crashed, exited non-zero, or the callable raised."""


def _child(fn: Callable[[], object], write_end: int) -> None:
    """Run `fn` and send ("ok", result) or ("error", traceback); never return."""
    status = 0
    try:
        try:
            envelope: tuple[str, object] = ("ok", fn())
        except BaseException:  # noqa: BLE001 - every failure is reported to the parent.
            envelope = ("error", traceback.format_exc())
        with os.fdopen(write_end, "wb") as stream:
            pickle.dump(envelope, stream)
    except BaseException:  # noqa: BLE001 - an unpicklable result still ends the child.
        status = 70
    finally:
        os._exit(status)


def _describe(status: int) -> str:
    """A wait status in words."""
    code = os.waitstatus_to_exitcode(status)
    return f"killed by signal {-code}" if code < 0 else f"exit status {code}"


def _read_until(read_end: int, deadline: float) -> bytes | None:
    """Everything the child writes before it closes the pipe, or None at the deadline."""
    chunks: list[bytes] = []
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return None
        ready, _, _ = select.select([read_end], [], [], remaining)
        if not ready:
            return None
        chunk = os.read(read_end, 65536)
        if not chunk:
            return b"".join(chunks)
        chunks.append(chunk)


def run_in_fork(fn: Callable[[], T], timeout: float) -> T:
    """Fork, run `fn` in the child, and return what it returned."""
    read_end, write_end = os.pipe()
    with _forking():
        pid = os.fork()
    if pid == 0:
        os.close(read_end)
        _child(fn, write_end)
    os.close(write_end)
    try:
        data = _read_until(read_end, time.monotonic() + timeout)
    finally:
        os.close(read_end)
    if data is None:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
        raise ForkTimeoutError(timeout, pid)
    _, status = os.waitpid(pid, 0)
    if status != 0:
        message = f"forked child {pid} failed: {_describe(status)}"
        raise ForkFailedError(message)
    if not data:
        message = f"forked child {pid} exited without a result"
        raise ForkFailedError(message)
    kind, value = pickle.loads(data)  # noqa: S301 - the bytes come from our own child.
    if kind != "ok":
        message = f"forked child {pid} raised:\n{value}"
        raise ForkFailedError(message)
    result: T = value
    return result


def run_in_fork_pool(fn: Callable[[], T], timeout: float) -> T:
    """Run `fn` in a one-worker pool forked from this process, as gunicorn-style servers do.

    `fn` must be importable by name (a module-level function), because the pool sends
    it to the worker pickled. The fork start method is requested explicitly: the
    default is no longer fork on either supported platform.
    """
    context = multiprocessing.get_context("fork")
    with _forking():
        return _run_in_pool(context.Pool(1), fn, timeout)


def _run_in_pool(pool: multiprocessing.pool.Pool, fn: Callable[[], T], timeout: float) -> T:
    """Run `fn` on `pool`, then terminate and join it whatever happened."""
    try:
        pending = pool.apply_async(fn)
        try:
            result: T = pending.get(timeout)
        except multiprocessing.TimeoutError:
            raise ForkTimeoutError(timeout) from None
        except Exception as error:
            message = f"forked pool worker raised: {error!r}"
            raise ForkFailedError(message) from error
        return result
    finally:
        pool.terminate()
        pool.join()
