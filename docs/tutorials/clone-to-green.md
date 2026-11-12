---
title: "Clone to green"
kind: "tutorial"
audience: ["contributor", "agent"]
canonical_for: ["first_run_tutorial"]
requires: []
---

# Clone to green

This walks from a fresh clone to a passing gate, and then proves the gate catches a
mistake. It takes one initialization download and a few minutes of building.

## 1. Clone and initialize

With the prerequisites on [Develop locally](../how-to/develop-locally.md) installed:

```sh
git clone https://github.com/BiscuitBin/transect.git
cd transect
just initialize
```

The last lines say `Ready. Next: just check.` and that nothing was staged, committed,
tagged or pushed.

## 2. Run the gate

```sh
just check
```

Each gate prints `==> just <recipe>` as it starts. The run ends with
`All checks passed and the worktree is unchanged.`

## 3. Watch it catch a panic path

Add a function that unwraps to `crates/libtransect/src/lib.rs`, above the tests:

```rust
/// Demonstration only.
#[must_use]
pub const fn first(value: Option<u8>) -> u8 {
    value.unwrap()
}
```

Run `just clippy`. It fails with `used unwrap() on an Option value`: a panic outside
test code is what [decision 0004](../decisions/0004-lint-policy.md) rejects. Remove the
function and run `just check` again to see it green.

## 4. See the Python client

```sh
just py-develop
.pixi/envs/default/bin/python -c 'import transectpy; print(transectpy.__version__)'
```

It prints the workspace version, the only thing the client exposes today.

## Related pages

- [Develop locally](../how-to/develop-locally.md)
- [Quality gates](../reference/quality-gates.md)
