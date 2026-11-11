# transect

`transect` is the Rust client API of Transect's in-application client: the crate a Rust
host application depends on. It is built on the `libtransect` core and translates the
core's behaviour; it holds none of its own.

The client is not implemented yet. Today the public API is one item, `version()`, which
returns the core's version.

Run `just doc` from the repository root and open `target/doc/transect/index.html` for
the API reference; the tested example lives in rustdoc. The handbook starts at
`docs/README.md` in the repository.

Requires Rust 1.99 or newer. Licensed under Apache-2.0. Repository:
<https://github.com/BiscuitBin/transect>.
