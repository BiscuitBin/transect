# 10: Propose snapshot capture

**What to build:** A developer can fill a snapshot state table: a completed capture replaces the table's contents, and an incomplete one changes nothing. This ticket delivers how a capture is expressed, bounded and scoped to a tenant, as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: a snapshot state table can be declared, and nothing can write to it. The specification says so on purpose and lists how a snapshot state table is captured under what it excludes. Time series tables and keyed state tables are unaffected by this ticket.

The maintainer's note from the elicitation, verbatim:

> We need to spec out snapshot capture more. We will do so once we decide more of the implementation details. Ideally being able to query the application DB directly (e.g. postgresql) would be an option so that the data doesn't need to go through the host language first. TBD though.

What is already settled, and is not reopened here:

- A completed capture replaces the table's contents. An incomplete capture changes nothing.
- A write never fails and never blocks, and the client never harms the host application.
- Every row the client loses while its process lives is counted exactly once.
- Keyed state tables have no delete and no tombstones. Whether a snapshot's "absent from the capture" is the one way a row leaves a state table is part of this ticket.

The proposal must say:

- How application code expresses a capture: where it begins, how rows join it, and what completes it.
- What makes a capture incomplete (an exception, a capture that never completes, the end of establish while it is open) and how its rows are counted.
- What bounds a capture, given that the local ingest queue is bounded per table and a capture may be larger than a table's capacity.
- What one capture covers for a tenant-scoped table: one tenant's rows or every tenant's. This is open question 4, so elicit the choice and do not assume it. Then, which rows a completed capture can remove.
- How a completed capture appears in a hand-over, and what a collector can conclude about rows absent from it.
- Whether reading the application's database directly is offered, and what the client then promises about load on that database and about credentials.

Related open questions, by number and gist. This ticket exists to put proposals for 4 and 5 to the maintainer; the agent closes neither:

- 4: for a tenant-scoped snapshot state table, whether one capture replaces one tenant's rows or every tenant's.
- 5: how a snapshot capture is expressed and bounded, including the option of reading the application's database directly.
- 3: whether keyed state writes coalesce by key in the queue.
- 16: the default queue capacity and maximum row size.
- 8: what bounds the local databases when no collection happens.

**External precondition:** The implementation details the maintainer wants decided first. The note does not list them. The local databases' on-disk format and the form of the hand-over (open question 15) are the likely ones; confirm with the maintainer which decisions gate this before starting.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] The maintainer confirms which implementation decisions gate this ticket, and they are decided, before any proposal is written
- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] Time series tables and keyed state tables behave as proposed today, so nothing already proposed changes meaning
- [ ] A completed capture replaces the contents and an incomplete one changes nothing, with one scenario of each traced through the proposal
- [ ] For the boundary the maintainer chooses (open question 4), the proposal says which rows a completed capture removes, with one scenario traced for a tenant-scoped table
- [ ] The proposal says what bounds a capture and what happens to one larger than the bound
- [ ] Every row of an incomplete or refused capture is counted exactly once, and no write blocks or fails
- [ ] The proposal says whether reading the application's database directly is offered, or records it as an `open question`
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] No code is added
