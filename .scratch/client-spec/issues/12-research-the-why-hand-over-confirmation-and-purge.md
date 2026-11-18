# 12: Research the why: hand-over, confirmation and purge

**What to build:** The maintainer can see why the systems behind the specification's hand-over rules behave as they do, and whether those reasons hold for this client. During the elicitation these systems were surveyed for what they do. Why they do it was mostly not captured, and no link was kept. This ticket checks the what again, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

What the specification proposes today, and what it was said to rest on:

- **A run id and positions.** Each run has a UUIDv7 run id, and each accepted row gets a position from a counter that only increases within the run. The survey reported a per-producer sequence number (Kafka) as the only documented way to recognise a duplicate, and `CONTEXT.md` says the run id and position follow it.
- **Purge only after confirmation.** The collector states the highest position it has safely received. A row at or below it may be purged later, off the hot path, and no row is purged before a collection confirms it. The survey reported that durable local buffers delete only after the downstream side confirms.
- **A re-send keeps its position.** A row may be handed over more than once and carries the same position every time, so a repeat is recognisable.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- Filebeat states "at least once" and deletes only after the downstream side confirms.
- The OTel Collector's persistent queue deletes in the same step as the acknowledgement.
- Vector deletes after confirmation when acknowledgements are on.
- In-memory SDK buffers are at-most-once: OTel batch processors drop a failed export.
- Pull sources keep their data: Prometheus purges nothing, and Kafka retains by time or size.
- A per-producer sequence number (Kafka) is the only documented way to recognise a duplicate.
- Nobody documents an asynchronous purge except in the Kafka style, where deletion is decoupled from reading.
- Marked "Unverified" at the time: Fluent Bit's and Vector's exact delete trigger.

The maintainer's notes from the elicitation, verbatim. Asked what must be true before the client may purge rows from a local database:

> Lets look at other systems to see what is most common. We should also reflect on what makes sense in our domain, what are the desired semantics. Also runtime perf considerations. As well as consider if the purge can happen async.

After the survey came back:

> You say that a duplicated time series row is not safe to resend. Well, lets assign each timeseries row a unique id that can key it. Lets use UUIDv7, unless you think there is a better option. Maybe we could key it by a UUIDv7 that uniquely id's the process and then each even pulls from a monotonic counter, (is this like the kafka sequence number?). Take this into consideration and then ask again. Do consider what might be the most simple MVP worthy option that is still correct.

On purging a keyed value:

> Locally it can be purged anytime after a push/pull has happened after the last seen (i.e. if the data has already been collected and we don't have a newer version lets stop holding it so that we can have less data locally and less data to transmit).

What the research must find out, beyond the fields every comparable gets:

- **Kafka's sequence numbers.** Why its authors chose a producer identity with a sequence number: which failure it answers, what the receiving side has to remember and for how long, and what happens when a producer restarts. Then answer the maintainer's question plainly: is a run id with a position like the Kafka sequence number, and where does it differ?
- **UUIDv7 for the run id.** The maintainer chose it. Record what the specification that defines UUID version 7 says it is for and what it warns against, and whether that fits an identifier for one run.
- **Delete only after confirmation.** Why each durable buffer waits for a confirmation, and what that costs when the downstream side is away: growth on disk, back-pressure, duplicates.
- **Pull sources.** Why a pull source keeps its data. Check first whether a Prometheus client holds a buffer of rows waiting for collection at all, or only current values, and say what that does to it as a comparable for a purge rule. For Kafka, why retention is decoupled from reading, and what a reader that falls behind the retention loses.
- **Asynchronous purge.** Whether any system documents purging off the path that confirms, and why.
- **A comparable that chose otherwise**, with its why: for example a system that deletes on send, or one that recognises a repeat some other way. If the search finds another documented way to recognise a duplicate, the "only documented way" claim is wrong: report it as wrong.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related open questions, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- 7: which collector confirms positions when more than one reads an instance.
- 8: what bounds the local databases when no collection happens, and what is lost at the bound.
- 15: whether the hand-over is a push or a pull, and in what form.
- 25: whether a hand-over also carries the stored position, so a collector can tell rows still waiting from rows lost.

**Research file:** `.scratch/client-spec/research/12-hand-over-confirmation-and-purge.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does each source say what the file claims about when the system deletes buffered data and how it recognises a repeat? Does "the only documented way" survive a search for another?
2. Is each why its authors' own words, quoted and linked, and is an absence reported as "No stated rationale found" with where was looked?
3. Does each fit argument face the differences: a run is one establish in a process that may be short-lived, a collector may pull, and nothing is decided about what a collector remembers?
4. Does the file recommend or imply an answer to open question 7, 8, 15 or 25?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] The file answers the maintainer's question whether a run id with a position is like the Kafka sequence number, and says where the two differ
- [ ] For each of the three stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [ ] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [ ] The file says what the evidence bears on open questions 7, 8, 15 and 25 and recommends an answer to none; all four are still open in the specification
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
