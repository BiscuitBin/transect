---
title: "Open decisions"
kind: "project"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["open_decisions"]
requires: []
---

# Open decisions

The single register of what is not yet decided. Nothing here has an answer, a preferred
answer or a shortlist: proposing one is the work of the decision that closes the entry.
Agents and contributors do not choose a design for anything listed here without that
decision.

## Product

- How the client reports its own failures to the host application.
- How the client behaves when the host application forks.

## Development and CI

Open points about the toolchain, the gates and the release.

- **Arithmetic overflow.** Whether overflow in `+`, `-`, `*`, shifts and negation, which
  panics in debug builds and is not linted, gets a lint or a checked-arithmetic rule once
  the client has real arithmetic. Blocks: nothing yet.
- **Free-threaded wheels.** Whether the release workflow also builds `cp314t` wheels for
  free-threaded Python, which the stable ABI does not cover. Blocks: nothing; the abi3
  wheels serve every supported CPython.
- **API compatibility checks.** Whether and when cargo-semver-checks guards the published
  crates' API: proposed as an advisory `just semver` at the first release that changes
  the public API, and a gate before 1.0
  ([decision 0010](../decisions/0010-release-process.md)). Blocks: nothing yet; the API
  is one function.
- **A GitHub Release for the tag.** Whether a release tag also creates a GitHub Release
  from its changelog section, which would give a release job `contents: write`
  ([decision 0010](../decisions/0010-release-process.md)). Blocks: nothing.

## Related pages

- [Architecture decisions](../decisions/README.md)
- [Glossary](glossary.md)
