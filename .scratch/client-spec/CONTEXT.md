# Client specification: shared context for the tickets

Read this before picking up a ticket in the issues folder beside it. It holds what the elicitation of the client specification produced that the specification itself does not carry: the maintainer's standing guidance, their leanings, the evidence gathered, worked examples, and what was deliberately left without a proposal ticket. It also holds two things the tickets share: the rule for citing another system, and the list of research files the tickets write.

Nothing here is a decision. The specification is a proposal, its open questions are open, and a leaning is not an answer. The elicitation ran from 2026-11-14 to 2026-11-18 (UTC).

## How to work a ticket

- Every ticket but one delivers a proposal or findings. Ticket 09 retires a piece of repository tooling. None adds product code, and none closes an open question: the maintainer does that.
- Tickets 12 to 17 research why the systems the specification already leans on behave as they do. They report, and recommend no answer to an open question.
- Read the handbook page on working with the specifications first. It says what an unmarked statement, a "Derived" statement and an `open question` each mean, and which recipes gate the specification.
- A ticket names open questions by number and gist. Numbers shift when a question is removed, so trust the gist.
- Tickets 03 to 08 and 10 are deferred until after the MVP, and each names what must be decided first. Tickets 01, 02 and 12 to 17 can start once web research is authorised. Tickets 09 and 11 wait on the maintainer.
- Before a ticket leans on another system, read "Citing a comparable" below. What a ticket finds about other systems goes in its research file, listed under "Research files".
- Each ticket names its key moments for an adversarial review. The procedure is `REVIEW.md`, beside this file.
- Append a "Hand-back" section to the ticket when its work is done. Where the ticket has a research file, the hand-back summarises it and points to it.
- Of the files in this folder, a ticket writes to itself and to its own research file, and edits no other file that already exists here: not this file, not `REVIEW.md`, not another ticket or its research file. Tickets worked in parallel worktrees then never change the same file.

## Standing guidance from the maintainer

Given during the elicitation, and meant to steer every later choice:

- Prefer coordination-free, or at least low-coordination, solutions. In the maintainer's words: "as much as possible we should strive for coordination free solutions or at least low coordination."
- Keep the MVP as simple as possible while sufficient and correct, without closing off later options. On forking: "we want make sure we do not design the api in a way that will overly limit our options in the future".
- The client never harms the host application: a queue is bounded and never blocks the worker.
- Where practice exists, follow it rather than invent. On logging to the host's logs: "we should generally follow best practice and do what most other frameworks and libraries do. We shouldn't be novel here".
- When a choice is open, look at what comparable systems do first, then weigh it against what this client wants: "it's good to factor in what others have done before."
- One behaviour for Rust and Python. The maintainer asked whether the confluence, establish and client-handle shape is idiomatic Rust. The agent answered that it is: the facade pattern of the logging and metrics crates, with a `with` block mapping to a guard value or a closure scope. That answer came from the agent's own knowledge and no survey was run. Ticket 16 checks it.

## Citing a comparable

A comparable is any other system, library, framework or platform whose behaviour is offered as a reason for this client's. The maintainer asked for the reason behind a comparable's behaviour to be captured before anything leans on it: "before we try to justify a decision within our design based off of what some other thing did, let's make sure that we capture the why behind. Why the other thing is doing it the way that they are."

The rule: a comparable justifies a proposal only with a reason its own authors stated, and an argument that the reason fits this client. Without both it may inform a proposal, and the text that cites it says "informs", not "because".

For each comparable, a research file records:

- **What it does**, checked now from a primary source: official documentation, a specification, or source code at a named version. Give the link and the date it was read. The surveys under "Evidence gathered during the elicitation" kept no links, so what they say is checked again, not assumed.
- **The stated why**, in its authors' own words: a design document, a proposal such as a Kafka or OpenTelemetry enhancement proposal, a specification's rationale, an issue or pull request thread, a commit message, a maintainer's post or talk. Quote the passage and link it.
- **An inferred why**, where the researcher worked a reason out and no author stated it. Label it "Inferred". It may inform a proposal and never justifies one.
- **"No stated rationale found"**, where that is the result, with where was looked. It is a valid finding, not a failure to report.
- **The constraints behind the choice**: the system's deployment model, the guarantees it promises, its failure model, and the history that led to it.
- **Costs and dissent**: known regrets, later reversals, and at least one comparable that chose otherwise, with its why.
- **Fit**: which of those constraints hold for this client and which do not. A leaning recorded under "Leanings, not decisions" (a pull, DuckDB, ephemeral pods) is cited as a leaning, not as a fact.

Anything no primary source confirmed is marked "Unverified". A claim that turns out to be wrong is reported as wrong, with the source that shows it.

## Research files

One file per ticket that may cite another system, under `research/` beside this file. A file is created by the agent that works its ticket and does not exist before then. Tickets 09 and 11 cite no other system and have none. A proposal ticket writes its file only if the proposal cites a comparable.

| Ticket | Research file |
| --- | --- |
| 01 | `research/01-who-stamps-a-rows-time.md` |
| 02 | `research/02-a-tenant-named-for-a-tenant-free-table.md` |
| 03 | `research/03-a-configurable-wait-at-shutdown.md` |
| 04 | `research/04-evict-oldest-as-a-queue-policy.md` |
| 05 | `research/05-one-shared-queue-bound-with-guaranteed-per-table-capacity.md` |
| 06 | `research/06-transactional-client-blocks.md` |
| 07 | `research/07-diagnostics-tables.md` |
| 08 | `research/08-fork-and-multi-process-support.md` |
| 10 | `research/10-snapshot-capture.md` |
| 12 | `research/12-hand-over-confirmation-and-purge.md` |
| 13 | `research/13-store-failure-and-data-writer-death.md` |
| 14 | `research/14-a-library-logging-its-own-failures.md` |
| 15 | `research/15-table-definitions-over-time.md` |
| 16 | `research/16-client-shape-and-failure-posture.md` |
| 17 | `research/17-platform-facts.md` |

A research file opens with the ticket it belongs to, the dates the sources were read and who authorised the web research. It then gives one section per comparable with the fields above, a section for the comparables that chose otherwise, and last what the findings bear on in the specification. That last section reports. It decides nothing.

## Leanings, not decisions

- **Host.** The most common host is an ephemeral cloud environment such as a Kubernetes worker pod. Google's GKE was named as an example.
- **Collection.** It leans towards a pull. Open question 15 is still open.
- **Storage engine.** DuckDB was named once as a possibility: "There can be only one writer process, Especially if we go with DuckDB." The local databases' on-disk format is undecided and is not yet an entry on any register.
- **What is transmitted.** "TBD on if the collector actually receives the files as they are represented on the disk or if there's some intermediary format. Transmission and local storage are different concerns. It may or may not end up being the same, but we'd like to keep our options open, probably."
- **Namespaces.** "Currently, name only. Leave an open question to explore further along the proposed dimension as well as others." The proposed dimension was atomic publishing per namespace, which happens downstream.
- **A keyed value's time.** Record a "last_seen" timestamp instead of a lifetime; the name "can be called somethings else, maybe something more standard". Time-to-live belongs to the final data store. "Tombstones, in practice are too complex to get correct."

## Where a choice was delegated

The maintainer did not pick the failure posture. Asked which calls may fail loudly, they answered: "Whatever option is most idiomatic while also within those boundaries, what's considered idiomatic, normal, and acceptable, whatever will allow for the most, the best developer experience and the best operator experience." The posture in the specification (declaring a table and establish may fail loudly; opening a client handle and every write never fail and never block) was chosen by the agent as the usual posture of observability libraries, and the maintainer approved the plan that stated it. No survey was run to show that it is usual. Ticket 16 researches it.

## Deliberately without a proposal ticket

No ticket proposes or recommends an answer to these. Where one of tickets 12 to 17 is named, it researches the why behind the evidence that bears on the question, and leaves the question as open as it found it.

- **A bounded retry before a failed batch is dropped.** It is open question 12. The evidence under "Failed stores" below bears on it, and ticket 13 researches that evidence.
- **A declared table version or definition hash, and stable column ids.** It is open question 13. The evidence under "Changed definitions" bears on it, and ticket 15 researches that evidence.
- **Whether a dead data writer is restarted.** It is open question 14. The evidence under "Background worker death" bears on it, and ticket 13 researches that evidence. The maintainer asked for that survey and has not chosen.
- **What bounds the local databases when no collection happens.** It is open question 8, left undecided with no note. Tickets 12 and 17 research evidence that bears on it: what pull sources retain, and what a full disk does to a pod.
- **Building the MVP.** The specification authorises no code, and the repository forbids choosing a design without a decision record.

## Evidence gathered during the elicitation

Surveys of official documentation and source code, run from 2026-11-15 to 2026-11-17. "Unverified" marks what no primary source confirmed. The sources were not recorded link by link, so check a finding again before building on it.

This section records what each system does. It mostly does not record why, so by the rule under "Citing a comparable" nothing here justifies a proposal yet. Each survey has a ticket that checks the what again and captures the why. No ticket edits this section: the findings go in the ticket's research file.

| Survey below | Ticket | Research file |
| --- | --- | --- |
| OTel Arrow posts | 17 | `research/17-platform-facts.md` |
| When buffered data may be deleted | 12 | `research/12-hand-over-confirmation-and-purge.md` |
| Failed stores | 13 | `research/13-store-failure-and-data-writer-death.md` |
| Library self-logging | 14 | `research/14-a-library-logging-its-own-failures.md` |
| Reserving disk space | 17 | `research/17-platform-facts.md` |
| Changed definitions | 15 | `research/15-table-definitions-over-time.md` |
| Background worker death | 13 | `research/13-store-failure-and-data-writer-death.md` |
| Late declaration | 15 | `research/15-table-definitions-over-time.md` |

Two things the specification leans on had no survey at all and so have no entry below: the shape of the client (a confluence, establish and a client handle) and its failure posture. Ticket 16 researches both. The one-writer rule of DuckDB, named under "Leanings, not decisions", was never checked either; ticket 17 does that.

- **OTel Arrow posts (2024, 2025, 2026).** Arrow there is a wire and in-pipeline format. None covers on-disk storage, durability, shutdown or schema evolution. Useful signals only: bounded channels and memory, overload made visible, larger batches compress better. They do not settle the local database format.
- **When buffered data may be deleted.**
  - Durable local buffers delete only after the downstream side confirms: Filebeat states "at least once"; the OTel Collector's persistent queue deletes in the same step as the acknowledgement; Vector does with acknowledgements on.
  - In-memory SDK buffers are at-most-once: OTel batch processors drop a failed export.
  - Pull sources keep their data: Prometheus purges nothing; Kafka retains by time or size.
  - The only documented way to recognise a duplicate is a per-producer sequence number (Kafka). The run id and position in the specification follow it.
  - Nobody documents an asynchronous purge except in the Kafka style, where deletion is decoupled from reading.
  - Unverified: Fluent Bit's and Vector's exact delete trigger.
- **Failed stores.** In-process libraries drop and carry on: OTel SDK batch processors, and Python logging handlers (the second from the agent's own knowledge). Pipeline agents retry within limits, then drop: Fluent Bit once by default; the OTel Collector while its queue fills; Prometheus remote-write for up to two hours.
- **Library self-logging.** The common practice is the standard logging facade, a library-named logger, no handlers installed, WARNING for dropped data, a stable name per kind of event, the first occurrence logged at once, then throttled.
  - ddtrace: one record per call site per 60 s, with "[N skipped]".
  - OTel Java: 5 per minute, then 1.
  - OTel Python: identical repeats suppressed within 20 s.
  - Linux kernel: 10 per 5 s, then "N callbacks suppressed".
  - OTel Rust: onset once, total at shutdown. The maintainer chose this rule.
  - Separate periodic summary logs are uncommon.
- **Reserving disk space.** Possible, with conditions.
  - Linux `fallocate` guarantees later writes into the range "will not fail because of lack of disk space".
  - A file created in the container or on an `emptyDir` is overwritten in place on the node's disk.
  - It does not hold on copy-on-write filesystems: ZFS, btrfs, reflinked XFS, APFS.
  - It never prevents the kubelet evicting a pod over its ephemeral-storage limit. A full disk on Kubernetes usually shows up as an eviction, not a failed write, so reserved space helps when a neighbour fills the node and not when the pod itself is over its limit.
  - Unverified: that GKE node disks are ext4; network and FUSE volumes.
- **Changed definitions.**
  - OpenTelemetry and Prometheus check nothing across processes and keep conflicting versions side by side downstream. The maintainer chose this for the MVP.
  - Snowplow and OTel's schema URL add a declared version validated downstream, with bad data quarantined.
  - Only Confluent Schema Registry blocks a producer at write time, and it needs an always-available service.
  - The cheapest upgrade: a declared version or definition hash, and column ids that are never reused.
- **Background worker death** (source of seven libraries).
  - None restarts a worker a limited number of times.
  - The usual pattern catches failures around handling one batch, logs, drops the batch and keeps looping. Anything escaping that guard kills the worker for the life of the process: OTel Python, Java and Rust, tracing-appender, CPython's QueueListener, ddtrace.
  - Only sentry-python restarts a dead worker: lazily, on the next submit, with no limit.
  - The Rust libraries read do not contain panics.
- **Late declaration** (the agent's own knowledge, not re-checked). Declaring at any time is normal for telemetry libraries: Prometheus clients, OpenTelemetry instruments. Frameworks that own a schema fix definitions at start-up.

## Worked hand-over examples

The maintainer confirmed the hand-over's contents field by field and asked for examples. These three were read back to them.

A keyed value replaced before collection:

```text
run 0192f3a1-7c2e-7b10-9a41-5d2f8e6c0b17, last_position 5

ops.request_log   time series, tenant-scoped   (path text, status integer, ms float?)
ops.job_state     keyed state, tenant-scoped   key (job)   (job integer, status text)

position  table            client_time  tenant          values
1         ops.request_log  10:00:00.10  acme            /a, 200, 12.5
2         ops.request_log  10:00:00.31  <unattributed>  /b, 500, (absent)
5         ops.job_state    10:00:01.02  acme            7, done

Positions 3 and 4 were earlier values for job 7 and are not sent: 5 replaced them.
The collector answers "have up to 5"; rows 1, 2 and 5 may then be purged.
```

A gap from a failed store, and a tenant-free table:

```text
run 0192f3a1-7c2e-7b10-9a41-5d2f8e6c0b17, last_position 6

ops.build_info    time series, tenant-free     (version text, commit text?)
ops.request_log   time series, tenant-scoped   (path text, status integer, ms float?)

position  table            client_time  tenant   values
1         ops.build_info   09:59:58.00  (none)   1.4.2, (absent)
2         ops.request_log  10:00:00.10  acme     /a, 200, 12.5
5         ops.request_log  10:00:00.52  acme     /c, 200, 3.1
6         ops.request_log  10:00:00.60  globex   /d, 404, 1.0

Positions 3 and 4 were in a batch whose store failed. They are lost, counted
under lost.store_failed for ops.request_log, and never sent.
```

The stored position holding rows back, and a re-send:

```text
run 0192f3a1-7c2e-7b10-9a41-5d2f8e6c0b17, last_position 9

Rows 1 to 6 are stored. Row 7 is still queued. Rows 8 and 9 are stored.
This hand-over carries rows 1 to 6 only: the stored position is 6, because 7 is waiting.
The collector answers "have up to 4". The next hand-over re-sends 5 and 6 with the
same positions. Once 7 is stored or lost it adds 8 and 9, and 7 as well if it
was stored. A lost row is counted and never sent.
```

The third example is where open question 25 comes from. The collector sees `last_position` 9 and rows up to 6, and cannot tell rows still waiting from rows lost, because the confirmed hand-over carries no stored position.

## Three scenarios traced through the specification

Rule names are the specification's at the time of writing.

1. **Tenant A writes two rows, a collection confirms them, they are purged.**
   - `OpenClientHandle` with tenant A, then `AcceptRow` twice: positions 1 and 2, attributed to A, `accepted` 2.
   - `TakeBatch`, then `StoreBatch` and `StoreRow` twice: `stored` 2, stored position 2.
   - The hand-over offers both rows. `ConfirmPosition` with 2, then `PurgeRow` twice: `purged` 2.
2. **A burst fills one queue, another table is unaffected, one store fails.** Capacity is 3.
   - Three writes to table one are accepted (positions 1 to 3). Two more hit `RefuseRowWhenQueueFull`: `rejected.queue_full` 2, one onset log record.
   - A write to table two is accepted (position 4), because it has its own queue.
   - `TakeBatch` on rows 1 to 3, then `FailBatch`: the data writer is `failing`, `lost.store_failed` 3, one onset log record.
   - `TakeBatch` on row 4, then `StoreBatchAndRecover`: the data writer is `running`, table two `stored` 1.
   - The diagnostics snapshot shows five losses, each in one counter: 2 and 3.
3. **No establish, and a fork.**
   - With no establish, each write hits `DiscardWriteWithoutRun`: `discarded.not_established` goes up, no row exists, no tenant is attributed.
   - When an established parent forks, `ForkCopiesConfluence` gives the child its own copy with the declarations and open handles, and no run.
   - The child's writes are counted on its own copy. Its `HostEstablishesProduction` fails the `fork_child` guard: loud, no run.

## What was not verified when the specification landed

- The checker is lenient, so the specification's meaning was reviewed by eye and in a second review pass, not proved by the gate.
- The comparison against the alliumpy checker was not independent: it is the same version, 3.6.1, as the pinned binary, and agreed with it.
- The checker's quirks at 3.6.1 are recorded on the handbook page on working with the specifications.
