set positional-arguments := true
set shell := ["sh", "-eu", "-c"]

# pixi owns every tool binary and the Python environment (.pixi/envs/default;
# pyproject.toml is the manifest, pixi.lock the pin). Tools conda-forge lacks
# (tools.txt, and tools-source.txt for those with no release binary) live in
# .tools/bin. Every recipe sees both first; cargo finds cargo-nextest and
# friends on PATH by name. Neither directory holds a cargo, so rustup's proxy
# stays first for the compiler (check-toolchain proves it).
export PATH := justfile_directory() / ".pixi" / "envs" / "default" / "bin" + ":" + justfile_directory() / ".tools" / "bin" + ":" + env("PATH")

default:
    @just --list

alias list := default

# ------------------------------------------------------------------ setup ---

# One explicit first-run command. Never stages, commits, tags, or pushes.
initialize:
    sh scripts/initialize.sh

# The pin in rust-toolchain.toml is honoured only by rustup's cargo proxy. A
# cargo from pixi, Homebrew or a distribution ignores the file and builds with
# whatever it is, so the gate refuses it before anything else runs. A proxy is
# rustup itself under another name (a symlink or hard link), so the test is file
# identity, not a path: CARGO_HOME pointed elsewhere cannot make a foreign cargo
# pass. The proxy
# still obeys RUSTUP_TOOLCHAIN or a `rustup override`, both of which outrank
# the file, so the active toolchain must then be the pinned channel, selected
# by rust-toolchain.toml itself. RUSTUP_AUTO_INSTALL=0 makes an uninstalled
# toolchain a refusal instead of a download.
check-toolchain:
    command -v rustup >/dev/null || { printf '%s\n' 'rustup is not installed; see https://rustup.rs' >&2; exit 2; }
    [ "$(command -v cargo)" -ef "$(command -v rustup)" ] || { printf '%s\n' "cargo resolves to $(command -v cargo), not rustup's proxy" >&2; exit 2; }
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

# Both lockfiles, exactly as committed. Never rewrites either.
sync:
    cargo fetch --locked
    pixi install --frozen

lock:
    cargo update --workspace
    pixi lock

# Within the manifest's constraints only; every direct pixi pin is exact, so
# this moves transitives. `pixi upgrade` rewrites the pins themselves and is
# not this recipe.
lock-upgrade:
    cargo update
    pixi update

# Offline, like every gate recipe: a cold Cargo cache fails rather than
# fetching the registry index (`just sync` fills it), and an offline solve on a
# stale lock still fails, which is the right answer. --dry-run because pixi
# would otherwise rewrite a stale lock from that restricted solve.
lock-check:
    cargo update --workspace --locked --offline
    pixi lock --check --offline --dry-run

# ---------------------------------------------------------------- develop ---

build:
    cargo build --workspace --all-features --locked

# nextest runs the unit and integration tests; it cannot run doctests, so those
# follow through cargo test.
test:
    cargo nextest run --workspace --all-features --locked
    cargo test --doc --workspace --all-features --locked

# --------------------------------------------------------------- aggregate ---

check-clean baseline="":
    bg-project-check clean "$1"

# The complete gate: the recipes pyproject.toml lists, in order, with the
# worktree snapshotted between each, then check-clean.
check:
    bg-project-check run
