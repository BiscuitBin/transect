# 04: Propose evict-oldest as a queue policy

**What to build:** A developer may choose, per table, that a full local ingest queue makes room for the arriving row by evicting the oldest queued row, instead of refusing the arriving one. This ticket delivers that second policy as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: each table has its own bounded local ingest queue, with a capacity in rows and a maximum row size. When a table's capacity is used up, the arriving row is refused and counted as rejected because the queue was full. That is the only queue-full behaviour, and it stays the default.

Provenance: the plan the maintainer approved after the elicitation records "Evict-oldest as a queue policy" as deferred until after the MVP. Asked which policies a developer can choose between when a time series table's capacity is used up, the maintainer chose "Reject the arriving row only" with the note "we can add more options later after the mvp". No sentence from the maintainer describes evict-oldest itself, so what it promises is elicited, not assumed.

The proposal must say:

- How a table is given the policy, and that a table with no policy stated refuses the arriving row as today.
- How an evicted row is counted. It was accepted and then lost, which is not the same as a row refused on arrival, and it must be counted exactly once.
- How an eviction is logged, under the existing rule for host logs: the first occurrence of a kind of failure for a table at once, then one total.
- What the gap means to a collector. A position is assigned when a row is accepted, so an evicted row leaves a gap in the positions a collector is handed.
- What the policy means for a keyed state table, where the oldest queued row may be the only queued value for its key.

Related open questions, by number and gist. Do not resolve them:

- 3: whether keyed state writes coalesce by key in the queue, and what stops a full queue from refusing the latest value for a key.
- 25: whether a hand-over also carries the stored position, so a collector can tell rows still waiting from rows lost.
- 16: the default queue capacity and maximum row size, and how a table is given its own.

**Research file:** `.scratch/client-spec/research/04-evict-oldest-as-a-queue-policy.md`, written only if the proposal cites another system. "Citing a comparable" in `CONTEXT.md` says what it records.

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the conformance and breakage lenses, at two key moments: after the maintainer's answers are recorded verbatim in this ticket's hand-back and before the specification changes; and before hand-back. Questions to put to the reviewers:

1. No sentence from the maintainer described evict-oldest before this ticket. Is everything the proposal says it promises now in the maintainer's recorded words, or marked "Derived"?
2. Is there a sequence of writes in which an evicted row is counted twice, not at all, or in the counter for a row refused on arrival, or in which a queue's depth exceeds its capacity?
3. Does the proposal quietly answer open question 3 for keyed state tables, or open question 25 on what a collector concludes from a gap?
4. Does a table that states no policy behave exactly as today?

**External precondition:** None.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] Refusing the arriving row stays the default, so nothing already proposed changes meaning
- [ ] Every evicted row is counted exactly once, the proposal says where and whether that is told apart from a row refused on arrival, and no write blocks or fails
- [ ] A table's queue depth still never exceeds its capacity
- [ ] The proposal says how an eviction appears in the host's logs and in the diagnostics snapshot
- [ ] The proposal says what a collector can and cannot conclude from the gap an eviction leaves in the positions
- [ ] The proposal says what the policy does for a keyed state table, or records it as an `open question`
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] Any comparable the proposal cites has its stated why and its fit in the research file, as "Citing a comparable" in `CONTEXT.md` requires; a comparable without both informs the proposal and does not justify it
- [ ] The maintainer's answers are recorded verbatim in the hand-back before the first review; the adversarial review ran at each key moment as `REVIEW.md` says; and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No code is added
