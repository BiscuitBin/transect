---
name: review-docs
description: Add or revise a handbook page so it satisfies the documentation contract and stays reachable.
---

# Add or revise a documentation page

1. Read `AGENTS.md` and `docs/README.md`. The contract is enforced by `bg-validate-docs`,
   which `just check-docs` runs and which reports every violation at once.
2. Find the topic's owner first. Every topic in `docs/manifest.yml` has exactly one
   canonical page, so prefer editing the owning page over writing a new one.
3. A new page needs a `docs/manifest.yml` entry whose `title`, `kind`, `audience`,
   `canonical_for` and `requires` match the page frontmatter exactly, list order
   included.
4. Give the page one level-one heading identical to its `title`, at least forty words of
   substance, and no unfinished markers or placeholder prose.
5. Link the page from `docs/README.md`, directly or transitively; an unreachable page
   fails the contract.
6. Describe only what exists. State nothing as decided that the open-decisions register
   lists, and nothing as open that a decision record settles.
7. Run `just check-docs` and `just check-undecided`, then `just check` before handoff.
