# libtransect

`libtransect` is the core of Transect's in-application client, where every behaviour
of the client will live. The `transect` Rust client API and the `transectpy` Python
binding are built on it, never the reverse.

The client is not implemented yet. Today the public API is one item, `version()`, which
returns the version in the workspace manifest. The private modules that will hold the
ingest queue, the local database, schema evolution and the data writer contain
documentation only.

Run `just doc` from the repository root and open `target/doc/libtransect/index.html`
for the API reference; the tested example lives in rustdoc. The handbook starts at
`docs/README.md` in the repository.

Requires Rust 1.99 or newer. Licensed under Apache-2.0. Repository:
<https://github.com/BiscuitBin/transect>.
