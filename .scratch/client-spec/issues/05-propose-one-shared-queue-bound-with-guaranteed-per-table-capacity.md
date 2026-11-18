# 05: Propose one shared queue bound with guaranteed per-table capacity

**What to build:** A host application may cap the client's queued rows with one bound across all tables, while each table keeps a guaranteed capacity that no other table can take. A noisy table can then use spare room without starving a quiet one. This ticket delivers that shape of bound as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: a bound per table. Every table has its own capacity in the local ingest queue, in rows, with a maximum row size. A flooding table can only displace its own rows, and other tables are unaffected. That stays the default.

The maintainer chose the bound per table during the elicitation, with this note, verbatim:

> Lets start with this. Later we can revisit and look at creating on shared bound but with individual guaranteed capacity (similar to option 3).

Option 3 of that question read: "Shared bound, reserved share: One overall capacity caps the client's memory, and each table may reserve a guaranteed share of it. A table can use unreserved space when it is free, but can never be pushed below its reservation by another table."

The proposal must say:

- What the shared bound is measured in, and how it relates to the per-table capacity in rows and the maximum row size.
- How a table is given its guaranteed capacity, and what a table with none gets.
- What happens when the guaranteed capacities add up to more than the shared bound. A declaration may arrive at any time, including during establish.
- What happens to an arriving row when its table is above its guarantee and the shared bound is full, and how that refusal is counted.
- That no table is ever pushed below its guaranteed capacity by another table.
- How it composes with evict-oldest, if ticket 04's policy has been proposed by then: whose row is evicted, and whether one table's arriving row may evict another table's row.

Related open questions, by number and gist. Do not resolve them:

- 16: the default queue capacity and maximum row size, and how a table is given its own.
- 21: how a row's size is measured against the maximum row size.
- 3: whether keyed state writes coalesce by key in the queue.

**External precondition:** None.

**Blocked by:** None in this set. Ticket 04 does not gate it: if 04 has landed, this proposal says how the two compose, and if it has not, it says nothing about eviction.

**Status:** deferred until after the MVP

- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] A bound per table stays the default, so nothing already proposed changes meaning
- [ ] The total queued never exceeds the shared bound, and no table is pushed below its guaranteed capacity by another table
- [ ] Every row the shared bound refuses is counted exactly once against its own table, and no write blocks or fails
- [ ] The proposal says what happens when guaranteed capacities exceed the shared bound, including for a table declared during establish
- [ ] If evict-oldest has been proposed, the proposal says how the two compose
- [ ] The diagnostics snapshot's per-table fields still describe each table's capacity and queued rows truthfully under the shared bound
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] No code is added
