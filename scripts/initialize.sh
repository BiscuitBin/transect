#!/bin/sh
set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$project_root"

git rev-parse --is-inside-work-tree >/dev/null

# The environment first: install-tools needs its cargo-binstall and the
# `bg-*` scripts; the toolchain lines need only rustup. `--locked` refuses a
# lockfile that disagrees with `pyproject.toml`, so a stale lock is fixed by
# `just lock` and committed, never rewritten silently by a first run.
pixi install --locked

# The toolchain rust-toolchain.toml pins, with the components the file names.
just install-toolchain

# The pin in `rust-toolchain.toml` is honoured only by rustup's cargo proxy, so
# this refuses any other cargo, the pixi environment holding none, before
# anything is built with it.
just check-toolchain

# What conda-forge lacks, from `tools.txt` and `tools-source.txt` into
# `.tools/bin` through the environment's cargo-binstall: the one network
# download in the first-run path that no lockfile accounts for.
just install-tools

# `Cargo.lock` is committed and every gate passes `--locked`; this line exists
# for a clone whose lockfile was deleted by hand.
test -f Cargo.lock || cargo generate-lockfile
just sync

printf '\n%s\n' 'Ready. Next: just check.'
printf '%s\n' 'Nothing has been formatted, staged, committed, tagged, or pushed.'
