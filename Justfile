set positional-arguments := true
set shell := ["sh", "-eu", "-c"]

# pixi owns every tool binary and the Python environment (.pixi/envs/default;
# pyproject.toml is the manifest, pixi.lock the pin). Tools conda-forge lacks
# (tools.txt, and tools-source.txt for those with no release binary) live in
# .tools/bin. Every recipe sees both first; cargo finds cargo-nextest and
# friends on PATH by name. Neither directory holds a cargo, so rustup's proxy
# stays first for the compiler (check-toolchain proves it).
export PATH := justfile_directory() / ".pixi" / "envs" / "default" / "bin" + ":" + justfile_directory() / ".tools" / "bin" + ":" + env("PATH")

# Line-coverage floor over crates/*/src/**. Lower the complexity, not the
# number.
coverage_floor := "90"

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

# Tools conda-forge lacks into .tools/bin (network). cargo-binstall comes from
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
# follow through cargo test. INSTA_UPDATE=no makes a snapshot mismatch fail
# without a pending file, which would trip the gate's worktree check.
test:
    INSTA_UPDATE=no cargo nextest run --workspace --all-features --locked
    cargo test --doc --workspace --all-features --locked

test-doc:
    cargo test --doc --workspace --all-features --locked

# Snapshots match, and every .snap file is referenced by a test; with no
# snapshots it passes. The whole suite runs so the orphan check sees every
# reference. --check and INSTA_UPDATE=no fail mismatches without writing
# pending files. cargo-insta forwards trailing options as test arguments, so
# nextest would reject --locked; the locks are checked first, offline, and the
# run stays offline. Doctests have their own gate, so its extra run is off.
snapshots-check: lock-check
    INSTA_UPDATE=no CARGO_NET_OFFLINE=true cargo insta test --check --unreferenced reject --test-runner nextest --disable-nextest-doctest --workspace --all-features

# Interactive review for a person at a terminal.
snapshots-review:
    cargo insta review --workspace

# The snapshot recipe that writes: rerun and accept without a terminal. Read
# the diff before committing. A .snap file no test refers to, left by a renamed
# or removed test, is deleted, so the deletion shows in the diff.
snapshots-accept: lock-check
    INSTA_UPDATE=new CARGO_NET_OFFLINE=true cargo insta test --accept --unreferenced delete --test-runner nextest --disable-nextest-doctest --workspace --all-features

# ----------------------------------------------------------------- format ---

# cargo fmt --all skips the fuzz crate, which is outside the workspace.
format:
    cargo fmt --all
    cargo fmt --manifest-path fuzz/Cargo.toml
    taplo fmt

# ------------------------------------------------------------------ check ---

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

# Every feature combination compiles and passes clippy, so a panic path behind
# `cfg(not(feature = ...))` is linted too. Not --no-dev-deps: that rewrites
# Cargo.toml while it runs and would trip the worktree snapshot on a crash.
features:
    cargo hack check --workspace --feature-powerset --locked
    cargo hack clippy --workspace --all-targets --feature-powerset --locked -- -D warnings

# Runs every nextest test under instrumentation and enforces the floor. Doctests
# are not measured (nightly-only in llvm-cov); test-doc runs them uncovered.
# llvm-cov does not create the lcov file's directory, so the recipe does.
coverage:
    cargo llvm-cov nextest --workspace --all-features --locked --no-report
    cargo llvm-cov report --fail-under-lines {{coverage_floor}}
    mkdir -p target/llvm-cov
    cargo llvm-cov report --lcov --output-path target/llvm-cov/lcov.info

# The API reference, with every rustdoc warning an error and the docs.rs cfg.
doc:
    RUSTDOCFLAGS="-D warnings --cfg docsrs" cargo doc --workspace --no-deps --all-features --locked

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

# --------------------------------------------------------------- aggregate ---

check-clean baseline="":
    bg-project-check clean "$1"

# The complete gate: the recipes pyproject.toml lists, in order, with the
# worktree snapshotted between each, then check-clean.
check:
    bg-project-check run
