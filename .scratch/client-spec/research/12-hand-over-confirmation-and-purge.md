# Research: hand-over, confirmation and purge

- **Ticket:** `issues/12-research-the-why-hand-over-confirmation-and-purge.md`. It checks again, from primary sources, the systems the specification's hand-over rules were said to follow, and captures why each behaves as it does.
- **Sources read:** 2026-11-25 (UTC). Every link below was read that day.
- **Web research:** authorised by the maintainer in the session that picked this ticket up, for the researcher and for the reviewers, read-only.
- **Status:** findings, the fit of each comparable, an answer to the maintainer's question about Kafka's sequence number, one verdict per stated behaviour with proposed wording where it is not the first, and what the findings bear on, for the maintainer. They recommend no answer to open questions 7, 8, 15 or 25, and the specification is not edited.

## How the sources were checked

- Each comparable was read from its official documentation, a specification, or source code at a named tag or commit. GitHub links are pinned to a tag or a commit, except issue, pull request and discussion threads, which have no version, and the Fluentd wiki, which is read at its current revision. Kafka KIPs are linked by Confluence page id, Apache JIRA issues by their browse URL, and RFCs by the RFC Editor's plain-text rendition. Two design documents are Google Docs, linked by their text export. The AWS, Google Cloud, Microsoft Learn, OASIS MQTT, ActiveMQ, RabbitMQ quorum queues and Prometheus governance pages, the PromCon 2023 talk abstract, and the Flickr, NATS, Robust Perception and ganeshvernekar.com posts are unversioned, and were read as the pages served that day; the AWS pages as the Markdown rendition the site serves. Etsy's 2011 post is read from the Wayback Machine's copy of 2012-01-03, because etsy.com refused the request. The Elasticsearch 8.19 reference guide is read at its versioned URL.
- Every blockquote sits under the `Source:` line it was copied from. Each was checked as a substring of raw source text the researcher fetched again: GitHub files from `raw.githubusercontent.com`, GitHub threads and commits through the GitHub API, Confluence pages through the Confluence REST API, JIRA issues through the JIRA REST API, and other pages as HTML with their tags stripped. 478 quotations were checked; 397 match exactly, and 81 match only once whitespace is collapsed: 28 passages of RFC 9562 and RFC 5426, whose plain text indents and wraps lines; nine of the PostgreSQL documentation's SGML, which wraps lines; 29 code comments and code lines whose indentation differs; one Markdown passage whose second line is indented; six passages of HTML pages that wrap lines elsewhere, four of them on Google Cloud pages, one in the Elasticsearch 8.19 guide and one in the OASIS MQTT specification; three passages of a GitHub pull request body whose lines end in CRLF; and five passages that carry a non-breaking space, three in the Robust Perception post, one on the ActiveMQ page and one in a JIRA issue.
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

The elicitation's survey made eight claims, recorded in `CONTEXT.md` with no link. Each was checked again on 2026-11-25 (UTC). The evidence, quoted and linked, is in the section named.

| # | Claim | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Filebeat states "at least once" and deletes only after the downstream side confirms. | **Partly wrong.** The statement is confirmed, and it is about the registry, a read position on a file Filebeat does not own: by default Filebeat deletes no source data, and the application or logrotate deletes it, which Filebeat names as a loss case. Where Filebeat does delete, the two triggers differ. A disk queue segment is deleted once the output has acknowledged all its events and the first of the next segment's, and the final segment only at shutdown, if every event was acknowledged. A source file with `delete.enabled` is deleted once the input's acknowledgement has run for all its events. The documentation calls this the output's acknowledgement; with the disk queue on, the code at `v9.5.7` runs it when the event is written to the queue, after a sync whose result it ignores. Either acknowledgement includes dropped events. | C3: [how-filebeat-works.md](https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/how-filebeat-works.md), [filebeat-input-filestream.md](https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/filebeat-input-filestream.md) |
| 2 | The OTel Collector's persistent queue deletes in the same step as the acknowledgement. | **Partly wrong.** The timing holds when storage works: the logical delete and the dispatched-list update are tried as one storage transaction, and only if that fails does the queue delete the item and then write the list in a second call, which can fail after the delete. But the step follows any finish, not only an acknowledgement: a permanent error and an exhausted retry budget delete too, an OTLP partial success deletes the whole request, its rejected part included, and only a shutdown error leaves the item for a restart, which puts it back unless reading, decoding or writing it again fails. An item that cannot be read or decoded as it is taken from the queue is deleted before any export. Disk space comes back only by compaction, off by default. | C4: [persistent_queue.go](https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go) |
| 3 | Vector deletes after confirmation when acknowledgements are on. | **Partly wrong.** A data file the writer has moved past is deleted once every record read from it is finalized, and finalization includes a failure or a drop. It does not depend on `acknowledgements.enabled`: end-to-end acknowledgements stop at the disk buffer. Since `v0.58.0` the physical delete is a background task. | C5: [ledger.rs](https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/ledger.rs), [writer.rs](https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/writer.rs) |
| 4 | In-memory SDK buffers are at-most-once: OTel batch processors drop a failed export. | **Partly wrong.** The processor does drop a failed batch, and drops on a full queue. But the path is not at-most-once: the OTLP exporter must retry transient errors, and OTLP accepts the duplicates that follow as "a deliberate choice". | C7: [trace/sdk.md](https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/v1.63.0/specification/trace/sdk.md), [OTLP specification](https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md) |
| 5 | Pull sources keep their data: Prometheus purges nothing, and Kafka retains by time or size. | **Prometheus: true only in a narrow sense.** A client holds no rows waiting for collection, only current values, and a scrape resets nothing; the server deletes by time or size. **Kafka: confirmed**, with three exceptions: compaction, which retains the latest value for each key; `DeleteRecords`, which deletes below an offset its caller supplies; and the Kafka Streams repartition purge, which supplies its committed offset. | C8: [writing_clientlibs.md](https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md); C9: [storage.md](https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/docs/storage.md); C10: [introduction.md](https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/getting-started/introduction.md) |
| 6 | A per-producer sequence number (Kafka) is the only documented way to recognise a duplicate. | **Wrong.** Documented alternatives: an id the sender assigns (NATS `Nats-Msg-Id`, or the subject under discard-new-per-subject; SQS FIFO; Azure Service Bus `MessageId`; Elasticsearch `_id`; MQTT's packet id within one exchange), content (Elasticsearch time series data streams, SQS content-based deduplication, Prometheus series and timestamp), a position in the sender's log that the receiver may record (PostgreSQL LSN), and Kafka's own handbook on the consuming side (a primary key, or the offset stored with the output). Pulsar is a per-producer sequence, but keeps two high marks, persisted and pushed, rather than a window of batches, and allows holes. | C13: [model_deep_dive.md](https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/using-nats/jetstream/model_deep_dive.md); O5: [API_SendMessage](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html); O3, O4, O6, O8, C9, C14, C11, C12 |
| 7 | Nobody documents an asynchronous purge except in the Kafka style, where deletion is decoupled from reading. | **Wrong.** Purges off the confirming path are documented by Vector (a background scan, every second by default, that retries a failed delete), the libbeat disk queue (a separate deleter), Filebeat's `delete.enabled` (a grace period), Pulsar (a whole ledger at a time, once the ledger holding the message is closed and the slowest durable cursor has passed it, by a background trim), PostgreSQL (at a checkpoint), Google Cloud Pub/Sub (asynchronously, once every subscription has acknowledged, where no retention keeps the message longer) and Kafka Streams (purging its repartition topics up to the committed offset, on an interval). Kafka's `DeleteRecords` deletes, off the reading path, below an offset its caller supplies; KIP-107 added it so that data could be deleted once consumed. NATS interest streams may defer a purge "for performance reasons" after the last interested consumer is removed; and in a clustered stream an acknowledgement that leaves no interest leads to a delete proposed to the replicas and applied after it; its file store also leaves the physical cleanup of a message deleted out of order, unless it compacts the block at once, to a periodic sync. The Prometheus agent truncates on a timer that consults what was sent. | C5, C3, C12, C13, C14, C10, C9, O7 |
| 8 | Unverified at the time: Fluent Bit's and Vector's exact delete trigger. | **Now verified from source.** Fluent Bit unlinks a chunk file synchronously when its task is released: all outputs done, no retries pending, which covers success, error, an exhausted retry and a retry the scheduler could not schedule. "Done" is the output plugin's return to the engine, not the destination's receipt: unless its buffered file has reached its upload size or timeout, the S3 output returns `FLB_OK` once the chunk is in its own buffer, whose file it deletes once the file is uploaded, whole or as one part of a multipart upload, or once its retries are exhausted, if `retry_exhausted_action` is `delete` or, under the default `quarantine`, if the quarantine is full or the move fails. Vector completes a data file logically when the writer has moved past it and every record read from it is finalized, and a background scan, every second by default, deletes it physically, retrying at a later scan if a delete fails or the process exits first. | C6: [flb_task.h](https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/include/fluent-bit/flb_task.h); C5 |

## Summary

| System | When buffered data is deleted | Delete in the same step as the confirmation? | How a repeat is recognised | What the receiving side remembers, and for how long | Stated why found? |
| --- | --- | --- | --- | --- | --- |
| C1 Kafka idempotent producer | n/a (retention, C10) | n/a | PID, epoch and per-partition sequence; a retry matched against the last 5 batches | Partition leader: per PID; 1 day after the last write with no transaction open (`producer.id.expiration.ms`) | Yes (KIP-98, its design document, KIP-360, KIP-854) |
| C2 RFC 9562 UUIDv7 | n/a | n/a | n/a: an identifier, not a delivery mechanism | n/a | Yes, for time order and index locality, and for entropy over v1 and v6; none for one id per run |
| C3 Filebeat / libbeat | Source file: never by default; with `delete.enabled`, after the input's acknowledgement (with the disk queue on, the write to the queue) and a 30-minute grace period. Disk queue segment: once the output has acknowledged all its events and the first of the next segment's; the final segment only at shutdown, if every event was acknowledged | No: a separate deleter; a grace timer | Not recognised; the docs push an id to the receiver (O3) | Elasticsearch: the document id, while the document exists | Partly (PR threads) |
| C4 OTel Collector persistent queue | On any finish: success, permanent error, exhausted retries; also when an item cannot be read or decoded as it is taken, or put back at a restart | Logical: yes, one local storage transaction once the exporter returns, or two calls if that transaction fails. Physical: only on compaction | Not recognised | Nothing | Partly (issue #2285, design document; PR #9090 for an exhausted retry); none for a permanent error beyond OTLP's rule |
| C5 Vector disk buffer v2 | Once the writer has moved past a data file and every record read from it is finalized, whatever its status; the file being written stays | No: a background scan, every second by default; a failed delete is retried at a later scan | Not recognised | Nothing | Yes (issue #7065, RFCs, code comments) |
| C6 Fluent Bit | When the task is released: success, error, exhausted retry, or a retry that could not be scheduled, where success is the plugin's return, which for S3 usually precedes the upload, S3's own buffer file then going once it is uploaded, whole or as one part of a multipart upload, or on an exhausted retry when it is not quarantined, bounded by `store_dir_limit_size`; evicted at `storage.total_limit_size` in a fixed order of steps, oldest first within an input but not across inputs | Yes, synchronous | Not recognised | Not addressed | Partly (issue #2408); none for the engine deleting on failure; a code comment on S3's terminal cleanup |
| C7 OTel SDK batch processor | When the batch is taken for export, whatever the outcome; on a full queue | n/a: nothing is kept | None in the protocol; a span carries a required trace id and span id; an idempotency key was proposed and not merged | Nothing | Yes (performance principles, OTLP specification, PR #219) |
| C8 Prometheus client | Never: holds only current values | n/a | n/a | n/a | Yes, for the pull model, and for cumulative counters from a core contributor's post (2016); a later stated benefit in a PromCon 2023 talk abstract |
| C9 Prometheus server | TSDB: by time or size. WAL: at head compaction (server) or on a 2-hour timer (agent) | No | Series and timestamp, for an in-order sample: identical repeat accepted, different value refused | The newest in-order sample per series | Partly: a purpose for retention and WAL truncation; none for the 15-day default or for truncating regardless of remote write |
| C10 Kafka retention | By time or size, or by key; below an offset a caller supplies (`DeleteRecords`), which the Streams purge sets from its committed offsets | No: a 5-minute task, then a 60 s file delay | n/a | n/a | Yes (design handbook, KIP-107, KIP-811, a code comment) |
| C11 Kafka consumer offsets | Nothing, in plain Kafka | n/a | On the consuming side: a primary key, or the offset stored with the output | For a repeat: the output, which keeps the primary key or the offset stored with it, for as long as it keeps them. The group coordinator keeps the committed offset, a restart point, by default until 7 days after the group empties, or 7 days after the last commit for a consumer with manual assignment; C11 lists the other terms | Yes (design handbook) |
| C12 Pulsar | Once every durable subscription acknowledges, or a TTL acknowledges it on expiry; a retention policy can keep acknowledged messages longer; storage a whole ledger at a time, once the ledger holding it is closed, by a background trim, which a deduplication cursor also holds back | No | Producer name and two high marks, persisted and pushed; a sequence between them is answered as unknown | Broker: 6 hours after the producer disconnects | Partly (PIP-6) |
| C13 NATS JetStream | Work queue: on acknowledgement, a termination (`AckTerm`) included. Interest: once all interested consumers acknowledge or terminate | In the code at `v2.15.3`: yes on a single server, in the acknowledgement handler, though reclaiming the space of a message removed out of order is mostly left to a periodic sync; no in a cluster, where the delete is proposed to the replicas and applied later. Possibly deferred after the last interested consumer is deleted | `Nats-Msg-Id` within a window | Server: 2 minutes by default | Partly; none for the window |
| C14 PostgreSQL replication slot | WAL kept until no slot needs it; removed at a checkpoint; capped by `max_slot_wal_keep_size` | No | The client may record the last LSN it saw and skip repeats | The receiver (replication origins) | Yes (documentation, commit c655077, code comments) |

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

  The producer does not always treat that rejection as fatal. Without a `transactional.id`, the producer at 4.4.0 retries an out-of-sequence error, bumping its epoch where it finds a real gap, and its documentation says it may go on sending, at the cost of order:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/KafkaProducer.java

  > It is a similar picture when idempotence is enabled, but no <code>transactional.id</code> has been configured.

  > Additionally, it is possible to continue
  >  * sending after receiving an {@link org.apache.kafka.common.errors.OutOfOrderSequenceException}, but doing so
  >  * can result in out of order delivery of pending messages.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/internals/TransactionManager.java

  > // For the idempotent producer, retry all OUT_OF_ORDER_SEQUENCE_NUMBER errors. If there are no
  > // unresolved sequences, or this batch is the one immediately following an unresolved sequence, we know
  > // there is actually a gap in the sequences, and we bump the epoch. Otherwise, retry without bumping
  > // and wait to see if the sequence resolves

- **Is the sequence also an acknowledgement or a read position?** No source says so. The produce response returns offsets, and consumers track offsets, never sequences (C11). Looked in: the KIP-98 page, its design document, `design.md`, `ProducerAppendInfo.java`, `ProducerStateEntry.java`, `UnifiedLog.java` and KAFKA-5494. Inferred: the sequence is a device between one producer and one partition leader, for recognising a retry and detecting a gap.
- **The five batches** follow from the producer's in-flight limit:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerConfig.java

  > because broker only retains at most 5 batches for each producer. If the value is more than 5, previous batches may be removed on broker side.

  > Idempotence is enabled by default if no conflicting configurations are set.

- **What the broker remembers, and for how long.** Per partition and PID: the epoch, the sequence range of up to the last five batches, and the last offset. After a restart the state is rebuilt from a snapshot, which restores one batch per producer, and then by replaying the log written after the snapshot, which adds the batches found there:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerStateManager.java

  > stateEntry.addBatch(producerEpoch, lastSequence, lastOffset, offsetDelta, timestamp);

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/UnifiedLog.java

  > loadProducersFromRecords(producerStateManager, fetchDataInfo.records);

  The design document linked from KIP-98:

  Source: https://docs.google.com/document/d/1Sc8qlnc3K1OlOmDhs8YHZrndyvnFzZs2IAmklJ4wWJE/export?format=txt

  > For each topic partition, the broker will maintain a mapping in memory from the PID to the epoch, sequence number, the last offset successfully written to the log, and the coordinator epoch from each producer (for transactional producers). The source of truth for this information is always the log itself.

  > It would be undesirable to let the PID-sequence map grew indefinitely, so we need a mechanism for PID expiration. We expire producerId’s when the age of the last message with that producerId exceeds the transactionalId expiration time or the topic’s retention time, whichever happens sooner.

  Today `producer.id.expiration.ms` defaults to one day and `transactional.id.expiration.ms` to seven:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/transaction-coordinator/src/main/java/org/apache/kafka/coordinator/transaction/TransactionLogConfig.java

  > public static final int PRODUCER_ID_EXPIRATION_MS_DEFAULT = 86400000;

  > Note that producer IDs may expire sooner if the last write from the producer ID is deleted due to the topic's retention settings.

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/transaction-coordinator/src/main/java/org/apache/kafka/coordinator/transaction/TransactionStateManagerConfig.java

  > public static final int TRANSACTIONAL_ID_EXPIRATION_MS_DEFAULT = (int) TimeUnit.DAYS.toMillis(7);

  A producer with a transaction open does not expire:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerStateManager.java

  > return producerState.currentTxnFirstOffset().isEmpty() && currentTimeMs - producerState.lastTimestamp() >= producerStateManagerConfig.producerIdExpirationMs();

- **A producer restart** gets a new PID unless it sets a `transactional.id`:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=217392092

  > Producer IDs, when not associated to a transaction, will be created every time the producer restarts.

- **When the broker's state is gone** (retention, `DeleteRecords` or expiry), the leader accepts a client's next write with any sequence, except for one case added for transactions version 2:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerAppendInfo.java

  > If there is no current producer epoch (possibly because all producer records have been deleted due to

  > retention or the DeleteRecords API) accept writes with any sequence number

  > // For transactions v2 idempotent producers, reject non-zero sequences when there is no producer ID state

  Kafka's tests at 4.4.0 show it on the plain path, with no transaction and no verification entry: once a producer's state has expired, its next write is accepted with a nonzero sequence. The tests drive the producer state manager directly, not a running broker. That is the case the design document says the broker must reject (quoted under the stated why).

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/test/java/org/apache/kafka/storage/internals/log/ProducerStateManagerTest.java

  > // we should accept the append and add the pid back in

  > stateManager.removeExpiredProducers(time.milliseconds());
  >         appendClientEntry(stateManager, producerId, epoch, defaultSequence + 1, 2L, false);

  > private final int defaultSequence = 0;

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

  The code at 4.4.0 adds two more statements, also not reconciled with each other or with those two. The class comment says producer ids can expire once the last written entry has been deleted from the log. The comment on `truncateAndReload` says the broker deletes snapshots before the log start and keeps the producer state in memory, and that state not in a snapshot is lost on a failover or an unclean shutdown:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/ProducerStateManager.java

  > However, producer ids can be expired due to lack of recent use or if the last written entry has been deleted from

  > We delete snapshot files prior to the logStartOffset but do not remove
  >  * producer state from the map. This means that in-memory and on-disk state can diverge, and in the case of
  >  * broker failover or unclean shutdown, any in-memory state not persisted in the snapshots will be lost, which
  >  * would lead to UNKNOWN_PRODUCER_ID errors.

- KIP-679 made idempotence the default, and KIP-854 gave producer ids their own, shorter expiry:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=165221843

  > The producer should enable the strongest message delivery guarantee by default.

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=217392092

  > it may be useful to have a separate timeout for producer IDs to avoid excess memory usage in this map

**Constraints.** Idempotence holds per partition and per producer session. A `transactional.id` carries transaction recovery across sessions: a new instance completes or aborts what the previous one left open. The producer's documentation says a record the application sends again cannot be de-duplicated:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/KafkaProducer.java

> To take advantage of the idempotent producer, it is imperative to avoid application level re-sends since these cannot
>  * be de-duplicated.

> The purpose of the <code>transactional.id</code> is to enable transaction recovery across multiple sessions of a
>  * single producer instance.

> Ensures any transactions initiated by previous instances of the producer with the same
>      *      {@code transactional.id} are completed. If the previous instance had failed with a transaction in
>      *      progress, it will be aborted.

The state lives on the partition leader and is replicated through the log. The guarantee assumes `acks=all`, retries and at most five requests in flight. A broker cluster serves thousands of producers, and the receiving side, not the producer, does the checking.

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

- UUIDs answer the cost of coordinating sequential keys across a network, and time-ordered versions answer as well the poor index locality of versions that are not (§2.1):

  > In such cases, "auto-increment" schemes that are often
  > used by databases do not work well: the effort required to coordinate
  > sequential numeric identifiers across a network can easily become a
  > burden.

  > The fact that UUIDs can be used to create unique, reasonably
  > short values in distributed systems without requiring coordination
  > makes them a good alternative,

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

- The embedded timestamp, in conjunction with an embedded counter, signals the order of creation, and UUIDs must not be used as security capabilities (§8):

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

- **(c) The disk queue (`queue.disk`)**, optional; the memory queue is the default. A segment file is deleted once every frame in it has been acknowledged by the output, which the acknowledgement code detects only when an acknowledgement reaches the first frame of the next segment. It cannot detect the end of the final segment, so the core loop deletes that one only at shutdown, and only if every event written to the queue was acknowledged. The acknowledgement path only writes the position of the oldest unacknowledged frame and signals the core loop, which hands the segments to a separate deleter goroutine. Physical deletion is therefore asynchronous to the acknowledgement. On restart, reading resumes at the saved position, so some frames are sent twice.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/acks.go

  > // if the application terminates before all frames have been acknowledged,
  > // the next session will restart at the first missing frame. This means
  > // some later frames may be transmitted twice in this case, but it
  > // guarantees that we don't drop any data.

  > // This means it can't detect the end of the final segment, so that case
  > // is handled diskQueue.handleShutdown.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/core_loop.go

  > // First check for the rare and fortunate case that every single event we
  > // wrote to the queue was ACKed. In this case it is safe to delete
  > // everything up to and including the current segment. Otherwise, we only
  > // delete things before the current segment.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/deleter_loop.go

  > // When one or more segments are ready to delete, they are sent to
  > // requestChan. At most one deleteRequest may be outstanding at any time.

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/configuring-internal-queue.md

  > Each segment contains some number of events waiting to be sent to the outputs, and is deleted when all its events are sent.

- **With the disk queue on,** the input's acknowledgement fires once the frame is written to the queue and a sync has been tried, not when the output confirms it. The queue's contract allows either:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/queue.go

  > // When the queue decides it is safe to progress (events have been ACKed by
  > // consumer or flush to some other intermediate storage), it will send an ACK signal
  > // with the number of ACKed events to the Producer (ACK happens in batches).

  The disk queue's writer tries to sync the segment file, ignores the result, and then acknowledges to each producer:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/queue/diskqueue/writer_loop.go

  > // Try to sync the written data to disk.
  > _ = wl.outputFile.Sync()

  > // Notify any producers with ACK listeners that their frames were written.

  > producer.config.ACK(ackCount)

  The pipeline hands that callback to the input's acknowledgement handler. The handler runs the registry update and releases the event's hold on the file, and the delete check waits for those holds:

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/publisher/pipeline/pipeline.go

  > ackHandler.ACKEvents(count)

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/filebeat/input/filestream/internal/input-logfile/publish.go

  > op.resource.UpdatesReleaseN(n)

  Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/filebeat/input/filestream/input.go

  > // We can only try deleting the file if all events have been published.

  > if !cursor.AllEventsPublished() {

  So with `queue.disk` the registry offset, and with it the `delete.enabled` condition, advances when an event is written to the disk queue, not when the output confirms it. The queue then holds the event until the output does. The documentation's condition, "All events have been acknowledged by the output", does not say this.

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

- Each request is a key in a storage extension, usually `file_storage` (bbolt). When a consumer finishes a request, the queue removes its index from the dispatched list and deletes the item in one `Batch` call, which `file_storage` runs as one bbolt transaction. If that call fails, the queue deletes the item first and writes the dispatched list in a second call, and reports when the second call fails after the delete. So the logical delete is in the same step as the outcome when the combined call succeeds.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > // The items currently dispatched by consumers are not deleted until the processing is finished.

  > setOp := storage.SetOperation(metadataKey, metadataBytes)
  > deleteOp := storage.DeleteOperation(getItemKey(index))
  > err = pq.client.Batch(ctx, setOp, deleteOp)

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-contrib/v0.166.0/extension/storage/filestorage/client.go

  > return normalizeStorageError(c.db.Update(batch))

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > if err = pq.client.Batch(ctx, deleteOp); err != nil {

  > return fmt.Errorf("failed updating currently dispatched items, but deleted item successfully: %w", err)

- **The outcome is any finish, not only a success.** The delete runs whatever the result, except a shutdown error: a permanent error and an exhausted retry budget (`max_elapsed_time`, 300 s by default) delete too.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > // The queue is shutting down, don't mark the item as dispatched, so it's picked up again after restart.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/retry_sender.go

  > // Immediately drop data on permanent errors.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/README.md

  > - `max_elapsed_time` (default = 300s): Is the maximum amount of time spent trying to send a batch; ignored if `enabled` is `false`. If set to 0, the retries are never stopped.

  > If the collector instance is killed while having some items in the persistent queue, on restart the items will be picked and the exporting is continued.

- **A partial success counts as a success.** OTLP lets a server accept part of a request and reject the rest in a response that is not an error, and forbids the client to retry it. The Collector's OTLP exporter at `v0.166.0` logs the rejected count and returns no error, so the queue deletes the whole request:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md

  > If the request is only partially accepted
  > (i.e. when the server accepts only parts of the data and rejects the rest), the
  > server response MUST be the same

  > The client MUST NOT retry the request when it receives a partial success
  > response where the `partial_success` is populated.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/otlpexporter/otlp.go

  > e.settings.Logger.Warn("Partial success response",

  > zap.Int64("dropped_spans", resp.PartialSuccess().RejectedSpans()),

- **The physical delete is deferred.** bbolt does not shrink its file; space comes back only by compaction, which is off by default:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-contrib/v0.166.0/extension/storage/filestorage/README.md

  > - `compaction.on_rebound` (default: false), which happens online when certain criteria are met; it's discussed in more detail below

- **Repeats.** Not recognised. After a crash or a shutdown, an item sent but not yet removed is put back at the next start: the queue reads every such item, deletes it, and writes it again at the back of the queue. The delete runs whether or not the read succeeded, and before the write, so an item whose read, decode or re-write fails is lost. An item whose read or decode fails as it is taken from the queue is deleted before any export. The README states no "at least once" guarantee (a search for "at least" and "at-least" found nothing).

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > // retrieveAndEnqueueNotDispatchedReqs gets the items for which sending was not finished, cleans the storage
  > // and moves the items at the back of the queue.

  > cleanupErr := pq.client.Batch(ctx, cleanupBatch...)

  > if pq.putInternal(reqCtx, req) != nil { //nolint:contextcheck

  > // We need to make sure that currently dispatched items list is cleaned

**Stated why.**

Source: https://github.com/open-telemetry/opentelemetry-collector/issues/2285

> Currently, collector buffers all data in memory, which can lead to data loss in case buffer gets overfilled (e.g. during temporary exporter connection issues) or due to a sudden crash.

> For example, exporter could buffer the incoming data on disk (up to the defined limit) and clear the buffer as data gets sent out.

The design document linked from PR #3274, which its authors have since marked outdated, gives the delete rule and why the queue sits in the exporter:

Source: https://docs.google.com/document/d/1Y4vNthCGdYI61ezeAzL5dXWgiZ73y9eSjIDitk3zXsU/export?format=txt

> when a record was successfully exported, it is removed from the WAL (or marked as such via a tombstone)

> It simplifies the design considerably, as queued_retry already knows the outcome of sending a given batch and has a memory-backed queue.

For a permanent error, OTLP's specification requires an OTLP client to drop data the server will not take, and gives bad data as its example; it states a rule and an example, not a reason, and does not govern the queue for other exporters.

Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md

> - Non-retryable errors indicate that telemetry data processing failed, and the
>   client MUST NOT retry sending the same telemetry data. The client MUST drop
>   the telemetry data.

For deleting after an exhausted retry budget, PR #9090 (merged 2023-12-15) states the why. Until then the persistent queue put a request whose retries had failed back in the queue. The PR removed that, so the retry policy alone decides how long a request is tried, and `max_elapsed_time` 0 retries forever. The issue behind it asked for one setting the user controls, and the PR's author did not know why the re-enqueueing had been added:

Source: https://github.com/open-telemetry/opentelemetry-collector/pull/9090

> The current re-enqueuing behavior is not obvious and cannot be configured.

> This change removes the re-enqueuing behavior in favor of the `retry_on_failure` option. Consider increasing `retry_on_failure::max_elapsed_time` to reduce chances of data loss.

Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382

> So why not keep it simple and Let the user decide how long a request can be retried at most?

Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1718148081

> I don't know why it was introduced in the first place.

Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1848779175

> If a request cannot be delivered right now, why do we need to put it back to the queue and try another one instead of increasing the backoff timeout and re-trying the same request again?

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

- The removal in PR #9090 was disputed in issue #8382. A contributor answered that users expect no data to be dropped while the queue has room, then agreed once a long `max_elapsed_time` was named as the equivalent. A user asked whether persistent-queue users lose performance; the PR's author answered that memory is bounded by the number of queue workers either way:

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1719017233

  > Requeueing as implemented is how a lot of users intuitively expect the queue to work, in my experience. That is, they expect no data to be dropped if the queue still has room.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1849811867

  > thinking about it more, reenqueueing is logically equivalent to retrying forever. As long as we document that users who want that behaviour should instead set `max_elapsed_time` to some large value, I think it's ok to remove it.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1852486641

  > But performance speaking, not having reenqueue looks like a huge hit for persistent queue users?

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1852517892

  > The amount of data kept in memory is always restricted by the number of queue workers.

### C5. Vector: disk buffer v2 and end-to-end acknowledgements

**Bears on:** purge only after confirmation, and an asynchronous purge. vectordotdev/vector `v0.62.0`, with `v0.50.0` and `v0.57.0` for history.

**What it does.**

- Records go to append-only data files of up to 128 MiB. A data file is logically complete once the writer has moved on to a later file and every record read from it has been finalized; a background task, woken every second, then deletes it. The file the writer is still writing stays: at its end the reader waits for the writer rather than rolling past it, and the scan skips every file from the reader's checkpoint to the writer's. Physical deletion is asynchronous to the acknowledgement:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/mod.rs

  > //! When all records from a data file have been fully acknowledged, the data file is scheduled for
  > //! deletion. We only delete entire data files, rather than truncating them piecemeal, which reduces
  > //! the I/O burden of the buffer.

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/ledger.rs

  > /// Deletes data files that are outside the durable reader/writer checkpoint window.

  > /// The reader advances the durable reader file checkpoint as soon as a data file's records are
  > /// fully acknowledged. Physical deletion can then happen asynchronously: if deletion fails or
  > /// the process exits first, this scan will retry later.

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/common.rs

  > pub const DEFAULT_DATA_FILE_CLEANUP_INTERVAL: Duration = Duration::from_secs(1);

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/lib/vector-buffers/src/variants/disk_v2/reader.rs

  > if reader_file_id != writer_file_id {

  > self.ledger.wait_for_writer().await;

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
- Before the change, a TODO in the reader's function that deleted the file inline asked whether the delete could become a background task, to take its tail latency off the read path. It is a question in the code, not the reason for PR #25845: no reason for the move was found in that pull request's description, commit messages, review comments, reviews or issue comments.

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.57.0/lib/vector-buffers/src/variants/disk_v2/reader.rs

  > // TODO: Could we actually make this a background task to remove the tail latency from the
  > // read path?  Technically all that's needed is a handle to the ledger and the data file
  > // path, so as long as the logic is still right, we can notify writers out-of-band.

- Why a disk buffer at all, from the buffer improvements RFC:

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/rfcs/2021-10-14-9477-buffer-improvements.md

  > Effectively, these users turn to disk buffering to increase reliability of their Vector-based
  > observability pipelines.

- Why the buffer waits for delivery, the nearest statement found, from the end-to-end acknowledgement RFC: its motivation, and its case of a buffer that finalizes events once they are persisted, which must then purge them only once they are delivered. That the motivation is the reason for the wait is Inferred; the code at `v0.62.0` deletes on any finalization (above).

  Source: https://raw.githubusercontent.com/vectordotdev/vector/v0.62.0/rfcs/2021-03-26-6517-end-to-end-acknowledgement.md

  > Users want assurance that their data pipeline successfully delivers all the
  > events that are presented to it.

  > 1. Since the events will no longer be lost in the event of a crash, they
  >    may be finalized as soon as they are persisted to the buffer. In this
  >    case, buffer will handle the finalization, and the finalization data
  >    will be stripped before the event is serialized. However, the buffer
  >    will need to be modified to handle acknowledgement, and only purge
  >    events from the buffer once they are delivered.

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

- **The same release runs on success and on giving up:** on `FLB_OK`, on `FLB_ERROR`, on `FLB_RETRY` with retries disabled, once the retry limit, 1 by default, is reached, and when the scheduler cannot schedule a retry. A copy goes to a dead letter queue first, if one is enabled and a storage path is set; the engine discards the copy's result, so the release goes ahead whether or not the copy was written.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_output.c

  > instance->retry_limit = 1;

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/administration/scheduling-and-retries.md

  > When a chunk exhausts all retry attempts or retries are disabled, the data is discarded by default.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_engine.c

  > If for some reason the Scheduler could not include this retry,
  >          * we need to get rid of it, likely this is because of not enough
  >          * memory available or we ran out of file descriptors.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/administration/dead-letter-queue.md

  > - **Scheduler failures**: When the retry scheduler can't schedule a retry (for example, due to resource constraints).

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_engine.c

  > !config->storage_path ||

  > (void) flb_storage_quarantine_chunk(config, cio_ch, tag, status_code, out);

- **`FLB_OK` is the output plugin's answer, not the destination's.** Unless its buffered file has reached the upload size or the upload timeout, the S3 output copies the chunk into its own store directory and returns `FLB_OK`. The engine then releases the task, and the chunk file goes, before the upload. Its authors give the reason as S3's large uploads:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/plugins/out_s3/s3.c

  > /* Buffer current chunk in filesystem and wait for next chunk from engine */

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/pipeline/outputs/s3.md

  > S3's `flush` callback function buffers the incoming chunk to the filesystem, and returns an `FLB_OK`.

  > the `storage.total_limit_size` parameter isn't meaningful for S3 since it has its own buffering system in the `store_dir`.

- **S3's own buffer has its own delete and its own bound.** The S3 output deletes its buffer file once the file has been uploaded whole, or once it has been uploaded as one part of a multipart upload, before that upload is completed. A file whose uploads have failed past the output's retry limit is moved by default to a quarantine directory, unbounded by default; it is deleted instead when `retry_exhausted_action` is `delete`, when the quarantine has reached `quarantine_dir_limit_size`, or when the move fails (quoted below). `store_dir_limit_size` bounds that buffer, and at the limit data is discarded:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/plugins/out_s3/s3.c

  > ret = upload_part(ctx, m_upload, body, body_size, NULL);

  > m_upload->part_number += 1;
  > /* data was sent successfully- delete the local buffer */

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/pipeline/outputs/s3.md

  > You must use `store_dir_limit_size` to limit the space on disk used by S3 buffer files.

  > If the limit is reached, data will be discarded.

  The default action, the cases that delete, and the terminal cleanup's code comment, which says what that cleanup must release:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/plugins/out_s3/s3.c

  > FLB_CONFIG_MAP_STR, "retry_exhausted_action", "quarantine",

  > "'delete' (remove permanently) and 'quarantine' (move to quarantine and "

  > "retry-exhausted chunks are deleted. Default is 0 (unlimited)."

  > "could not quarantine, deleting retry-exhausted chunk");

  > * Terminal retry exhaustion must permanently remove local buffer files.
  >  * Unlike inactive state (recoverable/restart-resumable), terminal cleanup
  >  * must release store_dir_limit_size accounting and delete on-disk state.

- **`storage.total_limit_size`** caps the filesystem chunks routed to one output. When a new chunk would exceed it, space is freed in a fixed order of steps. Chunks the storage-backlog input has loaded are destroyed outright, even if they are routed to other outputs. Then chunks still waiting in that input's queue for this output are closed and deleted. Then come ordinary inputs, the arriving chunk's own input first and the others in configuration order, oldest first within each input. Chunks of an ordinary input go in two passes: first those routed to this output alone, which are destroyed; then the rest, which only lose this output's route, their file going once no route remains. Inferred from that order: an older chunk shared with another output can outlive a newer one routed to this output alone.

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/src/flb_input_chunk.c

  > if (flb_input_chunk_has_other_routes(ic, o_ins) == FLB_TRUE) {
  > return FLB_FALSE;
  > }

  > result = sb_release_output_queue_space(output_plugin,
  >                                                &required_space_remainder);

  > mk_list_foreach(iterator, &output_plugin->config->inputs) {

  > if (input_plugin_instance != new_input_chunk->in) {

  Source: https://raw.githubusercontent.com/fluent/fluent-bit/v5.2.0/plugins/in_storage_backlog/sb.c

  > cio_chunk_close(underlying_chunk, FLB_TRUE);

  The documentation states it more simply:

  Source: https://raw.githubusercontent.com/fluent/fluent-bit-docs/81af32b72509583c9ee9f5e60452e43fcd36c3e2/pipeline/buffering.md

  > If the output plugin reaches its `storage.total_limit_size` capacity, the oldest chunk from its queue will be discarded to make room for new data.

- **Repeats.** No mechanism found in the chunk or task code read. Inferred: a chunk retried after a partial success is sent whole again.

**Stated why.** The proposal behind the size limit (issue #2408, 2020):

Source: https://github.com/fluent/fluent-bit/issues/2408

> Fluent Bit already provides a secondary buffering mechanism based in the file system. It can be enabled per-ingestor plugin, so every record and chunk registered keeps a copy in the file system until it is fully delivered to the destination.

> - CUJ 1: I want my logs to be buffered locally if my network goes down for a couple of hours, so that I will not lose logs.

> - CUJ 3: I want to prevent the disk becoming full by buffering input chunks without limit so other applications cannot use the disk.

> Will drop the oldest log data chunks when offline buffer size exceeds this limit.

No stated rationale found for the engine deleting a chunk on `FLB_ERROR` or on an exhausted retry; the S3 output's comment on its own terminal cleanup, quoted above, says what that cleanup must release, not why the file is not kept. Looked in `src/flb_engine.c` and `include/fluent-bit/flb_task.h` at `v5.2.0`, `administration/scheduling-and-retries.md` and `pipeline/buffering.md` at the docs commit, issue #2408 with PRs #2435 and #2520, and discussion #11362, where a contributor advises a retry limit so that an offline output stops blocking a healthy one; that is advice to a user, not a reason for the rule.

**Constraints.** One agent process; buffering per input, limits per output; `Retry_Limit` 1 by default; an optional dead letter queue (`storage.keep.rejected`).

**Costs and dissent.**

- Output away: with the default retry limit, a chunk is discarded after one failed retry. With `no_limits`, files accumulate up to `storage.total_limit_size`, and then chunks are evicted in the order above: loss at the bound. With no limit, the disk can fill.
- The proposal says a copy is kept "until it is fully delivered"; the source also deletes on an error and on an exhausted retry. The discrepancy is reported, not reconciled.

## In-memory buffers

### C7. OpenTelemetry SDK batch processors, and OTLP

**Bears on:** purge only after confirmation, and a re-send that keeps its position. opentelemetry-specification `v1.63.0`, opentelemetry-proto `v1.11.1`, opentelemetry-python `v1.45.2`.

**What it does.**

- The batch processor holds finished spans or log records in a bounded in-memory queue, drops items when it is full, and drops a batch whose export fails. Nothing is persisted, and the processor identifies no repeat. The specification does not say which items a full queue drops; a search of `trace/sdk.md` at `v1.63.0` for "oldest" and "newest" finds neither.

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

- **In one implementation**, opentelemetry-python, the processor takes the batch off the queue before it exports and does not look at the result, so the batch is gone whatever the outcome. When the queue is full it drops the oldest record, not the new one. The gRPC exporter treats a deadline as retryable, a case in which the server may already have the data.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-python/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  > batch = [self._queue.pop() for _ in range(count)]

  > _logger.exception("Exception while exporting %s.", self._exporting)

  > Oldest records are at the back, so pop from there.

  > This will drop a log from the right side if the queue is at _max_queue_size.

  > self._queue.appendleft(data)

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-python/v1.45.2/exporter/opentelemetry-exporter-otlp-proto-grpc/src/opentelemetry/exporter/otlp/proto/grpc/exporter.py

  > StatusCode.DEADLINE_EXCEEDED,

- **OTLP accepts duplicates and defines no way to recognise them.** Acknowledgement is per hop:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/docs/specification.md

  > In edge cases (e.g. on reconnections, network interruptions, etc) the client has
  > no way of knowing if recently sent data was delivered if no acknowledgement was
  > received yet. The client will typically choose to re-send such data to guarantee
  > delivery, which may result in duplicate data on the server side. This is a
  > deliberate choice and is considered to be the right tradeoff for telemetry data.

  > End-to-end
  > delivery guarantees in such systems is outside of the scope of OTLP.

  A span does carry an identity, a trace id and a span id, both required and assigned when the span is created. No statement that a receiver uses them to recognise a repeat was found in `docs/specification.md` or `opentelemetry/proto/trace/v1/trace.proto` at `v1.11.1`.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-proto/v1.11.1/opentelemetry/proto/trace/v1/trace.proto

  > // A unique identifier for a span within a trace, assigned when the span
  > // is created.

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

  The same issue names language-specific disk buffers in opentelemetry-java-contrib (`disk-buffering`) and in Swift; the Swift one is described after the Java one. The Java module at `v1.60.0`, by default, deletes each item its reader has taken once the reader asks for another, without seeing the export's outcome. Configured otherwise, it deletes an item only when the reader removes it, for example after a successful export. Size and age limits purge files in either mode:

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-java-contrib/v1.60.0/disk-buffering/README.md

  > By default, items are automatically deleted from disk as the iterator advances.

  > If you need more control (e.g., only deleting items after a successful network export), set
  > `deleteItemsOnIteration` to `false` in the configuration:

  > Note that even with explicit deletion, disk usage is still bounded by the configured max folder size and max file
  > age, so stale files are automatically purged when there's not enough space available before new data is written.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-java-contrib/v1.60.0/disk-buffering/src/main/java/io/opentelemetry/contrib/disk/buffering/internal/storage/StorageIterator.java

  > if (deleteOnIteration) {
  > currentResult.delete();

  A component owner named in the README gave the default's reason, and the author of the issue the objection to it:

  Source: https://github.com/open-telemetry/opentelemetry-java-contrib/issues/2540#issuecomment-3742917442

  > I thought a lot about this and decided to go with deleting on `next()` by default based on the existing use case in OTel Android, where we deleted items before polling the next one, though in hindsight it's still an opinionated choice that might not suit other use cases.

  Source: https://github.com/open-telemetry/opentelemetry-java-contrib/issues/2540

  > its [`next` method](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Iterator.html#next()) has a side-effect, namely that it deletes a file from the disk.

  The Swift persistence exporter at `2.6.0` states its goal as an environment that "can't guarantee stable export". Its export worker deletes a batch file once the export has not failed, and otherwise keeps it and lengthens the delay before the next try. The span, log and metric decorators each report a failure as needing a retry, a check PR #1030 (merged 2026-01-09) added to the span decorator. Size and age limits delete files whatever was exported: the oldest files once the directory is too big, and a file too old to read. Its authors run the size purge only when a new file is created, because it is "a memory-expensive operation":

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-swift/2.6.0/Sources/Exporters/Persistence/README.md

  > The goal is to allow dealing with situations where telemetry data is generated in an environment that can't guarantee stable export.

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-swift/2.6.0/Sources/Exporters/Persistence/Export/DataExportWorker.swift

  > // Delete or keep batch depending on the export status
  >         if exportStatus.needsRetry {

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-swift/2.6.0/Sources/Exporters/Persistence/PersistenceSpanExporterDecorator.swift

  > return DataExportStatus(needsRetry: result == .failure)

  Source: https://github.com/open-telemetry/opentelemetry-swift/pull/1030

  > Now checks the export result and sets needsRetry: result == .failure

  Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-swift/2.6.0/Sources/Exporters/Persistence/Storage/FilesOrchestrator.swift

  > /// Removes oldest files from the directory if it becomes too big.

  > if fileAge > performance.maxFileAgeForRead {

  > // NOTE: As purging files directory is a memory-expensive operation, do it only when we know
  >       // that a new file will be created.

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

Why counters are cumulative and not reset by a scrape: the documentation states no reason (looked in `docs/concepts/metric_types.md`, `docs/instrumenting/writing_clientlibs.md`, `docs/practices/instrumentation.md`, `docs/introduction/faq.md` and `docs/introduction/overview.md` at `31957d4`). A post by Brian Brazil (2016-04-08), whom the project's blog names as one of its core contributors, sets out two alternatives and their failures, then the approach Prometheus takes:

Source: https://www.robustperception.io/how-does-a-prometheus-counter-work/

> The first is that on a regular basis, such as once a minute, you extract the current value which goes to you monitoring system, and reset the counter to 0.

> This has a problem in that if the push fails, then you lose all information about that time period.

> Additionally, if you've two systems pulling data from the counter for redundancy, each will only see about half the increments.

> This can handle multiple Prometheus servers taking samples, and if a scrape fails you'll lose resolution but not data as on the next successful scrape the increments haven't been lost or averaged away.

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/blog/posts/2016-01-26-one-year-of-open-prometheus-development.md

> one of our core contributors ([Brian
> Brazil](https://github.com/brian-brazil)) has recently founded his own company,

A later benefit of the cumulative value is stated in the abstract of a PromCon EU 2023 talk by Arthur Silva Sens and Bartłomiej Płotka, both on the Prometheus steering committee as https://prometheus.io/governance/ lists it today; it does not address a scrape that resets nothing:

Source: https://promcon.io/2023-berlin/talks/when-my-counter-restarted-addressing-decade-old-counter-limitation-with-created-timestamps/

> Thanks to cumulative characteristics and simple semantics, they allow cheap and reliable rate calculations, even with missed scrapes.

**Constraints.** Per-series state only; values between scrapes are not kept. The documentation states the limit that follows:

Source: https://raw.githubusercontent.com/prometheus/docs/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/introduction/overview.md

> If you need 100%
> accuracy, such as for per-request billing, Prometheus is not a good choice, as
> the collected data will likely not be detailed and complete enough.

**Costs and dissent.** The Pushgateway is recommended only for service-level batch jobs (quoted above). It is a push cache, not a buffer of rows: it keeps the last metrics pushed for each group until a later push replaces them or they are deleted through its API, and by default it keeps nothing across its own restart.

Source: https://raw.githubusercontent.com/prometheus/pushgateway/v1.11.5/README.md

> `PUT` is used to push a group of metrics. All metrics with the
> grouping key specified in the URL are replaced by the metrics pushed
> with `PUT`.

> A `PUT` request with an empty body effectively deletes all metrics with the
> specified grouping key.

> By default, Pushgateway does not persist metrics.

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

- **In agent mode** the WAL is truncated on a timer, every two hours by default. The cut-off is a timestamp: `MinWALTime` (5 minutes) behind the slowest remote-write queue's highest *sent* timestamp, moved forward to no more than `MaxWALTime` (4 hours) behind the current time even while remote write is stalled, and back to at least `MinWALTime` behind the current time. So a queue stalled for longer than `MaxWALTime` no longer has `MinWALTime` kept behind what it sent. The cut-off bounds what a truncation may drop, not what stays on disk, and it applies only within the segments a truncation checkpoints. Each truncation starts a new segment, leaves out the one that was being written, checkpoints at most the lower two-thirds of the rest, dropping from them the samples below the cut-off, and deletes those segments. So the purge is asynchronous and time-driven, and consults remote-write progress only in part.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/agent/db.go

  > DefaultTruncateFrequency = 2 * time.Hour

  > ts := walTruncationTime(db.opts, db.rs.LowestSentTimestamp(), timestamp.FromTime(time.Now()))

  > // Keep at most MaxWALTime of data, even if remote write is stalled.

  > ts := max(lowestSentTs-opts.MinWALTime, 0)

  > ts = max(ts, nowTS-opts.MaxWALTime)

  > // Keep at least MinWALTime of data, even if lowestSentTs is in the future.

  > return min(ts, max(nowTS-opts.MinWALTime, 0))

  > last-- // Never consider most recent segment for checkpoint

  > // The lower two-thirds of segments should contain mostly obsolete samples.

  > if err := db.wal.Truncate(last + 1); err != nil {

  With the default options, the checkpoint is `wlog.Checkpoint`:

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/wlog/checkpoint.go

  > // All series not satisfying keep, samples/exemplars below mint, tombstones not
  > // satisfying keep or with all intervals below mint, and metadata that are not the
  > // latest are dropped.

  "Sent" is not "confirmed": the mark advances once the send-with-backoff returns, and it returns early only when cancelled, so a send that ended in a non-retryable error advances it too.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/storage/remote/queue_manager.go

  > // When there is resharding, we cancel the context for this queue, which means the data is not sent.
  > // So we exit early to not update the metrics.

- Neither mode marks samples for the receiver. An accepted proposal for resuming from a savepoint, not yet implemented, asks receivers to tolerate the repeats a replay sends:

  Source: https://raw.githubusercontent.com/prometheus/proposals/80693eac6188612f2378ec1e2389f2c7379bc66b/proposals/0072-remote-write-restart-from-savepoint.md

  > The remote write destination must handle duplicate or out-of-order sample errors gracefully so these do not slow down delivery.

**Stated why.**

- For accepting exact duplicates, the code comment above (federation, and an error would be "extremely noisy"). For retention by time and size, the TSDB's maintainer (named for `tsdb` in `MAINTAINERS.md` at `v3.16.0`) gives its purpose, to limit how much is stored, and `docs/storage.md` advises a size limit below the allocated storage so that old data goes before the disk is full. No stated rationale found for the 15-day default, in `docs/storage.md` at `v3.16.0` or in that post.

  Source: https://ganeshvernekar.com/blog/prometheus-tsdb-compaction-and-retention/

  > TSDB allows setting retention policies to limit how much data you store in it.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/docs/storage.md

  > It is wise to reduce the retention size to provide
  > a buffer, ensuring that older entries will be removed before the allocated storage
  > for Prometheus becomes full.

  Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/MAINTAINERS.md

  > * `tsdb`: Ganesh Vernekar
- The agent's truncation is described by its author as best-effort cooperation with remote write (PR #8785):

  Source: https://github.com/prometheus/prometheus/pull/8785

  > Truncation of the WAL cooperates on a best-effort case with Remote Write. Every time the WAL is truncated, the slowest remote write queue is used for the minimum timestamp of truncation. This gives loose guarantees that data from the WAL will not try to be removed until the maximum WAL age passes or the slowest queue catches up.

- The savepoint proposal states both its motive and why the WAL must stay bounded:

  Source: https://raw.githubusercontent.com/prometheus/proposals/80693eac6188612f2378ec1e2389f2c7379bc66b/proposals/0072-remote-write-restart-from-savepoint.md

  > If a config is reloaded or prometheus/agent is restarted before flushing pending samples we will skip those samples.

  > 4. Guards need to be in place to protect against infinite WAL growth.

  > The amount of complexity in this goal is large, it is my opinion that our current state where all samples are lost is worse than implementing a replay which does not give us at-least-once delivery.

- Why the server truncates its WAL at all, from the same maintainer's post on the WAL:

  Source: https://ganeshvernekar.com/blog/prometheus-tsdb-wal-and-checkpoint/

  > We need to regularly delete the old WAL segments, else, the disk will eventually fill up and the startup of TSDB will take a lot of time as it has to replay all the events in this WAL (where most of it will be discarded because it’s old).

- Why the server truncates its WAL regardless of remote write: no stated rationale found. Looked in `docs/practices/remote_write.md`, PR #4588 (WAL-based remote write) with its review comments, issues #6333, #8809 and #20141, proposal 0072 and the maintainer's WAL post above; a GitHub issue search for WAL truncation and remote write returned nothing, while a control search for "remote write" did. Inferred: the server's WAL exists for crash recovery of the head block, so remote write reads a log it does not own, as Filebeat (C3) reads a file it does not own.

**Constraints.** The repeat check holds per series, against the newest in-order sample:

Source: https://raw.githubusercontent.com/prometheus/prometheus/v3.16.0/tsdb/head_append.go

> // This only checks against the latest in-order sample.

**Costs and dissent.**

- Size-based retention can briefly exceed its limit during compaction, as `docs/storage.md` says.
- A remote away for longer than the bound loses data: two hours for the server, by its documentation. For the agent at `v3.16.0` the bound is not a fixed time: the cut-off trails by at most `MaxWALTime`, four hours by default, and can trail by less: it is `MinWALTime` behind the slowest queue's highest sent timestamp where that is later, and a send that ended in a non-retryable error advances that mark too, as above, so a sample the remote never stored can fall below the cut-off before it is `MaxWALTime` old. A truncation runs on its timer, two hours by default, and drops only from the older two-thirds of the segments, as above. An operator's account of the trade-off, and the open work towards at-least-once:

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

- **Deletion that a consumer's progress can drive exists too, off the reading path.** KIP-107 added `DeleteRecords`, which moves a partition's log start offset to an offset its caller supplies; the call does not check that the records were consumed. Segments wholly below it are deleted later by the same retention task. Kafka Streams is the case driven by consumption: it sets infinite retention on its repartition topics and purges records up to the committed offset on its own interval (KIP-811):

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/admin/RecordsToDelete.java

  > Delete all the records before the given {@code offset}

  > Use {@code -1} to truncate to the high watermark.

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

  > It is important that we can delete this data soon after it is consumed by downstream application

  > If we set small time-based log retention for intermediate data, the data may be deleted even before it is consumed by downstream jobs. If we set large time-based log retention, the data will take large amount of disk space for a long time.

- Streams purges on an interval, not at every commit, for throughput:

  Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=199528229

  > this causes delete records requests to be sent extremely frequently, potentially reducing throughput and causing a high volume of log messages to be logged by the brokers.

- Why a renamed segment is deleted later, from the comment on the method that deletes it:

  Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/LocalLog.java

  > Asynchronous deletion allows reads to happen concurrently without synchronization and without the possibility of
  >  * physically deleting a file while it is being read.

  Why 60 seconds: no stated rationale found in `TopicConfig.java`, `ServerLogConfigs.java`, `LocalLog.java` and `design.md` at 4.4.0.

**Constraints.** A broker cluster serving many consumer groups, each with its own position. Retention does not wait for data to be read, and it is no promise to keep data for the full period. The configuration text calls `retention.ms` the "maximum time" a log is retained, and a size limit or `DeleteRecords` can remove data sooner:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/common/config/TopicConfig.java

> This configuration controls the maximum time we will retain a

> (which consists of log segments) can grow to before we will discard old log segments to free up space if we

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

Committed offsets themselves expire. The retention is seven days by default, counted from when a group empties, or from the last commit for a standalone consumer (one with manual assignment) or for a topic the group no longer subscribes to; deleting the group or the topic deletes them at once:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/group-coordinator/src/main/java/org/apache/kafka/coordinator/group/GroupCoordinatorConfig.java

> public static final int OFFSETS_RETENTION_MINUTES_DEFAULT = 7 * 24 * 60;

> 1) this retention period has elapsed after the consumer group loses all its consumers (i.e. becomes empty);

> 2) this retention period has elapsed since the last time an offset is committed for the partition and the group is no longer subscribed to the corresponding topic.

> For standalone consumers (using manual assignment), offsets will be expired after this retention period has elapsed since the time of last commit.

> Note that when a group is deleted via the delete-group request, its committed offsets will also be deleted without extra retention period;

What a consumer fetches carries marks apart from the records: the Fetch response gives each partition, beside its records, its high watermark, its last stable offset and its log start offset, among other fields:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/resources/common/message/FetchResponse.json

> { "name": "HighWatermark", "type": "int64", "versions": "0+",
>           "about": "The current high water mark." },

> { "name": "LastStableOffset", "type": "int64", "versions": "4+", "default": "-1", "ignorable": true,

> The last stable offset (or LSO) of the partition. This is the last offset such that the state of all transactional records prior to this offset have been decided (ABORTED or COMMITTED).

> "about": "The current log start offset." },

> { "name": "Records", "type": "records", "versions": "0+", "nullableVersions": "0+", "about": "The record data."}

**Stated why.** A per-message acknowledgement re-delivers anyway and costs the broker state for every message:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

> First of all, if the consumer processes the message but fails before it can send an acknowledgement then the message will be consumed twice. The second problem is around performance, now the broker must keep multiple states about every single message (first to lock it so it is not given out a second time, and then to mark it as permanently consumed so that it can be removed).

> There is a side benefit of this decision. A consumer can deliberately _rewind_ back to an old offset and re-consume data.

The handbook leaves recognising a repeat on the consuming side to the output, in two ways that are not a producer's sequence:

> In many cases messages have a primary key and so the updates are idempotent (receiving the same message twice just overwrites a record with another copy of itself).

> This can be handled more simply and generally by letting the consumer store its offset in the same place as its output.

**Constraints.** One consumer per partition per consumer group, which is what lets a single integer stand for what has been consumed. Kafka 4.4 also has share groups, in which consumers share a partition and records are acknowledged one by one:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/docs/design/design.md

> The consumers in a share group cooperatively consume records, and partitions may be assigned to multiple consumers.

> Records are acknowledged individually, though the system is optimized for batch processing to improve efficiency.

**Costs and dissent.** Everything after the last commit is re-delivered on failure. Automatic commits can run ahead of what was processed:

Source: https://raw.githubusercontent.com/apache/kafka/4.4.0/clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java

> If you fail to do either of these, it is possible for the committed offset
>  * to get ahead of the consumed position, which results in missing records.

## Deletion after confirmation, outside a buffer

### C12. Apache Pulsar: producer deduplication and acknowledgement-driven deletion

**Bears on:** recognising a repeat, purge only after confirmation, and an asynchronous purge. apache/pulsar at `8c04f6c`, apache/pulsar-site at `4b4a781`.

**What it does.**

- Deduplication keys on the producer's name and a sequence id. The design keeps the highest sequence id received per producer per topic, not a window of batches, and the application may choose the sequence, holes included. The broker at `8c04f6c` keeps two high marks per producer, one updated before a message is persisted and one after. A sequence at or below the persisted mark is a duplicate; one between the two marks is answered as unknown, and the producer retries later. It is off by default.

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pip/pip-6.md

  > Broker needs to keep a per-topic hash-map that keeps track of the highest
  > `sequenceId` received from each unique `producerName`.

  > This will allow the application to have custom sequence schemes, also with "holes" in the
  > middle. For example, if the producer is reading data from a file and publishing on a Pulsar
  > topic, it might want to use the offset in the file for a particular *record* as the sequence
  > id when publishing.

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/persistent/MessageDeduplication.java

  > if (lastSequenceIdPushed != null && sequenceId <= lastSequenceIdPushed) {

  > // If current message's seq id is between lastSequenceIdPersisted and
  > // lastSequenceIdPushed, then we cannot be sure whether the message is a dup or not
  > // we should return an error to the producer for the latter case so that it can retry at a future time

- The broker forgets a disconnected producer after six hours. It persists the high marks of at most 10,000 producers, a limit the code applies only when it builds the snapshot:

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/conf/broker.conf

  > # Time of inactivity after which the broker will discard the deduplication information
  > # relative to a disconnected producer. Default is 6 hours.
  > brokerDeduplicationProducerInactivityTimeoutMinutes=360

  > brokerDeduplicationEnabled=false

  > # Maximum number of producer information that it's going to be
  > # persisted for deduplication purposes
  > brokerDeduplicationMaxNumberOfProducers=10000

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/persistent/MessageDeduplication.java

  > if (snapshot.size() < maxNumberOfProducers) {

- A message is kept until every durable subscription acknowledges it, then marked for deletion; the storage is not necessarily freed at once, and may remain until the next ledger rollover. A retention policy can keep acknowledged messages longer, and is what keeps messages for the Reader interface, which does not acknowledge:

  Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-retention-expiry.md

  > By default, when a Pulsar message arrives at a broker, the message is stored until it has been acknowledged on all subscriptions, at which point it is marked for deletion.

  > (Note that messages that are no longer being stored are not necessarily immediately deleted, and may still be accessible until the next ledger rollover. Because clients cannot predict when rollovers may happen, it is not wise to rely on a rollover not happening at an inconvenient point in time.)

  > The retention settings apply to all messages on topics that do not have any subscriptions, or to messages that have been acknowledged by all subscriptions.

  > The Reader interface does not use acknowledgments, and messages do not exist within backlogs.

  With no retention period and little backlog, the same page bounds when acknowledged messages leave the disk by three periods, none of them the acknowledgement, and the broker trims consumed ledgers in the background:

  > If you do not have any retention period and you never have much of a backlog, the upper limit for retained messages, which are acknowledged, equals the Pulsar segment rollover period + entry log rollover period + (garbage collection interval * garbage collection ratios).

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/managed-ledger/src/main/java/org/apache/bookkeeper/mledger/impl/ManagedLedgerImpl.java

  > // Only trigger a trimming when switching to the next ledger
  > if (previousSlowestReader.getLedgerId() != newPosition.getLedgerId()) {

  > executor.execute(() -> internalTrimConsumedLedgers(promise));

  The trim deletes whole ledgers below the slowest durable reader, subject to retention. A closed ledger becomes eligible once the slowest durable cursor has acknowledged its last entry; the ledger being written is never deleted:

  > // If the slowest reader position point the last entry in the ledger x,
  >                     // the slowestReaderLedgerId should be x + 1 and the ledger x could be deleted.

  > // currentLedger can not be deleted

  Among the events that start a trim are the slowest reader's acknowledged position moving into another ledger (above), a ledger being closed and a cursor being deleted. Besides these, a broker task requests a trim every 120 seconds by default:

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/BrokerService.java

  > consumedLedgersMonitor.scheduleAtFixedRateNonConcurrently(this::checkConsumedLedgers,

  > managedLedger.trimConsumedLedgersInBackground(Futures.NULL_PROMISE);

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/conf/broker.conf

  > # Check between intervals to see if consumed ledgers need to be trimmed
  > # Use 0 or negative number to disable the check
  > retentionCheckIntervalInSeconds=120

  Inferred from that code: a message in a closed ledger needs no further rollover to be trimmed, and a message in the ledger being written waits at least until that ledger is closed.

  A topic with no durable subscription has its messages marked as deleted by default. Inferred from the code: the trim does not wait for a non-durable cursor, since only a durable cursor is given a position to be ordered by, and a non-durable cursor's acknowledgements start no trim:

  Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/concepts-messaging.md

  > By default, messages of a topic without any durable subscriptions are marked as deleted.

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/managed-ledger/src/main/java/org/apache/bookkeeper/mledger/impl/ManagedLedgerImpl.java

  > // non-durable cursors aren't tracked for trimming

  > if (cursor.isDurable()) {
  > positionForOrdering = cursor.getMarkDeletedPosition();

  With deduplication on, the broker keeps a cursor of its own, moved when it takes a snapshot, and the code says that cursor holds back the trim:

  Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/persistent/MessageDeduplication.java

  > // Not deduplicated (see isDuplicate), but the entry counts toward the snapshot interval: the snapshot moves
  > // the deduplication cursor, which bounds the replay on recovery and holds back the trimming of the ledgers

  Whether one acknowledgement covers a range depends on the subscription type. A cumulative acknowledgement covers every message up to the one it names; Shared and Key_Shared subscriptions acknowledge each message on its own:

  Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/concepts-messaging.md

  > With cumulative acknowledgment, the consumer **only** acknowledges the last message it received.

  > In Shared and Key_Shared subscription types, messages should be acknowledged individually.

**Stated why.**

Source: https://raw.githubusercontent.com/apache/pulsar/8c04f6cdcb9c3561746b9f890df106ad9a333e93/pip/pip-6.md

> Additionally, for an application that is publishing messages, to avoid publishing duplicate
> messages after application crashes, it needs to be able to restart publishing from a certain
> messages, with a particular sequence id.

> This will simplify managing the sequence id for the application, as no
> mapping will be required.

Why six hours: no stated rationale found in `pip-6.md`, `conf/broker.conf` or `docs/cookbooks-deduplication.md`. Why storage is freed a whole ledger at a time: no stated rationale found in `docs/cookbooks-retention-expiry.md` or `docs/concepts-messaging.md`. The retention page states the effect:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-retention-expiry.md

> Messages over the retention limit are kept because other messages in the same segment are still within retention period.

Inferred: storage is in BookKeeper ledgers, which are removed whole.

For deleting only after an acknowledgement, the messaging concepts page says what an acknowledgement is for, and gives no reason beyond it:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/concepts-messaging.md

> An acknowledgment (ack) is Pulsar's way of knowing that the message can be deleted from the system.

**Constraints.** Deduplication across a restart needs a stable, unique producer name:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-deduplication.md

> Specify a name for the producer (this is a requirement, Pulsar will use the producer name to filter duplicated messages).

**Costs and dissent.** By default unacknowledged messages are kept forever. A TTL bounds that by acknowledging a message when it expires, and a backlog quota bounds it with a policy, one of which discards backlog:

Source: https://raw.githubusercontent.com/apache/pulsar-site/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/cookbooks-retention-expiry.md

> By default, Pulsar stores all unacknowledged messages forever.

> When the TTL expires, Pulsar automatically moves the message to the acknowledged state (and thus makes it ready for deletion).

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

- A consumer's acknowledgement may be cumulative. With `AckAll`, acknowledging a message acknowledges every earlier one, and for a pull consumer it covers the pending messages of all its subscribers:

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/consumers.md

  > `AckAll`: Acknowledge only the last message received in a series; all previous messages are automatically acknowledged. Will acknowledge all pending
  >   messages for all subscribers for Pull Consumer.

- Retention is by limits (the default), by work queue (deleted on acknowledgement) or by interest (deleted once every interested consumer acknowledges). The one deferral the documentation states follows the removal of the last interested consumer, not an acknowledgement:

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/streams.md

  > Once a given message is ack’ed, it will be deleted from the stream.

  > If the `InterestPolicy` is chosen for a stream, note that when a consumer is deleted, either manually or as part of a server cleanup when the consumer's `InactiveThreshold` is reached, and that consumer was the last one that marked interest in a set of subjects, the server may not immediately delete all messages that belong to that set of subjects, for performance reasons. Instead, deletion may be deferred until those messages reach the start of the stream.

- **In the code at `v2.15.3`,** a second deferral follows an acknowledgement. A stream on a single server removes the message in the acknowledgement handler itself. In a clustered stream the leader proposes the delete to the stream's replicas through its replicated log, and each replica removes the message when it applies the proposal; a clustered consumer's acknowledgement is itself replicated before the stream is told. So in a cluster the delete is not in the step that handles the acknowledgement.

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/stream.go

  > // (Or should be removed in the case of clustered streams, since it requires a message delete proposal)

  > if !mset.isClustered() {

  > if _, err := store.RemoveMsg(seq); err == ErrStoreEOF {

  > // Directly proposes if stream leader, otherwise forwards it.
  > mset.node.ForwardProposal(encodeMsgDelete(&md))

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/jetstream_cluster.go

  > removed, err = mset.removeMsg(md.Seq)

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/consumer.go

  > // If this consumer is clustered this will be handled by
  > // processReplicatedAck after the ack has propagated.

  That removal is the file store's bookkeeping. A message removed out of order from a block that still holds others is recorded as deleted; the block is compacted in that step only when a simple check finds it worth it, and otherwise is left to a sync that runs on a timer, two minutes by default, and compacts it when its own check holds. A block left empty is removed at once.

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/filestore.go

  > // Out of order delete.

  > // Make simple check here similar to Compact(). If we can save 50% and over a certain threshold do inline.
  > // All other more thorough cleanup will happen in syncBlocks logic.

  > // If empty remove this block and check if we need to update first sequence.

  > defaultSyncInterval = 2 * time.Minute

  > fs.syncTmr = time.AfterFunc(start, fs.syncBlocks)

- **A termination removes too.** `AckTerm` stops redelivery without acknowledging success. The server handles it as an acknowledgement, and that acknowledgement tells a work-queue or interest stream to remove the message once no consumer is still interested. The streams page says a work-queue stream deletes only on limits or a successful acknowledgement. The two are reported as found and not reconciled.

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/using-nats/jetstream/model_deep_dive.md

  > Instructs the server to stop redelivery of a message without acknowledging it as successfully processed

  Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/consumer.go

  > // Treat like an ack to suppress redelivery.
  > ackedInPlace := o.processAckMsgLocked(sseq, dseq, dc, reply, false, needLock)

  > mset.ackMsg(o, sseq)

  Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/streams.md

  > `WorkQueuePolicy` streams will only delete messages enforced by limits or when a message has been successfully `Ack’d` by its consumer.

**Stated why.**

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/README.md

> For the publishing side, it relies on the publishing application attaching a unique message or publication ID in a message header and on the server keeping track of those IDs for a configurable rolling period of time in order to detect the publisher publishing the same message twice. For the subscribers a _double_ acknowledgment mechanism is used to avoid a message being erroneously re-sent to a subscriber by the server after some kinds of failures.

> * _limits_ (the default) is to provide a replay of messages in the stream.
> * _work queue_ (the stream is used as a shared queue and messages are removed from it as they are consumed) is to provide the exactly-once consumption of messages in the stream.

Why two minutes, and why to caution against large windows: no stated rationale found. Looked in `model_deep_dive.md`, `nats-concepts/jetstream/streams.md` and `README.md` at the pinned commit, `server/stream.go` at `v2.15.3`, and every ADR in nats-io/nats-architecture-and-design at `cd44e99` (ADR-8, ADR-49 and ADR-50 mention deduplication; none states a why). Inferred: the id map grows with the publish rate times the window.

A post on the NATS blog (2022), by Synadia's field CTO, gives the limit of a fixed window and a way past it. With a limit of one message per subject and the discard-new-per-subject policy, a publish to a subject that already holds a message fails, so an id carried in the subject is recognised beyond the window:

Source: https://nats.io/blog/new-per-subject-discard-policy/

> The limitation of JetStream’s stream deduplication window being that one can never tell ahead of time how much time it will actually take before a failing client process can be restarted and able to successfully process the messages in the stream.

> To review, the new discard policy discard-new-per-subject enables the ability to have an ‘infinite deduplication window’ to avoid duplicated publications that can otherwise happen to some failure scenarios.

Inferred: that protection lasts only while the earlier message is retained, since limits always apply (quoted under Constraints).

**Constraints.** Ids are opaque strings the publisher chooses. Limits always apply, whatever the retention policy:

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/README.md

> Note that regardless of the retention policy selected, the limits (and the discard policy) _always_ apply.

Inferred: a repeat that arrives after its id has left the window is stored again.

The id map is rebuilt when a stream is created or recovered, as at a server start, and before a clustered stream replays its log, from the messages still stored within the window:

Source: https://raw.githubusercontent.com/nats-io/nats-server/v2.15.3/server/stream.go

> // rebuildDedupe will rebuild any dedupe structures needed after recovery of a stream.

> // Jump over deleted sequences instead of loading each one.

> mset.storeMsgIdLocked(&ddentry{msgId, sm.seq, sm.ts})

Inferred from that code: an id whose message was deleted before a restart, as a work queue deletes on acknowledgement, is not in the rebuilt map, so a repeat of it within the window is stored again.

**Costs and dissent.** A limit deletes unread messages from a work queue:

Source: https://raw.githubusercontent.com/nats-io/nats.docs/f115becf6563e3bbe16bb94cbf87bfceb84199c1/nats-concepts/jetstream/streams.md

> For example, given a work-queue stream, if `MaxMsgs` are set and the default discard policy of _old_, messages will be automatically deleted even if the consumer did not receive them.

### C14. PostgreSQL logical replication slots

**Bears on:** purge only after confirmation, the confirmed position, and an asynchronous purge. PostgreSQL documentation and source at `REL_18_7`.

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

- **Repeats.** The documentation says the slot's position is persisted only at a checkpoint, so after a crash changes are sent again, and the client is to recognise them by position:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

  > The current position of each slot is persisted only at checkpoint, so in
  > the case of a crash the slot might return to an earlier LSN, which will
  > then cause recent changes to be sent again when the server restarts.
  > Logical decoding clients are responsible for avoiding ill effects from
  > handling the same message more than once.  Clients may wish to record
  > the last LSN they saw when decoding and skip over any repeated data

  In the documentation's example of decoding a prepared transaction, a transaction's `BEGIN` and its `INSERT` carry the same LSN:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

  >  0/1689DC0 | 529 | BEGIN 529
  >  0/1689DC0 | 529 | table public.data: INSERT: id[integer]:3 data[text]:'5'

  The source writes the slot sooner on one path. When a consumer's confirmation lets the slot advance its `restart_lsn` or its catalog xmin, the confirmation handler writes the slot to disk at once. A confirmation that moves only `confirmed_flush_lsn` is changed in memory by that handler. The documentation does not describe the first path; the two are reported as found and not reconciled.

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/src/backend/replication/logical/logical.c

  > /* first write new xmin to disk, so we know what's up after a crash */

  > ReplicationSlotSave();

- `max_slot_wal_keep_size`, added in PostgreSQL 13, caps what a slot may retain and invalidates a slot that overruns it:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/config.sgml

  > replication slots may retain an unlimited amount of WAL files.

- **The hand-over.** The receiver starts it with `START_REPLICATION`, naming its slot, and the server then streams WAL to it:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/protocol.sgml

  > On success, the server responds with a CopyBothResponse
  >        message, and then starts to stream WAL to the frontend.

  Beside the WAL, the protocol documentation gives each XLogData message, and each keepalive the server sends, a field for the current end of WAL on the server, and says a logical stream's messages have the same format as a physical one's:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/protocol.sgml

  > The current end of WAL on the server.

  > The messages inside the CopyBothResponse messages are of the same format

  For a logical stream the walsender at `REL_18_7` fills that field otherwise: in XLogData with the `lsn` passed to the write, or zero for a write not marked as the last, and in a keepalive with `writePtr` when its caller passes a valid one, and otherwise `sentPtr`:

  Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/src/backend/replication/walsender.c

  > if (!last_write)
  >         lsn = InvalidXLogRecPtr;

  > pq_sendint64(ctx->out, lsn);	/* walEnd */

  > pq_sendint64(&output_message, XLogRecPtrIsInvalid(writePtr) ? sentPtr : writePtr);

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

Why a confirmation that moves only `confirmed_flush_lsn` is not written out, from a comment in `LogicalSlotAdvanceAndCheckSnapState`, in the same file:

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/src/backend/replication/logical/logical.c

> If only the confirmed_flush LSN has changed the slot won't get
>  * marked as dirty by the above. Callers on the walsender
>  * interface are expected to keep track of their own progress and
>  * don't need it written out.

Why the slot is written at once when its xmin or restart position moves: the comment quoted above, "so we know what's up after a crash".

**Constraints.** A slot knows nothing of its consumer and survives crashes:

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

> Replication slots persist across crashes and know nothing about the state
> of their consumer(s). They will prevent removal of required resources
> even when there is no connection using them.

**Costs and dissent.**

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/logicaldecoding.sgml

> In extreme cases this could cause the database to shut down to prevent
> transaction ID wraparound

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/high-availability.sgml

> Beware that replication slots can cause the server to retain so
> many WAL segments that they fill up the space allocated for

PostgreSQL 18 adds a second, default-off guard:

Source: https://raw.githubusercontent.com/postgres/postgres/REL_18_7/doc/src/sgml/config.sgml

> Invalidate replication slots that have remained inactive (not used by

## Comparables that chose otherwise

Some of the comparables above chose otherwise themselves, and are only pointed to here: the OpenTelemetry SDK drops a failed batch, and OTLP defines no way to recognise a repeat (C7); the Prometheus server truncates the log remote write reads, whether or not it has been sent (C9); Kafka deletes by time or size, whether or not anything has been read (C10). Pulsar (C12), NATS JetStream (C13), PostgreSQL (C14) and Kafka's own handbook (C11) each document a way to recognise a repeat that is not Kafka's producer sequence. The systems below were read for this section only.

### Sending with no confirmation, or deleting on send

#### O1. statsd

statsd `v0.10.2`. Clients send UDP datagrams with no acknowledgement. The server aggregates in memory and, after each flush to its backends, resets counters to zero or deletes them, whether or not the backend write succeeded; the graphite backend only logs connection errors. Nothing identifies a repeat.

Source: https://raw.githubusercontent.com/statsd/statsd/v0.10.2/stats.js

> // After all listeners, reset the stats

> metrics.counters[counter_key] = 0;

**Stated why, for the client's send.** The README at `v0.10.2` states no reason for UDP, and now offers TCP as well. The reason for UDP, a send that keeps nothing and learns nothing of its fate, is in the original authors' posts. Etsy's, from 2011, was read from the Wayback Machine's copy because etsy.com returned HTTP 403:

Source: https://web.archive.org/web/20120103141034id_/http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/

> So,  why do we use UDP to send data to StatsD? Well, it’s fast — you don’t  want to slow your application down in order to track its performance —  but also sending a UDP packet is fire-and-forget. Either StatsD gets the  data, or it doesn’t.

> The application doesn’t care if StatsD is up,  down, or on fire; it simply trusts that things will work. If they don’t,  our stats go a bit wonky, but the site stays up.

Flickr's, from 2008, which the README credits:

Source: https://code.flickr.net/2008/10/27/counting-timing/

> When counting frequent stats, losing the odd packet doesn’t really hurt us, especially when we can also graph when we’ve been dropping packets

No stated rationale found for the server resetting its aggregates after a flush whatever the backends' result. Looked in `stats.js`, `README.md`, `exampleConfig.js` and `docs/` (`backend.md`, `backend_interface.md`, `metric_types.md`, `history.md`, `graphite.md`) at `v0.10.2`, which say when the reset happens and not why, and in the two posts above.

Source: https://raw.githubusercontent.com/statsd/statsd/v0.10.2/docs/backend_interface.md

> StatsD will reset timers and counters after each
> listener has handled the event.

**Constraints, costs and dissent.** Loss is accepted, and measured through the kernel's UDP receive-error counters. Costs beyond these sources were not searched.

#### O2. Syslog over UDP (RFC 5426)

The RFC defines a transport with no acknowledgement, retransmission or loss detection. It describes no sender's buffer, so it shows a send that nothing confirms rather than a rule for deleting. Inferred: a sender has nothing to keep data for.

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

The documentation says a repeat overwrites. The output code at `v9.5.7` sends a `create` unless the event's `@metadata.op_type` is `index`: when an id is set, and on Elasticsearch 7.5 or later even without one. With `create` a repeat is refused with a 409 and counted as a duplicate. With `op_type` set to `index` it overwrites, as the page says, on a target that takes an `index` action (below):

Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/libbeat/outputs/elasticsearch/client.go

> if event.id != "" || version.Major > 7 || (version.Major == 7 && version.Minor >= 5) {

> if event.opType == events.OpTypeIndex {

> return eslegclient.BulkIndexAction{Index: meta}, nil

> return eslegclient.BulkCreateAction{Create: meta}, nil

> // 409 is used to indicate there is already an event with the same ID, or

> stats.duplicates++

Source: https://raw.githubusercontent.com/elastic/elasticsearch-specification/1b721b91aca7d38d6ed452746de2820f8b94b03f/specification/_global/index/IndexRequest.ts

> * Set to `create` to only index the document if it does not already exist (put if absent).
> * If a document with the specified `_id` already exists, the indexing operation will fail.

The overwrite needs a target that takes an `index` action. A data stream takes only `create`, and Filebeat's default target is a data stream:

Source: https://raw.githubusercontent.com/elastic/elasticsearch-specification/1b721b91aca7d38d6ed452746de2820f8b94b03f/specification/_global/bulk/BulkRequest.ts

> NOTE: Data streams support only the `create` action.

Source: https://raw.githubusercontent.com/elastic/elasticsearch-specification/1b721b91aca7d38d6ed452746de2820f8b94b03f/specification/_global/index/IndexRequest.ts

> If the request targets a data stream, an `op_type` of `create` is required.

Source: https://raw.githubusercontent.com/elastic/beats/v9.5.7/docs/reference/filebeat/change-index-name.md

> Filebeat uses data streams named `filebeat-[version]`.

**Stated why.** For the id: the deduplication page above ("document IDs are typically set by {{es}} *after* it receives the data"). For `create` and the 409, no stated rationale found in that page or in `libbeat/outputs/elasticsearch/client.go` at `v9.5.7`.

**Constraints.** The identity is per message, assigned by the sender or derived from content, and holds within one index (Inferred, not checked: a rollover to a new backing index starts a new namespace).

#### O4. Elasticsearch time series data streams

elastic/docs-content at `96870a9`. In a time series data stream the document id is generated from the dimension fields and the timestamp. The current documentation says a repeat is refused:

Source: https://raw.githubusercontent.com/elastic/docs-content/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/time-series-data-stream-tsds.md

> {{es}} uses dimensions and timestamps to generate time series document `_id` values. Two documents with the same dimensions and timestamp are considered duplicates. Duplicates are rejected during ingestion with a `409 Conflict` status.

The 8.19 reference guide says a repeat sent through `_bulk` overwrites the first, and the pull request that introduced the derived id shows, on a time series index, an `index` action overwriting and a `create` action writing only if the document is absent. The specification quoted under O3 says data streams support only the `create` action. The code at `v8.19.0` refuses any other action written through a data stream's name, while allowing one written directly to a backing index by its name, and the 8.19 bulk API says a `create` fails when a document with the id already exists (both quoted below). Whether the guide's overwrite happens only through a backing index was not checked; the guide's sentence and these are reported as found and not reconciled.

Source: https://www.elastic.co/guide/en/elasticsearch/reference/8.19/tsds.html#time-series-dimension

> endpoint to add documents to a TSDS, a second document with the same timestamp and dimensions overwrites the first.

Source: https://github.com/elastic/elasticsearch/pull/82633

> The ID comes from the dimensions and the `@timestamp`. So you can overwrite the document:

> Or you can write only if it doesn't already exist:

Source: https://raw.githubusercontent.com/elastic/elasticsearch/v8.19.0/server/src/main/java/org/elasticsearch/action/bulk/BulkOperation.java

> throw new IllegalArgumentException("only write ops with an op_type of create are allowed in data streams");

> // avoid valid cases when directly indexing into a backing index

Source: https://www.elastic.co/guide/en/elasticsearch/reference/8.19/docs-bulk.html

> create fails if a document with the same ID already exists in the target,

**Stated why.** For the derived id, pull request #82633 (merged 2022-03-10) gives its purpose, document GET, DELETE and versioning for time series documents, and names the cost of an id that must be looked up on every write:

Source: https://github.com/elastic/elasticsearch/pull/82633

> This adds support for GET and DELETE and the ids query and Elasticsearch's standard document versioning to TSDB.

> We have to entirely disable the append-only optimization that allows Elasticsearch to skip looking up the ids in lucene. This *halves* indexing speed.

For refusing a repeat rather than overwriting it, no stated rationale found in `time-series-data-stream-tsds.md` or `advanced-topics-tsds.md` at `96870a9`, the 8.19 guide, the design issue elastic/elasticsearch#74660 and its comments, pull request #82633, or pull request #84957, whose stated purpose is a clearer version-conflict message.

#### O5. Amazon SQS FIFO queues

The service remembers a deduplication id the sender assigns, or a SHA-256 of the body, for five minutes, even after the message is deleted, across the queue or, where the queue's `DeduplicationScope` is `messageGroup`, within a message group. A repeat within that interval is accepted and not delivered; after it, SQS cannot tell a repeat apart.

Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html

> If a message with a particular `MessageDeduplicationId` is sent successfully, any messages sent with the same `MessageDeduplicationId` are accepted successfully but aren't delivered during the 5-minute deduplication interval.

> If a message is sent successfully but the acknowledgement is lost and the message is resent with the same `MessageDeduplicationId` after the deduplication interval, Amazon SQS can't detect duplicate messages.

> Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.

Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SetQueueAttributes.html

> Specifies whether message deduplication occurs at the message group or queue level.

**Stated why.** The failure it answers is the one in the second quotation, a lost acknowledgement. No stated rationale found for five minutes, in `API_SendMessage`, `FIFO-queues-exactly-once-processing` and `using-messagededuplicationid-property` on docs.aws.amazon.com.

**Deletion.** A receive does not delete. The message stays in the queue, hidden from other consumers for a visibility timeout, and the consumer deletes it after processing, with the receipt handle of its latest receive. A message not deleted in time becomes visible again. One left longer than the queue's retention period is deleted by the service, whether or not it was processed.

Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html

> When you receive a message from an Amazon SQS queue, it remains in the queue but becomes temporarily invisible to other consumers.

> If you don't process and delete a message before the visibility timeout expires—due to application errors, crashes, or connectivity problems—the message becomes visible again in the queue. It can then be retrieved by the same or a different consumer for another processing attempt. This ensures that messages aren't lost even if the initial processing fails.

Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_DeleteMessage.html

> When you want to delete a message using the `DeleteMessage` action, you must use the `ReceiptHandle` from the most recent time you received the message. If you use an old `ReceiptHandle`, the request will succeed, but the message might not be deleted.

> Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue.

**Stated why, for deleting only after processing:** the visibility timeout exists so that a message is not lost if processing fails (above).

#### O6. MQTT QoS 2

OASIS MQTT 5.0 and 3.1.1. The sender assigns a packet identifier not in use by another of its own exchanges; the client and the server assign theirs independently. The receiver remembers it from PUBLISH until PUBREL and answers a repeat in that window without delivering it again; after it sends PUBCOMP the receiver treats the identifier as new, and the sender may reuse it once it has received PUBCOMP, or, in 5.0 only, a PUBREC with a Reason Code of 0x80 or greater. The state belongs to the session, which lasts as long as the connection plus the session expiry interval.

Source: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html

> Until it has received the
>      corresponding PUBREL packet, the receiver MUST acknowledge any subsequent
>      PUBLISH packet with the same Packet Identifier by sending a PUBREC. It
>      MUST NOT cause duplicate messages to be delivered to any onward recipients
>      in this case [MQTT-4.3.3-10].

> After it has sent a
>      PUBCOMP, the receiver MUST treat any subsequent PUBLISH packet that
>      contains that Packet Identifier as being a new Application Message [MQTT-4.3.3-12].

> The Packet Identifier becomes available for reuse once the sender has received the PUBCOMP packet or a PUBREC with a Reason Code of 0x80 or greater.

**Stated why, and its cost.**

> This is the highest Quality of Service level, for use when
> neither loss nor duplication of messages are acceptable. There is an increased
> overhead associated with QoS 2.

#### O7. Google Cloud Pub/Sub exactly-once delivery

On the subscriber side only, and only with pull subscriptions, Pub/Sub prevents redelivery of an acknowledged message within a region, by a message id the service assigns. It does not remove publish-side duplicates: a client's retried publish gets a new message id, and a repeat the service makes keeps the id but is still delivered.

Source: https://cloud.google.com/pubsub/docs/exactly-once-delivery

> Pub/Sub supports exactly-once delivery, within a cloud region,
> based on a Pub/Sub-defined unique
> message ID.

> A subscription might receive multiple copies of the same message due to publish side duplicates, even with exactly-once delivery enabled.

> Multiple unique publishes by the publishing client, across retries, leads to redeliveries with different message IDs. Multiple unique publishes by the Pub/Sub service, to respond to a client publish request, leads to redeliveries with the same message IDs.

**Stated why.** For limiting it to pull subscriptions: a push subscriber acknowledges by answering a request, and cannot know that the answer arrived. No stated rationale found on that page for deduplicating on the subscriber side only.

Source: https://cloud.google.com/pubsub/docs/exactly-once-delivery

> Pub/Sub supports exactly-once delivery only with pull subscriptions.

> Clients consuming messages from the push subscriptions acknowledge the messages
> by responding to the push requests with a successful response. However, clients
> don't know if the Pub/Sub subscription received the response and
> processed it.

> exactly-once delivery semantics don't align well with push subscriptions.

**Deletion.** By default a subscription discards a message once it is acknowledged, and keeps an unacknowledged one for seven days; a subscription can be set to keep acknowledged messages too, for replay. Once every subscription on the topic has acknowledged a message, it is deleted from storage asynchronously. Retention on the topic is off by default. Its page says that once the topic's retention duration is over, Pub/Sub may discard a message whatever its acknowledgements; the subscription retention page says that with topic retention also on, messages are deleted from the subscription only once older than the longer of the two durations.

Source: https://docs.cloud.google.com/pubsub/docs/subscription-message-retention

> By default, Pub/Sub discards a message from a subscription as soon as the message is acknowledged, and retains unacknowledged messages for 7 days.

> You can also enable the subscription to retain acknowledged messages, up to the configured retention duration.

Source: https://docs.cloud.google.com/pubsub/docs/pubsub-basics

> If all the subscriptions on a topic have acknowledged the message, the message is asynchronously deleted from the publish message source and from storage.

Source: https://docs.cloud.google.com/pubsub/docs/subscription-message-retention

> If you also enable message retention on the subscription's topic, then messages
> are deleted from the subscription only when their age exceeds the maximum of the
> subscription retention and topic retention durations.

Source: https://docs.cloud.google.com/pubsub/docs/topic-properties

> After the message retention duration is over, Pub/Sub
> might discard the message regardless of its acknowledgment state.

> Default = Not enabled

#### O8. Azure Service Bus duplicate detection

The service remembers an application-controlled `MessageId`, with the partition key when partitioning is enabled, for a configured window, and accepts and drops a repeat sent within it.

Source: https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection

> If any new message is sent with MessageId that was logged during the time window, Service Bus reports the message as accepted (the send operation succeeds), but the newly sent message is instantly ignored and dropped.

> When partitioning is enabled, MessageId+PartitionKey is used to determine uniqueness.

**Stated why.** The failures it answers are a sender restarted after a fatal error that sends again, and a send committed whose acknowledgement was lost:

> If an application fails due to a fatal error immediately after sending a message, and the restarted application instance mistakenly believes that the prior message delivery didn't occur, a subsequent send causes the same message to appear in the system twice.

> It's also possible for an error at the client or network level to occur a moment earlier, and for a sent message to be committed into the queue, with the acknowledgment not successfully returned to the client.

> Application control of the identifier is essential because it allows the application to tie the MessageId to a business process context from which it can be predictably reconstructed when a failure occurs.

> Keeping the window small means that fewer message IDs must be retained and matched, and throughput is impacted less.

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
- Out-of-order sample handling in the Prometheus TSDB, which has its own repeat check.
- What the Azure Event Hubs service remembers. For Google Cloud Pub/Sub, only the exactly-once delivery, subscription retention, topic properties and service overview pages were read (O7).
- ActiveMQ Classic's KahaDB, read only on one FAQ page: it cleans up unreferenced journal files every 30 seconds by default, and keeps a file that holds an acknowledgement while the acknowledged message's file is still in use.

  Source: https://activemq.apache.org/components/classic/documentation/why-do-kahadb-log-files-remain-after-cleanup

  > Clean-up of un-referenced KahaDB journal log files data-<id>.log will occur every 30 seconds by default.

  > It contains an ACK for a message which is in an in-use data file - the ACK cannot be removed as a recovery would then mark the message for redelivery

- RabbitMQ's automatic acknowledgement mode, read only on its acknowledgements page, which counts a message delivered as soon as it is sent:

  Source: https://raw.githubusercontent.com/rabbitmq/rabbitmq-website/44f3c56f278159caedf6564f5d93b78d829ea568/docs/confirms.md

  > In automatic acknowledgement mode, a message is considered
  > to be successfully delivered immediately after it is
  > sent. This mode trades off higher throughput (as long as the
  > consumers can keep up) for reduced safety of delivery and
  > consumer processing.

- Log shippers not surveyed by the elicitation (rsyslog's disk-assisted queues, Logstash's persistent queue, the Datadog and Splunk agents).
- Google Cloud Tasks, read only on its overview page: creating a task with a name already in the queue fails, and a name is remembered for up to 24 hours after its task is deleted, another id the sender assigns.

  Source: https://docs.cloud.google.com/tasks/docs/dual-overview#task_deduplication

  > If you attempt to create a task with a name that already exists in the queue, the
  > creation request will fail.

  > Cloud Tasks remembers task names for up to 24 hours after the
  > task has been deleted from the queue.

- RabbitMQ quorum queues, read only on the quorum queues page: since 4.3, a compaction that runs periodically in the background copies the entries still needed out of sparse log segments and deletes the old segments; before it, one unacknowledged message could stop the log being truncated.

  Source: https://www.rabbitmq.com/docs/quorum-queues#log-compaction

  > Runs periodically in the background. It consolidates multiple sparse segments by copying only the remaining live entries into new, smaller segments, and deleting the old ones.

  > Previously, a single unacknowledged message could prevent the log from being truncated, leading to unbounded disk growth.

## Fit

### The constraints of this client

What the specification states, and what is only a leaning, are kept apart here. A leaning recorded in `CONTEXT.md` is cited as a leaning.

- **The sender is an in-process library.** The client runs inside the host application, which it must never harm: a queue is bounded and never blocks the worker, and a write never fails. One data writer stores rows in local databases. Purging is off the hot path and never required; that it is the data writer's work, so that nothing is purged once the data writer has stopped, is marked Derived in `PurgeRow`.
- **A run is one establish, in a process that may be short-lived.** Each establish mints a new run id (`uuid_v7(now)`) and starts positions at 1; one establish after another is a new run each time (Derived, `EstablishProductionCore`). When establish ends, what is still queued is discarded and counted, the batch in hand is finished and the data writer stops, so a run can end with stored rows that no collection has confirmed. What a later establish does with databases a previous run left at the location is open question 6. A forked child's production establish is refused (`EstablishProductionCore`). That the usual host is an ephemeral pod is a leaning, not a decision.
- **A run id is minted without coordination.** The specification has one writer process per instance, the location being the instance, and leaves more than one process per instance to open questions 1 and 17. It does not say that several instances or pods hand over to one collection: the collector's internals are outside it. That they would, with each run id minted on its own host, is a reading of the ephemeral-pod leaning, not a statement of the specification. The maintainer's standing guidance prefers coordination-free or low-coordination solutions.
- **The client holds the data it hands over.** The rows live in the client's own local databases, at a location one live process claims; the specification gives no other process a way to remove them, though what happens to a previous run's databases is open question 6. The local databases are bounded, and anything removed uncollected is counted (settled), but what bounds them is open question 8. Until it is decided, open question 8 says, no rule removes a stored row that has not been confirmed. Keyed values are the case the rules already make: a newer value for a slot replaces the stored value, confirmed or not (`ReplaceKeyedValue`), and the replaced value is not handed over (`LatestValuePerKey`), as the first worked hand-over example in `CONTEXT.md` shows.
- **The collector may pull.** Whether the hand-over is a push or a pull, and in what form, is open question 15; the maintainer leans towards a pull.
- **Nothing is decided about what a collector remembers.** Which collector confirms when more than one reads an instance is open question 7, and whether a hand-over carries the stored position is open question 25. A collector is not known to be a server cluster, a single process, or something that keeps state between collections.
- **Positions have gaps.** A row is given its position when it is accepted, so a row lost afterwards leaves a visible gap (marked Derived in `AcceptRow`); earlier values of a key that a later one replaced are not sent (`LatestValuePerKey`); and a hand-over offers nothing above the stored position (marked Derived), so rows above a row still waiting are held back. The worked hand-over examples in `CONTEXT.md`, which were read back to the maintainer, show all three.
- **A confirmation is cumulative.** The collector states the highest position it has safely received (`ConfirmPosition`), and a row at or below it may be purged later, a keyed value only while no newer value for its key exists (`PurgeRow`). One integer per run stands for what has been collected. That a confirmation above the stored position is refused, and one at or below the confirmed position changes nothing, is marked Derived.
- **The storage engine is undecided.** DuckDB was named once, as a possibility; the local databases' on-disk format is not decided.

### Fit of each comparable

- **C1, Kafka's idempotent producer.** *Holds:* the failure it answers, a retry after a lost acknowledgement producing a duplicate, arises for any hand-over that re-sends, push or pull. The identity is per producer session, and a restart without a `transactional.id` gets a new one, as a new establish gets a new run. *Does not hold:* the producer id is assigned by the broker, a coordination this client avoids; the checking side is a broker cluster that remembers the last five batches per producer and partition for a bounded time, where nothing is decided about what a collector remembers; the check, wherever the leader holds the producer's state, is exact continuity, a gap being rejected as out of sequence (fatal in KIP-98's words; the idempotent producer at 4.4.0 retries it, bumping its epoch on a real gap), where this client's positions have gaps by design; the sequence is per partition, where a position is per run across all its tables; and the sequence is not an acknowledgement or a read position (Inferred, C1), where a position is also what the collector confirms. KIP-98's own scope note, that idempotence holds "within a single producer session", matches a run.
- **C2, RFC 9562.** *Holds:* §2.1's stated reason for UUIDs in general, that coordinating sequential identifiers across a network "can easily become a burden", fits many runs minted without coordination, and §6.4 says no coordination is required. *Does not hold, or not shown:* the RFC says nothing about one identifier per run or per process, and its counters sit inside the UUID; its index-locality reason, the one it gives for a time-ordered version such as UUIDv7, applies only where something stores and indexes by run id, which no decision says the collector does; its further reason for version 7, improved entropy over versions 1 and 6 (§5.7), does not depend on order and compares version 7 with those two only; one id per run needs none of §6.2's monotonicity guidance. The §8 warnings carry over unchanged: a run id must not be treated as a capability, and its timestamp, "in conjunction with an embedded counter", signals the order of creation, here read from the client's clock at establish (`uuid_v7(now)`); two run ids minted by independent generators in the same millisecond are ordered by their random bits, not by creation time (Inferred, C2).
- **C3, Filebeat.** *Holds:* the registry is a confirmed read position, like the confirmed position; `delete.enabled` deletes only once every event is acknowledged, and its reviewer's stated reason, not to discard data still to be sent, fits the settled rule that nothing uncollected is removed uncounted. *Does not hold:* Filebeat reads files another process owns, so its stated loss case (rotation or deletion before reading) is someone else's purge, where this client owns its data; and its acknowledgement can be the disk queue's, or a drop, rather than the destination's receipt. The disk queue author's reason for a deleter of its own, to keep one operation from blocking the others, so that an error deleting an old segment does not stop writing to the current one, rests on reading, writing and deleting in separate loops; here purging is the data writer's own work (Derived, `PurgeRow`) and no rule says what a failed purge does, so it informs an asynchronous purge and does not justify it (verdict 2).
- **C4, the OpenTelemetry Collector's persistent queue.** *Holds:* its stated motive, data lost when a memory buffer overfills or the process crashes (issue #2285), is the motive for any durable local buffer. *Does not hold:* it is a pipeline agent with a retry budget, and it deletes on giving up as well as on success; this client has no give-up rule on the hand-over, and its purge requires a confirmation. That the delete is in the same step as the outcome has no counterpart: this client's purge is a separate, later step by design.
- **C5, Vector.** *Holds:* the stated reason for the asynchronous physical delete, that a failed delete is retried by a later scan, fits a purge that is off the hot path, may fail and is never required, for as long as the data writer runs; the earlier TODO on the read path's tail latency only informs it (verdict 2). *Does not hold:* the same comment's retry after the process exits needs a later process to open the same buffer, where here nothing is purged once the data writer has stopped (Derived, `PurgeRow`) and what a later establish does with a previous run's databases is open question 6; its deletion follows finalization of any status, and its end-to-end acknowledgements stop at the buffer, so the confirmation is one hop's; this client's confirmation is the collector's own statement.
- **C6, Fluent Bit.** *Holds:* the size limit's stated reason, not filling the disk other applications use (issue #2408), fits a client that must never harm its host. *Does not hold:* its engine deletes on an error and on an exhausted retry with no stated reason, the S3 output's own buffer can go on an exhausted retry too, and an output's `FLB_OK` can precede delivery; neither has a counterpart here.
- **C7, the OpenTelemetry SDK and OTLP.** *Holds:* the deployment is the same, a library inside the application, and its stated principles, not blocking the application and not using unbounded memory, are this client's settled promises. OTLP's stated choice, that duplicates are "the right tradeoff for telemetry data", fits a hand-over that may repeat. *Does not hold:* the SDK keeps nothing on disk and drops a failed batch, where this client keeps rows until confirmed: it chose otherwise, and its maintainers declined persistent retry in the SDK as complex and of unclear demand. Of the two SDK disk buffers read, opentelemetry-java-contrib's deletes by default an item its reader has taken without seeing the export's outcome, and OpenTelemetry Swift's deletes a batch file once its export has not failed, with size and age limits that delete whatever was exported. OTLP's maintainer objected to a request id because load-balanced and re-batching collectors cannot share it without coordinating, and its author withdrew it, judging it unneeded once an instance id and each point's timestamp are required; the objection applies only if this client's collector has that shape, which open question 7 leaves open.
- **C8, the Prometheus client.** *Holds:* it is a pull from a library inside the application, as the leaning has it. A keyed state table, which hands over one latest value per key, is close to a Prometheus series. *Does not hold:* as a comparable for a purge rule it does not transfer at all, because a Prometheus client holds no rows waiting for collection and so purges nothing; a time series table of rows has no cumulative value that makes a missed collection harmless.
- **C9, the Prometheus server and agent.** *Holds:* the agent is a local write-ahead buffer feeding a remote, with a time cut-off past which unsent data may go, which is the situation open question 8 describes. *Does not hold:* the server's WAL belongs to its storage engine, and remote write reads a log it does not own; the agent's purge follows what was sent, not what was confirmed.
- **C10, Kafka's retention.** *Holds:* Kafka Streams purges on an interval, off the path that commits, as this client purges off the path that confirms. *Does not hold, or not shown:* the stated reason for the interval (KIP-811) is the cost of sending the brokers a delete request at every commit, in throughput and broker log volume, where this client's purge is the data writer's local work, whose cost depends on a storage engine that is undecided; and the reason for deleting a renamed segment later, that a reader may still have it open, applies only if something reads the local databases' files while the data writer purges: their on-disk form is private to the client and what a hand-over transmits is a separate concern (`PrivateOnDiskForm`), and the form of the hand-over is open question 15. Both inform an asynchronous purge here; neither justifies it. Retention by time or size serves many consumer groups re-reading a shared log on a broker, where this client's rows are handed over and then purged. *Dissent that bears on it:* the handbook's authors rejected a "store-and-forward" producer, one that keeps its own local log, as "not very suitable for our target use cases which have thousands of producers", because involving thousands of disks would be "a nightmare to operate". This client keeps a local store for each writing process, the shape the objection names. Whether its deployments reach the number of producers the objection is scoped to is not known: one store per pod is a reading of the ephemeral-pod leaning, and whether the one-process rule holds per container if collection is a pull is open question 17.
- **C11, Kafka's consumer offsets.** *Holds:* the stated reason for one integer per partition, that it makes "the equivalent of message acknowledgements very cheap" compared with state per message, fits a cumulative confirmed position. The at-least-once order, process then commit, is the hand-over's: a collector confirms what it has safely received, and every stored row above the confirmed position, up to the stored position (marked Derived), is offered by each hand-over until a confirmation covers it, so a row already offered is offered again (`Run.offered_rows`), except a keyed value that a newer one has replaced (`ReplaceKeyedValue`): a keyed state table offers only its latest value per key (`LatestValuePerKey`). *Does not hold:* the integer is the next offset to read, where the confirmed position is the highest received; and it stands for what is consumed only because one consumer reads a partition in a consumer group; Kafka's share groups, where consumers share a partition, acknowledge records one by one instead. Which collector confirms is open question 7.
- **C12, Pulsar.** *Holds:* its deduplication keeps the highest sequence seen and allows holes, closer to positions with gaps than Kafka's continuity check. Its stated reason, resuming after an application crash from a known sequence with the same producer name, fits only rows handed over again after the process that wrote them has gone; a new establish mints a new run id, and whether a previous run's rows are handed over at all is open question 6. *Does not hold:* the broker remembers producers for six hours, a server's bounded memory; deletion waits for every durable subscription, a multi-reader rule open question 7 leaves open here; and the check treats any sequence at or below the highest persisted one as a repeat, which is safe only while a producer's messages arrive in sequence order (Inferred), where the specification states no order for the rows a hand-over offers (`HandOver`) and how a hand-over is carried is open question 15.
- **C13, NATS JetStream.** *Holds:* an id the publisher chooses, remembered by the receiver for a window, is a way to recognise a repeat that needs no continuity. *Does not hold:* the window is bounded, and the documentation cautions against large windows without saying why (that the cost is the server's id map is Inferred, C13); a repeat after the window is stored again (Inferred).
- **C14, PostgreSQL replication slots.** *Holds:* it is the closest in structure within a run. The sender keeps the WAL a slot may still need, from its `restart_lsn`, which a confirmation can move on; it removes that WAL later, at a checkpoint, rather than in the confirming step; and after a crash it may send again what follows the slot's persisted position, which the documentation leaves the client to handle, suggesting it may record the last LSN it saw. Its stated reasons fit: keep exactly what the receiver still needs, even while it is disconnected; and bound it, because unbounded retention "can lead to the primary failing because of running out of space". *Does not hold:* the sender is a long-lived database server and a slot persists across crashes, where a run ends with its establish and a later establish is a new run (open question 6); and one receiver reads a slot at a time (open question 7).
- **O1 and O2, statsd and syslog over UDP.** *Holds:* Etsy's stated reason, that the application should not care whether the collector is up, is this client's promise never to harm the host. *Does not hold:* neither keeps anything to hand over again.
- **O3 to O8, an id the sender assigns, or content.** *Holds:* a run id with a position is an id the sender assigns to each row and keeps across a re-send, as in O3, O5 with a deduplication id, O6 and O8. Azure Service Bus's stated reason for an application-controlled id, that the application can reconstruct it "predictably" after a failure, fits a position stored with its row, for as long as the row and its run id are kept; across an establish the run id changes (open question 6). SQS's stated reason for deleting only after processing, that a message is not lost if its first processing fails (O5), shares the rationale of keeping rows until a collection confirms them, within a run; its threshold, the consumer's processing and its own delete, differs from the collector's statement of what it has safely received (`ConfirmPosition`), so it informs and does not justify (verdict 2). *Does not hold:* each of O3, O5, O6 and O8 names what its receiver remembers, and for how long (five minutes for SQS, a configured window for Service Bus, one exchange from PUBLISH to PUBREL for MQTT, a document's life for Elasticsearch); for this client's collector nothing is decided. Content (O4, and SQS's content-based deduplication) recognises a repeat by what a message carries, not by an id the sender keeps for it, a different mechanism from a position; and O7's id is one Pub/Sub assigns, not the sender, which prevents its redelivery to a subscriber, not a publisher's repeat.

## Is a run id with a position like Kafka's sequence number?

**Partly.** Both name the producing instance for one session and number what it produces, so that something re-sent after a lost acknowledgement can be recognised. In that, a run id is like Kafka's producer id and a position like its sequence number. But the two differ in who assigns the identity, who checks the number and how, and what the number is for:

| | Kafka's producer id and sequence (C1) | This client's run id and position |
| --- | --- | --- |
| Identity | A producer id the broker assigns; a new one on each restart unless a `transactional.id` is set | A UUIDv7 the client mints at establish, with no coordination; a new one each establish |
| Scope of the number | Per producer id and partition | Per run, across all its tables |
| Unit | Each record is numbered; a batch carries its first number and is matched by its first and last | Each row has its own position |
| Who checks it | The partition leader, at append | Undecided: no rule says what a collector does with it |
| The check | Exact continuity where the leader holds the producer's state: one more than the last, a gap rejected as out of sequence (fatal in KIP-98; retried by the idempotent producer at 4.4.0, which bumps its epoch on a real gap); with no state, any sequence is accepted on the plain path, with no transaction and no verification entry; in the one case added for transactions version 2, a sequence other than 0 is rejected (C1); a retry is recognised by matching one of the last five batches | None defined; gaps are normal, from lost rows, replaced keyed values and the stored position holding rows back |
| What the receiving side remembers | Per producer and partition, up to the last five batches, for a day after the last write by default, longer while a transaction is open | Undecided: a collector's internals are outside the specification (`Collector`) |
| What the number is for | Recognising a retry and detecting loss; never a read position | Recognising a repeat, and the position the collector confirms and purging follows |

So in two respects a position is closer to other comparables than to Kafka's sequence. As the unit a collector confirms, it is Kafka's consumer offset (C11) or PostgreSQL's confirmed position (C14), not the producer's sequence. As the identity of a repeat, a run id with a position is an id the sender assigns to each row (O3, O5, O8), and since positions have gaps it cannot be checked by continuity, as Kafka's is; Pulsar's highest-seen check, which allows holes (C12), is the nearest sequence-based one, though it treats anything at or below the highest seen as a repeat, and so relies on arrival in sequence order, which the specification does not state for a hand-over (Inferred, C12).

## Verdicts

One verdict per stated behaviour: **(i)** it rests on a stated why that fits this client; **(ii)** on a stated why that does not transfer; **(iii)** on no stated why.

### 1. A run id and positions: (ii), a stated why that does not transfer whole

`CONTEXT.md` says the run id and position follow Kafka's per-producer sequence number, "the only documented way to recognise a duplicate". That claim is wrong (claims row 6), and Kafka's stated why transfers only in part. The failure KIP-98 answers, a retry after a lost acknowledgement, is this client's. But the reasons for Kafka's shape (a broker-assigned id, sized for the message set; a continuity check a broker enforces with bounded memory) rest on constraints this client does not share. So Kafka informs the position; it does not justify it.

The two halves split. **The run id** rests, as a UUID, on a stated why that fits: RFC 9562's reason for UUIDs in general over sequential keys, that coordinating sequential identifiers across a network "can easily become a burden" and UUIDs need no coordination (§2.1), fits runs minted with no coordination. Its reasons for a time-ordered version such as UUIDv7 in particular (§2.1: database-index locality, a common epoch, ordering by byte comparison) apply only if something sorts or indexes by run id, which no decision says, so for version 7 in particular the RFC informs the choice. A further reason, that version 7 has "improved entropy characteristics" over versions 1 and 6 (§5.7), does not depend on order, but compares version 7 only with those two time-based versions, so it too informs the choice; and the RFC says nothing about one identifier per run. **The position** as an identity for a repeat is informed by Kafka's why, and by the stated whys of comparables that recognise an id the sender assigns (Azure Service Bus, O8) or a position in the sender's log (PostgreSQL, C14). Azure Service Bus's reason, that an id the application controls can be "predictably reconstructed when a failure occurs", holds for any identity the sender keeps across a re-send, which is verdict 3, and says nothing of a counter in particular. PostgreSQL's, that a client may record the last LSN it saw and skip repeats, is for a replay point rather than an identity for each output: in its documentation's example a transaction's `BEGIN` and its `INSERT` carry one LSN (C14). As the unit a collector confirms, it is informed by Kafka's stated why for consumer offsets (C11), which Kafka's design ties to one consumer per partition in a group; which collector confirms here is open question 7.

**Proposed wording for the maintainer**, replacing the last two sentences of the bullet on recognising a duplicate under "When buffered data may be deleted" in `CONTEXT.md` (the ticket does not edit that file):

```text
Documented ways to recognise a repeat include a producer identity with a sequence number (Kafka, Pulsar), an id the sender assigns to each message (NATS, SQS FIFO, Azure Service Bus, Elasticsearch), content (Elasticsearch time series, Prometheus), and a position in the sender's log that the receiver may record (PostgreSQL). The run id and position in the specification are an id the sender assigns to each row. Kafka's idempotent producer informs them, since it answers the same failure, a retry after a lost acknowledgement; its broker-assigned producer id, its continuity check and its bounded broker memory do not transfer. Kafka's consumer offset informs the position a collector confirms: one integer stands for what has been received, which Kafka's design ties to one consumer per partition in a group.
```

No change to the specification's text is proposed: `Run.id` and `PositionsOnlyIncrease` cite no comparable.

### 2. Purge only after confirmation: (i), a stated why that fits

Two comparables state a reason for waiting for the downstream side that fits this client within a run: Filebeat's review of `delete.enabled` (C3: not discarding data still to be sent), though with the disk queue on, the acknowledgement Filebeat waits for is the write to that queue; and PostgreSQL's slots (C14: keep what the receiver still needs while it is away). SQS also states a reason, for keeping a received message until the consumer deletes it (O5: so that a message is not lost if its first processing fails). It shares the rationale, keeping a copy while the receiver may still fail, but its threshold differs: SQS waits for the consumer to process the message and delete it itself, where here the collector states the highest position it has safely received (`ConfirmPosition`) and the client purges later. So it informs the rule. Pulsar states what an acknowledgement is for, that the message can be deleted, and no reason beyond that (C12). The OpenTelemetry Collector states why it keeps data on disk at all (C4: data lost on overfill or crash), but not why it waits, and its delete rule does not transfer. Fluent Bit's proposal for its size limit gives a user's reason for keeping a copy until it is delivered, to be buffered locally while the network is down "so that I will not lose logs" (C6), though by default its engine discards a chunk after one failed retry. Vector's end-to-end acknowledgement RFC says that a buffer which finalizes events once they are persisted will need to "only purge events from the buffer once they are delivered" (C5); that its motivation, assurance that every event is delivered, is the reason for that wait is Inferred, and the code at `v0.62.0` deletes on any finalization, a failure or a drop included. Both inform the verdict and do not carry it.

The asynchronous purge has one stated reason that fits within a run, Vector's (C5: a failed delete is retried at a later scan, while the data writer runs). Vector's retry after the process exits needs a later process to open the same buffer, where nothing is purged once the data writer has stopped (Derived, `PurgeRow`) and what a later establish does with a previous run's databases is open question 6. Two more statements concern one operation holding up another, and both only inform it. The libbeat disk queue's author kept its deleter in a loop of its own, to keep any one operation from blocking the others: an error deleting an old segment should not stop writing to the current one (C3). Before the change, a TODO in Vector's reader asked whether the delete could become a background task, to take its tail latency off the read path (C5); it is a question in the code, and no reason for the change was found in the pull request that made it. Either needs a path the purge would hold up: here the purge is already off the hot path (`PurgeRow`), and is the data writer's own work beside storing (Derived, `PurgeRow`); whether purging in the same step would slow storing depends on a storage engine that is undecided, and no rule says what a failed purge does. Kafka's two reasons (C10) are that delete requests sent to the brokers at every commit cost throughput and log volume, where this client's purge is local work, and that a reader may still have a segment open, which applies only if something reads the local databases while the data writer purges. These rest on premises not shown for this client, so they inform the asynchronous purge and do not justify it. The verdict's category rests on Filebeat's and PostgreSQL's reasons for waiting.

The fit holds within a run and no further. Each comparable that waits is a long-lived holder, or keeps its position across a restart: Filebeat's registry, the Collector's queue at its next start, a PostgreSQL slot across crashes. A run can end with stored rows unconfirmed, and nothing is purged once its data writer has stopped (Derived, `PurgeRow`). What a later establish does with them is open question 6, and no comparable read says anything about it that transfers.

Two further qualifications go with the verdict, and both are findings, not proposals. The survey's description was wrong. Those buffers also delete without a confirmation: on a failure, at once or after retries (C4, C6); on any finalization, a drop included (C5); or at a size or time bound (C6, C9, C14); and an "acknowledgement" can be an intermediate hop's or include a drop (C3, C5). And the reasons for the bound are stated as firmly as the reasons for waiting: PostgreSQL added its bound because unbounded retention filled the disk (C14). The specification already names its bound as the one exception (`PurgedRowsWereConfirmed`), and leaves it to open question 8.

### 3. A re-send keeps its position: (i), a stated why that fits

PostgreSQL states the case exactly: after a crash, changes are sent again, and clients "may wish to record the last LSN they saw when decoding and skip over any repeated data" (C14). Azure Service Bus states why the sender should control the identifier: so that it "can be predictably reconstructed when a failure occurs" (O8); a position stored with its row is such an identifier. OTLP states why a repeat is acceptable for telemetry at all (C7), and KIP-98 why one occurs (C1). These fit a client that, within a run, hands over what is still unconfirmed and may hand it over again. Azure Service Bus names two cases (O8): a sender restarted after a fatal error, and a send committed whose acknowledgement did not reach the client, which can happen while the sender is still running, within one run. PostgreSQL's case is a server that restarts and sends again from a position persisted in its own log (C14). Within a run, the lost acknowledgement fits as it stands. The restart cases, Azure Service Bus's restarted sender and PostgreSQL's server, need a sender that reconstructs the same identity after a restart; a new establish mints a new run id, so they transfer to a previous run's rows only if those are handed over after their process has gone, which is open question 6.

The guarantee says a repeat is *recognisable*; whether a collector recognises one depends on what it remembers, and a collector's internals are outside the specification (`Collector`). The comparables that recognise a repeat differ in what the receiving side remembers, who keeps it and for how long: an id for a window (NATS, SQS FIFO, Azure Service Bus), one exchange in flight (MQTT), up to five batches per producer for a day by default (Kafka), the newest in-order sample per series (Prometheus), a document while it exists (Elasticsearch), or a last position the client may choose to record (PostgreSQL).

## Corrections to the survey in `CONTEXT.md`

The ticket does not edit `CONTEXT.md`. The claims table above shows which survey statements are wrong or partly wrong. For the maintainer, replacement wording for the bullets under "When buffered data may be deleted", besides the one given under verdict 1:

```text
- Durable local buffers wait for the downstream side before deleting, and also delete without it: on a failure, at once or once retries run out (the OpenTelemetry Collector, Fluent Bit); on any finalization, a failure or a drop included (Vector); and at a size or time bound (Fluent Bit, the Prometheus agent, PostgreSQL slots). What counts as confirmation varies: an intermediate queue's write (Filebeat with a disk queue, Vector's source acknowledgement), and drops counted as acknowledged (Filebeat, Vector).
- The OpenTelemetry SDK's batch processor drops a failed batch after the exporter's retries; OTLP accepts the duplicates retries cause, and defines no way to recognise them.
- A Prometheus client holds current values only, with no rows waiting for collection; the server deletes by time or size. Kafka retains by time or size, and `DeleteRecords` deletes below an offset its caller supplies.
- Asynchronous purges after what each counts as confirmation are documented by Vector, the libbeat disk queue, Filebeat's `delete.enabled`, Pulsar, PostgreSQL and Kafka Streams.
```

## What the findings bear on in the specification

This section reports. It recommends no answer to any open question.

- **Open question 7, which collector confirms when more than one reads an instance.** In Kafka and PostgreSQL a single confirmed integer is kept for one reader at a time and stands for what that reader has consumed: Kafka's offset is per consumer group, with one consumer per partition in a group (C11), and a PostgreSQL slot has one receiver at a time (C14). A NATS consumer with `AckAll` is different: acknowledging a message acknowledges every earlier one, and for a pull consumer it covers the pending messages of all its subscribers (C13). Where several readers each need the data, each keeps its own position or acknowledgements, and where deletion follows acknowledgement it waits for all of them: Pulsar trims below the slowest durable cursor's position, one position derived from many, and with deduplication on, its own cursor holds the trim back too (C12); NATS interest streams delete once every interested consumer acknowledges or terminates, while a work queue deletes on the first (C13); and PostgreSQL keeps WAL until no slot needs it (C14). Where several readers share the work of one partition instead, Kafka's share groups acknowledge records one by one (C11), and deletion still follows the topic's retention, by time or size, not those acknowledgements, as in plain Kafka, where committing an offset deletes nothing (C10, C11). Prometheus avoids the question: nothing is confirmed or purged, so several scrapers read one target without interfering (C8). OTLP's maintainer objected to a request-level identity because load-balanced collectors would have to coordinate to share it, and its author withdrew it for another reason (C7).
- **Open question 8, what bounds the local databases when no collection happens, and what is lost at the bound.** Every durable comparable read can be bounded, and they lose in different places; Filebeat's disk queue can also be left unbounded (C3). Fluent Bit frees space at `storage.total_limit_size` in a fixed order of steps, oldest first within an input but not across inputs (C6); PostgreSQL invalidates a slot that overruns `max_slot_wal_keep_size`, releasing its WAL (C14); the Prometheus agent drops, at each truncation and only from the older segments it checkpoints, samples below a cut-off that trails the current time by at most `MaxWALTime`, sent or not (C9); Kafka retains by time or size and a lagging consumer loses what retention passed (C10). Others refuse or block the newest instead: the OpenTelemetry Collector rejects new data at `queue_size` or blocks if configured (C4), Vector blocks by default or drops the newest (C5), and Filebeat's disk queue pauses an input or discards, per input (C3). Pulsar bounds an unacknowledged backlog by a TTL or a quota with a discarding policy (C12). The stated reasons for a bound are the host's disk: Fluent Bit's issue #2408 (C6) and PostgreSQL's commit c655077 (C14).
- **Open question 15, whether the hand-over is a push or a pull, and in what form.** Pull comparables: the Prometheus client, which holds no rows (C8); Kafka consumers, which pull from a broker and commit an offset (C11); SQS consumers, which receive and then delete (O5); and Pub/Sub, whose exactly-once delivery is pull-only because a push subscriber cannot know its acknowledgement arrived (O7). Push comparables: Filebeat, the OpenTelemetry Collector, Vector and Fluent Bit (C3 to C6), and OTLP (C7). PostgreSQL's receiver is in neither list: it opens a stream from a slot, the server then streams WAL on it, and the receiver reports positions back (C14). Kafka's handbook rejected a producer that keeps a local log for brokers to pull from, for its own target of thousands of producers (C10).
- **Open question 25, whether a hand-over also carries the stored position.** Kafka's sequence detects loss because it is contiguous by construction: where the partition leader holds the producer's state, a gap is an out-of-sequence error (C1). Pulsar's allows holes, and so a gap tells it nothing (C12). This client's positions have gaps by design. If a hand-over offers nothing above the stored position, which is marked Derived, then between the confirmed position and the highest position offered a missing position is a row lost or a keyed value replaced; above that, up to `last_position`, a row still waiting and a row lost look alike, which is the question as stated. PostgreSQL keeps two positions for a slot, what the consumer confirmed and the oldest still needed (C14); Vector's ledger keeps a reader and a writer position (C5). Kafka's fetch response sends its receiver, beside the records, marks for each partition: its high watermark; its last stable offset, the last offset below which every transactional record has been decided; and its log start offset (C11). PostgreSQL's protocol documentation gives each XLogData message and each keepalive a field for the current end of WAL on the server, and in a logical stream its walsender fills that field otherwise: XLogData carries the `lsn` passed to the write, or zero, and a keepalive `writePtr` or `sentPtr` (C14). What these marks mean was not compared with the stored position, and whether the other comparables send such a mark was not researched.
