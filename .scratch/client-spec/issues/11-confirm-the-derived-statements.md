# 11: Confirm the Derived statements

**What to build:** Every statement the client specification marks "Derived" has been put to the maintainer and is either confirmed or corrected. Afterwards a reader can trust that an unmarked statement is something the maintainer answered, and nothing is built on a guess.

A "Derived" statement follows from the maintainer's answers during the elicitation but was never put to them directly. Search the specification for "Derived" to find them: there were 29 such lines when this ticket was last revised, and some hold more than one statement. The handbook's page on working with the specifications says to confirm a Derived statement before building on it.

Eight were listed in the plan the maintainer approved before the specification was written, and were not corrected then. They are still marked, because not correcting a list is weaker than confirming each item:

- Nesting establish inside an open establish fails loudly. One after another is fine; each is a new run.
- The fake core applies the same declaration, row and tenant rules as the production core and records every write with its outcome. It has no data writer, no local databases and no queue bound.
- A client handle may be used from several threads or tasks at once.
- Every accepted row is stamped from the client's clock when it is written.
- Positions are assigned when a row is accepted, so a row lost after that leaves a visible gap.
- A tenant-scoped keyed state table holds the latest value per tenant and key. Unattributed rows form their own group.
- A row exactly at the maximum row size is accepted.
- A declared table lasts as long as its confluence. Nothing removes one.

The rest were added while the specification was written and have never been listed for approval. Among them: the order in which a write is checked; what the stored position is and that a hand-over offers nothing above it; that a confirmation above the stored position is refused; that per-table counters belong to a run; that the location is an argument to establish and not configuration; that a table is known by its namespace and name; what a forked child's copy of a confluence carries; and that a loss at shutdown is logged like any other loss. Read the specification for the full set: this list is a summary and may be stale.

The interim behaviours that open questions carry ("Until decided") are a separate thing. Each belongs to its open question and is not confirmed here.

How to run it: put the statements to the maintainer in plain language, a few related ones at a time, each with the consequence of the opposite answer. For each, the maintainer confirms it, corrects it, or says it is undecided.

**External precondition:** The maintainer's time. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** waiting on the maintainer

- [ ] Every statement marked "Derived" in the specification has been put to the maintainer, in plain language, with what the opposite answer would mean
- [ ] A confirmed statement loses its "Derived" marker and is otherwise unchanged
- [ ] A corrected statement is rewritten as the maintainer answered, with every rule, invariant and guarantee that depended on it brought into line
- [ ] A statement the maintainer calls undecided becomes an `open question`, with the interim behaviour stated if one holds
- [ ] No statement is confirmed by the agent, and no existing open question is resolved
- [ ] Handbook text that restates the specification (the glossary, the count of open questions, and the meaning of the "Derived" marker) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] No code is added
