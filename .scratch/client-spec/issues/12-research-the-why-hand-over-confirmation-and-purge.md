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

- [x] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] The file answers the maintainer's question whether a run id with a position is like the Kafka sequence number, and says where the two differ
- [x] For each of the three stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [x] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [x] The file says what the evidence bears on open questions 7, 8, 15 and 25 and recommends an answer to none; all four are still open in the specification
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/12-hand-over-confirmation-and-purge.md`, beside the issues folder. This section summarises it. The specification is not edited, `CONTEXT.md` is not edited, and open questions 7, 8, 15 and 25 are still open in `docs/specs/transect-client.allium`.

### Findings

The research file records fourteen comparables, C1 to C14, and eight that chose otherwise, O1 to O8, with a list of candidates not examined. For each one it records:

- what it does, checked from documentation, a specification or source code at a named tag or commit;
- the stated why, quoted and linked, or "No stated rationale found" with where was looked;
- any inferred why, labelled;
- the constraints, and the costs and dissent.

Fit is recorded in its own section. Every quotation was checked as a substring of source text the researcher fetched again: 478 at the last check, 397 exactly and 81 once whitespace is collapsed.

**The elicitation's eight claims, checked again:**

1. **Filebeat: partly wrong.** Its "at least once" is about the registry, a read position on a file Filebeat does not own. By default Filebeat deletes no source data.
2. **The OpenTelemetry Collector's persistent queue: partly wrong.** The delete is in the same storage step, but it follows any finish, a failure or an exhausted retry included.
3. **Vector: partly wrong.** A data file goes once every record read from it is finalized, a drop included, whether or not acknowledgements are on.
4. **The OpenTelemetry SDK: partly wrong.** The batch processor drops a failed batch, but the exporter retries, and OTLP accepts the duplicates that follow.
5. **Pull sources: true only narrowly for Prometheus,** whose client holds no rows at all. **Confirmed for Kafka,** with exceptions driven by consumption.
6. **"The only documented way to recognise a duplicate": wrong.** Ids the sender assigns (NATS, SQS FIFO, Azure Service Bus, Elasticsearch), content (Elasticsearch time series, SQS, Prometheus) and a recorded log position (PostgreSQL) are all documented.
7. **"Nobody documents an asynchronous purge": wrong.** Vector, the libbeat disk queue, Filebeat, Pulsar, PostgreSQL, Pub/Sub and Kafka Streams all document one.
8. **Fluent Bit's and Vector's delete triggers: now verified from source.**

**Across the durable buffers,** every one also deletes without a confirmation: on giving up, on any finalization, or at a size or time bound. What counts as a confirmation varies too: an intermediate queue's write, or a drop counted as acknowledged.

### Is a run id with a position like Kafka's sequence number?

**Partly.** Both name the producing instance for one session and number what it produces, so that a re-send after a lost acknowledgement can be recognised. They differ in five ways:

- **Who assigns the identity.** Kafka's broker assigns the producer id. The client mints the run id itself, with no coordination.
- **Scope.** Kafka's sequence is per partition. A position is per run, across all its tables.
- **Who checks it, and how.** Kafka's partition leader checks continuity while it holds the producer's state. Nothing is decided for a collector, and positions have gaps by design.
- **What the receiving side remembers.** Kafka's broker keeps up to five batches, for a day by default. Nothing is decided here: a collector's internals are outside the specification.
- **What the number is for.** Kafka's sequence is never a read position. A position is also what the collector confirms, which makes it closer to Kafka's consumer offset or PostgreSQL's confirmed position.

As an identity for a repeat, a run id with a position is closer to an id the sender assigns to each message than to Kafka's sequence.

### Verdicts

1. **A run id and positions: (ii), a stated why that does not transfer whole.** Kafka answers the same failure, so it informs the position, but its reasons rest on constraints this client does not share.
   - **The run id** rests, as a UUID, on RFC 9562's stated reason that UUIDs need no coordination. Its reasons for version 7 in particular inform the choice.
   - **The position**, as the unit a collector confirms, is informed by Kafka's consumer offset. Kafka ties that offset to one consumer per partition, and which collector confirms here is open question 7.
   - **Proposed wording** replaces the survey's sentence in `CONTEXT.md`.
2. **Purge only after confirmation: (i), a stated why that fits, within a run.** Filebeat's and PostgreSQL's stated reasons for waiting fit. What happens past the end of a run is open question 6, and no comparable read says anything about it that transfers.
3. **A re-send keeps its position: (i), a stated why that fits, within a run.** PostgreSQL's and Azure Service Bus's stated reasons fit, the second for a lost acknowledgement, which can happen within a run. Whether a collector recognises a repeat depends on what it remembers, which is outside the specification.

The research file also gives replacement wording for the survey's other bullets in `CONTEXT.md`. It is for the maintainer and is not applied.

### What the findings bear on

The research file reports the evidence for each question and recommends no answer:

- **Open question 7:** how comparables with several readers keep positions or acknowledgements and when they delete.
- **Open question 8:** where each durable comparable's bound loses data, and the stated reasons for a bound.
- **Open question 15:** which comparables pull and which push, PostgreSQL's stream being in neither group.
- **Open question 25:** the gap ambiguity, which arises only above the highest position offered, and the marks Kafka's fetch response carries beside the records.

### Adversarial review

Every review ran on Codex (codex-cli 0.172.0) with `gpt-6.2-sol`, at the user's request in place of `gpt-6-astra`, which `REVIEW.md` prefers. Each session header recorded the model, a read-only sandbox and live web search under this ticket's authorisation. The reasoning effort was `medium`, the user's Codex configuration, left as it was. Before the first review, a preflight confirmed that Codex ran `gpt-6.2-sol` and could open a URL.

Every finding was triaged by fresh Claude Code subagents on Claude Opus 5.5 (`claude-opus-5-5`), one per lens and round, neither the author nor a reviewer. The two lenses' triaged fixes overlapped in three rounds (1, 2; 2, 1; 2, 2). There a further Claude Opus 5.5 subagent merged and applied them, and the author read each merged diff and re-ran the quotation checker before committing. Between the key moments, an advisor model the author consulted in this session checked the fit and verdicts against the specification, and its points were applied in commit `741daff`, before the second key moment's review. That commit scoped verdicts 2 and 3 to a run, marked the Derived statements in the constraints, and changed "follows" to "informs" for the consumer offset; the second key moment reviewed the result. The review and triage files are under `ai_tmp/client-spec-review/12/`, which is not committed.

The `tdd` and `code-review` skills do not fit a ticket that delivers findings and no code. The Codex adversarial review takes the place of `code-review`.

The first column gives the key moment, the round and the lens. Each round ran both lenses. Key moment 1 reviewed `1b17237` and `1d38673`; key moment 2 reviewed `741daff` and `4393353`.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | The Collector's combined transaction has a two-call fallback | Valid, narrower | Row 2, C4 and Summary name the fallback |
| 1, 1, sources | 2 | With the disk queue, a source file's delete follows the queue write | Valid, narrower | The chain traced in code at `v9.5.7`; row 1 corrected |
| 1, 1, sources | 3 | Kafka's live and recovered producer state differ | Valid, narrower | C1: a snapshot restores one batch; a producer with a transaction open does not expire; two code comments reported, not reconciled |
| 1, 1, sources | 4 | A `transactional.id` does not de-duplicate an application's re-send | Valid | C1's constraints quote the producer documentation |
| 1, 1, sources | 5 | Pulsar keeps two high marks; its 10,000 limit is the snapshot's; trimming is separate | Valid | C12, rows 6 and 7, Summary |
| 1, 1, sources | 6 | NATS's stated deferral follows a consumer's deletion | Valid | C13, row 7, Summary |
| 1, 1, sources | 7 | Fluent Bit also releases on a failed retry schedule; S3 returns `FLB_OK` before uploading | Valid | C6, row 8, Summary |
| 1, 1, sources | 8 | Vector's one second is a scan interval | Valid, narrower | Rows 7 and 8, Summary |
| 1, 1, sources | 9 | opentelemetry-python evicts the oldest item | Valid | C7 |
| 1, 1, sources | 10 | Prometheus's maintainer states what retention and WAL truncation are for | Valid, narrower | C9 quotes both posts; none for the 15-day default or for truncating regardless of remote write |
| 1, 1, sources | 11 | Kafka's retention is a maximum | Valid | C10's constraints |
| 1, 1, sources | 12 | A Pushgateway push replaces its group | Valid | C8 |
| 1, 1, sources | 13 | Beats sends `index` when `op_type` is `index` | Valid | O3 |
| 1, 1, sources | 14 | Pub/Sub documents publish-side duplicates and why exactly-once is pull-only | Valid | O7, candidates |
| 1, 1, sources | 15 | NATS discard-new-per-subject and Azure Service Bus were missing | Valid, narrower | C13 addition; O8 added; row 6 |
| 1, 1, sources | 16 | ActiveMQ KahaDB cleans up periodically | Valid, narrower | Candidates not examined |
| 1, 1, sources | S1 | No reason found for deleting on failure | Valid, narrower | C4 cites OTLP's rule to drop, as a rule, not a reason |
| 1, 1, sources | S2 | No reason found for the NATS, SQS and Pulsar defaults | Invalid | The file already says so, with where was looked |
| 1, 1, sources | S3 | No reason found for the TSDS identity | Valid, narrower | O4's list of where was looked extended |
| 1, 1, reasoning | 1 | Claim 2 confirms a different event from the one claimed | Valid, narrower | Row 2 to "Partly wrong", merged with sources 1 |
| 1, 1, reasoning | 2 | The Filebeat rows assert the output's acknowledgement | Valid | As sources 2 |
| 1, 1, reasoning | 3 | As sources 6 | Valid | As sources 6 |
| 1, 1, reasoning | 4 | `DeleteRecords` takes an offset its caller supplies | Valid | C10, rows 5 and 7, Summary |
| 1, 1, reasoning | 5 | As sources 11 | Valid | As sources 11 |
| 1, 1, reasoning | 6 | The Kafka offset summary puts the repeat check in the wrong place | Valid, narrower | Summary C11 |
| 1, 1, reasoning | 7 | As sources 9 | Valid | As sources 9 |
| 1, 1, reasoning | 8 | As sources 8 | Valid, narrower | As sources 8 |
| 1, 1, reasoning | 9 | OTLP spans carry a stable identity | Valid, narrower | C7: the protocol defines no way to recognise a repeat; spans carry ids |
| 1, 1, reasoning | 10 | As sources 14 | Valid | As sources 14 |
| 1, 1, reasoning | 11 | SQS's receive and delete were missed | Valid | O5 gains a deletion paragraph |
| 1, 1, reasoning | 12 | Pulsar's Reader interface and TTL were omitted | Valid, narrower | C12, Summary |
| 1, 1, reasoning | 13 | statsd's why is for another hop; syslog has no buffer | Valid, narrower | O1's why scoped to the client's send; O2 labelled; heading renamed |
| 1, 1, reasoning | 14 | As sources 12 | Valid, narrower | As sources 12 |
| 1, 1, reasoning | S1 | The filestream wiring at `v9.5.7` | Valid, confirmed | Folded into 2 |
| 1, 1, reasoning | S2 | The Collector fallback at `v0.166.0` | Valid, confirmed | Folded into 1 |
| 1, 1, reasoning | S3 | Whether Beats always sends `create` | Valid | As sources 13 |
| 1, 1, reasoning | S4 | Sources the reviewer could not open | Invalid | All of them loaded for the triage |
| 1, 2, sources | 1 | The Collector's restart put-back and dequeue can delete before export | Valid | C4, row 2, Summary |
| 1, 2, sources | 2 | Kafka's tests show the append after expiry | Valid, narrower | C1 cites the tests; "Unverified" removed |
| 1, 2, sources | 3 | Fluent Bit's eviction has a backlog step and orders inputs | Valid, narrower | C6, Summary |
| 1, 2, sources | 4 | The Prometheus agent's cut-off is not a retention guarantee | Valid | C9 |
| 1, 2, sources | 5 | Pulsar trims a closed ledger with no further rollover | Valid | C12, row 7, Summary, correcting round 1's wording |
| 1, 2, sources | 6 | JetStream proposes a clustered delete after an acknowledgement | Valid, narrower | C13, row 7, Summary |
| 1, 2, sources | 7 | JetStream rebuilds its id map from stored messages only | Valid | C13's constraints, the consequence Inferred |
| 1, 2, sources | 8 | Vector: every record read from the file | Valid | Row 8, Summary |
| 1, 2, sources | 9 | Fluent Bit's dead-letter copy is best effort | Valid | C6 |
| 1, 2, sources | 10 | Kafka's offset retention has several starting points | Valid | C11, Summary |
| 1, 2, sources | 11 | PR #9090 states why an exhausted retry drops | Valid | C4's stated why and dissent |
| 1, 2, sources | 12 | A Fluent Bit contributor's advice on retry limits | Valid, narrower | Added to where was looked; "No stated rationale found" stands |
| 1, 2, sources | 13 | A PromCon abstract states a benefit of cumulative counters | Valid, narrower | C8, as a later benefit |
| 1, 2, sources | 14 | PR #82633 gives the TSDS id's purpose; older docs describe overwriting | Valid | O4, reported unreconciled |
| 1, 2, sources | 15 | Cloud Tasks recognises a repeat by task name | Valid, minimal | Candidates not examined |
| 1, 2, sources | 16 | RabbitMQ quorum queues compact in the background | Valid, minimal | Candidates not examined |
| 1, 2, sources | S1, S2 | No reason found for several defaults and rules | Valid, no change | They agree with the file |
| 1, 2, reasoning | 1 | As sources 6 | Valid, narrower | As sources 6 |
| 1, 2, reasoning | 2 | `AckTerm` makes a message removable | Valid | C13, Summary, reported beside the docs, not reconciled |
| 1, 2, reasoning | 3 | Kafka states why a segment's delete is delayed | Valid | C10 quotes `LocalLog.java`; none for 60 s |
| 1, 2, reasoning | 4 | As sources 5 | Valid, narrower | As sources 5 |
| 1, 2, reasoning | 5 | Pulsar's rule depends on durable subscriptions and their type | Valid, narrower | C12 |
| 1, 2, reasoning | 6 | PostgreSQL writes a slot at once on one path | Valid | C14, reported beside the docs |
| 1, 2, reasoning | 7 | Filebeat's disk queue acknowledges after a sync it does not check | Valid | C3, row 1 |
| 1, 2, reasoning | 8 | The Collector's transaction is local; an OTLP partial success deletes the request | Valid, narrower | C4, row 2, Summary |
| 1, 2, reasoning | 9 | S3 has a second buffer with its own delete and bound | Valid | C6, row 8, Summary |
| 1, 2, reasoning | 10 | A core contributor states why counters are cumulative | Valid | C8, Summary; the Inferred line removed |
| 1, 2, reasoning | 11 | As sources 4 | Valid, narrower | As sources 4 |
| 1, 2, reasoning | 12 | Kafka compaction, share groups and manual-assignment expiry | Valid, narrower | Row 5, C11 |
| 1, 2, reasoning | 13 | Elasticsearch overwrites only on a target that takes `index` | Valid | O3, O4 |
| 1, 2, reasoning | 14 | O7 misstates a service-made repeat; Pub/Sub also purges asynchronously | Valid, narrower: the first half invalid, since the page says the service's repeats keep "the same message IDs" | O7, row 7 gain the asynchronous delete |
| 1, 2, reasoning | 15 | The Java SDK disk buffer, and RabbitMQ's automatic acknowledgement | Valid, narrower | C7; candidates |
| 1, 2, reasoning | 16 | SQS, Azure and MQTT scope details | Valid, narrower | O5, O6, O8 |
| 1, 2, reasoning | S | The quotation tally | Not a finding | Recounted with the checker |
| 2, 1, sources | 1 | Kafka's answer made an out-of-sequence gap unconditionally fatal | Valid, narrower | Fit C1 and the comparison table: a gap is rejected where the leader holds state; the idempotent producer retries it |
| 2, 1, sources | 2 | Vector never deletes the file the writer is still writing | Valid | C5, rows 3 and 8, Summary |
| 2, 1, sources | 3 | S3's own buffer can go on an exhausted retry | Valid, narrower | C6, row 8, Summary, fit C6; "No stated rationale found" stands for the engine's rule |
| 2, 1, sources | 4 | The agent's four hours read as a minimum age | Valid, narrower | C9: the bound is for unsent data |
| 2, 1, sources | 5 | Pulsar's deduplication cursor holds back the trim | Valid, narrower | C12, Summary, question 7 |
| 2, 1, sources | 6 | JetStream leaves an out-of-order delete's compaction to a timed sync | Valid | C13, Summary, row 7 |
| 2, 1, sources | 7 | Pub/Sub's topic retention overrides acknowledgements | Valid | O7, row 7, candidates |
| 2, 1, sources | 8 | Elasticsearch 8.19's code refuses all but `create` through a data stream | Valid, narrower | O4 adds the code; a repeated `create` in a TSDS stays unshown and unreconciled |
| 2, 1, sources | 9 | MQTT 3.1.1's reuse rule differs from 5.0's | Valid | O6 |
| 2, 1, sources | 10 | Verdict 2 counted Filebeat without its disk-queue condition and missed Pulsar | Valid, narrower | Verdict 2 names the condition; Pulsar's sentence recorded as what an acknowledgement is for, not a reason |
| 2, 1, sources | 11 | RFC 9562's coordination reason is for UUIDs in general | Valid | C2, fit C2, verdict 1 |
| 2, 1, sources | 12 | OTLP's request id was withdrawn by its author, for another reason | Valid | Fit C7, question 7 |
| 2, 1, sources | 13 | Swift's disk buffer trigger is in its source | Valid | C7 at tag `2.6.0`, fit C7, candidates |
| 2, 1, sources | 14 | A NATS inference became a stated cost in the fit | Valid | Fit C13 |
| 2, 1, sources | 15 | A PostgreSQL quotation crossed a heading without its source line | Valid, narrower | The `Source:` line repeated for readers |
| 2, 1, sources | 16 | The PostgreSQL and Azure fit collapsed retention, replay and failure | Valid | Fit C14, Summary, row 6, verdicts 1 and 3, O8 |
| 2, 1, sources | 17 | The fit invented a common receiver lifetime | Valid | Verdict 3, fit O3 to O8, row 6 |
| 2, 1, sources | 18 | The asynchronous-purge fit assumed a later process or a reader of the files | Valid | Fit C5, fit C10, verdict 2 |
| 2, 1, sources | 19 | Question 7 implied only one reader can confirm | Valid, narrower | Question 7 and verdict 1 attribute the arrangement to Kafka and PostgreSQL; Pulsar's slowest-cursor position added |
| 2, 1, sources | 20 | PostgreSQL's receiver opens a stream rather than pulling | Valid | Question 15 lists it in neither group; C14 quotes the protocol |
| 2, 1, sources | 21 | Kafka's fetch response carries watermarks; question 25's ambiguity is the trailing positions | Valid | C11, fit C11, question 25 |
| 2, 1, sources | S1 | The rollover namespace in O3 | Valid, no change | Already "Inferred, not checked" |
| 2, 1, reasoning | 1 | A stored keyed value can be replaced unconfirmed | Valid, narrower | The constraints name `ReplaceKeyedValue`; fit C11 narrowed; verdict 2 stays (i) |
| 2, 1, reasoning | 2 | Verdict 2 overstated the asynchronous-delete reasons | Valid | As sources 18; Vector's and Fluent Bit's missing reason for waiting marked Unverified |
| 2, 1, reasoning | 3 | Verdict 3 made restart a precondition | Valid, narrower | As sources 16; what a collector remembers attributed to `Collector` being outside the module |
| 2, 1, reasoning | 4 | Verdict 1 gave the RFC and Kafka too much authority | Valid | As sources 11; the position "is informed by" Kafka; verdict 1 stays (ii) |
| 2, 1, reasoning | 5 | The constraints flattened Derived behaviour | Valid, narrower | Sequential establish marked Derived; "production establish" for the fork; that the data writer stops is stated unmarked, so that part is invalid |
| 2, 1, reasoning | 6 | As sources 1 | Valid | As sources 1, with the `TransactionManager.java` quotations |
| 2, 1, reasoning | 7 | The survey wording gave Vector a retry it does not check | Valid | Survey wording and verdict 2 |
| 2, 1, reasoning | 8 | The O3 to O8 fit grouped different identities | Valid, narrower | Fit O3 to O8 names which use an id the sender assigns |
| 2, 1, reasoning | 9 | As sources 19 | Valid | As sources 19; no coordinator sketched, so question 7 stays open |
| 2, 1, reasoning | 10 | As sources 21 | Valid | As sources 21 |
| 2, 1, reasoning | 11 | Kafka's store-and-forward objection was applied as established | Valid | Fit C10 scopes it to its thousands of producers; per pod is a leaning; question 17 named |
| 2, 1, reasoning | S1, S2 | Filebeat and Vector review comments the reviewer could not open | Resolved | Re-opened through the GitHub API: verbatim, correctly attributed |
| 2, 1, reasoning | S3 | Other links that failed to load | Out of scope | No link named; quotations were rechecked by the checker |
| 2, 2, sources | 1 | The Kafka table dropped the transactions-v2 exception | Valid | The table's cell names it, as C1 does |
| 2, 2, sources | 2 | Verdict 2 omitted SQS's stated reason for keeping a received message | Valid | Verdict 2 and fit O3 to O8: it informs, its threshold being processing; verdict 2 stays (i) |
| 2, 2, sources | 3 | Verdict 2 overlooked Vector's latency TODO and libbeat's reason for a separate deleter | Valid | C5 quotes the TODO; fits C3 and C5 and verdict 2 record both as informing |
| 2, 2, sources | 4 | Question 7 put Kafka's share groups under "deletion waits for all" | Valid | Moved out: retention, not their acknowledgements, deletes |
| 2, 2, sources | 5 | C9 treated `MaxWALTime` as the earliest loss of unsent data | Valid, narrower | C9 says the cut-off can trail by less; question 8 keeps the segment condition |
| 2, 2, sources | 6 | Verdict 1 dropped RFC 9562's entropy reason for version 7 | Valid, narrower | C2, fit C2, Summary, verdict 1: it compares with v1 and v6 only, so it informs; verdict 1 stays (ii) |
| 2, 2, sources | 7 | Filebeat's final disk-queue segment goes only at shutdown | Valid | C3, row 1, Summary |
| 2, 2, sources | 8 | PostgreSQL's protocol carries an end-of-WAL field | Valid, narrower | C14 and question 25, with what the walsender at `REL_18_7` puts in it |
| 2, 2, reasoning | 1 | Question 7 treated a shared acknowledgement as one reader's | Valid | Question 7 and C13 add NATS `AckAll`; the one-reader integer scoped to Kafka and PostgreSQL |
| 2, 2, reasoning | 2 | Pulsar's highest-seen check relies on arrival order | Valid, narrower | Fit C12 and the Kafka answer, labelled Inferred |
| 2, 2, reasoning | 3 | Verdict 1 gave Azure and PostgreSQL more weight than they carry | Valid | Both inform the position; C14 quotes a shared LSN |
| 2, 2, reasoning | 4 | As sources 3 | Valid, narrower | As sources 3 |
| 2, 2, reasoning | 5 | Fit C11 confused a position boundary with the time of confirmation | Valid | Fit C11 follows `Run.offered_rows` |
| 2, 2, reasoning | 6 | As sources 1 | Valid | As sources 1 |
| 2, 2, reasoning | 7 | C2 dropped "in conjunction with an embedded counter" | Valid, narrower | C2 and fit C2; same-millisecond order across generators labelled Inferred |
| 2, 2, reasoning | 8 | Question 8 made Fluent Bit's eviction order sound global | Valid | Question 8 uses the summary table's wording |
| 2, 2, reasoning | 9 | Verdict 2's absence for Vector and Fluent Bit had no search record | Valid | The triage searched and found Fluent Bit's CUJ 1 and Vector's RFC; C5, C6 and verdict 2 quote them as informing |
| 2, 2, reasoning | S | Design exports and the Etsy copy the reviewer could not open | Resolved | Re-opened: verbatim |

**Open points.** Every numbered finding and suspicion was triaged, and every valid one applied. What remains:

- **The last round's fixes were not reviewed again.** They are commit `9652d97`, applied after the second key moment's second round, the last `REVIEW.md` allows.
- **The reviewers ran at `medium` reasoning effort,** the user's Codex configuration, where ticket 01's ran at `ultra`.
- **The proposed wording is not applied.** It replaces the survey's bullets in `CONTEXT.md` (under verdict 1 and in "Corrections to the survey"). It is for the maintainer, and this ticket does not edit that file.
- **Still Unverified, or not researched,** as the research file says in each place:
  - what the Azure Event Hubs service remembers;
  - whether comparables other than Kafka and PostgreSQL send their receiver a progress mark apart from the data;
  - Snowflake-style identifiers, and the log shippers listed under "Candidates not examined";
  - several defaults with no stated reason: the NATS, SQS and Pulsar windows, Prometheus's 15 days, and Kafka's 60 seconds.
- **Verdict 1 depends on a premise the maintainer should check.** The run-id half reads several hosts handing over to one collection from the ephemeral-pod leaning. The specification does not state it.

### Gates and files

- **Baseline**, at `90f0abb`, the untouched branch:

  > All checks passed and the worktree is unchanged.

- **Final**: FINAL_GATE
- **Changed files:** this ticket and `research/12-hand-over-confirmation-and-purge.md` only. The specification and `CONTEXT.md` are unchanged, open questions 7, 8, 15 and 25 are still in the specification, and no code was added.
- **`git status --short`** is empty.
