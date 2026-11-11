set positional-arguments := true
set shell := ["sh", "-eu", "-c"]

# pixi owns every tool binary and the Python environment (.pixi/envs/default;
# pyproject.toml is the manifest, pixi.lock the pin). Tools conda-forge lacks
# (tools.txt, and tools-source.txt for those with no release binary) live in
# .tools/bin. Every recipe sees both first; cargo finds cargo-nextest and
# friends on PATH by name. Neither directory holds a cargo, so rustup's proxy
# stays first for the compiler (check-toolchain proves it).
export PATH := justfile_directory() / ".pixi" / "envs" / "default" / "bin" + ":" + justfile_directory() / ".tools" / "bin" + ":" + env("PATH")

# Every cargo invocation compiles the bindings against pixi's Python.
export PYO3_PYTHON := justfile_directory() / ".pixi" / "envs" / "default" / "bin" / "python"

# Line-coverage floor over the pure-Rust crates' src/**. Lower the complexity, not the
# number.
coverage_floor := "90"

# The wheel's floor interpreter, the oldest Python the abi3-py311 wheel claims:
# a python-build-standalone CPython that uv installs into .tools/python, so the
# floor smoke runs locally and offline on a plain 3.11, not pixi's 3.14.
# Verified with `uv python list` on 2026-11-11.
python_floor := "3.11.18"

default:
    @just --list

alias list := default

# ------------------------------------------------------------------ setup ---

# One explicit first-run command. Never stages, commits, tags, or pushes.
initialize:
    sh scripts/initialize.sh

# The pin in rust-toolchain.toml is honoured only by rustup's cargo proxy. A
# cargo from pixi, Homebrew or a distribution ignores the file and builds with
# whatever it is, so the gate refuses it before anything else runs. The test is
# behaviour, not a path: only a rustup proxy accepts `+toolchain`, and the
# runners lay rustup out differently (Ubuntu's ~/.cargo/bin, macOS's Homebrew
# keg), so neither the path nor file identity with `rustup` would hold on both.
# Pointing CARGO_HOME elsewhere cannot make a foreign cargo pass. RUSTC outranks
# the proxy's toolchain inside cargo itself, so it is refused outright. The proxy
# still obeys RUSTUP_TOOLCHAIN or a `rustup override`, both of which outrank
# the file, so the active toolchain must then be the pinned channel, selected
# by rust-toolchain.toml itself. RUSTUP_AUTO_INSTALL=0 makes an uninstalled
# toolchain a refusal instead of a download.
check-toolchain:
    command -v rustup >/dev/null || { printf '%s\n' 'rustup is not installed; see https://rustup.rs' >&2; exit 2; }
    [ -z "${RUSTC:-}" ] || { printf '%s\n' "RUSTC is set ($RUSTC); it overrides the pinned toolchain, so unset it" >&2; exit 2; }
    pin=$(sed -n 's/^channel = "\(.*\)"$/\1/p' rust-toolchain.toml); [ -n "$pin" ] || { printf '%s\n' 'rust-toolchain.toml names no channel' >&2; exit 2; }; RUSTUP_AUTO_INSTALL=0 cargo "+$pin" --version >/dev/null 2>&1 || { printf '%s\n' "cargo resolves to $(command -v cargo), not rustup's proxy for $pin" >&2; exit 2; }
    pin=$(sed -n 's/^channel = "\(.*\)"$/\1/p' rust-toolchain.toml); [ -n "$pin" ] || { printf '%s\n' 'rust-toolchain.toml names no channel' >&2; exit 2; }; active=$(RUSTUP_AUTO_INSTALL=0 rustup show active-toolchain); case "$active" in "$pin"-*" (overridden by '"*"/rust-toolchain.toml')") printf '%s\n' "$active" ;; *) printf '%s\n' "the active toolchain is $active; it must be $pin, selected by rust-toolchain.toml" >&2; exit 2;; esac

# Installs the toolchain and components rust-toolchain.toml names.
install-toolchain:
    rustup toolchain install

# Tools conda-forge lacks into .tools/bin, and the floor interpreter into
# .tools/python (network). cargo-binstall comes from
# the pixi environment. tools.txt is binary-only: a release archive or nothing.
# tools-source.txt holds tools with no release binary, so its pass may compile,
# and cargo-binstall passes --locked through to `cargo install`. It tries a
# signed cargo-quickinstall build first; --only-signed refuses an unsigned one,
# and an upstream release asset, which nothing would sign, is refused too. That
# pass runs without a GitHub token, so no build script it compiles can read one.
# A pass whose list is empty is skipped, since cargo binstall with no crate
# fails; the guard is plain sh, so it holds for GNU and BSD alike. sed, not
# grep, strips the comments: it exits 0 on a list with no pins but still fails,
# and so fails the recipe, when the file is missing or unreadable.
install-tools:
    UV_PYTHON_INSTALL_DIR=.tools/python uv python install --no-bin {{python_floor}}
    pins=$(sed -e '/^#/d' -e '/^$/d' tools.txt); [ -z "$pins" ] || cargo binstall --root .tools --no-confirm --locked --disable-strategies compile $pins
    pins=$(sed -e '/^#/d' -e '/^$/d' tools-source.txt); [ -z "$pins" ] || env -u GITHUB_TOKEN -u GH_TOKEN cargo binstall --root .tools --no-confirm --locked --disable-strategies crate-meta-data --only-signed --no-discover-github-token $pins

# All three lockfiles, exactly as committed. Never rewrites any.
sync:
    cargo fetch --locked
    cargo fetch --locked --manifest-path fuzz/Cargo.toml
    pixi install --frozen

lock:
    cargo update --workspace
    cargo update --workspace --manifest-path fuzz/Cargo.toml
    pixi lock

# Within the manifest's constraints only; every direct pixi pin is exact, so
# this moves transitives. `pixi upgrade` rewrites the pins themselves and is
# not this recipe.
lock-upgrade:
    cargo update
    cargo update --manifest-path fuzz/Cargo.toml
    pixi update

# Offline, like every gate recipe: a cold Cargo cache fails rather than
# fetching the registry index (`just sync` fills it), and an offline solve on a
# stale lock still fails, which is the right answer. --dry-run because pixi
# would otherwise rewrite a stale lock from that restricted solve.
lock-check:
    cargo update --workspace --locked --offline
    cargo update --workspace --locked --offline --manifest-path fuzz/Cargo.toml
    pixi lock --check --offline --dry-run

# The shim, then every hook environment, so that `just check` never fetches.
# Primary checkout only: every worktree of this repository shares one
# .git/hooks directory, and `prek install` writes a shim naming an absolute
# path into whichever worktree ran it, so a hook installed from a secondary
# worktree runs that worktree's prek for commits made anywhere, and fails every
# commit once the worktree is deleted. In a secondary worktree the common
# directory and the git directory differ, which is the test git itself uses.
# lychee is `language: script` and downloads its binary at first run, not at
# prepare, so it is run once here on one Markdown file; its exit status is
# lint's business, not this recipe's. RUSTUP_AUTO_INSTALL=0 stops its
# cargo-binstall step from installing another toolchain.
install-hooks:
    git rev-parse --is-inside-work-tree >/dev/null
    [ "$(git rev-parse --git-common-dir)" = "$(git rev-parse --git-dir)" ] || { printf '%s\n' 'install-hooks: this is a secondary worktree; run it once from the primary checkout' >&2; exit 2; }
    test -x .pixi/envs/default/bin/prek || { printf '%s\n' 'the pixi environment is not installed; run just initialize first' >&2; exit 2; }
    prek install --overwrite --hook-type=pre-commit --prepare-hooks
    prek prepare-hooks --config .pre-commit-fix.yaml
    -RUSTUP_AUTO_INSTALL=0 prek run lychee --files README.md

# ---------------------------------------------------------------- develop ---

# Benchmarks, by hand: timings measure the machine and its load as much as the
# code, so never a gate and never in CI. Bench targets only: without --bench '*'
# cargo also runs every unit test in bench mode, as ignored. just clippy already
# compiles the benches, so a bench that stops building fails the gate.
bench *args:
    cargo bench --workspace --all-features --locked --bench '*' "$@"

# Fuzzing, by hand: nondeterministic, so never a gate. On the pinned stable
# toolchain without a sanitizer: AddressSanitizer needs nightly, and every crate
# forbids unsafe code. cargo-fuzz takes no --locked and would rewrite a stale
# fuzz/Cargo.lock, so the first line refuses one offline; `cargo fetch` would be
# a network command, and this is not a network recipe (`just sync` fills the
# cache). CARGO_NET_OFFLINE keeps cargo-fuzz's own build offline too. --target
# because cargo-fuzz defaults to the triple it was built for, and its macOS
# binary is x86_64. seconds bounds the fuzzing, not the build.
fuzz target="smoke" seconds="300":
    cargo update --workspace --locked --offline --manifest-path fuzz/Cargo.toml
    CARGO_NET_OFFLINE=true cargo fuzz run --sanitizer none --target "$(rustc -vV | sed -n 's/^host: //p')" "$1" -- -max_total_time="$2"

# The fuzz crate compiles on the pinned stable the way cargo-fuzz builds it,
# without running it, so a fuzz target that stops building fails the gate rather
# than the weekly job. The same offline lock guard and CARGO_NET_OFFLINE as fuzz.
fuzz-build:
    cargo update --workspace --locked --offline --manifest-path fuzz/Cargo.toml
    CARGO_NET_OFFLINE=true cargo fuzz build --sanitizer none --target "$(rustc -vV | sed -n 's/^host: //p')"

build:
    cargo build --workspace --all-features --locked

# nextest runs the unit and integration tests; it cannot run doctests, so those
# follow through cargo test. The cdylib's test binary needs libpython, and its
# behaviour tests are Python's, so the binding crate is excluded, as in every
# Rust test recipe. INSTA_UPDATE=no makes a snapshot mismatch fail
# without a pending file, which would trip the gate's worktree check.
test:
    INSTA_UPDATE=no cargo nextest run --workspace --exclude transectpy --all-features --locked
    cargo test --doc --workspace --exclude transectpy --all-features --locked

test-doc:
    cargo test --doc --workspace --exclude transectpy --all-features --locked

# Snapshots match, and every .snap file is referenced by a test; with no
# snapshots it passes. The whole suite runs so the orphan check sees every
# reference. --check and INSTA_UPDATE=no fail mismatches without writing
# pending files. cargo-insta forwards trailing options as test arguments, so
# nextest would reject --locked; the locks are checked first, offline, and the
# run stays offline. Doctests have their own gate, so its extra run is off.
snapshots-check: lock-check
    INSTA_UPDATE=no CARGO_NET_OFFLINE=true cargo insta test --check --unreferenced reject --test-runner nextest --disable-nextest-doctest --workspace --exclude transectpy --all-features

# Interactive review for a person at a terminal.
snapshots-review:
    cargo insta review --workspace

# The snapshot recipe that writes: rerun and accept without a terminal. Read
# the diff before committing. A .snap file no test refers to, left by a renamed
# or removed test, is deleted, so the deletion shows in the diff.
snapshots-accept: lock-check
    INSTA_UPDATE=new CARGO_NET_OFFLINE=true cargo insta test --accept --unreferenced delete --test-runner nextest --disable-nextest-doctest --workspace --exclude transectpy --all-features

# ----------------------------------------------------------------- format ---

# cargo fmt --all skips the fuzz crate, which is outside the workspace.
format:
    cargo fmt --all
    cargo fmt --manifest-path fuzz/Cargo.toml
    taplo fmt

# Automatic repairs. The fix config is run twice because a fixer's first pass
# may itself fail on what another fixer then repairs. Then clippy's own fixes,
# and the read-only gate to show what is left.
fix:
    -prek run --all-files --config .pre-commit-fix.yaml
    prek run --all-files --config .pre-commit-fix.yaml
    cargo fmt --manifest-path fuzz/Cargo.toml
    cargo clippy --workspace --all-targets --all-features --locked --fix --allow-dirty --allow-staged
    cargo clippy --manifest-path fuzz/Cargo.toml --all-targets --locked --fix --allow-dirty --allow-staged
    just lint

# ------------------------------------------------------------------ check ---

# Every hook in the read-only gate configuration, over every file.
lint:
    prek run --all-files

fmt-check:
    cargo fmt --all --check
    cargo fmt --manifest-path fuzz/Cargo.toml --check

toml-check:
    taplo fmt --check
    taplo lint

# Every lint the manifests declare, as errors. The manifests say `warn` so a
# local build never breaks mid-edit; this is where warnings become failures.
# The fuzz crate is outside the workspace, so --workspace skips it, and its own
# lint tables hold only if something compiles it; libfuzzer-sys's build script
# compiles libFuzzer's C++, so a C++ compiler is a prerequisite of the gate.
# allow_attributes sees only outer attributes, so an inner
# #![allow(..., reason = "...")] would pass it and silence the policy for a whole
# module; the search first rejects that form, on any line of the file and inside
# a cfg_attr, which rustfmt spreads over several lines: each file is joined into
# one line first. `[^]]*` stops at the attribute's first `]`, before any reason
# text. POSIX tools only, so BSD and GNU agree.
clippy:
    #!/bin/sh
    set -eu
    hits=$(find crates fuzz/fuzz_targets -name '*.rs' -exec sh -c 'for f; do tr "\n" " " < "$f" | grep -qE "#!\[[^]]*allow[[:space:](]" && printf "%s\n" "$f"; done; exit 0' sh {} +)
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" >&2
        printf '%s\n' 'clippy: inner #![allow] attribute found; use #[expect(..., reason = "...")]' >&2
        exit 1
    fi
    cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
    cargo clippy --manifest-path fuzz/Cargo.toml --all-targets --locked -- -D warnings

# Complexity, cohesion and coupling, through rustqual against rustqual.toml,
# once per crate. The version check comes first: rustqual's version decides
# what the gate reports, so a missing .tools/bin/rustqual must not fall
# through to another one on PATH.
metrics:
    #!/bin/sh
    set -eu
    pin=$(sed -n 's/^rustqual@//p' tools-source.txt)
    have=$(rustqual --version 2>/dev/null | sed -n 's/^rustqual //p')
    if [ "$have" != "$pin" ]; then
        printf 'metrics: rustqual %s on PATH, tools-source.txt pins %s; run just install-tools\n' "${have:-missing}" "$pin" >&2
        exit 1
    fi
    rustqual crates/libtransect --config rustqual.toml --fail-on-warnings --format github
    rustqual crates/transect --config rustqual.toml --fail-on-warnings --format github
    rustqual crates/transectpy --config rustqual.toml --fail-on-warnings --format github

# Every feature combination compiles and passes clippy, so a panic path behind
# `cfg(not(feature = ...))` is linted too. Not --no-dev-deps: that rewrites
# Cargo.toml while it runs and would trip the worktree snapshot on a crash.
features:
    cargo hack check --workspace --feature-powerset --locked
    cargo hack clippy --workspace --all-targets --feature-powerset --locked -- -D warnings

# Measures the pure-Rust crates; pytest exercises the binding outside llvm-cov.
# Runs every nextest test under instrumentation and enforces the floor. Doctests
# are not measured (nightly-only in llvm-cov); test-doc runs them uncovered.
# llvm-cov does not create the lcov file's directory, so the recipe does.
coverage:
    cargo llvm-cov nextest --workspace --exclude transectpy --all-features --locked --no-report
    cargo llvm-cov report --fail-under-lines {{coverage_floor}}
    mkdir -p target/llvm-cov
    cargo llvm-cov report --lcov --output-path target/llvm-cov/lcov.info

# The API reference, with every rustdoc warning an error and the docs.rs cfg.
doc:
    RUSTDOCFLAGS="-D warnings --cfg docsrs" cargo doc --workspace --no-deps --all-features --locked

# What GitHub Pages serves: the API reference `doc` builds, from an empty
# target/doc so that nothing stale is published, and a root index.html that
# links to every crate's page, because stable rustdoc writes none. Not a gate
# and outside `just check`: `doc` is the gate, and this adds one file to what it
# built, with `doc`'s own flags, so the hosted reference is the one the gate
# proved.
site:
    rm -rf target/doc
    just doc
    printf '%s\n' '<!doctype html>' '<html lang="en">' '<meta charset="utf-8">' '<title>transect: API reference</title>' '<p><a href="libtransect/index.html">The libtransect API reference</a></p>' '<p><a href="transect/index.html">The transect API reference</a></p>' '<p><a href="transectpy/index.html">The transectpy binding crate</a></p>' '</html>' > target/doc/index.html

# Licences, bans and sources are answerable offline once `just sync` has run.
# The fuzz crate is outside the workspace, so it gets its own run.
deny:
    cargo deny --locked check licenses bans sources
    cargo deny --locked --manifest-path fuzz/Cargo.toml check licenses bans sources

# Advisories need the RustSec database over the network, so this sits outside
# `just check`.
audit:
    cargo deny --locked check advisories
    cargo deny --locked --manifest-path fuzz/Cargo.toml check advisories

# Unused dependencies in the workspace's manifests and the fuzz crate's.
deps-unused:
    cargo shear
    cargo shear fuzz

# Mutation testing, a report and never a gate: it grows with the code towards
# hours, and a mutant that survives asks for a judgement. It mutates a copy of
# the tree, so the worktree gains only mutants.out/, which Git ignores; the copy
# leaves out what Git ignores, or it would carry .pixi/ and .tools/ into every
# build. `cargo test`, not nextest, because nextest skips doctests and a mutant
# only a doc example catches would be reported missed. The pure-Rust crates
# only. The first line is the positive control over the same selection the run
# uses, the caller's filters included: a filter that matched nothing would
# otherwise print a green summary over zero mutants. Exit 2 means a mutant
# survived, 3 a timeout, 4 a failing baseline. lock-check runs first: the
# listing pass's `cargo metadata` takes no --locked and would rewrite a stale
# Cargo.lock.
mutants *args: lock-check
    [ "$(cargo mutants --list --package libtransect --package transect --all-features "$@" | grep -c .)" -gt 0 ] || { printf '%s\n' 'mutants: no mutants found; the filters select nothing' >&2; exit 1; }
    cargo mutants --package libtransect --package transect --all-features --gitignore=true --cargo-arg=--locked "$@"

# --------------------------------------------------------------- documents ---

# Markdown lint, typos and the offline link check over every file, then the
# handbook contract: every page in docs/manifest.yml with matching front matter,
# every topic owned once, every page reachable from docs/README.md.
check-docs:
    prek run --all-files markdownlint-cli2 typos lychee
    bg-validate-docs

# Gate: every `//! UNDECIDED:` marker under crates/ is listed under
# "Undecided areas" in docs/project/open-decisions.md, and every path listed
# there carries the marker, so the register and the stubs cannot drift apart.
check-undecided:
    python -I scripts/check_undecided.py

# The agent contract: AGENTS.md carries the required guidance, the adapters
# are exact, and every skill's bridges repeat its frontmatter and add nothing.
check-agents:
    bg-validate-agents

# Every link, external ones included (network); outside `just check`.
check-links-online:
    prek run --all-files --hook-stage manual lychee-online

# ------------------------------------------------------------------ python ---

# Builds the extension into the pixi environment in place (the .so beside
# __init__.py, gitignored). maturin needs an environment to install into and
# finds the pixi one through CONDA_PREFIX, set on this line alone; it installs
# with the pinned uv on PATH. `locked = true` in crates/transectpy/pyproject.toml
# makes it honour Cargo.lock. Not a gate: py-test and py-stubtest depend on it.
py-develop:
    CONDA_PREFIX="{{ justfile_directory() }}/.pixi/envs/default" maturin develop --uv --manifest-path crates/transectpy/Cargo.toml

# Gate: ruff over every Python file ruff.toml names; --show-files must list
# the package, or an exclude has emptied the gate (ruff exits 0 on no files);
# then the positive control: the fixture must fail with exit status 1
# (violations found) and the output must name F401 and E501, the fixture's own
# violations: under select = ALL the file also trips other rules, so the exit
# status alone would fire with F and E dropped. Exit 2 is a tool or usage error,
# not a fired control; a missing fixture is E902 with exit 1, so it is tested
# first.
py-lint:
    ruff check .
    ruff format --check .
    ruff check --show-files . | grep -q 'crates/transectpy/python/transectpy/__init__\.py$' || { printf '%s\n' 'py-lint: ruff did not see the package' >&2; exit 1; }
    test -f tests/fixtures/py-lint-violation/ruff.py || { printf '%s\n' 'py-lint: the positive control fixture is missing' >&2; exit 1; }
    status=0; out=$(ruff check --quiet --output-format concise tests/fixtures/py-lint-violation/ruff.py) || status=$?; [ "$status" -eq 1 ] && printf '%s\n' "$out" | grep -q ': F401 ' && printf '%s\n' "$out" | grep -q ': E501 ' || { printf '%s\n' "$out" 'py-lint: the positive control did not fire (exit 1 naming F401 and E501)' >&2; exit 1; }

# Gate: mypy over the files mypy.ini names (the stub, the package, the tests,
# scripts/), then the positive control: the fixture must fail with exit status
# 1 (type errors). Exit 2 is a usage or I/O error, not a fired control.
# stubtest, which imports the built module, is py-stubtest.
py-typecheck:
    mypy
    status=0; mypy --no-error-summary tests/fixtures/py-lint-violation/mypy.py || status=$?; [ "$status" -eq 1 ] || { printf '%s\n' 'py-typecheck: the positive control did not fire' >&2; exit 1; }

# Gate: the binding's behaviour tests against the extension py-develop built,
# and the repository scripts' tests.
py-test: py-develop
    python -m pytest crates/transectpy/tests tests/scripts

# Gate: the stub file describes the built module exactly. The allowlist must
# stay short; an entry hides a discrepancy. stubtest ignores `__version__`, so
# test_version.py pins its declared type with assert_type, under py-typecheck.
py-stubtest: py-develop
    python -m mypy.stubtest transectpy._transectpy --allowlist crates/transectpy/tests/stubtest-allowlist.txt

# The release wheel for this platform into dist/, which is emptied first so a
# stale wheel can never be smoked. A release build on every `just check` is
# the price of smoking the artefact a release ships.
wheel:
    rm -rf dist
    maturin build --release --manifest-path crates/transectpy/Cargo.toml --out dist

# Gate: the wheel installs and works in a fresh virtual environment, offline.
# Exactly one wheel, which must exist and be stable-ABI for the 3.11 floor
# (an unmatched glob is one literal argument); a venv on the pixi interpreter
# with no download; install from dist/ alone; then the smoke script. Python
# runs with -I so nothing in the worktree shadows the package.
wheel-smoke: wheel
    #!/bin/sh
    set -eu
    set -- dist/*.whl
    [ "$#" -eq 1 ] && [ -f "$1" ] || { printf 'wheel-smoke: expected one wheel in dist/, found: %s\n' "$*" >&2; exit 1; }
    case "$1" in *-cp311-abi3-*.whl) ;; *) printf 'wheel-smoke: %s is not a cp311-abi3 wheel\n' "$1" >&2; exit 1;; esac
    rm -rf target/wheel-smoke/venv
    uv venv --python .pixi/envs/default/bin/python --no-python-downloads --offline target/wheel-smoke/venv
    uv pip install --python target/wheel-smoke/venv --offline --no-index --no-deps "$1"
    target/wheel-smoke/venv/bin/python -I tests/fixtures/smoke/smoke.py

# Gate: the same wheel on the floor interpreter, the plain CPython 3.11 that
# install-tools put in .tools/python. Offline: uv may use only that managed
# interpreter and may download nothing, so a missing one fails here.
wheel-smoke-floor: wheel
    #!/bin/sh
    set -eu
    set -- dist/*.whl
    [ "$#" -eq 1 ] && [ -f "$1" ] || { printf 'wheel-smoke-floor: expected one wheel in dist/, found: %s\n' "$*" >&2; exit 1; }
    rm -rf target/wheel-smoke/venv-floor
    UV_PYTHON_INSTALL_DIR=.tools/python uv venv --python {{python_floor}} --managed-python --no-python-downloads --offline target/wheel-smoke/venv-floor
    uv pip install --python target/wheel-smoke/venv-floor --offline --no-index --no-deps "$1"
    target/wheel-smoke/venv-floor/bin/python -I -c 'import sys; assert sys.version_info[:3] == (3, 11, 18), sys.version'
    target/wheel-smoke/venv-floor/bin/python -I tests/fixtures/smoke/smoke.py

# Gate: one version, in every place it is written: the workspace, every member
# crate as cargo resolves it, the wheel manifest, and the installed wheel's
# module and metadata, read from the venv wheel-smoke left; fails if that venv
# is missing.
version-check:
    python -I scripts/version_check.py

# --------------------------------------------------------------- aggregate ---

check-clean baseline="":
    bg-project-check clean "$1"

# The complete gate: the recipes pyproject.toml lists, in order, with the
# worktree snapshotted between each, then check-clean.
check:
    bg-project-check run
