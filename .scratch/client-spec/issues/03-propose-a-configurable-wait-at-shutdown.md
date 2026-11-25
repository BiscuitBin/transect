# 03: Propose a configurable wait at shutdown

**What to build:** A host application may ask the client to wait a bounded time at the end of establish, so that rows still in the local ingest queues are stored instead of discarded. This ticket delivers that behaviour as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: at the end of establish nothing waits. Writes stop being accepted, the batch the data writer has in hand is finished, everything still queued is discarded and counted as lost at shutdown, and the local databases are left consistent. That stays the default. The wait is something a host application opts into.

The maintainer's note from the elicitation, verbatim:

> If we go with a push model we can revisit, but with a pull model it is unlikely to provided benefit. We are likely to drain the queue just for all the data to be dropped. For context, the most common use case for this will be in ephemeral cloud environments such as Kubernetes worker pods. Create a ticket to revisit this at some point in the future to at least make it configurable, But for the MVP, let's keep it simple and not introduce any complications for the host's shutdown process.

The proposal must say:

- What bounds the wait, and what happens to rows still queued when the bound is reached. They are discarded and counted as today.
- Whether writes are still refused from the moment establish begins to end. The specification says today that none is taken once establish has begun to end.
- What the wait does when the data writer is failing or stopped.
- What the host application's shutdown sees: the longest the end of establish can take, given that the batch in hand is finished today whatever its length.
- Whether the wait is worth offering at all when collection is a pull. The maintainer's note says that stored rows are then likely dropped with the pod.

Related open questions, by number and gist. Do not resolve them:

- 15: whether the hand-over is a push or a pull, and in what form.
- 14: whether a data writer that has died stays stopped or is restarted.
- 26: whether the end of establish waits for the batch in hand, and what bounds that wait when a store never returns. This is about the default behaviour, so it is not deferred with this ticket.

**Ticket 16's findings:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md` bears on this ticket. G1 to G7 record how values that own a background writer end it, and what their waits bound: `tracing-appender`'s guard waits about 1.1 s and does not join, and `sentry`'s timeout bounds only the wait for an acknowledgement (G1, G2). C1 records that OpenTelemetry's shutdown may block, with a configurable timeout. D1 to D4 record what the end of a Rust guard, a closure scope and a Python `with` can guarantee or report. E14 records `ddtrace`'s `sync_mode` for hosts that may end before a background flush. The file points these at open question 26 and does not weigh them. Read it before starting. Its fits and verdicts are findings, not decisions: the maintainer has said they are not guaranteed to be applied, and they stay open for the tickets they bear on.

**Research file:** `.scratch/client-spec/research/03-a-configurable-wait-at-shutdown.md`, written only if the proposal cites another system. "Citing a comparable" in `CONTEXT.md` says what it records.

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the conformance and breakage lenses, at two key moments: after the maintainer's answers are recorded verbatim in this ticket's hand-back and before the specification changes; and before hand-back. Questions to put to the reviewers:

1. Is every point the ticket says the proposal must state answered in the maintainer's recorded words, and is anything the agent filled in marked "Derived"?
2. Can the end of establish take longer than the bound the proposal states, once the batch in hand is counted?
3. Is there a way for the wait to end (the bound reached, the data writer failing or stopped, an exception) that leaves a queued row uncounted, counted twice, or a write blocked?
4. Does the proposal quietly answer open question 14, 15 or 26, or change what not waiting means as the default?

**External precondition:** Open question 15 (push or pull). The maintainer asked for this to be revisited if collection becomes a push. If it is decided as a pull, raise with the maintainer whether the ticket is still wanted before doing anything else.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] Not waiting stays the default, so nothing already proposed changes meaning
- [ ] The wait is bounded, and the proposal says the longest the end of establish can take, counting the batch the data writer has in hand
- [ ] Every row still queued when the wait ends is discarded and counted exactly once, and no write blocks or fails
- [ ] The proposal says what the wait does when the data writer is failing or stopped
- [ ] The local databases are left consistent however the wait ends
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] Any comparable the proposal cites has its stated why and its fit in the research file, as "Citing a comparable" in `CONTEXT.md` requires; a comparable without both informs the proposal and does not justify it
- [ ] The maintainer's answers are recorded verbatim in the hand-back before the first review; the adversarial review ran at each key moment as `REVIEW.md` says; and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No code is added
