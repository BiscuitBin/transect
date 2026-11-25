# Research: hand-over, confirmation and purge

- **Ticket:** `issues/12-research-the-why-hand-over-confirmation-and-purge.md`. It checks again, from primary sources, the systems the specification's hand-over rules were said to follow, and captures why each behaves as it does.
- **Sources read:** 2026-11-24 (UTC). Every link below was read that day.
- **Web research:** authorised by the maintainer in the session that picked this ticket up, for the researcher and for the reviewers, read-only.
- **Status:** findings, for the maintainer. They report and recommend no answer to open questions 7, 8, 15 or 25, and the specification is not edited.

## How the sources were checked

- Each comparable was read from its official documentation, a specification, or source code at a named tag or commit. GitHub links are pinned to a tag or a commit, except issue and pull request threads, which have no version, and the Fluentd wiki, which is read at its current revision. Kafka KIPs are linked by Confluence page id, Apache JIRA issues by their browse URL, and RFCs by the RFC Editor's plain-text rendition. Two design documents are Google Docs, linked by their text export. The AWS, Google Cloud and OASIS MQTT pages and the Flickr post are unversioned, and were read as the pages served that day; the AWS pages as the Markdown rendition the site serves. Etsy's 2011 post is read from the Wayback Machine's copy of 2012-01-03, because etsy.com refused the request.
- Every blockquote sits under the `Source:` line it was copied from. Each was checked as a substring of raw source text the researcher fetched again: GitHub files from `raw.githubusercontent.com`, GitHub threads and commits through the GitHub API, Confluence pages through the Confluence REST API, JIRA issues through the JIRA REST API, and other pages as HTML with their tags stripped. 253 quotations were checked; 207 match exactly, and 46 match only once whitespace is collapsed: 27 passages of RFC 9562 and RFC 5426, whose plain text indents and wraps lines; nine of the PostgreSQL documentation's SGML, which wraps lines; nine code comments whose indentation differs; and one JIRA issue whose text carries a non-breaking space.
- A quotation inside a sentence was checked against the blockquotes, the ticket and `CONTEXT.md`.
- What no primary source confirmed is marked "Unverified". A reason the researcher worked out, and no author stated, is marked "Inferred".

## The shape being looked for

The specification, `docs/specs/transect-client.allium`, proposes three hand-over behaviours. `CONTEXT.md` says they follow comparables, but the survey behind it kept no links and no why.

| Behaviour | Where the specification states it |
| --- | --- |
| **A run id and positions.** Each run has a UUIDv7 run id, and each accepted row gets a position from a counter that only increases within the run. | `Run.id` (`uuid_v7(now)` at establish), `AcceptRow`, the `PositionsOnlyIncrease` and `NoLowerPositionLater` guarantees |
| **Purge only after confirmation.** The collector states the highest position it has safely received; a row at or below it may be purged later, off the hot path; nothing is purged before a collection confirms it. | `ConfirmPosition`, `PurgeRow`, `Row.is_purgeable`, the `PurgedRowsWereConfirmed` invariant |
| **A re-send keeps its position.** A row may be handed over more than once and carries the same position every time, so a repeat is recognisable. | The `AtLeastOnce` guarantee |

For each comparable the survey asks:

- when it deletes buffered data, and what triggers the delete;
- whether the delete is in the same step as the confirmation or later, off that path;
- how it recognises a repeat, if it does, and what the receiving side remembers and for how long;
- what happens when the downstream side is away: growth on disk, back-pressure, duplicates, loss;
- and the reasons its authors gave for each of those choices.

## The claims rechecked

The elicitation's survey made eight claims, recorded in `CONTEXT.md` with no link. Each was checked again on 2026-11-24. The evidence, quoted and linked, is in the section named.

| # | Claim | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Filebeat states "at least once" and deletes only after the downstream side confirms. | **Partly wrong.** The statement is confirmed, and it is about the registry, a read position on a file Filebeat does not own: by default Filebeat deletes no source data, and the application or logrotate deletes it, which Filebeat names as a loss case. Where Filebeat does delete (disk queue segments; source files with `delete.enabled`), the delete follows the output's acknowledgement, and that acknowledgement includes dropped events. Inferred: with the disk queue on, the input's acknowledgement fires when the event reaches the queue. | C3: [how-filebeat-works.md](https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/how-filebeat-works.md), [filebeat-input-filestream.md](https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/filebeat-input-filestream.md) |
| 2 | The OTel Collector's persistent queue deletes in the same step as the acknowledgement. | **Confirmed, with two qualifications.** The logical delete and the dispatched-list update are one storage transaction. The step follows any finish, not only a success: a permanent error and an exhausted retry budget delete too. Disk space comes back only by compaction, off by default. | C4: [persistent_queue.go](https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go) |
| 3 | Vector deletes after confirmation when acknowledgements are on. | **Partly wrong.** A data file is deleted once every record read from it is finalized, and finalization includes a failure or a drop. It does not depend on `acknowledgements.enabled`: end-to-end acknowledgements stop at the disk buffer. Since `v0.58.0` the physical delete is a background task. | C5: [ledger.rs](https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/ledger.rs), [writer.rs](https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/writer.rs) |
| 4 | In-memory SDK buffers are at-most-once: OTel batch processors drop a failed export. | **Partly wrong.** The processor does drop a failed batch, and drops on a full queue. But the path is not at-most-once: the OTLP exporter must retry transient errors, and OTLP accepts the duplicates that follow as "a deliberate choice". | C7: [trace/sdk.md](https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/specification/trace/sdk.md), [OTLP specification](https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md) |
| 5 | Pull sources keep their data: Prometheus purges nothing, and Kafka retains by time or size. | **Prometheus: true only in a narrow sense.** A client holds no rows waiting for collection, only current values, and a scrape resets nothing; the server deletes by time or size. **Kafka: confirmed**, with exceptions driven by consumption: `DeleteRecords` and the Kafka Streams repartition purge. | C8: [writing_clientlibs.md](https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md); C9: [storage.md](https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/docs/storage.md); C10: [introduction.md](https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/getting-started/introduction.md) |
| 6 | A per-producer sequence number (Kafka) is the only documented way to recognise a duplicate. | **Wrong.** Documented alternatives: an id the sender assigns (NATS `Nats-Msg-Id`, SQS FIFO, Elasticsearch `_id`, MQTT's packet id within a session), content (Elasticsearch time series data streams, SQS content-based deduplication, Prometheus series and timestamp), a position in the sender's log recorded by the receiver (PostgreSQL LSN), and Kafka's own handbook on the consuming side (a primary key, or the offset stored with the output). Pulsar is a per-producer sequence, but keeps only the highest seen and allows holes. | C13: [model_deep_dive.md](https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/using-nats/jetstream/model_deep_dive.md); O5: [API_SendMessage](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html); O3, O4, O6, C9, C14, C11, C12 |
| 7 | Nobody documents an asynchronous purge except in the Kafka style, where deletion is decoupled from reading. | **Wrong.** Purges off the confirming path are documented by Vector (a background task within about a second), the libbeat disk queue (a separate deleter), Filebeat's `delete.enabled` (a grace period), Pulsar (at the next ledger rollover), NATS interest streams (deferred "for performance reasons"), PostgreSQL (at a checkpoint) and Kafka itself, driven by confirmation (`DeleteRecords`, the Streams purge). The Prometheus agent truncates on a timer that consults what was sent. | C5, C3, C12, C13, C14, C10, C9 |
| 8 | Unverified at the time: Fluent Bit's and Vector's exact delete trigger. | **Now verified from source.** Fluent Bit unlinks a chunk file synchronously when its task is released: all outputs done, no retries pending, which covers success, error and an exhausted retry. Vector completes a data file logically when every record in it is finalized, and deletes it physically within about a second. | C6: [flb_task.h](https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/include/fluent-bit/flb_task.h); C5 |

## Summary

| System | When buffered data is deleted | Delete in the same step as the confirmation? | How a repeat is recognised | What the receiving side remembers, and for how long | Stated why found? |
| --- | --- | --- | --- | --- | --- |
| C1 Kafka idempotent producer | n/a (retention, C10) | n/a | PID, epoch and per-partition sequence; a retry matched against the last 5 batches | Partition leader: per PID; 1 day after the last write (`producer.id.expiration.ms`) | Yes (KIP-98, its design document, KIP-360, KIP-854) |
| C2 RFC 9562 UUIDv7 | n/a | n/a | n/a: an identifier, not a delivery mechanism | n/a | Yes, for time order and index locality; none for one id per run |
| C3 Filebeat / libbeat | Source file: never by default; with `delete.enabled`, after acknowledgement and a 30-minute grace period. Disk queue segment: once all its events are acknowledged | No: a separate deleter; a grace timer | Not recognised; the docs push an id to the receiver (O3) | Elasticsearch: the document id, while the document exists | Partly (PR threads) |
| C4 OTel Collector persistent queue | On any finish: success, permanent error, exhausted retries | Logical: yes, one transaction. Physical: only on compaction | Not recognised | Nothing | Partly (issue #2285, design document); none for deleting on failure |
| C5 Vector disk buffer v2 | Once every record in a data file is finalized, whatever its status | No: a background task, within about 1 s | Not recognised | Nothing | Yes (issue #7065, RFCs, code comments) |
| C6 Fluent Bit | When the task is released: success, error or exhausted retry; oldest evicted at `storage.total_limit_size` | Yes, synchronous | Not recognised | Not addressed | Partly (issue #2408); none for deleting on failure |
| C7 OTel SDK batch processor | When the batch is taken for export, whatever the outcome; on a full queue | n/a: nothing is kept | None; an idempotency key was proposed and not merged | Nothing | Yes (performance principles, OTLP specification, PR #219) |
| C8 Prometheus client | Never: holds only current values | n/a | n/a | n/a | Yes, for the pull model; none for cumulative counters |
| C9 Prometheus server | TSDB: by time or size. WAL: at head compaction (server) or on a 2-hour timer (agent) | No | Series and timestamp: identical repeat accepted, different value refused | The newest in-order sample per series | Partly; none for retention or for server WAL truncation |
| C10 Kafka retention | By time or size, or by key; `DeleteRecords` and the Streams purge by consumption | No: a 5-minute task, then a 60 s file delay | n/a | n/a | Yes (design handbook, KIP-107, KIP-811) |
| C11 Kafka consumer offsets | Nothing, in plain Kafka | n/a | On the consuming side: a primary key, or the offset stored with the output | The group coordinator: the committed offset, 7 days after the group empties | Yes (design handbook) |
| C12 Pulsar | Once every subscription acknowledges; storage at the next ledger rollover | No | Producer name and highest sequence id seen | Broker: 6 hours after the producer disconnects | Partly (PIP-6) |
| C13 NATS JetStream | Work queue: on acknowledgement. Interest: once all interested consumers acknowledge, possibly deferred | Sometimes deferred | `Nats-Msg-Id` within a window | Server: 2 minutes by default | Partly; none for the window |
| C14 PostgreSQL replication slot | WAL kept until no slot needs it; removed at a checkpoint; capped by `max_slot_wal_keep_size` | No | The receiver records the last LSN and skips repeats | The receiver (replication origins) | Yes (documentation, commit c655077) |

## Identity and sequence

### C1. Apache Kafka: the idempotent producer

**Bears on:** the run id and positions, and a re-send that keeps its position. Kafka 4.4.0 throughout; from 4.x the handbook lives at `docs/design/design.md`.

**What it does.**

- The broker gives each producer a producer id (PID). The producer numbers its records per partition, and sends the sequence number of a batch's first record in the batch header. The handbook states the failure and the mechanism:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

  > If a producer attempts to publish a message and experiences a network error, it cannot be sure if this error happened before or after the message was committed. This is similar to the semantics of inserting into a database table with an autogenerated key.

  > Since 0.11.0.0, the Kafka producer also supports an idempotent delivery option which guarantees that resending will not result in duplicate entries in the log. To achieve this, the broker assigns each producer an ID and deduplicates messages using a sequence number that is sent by the producer along with every message.

  Source: https://docs.google.com/document/d/1Sc8qlnc3K1OlOmDhs8YHZrndyvnFzZs2IAmklJ4wWJE/export?format=txt

  > Similarly, we the sequence number field represents the sequence number of the first message.

- **Where the sequence is checked, and what for.** KIP-98, as adopted, describes a check at the broker for exact continuity per PID and partition, with a lower number a duplicate and a higher one a fatal gap:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=66854913

  > The broker maintains in memory the sequence numbers it receives for each topic partition from every PID. The broker will reject a produce request if its sequence number is not exactly one greater than the last committed message from that PID/TopicPartition pair. Messages with a lower sequence number result in a duplicate error, which can be ignored by the producer. Messages with a higher number result in an out-of-sequence error, which indicates that some messages have been lost, and is fatal.

  > This ensures that, even though a producer must retry requests upon failures, every message will be persisted in the log exactly once. Further, since each new instance of a producer is assigned a new, unique, PID, we can only guarantee idempotent production within a single producer session.

  The code at 4.4.0 differs from that text. The partition leader checks continuity when it appends a client's batch, and recognises a retry by an exact match of the batch's first and last sequence against the batches it retains, returning the original batch's offsets as a success:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerAppendInfo.java

  > return nextSeq == lastSeq + 1L || (nextSeq == 0 && lastSeq == Integer.MAX_VALUE);

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/UnifiedLog.java

  > // if this is a client produce request, there will be up to 5 batches which could have been duplicated.

  > // If we find a duplicate, we return the metadata of the appended batch to the client.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerStateEntry.java

  > public static final int NUM_BATCHES_TO_RETAIN = 5;

  > filter(metadata -> firstSeq == metadata.firstSeq() && lastSeq == metadata.lastSeq())

  Inferred from that code: a retry older than the five retained batches does not match and fails the continuity check, so it is rejected as out of order rather than recognised as a repeat.

- **Is the sequence also an acknowledgement or a read position?** No source says so. The produce response returns offsets, and consumers track offsets, never sequences (C11). Looked in: the KIP-98 page, its design document, `design.md`, `ProducerAppendInfo.java`, `ProducerStateEntry.java`, `UnifiedLog.java` and KAFKA-5494. Inferred: the sequence is a device between one producer and one partition leader, for recognising a retry and detecting a gap.
- **The five batches** follow from the producer's in-flight limit:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerConfig.java

  > because broker only retains at most 5 batches for each producer. If the value is more than 5, previous batches may be removed on broker side.

  > Idempotence is enabled by default if no conflicting configurations are set.

- **What the broker remembers, and for how long.** Per partition and PID: the epoch, the sequence range of the last batches and the last offset, rebuilt from the log and snapshots. The design document linked from KIP-98:

  Source: https://docs.google.com/document/d/1Sc8qlnc3K1OlOmDhs8YHZrndyvnFzZs2IAmklJ4wWJE/export?format=txt

  > For each topic partition, the broker will maintain a mapping in memory from the PID to the epoch, sequence number, the last offset successfully written to the log, and the coordinator epoch from each producer (for transactional producers). The source of truth for this information is always the log itself.

  > It would be undesirable to let the PID-sequence map grew indefinitely, so we need a mechanism for PID expiration. We expire producerId’s when the age of the last message with that producerId exceeds the transactionalId expiration time or the topic’s retention time, whichever happens sooner.

  Today `producer.id.expiration.ms` defaults to one day and `transactional.id.expiration.ms` to seven:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/transaction-coordinator/src/main/java/org/apache/kafka/coordinator/transaction/TransactionLogConfig.java

  > public static final int PRODUCER_ID_EXPIRATION_MS_DEFAULT = 86400000;

  > Note that producer IDs may expire sooner if the last write from the producer ID is deleted due to the topic's retention settings.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/transaction-coordinator/src/main/java/org/apache/kafka/coordinator/transaction/TransactionStateManagerConfig.java

  > public static final int TRANSACTIONAL_ID_EXPIRATION_MS_DEFAULT = (int) TimeUnit.DAYS.toMillis(7);

- **A producer restart** gets a new PID unless it sets a `transactional.id`:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=217392092

  > Producer IDs, when not associated to a transaction, will be created every time the producer restarts.

- **When the broker's state is gone** (retention, `DeleteRecords` or expiry), the leader accepts a client's next write with any sequence, except for one case added for transactions version 2:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerAppendInfo.java

  > If there is no current producer epoch (possibly because all producer records have been deleted due to

  > retention or the DeleteRecords API) accept writes with any sequence number

  > // For transactions v2 idempotent producers, reject non-zero sequences when there is no producer ID state

  Inferred, and Unverified beyond that one file: a plain idempotent producer whose state has expired has its next write accepted with any sequence, which is the case the design document says the broker must reject (quoted under the stated why).

**Stated why.**

- Retries after a lost acknowledgement cause duplicates:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=66854913

  > Duplicates may occur in the stream due to producer retries. For instance, the broker may crash between committing a message and sending an acknowledgment to the producer, causing the producer to retry and thus resulting in a duplicate message in the stream.

  > These idempotent producer semantics are potentially useful for stateless applications like metrics tracking and auditing.

- A broker-generated PID rather than the user's id, for size; an epoch, to fence a zombie writer that shares a stable id; and a rejection once state has expired, because a repeat can no longer be told apart:

  Source: https://docs.google.com/document/d/1Sc8qlnc3K1OlOmDhs8YHZrndyvnFzZs2IAmklJ4wWJE/export?format=txt

  > We chose not to use the externally created TransactionalId directly in the message set because size is a premium. The TransactionalId is a variable length string, and could be very long, so we were concerned about the increased overhead. Hence we chose to store an internally generated PID in the message set instead.

  > Hence we introduce a new TransactionalId to distinguish producers, along with an epoch number so that zombie writers with the same TransactionalId can be fenced.

  > If not, we risk violating deduplication guarantees since we cannot know if the new message is a duplicate of a message which was already deleted.

- Five batches: the first release allowed one request in flight, and caching the last few batches was proposed to lift that:

  Source: https://issues.apache.org/jira/browse/KAFKA-5494

  > This was due to simplifying the implementation on the client and server.

  > This can be optimized by caching the metadata for the last 'n' batches. For instance, if the default max.inflight is 5, we could cache the record metadata of the last 5 batches, and fall back to a scan if the duplicate is not within those 5.

- KIP-360 (2.5.0): the producer bumps its epoch on `UNKNOWN_PRODUCER_ID` rather than resetting its sequence, and the broker keeps producer state after the log has dropped it:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=89068820

  > Idempotent/transactional semantics depend on the broker retaining state for each active producer id (e.g. epoch and sequence number). When the broker loses that state–due to segment deletion or a call to DeleteRecords–then additional produce requests will result in the UNKNOWN_PRODUCER_ID error.

  > Resetting the sequence number is fundamentally unsafe because it violates the uniqueness of produced records.

  > we will alter the behavior of the broker to retain the cached producer state even after it has been removed from the log.

  That last sentence sits beside the current `producer.id.expiration.ms` documentation, quoted above, which says a PID "may expire sooner" when its last write is deleted by retention. The two are reported as found and not reconciled.

- KIP-679 made idempotence the default, and KIP-854 gave producer ids their own, shorter expiry:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=165221843

  > The producer should enable the strongest message delivery guarantee by default.

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=217392092

  > it may be useful to have a separate timeout for producer IDs to avoid excess memory usage in this map

**Constraints.** Idempotence holds per partition and per producer session; across sessions it needs a `transactional.id`. The state lives on the partition leader and is replicated through the log. The guarantee assumes `acks=all`, retries and at most five requests in flight. A broker cluster serves thousands of producers, and the receiving side, not the producer, does the checking.

**Costs and dissent.**

- Memory: one entry per PID per partition. KIP-854 exists because default idempotence multiplied PIDs (quoted above).
- A purge driven by consumption can delete a producer's state with its last write (KAFKA-7190):

  Source: https://issues.apache.org/jira/browse/KAFKA-7190

  > When a streams application has little traffic, then it is possible that consumer purging would delete
  > even the last message sent by a producer (i.e., all the messages sent by
  > this producer have been consumed and committed), and as a result, the broker
  > would delete that producer's ID.

- The change of default meant for 3.0.0 did not take effect, because of a bug, until 3.0.1, 3.1.1 and 3.2.0:

  Source: https://issues.apache.org/jira/browse/KAFKA-13598

  > In KAFKA-10619, we intended to enable idempotence by default, but this was not achieved due to a bug in the config validation logic.

### C2. RFC 9562: UUID version 7

**Bears on:** the run id. RFC 9562 (Standards Track, May 2024, obsoleting RFC 4122) was read in full as plain text.

**What it does.**

- A 128-bit value: a 48-bit Unix-epoch millisecond timestamp in the most significant bits, a 4-bit version, a 2-bit variant, and 74 remaining bits, random by default (§5.7):

  Source: https://www.rfc-editor.org/rfc/rfc9562.txt

  > UUIDv7 values are created by allocating a Unix timestamp in
  > milliseconds in the most significant 48 bits and filling the
  > remaining 74 bits, excluding the required version and variant bits,
  > with random bits for each new UUIDv7 generated to provide uniqueness
  > as per Section 6.9.

  > Implementations SHOULD utilize UUIDv7 instead of UUIDv1 and UUIDv6 if
  > possible.

- **Monotonicity (§6.2)** comes normally from the timestamp; a counter or a sub-millisecond fraction is optional, and the three methods are a SHOULD only for one node making batches or generating at high frequency:

  > Monotonicity (each subsequent value being greater than the last) is
  > the backbone of time-based sortable UUIDs.  Normally, time-based
  > UUIDs from this document will be monotonic due to an embedded
  > timestamp; however, implementations can guarantee additional
  > monotonicity via the concepts covered in this section.

  > For single-node UUID implementations that do not need to create
  > batches of UUIDs, the embedded timestamp within UUIDv6 and UUIDv7 can
  > provide sufficient monotonicity guarantees by simply ensuring that
  > timestamp increments before creating a new UUID.  Distributed nodes
  > are discussed in Section 6.4.

- **Clock moves** are left to the implementation, and the RFC makes no promise about the clock's accuracy (§6.1, §6.2):

  > For example, if
  > it is possible for the system clock to move backward due to either
  > manual adjustment or corrections from a time synchronization
  > protocol, implementations need to determine how to handle such
  > cases.

  > This specification makes no
  > requirement or guarantee about how close the clock value needs to
  > be to the actual time.

  > To handle this scenario, the general
  > guidance is that the application MAY reuse the previous timestamp
  > and increment the previous counter method.

- **Across generators (§6.4, §6.8):** collision chance grows with the number of generating nodes, no coordination is required, and uniqueness rests on each host's random source:

  > While
  > UUIDs already feature sufficient entropy to ensure that the chances
  > of collision are low, as the total number of UUID generating nodes
  > increases, so does the likelihood of a collision.

  > Distributed applications generating UUIDs at a variety of hosts MUST
  > be willing to rely on the random number source at all hosts.

  > Although true global uniqueness is impossible to guarantee without a
  > shared knowledge scheme, a shared knowledge scheme is not required by
  > a UUID to provide uniqueness for practical implementation purposes.

- **The random source (§6.9)** should be a CSPRNG, reseeded across a fork:

  > Take care to ensure the
  > CSPRNG state is properly reseeded upon state changes, such as process
  > forks, to ensure proper CSPRNG operation.

- **Opacity (§6.12)** is lower-case guidance, not a SHOULD:

  > As general guidance, avoiding parsing UUID values unnecessarily is
  > recommended; instead, treat UUIDs as opaquely as possible.

- **One UUID as the identifier of a process, session or run: no statement found.** A search of the full text for session, process, run, instance, restart, boot and reboot found none. §2 lists what UUIDs identify, and a run is not among them:

  > Modern applications have a need to create and utilize UUIDs
  > as the primary identifier for a variety of different items in complex
  > computational systems, including but not limited to database keys,
  > file names, machine or system names, and identifiers for event-driven
  > transactions.

- **A UUID combined with a separate counter: no statement found.** The counters of §6.2 sit inside the UUID's own bits. The nearest passages are in §6.13, quoted as nearest only; the RFC does not say what the additional identifiers are:

  > DBMS vendors are encouraged to provide functionality to generate and
  > store UUID formats defined by this specification for use as
  > identifiers or left parts of identifiers such as, but not limited to,

  > In addition to UUIDs, additional identifiers MAY be
  > used to ensure integrity and feedback.

**Stated why.**

- Time-ordered UUIDs answer index locality and the cost of coordinating sequential keys across a network (§2.1):

  > In such cases, "auto-increment" schemes that are often
  > used by databases do not work well: the effort required to coordinate
  > sequential numeric identifiers across a network can easily become a
  > burden.

  > UUID versions that are not time ordered, such as UUIDv4
  > (described in Section 5.4), have poor database-index locality.

- v7 over v1 and v6 (§5.7):

  > Generally, UUIDv7 has improved entropy characteristics over UUIDv1
  > (Section 5.1) or UUIDv6 (Section 5.6).

- Millisecond precision (§6.1):

  > UUID timestamp source, precision, and length were topics of great
  > debate while creating UUIDv7 for this specification.

  > With UUIDv1 and UUIDv6, 100 nanoseconds
  > of precision are present, while UUIDv7 features a millisecond
  > level of precision by default within the Unix Epoch that does not
  > exceed the granularity capable in most modern systems.

- Why monotonicity is guidance rather than a requirement, from a draft editor in the drafting repository:

  Source: https://github.com/uuid6/uuid6-ietf-draft/issues/60#issuecomment-1061450955

  > Unless someone wants to argue otherwise, yes, the entire point of this section in the spec is as an implementation guideline for those implementations that wish to implement monotonicity.  It is not intended to be a requirement for all implementations.  Two important reasons for this are a) not all implementations require monotonicity, and b) there are an increasing number of applications which cannot feasibly provide it anyway because UUIDs are being generated on different systems (e.g. a cluster of web servers each generating records separately, where the cost of providing true monotonicity across the cluster is not worth the effort).

**Inferred.**

- The RFC's monotonicity text addresses one generator's own sequence: §6.2 speaks of single-node implementations and sends distributed nodes to §6.4, which is about collisions, not ordering. The RFC never says that monotonicity holds only within one generator.
- Two UUIDv7 values made by independent generators in the same millisecond are ordered by their random bits, not by creation time.

**Constraints.** A 48-bit millisecond timestamp, leap seconds excluded, valid to 10889 AD; 74 bits random by default. Everything beyond the minimum is the implementer's choice:

Source: https://www.rfc-editor.org/rfc/rfc9562.txt

> The minimum requirements for generating UUIDs of each version are
> described in this document.  Everything else is an implementation
> detail, and it is up to the implementer to decide what is appropriate
> for a given implementation.

**Costs and dissent.**

- The embedded timestamp signals the order of creation, and UUIDs must not be used as security capabilities (§8):

  > Implementations SHOULD NOT assume that UUIDs are hard to guess.  For
  > example, they MUST NOT be used as security capabilities (identifiers
  > whose mere possession grants access).

  > Timestamps embedded in the UUID do pose a very small attack surface.
  > The timestamp in conjunction with an embedded counter does signal the
  > order of creation for a given UUID and its corresponding data but
  > does not define anything about the data itself or the application as
  > a whole.

- A generator with no stable store raises the probability of duplicates (§6.3):

  > If an implementation does not have any stable store available, then
  > it MAY proceed with UUID generation as if this were the first UUID
  > created within a batch.  This is the least desirable implementation
  > because it will increase the frequency of creation of values such as
  > clock sequence, counters, or random data, which increases the
  > probability of duplicates.

- A contributor objected to stalling for monotonicity, and an editor answered that the rules are a SHOULD:

  Source: https://github.com/uuid6/uuid6-ietf-draft/issues/60#issuecomment-1057367360

  > Waiting for the timestamp to advance can slow down the generation of UUIDs and thus break the application. The UUID generation should not be a source of possible run-time errors for the application. It is better to allow a slight non-monotonicity, which the DBMS can handle quite well. It will only slow down the search for some records a little. In any case, with several data sources, a slight non-monotonicity is inevitable.

  Source: https://github.com/uuid6/uuid6-ietf-draft/issues/60#issuecomment-1057533949

  > The text let's the application implementers decide and provides some guidance. Both usages in this section are SHOULD not MUST.

- An alternative the RFC cites, ULID, does not guarantee order within one millisecond unless its monotonic mode is used, which fails on overflow:

  Source: https://raw.githubusercontent.com/ulid/spec/d0c7170df4517939e70129b4d6462cc162f2d5bf/README.md

  > Within the same millisecond, sort order is not guaranteed

  > If, in the extremely unlikely event that, you manage to generate more than 2<sup>80</sup> ULIDs within the same millisecond, or cause the random component to overflow with less, the generation will fail.

  Snowflake-style ids (a worker id plus a per-worker sequence) were not researched.

## Durable local buffers

Two words are kept apart in this part. A **logical delete** is the buffer's own bookkeeping ceasing to count data as pending. A **physical delete** is the bytes leaving the disk: an unlink, a truncation, or space handed back by compaction.

### C3. Filebeat and the libbeat disk queue

**Bears on:** purge only after confirmation, and an asynchronous purge. elastic/beats `v9.5.7`.

**What it does.** Filebeat has three mechanisms, and each confirms against something different.

- **(a) The registry: a read position on a file the application owns.** By default Filebeat deletes no source data; the application or logrotate does. The registry stores an offset per file, written when the input's acknowledgement handler runs. Filebeat's "at least once" statement is about the registry:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/how-filebeat-works.md

  > Filebeat guarantees that events will be delivered to the configured output at least once and with no data loss. Filebeat is able to achieve this behavior because it stores the delivery state of each event in the registry file.

  > In situations where the defined output is blocked and has not confirmed all events, Filebeat will keep trying to send events until the output acknowledges that it has received the events.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/filebeat/input/filestream/internal/input-logfile/publish.go

  > // updates the in memory state and create an updateOp that is used to schedule
  > // an update for the persistent store. The updateOp is run by the inputs ACK
  > // handler, persisting the pending update.

  Registry state itself is removed by time (`clean_inactive`) or when the file has gone (`clean_removed`), not by confirmation.

- **(b) The source file, when `delete.enabled` is on** (generally available since 9.2.0). Filestream can delete the file it reads once three conditions hold, and then only after a grace period, 30 minutes by default; a failed check is retried at the next scan. So the delete runs after the confirmation, off its path, on a timer. An acknowledgement here includes a drop:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/filebeat-input-filestream.md

  > By default, Filestream input doesn't delete files. If option is turned
  > on, Filestream input can delete files when those conditions are met:
  > - The reader is closed. The default is 5 minutes of inactivity.
  > - EOF has been reached.
  > - All events have been acknowledged by the output.

  > An output always acknowledges a successfully written event.
  > However, it also acknowledges dropped events.

- **(c) The disk queue (`queue.disk`)**, optional; the memory queue is the default. A segment file is deleted once every frame in it has been acknowledged by the output. The acknowledgement path only writes the position of the oldest unacknowledged frame and signals the core loop, which hands the segments to a separate deleter goroutine. Physical deletion is therefore asynchronous to the acknowledgement. On restart, reading resumes at the saved position, so some frames are sent twice.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/acks.go

  > // if the application terminates before all frames have been acknowledged,
  > // the next session will restart at the first missing frame. This means
  > // some later frames may be transmitted twice in this case, but it
  > // guarantees that we don't drop any data.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/deleter_loop.go

  > // When one or more segments are ready to delete, they are sent to
  > // requestChan. At most one deleteRequest may be outstanding at any time.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/configuring-internal-queue.md

  > Each segment contains some number of events waiting to be sent to the outputs, and is deleted when all its events are sent.

- **With the disk queue on,** the producer's acknowledgement fires once the frame is written to the queue:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/writer_loop.go

  > // Notify any producers with ACK listeners that their frames were written.

  Inferred from that file and `libbeat/publisher/pipeline/pipeline.go`: with `queue.disk`, the registry offset, and with it the `delete.enabled` condition, advances when an event reaches the disk queue, not when the output confirms it; the queue then holds the event until the output does.

- **Repeats.** Filebeat does not recognise them. Its documentation pushes identity to the receiver, through an id set before sending (O3).

**Stated why.**

- Why the deleter is its own loop, from the author of the disk queue (PR #21176):

  Source: https://github.com/elastic/beats/pull/21176#issuecomment-696179092

  > The short answer is, merging loops would make things more complex. I tried to find ways to have fewer, but the operations (read / write / delete) are logically independent (none _needs_ to know about the others), and trying to merge them ends up being a mess trying to keep any one operation from blocking the others (e.g.: just because we get an error deleting an old segment file doesn't mean we should stop writing to the current segment, but if they share a goroutine this becomes difficult.)

- Why a source file is deleted only once its data has been sent, from a reviewer of PR #43368, and why the grace period, from its author:

  Source: https://github.com/elastic/beats/pull/43368#discussion_r2021730545

  > We do not want "we still have data to send but it has been sitting in the queue for N seconds so discard it" which is what it sounds like might have been the case here. If that's what users wanted they wouldn't ask us for this feature, they would just have `rm -rf` in a cron job.

  Source: https://github.com/elastic/beats/pull/43368#discussion_r2081929039

  > The grace period is an extra safety to ensure the file is not removed by accident with data that has not been ingested.

- Why the registry, for at-least-once: the quotation from the page on how Filebeat works, above. A design write-up for the disk queue was promised in PR #21176 and was not found beyond `libbeat/publisher/queue/diskqueue/docs/on-disk-structures.md`.

**Constraints.** One agent per host, reading files another process owns; outputs that acknowledge (Elasticsearch, Logstash, Kafka, Redis). The disk queue landed in 2020 (#21176); `delete.enabled` in 9.2.0 (#43368, 2025).

**Costs and dissent.**

- Not owning the file is the stated limit of the guarantee:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/how-filebeat-works.md

  > There is a limitation to Filebeat’s at-least-once delivery guarantee involving log rotation and the deletion of old files. If log files are written to disk and rotated faster than they can be processed by Filebeat, or if files are deleted while the output is unavailable, data might be lost.

- With the output away, Filebeat holds deleted files open, so their space is not freed:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/faq-deleted-files-are-not-freed.md

  > In situations when the configured output is blocked (e.g. {{es}} or {{ls}} is unavailable) for a long time, this can cause Filebeat to keep file handlers to files that were deleted from the file system in the mean time.

- A full disk queue pauses an input or discards, per input; a `max_size` of 0 lets it fill the disk:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/configuring-internal-queue.md

  > Events that exceed this maximum will either pause their input or be discarded, depending on the input’s configuration.

- Duplicates after a restart are by design (acks.go, above), and a bug once made them routine:

  Source: https://github.com/elastic/beats/issues/32560

  > When using the disk queue, when Filebeat is restarted and a new event is sent, the disk queue creates a second segment file, if both are present, whenever Filebeat is restarted, the last event is always re-sent.

### C4. OpenTelemetry Collector: the persistent queue

**Bears on:** purge only after confirmation. opentelemetry-collector and -contrib `v0.166.0`.

**What it does.**

- Each request is a key in a storage extension, usually `file_storage` (bbolt). When a consumer finishes a request, the queue removes its index from the dispatched list and deletes the item in one `Batch` call, which `file_storage` runs as one bbolt transaction. So the logical delete is in the same step as the outcome.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > // The items currently dispatched by consumers are not deleted until the processing is finished.

  > setOp := storage.SetOperation(metadataKey, metadataBytes)
  > deleteOp := storage.DeleteOperation(getItemKey(index))
  > err = pq.client.Batch(ctx, setOp, deleteOp)

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-contrib/v0.166.0/extension/storage/filestorage/client.go

  > return normalizeStorageError(c.db.Update(batch))

- **The outcome is any finish, not only a success.** The delete runs whatever the result, except a shutdown error: a permanent error and an exhausted retry budget (`max_elapsed_time`, 300 s by default) delete too.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > // The queue is shutting down, don't mark the item as dispatched, so it's picked up again after restart.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/retry_sender.go

  > // Immediately drop data on permanent errors.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/README.md

  > - `max_elapsed_time` (default = 300s): Is the maximum amount of time spent trying to send a batch; ignored if `enabled` is `false`. If set to 0, the retries are never stopped.

  > If the collector instance is killed while having some items in the persistent queue, on restart the items will be picked and the exporting is continued.

- **The physical delete is deferred.** bbolt does not shrink its file; space comes back only by compaction, which is off by default:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-contrib/v0.166.0/extension/storage/filestorage/README.md

  > - `compaction.on_rebound` (default: false), which happens online when certain criteria are met; it's discussed in more detail below

- **Repeats.** Not recognised. After a crash, an item sent but not yet removed is sent again. The README states no "at least once" guarantee (a search for "at least" and "at-least" found nothing).

**Stated why.**

Source: https://github.com/open-telemetry/opentelemetry-collector/issues/2285

> Currently, collector buffers all data in memory, which can lead to data loss in case buffer gets overfilled (e.g. during temporary exporter connection issues) or due to a sudden crash.

> For example, exporter could buffer the incoming data on disk (up to the defined limit) and clear the buffer as data gets sent out.

The design document linked from PR #3274, which its authors have since marked outdated, gives the delete rule and why the queue sits in the exporter:

Source: https://docs.google.com/document/d/1Y4vNthCGdYI61ezeAzL5dXWgiZ73y9eSjIDitk3zXsU/export?format=txt

> when a record was successfully exported, it is removed from the WAL (or marked as such via a tombstone)

> It simplifies the design considerably, as queued_retry already knows the outcome of sending a given batch and has a memory-backed queue.

No stated rationale was found for deleting after a permanent error or an exhausted retry budget, beyond the retry sender's comment above.

**Constraints.** One queue per exporter, inside the Collector process; storage is a pluggable extension; `fsync` is off by default in `file_storage`. History: PR #3274 (2021) behind a build tag, then moved into `exporterhelper`.

**Costs and dissent.**

- Exporter away: the queue grows to `queue_size` (1000 requests by default), then new data is rejected, or blocks if `block_on_overflow` is set; after `max_elapsed_time` an item is deleted as dropped. A long outage loses data at both ends.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/README.md

  > **Failure behavior**: If data cannot be added to the sending queue, it is typically dropped. This occurs when the queue has reached its configured capacity or, for persistent queues, when the underlying storage cannot accept additional data (for example, due to insufficient disk space or I/O errors).

- Disk does not shrink after a drain; a delete could fail on a full disk and wedge the queue; and the delete-on-any-finish rule once lost data at shutdown:

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/5159

  > it was observed that after persistent queue grows, the space is not reclaimed automatically after draining.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/7198

  > As a result, we can take items out of the queue, but they're not actually removed from the storage, and no new items can be put in.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/6771

  > As `OnProcessingFinished` is always executed and the item is always removed from dispatched list even if the send was an error.

### C5. Vector: disk buffer v2 and end-to-end acknowledgements

**Bears on:** purge only after confirmation, and an asynchronous purge. vectordotdev/vector `v0.62.0`, with `v0.50.0` and `v0.57.0` for history.

**What it does.**

- Records go to append-only data files of up to 128 MiB. A data file is logically complete once every record read from it has been finalized; a background task, woken every second, then deletes it. Physical deletion is asynchronous to the acknowledgement:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/mod.rs

  > //! When all records from a data file have been fully acknowledged, the data file is scheduled for
  > //! deletion. We only delete entire data files, rather than truncating them piecemeal, which reduces
  > //! the I/O burden of the buffer.

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/ledger.rs

  > /// The reader advances the durable reader file checkpoint as soon as a data file's records are
  > /// fully acknowledged. Physical deletion can then happen asynchronously: if deletion fails or
  > /// the process exits first, this scan will retry later.

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/common.rs

  > pub const DEFAULT_DATA_FILE_CLEANUP_INTERVAL: Duration = Duration::from_secs(1);

- **History.** Up to `v0.57.0` the reader deleted the file inline; PR #25845 (merged 2026-07-27, first in `v0.58.0`) moved the delete to the background task:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.57.0/lib/vector-buffers/src/variants/disk_v2/reader.rs

  > self.delete_completed_data_file(data_file_path, Some(bytes_read))

  Source: https://github.com/vectordotdev/vector/pull/25845

  > - Move stale data-file deletion to asynchronous cleanup and add focused recovery, truncation, cleanup, and accounting coverage.

- **"Acknowledged" means finalized, whatever the status.** The ledger ignores the status, and the end-to-end acknowledgement RFC defines finalization to include a failure or a drop:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/ledger.rs

  > while let Some((_status, amount)) = stream.next().await {

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/rfcs/2021-03-26-6517-end-to-end-acknowledgement.md

  > In the discussion, the term "finalization" is used to describe the point
  > at which an event completes its trip through the pipeline, which may be
  > caused by its acknowledged delivery, a permanent failure, or a situation
  > causing the event to be dropped in processing.

- **End-to-end acknowledgements (`acknowledgements.enabled`) stop at the disk buffer.** The upstream source is told the event was delivered once it is on disk:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/writer.rs

  > // Record is durable on disk; disarm so finalizers resolve as Delivered.

  Inferred from those quotations: the buffer's delete does not depend on `acknowledgements.enabled`; it follows the sink's finalization on the far side of the buffer.

- **A full buffer** blocks by default, and the size limit is described as rigid:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/website/content/en/docs/architecture/buffering-model.md

  > When configured to block, Vector will wait indefinitely to write to a buffer that is currently full.
  > This is the default "when full" behavior.

  > This maximum size is adhered to rigidly, so you can depend on Vector
  > not exceeding it.

- **Repeats.** Records carry an increasing id used only to resume reading inside the buffer; no identity reaches the sink's destination.

**Stated why.**

- Why the source is acknowledged at the buffer rather than at the sink, from a maintainer:

  Source: https://github.com/vectordotdev/vector/issues/7065#issuecomment-944609134

  > We should be confident enough that the event is stored durably in the buffer that we can respond back that it was handled.  In the cases where we stored the event on disk/externally and had not yet acknowledged it at the source, and Vector crashes, we would open ourselves up to the caller thinking they needed to resend, and then we also read the event from the buffer, and now we've sent it twice.

- Why whole files: to reduce the buffer's I/O burden (mod.rs, above). Why the physical delete is asynchronous: a failed or interrupted delete is retried by the next scan (ledger.rs, above).
- Why a disk buffer at all, from the buffer improvements RFC:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/rfcs/2021-10-14-9477-buffer-improvements.md

  > Effectively, these users turn to disk buffering to increase reliability of their Vector-based
  > observability pipelines.

**Constraints.** One buffer per sink, inside the Vector process; `block` by default; a minimum size of about 256 MiB; at most 65,536 data files.

**Costs and dissent.**

- With deletion asynchronous, the disk can briefly exceed the "rigid" limit, as the author of #25845 accepted in review:

  Source: https://github.com/vectordotdev/vector/pull/25845#discussion_r3646993354

  > Now that deletion is asynchronous `total_buffer_size` really represents buffered size between acknowledged checkpointed boundaries. On a 1s interval we will be cleaning up these closed data files, so it should only be for small amount of time where the physical size on disk is exceeding the configured threshold.

- Space is freed whole files at a time, so one unacknowledged record holds a data file:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/mod.rs

  > This does mean, however, that a data file will stick around until
  > //! it is entirely processed and acknowledged.

- Sink away: with `block`, back-pressure reaches the source once the buffer is full; with `drop_newest`, new events are lost.

### C6. Fluent Bit: filesystem buffering

**Bears on:** purge only after confirmation. fluent/fluent-bit `v5.2.0`; fluent/fluent-bit-docs at `81af32b` (the repository has no tags).

**What it does.**

- Records are grouped into chunks of about 2 MB; with `storage.type filesystem` each chunk is a file. A task carries a chunk to its outputs. Once the task is releasable (no users, no deferred routes, no pending retries) the engine destroys it with deletion on, and the chunk file is unlinked, synchronously, in the engine's result handler:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/include/fluent-bit/flb_task.h

  > return task->users == 0 && task->deferred_routes == 0 &&
  > mk_list_size(&task->retries) == 0;

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/lib/chunkio/src/cio_file.c

  > /* Should we delete the content from the file system ? */
  > if (delete == CIO_TRUE) {
  > ret = cio_file_native_delete(cf);

- **The same release runs on success and on giving up:** on `FLB_OK`, on `FLB_ERROR`, on `FLB_RETRY` with retries disabled, and once the retry limit, 1 by default, is reached. A copy goes to a dead letter queue first, if one is enabled.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_output.c

  > instance->retry_limit = 1;

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/administration/scheduling-and-retries.md

  > When a chunk exhausts all retry attempts or retries are disabled, the data is discarded by default.

- **`storage.total_limit_size`** caps the filesystem chunks routed to one output. When a new chunk would exceed it, space is freed in a fixed order, oldest first within each step. Chunks from the storage-backlog input are destroyed outright, even if they are routed to other outputs. Chunks of an ordinary input go in two passes: first those routed to this output alone, which are destroyed; then the rest, which only lose this output's route, their file going once no route remains. Inferred from that order: an older chunk shared with another output can outlive a newer one routed to this output alone.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_input_chunk.c

  > if (flb_input_chunk_has_other_routes(ic, o_ins) == FLB_TRUE) {
  > return FLB_FALSE;
  > }

  The documentation states it more simply:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/pipeline/buffering.md

  > If the output plugin reaches its `storage.total_limit_size` capacity, the oldest chunk from its queue will be discarded to make room for new data.

- **Repeats.** No mechanism found in the chunk or task code read. Inferred: a chunk retried after a partial success is sent whole again.

**Stated why.** The proposal behind the size limit (issue #2408, 2020):

Source: https://github.com/fluent/fluent-bit/issues/2408

> Fluent Bit already provides a secondary buffering mechanism based in the file system. It can be enabled per-ingestor plugin, so every record and chunk registered keeps a copy in the file system until it is fully delivered to the destination.

> - CUJ 3: I want to prevent the disk becoming full by buffering input chunks without limit so other applications cannot use the disk.

> Will drop the oldest log data chunks when offline buffer size exceeds this limit.

No stated rationale found for deleting a chunk on `FLB_ERROR` or on an exhausted retry. Looked in `src/flb_engine.c` and `include/fluent-bit/flb_task.h` at `v5.2.0`, `administration/scheduling-and-retries.md` and `pipeline/buffering.md` at the docs commit, and issue #2408 with PRs #2435 and #2520.

**Constraints.** One agent process; buffering per input, limits per output; `Retry_Limit` 1 by default; an optional dead letter queue (`storage.keep.rejected`).

**Costs and dissent.**

- Output away: with the default retry limit, a chunk is discarded after one failed retry. With `no_limits`, files accumulate up to `storage.total_limit_size`, and then the oldest are evicted: loss at the bound. With no limit, the disk can fill.
- The proposal says a copy is kept "until it is fully delivered"; the source also deletes on an error and on an exhausted retry. The discrepancy is reported, not reconciled.

## In-memory buffers

### C7. OpenTelemetry SDK batch processors, and OTLP

**Bears on:** purge only after confirmation, and a re-send that keeps its position. opentelemetry-specification `v1.63.0`, opentelemetry-proto `v1.11.1`, opentelemetry-python `v1.45.2`.

**What it does.**

- The batch processor holds finished spans or log records in a bounded in-memory queue, drops new ones when it is full, and drops a batch whose export fails. Nothing is persisted, and nothing identifies a repeat.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/specification/trace/sdk.md

  > * `maxQueueSize` - the maximum queue size. After the size is reached, spans are
  >   dropped. The default value is `2048`.

  > * `Failure` - exporting failed. The batch must be dropped. For example, this
  >   can happen when the batch contains bad data and cannot be serialized.

  > Concurrent requests and retry logic is the responsibility of the exporter. The
  > default SDK's Span Processors SHOULD NOT implement retry logic, as the required
  > logic is likely to depend heavily on the specific protocol and backend the spans
  > are being sent to.

- **The exporter retries.** The OTLP exporter must retry transient errors, bounded by its timeout, and then fail:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/specification/protocol/exporter.md

  > Transient errors MUST be handled with a retry strategy. This retry strategy MUST implement an exponential back-off with jitter to avoid overwhelming the destination until the network is restored or the destination has recovered.

- **In one implementation**, opentelemetry-python, the processor takes the batch off the queue before it exports and does not look at the result, so the batch is gone whatever the outcome. The gRPC exporter treats a deadline as retryable, a case in which the server may already have the data.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-python/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  > batch = [self._queue.pop() for _ in range(count)]

  > _logger.exception("Exception while exporting %s.", self._exporting)

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-python/v1.45.2/exporter/opentelemetry-exporter-otlp-proto-grpc/src/opentelemetry/exporter/otlp/proto/grpc/exporter.py

  > StatusCode.DEADLINE_EXCEEDED,

- **OTLP accepts duplicates and has nothing to recognise them by.** Acknowledgement is per hop:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md

  > In edge cases (e.g. on reconnections, network interruptions, etc) the client has
  > no way of knowing if recently sent data was delivered if no acknowledgement was
  > received yet. The client will typically choose to re-send such data to guarantee
  > delivery, which may result in duplicate data on the server side. This is a
  > deliberate choice and is considered to be the right tradeoff for telemetry data.

  > End-to-end
  > delivery guarantees in such systems is outside of the scope of OTLP.

**Stated why.**

- For dropping, the specification's performance principles:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/specification/performance.md

  > - **Library should not block end user application by default.**
  > - **Library should not consume unbounded memory resource.**

  > In such a case, there is a trade-off between dropping some tasks to prevent memory starvation and keeping all tasks to prevent information loss.

- For accepting duplicates: "a deliberate choice and is considered to be the right tradeoff for telemetry data" (above), also in the original OTEP:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/oteps/0035-opentelemetry-protocol.md

  > This is a deliberate choice and is considered to be the right trade-off for telemetry data.

- **A per-request identity was proposed and not merged.** opentelemetry-proto PR #219 proposed an idempotency key; OTLP's maintainer at the time objected that intermediaries defeat it, and its author withdrew it in favour of an identity made from the producing instance and each point's timestamp:

  Source: https://github.com/open-telemetry/opentelemetry-proto/pull/219

  > Adds an idempotency key as described in #218. This is to support AggregationTemporality=DELTA correctly in systems that ingest and store DELTA data points.

  Source: https://github.com/open-telemetry/opentelemetry-proto/pull/219#issuecomment-687163264

  > Collectors can (and often are in production) be behind a load balancer with no guarantees that retried requests go to the same Collector instance. This makes detection either impossible if we store the idempotency keys locally per instance or requires Collector instances to coordinate and exchange idempotency keys (which is complicated and I am not sure we will actually implement it in the Collector).

  > This can be an operation mode for OTLP (as opposed to the currently specified operation which aims for at-least-once).

  Source: https://github.com/open-telemetry/opentelemetry-proto/pull/219#issuecomment-749974433

  > Further investigation into the Metrics part of OTLP leads me to think this is not needed after we specify a mandatory `service.instance.id` resource combined with timestamps in each data point.

**Constraints.** In-process, memory only, so a process exit loses whatever is queued; shutdown and flush may block, with a timeout. The Collector deserialises and re-batches what it receives, which the maintainer gave as the reason a request-level id cannot survive.

**Costs and dissent.**

- Persistent retry in the SDKs was proposed (specification issue #3645) and closed as not planned:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3645#issuecomment-2289605211

  > For this specific issue, it was noted that the collector already supports persistent storage.

  > But persistence mechanisms will be complicated to implement in the SDK, and its not clear that there is enough user demand to justify the investment.

  The same issue names language-specific disk buffers in opentelemetry-java-contrib (`disk-buffering`) and in Swift; their delete triggers are Unverified.
- An open issue (#5178) proposes opt-in blocking; its author states the current intent:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/5178

  > This is intentional — telemetry must not affect application behavior by default.

## Pull sources and retention decoupled from reading

### C8. Prometheus client libraries

**Bears on:** purge only after confirmation, as the comparable for a pull. prometheus/docs at `31957d4`, client_golang `v1.25.0`.

**What it does.** First, the ticket's check: a Prometheus client holds no buffer of rows waiting for collection. It holds one current value per series in memory. Each scrape calls every collector and reads the values; it does not reset them, and a counter goes back to zero only when the process restarts. The scraper confirms nothing, and the client remembers nothing about scrapes. So there is nothing for a scrape to purge.

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md

> Every time the CollectorRegistry is scraped it must
> callback to each of the Collectors’ collect method.

> counter. It MUST NOT allow the value to decrease, however it MAY be reset to 0
> (such as by server restart).

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/concepts/metric_types.md

> A _counter_ is a cumulative metric that represents a single [monotonically
> increasing counter](https://en.wikipedia.org/wiki/Monotonic_function) whose
> value can only increase or be reset to zero on restart.

In client_golang a counter is two atomic words, and `Write`, which the scrape path calls, only loads them:

Source: https://raw.githubusercontent.com/prometheus/client_golang/v1.25.0/prometheus/counter.go

> ival := atomic.LoadUint64(&c.valInt)

The exposition format carries one value, and optionally a timestamp, per series line: a snapshot, not a log of rows.

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/exposition_formats.md

> metric_name_or_labels value [ timestamp ]

**Stated why.** For the pull model:

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/introduction/faq.md

> * You can more easily and reliably tell if a target is down.

> Overall, we believe that pulling is slightly better than pushing, but it should
> not be considered a major point when considering a monitoring system.

And against a push cache that keeps what it is given:

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/practices/pushing.md

> * The Pushgateway never forgets series pushed to it and will expose them to
>   Prometheus forever unless those series are manually deleted via the
>   Pushgateway's API.

> Contrast this to
> Prometheus's usual pull-style monitoring: when an instance disappears
> (intentional or not), its metrics will automatically disappear along with it.

Why counters are cumulative and not reset by a scrape: no stated rationale found. Looked in `docs/concepts/metric_types.md`, `docs/instrumenting/writing_clientlibs.md`, `docs/practices/instrumentation.md`, `docs/introduction/faq.md` and `docs/introduction/overview.md` at `31957d4`.

**Inferred.** Because a scrape resets nothing, a missed scrape loses resolution but not the count, and several scrapers can read one target without interfering.

**Constraints.** Per-series state only; values between scrapes are not kept. The documentation states the limit that follows:

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/introduction/overview.md

> If you need 100%
> accuracy, such as for per-request billing, Prometheus is not a good choice, as
> the collected data will likely not be detailed and complete enough.

**Costs and dissent.** The Pushgateway, a push buffer that keeps everything until it is deleted by hand, is recommended only for service-level batch jobs (quoted above).

### C9. Prometheus server: TSDB retention, remote write and the agent's WAL

**Bears on:** purge only after confirmation, and recognising a repeat. prometheus/prometheus `v3.16.0`.

**What it does.**

- The server deletes by time or by size, in the background, independently of reads and scrapes:

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/docs/storage.md

  > - `--storage.tsdb.retention.time`: How long to retain samples in storage. If neither
  >   this flag nor `storage.tsdb.retention.size` is set, the retention time defaults to
  >   `15d`. Supported units: y, w, d, h, m, s, ms.

  > Expired block cleanup happens in the background. It may take up to two hours
  > to remove expired blocks. Blocks must be fully expired before they are removed.

- It recognises a repeated sample by series and timestamp: an identical repeat is accepted silently, a different value at the same timestamp is rejected.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/head_append.go

  > // We are allowing exact duplicates as we can encounter them in valid cases
  > // like federation and erroring out at that time would be extremely noisy.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/storage/interface.go

  > // ErrDuplicateSampleForTimestamp is when the sample has same timestamp but different value.

- Remote-Write 2.0 requires a receiver to be idempotent only for retries after a partial write:

  Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/specs/prw/remote_write_spec_2_0.md

  > In that case, the Receiver MUST support idempotency as Senders MAY retry with the same request.

- **Remote write, in server mode,** tails the TSDB's write-ahead log, which head compaction truncates with no input from remote write (a search of `tsdb/head.go` and `tsdb/db.go` at `v3.16.0` finds no reference to it). A remote that stays away longer than that loses data:

  Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/practices/remote_write.md

  > Failures will be retried without loss of data unless
  > the remote endpoint remains down for more than 2 hours. After 2 hours, the WAL
  > will be compacted and data that has not been sent will be lost.

- **In agent mode** the WAL is truncated on a timer, every two hours by default. The cut-off follows the slowest remote-write queue's highest *sent* timestamp, with a floor and a ceiling: at least `MinWALTime` (5 minutes) is kept behind it, and at most `MaxWALTime` (4 hours) even while remote write is stalled. So the purge is asynchronous and time-driven, and consults remote-write progress only in part.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/agent/db.go

  > DefaultTruncateFrequency = 2 * time.Hour

  > ts := walTruncationTime(db.opts, db.rs.LowestSentTimestamp(), timestamp.FromTime(time.Now()))

  > // Keep at most MaxWALTime of data, even if remote write is stalled.

  "Sent" is not "confirmed": the mark advances once the send-with-backoff returns, and it returns early only when cancelled, so a send that ended in a non-retryable error advances it too.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/storage/remote/queue_manager.go

  > // When there is resharding, we cancel the context for this queue, which means the data is not sent.
  > // So we exit early to not update the metrics.

- Neither mode marks samples for the receiver. An accepted proposal for resuming from a savepoint, not yet implemented, asks receivers to tolerate the repeats a replay sends:

  Source: https://raw.githubusercontent.com/prometheus/proposals/80693eac6188612f2378ec1e2389f2c7379bc66b/proposals/0072-remote-write-restart-from-savepoint.md

  > The remote write destination must handle duplicate or out-of-order sample errors gracefully so these do not slow down delivery.

**Stated why.**

- For accepting exact duplicates, the code comment above (federation, and an error would be "extremely noisy"). For retention by time and size: no stated rationale found in `docs/storage.md` at `v3.16.0`.
- The agent's truncation is described by its author as best-effort cooperation with remote write (PR #8785):

  Source: https://github.com/prometheus/prometheus/pull/8785

  > Truncation of the WAL cooperates on a best-effort case with Remote Write. Every time the WAL is truncated, the slowest remote write queue is used for the minimum timestamp of truncation. This gives loose guarantees that data from the WAL will not try to be removed until the maximum WAL age passes or the slowest queue catches up.

- The savepoint proposal states both its motive and why the WAL must stay bounded:

  Source: https://raw.githubusercontent.com/prometheus/proposals/80693eac6188612f2378ec1e2389f2c7379bc66b/proposals/0072-remote-write-restart-from-savepoint.md

  > If a config is reloaded or prometheus/agent is restarted before flushing pending samples we will skip those samples.

  > 4. Guards need to be in place to protect against infinite WAL growth.

  > The amount of complexity in this goal is large, it is my opinion that our current state where all samples are lost is worse than implementing a replay which does not give us at-least-once delivery.

- Why the server truncates its WAL regardless of remote write: no stated rationale found. Looked in `docs/practices/remote_write.md`, PR #4588 (WAL-based remote write) with its review comments, issues #6333, #8809 and #20141, and proposal 0072; a GitHub issue search for WAL truncation and remote write returned nothing, while a control search for "remote write" did. Inferred: the server's WAL exists for crash recovery of the head block, so remote write reads a log it does not own, as Filebeat (C3) reads a file it does not own.

**Constraints.** The repeat check holds per series, against the newest in-order sample:

Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/head_append.go

> // This only checks against the latest in-order sample.

**Costs and dissent.**

- Size-based retention can briefly exceed its limit during compaction, as `docs/storage.md` says.
- A remote away for longer than the bound loses data: two hours for the server, by its documentation; up to `MaxWALTime`, four hours by default, for the agent at `v3.16.0`. An operator's account of the trade-off, and the open work towards at-least-once:

  Source: https://github.com/prometheus/prometheus/issues/17616

  > Due to this it's really hard to determine how much downtime can be tolerated in a remote write configuration since it's a factor of `TruncateFrequency` + rate of data in.

  Source: https://github.com/prometheus/prometheus/issues/20141

  > - [ ] Only advance the savepoint once every shard has sent a segment

- The 2021 post announcing agent mode describes a removal the source at the tag does not make:

  Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/blog/posts/2021-11-16-agent.md

  > Our customized Agent TSDB WAL removes the data immediately after successful writes.

### C10. Apache Kafka: retention decoupled from reading

**Bears on:** purge only after confirmation, and an asynchronous purge. Kafka 4.4.0.

**What it does.**

- A topic retains by time or size (cleanup policy `delete`, the default), or by key (compaction), whatever has been read:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/getting-started/introduction.md

  > Events in a topic can be read as often as needed-unlike traditional messaging systems, events are not deleted after consumption. Instead, you define for how long Kafka should retain your events through a per-topic configuration setting, after which old events will be discarded.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/common/config/TopicConfig.java

  > This represents an SLA on how soon consumers must read

- **Deletion is asynchronous, in two stages.** A scheduled task checks retention every five minutes by default; it renames eligible segments with a `.deleted` suffix, and the files go `file.delete.delay.ms` later, 60 seconds by default:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/server-common/src/main/java/org/apache/kafka/server/config/ServerLogConfigs.java

  > public static final long LOG_CLEANUP_INTERVAL_MS_DEFAULT = 5 * 60 * 1000L;

  > public static final long LOG_DELETE_DELAY_MS_DEFAULT = 60000L;

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/LocalLog.java

  > respective file name. Allows these files to be optionally deleted asynchronously.

- **A consumer that falls behind retention** finds its offset gone. `auto.offset.reset` (default `latest`) decides where it resumes, or, with no reset policy, the client raises `OffsetOutOfRangeException`. What lay between is lost to that consumer.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/consumer/ConsumerConfig.java

  > What to do when there is no initial offset in Kafka or if the current offset does not exist any more on the server

  > (e.g. because that data has been deleted)

- **Deletion driven by consumption exists too, off the reading path.** KIP-107 added `DeleteRecords`, which moves a partition's log start offset; segments wholly below it are deleted later by the same retention task. Kafka Streams sets infinite retention on its repartition topics and purges records up to the committed offset on its own interval (KIP-811):

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=67636826

  > will not be exposed to consumer even if it is still on the disk

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=199528229

  > Kafka Streams sets infinite retention on repartition topics and explicitly deletes records once they've been committed to the next topic in their Topology.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/streams/src/main/java/org/apache/kafka/streams/StreamsConfig.java

  > The frequency in milliseconds with which to delete fully consumed records from repartition topics.

  > Purging will occur after at least this value since the last purge, but may be delayed until later.

**Stated why.**

- Retaining past consumption gives consumers flexibility, and a log of appends makes long retention cheap; the alternative is named and set aside:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

  > For example, in Kafka, instead of attempting to delete messages as soon as they are consumed, we can retain messages for a relatively long period (say a week). This leads to a great deal of flexibility for consumers, as we will describe.

  > Since the data structures used for storage in many messaging systems scale poorly, this is also a pragmatic choice--since the broker knows what is consumed it can immediately delete it, keeping the data size small.

- The handbook also rejected a producer that keeps its own log for brokers to pull from:

  > You could imagine other possible designs which would be only pull, end-to-end. The producer would locally write to a local log, and brokers would pull from that with consumers pulling from them. A similar type of "store-and-forward" producer is often proposed. This is intriguing but we felt not very suitable for our target use cases which have thousands of producers.

  > Our experience running persistent data systems at scale led us to feel that involving thousands of disks in the system across many applications would not actually make things more reliable and would be a nightmare to operate.

- `DeleteRecords` exists because retention that ignores the consumer either loses data or costs disk:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=67636826

  > It provides only time-based and size-based log retention policy, both of which are agnostic to consumer

  > If we set small time-based log retention for intermediate data, the data may be deleted even before it is consumed by downstream jobs. If we set large time-based log retention, the data will take large amount of disk space for a long time.

- Streams purges on an interval, not at every commit, for throughput:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=199528229

  > this causes delete records requests to be sent extremely frequently, potentially reducing throughput and causing a high volume of log messages to be logged by the brokers.

- Why a delay between renaming a segment and removing its file: no stated rationale found. Looked in `TopicConfig.java`, `ServerLogConfigs.java`, `LocalLog.java` and `design.md` at 4.4.0. Inferred: it lets readers that still hold the old segment open finish.

**Constraints.** A broker cluster serving many consumer groups, each with its own position. Retention is a promise to keep data at least that long, not until it is read.

**Costs and dissent.** A lagging consumer loses data once retention passes its offset (above). Intermediate data costs disk, the stated reason for KIP-107. A purge driven by consumption can delete a producer's deduplication state (KAFKA-7190, under C1).

### C11. Apache Kafka: consumer offset commits

**Bears on:** the confirmed position. Kafka 4.4.0.

**What it does.** A consumer's position in a partition is one integer, the offset of the next record to read, which the group coordinator stores when the consumer commits it. It is the restart point. Committing does not delete anything in plain Kafka; it does drive the Streams repartition purge (C10).

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

> This means that the position of a consumer in each partition is just a single integer, the offset of the next message to consume. This makes the state about what has been consumed very small, just one number for each partition. This state can be periodically checkpointed. This makes the equivalent of message acknowledgements very cheap.

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java

> The committed offset should be the next message your application will consume,

The at-least-once order is to process and then commit, so a failure between the two re-delivers:

> Kafka provides what is often called "at-least-once" delivery guarantees, as each record will likely be delivered one
>  * time but in failure cases could be duplicated.

Committed offsets themselves expire, seven days after a group empties by default:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/group-coordinator/src/main/java/org/apache/kafka/coordinator/group/GroupCoordinatorConfig.java

> public static final int OFFSETS_RETENTION_MINUTES_DEFAULT = 7 * 24 * 60;

**Stated why.** A per-message acknowledgement re-delivers anyway and costs the broker state for every message:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

> First of all, if the consumer processes the message but fails before it can send an acknowledgement then the message will be consumed twice. The second problem is around performance, now the broker must keep multiple states about every single message (first to lock it so it is not given out a second time, and then to mark it as permanently consumed so that it can be removed).

> There is a side benefit of this decision. A consumer can deliberately _rewind_ back to an old offset and re-consume data.

The handbook leaves recognising a repeat on the consuming side to the output, in two ways that are not a producer's sequence:

> In many cases messages have a primary key and so the updates are idempotent (receiving the same message twice just overwrites a record with another copy of itself).

> This can be handled more simply and generally by letting the consumer store its offset in the same place as its output.

**Constraints.** One consumer per partition per group, which is what lets a single integer stand for what has been consumed.

**Costs and dissent.** Everything after the last commit is re-delivered on failure. Automatic commits can run ahead of what was processed:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java

> If you fail to do either of these, it is possible for the committed offset
>  * to get ahead of the consumed position, which results in missing records.

## Deletion after confirmation, outside a buffer

### C12. Apache Pulsar: producer deduplication and acknowledgement-driven deletion

**Bears on:** recognising a repeat, purge only after confirmation, and an asynchronous purge. apache/pulsar at `8c04f6c`, apache/pulsar-site at `4b4a781`.

**What it does.**

- Deduplication keys on the producer's name and a sequence id. The broker keeps the highest sequence id seen per producer per topic, not a window of batches, and the application may choose the sequence, holes included. It is off by default.

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pip/pip-6.md

  > Broker needs to keep a per-topic hash-map that keeps track of the highest
  > `sequenceId` received from each unique `producerName`.

  > This will allow the application to have custom sequence schemes, also with "holes" in the
  > middle. For example, if the producer is reading data from a file and publishing on a Pulsar
  > topic, it might want to use the offset in the file for a particular *record* as the sequence
  > id when publishing.

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/persistent/MessageDeduplication.java

  > if (lastSequenceIdPushed != null && sequenceId <= lastSequenceIdPushed) {

- The broker forgets a disconnected producer after six hours, and tracks at most 10,000:

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/conf/broker.conf

  > # Time of inactivity after which the broker will discard the deduplication information
  > # relative to a disconnected producer. Default is 6 hours.
  > brokerDeduplicationProducerInactivityTimeoutMinutes=360

  > brokerDeduplicationEnabled=false

- A message is kept until every subscription acknowledges it, then marked for deletion; the storage goes later, at ledger granularity:

  Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-retention-expiry.md

  > By default, when a Pulsar message arrives at a broker, the message is stored until it has been acknowledged on all subscriptions, at which point it is marked for deletion.

  > (Note that messages that are no longer being stored are not necessarily immediately deleted, and may still be accessible until the next ledger rollover. Because clients cannot predict when rollovers may happen, it is not wise to rely on a rollover not happening at an inconvenient point in time.)

**Stated why.**

Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pip/pip-6.md

> Additionally, for an application that is publishing messages, to avoid publishing duplicate
> messages after application crashes, it needs to be able to restart publishing from a certain
> messages, with a particular sequence id.

> This will simplify managing the sequence id for the application, as no
> mapping will be required.

Why six hours: no stated rationale found in `pip-6.md`, `conf/broker.conf` or `docs/cookbooks-deduplication.md`. Why deletion at ledger rollover: no stated rationale found in `docs/cookbooks-retention-expiry.md` or `docs/concepts-messaging.md`. Inferred: storage is in BookKeeper ledgers, which are removed whole.

**Constraints.** Deduplication across a restart needs a stable, unique producer name:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-deduplication.md

> Specify a name for the producer (this is a requirement, Pulsar will use the producer name to filter duplicated messages).

**Costs and dissent.** Unacknowledged backlog grows without bound unless a backlog quota is set, and one of the quota's policies discards backlog:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-retention-expiry.md

> | `consumer_backlog_eviction` | The broker will begin discarding backlog messages                                                 |

### C13. NATS JetStream: message ids, double acknowledgement and retention policies

**Bears on:** recognising a repeat, purge only after confirmation, and an asynchronous purge. nats-io/nats.docs at `f115bec`, nats-server `v2.15.3`.

**What it does.**

- A publisher may set a `Nats-Msg-Id` header. The server keeps a map of ids for a window, two minutes by default, and drops a repeat within it:

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/using-nats/jetstream/model_deep_dive.md

  > Here we set a `Nats-Msg-Id:1` header which tells JetStream to ensure we do not have duplicates of this message - we only consult the message ID not the body.

  > The default window to track duplicates in is 2 minutes, this can be set on the command line using `--dupe-window` when creating a stream, though we would caution against large windows.

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/stream.go

  > const StreamDefaultDuplicatesWindow = 2 * time.Minute

- A consumer may ask the server to acknowledge its acknowledgement:

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/using-nats/jetstream/model_deep_dive.md

  > If the response received from the server indicates success you can be sure that the message will never be re-delivered by the consumer (due to a loss of your acknowledgement).

- Retention is by limits (the default), by work queue (deleted on acknowledgement) or by interest (deleted once every interested consumer acknowledges). Interest deletion may be deferred:

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/streams.md

  > Once a given message is ack’ed, it will be deleted from the stream.

  > the server may not immediately delete all messages that belong to that set of subjects, for performance reasons. Instead, deletion may be deferred until those messages reach the start of the stream.

**Stated why.**

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/README.md

> For the publishing side, it relies on the publishing application attaching a unique message or publication ID in a message header and on the server keeping track of those IDs for a configurable rolling period of time in order to detect the publisher publishing the same message twice. For the subscribers a _double_ acknowledgment mechanism is used to avoid a message being erroneously re-sent to a subscriber by the server after some kinds of failures.

> * _limits_ (the default) is to provide a replay of messages in the stream.
> * _work queue_ (the stream is used as a shared queue and messages are removed from it as they are consumed) is to provide the exactly-once consumption of messages in the stream.

Why two minutes, and why to caution against large windows: no stated rationale found. Looked in `model_deep_dive.md`, `nats-concepts/jetstream/streams.md` and `README.md` at the pinned commit, `server/stream.go` at `v2.15.3`, and every ADR in nats-io/nats-architecture-and-design at `cd44e99` (ADR-8, ADR-49 and ADR-50 mention deduplication; none states a why). Inferred: the id map grows with the publish rate times the window.

**Constraints.** Ids are opaque strings the publisher chooses. Limits always apply, whatever the retention policy:

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/README.md

> Note that regardless of the retention policy selected, the limits (and the discard policy) _always_ apply.

Inferred: a repeat that arrives after its id has left the window is stored again.

**Costs and dissent.** A limit deletes unread messages from a work queue:

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/streams.md

> For example, given a work-queue stream, if `MaxMsgs` are set and the default discard policy of _old_, messages will be automatically deleted even if the consumer did not receive them.

### C14. PostgreSQL logical replication slots

**Bears on:** purge only after confirmation, the confirmed position, and an asynchronous purge. PostgreSQL documentation at `REL_18_7`.

**What it does.**

- A slot holds back the removal of write-ahead log (WAL) for its consumer, even while the consumer is disconnected. It keeps two positions. `confirmed_flush_lsn` is what the consumer has confirmed receiving; `restart_lsn` is the oldest WAL still needed, and it is `restart_lsn` that the documentation ties to removal. WAL is removed at a checkpoint, later than the confirmation:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/system-views.sgml

  > up to which the logical
  > slot's consumer has confirmed receiving data. Data corresponding to the
  > transactions committed before this

  > might be required by the consumer of this slot and thus won't be
  > automatically removed during checkpoints unless this LSN
  > gets behind more than

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/wal.sgml

  > Hence, after a checkpoint, WAL segments preceding the one containing
  > the redo record are no longer needed and can be recycled or removed.

- **Repeats.** The slot's position is persisted only at a checkpoint, so after a crash changes are sent again, and the client is to recognise them by position:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

  > The current position of each slot is persisted only at checkpoint, so in
  > the case of a crash the slot might return to an earlier LSN, which will
  > then cause recent changes to be sent again when the server restarts.
  > Logical decoding clients are responsible for avoiding ill effects from
  > handling the same message more than once.  Clients may wish to record
  > the last LSN they saw when decoding and skip over any repeated data

- `max_slot_wal_keep_size`, added in PostgreSQL 13, caps what a slot may retain and invalidates a slot that overruns it:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/config.sgml

  > replication slots may retain an unlimited amount of WAL files.

**Stated why.**

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/high-availability.sgml

> Replication slots provide an automated way to ensure that the
> primary server does
> not remove WAL segments until they have been received by all standbys,

> A disadvantage of these methods is that they
> often result in retaining more WAL segments than
> required, whereas replication slots retain only the number of segments
> known to be needed.

The bound, in the commit that added it:

Source: https://github.com/postgres/postgres/commit/c6550776394e25c1620bc8258427c8f1d448080d

> Replication slots are useful to retain data that may be needed by a
> replication system.  But experience has shown that allowing them to
> retain excessive data can lead to the primary failing because of running
> out of space.

> Slots that overrun that space are invalidated
> at checkpoint time, enabling the storage to be released.

Why the position is persisted only at a checkpoint: no stated rationale found in `logicaldecoding.sgml` at `REL_18_7`. Inferred: to avoid a durable write for every confirmation.

**Constraints.** A slot knows nothing of its consumer and survives crashes:

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

> Replication slots persist across crashes and know nothing about the state
> of their consumer(s). They will prevent removal of required resources
> even when there is no connection using them.

**Costs and dissent.**

> In extreme cases this could cause the database to shut down to prevent
> transaction ID wraparound

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/high-availability.sgml

> Beware that replication slots can cause the server to retain so
> many WAL segments that they fill up the space allocated for

PostgreSQL 18 adds a second, default-off guard:

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/config.sgml

> Invalidate replication slots that have remained inactive (not used by

## Comparables that chose otherwise

Some of the comparables above chose otherwise themselves, and are only pointed to here: the OpenTelemetry SDK drops a failed batch and has no identity for a repeat (C7); the Prometheus server truncates the log remote write reads, whether or not it has been sent (C9); Kafka deletes by time or size, whether or not anything has been read (C10). Pulsar (C12), NATS JetStream (C13), PostgreSQL (C14) and Kafka's own handbook (C11) each document a way to recognise a repeat that is not Kafka's producer sequence. The systems below were read for this section only.

### Deleting on send

#### O1. statsd

statsd `v0.10.2`. Clients send UDP datagrams with no acknowledgement. The server aggregates in memory and, after each flush to its backends, resets counters to zero or deletes them, whether or not the backend write succeeded; the graphite backend only logs connection errors. Nothing identifies a repeat.

Source: https://raw.githubusercontent.com/statsd/statsd/v0.10.2/stats.js

> // After all listeners, reset the stats

> metrics.counters[counter_key] = 0;

**Stated why.** The README at `v0.10.2` states no reason for UDP, and now offers TCP as well. The reason is in the original authors' posts. Etsy's, from 2011, was read from the Wayback Machine's copy because etsy.com returned HTTP 403:

Source: https://web.archive.org/web/20120103141034id_/http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/

> So,  why do we use UDP to send data to StatsD? Well, it’s fast — you don’t  want to slow your application down in order to track its performance —  but also sending a UDP packet is fire-and-forget. Either StatsD gets the  data, or it doesn’t.

> The application doesn’t care if StatsD is up,  down, or on fire; it simply trusts that things will work. If they don’t,  our stats go a bit wonky, but the site stays up.

Flickr's, from 2008, which the README credits:

Source: https://code.flickr.net/2008/10/27/counting-timing/

> When counting frequent stats, losing the odd packet doesn’t really hurt us, especially when we can also graph when we’ve been dropping packets

**Constraints, costs and dissent.** Loss is accepted, and measured through the kernel's UDP receive-error counters. Costs beyond these sources were not searched.

#### O2. Syslog over UDP (RFC 5426)

No acknowledgement, retransmission or loss detection; nothing is kept for a repeat.

Source: https://www.rfc-editor.org/rfc/rfc5426.txt

> This transport mapping does not provide any mechanism to detect and
> correct loss of datagrams.

**Stated why, and the RFC's own dissent.**

> However, this transport is lightweight and is built upon the existing
> popular use of UDP for syslog.

> This is why the syslog
> TLS transport [7] is REQUIRED to implement and RECOMMENDED for
> general use.

### Recognising a repeat by an id the sender assigns, or by content

Each of these recognises a repeat without a per-producer sequence number.

#### O3. Elasticsearch and Beats: a document id set before sending

elastic/beats `v9.5.7`, elasticsearch-specification at `1b721b9`. Beats is at-least-once and accepts duplicates. To recognise a repeat, Beats sets the document id itself, as a random id (`add_id`) or as a fingerprint of chosen fields (`fingerprint`), and Elasticsearch remembers the id for as long as the document exists in that index.

Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/filebeat-deduplication.md

> Because document IDs are typically set by {{es}} *after* it receives the data from {{beats}}, the duplicate events are indexed as new documents.

> Rather than allowing {{es}} to set the document ID, set the ID in {{beats}}. The ID is stored in the {{beats}} `@metadata._id` field and used to set the document ID during indexing. That way, if {{beats}} sends the same event to {{es}} more than once, {{es}} overwrites the existing document rather than creating a new one.

The documentation says a repeat overwrites. The output code at `v9.5.7` sends a `create` when the id is set, so a repeat is refused with a 409 and counted as a duplicate:

Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/outputs/elasticsearch/client.go

> return eslegclient.BulkCreateAction{Create: meta}, nil

> // 409 is used to indicate there is already an event with the same ID, or

> stats.duplicates++

Source: https://raw.githubusercontent.com/elastic/elasticsearch-specification/1b721b91aca7d38d6ed452746de2820f8b94b03f/specification/_global/index/IndexRequest.ts

> * Set to `create` to only index the document if it does not already exist (put if absent).
> * If a document with the specified `_id` already exists, the indexing operation will fail.

**Stated why.** For the id: the deduplication page above ("document IDs are typically set by {{es}} *after* it receives the data"). For `create` and the 409, no stated rationale found in that page or in `libbeat/outputs/elasticsearch/client.go` at `v9.5.7`.

**Constraints.** The identity is per message, assigned by the sender or derived from content, and holds within one index (Inferred, not checked: a rollover to a new backing index starts a new namespace).

#### O4. Elasticsearch time series data streams

elastic/docs-content at `96870a9`. In a time series data stream the document id is generated from the dimension fields and the timestamp, and a repeat is refused:

Source: https://raw.githubusercontent.com/elastic/docs-content/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/time-series-data-stream-tsds.md

> {{es}} uses dimensions and timestamps to generate time series document `_id` values. Two documents with the same dimensions and timestamp are considered duplicates. Duplicates are rejected during ingestion with a `409 Conflict` status.

**Stated why.** No stated rationale found in `time-series-data-stream-tsds.md` or `advanced-topics-tsds.md` at `96870a9`.

#### O5. Amazon SQS FIFO queues

The service remembers a deduplication id the sender assigns, or a SHA-256 of the body, for five minutes, even after the message is deleted. A repeat within that interval is accepted and not delivered; after it, SQS cannot tell a repeat apart.

Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html

> If a message with a particular `MessageDeduplicationId` is sent successfully, any messages sent with the same `MessageDeduplicationId` are accepted successfully but aren't delivered during the 5-minute deduplication interval.

> If a message is sent successfully but the acknowledgement is lost and the message is resent with the same `MessageDeduplicationId` after the deduplication interval, Amazon SQS can't detect duplicate messages.

> Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.

**Stated why.** The failure it answers is the one in the second quotation, a lost acknowledgement. No stated rationale found for five minutes, in `API_SendMessage`, `FIFO-queues-exactly-once-processing` and `using-messagededuplicationid-property` on docs.aws.amazon.com.

#### O6. MQTT QoS 2

OASIS MQTT 5.0 and 3.1.1. The sender assigns a packet identifier unused in the session. The receiver remembers it from PUBLISH until PUBREL and answers a repeat in that window without delivering it again; after PUBCOMP the identifier is forgotten and may be reused. The state belongs to the session, which lasts as long as the connection plus the session expiry interval.

Source: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html

> Until it has received the
>      corresponding PUBREL packet, the receiver MUST acknowledge any subsequent
>      PUBLISH packet with the same Packet Identifier by sending a PUBREC. It
>      MUST NOT cause duplicate messages to be delivered to any onward recipients
>      in this case [MQTT-4.3.3-10].

> After it has sent a
>      PUBCOMP, the receiver MUST treat any subsequent PUBLISH packet that
>      contains that Packet Identifier as being a new Application Message [MQTT-4.3.3-12].

**Stated why, and its cost.**

> This is the highest Quality of Service level, for use when
> neither loss nor duplication of messages are acceptable. There is an increased
> overhead associated with QoS 2.

#### O7. Google Cloud Pub/Sub exactly-once delivery

On the subscriber side only, Pub/Sub prevents redelivery of an acknowledged message within a region, by a message id the service assigns. Publish-side deduplication is Unverified.

Source: https://cloud.google.com/pubsub/docs/exactly-once-delivery

> Pub/Sub supports exactly-once delivery, within a cloud region,
> based on a Pub/Sub-defined unique
> message ID.

**Stated why.** No stated rationale found on that page.

### Weaker cases, not counted as a way to recognise a repeat

- **Fluentd's forward protocol.** A sender may tag a request with a random `chunk` id, and the receiver must echo it as `ack`. Fluentd `v1.20.1`'s `in_forward` builds the acknowledgement straight from the option and keeps no record of ids, so it acknowledges a repeat but does not recognise it. `out_forward` is at-most-once by default, and at-least-once with `require_ack_response`. No stated rationale found, in the Forward Protocol Specification v1 wiki page, `lib/fluent/plugin/in_forward.rb` at `v1.20.1` and `output/forward.md` at `cb3c4ca` of fluentd-docs-gitbook.

  Source: https://raw.githubusercontent.com/wiki/fluent/fluentd/Forward-Protocol-Specification-v1.md

  > - `ack`: Server MUST respond `ack` when the `chunk` option is sent by client. The `ack` response value MUST be the same value given by `chunk` option from client. Client SHOULD retry to send events later when the request has a `chunk` but the response has no `ack`.

- **Amazon Kinesis Data Streams** does not deduplicate; it recommends a key in the record:

  Source: https://docs.aws.amazon.com/streams/latest/dev/kinesis-record-processor-duplicates.html

  > Although the two records have identical data, they also have unique sequence numbers. Applications that need strict guarantees should embed a primary key within the record to remove duplicates later when processing.

- **Azure Event Hubs idempotent publishing** is Kafka's shape: a producer group id, an owner level and a starting sequence number per partition. At SDK 5.12.2 the switch is hidden from code completion. What the service remembers, and for how long, is Unverified.

  Source: https://raw.githubusercontent.com/Azure/azure-sdk-for-net/Azure.Messaging.EventHubs_5.12.2/sdk/eventhub/Azure.Messaging.EventHubs/src/Producer/PartitionPublishingOptions.cs

  > ///   The starting number that should be used for the automatic sequencing of events for the associated partition, when published by this producer.

## Candidates not examined

- Snowflake-style identifiers (a worker id plus a per-worker sequence), named in RFC 9562's survey of implementations.
- The disk buffers in opentelemetry-java-contrib (`disk-buffering`) and OpenTelemetry Swift, named in specification issue #3645: their delete triggers are Unverified.
- Out-of-order sample handling in the Prometheus TSDB, which has its own repeat check.
- Publish-side deduplication in Google Cloud Pub/Sub, and what the Azure Event Hubs service remembers.
- Log shippers not surveyed by the elicitation (rsyslog's disk-assisted queues, Logstash's persistent queue, the Datadog and Splunk agents).
