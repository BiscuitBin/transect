# 06: Propose transactional client blocks

**What to build:** Application code may opt into a mode in which the rows written through one client handle, within its block, are treated as a group. This ticket delivers that mode as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: a client handle's block is one unit of work (a request, job or task). The block only scopes bindings, such as the tenant. It holds no rows: each write is offered to the local ingest queue immediately, and rows from one block may be accepted, refused, stored and lost independently of each other. That stays the default.

The maintainer's note from the elicitation, verbatim. It is the only statement on the subject:

> Eventually we could look at making the block have more of a transactional behavior as an option, but for now this sounds right.

What "transactional" promises is therefore elicited, not assumed. The elicitation must settle at least:

- What the group promises: all of a block's rows are accepted or none; all are stored or none; all are handed over together; or something weaker, such as rows that share an identifier a collector can group by.
- When the group's rows are offered to the local ingest queue: as written, or when the block ends. Holding them until the block ends means the block holds rows, which it does not today.
- What ends a group without committing it: an exception leaving the block, a block that never ends, the end of establish while the block is open.
- What happens when one row of the group is refused (invalid, oversize, queue full), and what happens when the group is larger than a table's capacity.
- How a group that spans several tables behaves, given that each table has its own queue.
- How a discarded group is counted. Every row the client loses while its process lives is counted exactly once.

Promises that hold in any mode: a write never fails and never blocks, and a write returns nothing.

Related open questions, by number and gist. Do not resolve them:

- 3: whether keyed state writes coalesce by key in the queue.
- 12: whether a bounded retry comes before a failed batch is dropped.
- 16: the default queue capacity and maximum row size.

**Research file:** `.scratch/client-spec/research/06-transactional-client-blocks.md`, written only if the proposal cites another system. "Citing a comparable" in `CONTEXT.md` says what it records.

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the conformance and breakage lenses, at two key moments: after the maintainer's answers are recorded verbatim in this ticket's hand-back and before the specification changes; and before hand-back. Questions to put to the reviewers:

1. Is what "transactional" promises stated in one sentence that the maintainer's recorded words support, with nothing assumed from what the word usually means?
2. Is there a way for a group to end (an exception, a block that never ends, the end of establish, a refused row, a group larger than a table's capacity) that leaves it partly applied, or a row uncounted or counted twice?
3. Can a write now block or fail, or can a block hold rows without a bound?
4. Does the proposal quietly answer open question 3, 12 or 16, or change what a block that does not ask for the mode does?

**External precondition:** None.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] What "transactional" promises is elicited with the maintainer before the specification changes, and the proposal states it in one sentence
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] The mode is opt-in; a block that does not ask for it behaves as today, so nothing already proposed changes meaning
- [ ] The proposal says when a group's rows are offered to the local ingest queue, and what bounds the rows a block may hold if it holds any
- [ ] The proposal says what happens to the group when a row is refused, when the block ends by an exception, and when establish ends while the block is open
- [ ] Every row of a discarded group is counted exactly once, and no write blocks or fails
- [ ] The proposal says how a group spanning several tables behaves, or records it as an `open question`
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] Any comparable the proposal cites has its stated why and its fit in the research file, as "Citing a comparable" in `CONTEXT.md` requires; a comparable without both informs the proposal and does not justify it
- [ ] The maintainer's answers are recorded verbatim in the hand-back before the first review; the adversarial review ran at each key moment as `REVIEW.md` says; and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No code is added
