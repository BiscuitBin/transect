# Research: who stamps a row's time

- **Ticket:** `issues/01-research-who-stamps-a-rows-time.md`, open question 11 of `docs/specs/transect-client.allium`: "Is a row's time stamped by the client only, or may application code supply it, and what are its name and precision? Until decided, the client stamps every accepted row."
- **Sources read:** 2026-11-24 (UTC). Every link below was read that day.
- **Web research:** authorised by the maintainer in the session that picked this ticket up, for the researcher and for the reviewers.
- **Status:** findings, fit, options, a recommendation and proposed wording, for the maintainer to decide. Nothing here decides question 11, and the specification is not edited.

## How the sources were checked

- Each comparable was read from its official documentation, a specification, or source code at a named tag or commit. GitHub links are pinned to a tag or a commit, except issue and pull request threads, which have no version. Apache JIRA issues are linked by their browse URL, Confluence pages (Kafka KIPs) by page id, and Apache mailing-list messages by their thread URL. The AWS documentation is unversioned; its pages were read as the Markdown rendition the site serves. The Redis `RESTORE` command page on redis.io, the Firebase pages on firebase.google.com, the systemd journal's design document (a published Google Doc) and the 0pointer.net post that links it are unversioned too, and were read as HTML; the systemd man pages are the HTML that freedesktop.org serves for version 260. QOS.ch JIRA issues are linked by their browse URL, except two quotations found only in an issue's REST rendition (a comment, and a description in JIRA wiki markup), which are linked by that REST URL.
- Every blockquote sits under the `Source:` line it was copied from. Each was checked as a substring of raw source text the researcher fetched again: GitHub files from `raw.githubusercontent.com`, GitHub threads through the GitHub API, Apache JIRA issues through the JIRA REST API, Confluence pages through the Confluence REST API, mailing-list messages through the Apache mail archive's API, and the HTML pages above, including the QOS.ch JIRA's browse pages, with their tags stripped. 396 quotations were checked; 383 match exactly, and 13 match only once whitespace is collapsed (two issue bodies with different line endings, three code comments whose indentation differs, and eight passages of the systemd man pages, whose HTML wraps lines).
- A quotation inside a sentence was checked the same way.
- What no primary source confirmed is marked "Unverified". A reason the researcher worked out, and no author stated, is marked "Inferred".

## The shape being looked for

The client stamps every accepted row from its own clock, under the name `client_time`. A time series table appends rows; a keyed state table holds the latest value per key, and its time records when the value was last written. Settled, and not reopened: within one process the client's clock never moves backwards, and there is no ordering promise across processes.

For each comparable the survey asks:

- who stamps the time: the library, the application, a receiver or store, or more than one of them, each under its own name;
- whether application code may supply or override a time, and how;
- the field's name, its precision, its epoch and its representation;
- what happens to a supplied time that is in the future, in the past, or out of order;
- which clock stamps it, where that is documented;
- and the reasons its authors gave for each of those choices.

Two families, as the maintainer asked: application logging frameworks and collection systems for time series tables (T1 to T13), and comparable keyed-state systems for keyed state tables (K1 to K11). Kafka appears in both: T12 covers who stamps a record, K4 what a compacted topic and a KTable do with that time.

### Summary: time series

| System | Who stamps | May the application supply a time? | Field, precision, epoch | Supplied time in future / past / out of order | Clock when it stamps |
| --- | --- | --- | --- | --- | --- |
| OpenTelemetry logs | Source sets `Timestamp`; OTel code sets `ObservedTimestamp` when it first sees the record (the in-process SDK too) | Yes, both, through the emit API | `uint64` ns since Unix epoch, two fields | Not specified by the data model | Not specified (an early monotonic requirement was dropped) |
| OpenTelemetry traces and metrics | API or SDK, defaulting to now | Yes: span start and end; metric points carry start and time | ns since Unix epoch | Not specified | Java SDK: wall clock anchored once, then advanced by `System.nanoTime()` |
| Python `logging` | `LogRecord` constructor | No direct parameter; `extra` cannot overwrite `created`; a record factory or `makeLogRecord` can | `created`: float seconds; `msecs`; `relativeCreated` ms since module load | Not applicable | `time.time_ns()` (wall) |
| Log4j 2 | Core, through a pluggable `Clock` | Yes, through a message implementing `TimestampMessage`; the clock is pluggable | `Instant` (2.11+), up to ns where the JVM provides it; millis also exposed | Not checked | `log4j2.clock`, default `SystemClock` |
| Logback / SLF4J 2 | Logback's `LoggingEvent` constructor | Not through the SLF4J API or fluent builder; Logback's event has a public `setInstant` | `Instant` since 1.3; millis `timeStamp` and `nanoseconds` | Not applicable | `Clock.systemUTC()` |
| Rust `tracing` | Each subscriber or layer, when it formats | No: events carry no timestamp | Formatter-defined | Not applicable | `SystemTime::now()` by default; `Uptime` uses `Instant` |
| Elastic Common Schema | Source or pipeline (`@timestamp`), agent (`event.created`), store (`event.ingested`) | `@timestamp` is the source's time | `date`, three fields | Order expected `@timestamp` < `event.created` < `event.ingested` | Not specified |
| Fluentd / Fluent Bit | Input plugin, a parser (`time_key`), or the sending client | Yes: forward protocol and logger libraries carry the client's time | `EventTime` (sec + ns) or integer seconds | Not checked, except that the forward input replaces a zero time with its own current time | `Time.now` (Fluentd); `timespec_get(TIME_UTC)` (Fluent Bit) |
| Grafana Loki | Client (push API) | Yes; the push format has a timestamp slot in every entry (Inferred: required) | ns since Unix epoch, as a string in JSON | Rejected if older than `reject_old_samples_max_age` (1w) or beyond `creation_grace_period` (10m); out of order accepted by default since 2.4, back to the stream's newest entry minus `max_chunk_age`/2 (1 h by default) | Bounds are relative to the current time (Inferred: the server's clock) |
| InfluxDB | Client, or server when absent | Optional per point | Unix timestamp, default ns, `precision` parameter | Points outside retention rejected; same series and timestamp merges fields | Server host clock (UTC) when absent |
| Prometheus | Server at scrape time | Exposition format allows it; docs say not to; `client_golang` exposes it with caveats | `int64` ms since epoch | Out of order rejected unless `out_of_order_time_window` > 0; on scrape, a sample more than 10 min ahead of the server is dropped | Server |
| Apache Kafka | Producer (`CreateTime`) or broker (`LogAppendTime`), per topic | Yes: `ProducerRecord` timestamp | `int64` ms since epoch | Bounded by `message.timestamp.before.max.ms` / `after.max.ms`; whole batch rejected | `System.currentTimeMillis()` in the producer |
| systemd journal | Journal daemon on receipt (`__REALTIME_TIMESTAMP`, `__MONOTONIC_TIMESTAMP`, `__SEQNUM`); a trusted source time when known (`_SOURCE_REALTIME_TIMESTAMP`) | No for the journal's own stamps or trusted fields; `SYSLOG_TIMESTAMP` is accepted unvalidated | µs: realtime since Unix epoch, monotonic per boot id | No validation found (Unverified) | `CLOCK_REALTIME` and `CLOCK_MONOTONIC` at reception |

### Summary: keyed state

| System | Who stamps by default | May application code supply it? | Field, precision, epoch | Future / too old / out of order | Stated why found? |
|---|---|---|---|---|---|
| Cassandra | Driver (client side) since Java driver 3.0; coordinator if no client time | Yes: `USING TIMESTAMP`, per-statement, pluggable generator | cell `WRITETIME`, int64 microseconds since Unix epoch (by convention) | Accepted; last write wins; optional guardrail since 5.0 rejects outside a window | Yes, extensive (CASSANDRA-6178, -6106, -4947, -18352) |
| HBase | RegionServer | Yes (`Put` with explicit timestamp); docs advise against | cell timestamp, int64 milliseconds since Unix epoch (server `currentTimeMillis`) | Accepted; highest timestamp is the "latest"; future deletes mask later puts | Yes (HBASE-10247, -14070, -18642, -9905) |
| Flink state TTL | Flink runtime (`TtlTimeProvider`) | No (processing time only; the provider is internal) | `lastAccessTimestamp`, long ms from `System.currentTimeMillis()` | n/a (no supplied time) | Partly: event-time TTL debated (FLINK-12005, dev thread), never landed |
| Kafka (compacted topic / KTable) | Producer library (`CreateTime`) or broker (`LogAppendTime`), per topic; in Kafka Streams the `TimestampExtractor` decides what a KTable stores (processing time with `WallclockTimestampExtractor`) | Yes (`ProducerRecord` timestamp) under `CreateTime` | record timestamp, int64 ms since Unix epoch | Broker rejects outside `before/after.max.ms` (future default 1 h since 4.0); compaction keeps highest offset, not highest timestamp | Yes (KIP-32, KIP-937, KIP-258, KIP-280, KIP-914) |
| Redis | Server eviction clock: on access and write (LRU), on write only (LRM, 8.6+); LFU data under LFU | Not on the write path; `RESTORE … IDLETIME` sets it (K5) | 24-bit `lru` field, 1 s resolution, wraps | n/a | For LRM's purpose only (PR 14624); none for omitting a general write time |
| etcd | Server (Raft-ordered revision counter, not time) | No | `create_revision`, `mod_revision`, int64 logical | n/a | Revisions documented as a logical clock; no stated reason for omitting wall time found |
| Kubernetes | API server (`creationTimestamp`, `managedFields[].time`); kubelet for `lastHeartbeatTime`, Lease `renewTime` | `creationTimestamp`: no. Heartbeat/renew: the writing client stamps | RFC 3339 seconds (`Time`) or microseconds (`MicroTime`), UTC | Node controller ignores the writer's clock for liveness; uses its own local observation time | Yes (node lifecycle controller comment; KEP-589 for the Lease move) |
| DynamoDB | No item write time at all; stream records stamped by the service | Item attributes: the application, or opt-in stamping by the Java SDK v2 Enhanced Client on a tagged attribute. Stream time: no | `ApproximateCreationDateTime`: seconds (Streams), ms or µs (Kinesis destination) | Global tables: last writer wins on an internal timestamp under MREC (the default); MRSC rejects a concurrent write; TTL ignores > 5 years past | No stated rationale found |
| OpenTelemetry metrics (Gauge) | SDK at measurement / collection | No (requested and declined) | `time_unix_nano`, fixed64 ns since Unix epoch | n/a | Yes (spec issue #4343) |
| ZooKeeper | Server (the leader's wall clock, in the transaction header) | No | `mtime`/`ctime`: int64 ms since Unix epoch; `mzxid`/`czxid`: transaction ids | n/a | No, for keeping wall time beside the zxid; ZOOKEEPER-1366 records keeping `mtime` on wall time |
| Cloud Firestore | Service (`create_time`, `update_time`) | No (output only); a write may ask for the server's time in an application field (`REQUEST_TIME`) | `update_time`, `google.protobuf.Timestamp`, RFC 3339 over REST; preconditions microsecond aligned | n/a (no supplied time) | No stated rationale found |

## Time series

### T1. OpenTelemetry logs data model

**Analogy.** Close. A record-per-event data model shared by in-process SDKs and an
out-of-process collector, with an explicit answer to who stamps. Family: time series.

**What it does.** Specification `v1.63.0`, proto `v1.11.1`, Python SDK `v1.45.2`.

- Two fields. `Timestamp` is the time at the source, by the origin clock, and is optional.
  `ObservedTimestamp` is when OpenTelemetry's code first observed the event. Both are
  `uint64` nanoseconds since the Unix epoch.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/logs/data-model.md

  > Type: Timestamp, uint64 nanoseconds since UNIX epoch.
  >
  > Description: Time when the event occurred measured by the origin clock, i.e. the
  > time at the source. This field is optional, it may be missing if the source
  > timestamp is unknown.

  > Description: Time when the event was observed by the collection system. For
  > events that originate in OpenTelemetry (e.g. using OpenTelemetry Logging SDK)
  > this timestamp is typically set at the generation time and is equal to
  > Timestamp. For events originating externally and collected by OpenTelemetry
  > (e.g. using Collector) this is the time when OpenTelemetry's code observed the
  > event measured by the clock of the OpenTelemetry code. This field SHOULD be set
  > once the event is observed by OpenTelemetry.

  > - Use `Timestamp` if it is present, otherwise use `ObservedTimestamp`.

- **The unchecked claim.** OTel's name is `ObservedTimestamp` (`observed_time_unix_nano`
  in OTLP), not `observed at`. It is the time OpenTelemetry's own code first saw the
  event, which for an event born in an in-process SDK is the generation time and
  typically equal to `Timestamp`. It is therefore not specifically a collecting or
  receiving side's time: the in-process SDK sets it too. The data model says SHOULD set;
  the proto comment says MUST.

  Source: https://github.com/open-telemetry/opentelemetry-proto/blob/v1.11.1/opentelemetry/proto/logs/v1/logs.proto

  >   // Collector) this is the time when OpenTelemetry's code observed the event measured
  >   // by the clock of the OpenTelemetry code. This field MUST be set once the event is
  >   // observed by OpenTelemetry.

  >   // Value of 0 indicates unknown or missing timestamp.

- The application may supply either time. The Logs API's emit operation takes both as
  optional parameters; the SDK fills `ObservedTimestamp` with the current time if absent,
  and leaves `Timestamp` unset if absent.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/logs/api.md

  > - [Timestamp](./data-model.md#field-timestamp) (optional)
  > - [Observed Timestamp](./data-model.md#field-observedtimestamp) (optional)

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/logs/sdk.md

  > If [Observed Timestamp](./data-model.md#field-observedtimestamp) is unspecified,
  > the implementation SHOULD set it equal to the current time.

- The Python SDK's bridge from the standard `logging` module takes `Timestamp` from the
  `LogRecord`'s own `created` time and stamps `ObservedTimestamp` itself, with
  `time.time_ns()`.

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_logs/_internal/__init__.py

  >         timestamp = int(record.created * 1e9)
  >         observered_timestamp = time_ns()

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/_logs/_internal/__init__.py

  >         if observed_timestamp is None:
  >             observed_timestamp = time_ns()

- Future, past and out-of-order times: the data model, API and SDK pages read say nothing
  about validating them. A case-insensitive search for `future`, `past` and `order` in
  the three files finds only unrelated text (processor order, filtering, an export
  future).
- Clock: not specified. OTEP 0097 records that a monotonic, NTP-synchronised requirement
  was drafted and removed (quoted below).

**Stated why.**

- The second field came from collection, not from SDKs. The issue that led to it listed
  three ways a log record gets a time, and the problems of having one field for all.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/1875

  > 1. It can be set by a library supporting OTLP natively
  > 2. It can be parsed out from the log Body or Attributes (e.g. using [timestamp operator](https://github.com/open-telemetry/opentelemetry-log-collection/blob/main/docs/types/timestamp.md) for filelogreceiver)
  > 3. It can be set to receipt timestamp (which is a good fallback when the others are not available or fail)

  > * Inability to fallback to receipt timestamp when parsing yielded incorrect value (also, no easy ability to find records with potential timestamp parsing errors)
  > * No way to to tell using what method the timestamp was assigned to the record 
  > * Lack of data to measure delay between log occurrence and log being collected

- The Log SIG's decision, recorded by tigrannajaryan (GitHub association: MEMBER), names
  the gap between the two times as a diagnostic.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/1875#issuecomment-965665616

  > We probably want 2 fields: ObservedTimestamp and SourceTimestamp (names preliminary). ObservedTimestamp is the time when event was first observed in Otel (generated by Otel SDK or collected by Otel Collector). SourceTimestamp is what we could extract from the source (e.g. parse from file, copy from another protocol, etc).

  > If SourceTimestamp and ObservedTimestamp differ significantly it can be an indication that something went wrong (lagging collection, incorrect parsing, etc).

- Why `Timestamp` kept the source meaning, from djaglowski (MEMBER):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/1875#issuecomment-965695729

  > In addition to what Tigran captured, I think it's important to note that first party applications would directly populate the SourceTimestamp as the log is created. 

  > My rationale is that the SourceTimestamp is fundamentally associated with the event itself, but that the ObservedTimestamp is only context about how the event was processed.

- An earlier objection to adding a field at all, from tigrannajaryan:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/1875#issuecomment-919599800

  > I think adding a second timestamp field can be justified if we have a strong evidence that it will be populated in significant portion of cases. I am not certain that is going to be the case. Also, it is possible to imagine more than 2 types of timestamps. Are we going to add all those possible types of timestamps as fields and have them almost always unspecified?

- Why `Timestamp` is not defaulted to now (issue 3386, resolved as won't do): the emit API
  is for bridges, whose logging library has already captured the time, and an unset field
  must stay able to say the time is unknown.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3386

  > The one opposing argument I can think of is that somehow the user obtains the log record externally, and the external source does not include the information about when the log record was created. In this case keeping the Timestamp unspecified is desirable, to indicate that it is unknown.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3386#issuecomment-1505758956

  > Yes, exactly. If you are implementing a bridge/appender you already have a timestamp that was captured for you. You just need to pass that along. For bridge authors there is no value in having a default of "now".

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3386#issuecomment-1506924773

  > @open-telemetry/specs-logs-approvers I am resolving this as "won't do" (i.e. we will leave Timestamp unspecified if the caller does not specify it).

- Why `ObservedTimestamp` defaults to the current time rather than being left unset
  (pull request 3385). Two members proposed leaving it unset to save bytes; the data
  model's intent won.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/3385#discussion_r1164519850

  > A non-blocking suggestion - could we leave it unset, so the SDK doesn't have to duplicate the info and waste the storage/network. The receiver should be able to handle the unset value by using the Timestamp.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/3385#discussion_r1164563145

  > I have always understood `ObservedTimestamp` to be the time at which OpenTelemetry first observed the log, and that we should set it to the current time at the first opportunity. 

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/3385#discussion_r1164714981

  > I think we should still allow the Bridge API to accept a value from the caller, not force the current time. A bridge implementation can be considered part of Otel and may want to set the ObservedTimestamp equal to Timestamp, knowing that Timestamp was just observed (because that's what logging libraries do).

- Clock requirements were left out of the data model on purpose.

  Source: https://github.com/open-telemetry/oteps/blob/67dc8ec420cf85ca80d03e578ffe9fdf528f202c/text/logs/0097-log-data-model.md

  > Question: Early draft of this proposal specified that `Timestamp` should be
  > populated from a monotonic, NTP-synchronized source. We removed this requirement
  > to avoid confusion. Do we need any requirements for timestamp sources?
  >
  > Answer: discussions revealed that it is not data model's responsibility to
  > specify such requirements.

**Constraints.** The data model serves both first-party SDK logs and logs collected from
files and other protocols, where the source time may be missing or parsed wrongly. OTEP
0097 originally had one optional `Timestamp`; `ObservedTimestamp` was added in December
2021 (pull request 2184, merged 2021-12-10) before the data model was declared stable.

**Costs and dissent.** Duplicating the time in every SDK record costs bytes on the wire
(reyang's and trask's comments on pull request 3385, above). tigrannajaryan answered that
an identical value will likely compress well (same comment as the third 3385 quotation;
not quoted further).

### T2. OpenTelemetry traces and metrics (supplementary)

**Analogy.** Looser: span start and end times describe an operation, not an appended row.
Included for the caller-supplied-time rule and the Java clock.

**What it does.** The trace API takes an optional start timestamp and an optional end
timestamp, defaulting to the current time, and tells callers not to set the start when
the span starts now. Timestamps are time since the Unix epoch, at millisecond to
nanosecond precision.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/api.md

> - `Start timestamp`, default to current time. This argument SHOULD only be set
>   when span creation time has already passed. If API is called at a moment of
>   a Span logical start, API user MUST NOT explicitly set this argument.

> - (Optional) Timestamp to explicitly set the end timestamp.
>   If omitted, this MUST be treated equivalent to passing the current time.

> A timestamp is the time elapsed since the UNIX epoch.
>
> * The minimal precision is milliseconds.
> * The maximal precision is nanoseconds.

The metrics data model gives points a `time_unix_nano` and an optional
`start_time_unix_nano`; the start time lets a consumer see gaps and overlapping writers.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md

> When the `StartTimeUnixNano` field is present, it allows the consumer
> to observe when there are gaps and overlapping writers in a stream.

**Clock (Java SDK, `v1.68.0`).** Span times are wall-clock time read once at the local root
span, then advanced by the monotonic `System.nanoTime()`.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/AnchoredClock.java

>  * A utility for returning wall times anchored to a given point in time. Wall time measurements will
>  * not be taken from the system, but instead are computed by adding {@linkplain System#nanoTime()
>  * monotonic time} to the anchor point.

>  * <p>This is needed because Java has lower granularity for epoch times and tracing events are
>  * recorded more often. There is also a performance improvement in avoiding referencing the system's
> * wall time where possible.

The method that returns the time says its result can be used for durations; it adds
monotonic elapsed time to the anchor and never reads the wall clock again.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/AnchoredClock.java

>    * Returns the current epoch timestamp in nanos calculated using {@link System#nanoTime()} since
>    * the reference time read in the constructor. This time can be used for computing durations.

>     return epochNanos + deltaNanos;

**Stated why** for the start-timestamp rule: none found beyond the quoted text.

**Constraints.** Spans and metric points are produced in-process by the SDK. None stated
beyond the Java clock note.

**Costs and dissent.** None found in the pages read.

### T3. Python `logging`

**Analogy.** Close for in-process stamping: every record is stamped by the library when
it is constructed. Family: time series.

**What it does.** CPython `v3.15.2`.

- The `LogRecord` constructor reads `time.time_ns()` once and derives three fields:
  `created` (float seconds since the epoch), `msecs` (the millisecond part) and
  `relativeCreated` (milliseconds since the logging module was loaded).

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py

  >         ct = time.time_ns()

  >         self.created = ct / 1e9  # ns to float seconds

  >         self.relativeCreated = (ct - _startTime) / 1e6

  Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.rst

  > | created        | ``%(created)f``         | Time when the :class:`LogRecord` was created  |
  > |                |                         | (as returned by :func:`time.time_ns` / 1e9).  |

- No logging call takes a time. The `extra` mapping cannot overwrite an attribute the
  record already has, so `extra={"created": ...}` raises `KeyError`.

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py

  >                 if (key in ["message", "asctime"]) or (key in rv.__dict__):
  >                     raise KeyError("Attempt to overwrite %r in LogRecord" % key)

- Two documented hooks can produce a record with another time: a custom record factory
  (since 3.2) and `makeLogRecord`, which builds a record from an attribute dictionary,
  for example one received over a socket.

  Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.rst

  >       This function has been provided, along with :func:`getLogRecordFactory`, to
  >       allow developers more control over how the :class:`LogRecord` representing
  >       a logging event is constructed.

  >    Creates and returns a new :class:`LogRecord` instance whose attributes are
  >    defined by *attrdict*. This function is useful for taking a pickled
  >    :class:`LogRecord` attribute dictionary, sent over a socket, and reconstituting
  >    it as a :class:`LogRecord` instance at the receiving end.

- Clock: the wall clock (`time.time_ns()`); `relativeCreated` is a difference of two wall
  readings, not a monotonic reading.

**Constraints.** Records are created in the calling thread by the logger; the record
constructor is the one place a time is taken (Inferred from the code quoted).

**Stated why.** The switch from `time.time()` to `time.time_ns()` (gh-102402, commit dated
2024-04-16; the first release containing it was not checked) was made to fix a float
rounding bug in `msecs`, not to change who stamps.

Source: https://github.com/python/cpython/issues/102402

> `LogRecord.msecs` returns an incorrect value when timestamp (`self.ct`) value has exactly 100ms.

Source: https://github.com/python/cpython/issues/102402#issuecomment-1454072261

> I agree with @dougthor42 about the proposed solution, since [time library itself suggests](https://docs.python.org/3/library/time.html#time.time:~:text=Use%20time_ns()%20to%20avoid%20the%20precision%20loss%20caused%20by%20the%20float%20type.) to "use time_ns() to avoid the precision loss caused by the float type".

Source: https://github.com/python/cpython/commit/1316692e8c7c1e1f3b6639e51804f9db5ed892ea

> gh-102402: Fix floating point math issue by using `time.time_ns()` in `logging.LogRecord` (GH-102412)

For why a logging call has no time parameter: **No stated rationale found.** Looked at
`Doc/library/logging.rst` and `Lib/logging/__init__.py` at `v3.15.2`, and searched the
`python/cpython` issue tracker for `time_ns logging`, `msecs` and
`logging record created timestamp override`.

**Costs and dissent.** `created` is still a float, so the public field keeps only about
microsecond resolution at current epoch values (Inferred, from the `ct / 1e9` line).

### T4. Apache Log4j 2

**Analogy.** Close: an in-process library that stamps each event, with a documented way
for the application to supply the time. Family: time series.

**What it does.** Tag `rel/2.26.1`.

- Each `LogEvent` carries an `Instant` (since 2.11) and the millisecond time.

  Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/LogEvent.java

  >      * Gets event time in milliseconds since midnight, January 1, 1970 UTC.
  >      * Use {@link #getInstant()} to get higher precision timestamp information if available on this platform.

- The stamping clock is pluggable through `log4j2.clock`; the default `SystemClock` uses
  the best system time source available.

  Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/partials/manual/systemproperties/properties-log4j-core-misc.adoc

  > It specifies the
  > link:../javadoc/log4j-core/org/apache/logging/log4j/core/util/Clock.html[`Clock`]
  > implementation used to timestamp log events.

  > SystemClock:: It uses the best available system time source.

  > SystemMillisClock:: It is similar to `SystemClock`, but truncates the result to a millisecond.
  > This implementation is garbage-free.

- The application can supply the time per event: a message that implements
  `TimestampMessage` overrides the event's time.

  Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-api/src/main/java/org/apache/logging/log4j/message/TimestampMessage.java

  >  * Messages that use this interface will cause the timestamp in the message to be used instead of the timestamp in
  >  * the LogEvent.

  `getTimestamp()` returns a `long`, so a supplied time is at millisecond precision
  (Inferred from the interface signature).
- Future, past or out-of-order supplied times: no validation found (Unverified; not
  searched beyond the interface).

**Stated why.**

- Application-supplied time (LOG4J2-53, 2011, fixed in 2.0-alpha1): applications that need
  accurate times, and that decide late whether to log a milestone.

  Source: https://issues.apache.org/jira/browse/LOG4J2-53

  > For apps which require very accurate event times, the timestamp must be provided by the app.  In log4j 1.2 it is assigned when the event is created, which is the time the event is appended.  This could be many milliseconds after the actual generation of the event.  This also gives the app the ability to collect event milestones and then choose at the end of the processing whether or not to have them sent to an appender and still control the timestamp.

  > I've added the TimestampMessage interface to the experimental Log4j 2.0. The timestamp in the message will be used.

- The asynchronous logger once ignored it (LOG4J2-455, 2013); the fix made it honour the
  message's time.

  Source: https://issues.apache.org/jira/browse/LOG4J2-455

  > But it should check the message implements TimestampMessage or not, if yes, should use TimestampMessage.getTimestamp() as the timestamp, if not , then using clock.currentTimeMillis(). 

- Nanosecond precision (LOG4J2-1883, fixed in 2.11.0, January 2018). The reporter asked
  for microseconds in the formatted time; a commenter, Anthony Maire, gave a regulation
  as the reason it mattered. The fix waited on the JVM's clock.

  Source: https://issues.apache.org/jira/browse/LOG4J2-1883

  > Having this microsecond precision will become a key feature for a logging framework in financial services, since because of the european MiFID II regulation, some trading systems will have to timestamp events with resolution of 100µs or better as of 2018.

  > The current limitations are that the only real time clock available in Java is System.currentTimeMillis(). That gives the number of microseconds since Jan 1, 1970.  System.nanoTime() gives you the number of nanoseconds since the JVM started. Since there is no way to know what the real time in nanoseconds was when the JVM started there is no way to correlate them.

  > Sorry. I misspoke. System.currentTimeMillis() give the number of milliseconds since Jan 1, 1970, not microseconds.

  > I did some rough performance tests and it seems to me that the performance of the precise clock and the millisecond clock are not significantly different.

**Constraints.** The developers wanted the precise clock to stay garbage-free and to
work on Java 7, as rpopma wrote in LOG4J2-1883.

Source: https://issues.apache.org/jira/browse/LOG4J2-1883

> As you pointed out, we would like something that is garbage free and works (perhaps with less precision) on Java 7. 

The shipped `SystemClock` documentation says it might not be garbage-free on every JRE,
and offers `SystemMillisClock` for garbage-free use without nanoseconds (quoted above).

**Costs and dissent.** LOG4J2-3498 (open) reports zero-padded micro and nanoseconds on
Linux; LOG4J2-2791 records an ordering regression in `JsonLayout` between 2.10.0 and
2.11.0 (titles only read, from the JIRA search; not quoted).

### T5. Logback and the SLF4J 2 API

**Analogy.** Close: in-process library stamping. Family: time series.

**What it does.** Logback `v_1.6.8`, SLF4J `v_2.0.20`.

- Logback stamps each event in its `LoggingEvent` constructor with `Clock.systemUTC()`,
  keeping an `Instant`, a millisecond `timeStamp` and a `nanoseconds` part.

  Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-classic/src/main/java/ch/qos/logback/classic/spi/LoggingEvent.java

  >         Instant instant = Clock.systemUTC().instant();
  >         initTmestampFields(instant);

  >      * Return the {@link Instant} corresponding to the creation of this event.
  >  *
  >      * @see {@link #getTimeStamp()}
  >      * @since 1.3

- `LoggingEvent` also has public `setInstant` and `setTimeStamp`, which code that builds
  its own events can call. The SLF4J API gives the application no way to reach them:
  the fluent `LoggingEventBuilder` has no timestamp method (grep for `imestamp` in
  `LoggingEventBuilder.java` and `DefaultLoggingEventBuilder.java` at `v_2.0.20` finds
  nothing), and when Logback receives an SLF4J `LoggingEvent` it builds a new event,
  which stamps itself, without reading the SLF4J event's timestamp (grep for `imestamp`
  in Logback's `Logger.java` at `v_1.6.8` finds nothing).

  Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-classic/src/main/java/ch/qos/logback/classic/Logger.java

  >         LoggingEvent lle = new LoggingEvent(callerBoundary, this, logbackLevel, slf4jEvent.getMessage(),
  >                 slf4jEvent.getThrowable(), slf4jEvent.getArgumentArray());

- SLF4J's own `DefaultLoggingEvent` has `setTimeStamp`, added by a commit dated 2022-09-28 so that the reload4j
  binding could stamp fluent-API events, which previously carried no time. The binding
  stamps with `System.currentTimeMillis()`.

  Source: https://github.com/qos-ch/slf4j/commit/4b5bb41ede1cf046e7bfd9dd639d43584020fb41

  > fix SLF4J-546, Fluent logging API doesn't populate timestamp with Reload4JLogger

**Stated why.** No stated rationale found for why the SLF4J API offers no caller-supplied
time. Looked at: `qos-ch/slf4j` and `qos-ch/logback` issues with `timestamp` in the
title, `qos-ch/slf4j` issues mentioning `setTimeStamp`, `qos-ch/logback` commits
mentioning `instant`, and https://logback.qos.ch/news.html (no match for `Instant`,
`getInstant` or `nanosecond`).

For Logback's move to `Instant` and sub-millisecond precision in 1.3, the request and the
change are on the QOS.ch JIRA, read through its REST API. The reason was given by the
reporter, Oleksandr Gavenko, not by a maintainer: events sorted by a millisecond
timestamp lose their order.

Source: https://jira.qos.ch/browse/LOGBACK-1374
> When sorting by @timestamp in ES events are ordered randomly within millisecond. In contrast writing to file at any precision preserves ordering.

The maintainer, Ceki Gülcü, implemented it and resolved the issue in 1.3.0-alpha12.
Neither his commit message nor his resolving comment gives a reason of his own.

Source: https://github.com/qos-ch/logback/commit/ce43569b0ffcb9430fc71fd7100065b3c022c7b0
> added support for micro seconds in LoggingEvent

Source: https://jira.qos.ch/rest/api/2/issue/LOGBACK-1374?fields=comment,description,summary
> Logback now uses java.time.Instant to store event time

**Constraints.** SLF4J is a facade over several backends, and each backend stamps its own
events (Inferred from the reload4j commit and Logback's `Logger.java` above).

**Costs and dissent.** Fluent-API events once reached the reload4j binding with no time
at all, until the 2022 commit above (SLF4J-546).

The first implementation (`ce43569`, shipped in 1.3.0-alpha11) made `getTimeStamp()`
return seconds, which broke a user's layout (LOGBACK-1599, reporter Brett Kail). The fix
(`18edd91`, 1.3.0-alpha12) kept the `Instant` and restored milliseconds.

Source: https://jira.qos.ch/rest/api/2/issue/LOGBACK-1599?fields=comment,description,summary
> the {{LoggingEvent.getTimeStamp}} method is returning seconds rather than milliseconds, which breaks our custom layout, which is currently compatible with both SLF4J 1.x and 2.x and used by projects that are using a mix of both.

Source: https://github.com/qos-ch/logback/commit/18edd9168d105124d3dbb69d21db9e8d2996c7ea
> Fix LOGBACK-1599

> this.timeStamp = (epochSecond*1000)+(milliseconds);

An open request (LOGBACK-1682, 2022, reporter Alonso Gonzalez; no comments on the JIRA
issue on the date read) asks for a configurable clock, because the application cannot
influence the stamp. It contrasts Logback with Log4j's pluggable `Clock` (T4). This is a
user's request, not the maintainers' position.

Source: https://jira.qos.ch/browse/LOGBACK-1682
> Thus the time of the server is used to generate the timestamp of an entry. In scenarios where this time is not correct, the application can not influence the timestamps.

> Would it be possibe to use a configurable clock instead of Clock.systemUTC() in logback?

### T6. Rust `tracing` and `tracing-subscriber`

**Analogy.** Close, and the opposite of the majority: the event itself carries no time;
each consumer stamps when it handles the event. Family: time series.

**What it does.** `tracing-core-0.1.36`, `tracing-subscriber-0.3.23`.

- An `Event` holds fields, metadata and a parent, and no timestamp.

  Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/event.rs

  > pub struct Event<'a> {
  >     fields: &'a field::ValueSet<'a>,
  >     metadata: &'static Metadata<'static>,
  >     parent: Parent,
  > }

- The `fmt` layer stamps at formatting time through a `FormatTime` timer. The default
  `SystemTime` reads the wall clock; `Uptime` reads elapsed time on a monotonic `Instant`.

  Source: https://github.com/tokio-rs/tracing/blob/tracing-subscriber-0.3.23/tracing-subscriber/src/fmt/time/mod.rs

  >     /// When `format_time` is called, implementors should get the current time using their desired
  > /// mechanism, and write it out to the given `fmt::Write`.

  >             datetime::DateTime::from(std::time::SystemTime::now())

  > /// Retrieve and print the relative elapsed wall-clock time since an epoch.

- The application cannot supply an event time (Inferred: it can record a field, which the
  formatter treats as any other field).

**Stated why.** A member of the project (davidbarsky, GitHub association MEMBER) declined
to put timestamps into `tracing` or `tracing-core`: it would cost every consumer that does
not want one, and it would force a clock on `no_std` users and on layers that use a
different clock.

Source: https://github.com/tokio-rs/tracing/issues/2801#issuecomment-1815498560

> This isn't an unreasonable request, but I don't know how to accomplish this without putting timestamps into `tracing`/`tracing-core`, which we're not willing to do because that imposes a cost for every layer/subscriber that doesn't care about timestamps or wants a different form of timekeeping.

Source: https://github.com/tokio-rs/tracing/issues/2801#issuecomment-1817702648

> While the universal tracing replayer is certainly an interesting capability, we'd like to continue supporting `no_std`. This means that we cannot make `std::time::{SystemTime, Instant}` a requirement.

**Constraints.** The project supports `no_std` and lets layers choose their own clock (the two quotations from davidbarsky above); many layers may handle one event.

**Costs and dissent.** Two layers writing the same event stamp it at different times.
Users reported this twice; issue 2801's reporter wanted the same time in a JSON log and a
human-readable log.

Source: https://github.com/tokio-rs/tracing/issues/2801

> As you can see, we got 2 different timestamps. This is bad for my application. I log JSON and human-readable output in the same time.

Source: https://github.com/tokio-rs/tracing/issues/2563

> I want to output logs to console and file at the same time, but found that they have different timestamps (only minor differences) and their times should be calculated separately.

Source: https://github.com/tokio-rs/tracing/issues/2801#issuecomment-1817551537

> Unfortunately, this will not work, because timestamps are not stored in `tracing`/`tracing-core`.

### T7. Elastic Common Schema

**Analogy.** Close: a schema with three named times for one event, set by three parties.
Family: time series. The schema does not stamp; producers fill it.

**What it does.** ECS `v9.5.0`.

Source: https://github.com/elastic/ecs/blob/v9.5.0/schemas/base.yml

>         This is the date/time extracted from the event, typically representing
>         when the event was generated by the source.
>
>         If the event source has no original timestamp, this value is typically
>         populated by the first time the event was received by the pipeline.

Source: https://github.com/elastic/ecs/blob/v9.5.0/schemas/event.yml

>         `event.created` contains the date/time when the event was first read by an
>         agent, or by your pipeline.

>         The difference can be used to calculate the delay between your source
>         generating an event, and the time when your agent first processed it.
>         This can be used to monitor your agent's or pipeline's ability to
>         keep up with your event source.

>         Timestamp when an event arrived in the central data store.

>         In normal conditions, assuming no tampering, the timestamps should
>         chronologically look like this: `@timestamp` < `event.created` < `event.ingested`.

All three have ECS type `date`. ECS maps `@timestamp` to both OTLP `time_unix_nano` and
`observed_time_unix_nano` (same file, `otel:` block). Precision is not set in the
schema text read (Unverified for the stored precision).

**Stated why.**

- `event.ingested` (pull request 582, by cwurm): sources can be offline, pipelines can
  back up, and an attacker can move a machine's clock.

  Source: https://github.com/elastic/ecs/pull/582

  > - An endpoint device (e.g. laptop) is running and collecting data, but is unable to send it (e.g. because it is being used offline for a while, e.g. on a plane).

  > - An attacker has gained control over a machine and has changed the system time to the distant past or future to hide security events from this machine from the usual scrutiny (e.g. queries and dashboards looking at the last N minutes/hours of data only).

  > Having the ingest timestamp in addition to the event timestamp allows making sure that all data is processed as it arrives into Elasticsearch (e.g. by a scheduled query on the ingest timestamp).

- `@timestamp` versus `event.created` (issue 326): both exist to diagnose pipeline delay
  and imprecise source times.

  Source: https://github.com/elastic/ecs/issues/326#issuecomment-464159709

  > Having both fields is specifically to help work around or understand situations as you both describe: pipeline delays and imprecise source timestamps 👍 

  Source: https://github.com/elastic/ecs/issues/326#issuecomment-464117612

  > Many log sources (especially syslog) do not use sub-second precision timestamps, which means that using a parsed value as `@timestamp` will cause Kibana to display events in the wrong order (the ordering within a second will be essentially random).

**Constraints.** Events pass from sources through agents and pipelines to a central store, sometimes after long delays, and the security use case assumes a source clock may be tampered with (pull request 582, quoted above).

**Costs and dissent.** The name `event.created` was found ambiguous (webmat, issue 326:
it reads as the event's own creation). In pull request 582, cwurm judged `event.created`
the least used of the three.

Source: https://github.com/elastic/ecs/pull/582#issuecomment-541023418

> Out of these three, I personally see `@timestamp` and `event.ingested` as essential, `event.created` maybe less so. As it stands, few data sources seem to fill `event.created` (I see it in Winlogbeat, Filebeat suricata.eve, Filebeat googlecloud.vpcflow).

### T8. Fluentd and Fluent Bit

**Analogy.** Medium: log collectors, not embedded libraries, but their client libraries
and wire protocol answer the same question. Family: time series.

**What it does.**

- Every event is a tag, a time and a record. On the forward protocol the client sends the
  time, as integer seconds or as `EventTime` (seconds plus nanoseconds). The raw wiki
  text cannot be fetched at a SHA, so the source below is unpinned; the wiki repository
  HEAD on the date read was `7781113ab3e2fb62935974cd873b7579131b88ad`, and the rendered
  page at that revision is
  https://github.com/fluent/fluentd/wiki/Forward-Protocol-Specification-v1/7781113ab3e2fb62935974cd873b7579131b88ad
  (HTTP 200 on the date read).

  Source: https://raw.githubusercontent.com/wiki/fluent/fluentd/Forward-Protocol-Specification-v1.md

  > `EventTime` uses msgpack extension format of type 0 to carry nanosecond precision of `time`.

  > - Client MAY send `EventTime` instead of plain integer representation of second since unix epoch.
  > - Server SHOULD accept both formats of integer and EventTime.

- The Python logger library stamps with the wall clock by default and takes a caller's
  time through `emit_with_time` (`v0.11.1`).

  Source: https://github.com/fluent/fluent-logger-python/blob/v0.11.1/fluent/sender.py

  >     def emit(self, label, data):
  >         if self.nanosecond_precision:
  >             cur_time = EventTime.from_unix_nano(time.time_ns())
  >         else:
  >             cur_time = int(time.time())
  >         return self.emit_with_time(label, cur_time, data)

- Parsers take the time from a record field (`time_key`). When the field is absent they
  use the current time only if `estimate_current_event` is true, which is the default;
  with it false the parser returns no time (code at `v1.20.1`). The parser filter keeps
  the incoming event's time when the parser returns none, and always when
  `reserve_time` is set. The docs at `cb3c4ca` describe `estimate_current_event` as
  applying "when `time_key` is specified", which reads differently from the code.

  Source: https://github.com/fluent/fluentd-docs-gitbook/blob/cb3c4ca464a9d0e47d820bf838803ba2a8827f21/configuration/parse-section.md

  > * **`time_key`** \(string\) \(optional\): Specify time field for event time. If
  >
  >   the event doesn't have this field, current time is used.

  Source: https://github.com/fluent/fluentd/blob/v1.20.1/lib/fluent/plugin/parser.rb

  > config_param :estimate_current_event, :bool, default: true

  > elsif @estimate_current_event
  >           Fluent::EventTime.now
  >         else
  >           nil

  Source: https://github.com/fluent/fluentd/blob/v1.20.1/lib/fluent/plugin/filter_parser.rb

  > config_param :reserve_time, :bool, default: false

  > t.nil? ? time : t

  Source: https://github.com/fluent/fluentd-docs-gitbook/blob/cb3c4ca464a9d0e47d820bf838803ba2a8827f21/filter/parser.md

  > Keeps the original event time in the parsed result.

- Fluentd stamps with Ruby's `Time.now` (`v1.20.1`); Fluent Bit with C11
  `timespec_get(..., TIME_UTC)` (`v5.2.0`).

  Source: https://github.com/fluent/fluentd/blob/v1.20.1/lib/fluent/time.rb

  >       time = Time.now
  >       Fluent::EventTime.new(time.to_i, time.nsec)

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/src/flb_time.c

  >     return timespec_get(&tm->tm, TIME_UTC);

- Fluent Bit documents the event time as set by the input plugin or found by parsing.

  Source: https://github.com/fluent/fluent-bit-docs/blob/81af32b72509583c9ee9f5e60452e43fcd36c3e2/concepts/key-concepts.md

  > The timestamp represents the time an Event was created. Every Event contains an associated timestamp. All events have timestamps, and they're set by the input plugin or discovered through a data parsing process.

- The forward input (`in_forward`, `v1.20.1`) replaces a supplied time whose whole
  seconds are zero, or a missing time, with the receiving Fluentd's current time. It
  does so for a single message always, for each event of a `Forward` batch always, and
  for a `PackedForward` batch only when `skip_invalid_event` is on, which is the
  default. With that option on it also drops an event whose time is neither an integer
  nor an `EventTime`. The forward protocol specification does not mention a zero time,
  and no rationale was searched for.

  Source: https://github.com/fluent/fluentd/blob/v1.20.1/lib/fluent/plugin/in_forward.rb

  > config_param :skip_invalid_event, :bool, default: true

  > time = Fluent::EventTime.now if time.to_i == 0

  > time = Fluent::EventTime.now if time.nil? || time.to_i == 0 # `to_i == 0` for empty EventTime

  > if @skip_invalid_event
  >           es = normalize_event_stream(tag, es, conn.remote_host)

  > !((time.is_a?(Integer) || time.is_a?(::Fluent::EventTime)) && record.is_a?(Hash) && tag.is_a?(String))

- Future, past or out-of-order times: no validation found in the pages read, beyond the
  zero-time rule above (Unverified).

**Stated why** (precision only). Fluentd had second granularity until 0.14.0 (2016-05-25,
pull request 653). The discussion in issue 461 weighed float seconds against a split
representation; float was rejected for nanoseconds.

Source: https://github.com/fluent/fluentd/issues/461#issuecomment-61567465

> Given the current seconds since epoch, the latter can only represent microseconds, and that's generally what we have to work with.  So, to support nanoseconds we'd need another representation like separate (integer) seconds and nanoseconds.

Source: https://github.com/fluent/fluentd/pull/653

> This patch introduces new fluentd timestamp, `Fluent::EventTime`, which can have nanosecond granularity and is compatible with current `Integer` timestamp.

For the parser's fallback, its author stated a reason. Pull request 370 (by tagomoris,
merged 2014-07-01) added `estimate_current_event` so that a parser can return no time
instead of the current time, because a substituted current time cannot be told apart from
a parsed one:

Source: https://github.com/fluent/fluentd/pull/370

> - By setting current time, caller cannot know "time" is from whether parse result or current time
>   - it brings troubles especially in case for filter plugins like fluent-plugin-parser

For the rest of who stamps, the forward protocol carrying the client's time and the input
plugins stamping: No stated rationale found. Looked at the forward protocol
specification, the parse-section docs, Fluent Bit's key concepts, `fluent/fluent-bit`
issues with `nanosecond` in the title (titles only), and pull request 370's body and
comments.

**Constraints.** Events cross several hops (client, forwarder, aggregator), and plugins written for integer seconds had to keep working (pull request 653's backward-compatibility notes, not quoted further).

**Costs and dissent.** Pull request 653 kept integer time on the wire by default
(`time_as_integer`) for backward compatibility, so nanoseconds were lost unless every hop
was upgraded (same pull request body; not quoted further).

The parser's default (`estimate_current_event` true at `v1.20.1`, quoted under "What it
does") carries the cost pull request 370 names: a later stage cannot tell whether an
event's time was parsed or substituted (quoted under "Stated why").

### T9. Grafana Loki

**Analogy.** Medium: a log store whose push API carries the client's time in every
entry, with server-side bounds on it. Family: time series.

**What it does.** Tag `v3.7.10`.

- Every pushed entry carries its own timestamp, nanoseconds since the Unix epoch.

  Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/reference/loki-http-api.md

  > - All epoch values will be interpreted as a Unix timestamp in nanoseconds.

- Bounds, relative to the current time (Inferred: the server's clock): older than `reject_old_samples_max_age` (default 1w) or
  further ahead than `creation_grace_period` (default 10m) is rejected with HTTP 400.

  Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/shared/configuration.md

  > [reject_old_samples: <boolean> | default = true]

  > [reject_old_samples_max_age: <duration> | default = 1w]

  > [creation_grace_period: <duration> | default = 10m]

  > # Deprecated. When true, out-of-order writes are accepted.
  > # CLI flag: -ingester.unordered-writes
  > [unordered_writes: <boolean> | default = true]

  Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/operations/request-validation-rate-limits.md

  > If a sample's timestamp is greater than the current timestamp, Loki allows for a certain grace period during which samples will be accepted. If the grace period is exceeded, the error will occur.

  > The `too_far_behind` and `out_of_order` reasons are identical. Loki clusters with `unordered_writes=true` (the default value as of Loki v2.4) use `reason=too_far_behind`. Loki clusters with `unordered_writes=false` use `reason=out_of_order`.

  > `unordered_writes` and its related flag `-ingester.unordered-writes` are deprecated and will be removed in a future major release. Once removed, out-of-order writes will be accepted unconditionally, and this setting will no longer be configurable.

- Separately, for out-of-order entries, a per-stream window relative to the stream's most
  recent entry rather than to the clock. An entry is accepted only if it is no older
  than half of `max_chunk_age` (ingester default `2h`) behind the newest entry already in
  that stream: one hour by default. An entry within the one-week
  `reject_old_samples_max_age` can still be rejected by this window.

  Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/shared/configuration.md

  > `max_chunk_age` defaults to 2 hour.

  > time_of_most_recent_line - (max_chunk_age/2)

  > This means the allowed out-of-order window is half of the configured max_chunk_age.

  > Log entries with timestamps that are after this earliest time are accepted.
  > Log entries further back in time return an out-of-order error.

**Stated why** for accepting out-of-order writes (design document, Owen Diehl, 2021-01-28):
the in-order rule came from Cortex, pushed users toward high-cardinality labels, and lost
logs from agents that retry batches independently.

Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/community/design-documents/2021-01-Ordering-Constraint-Removal.md

> Loki imposes an ordering constraint on ingested data; that is to say incoming data must have monotonically increasing timestamps, partitioned by stream. This has historical inertia from our parent project, Cortex, but presents unintended consequences specific to log ingestion.

> - Ingesting logs from other agents/mechanisms that don’t take into account Loki’s ordering constraint. For instance, fluent{d,bit} variants may batch and retry writes independently of other batches, causing unpredictable log loss via out of order errors.

> Many of these illustrate the adversity between _ordering_ and _cardinality_.

And why a window still bounds them:

> For most of our clusters, this would mean the range of acceptable data is one week long. In contrast, our max chunk age is `2h`. Allowing unordered writes would mean that ingesters would willingly receive data for 168h, or up to 84 distinct chunk lengths. This presents a problem: a malicious user could be writing to many (84 in this case) distinct chunks simultaneously, flooding Loki with underutilized chunks which bloat the index.

> The second is simple to implement and an effective way to ensure Loki can ingest unordered logs but maintain a sliding validity window. I expect this to cover nearly all reasonable use cases and effectively mitigate bad actors.

**Constraints.** Data is held per stream in compressed blocks, and the in-order rule traded against label cardinality (design document, quoted above).

**Costs and dissent.** Before 2.4 the in-order rule was a common complaint, and the
documented workaround was to let the shipping agent stamp the time rather than the
application.

Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/configure/bp-configure.md

> One issue many people have with Loki is their client receiving errors for out of order log entries.

> If you are extracting the timestamp from the log line with something like the [Alloy `stage.timestamp` block](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#stagetimestamp), you could instead _not_ do this and let your log shipping agent assign a timestamp to the log lines.

Source: https://github.com/grafana/loki/blob/v3.7.10/CHANGELOG.md

> * [4594](https://github.com/grafana/loki/pull/4594) **owen-d**: Enable unordered_writes by default

### T10. InfluxDB

**Analogy.** Medium: a time series database whose write protocol makes the client's time
optional. Also touches keyed state, because the time is part of a point's identity.

**What it does.** `influxdata/docs-v2` at `df4a7d5`.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/reference/syntax/line-protocol.md

> The [unix timestamp](/influxdb/version/reference/glossary/#unix-timestamp) for the data point.
> InfluxDB accepts one timestamp per point.
> If no timestamp is provided, InfluxDB uses the system time (UTC) of its host machine.

> - To ensure a data point includes the time a metric is observed (not received by InfluxDB),
>   include the timestamp.

> Default precision is nanoseconds (`ns`).

The same text appears in the InfluxDB 3 line protocol page of the same repository. A point with
the same measurement, tag set and timestamp as an existing one merges into it, the new
field values winning.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/v2/write-data/best-practices/duplicate-points.md

> For points that have the same measurement name, tag set, and timestamp,
> InfluxDB creates a union of the old and new field sets.

Points outside the retention period are rejected (HTTP 422, partial write).

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> - `422` **Unprocessable entity**: The request was well-formed, but some or all the points were rejected due to semantic errors--for example, schema conflicts or retention policy violations.

A write `precision` parameter is referred to in these pages, and seconds (`s`) appear
as a value in the InfluxDB 2 getting-started page on writing data; its
reference page was not read, so its full list of values is Unverified.
Future timestamps: no rule found in the pages read (Unverified).

**Stated why.** For who stamps: only the documentation note quoted above (include the
time if you want observation time, not receipt time). No further stated rationale found;
looked at the line protocol, duplicate-points, troubleshooting and retention pages of
`influxdata/docs-v2` at `df4a7d5`.

For precision, InfluxData's write guidance gives performance as the reason to write the
coarsest precision the data needs (InfluxDB 2 page; the InfluxDB 1 FAQ says the same):

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/v2/write-data/best-practices/optimize-writes.md
> By default, InfluxDB writes data in nanosecond precision.
> However if your data isn't collected in nanoseconds, there is no need to write at that precision.
> For better performance, use the coarsest precision possible for timestamps.

**Constraints.** A time the server fills in is only as accurate as its host's clock.
InfluxData's write guidance asks for hosts synchronised with NTP, because a point written
without a timestamp takes the InfluxDB host's local time:

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/v2/write-data/best-practices/optimize-writes.md
> Use the Network Time Protocol (NTP) to synchronize time between hosts.
> If a timestamp isn't included in line protocol, InfluxDB uses its host's local
> time (in UTC) to assign timestamps to each point.
> If a host's clocks isn't synchronized with NTP, timestamps may be inaccurate.

No other constraint was stated in the pages read.

**Costs and dissent.** The InfluxDB 1 FAQ names the cost of coarse precision: points
that collide on a timestamp overwrite each other, under the merge rule quoted above.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/v1/troubleshooting/frequently-asked-questions.md
> To maximize performance, use the coarsest possible timestamp precision when writing data to InfluxDB.

> The tradeoff is that identical points with duplicate timestamps, more likely to occur as precision gets coarser, may overwrite other points.

### T11. Prometheus

**Analogy.** Close as a counterpoint: a pull system where the server stamps, and the
format's optional client timestamp is discouraged. Family: time series (metrics).

**What it does.** `prometheus/docs` at `31957d4`, Prometheus `v3.16.0`, `client_golang`
`v1.25.0`.

- The text format allows an optional timestamp, in milliseconds since the epoch.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/exposition_formats.md

  > * The `timestamp` is an `int64` (milliseconds since epoch, i.e. 1970-01-01 00:00:00 UTC, excluding leap seconds), represented as required by Go's [`ParseInt()`](https://golang.org/pkg/strconv/#ParseInt) function.

- The documentation tells exporters not to set it.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_exporters.md

  > Metrics should only be pulled from the application when Prometheus
  > scrapes them, exporters should not perform scrapes based on their own
  > timers. That is, all scrapes should be synchronous.
  >
  > Accordingly, you should not set timestamps on the metrics you expose, let
  > Prometheus take care of that. If you think you need timestamps, then you
  > probably need the
  > [Pushgateway](https://prometheus.io/docs/instrumenting/pushing/)
  > instead.

- `client_golang` offers `NewMetricWithTimestamp`, documented as for rare cases such as
  mirroring another source.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/metric.go

  > // NewMetricWithTimestamp returns a new Metric wrapping the provided Metric in a
  > // way that it has an explicit timestamp set to the provided Time. This is only
  > // useful in rare cases as the timestamp of a Prometheus metric should usually
  > // be set by the Prometheus server during scraping. Exceptions include mirroring
  > // metrics with given timestamps from other metric
  > // sources.

- The server honours exposed timestamps by default, but exposed-timestamp series are not
  marked stale by default.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/configuration/configuration.md

  > [ honor_timestamps: <boolean> | default = true ]

  > [ track_timestamps_staleness: <boolean> | default = false ]

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/querying/basics.md

  > Some exporters, which put their own timestamps on samples, get a different behaviour:
  > series that stop being exported take the last value for (by default) 5 minutes before
  > disappearing. The `track_timestamps_staleness` setting can change this.

- Out-of-order and old samples are rejected unless `out_of_order_time_window` is set.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/configuration/configuration.md

  > # Configures how old an out-of-order/out-of-bounds sample can be w.r.t. the TSDB max time.
  > # An out-of-order/out-of-bounds sample is ingested into the TSDB as long as the timestamp
  > # of the sample is >= TSDB.MaxTime-out_of_order_time_window.

  > [ out_of_order_time_window: <duration> | default = 0s ]

- On the scrape path, a sample timestamped more than ten minutes ahead of the scraping
  server's clock is dropped as out of bounds. It is counted, and a warning is logged per
  scrape; the other samples of the scrape are kept (Inferred from the per-sample
  handling). The limit is a constant in the code, not a setting, and is independent of
  `out_of_order_time_window`. The AppenderV2 path (`scrape/scrape_append_v2.go`)
  applies the same limit. No stated rationale found for the ten-minute figure (searched
  GitHub issues for `maxAheadTime`, and commits for `maxAheadTime` and for the phrase
  "too far into the future").

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/scrape.go

  > const maxAheadTime = 10 * time.Minute

  > maxTime:  timestamp.FromTime(time.Now().Add(maxAheadTime)),

  > sl.l.Warn("Error on ingesting samples that are too old or are too far into the future", "num_dropped", appErrs.numOutOfBounds)

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/target.go

  > if t > app.maxTime {
  > 		return 0, storage.ErrOutOfBounds

**Stated why.**

- Against client timestamps: they break features that assume one time per scrape, and
  most users who asked for them did not need them. Quotations from brian-brazil (GitHub
  association today: CONTRIBUTOR).

  Source: https://github.com/prometheus/client_golang/issues/187#issuecomment-168345993

  > That's a highly advanced use case that should generally be discouraged, as having different timestamps for metrics from the same scrape will cause oddness and may prevent some features from working correctly.

  Source: https://github.com/prometheus/client_golang/issues/187#issuecomment-241248228

  > However offering any functionality like this before https://github.com/prometheus/prometheus/issues/398 is complete would be reckless, as the vast majority of users looking to use timestamps it turned out that they should either have used normal pull or the pushgateway without timetamps.

  Source: https://github.com/prometheus/client_golang/issues/187#issuecomment-307380351

  > With staleness handling complete and timestamp abuse mitigation in place, I believe it's now okay to expose timestamp support for the handful of advanced use cases that require it.

  Issue 398 (staleness) named the timestamp-propagation problem:

  Source: https://github.com/prometheus/prometheus/issues/398

  > This causes dead instances' data to hang around for longer than it should, makes less often scrape intervals difficult, makes advanced self-referential use cases more difficult and   prevents the timestamp propagating from the push gateway.

- For out-of-order ingestion (issue 8535, gouthamve, MEMBER): data pushed late after an
  outage was lost.

  Source: https://github.com/prometheus/prometheus/issues/8535

  > Prometheus now accepts remote write data. But it can't ingest data more than an hour old reliably. This means if there is an outage or network partition and the downstream Prometheus has issues with pushing for more than an hour, it is likely that there will be data loss after the issues are resolved.

  The implementation (pull request 11075) cites a design document hosted on Google Docs,
  which was not read (Unverified).

**Constraints.** Pull model: the server scrapes targets on its own schedule, and staleness was defined per scrape (issue 398 and the exporter guidance, quoted above).

**Costs and dissent.** Users of other client libraries asked for parity with Go; the Java
client offers it only through custom collectors.

Source: https://github.com/prometheus/client_java/issues/767#issuecomment-1680852762

> For me is also confusing why the golang interface allows for timestamps and the java doesn't, I understand that it was targeted towards online systems and not batch processing, however monitoring internal tasks in online systems is a valid use case IMHO and can leverage a lot from this feature.

Source: https://github.com/prometheus/client_java/issues/767#issuecomment-1732590083

> Implementing custom collectors is not a common case, but when your use case is to bridge existing metrics to a [PrometheusRegistry](https://prometheus.github.io/client_java/api/io/prometheus/metrics/model/registry/PrometheusRegistry.html) it might be a good option.

### T12. Apache Kafka

**Analogy.** Close for the choice itself: one timestamp field per record, which either the
producer library (with an application override) or the broker sets, chosen per topic.
Family: time series (append-only log).

**What it does.** Kafka `4.4.0`.

- The producer stamps with its current time unless the application gives a timestamp;
  the broker keeps it (`CreateTime`, default) or overwrites it (`LogAppendTime`).
  Milliseconds since the epoch, non-negative.

  Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerRecord.java

  >  * The record also has an associated timestamp. If the user did not provide a timestamp, the producer will stamp the
  >  * record with its current time. The timestamp eventually used by Kafka depends on the timestamp type configured for
  >  * the topic.

  >      * @param timestamp The timestamp of the record, in milliseconds since epoch. If null, the producer will assign
  >      *                  the timestamp using System.currentTimeMillis().

- Bounds under `CreateTime`: `message.timestamp.before.max.ms` (default `Long.MAX_VALUE`)
  and `message.timestamp.after.max.ms` (default one hour since 4.0.0).

  Source: https://github.com/apache/kafka/blob/4.4.0/server-common/src/main/java/org/apache/kafka/server/config/ServerLogConfigs.java

  >     public static final long LOG_MESSAGE_TIMESTAMP_BEFORE_MAX_MS_DEFAULT = Long.MAX_VALUE;

  >     public static final long LOG_MESSAGE_TIMESTAMP_AFTER_MAX_MS_DEFAULT = 3600000; // 1 hour

  Source: https://github.com/apache/kafka/blob/4.4.0/docs/getting-started/upgrade.md

  > The default value of `message.timestamp.after.max.ms` has been changed from Long.Max to 1 hour. The impact of this messages with a timestamp of more than 1 hour in the future will be rejected when message.timestamp.type=CreateTime is set. See [KIP-1030](https://cwiki.apache.org/confluence/x/FAqpEQ)

  > The `log.message.timestamp.difference.max.ms` configuration was removed. Please use `log.message.timestamp.before.max.ms` and `log.message.timestamp.after.max.ms` instead. See [KIP-937](https://cwiki.apache.org/confluence/x/thQ0Dw) for details. 

- One out-of-bounds record rejects its whole batch (KIP-937, below). Out-of-order times
  within bounds are accepted; KIP-32 lists non-monotonic time as a known downside.

- Under `LogAppendTime` the partition leader stamps each batch with its wall clock, read
  once per append. `SystemTime` implements `time.milliseconds()` as
  `System.currentTimeMillis()`. Neither `LogValidator.java` nor `UnifiedLog.java` at
  4.4.0 clamps it against the previous append time; Kafka's other source files were not
  searched.

  Source: https://github.com/apache/kafka/blob/4.4.0/storage/src/main/java/org/apache/kafka/storage/internals/log/LogValidator.java

  >         long now = time.milliseconds();

  >                     batch.setMaxTimestamp(TimestampType.LOG_APPEND_TIME, now);

  Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/common/utils/SystemTime.java

  >         return System.currentTimeMillis();

**Stated why.**

- KIP-32 (accepted; the config was proposed as `max.message.time.difference.ms` and
  shipped as `log.message.timestamp.difference.max.ms`).

  Source: https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message

  > The key decision we made in this KIP is whether use LogAppendTime(Broker Time) or CreateTime(Application Time)

  The listed advantages of the broker's time:

  > Broker is more robust.

  > Monotonically increasing.

  > Deterministic behavior for log rolling and retention.

  > If CreateTime is required, it can always be put into the message payload.

  The listed advantages of the producer's time include:

  > User may want to have log retention based on when the message is created instead of when the message enters the pipeline.

  > Immutable after entering the pipeline.

  The decision, and why no single design worked (from the rejected alternatives):

  > Because both LogAppendTime and CreateTime have their own use cases, the proposed change provides users with the flexibility to choose which one they want to use.

  > Protect the broker from misbehaving users (e.g. appending wrong create time to messages)

  A downside the KIP accepts for `CreateTime`:

  > The timestamp might not be monotonically increasing if message.timestamp.type=CreateTime.

  Two rejected alternatives: carrying both times, and carrying only the broker's.

  > It introduces 16 bytes overhead to the message.

  > It exposes LogAppendTime to users.

  > If the CreateTime is not in the message itself. Application needs to include the timestamp in payload. Instead of asking each application to do this, it is better to include the timestamp in the message.

- KIP-937 (separate past and future bounds): future times are inaccurate and disturb log
  rotation; producers had sent nanoseconds as milliseconds.

  Source: https://cwiki.apache.org/confluence/display/KAFKA/KIP-937%3A+Improve+Message+Timestamp+Validation

  > While there can be valid use cases for messages with past timestamps for the purpose of replaying old messages, messages with future timestamps are inherently inaccurate and can lead to unexpected log rotation behavior.

  > Kafka users have encountered problems due to misconfigured producers, such as using nanoseconds instead of milliseconds for the message timestamp.

  > It is important to note that if a validation fails, even for a single record within a batch, we reject the entire batch.

  > The client timestamp closely represents the actual event timestamp as assigned by the producer. On the other hand, the broker's timestamp only indicates the time of log append, which can be considered an implementation detail.

**Constraints.** Retention and segment rolling are driven by record time (KIP-33), so a
bad producer time can affect when other records in the same segment are deleted
(Inferred; KIP-32 states the narrower point that retention might become
non-deterministic).

Source: https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index

> In this KIP we propose adding a time based log index using the timestamp of the messages introduced in KIP-32.

**Costs and dissent.** The one-field design is itself a stated regret: KIP-937 records a
future wish for both times in the record (quoted above), which would need a new message
format. The future-time default changed from unbounded to one hour in 4.0.0 (KIP-1030,
not read; the upgrade note is quoted above).

KIP-32's "Monotonically increasing" is a listed advantage, not a guarantee the 4.4.0 code
read was found to implement. KIP-32 describes the clamp that would keep the broker's time
from going backwards when leadership moves, but only under the rejected Option 1:

Source: https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message

> To handle leader migration where new leader has slower clock than old leader, all the leader should append max(lastAppendedTimestamp, currentTimeMillis) as the timestamp

A user report on the users@ list (2026-08-18) says the broker's time can go backwards after
a leader election. Its sender was not found by name in the Kafka project's committer
roster. A PMC member replied asking for a JIRA and a KIP, without confirming or disputing
the behaviour; no JIRA or KIP on it was found on the date read. The report is Unverified
as observed behaviour; the code quoted under "What it does" is consistent with it
(Inferred). Inferred, not checked: because the stamp is the host's wall clock, a clock
step on one broker could also lower it.

Source: https://lists.apache.org/thread/267c522t0tfhl38o0qorjnl6jvqkkg9g

> After a leader election, the new leader’s clock may be behind the previous leader’s clock. In that case, newly appended records can receive a lower LogAppendTime than preceding records in the partition.

The PMC member's reply (2026-09-06):

Source: https://lists.apache.org/thread/s87r82g1l2c6wo54d0xdp8ft1vnfb9no

> It's interesting and worth mulling it over. Would you mind opening a jira and KIP to propose this change?

### T13. The systemd journal

**Analogy.** A local log collector: a daemon (by default one per machine) receives entries from processes on the same
machine and stamps each entry itself. Family: time series.

**What it does.** systemd `v260`: the `systemd.journal-fields(7)` and `systemd-journald.service(8)` man
pages for 260,
`docs/JOURNAL_FILE_FORMAT.md` and `src/journal/journald-manager.c` at tag `v260`.

- **Who stamps.** The journal daemon, on receipt, on two clocks: the wall clock
  (`CLOCK_REALTIME`) and the monotonic clock (`CLOCK_MONOTONIC`, stored with the boot
  id). Both are in microseconds, and each entry also gets a sequence number. They are
  exported as `__REALTIME_TIMESTAMP`, `__MONOTONIC_TIMESTAMP` and `__SEQNUM`. They are
  addressing metadata, not fields, and a client cannot write them.
- **A second, trusted source time.** Underscore-prefixed fields are added by the
  journal and cannot be altered by client code. Among them,
  `_SOURCE_REALTIME_TIMESTAMP` is the earliest trusted time known for the message when
  it differs from the reception time. For datagrams on the native and syslog sockets,
  the daemon takes it from the kernel's `SCM_TIMESTAMP` socket timestamp. Its other
  sources were not traced (Unverified).
- **May the application supply a time.** Not one the journal stamps or trusts. A client
  may send any field without an underscore, including the syslog `SYSLOG_TIMESTAMP`,
  and the journal does not validate those.
- **Field, precision, epoch.** Microseconds; the realtime stamp since the Unix epoch
  (UTC), the monotonic stamp from the clock's own origin for that boot.
- **Ordering.** Entries in a file are written in sequence-number order. Within one boot
  the monotonic stamp is monotonic too, and so is the realtime stamp, apart from clock
  corrections.
- **Future, past or out of order.** No validation of a supplied time was found in the
  pages read (Unverified).

Source: https://www.freedesktop.org/software/systemd/man/260/systemd.journal-fields.html
> Fields prefixed with an underscore are trusted fields, i.e. fields that are implicitly added by the journal and cannot be altered by client code.

> The earliest trusted timestamp of the message, if any is known that is different from the reception time of the journal. The timestamp is the CLOCK_REALTIME time in microseconds, formatted as a decimal.

> Note that these are not proper fields when stored in the journal but for addressing metadata of entries. They cannot be written as part of structured log entries via calls such as sd_journal_send(3).

> The wallclock time (CLOCK_REALTIME) at the point in time the entry was received by the journal, in microseconds since the epoch UTC, formatted as a decimal. This has different properties from "_SOURCE_REALTIME_TIMESTAMP=", as it is usually a bit later but more likely to be monotonic.

> The monotonic time (CLOCK_MONOTONIC) at the point in time the entry was received by the journal in microseconds, formatted as a decimal. To be useful as an address for the entry, this should be combined with the boot ID in "_BOOT_ID=".

> the timestamp as specified in the original datagram.

> Note that the journal service does not validate the values of any structured journal fields whose name is not prefixed with an underscore, and this includes any syslog related fields such as these.

Source: https://github.com/systemd/systemd/blob/v260/docs/JOURNAL_FILE_FORMAT.md
> In the file ENTRY objects are written ordered monotonically by sequence
> number. For continuous parts of the file written during the same boot
> (i.e. with the same boot_id) the monotonic timestamp is monotonic too. Modulo
> wallclock time jumps (due to incorrect clocks being corrected) the realtime
> timestamps are monotonic too.

Source: https://github.com/systemd/systemd/blob/v260/src/journal/journald-manager.c
> } else if (cmsg->cmsg_type == SCM_TIMESTAMP &&

> xsprintf(source_time, "_SOURCE_REALTIME_TIMESTAMP=" USEC_FMT, timeval_load(tv));

**Stated why.**

The design document, which Lennart Poettering's post "Introducing the Journal"
(2011-11-18) links as "the design document we put up on Google Docs", contrasts the
journal with syslog: syslog stored the client's metadata, timestamp included,
unverified; the journal adds its own trusted fields, which a client cannot set, and
stamps every entry with both a wall-clock and a monotonic time, carrying the boot ID so
the monotonic time is usable. It is a live Google Doc, so its 2011 text is Unverified.

Source: https://0pointer.net/blog/projects/the-journal.html

> check out the full explanation on what we have
> implemented on the design
> document we put up on Google Docs

Source: https://docs.google.com/document/pub?id=1IC9yOXj7j6cdLLxWEBAGRL6wl97tFxgjLUEHIX3MSTs

> These properties are passed in from the client, not verified and usually stored away as-is.

> This service will augment the entry with a number of meta fields. The values of these trusted fields are determined by the journal service itself and cannot be faked by the client side.

> The fields the journal daemon adds are prefixed with an underscore (“_”) as an indication that this field is trusted and not supplied by a potentially rogue client.

> The message data is generally not authenticated, every local process can claim to be Apache under PID 4711, and syslog will believe that and store it on disk.

> All entries are implicitly timestamped with the realtime (i.e. wallclock) and monotonic clock. To make the monotonic timestamps useful all messages also carry the boot ID of the running Linux kernel (i.e. /proc/sys/kernel/random/boot_id). The accuracy is 1usec, and the wallclock is stored in usec since the epoch UTC in order to avoid the timezone problems syslog is suffering by.

The trusted-fields passage covers the `_`-prefixed fields. The reception timestamps
`__REALTIME_TIMESTAMP` and `__MONOTONIC_TIMESTAMP` are addressing metadata, which the
manual says cannot be written as part of an entry (quoted under "What it does").

The documentation also states three reasons for its clocks:

- why the reception time is kept beside the source time: it is
  "more likely to be monotonic" (quoted above);
- why the monotonic stamp needs the boot id: to be useful as an address (quoted above);
- why entries carry a sequence number:

Source: https://github.com/systemd/systemd/blob/v260/docs/JOURNAL_FILE_FORMAT.md
> This should guarantee a monotonic stream
> of sequential numbers for easy interleaving even if entries are distributed
> among several files, such as the system journal and many per-user journals.

No stated rationale found for refusing a client-set reception time in particular: the
design document's reason covers the trusted fields, and the manual states the rule for
the reception timestamps without giving one. Looked at: the 260 man page,
`JOURNAL_FILE_FORMAT.md` at `v260`, the design document, and the post that links it.

**Constraints.**

- By default one daemon receives from many local processes over sockets (Inferred from
  the socket handling in `journald-manager.c`). The manual allows more than one: each
  journal namespace has its own, independent log stream and its own daemon instance, and
  a service is assigned to a namespace through `LogNamespace=`. The manual gives
  isolation and performance as the reasons for namespaces.
- Each daemon instance numbers every entry it writes from one sequence (Inferred from
  `JOURNAL_FILE_FORMAT.md`, which says files from the same daemon instance carry the
  same `seqnum_id`). With several namespaces, one machine therefore has several stamping
  daemons and several independent sequences (Inferred).
- Wall-clock jumps happen, so the realtime stamp is monotonic only between them (quoted
  above).

Source: https://www.freedesktop.org/software/systemd/man/260/systemd-journald.service.html
> Journal 'namespaces' are both a mechanism for logically isolating the log stream of projects consisting of one or more services from the rest of the system and a mechanism for improving performance. Multiple journal namespaces may exist simultaneously, each defining its own, independent log stream managed by its own instance of systemd-journald. Namespaces are independent of each other, both in the data store and in the IPC interface.

> Service units may be assigned to a specific journal namespace through the LogNamespace= unit file setting

**Costs and dissent.**

- The reception stamp is "usually a bit later" than the source time (quoted above).
- A client's own time survives only as an unvalidated field (`SYSLOG_TIMESTAMP`) that the
  journal does not use to order entries (Inferred from the ordering rule quoted above).
- Dissent was not searched for.

## Keyed state

### K1. Apache Cassandra

**Analogy.** Close. Each cell holds the latest value for a (partition, clustering, column)
key, and its write timestamp decides which write survives (last write wins). The
timestamp is both the last-write time and the conflict-resolution order. Keyed state.

**What it does.**

- **Field.** `WRITETIME(column)` returns the cell's timestamp, an int64.
- **Who stamps.** Three possible stampers, in precedence order: the CQL string
  (`USING TIMESTAMP`), the statement object or driver generator (sent at the protocol
  level), and otherwise the coordinator node.
- **Default since Java driver 3.0.** The driver stamps client side with a monotonic
  generator.
- **Precision and epoch.** Microseconds. The Unix epoch is a convention, not enforced
  (see CASSANDRA-4947 below).
- **Clock.** Coordinator: `currentTimeMillis() * 1000`, forced strictly increasing per
  node. Driver: wall clock, best-effort microseconds via native `gettimeofday`, forced
  monotonic with a drift warning.
- **Future, past and out of order.** Accepted by default: the highest timestamp wins
  regardless of arrival order. Since 5.0 an optional guardrail can warn about or reject
  user-provided timestamps outside a configured window (CASSANDRA-18352, fix version
  5.0). A second guardrail that can disable user-provided timestamps entirely is present
  in 5.0.9; when it was added was not checked.
- **Lightweight transactions.** Client timestamps are refused for LWT. The driver
  silently ignores its own generated timestamp there, and the server assigns one.

Version: Cassandra `cassandra-5.0.9`; Java driver `4.19.4` (Apache) and `3.11.5` (upgrade
guide).

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/doc/modules/cassandra/pages/developing/cql/dml.adoc
> * `TIMESTAMP`: sets the timestamp for the operation. If not specified,
> the coordinator will use the current time (in microseconds) at the start
> of statement execution as the timestamp. This is usually a suitable
> default.

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/doc/modules/cassandra/pages/developing/cql/dml.adoc
> * `WRITETIME` stores the timestamp of the value of the column.

The protocol-level default timestamp (flag `0x20`, field `<timestamp>`, a `[long]` of
microseconds) on QUERY and EXECUTE:

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/doc/native_protocol_v4.spec
>         0x20: With default timestamp. If set, <timestamp> should be present.
>               <timestamp> is a [long] representing the default timestamp for the query
>               in microseconds (negative values are forbidden). This will
>               replace the server side assigned timestamp as default timestamp.
>               Note that a timestamp in the query itself will still override
>               this timestamp. This is entirely optional.

Coordinator clock (server-side default):

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/src/java/org/apache/cassandra/service/ClientState.java
>     // The biggest timestamp that was returned by getTimestamp/assigned to a query. This is global to ensure that the
>     // timestamp assigned are strictly monotonic on a node, which is likely what user expect intuitively (more likely,
>     // most new user will intuitively expect timestamp to be strictly monotonic cluster-wise, but while that last part
>     // is unrealistic expectation, doing it node-wise is easy).

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/src/java/org/apache/cassandra/service/ClientState.java
>             long current = currentTimeMillis() * 1000;
>             long last = lastTimestampMicros.get();
>             long tstamp = last >= current ? last + 1 : current;

Driver (client-side default):

Source: https://github.com/apache/cassandra-java-driver/blob/4.19.4/manual/core/query_timestamps/README.md
> This is the default implementation. It always generates a client timestamp, and guarantees
> monotonicity (i.e. ever-increasing timestamps) across all application threads.
>
> Note that, in order to achieve monotonicity, the generator might return timestamps that drift out in
> the future. This happens if timestamps are generated at a rate of more than one per microsecond, or
> more likely in the event of a system clock skew. When this happens, the generator logs a warning
> message in the category `com.datastax.oss.driver.internal.core.time.MonotonicTimestampGenerator`:

The warning it logs ends:

Source: https://github.com/apache/cassandra-java-driver/blob/4.19.4/manual/core/query_timestamps/README.md
> returned timestamps will be artificially incremented to guarantee monotonicity.

Source: https://github.com/apache/cassandra-java-driver/blob/4.19.4/manual/core/query_timestamps/README.md
> This generator strives to achieve microsecond resolution on a best-effort basis. But in practice,
> the real accuracy of generated timestamps is largely dependent on the granularity of the operating
> system's clock. For most systems, this minimum granularity is millisecond, and the sub-millisecond
> part is simply a counter that gets incremented until the next clock tick, as provided by
> `System.currentTimeMillis()`.

Source: https://github.com/apache/cassandra-java-driver/blob/4.19.4/manual/core/query_timestamps/README.md
> 1. if there is a `USING TIMESTAMP` clause in the CQL string, use that over anything else;
> 2. otherwise, if a default timestamp was set directly on the statement, use it;
> 3. otherwise, if the timestamp generator assigned a timestamp, use it;
> 4. otherwise, let the server assign the timestamp.

Source: https://github.com/apache/cassandra-java-driver/blob/4.19.4/manual/core/query_timestamps/README.md
> If you execute a conditional update through the driver with a client-side timestamp generator, the
> client-side timestamp will be silently ignored and the server will provide its own.

Default change (driver 3.0.0):

Source: https://github.com/apache/cassandra-java-driver/blob/3.11.5/upgrade_guide/README.md
> 12. [Client-side timestamp generation](../manual/query_timestamps/) is
>     now the default (provided that [native
>     protocol](../manual/native_protocol) v3 or higher is in use). The
>     generator used is `AtomicMonotonicTimestampGenerator`.

Guardrails (5.0):

Source: https://github.com/apache/cassandra/blob/cassandra-5.0.9/conf/cassandra.yaml
> # Guardrail to allow/disallow user-provided timestamps. Defaults to true.
> # user_timestamps_enabled: true
> #
> # Guardrail to bound user-provided timestamps within a given range. Default is infinite (denoted by null).
> # Accepted values are durations of the form 12h, 24h, etc.
> # maximum_timestamp_warn_threshold:
> # maximum_timestamp_fail_threshold:
> # minimum_timestamp_warn_threshold:
> # minimum_timestamp_fail_threshold:

**Stated why.**

The proposal to move the default stamper from the server to the client (description,
2013):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178
> Generating timestamps server side by default for CQL has been done for convenience, so that end-user don't have to provide one with every query.  However, doing it server side has the downside that updates made sequentially by one single client (thread) are no guaranteed to have sequentially increasing timestamps.

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178
> Very concretely, this means that if you write a very trivial test program that sequentially insert a value and then erase it (or overwrite it), then, if you let CQL pick timestamp server side, the deletion might not erase the just inserted value (because the delete might reach a different coordinator than the insert and thus get a lower timestamp). From the user point of view, this is a very confusing behavior, and understandably so: if timestamps are optional, you'd hope that they are least respect the sequentiality of operation from a single client thread.

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178
> As a side note, letting the client provide the timestamp would also have the advantage of making it easy for the driver to retry failed operations with their initial timestamp, so that retries are truly idempotent.

Dissent in the same thread (Jonathan Ellis, comment 13792588):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=13792588&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13792588
> I understand the problem, but I still think the cure may be worse than the disease.  Let's not forget that "Bad Things happen if not just your server clocks but also your app server clocks are not synchronized" confuses people too.

Reply (Sylvain Lebresne, comment 13792631):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=13792631&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13792631
> I'm not really convinced that server side timestamps makes much of anything simpler for a user point of view (versus having the timestamp set by the driver that is).  Yes, you need to run ntpd on your clients too, but that sound hardly a big deal to me.

A multi-tenant ("as a service") objection (Sankalp Kohli, comment 13885248):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=13885248&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13885248
> Well this does not work well if you are trying to do Cassandra as a service type of a model. I agree running ntpd is not a big deal but that does not protect Cassandra from bad clients.

Answer (Lebresne, comment 13885424):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=13885424&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13885424
> But clients can already provide their own timestamp, so you're not "protected from bad clients" at all. In fact, because there is use cases where clients do need to provide their own timestamps to guarantee specific orderings, you're likely to get a mix of mostly server-side generated timestamp and a few client generated ones, which imo is much more likely to give "very hard to diagnose problems".

Idempotent retries as the precondition (Aleksey Yeschenko, comment 14031213):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=14031213&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14031213
> With CASSANDRA-6855 in, nothing is going to change for v3-protocol users - the driver will generate the timestamp automatically and transparently behind the scenes, unless you provide one explicitly. And, as mentioned in #6855 comments, it's the necessary precondition for idempotent retries in the driver.

Resolution (Yeschenko, comment 15191237, closed "Not A Problem"):

Source: https://issues.apache.org/jira/browse/CASSANDRA-6178?focusedCommentId=15191237&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-15191237
> To sum it up, we do now allow providing timestamps via the native protocol, and that's what most new drivers use by default.
>
> There is also strong resistance to removing server-side generated timestamps altogether, so that is not going anywhere anytime soon. Thus closing the ticket as Not A Problem.

Precision: microseconds at the server were judged not worth complexity, and the default
stamper moved to the client, which then owns precision (CASSANDRA-6106).

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=13976949&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13976949
> As far as conflict resolution goes, microsecond resolution is imo rather useless. Given the accuracy of ntp, network latencies and whatnot, no application should ever rely on sub-milliseconds resolution for conflicts, and any application that rely on fine-grained ordering of updates to a cell should really provide client-side timestamp.

> It doesn't mean we can't use microsecond resolution if it's easy of course, but does mean that imo the bar on what complexity is worth it is rather low.

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=13800513&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13800513
> Though on the longer run, I'm starting to be convinced that we should slowly move back to client side timestamps by default (CASSANDRA-6178) so it's unclear to me how much effort is worth putting into this (given that, at the end of the day, this won't ensure timestamp uniqueness anyway and you'd still have to be aware that on timestamp tie, the resolution is based on the value).

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=14307723&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14307723
> It was decided that v3 protocol implementors should ensure their timestamps are high precision, since this is the default source of timestamps going forwards.

Why not use a monotonic clock for the stamp (Jonathan Ellis, comment 13779492). He quotes
the `nanoTime` Javadoc, then gives his own warning:

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=13779492&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13779492
> This method can only be used to measure elapsed time and is not related to any other notion of system or wall-clock time.

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=13779492&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13779492
> It is NOT time since any particular epoch and you WILL have problems if you treat it like that.  (We've actually had a bug where that slipped past code review: CASSANDRA-4432.)

Why client-supplied timestamps were kept at all (CASSANDRA-4947, Won't Fix,
2012). Description, then Jonathan Ellis relaying use cases:

Source: https://issues.apache.org/jira/browse/CASSANDRA-4947
> Client-provided timestamps cause a lot of pain since we can't make any assumptions as to client:server clock agreement.  Is this worth the pain?  If not we should rip out {{WITH TIMESTAMP}} before 1.2.0. 

Source: https://issues.apache.org/jira/browse/CASSANDRA-4947?focusedCommentId=13495095&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13495095
> One use Brandon came up with for being able to specify timestamp client-side is for recovering from a years-too-fast clock: issue deletes with sufficiently high timestamps and compact the bad data out.

Source: https://issues.apache.org/jira/browse/CASSANDRA-4947?focusedCommentId=13495300&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13495300
> Ben Coverston: "Client provided timestamps are helpful if a write fails and you want to "replay" the writes later."

Source: https://issues.apache.org/jira/browse/CASSANDRA-4947?focusedCommentId=13496866&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13496866
> Timestamps can be anything you like, but microseconds since 1970 is a convention. Whatever you use, it must be consistent across the application, otherwise earlier changes may overwrite newer ones. 

Why the 5.0 timestamp guardrail exists (CASSANDRA-18352, description and Jordan West
comment 17706186):

Source: https://issues.apache.org/jira/browse/CASSANDRA-18352
> In several cases it is desirable to have client provided timestamps generated at the application-level. This can be error prone, however. In particular, applications can choose timestamps that may be nonsensical for a given application. One dangerous manifestation of this is the "doomstone" (a tombstone far in the future of any realistic write).

Source: https://issues.apache.org/jira/browse/CASSANDRA-18352?focusedCommentId=17706186&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-17706186
> I will say that we commonly see folks accidentally use millisecond resolution (when they had implicitly been using microseconds but need to write some data USING TIMESTAMP or other reason). That is the one of the main scenarios we want to prevent.

**Constraints.**

- Peer-to-peer cluster with no single ordering point. Drivers load-balance a client
  thread's requests across coordinators, so server-side stamps from different nodes'
  clocks can reorder one thread's writes (6178).
- Last-write-wins is the conflict rule; ties are broken by value comparison (6106).
- Driver retries and speculative executions need the original timestamp to stay
  idempotent (6178, 6855).
- LWT/Paxos needs server-chosen timestamps, so client timestamps are refused there.

**Costs and dissent.**

- Client clocks now matter. A user surprised that `IF NOT EXISTS` writes got server
  time and other writes got client time:

Source: https://issues.apache.org/jira/browse/CASSANDRA-12767?focusedCommentId=15562712&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-15562712

> {{ifnotexists}} uses a lightweight transaction within the cluster to provide some guarantees.  You can't do this with a client-side timestamp.  So for anything that doesn't require a server-side timestamp, it uses a client-side timestamp.

- Some users force server-side stamps and hit the original reordering problem
  (CASSANDRA-14521, description):

Source: https://issues.apache.org/jira/browse/CASSANDRA-14521

> We use server-generated timestamps for all requests because of CASSANDRA-14304.

- Unit mistakes leave rows that cannot be overwritten (CASSANDRA-18374, description):

Source: https://issues.apache.org/jira/browse/CASSANDRA-18374

> We ran into an issue where data inserted was USING TIMESTAMP that was using nanoseconds which cassandra was converting to something like this:

- Jon Haddad argued for keeping a way to disable client-side timestamps (6178, comment
  14366136). The 5.0 `user_timestamps_enabled` guardrail covers user-written
  `USING TIMESTAMP`. Whether it also blocks the protocol-level default timestamp that
  drivers send: **Unverified**.

### K2. Apache HBase

**Analogy.** Close. A cell holds versions keyed by timestamp; with `VERSIONS=1` (the
default since 0.96) it is the latest value per key. The timestamp doubles as the version
identifier. Keyed state.

**What it does.**

- **Who stamps.** The RegionServer, by default, at write.
- **May the application supply it.** Yes, via `Put` with an explicit timestamp.
- **Precision and epoch.** Milliseconds since the Unix epoch, from the server's
  `currentTimeMillis` (quoted below). A nanosecond mode was proposed in HBASE-21476 and
  is still open.
- **Future, past and out of order.** Accepted: any version order may be written. Reads
  return the highest timestamp. The same timestamp written twice keeps the last write.
- **Delete markers.** A marker with a future timestamp masks later puts until compaction
  (classic behaviour). `NEW_VERSION_BEHAVIOR` (2.0) changes some of this.

Version: reference guide source at master SHA `81e463a` (the book moved to
`hbase-website/` there; a fetch of `src/main/asciidoc/_chapters/datamodel.adoc` at
`rel/2.6.7` returned 404, and the cause was not investigated).

Source: https://github.com/apache/hbase/blob/81e463a0ec11bf6c4cb959a46f2665781afa5e79/hbase-website/app/pages/_docs/docs/_mdx/%28multi-page%29/datamodel.mdx
> A timestamp is written alongside each value, and is the identifier for a given version of a value.
> By default, the timestamp represents the time on the RegionServer when the data was written, but you can specify a different timestamp value when you put data into the cell.

Source: https://github.com/apache/hbase/blob/81e463a0ec11bf6c4cb959a46f2665781afa5e79/hbase-website/app/pages/_docs/docs/_mdx/%28multi-page%29/datamodel.mdx
> - If multiple writes to a cell have the same version, only the last written is fetchable.
> - It is OK to write cells in a non-increasing version order.

Source: https://github.com/apache/hbase/blob/81e463a0ec11bf6c4cb959a46f2665781afa5e79/hbase-website/app/pages/_docs/docs/_mdx/%28multi-page%29/datamodel.mdx
> Caution: the version timestamp is used internally by HBase for things like time-to-live calculations.
> It's usually best to avoid setting this timestamp yourself.
> Prefer using a separate timestamp attribute of the row, or have the timestamp as a part of the row key, or both.

Source: https://github.com/apache/hbase/blob/81e463a0ec11bf6c4cb959a46f2665781afa5e79/hbase-website/app/pages/_docs/docs/_mdx/%28multi-page%29/datamodel.mdx
> By default the system uses the server's `currentTimeMillis`, but you can specify the version (= the long integer) yourself, on a per-column level.

Source: https://github.com/apache/hbase/blob/81e463a0ec11bf6c4cb959a46f2665781afa5e79/hbase-website/app/pages/_docs/docs/_mdx/%28multi-page%29/datamodel.mdx
> These issues should not be a problem if you use always-increasing versions for new puts to a row.
> But they can occur even if you do not care about time: just do delete and put immediately after each other, and there is some chance they happen within the same millisecond.

**Stated why.**

The guide's own reason for discouraging client-set timestamps is the TTL coupling quoted
above. The JIRA discussions add more.

Proposal for per-table timestamp policies (HBASE-10247, Won't Fix; Lars Hofhansl,
comment 13999603):

Source: https://issues.apache.org/jira/browse/HBASE-10247?focusedCommentId=13999603&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13999603
> * CLIENT_OK, this would allow a client to set timestamps freely
> * SERVER_ONLY - RegionServer sets timestamps, attempts to set TS from a client would result in an Exception
> * CLIENT_MONOTONIC (maybe) - client can set timestamp, but promises to do so monotonically. For experts, we basically have to trust the client would do the right thing.

Why it was abandoned (Hofhansl, comment 14094389):

Source: https://issues.apache.org/jira/browse/HBASE-10247?focusedCommentId=14094389&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14094389
> # More importantly. Server-side-only TSs *cannot* work with replication! When region servers fail in a source cluster edit may reach the slave cluster out of order. Now we can (a) assign TSs again by a slave server and we'd have different ordering of the KVs and hence different data, or we can (b) allow using the TSs from KVs and we're back to where we were, edits can be back and future dated.

Source: https://issues.apache.org/jira/browse/HBASE-10247?focusedCommentId=14095152&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14095152
> Needless to say I am much less enthused about this idea now... if we cannot generally use it.
> And CLIENT_MONOTONIC makes no sense under scrutiny.

Earlier motivation (HBASE-9905, "Abandoned", description):

Source: https://issues.apache.org/jira/browse/HBASE-9905
> The problem is that, for data models not using timestamps, we are still relying on clocks to order the updates. Clock skew, same milisecond puts after deletes, etc can cause unexpected behavior and data not being visible.

Hybrid logical clocks, server-stamped (HBASE-14070, description):

Source: https://issues.apache.org/jira/browse/HBASE-14070
> HBase and Phoenix uses systems physical clock (PT) to give timestamps to events (read and writes). This works mostly when the system clock is strictly monotonically increasing and there is no cross-dependency between servers clocks. However we know that leap seconds, general clock skew and clock drift are in fact real. 

Proposal to deprecate client-set timestamps under HLC, and the pushback (HBASE-18642):

Source: https://issues.apache.org/jira/browse/HBASE-18642
> With using [HBASE-14070|https://issues.apache.org/jira/browse/HBASE-14070], clients should no longer set the timestamp for mutations (i.e., put/delete) because the server will do time stamping instead.

Source: https://issues.apache.org/jira/browse/HBASE-18642?focusedCommentId=16139354&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-16139354
> - For another case, we have certain columns where we want to maintain only the most recent (or oldest) version of a given cell, according to a timestamp of the data itself, including data that may arrive to our system late or out of order.  Multiple writes may regularly update that cell, without reading it (or anything) first.  We rely on HBase to surface only the copy with the most up to date timestamp (or oldest timestamp by inverting it via Long.MAX_VALUE - timestamp).

Source: https://issues.apache.org/jira/browse/HBASE-18642?focusedCommentId=16139510&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-16139510
> Thanks [~davelatham] Sounds like blanket disabling setting of timestamp is not on. Will be back.

Why not nanoTime (HBASE-8927, Won't Fix; Hofhansl, comment 13705574):

Source: https://issues.apache.org/jira/browse/HBASE-8927?focusedCommentId=13705574&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13705574
> nanoTime cannot be used as absolute timestamps, it can only be used to compare times over a relatively small interval.

Why a nanosecond mode was proposed (HBASE-21476, open, description):

Source: https://issues.apache.org/jira/browse/HBASE-21476
> Introducing a new table attribute "NANOSECOND_TIMESTAMPS" to tell HBase to handle timestamps with nanosecond precision. This is useful for applications that timestamp updates at the source with nanoseconds and still want features like column family TTL and "hbase.hstore.time.to.purge.deletes" to work.

**Constraints.**

- Asynchronous cross-cluster replication replays edits, so they must keep their original
  timestamps (10247).
- The timestamp is overloaded: it is the version id, the TTL clock and the ordering key.
- Applications rely on supplying their own timestamps: Phoenix and transaction
  libraries (10247), date-tiered compaction and keep-latest-by-data-time columns
  (18642).

**Costs and dissent.**

- The guide documents deletes masking puts and same-millisecond collisions as known
  hazards.
- HLC status. The last progress note (Amit Patel, comment 16142478, 2017) lists open
  performance and test-timeout issues. The JIRA was re-opened administratively in 2022
  and has no resolution. That it was never merged is **Unverified** from what was read.

### K3. Apache Flink keyed state TTL

**Analogy.** Close in shape: each keyed-state entry carries the time it was last
written (or read) so it can expire. The time is internal metadata, not a user field.
Keyed state.

**What it does.**

- **Who stamps.** The runtime, through `TtlTimeProvider`.
- **Clock.** The default provider is `System::currentTimeMillis`, so wall-clock
  milliseconds since the Unix epoch.
- **Field.** `TtlValue.lastAccessTimestamp` (long).
- **May the application supply it.** No. The only `TtlTimeCharacteristic` is
  `ProcessingTime`.
- **When the stamp updates.** `UpdateType` chooses: `OnCreateAndWrite` (default) or
  `OnReadAndWrite`.
- **Future, past and out of order.** Not applicable, because no supplied time is
  accepted.

Version: `release-2.3.0` (identical text to `release-2.2.1` for the docs and runtime
classes quoted).

Source: https://github.com/apache/flink/blob/release-2.3.0/flink-runtime/src/main/java/org/apache/flink/runtime/state/ttl/TtlTimeProvider.java
> /** Provides time to TTL logic to judge about state expiration. */
> public interface TtlTimeProvider {
>     TtlTimeProvider DEFAULT = System::currentTimeMillis;

Source: https://github.com/apache/flink/blob/release-2.3.0/flink-core/src/main/java/org/apache/flink/api/common/state/StateTtlConfig.java
>     public enum TtlTimeCharacteristic {
>         /** Processing time. */
>         ProcessingTime
>     }

Source: https://github.com/apache/flink/blob/release-2.3.0/docs/content/docs/dev/datastream/fault-tolerance/state.md
> - The state backends store the timestamp of the last modification along with the user value, 
> which means that enabling this feature increases consumption of state storage. 
> Heap state backend stores an additional Java object with a reference to the user state object 
> and a primitive long value in memory. The RocksDB state backend adds 8 bytes per stored value, list entry or map entry.
>
> - Only TTLs in reference to *processing time* are currently supported.

**Stated why.**

- FLIP-25 lists both "processing time" and "event time" as time characteristics. It
  gives no reason for shipping processing time only; event time is simply deferred.
- The tracking issue, FLINK-12005, is open and unassigned.
- The design trade-offs were laid out on the dev list in April 2019. Andrey Zagrebin
  opened the thread:

Source: https://lists.apache.org/thread/5nszby28kryxs1xz2y2n6qtgk9yzw1yh
> At the moment, Flink supports *only processing time* for both timestamps:
> state *last access and current timestamp*. It is basically current local
> system unix epoch time.

Source: https://lists.apache.org/thread/5nszby28kryxs1xz2y2n6qtgk9yzw1yh
>    - *Event timestamp of currently being processed record.* This seems to
>    be the simplest option and it allows user-defined timestamps in state
>    backend. The problem here might be instability of event time which can not
>    only increase but also decrease if records come out of order. This can lead
>    to rewriting the state timestamp to smaller value which is unnatural for
>    the notion of time.
>    - *Max event timestamp of records seen so far for this record key.* This
>    option is similar to the previous one but it tries to fix the notion of
>    time to make it always increasing. Maintaining this timestamp has also
>    performance implications because the previous timestamp needs to be read
>    out to decide whether to rewrite it.

Aljoscha Krettek, arguing from regulatory expiry:

Source: https://lists.apache.org/thread/hnzqsl4jyrr4ssmyzbsfk8v3hffxy59b
> For *last-access-timestamp*, I think only *event-time-of-current-record* makes sense. I’m looking at this from a GDPR/regulatory compliance perspective.

Kostas Kloudas, questioning event time as a backend notion at all:

Source: https://lists.apache.org/thread/ftdrgq6crrlvfgr8sq885jo4m2r7lhm0
> Event-time, although we call it "time", is just another user-defined column
> or attribute of the data and can be anything. It is not an "objective" and
> independently evolving attribute like wall-clock time.

Source: https://lists.apache.org/thread/ftdrgq6crrlvfgr8sq885jo4m2r7lhm0
> For GDPR: I am not sure about the regulatory requirements of GDPR but I
> would assume that the time for deletion starts counting from the time an
> organisation received the data (i.e. the wall-clock ingestion time of the
> data), and not the "event time" of the data.

Zagrebin's wrap-up of the thread (2019-04-15) names event time of the record being
processed as the trend for the last-access time, and leaves out-of-order records to a
caveat in the documentation:

Source: https://lists.apache.org/thread/chs2b6y4818rmyx428obdxmvc49ybrnc
> As far as I see we have the following trends:
>
> *Last access timestamp: **Event timestamp of currently being processed
> record*

Source: https://lists.apache.org/thread/chs2b6y4818rmyx428obdxmvc49ybrnc
> The biggest concern is out-of-orderness problem. In general, from Flink
> side it does not look that we can do a lot about it except putting again a
> caveat into the user docs about it. It depends on the use case whether the
> out-of-orderness can be tolerated or not and whether an additional stream
> ordering operator needs to be put before TTL state access.

Source: https://lists.apache.org/thread/chs2b6y4818rmyx428obdxmvc49ybrnc
> I would still consider TTL event time feature to be implemented as we have
> some user requests for it.

Yu Li replied the next day, asking to confirm that conclusion and offering to build it:

Source: https://lists.apache.org/thread/cf9hrx6bwnylmw083rdzz6dmtj2og418
> Just to confirm, that for the out-of-order case, the conclusion is to
> update the data and timestamp with the currently-being-processed record w/o
> checking whether it's an old data, right?

Source: https://lists.apache.org/thread/cf9hrx6bwnylmw083rdzz6dmtj2og418
> Will start/continue the development/implementation following the conclusion
> if no objections.

Outcome as recorded on the JIRA (Andrey Zagrebin, comment 17123421, 2020):

Source: https://issues.apache.org/jira/browse/FLINK-12005?focusedCommentId=17123421&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-17123421
> I have attached the full mailing list discussion. It looks we have an agreement there.

The agreement Zagrebin's comment points to is the wrap-up above (Inferred): event time
of the record being processed for the last-access time, with out-of-order records left
to a documented caveat. The comment names no message and its attached copy of the
discussion was not read; the wrap-up is the thread's only summary, and Yu Li's reply
calls it the conclusion. It was a "preliminary wrap-up", and Yu Li's confirmation was
put as a question. No event-time TTL has shipped since, and there is no stated
rejection: the feature was proposed, agreed in outline on the list and left
unimplemented. Yu Li (comment 17121272) had said the discussion had no explicit
conclusion; Zagrebin's next comment, above, disagreed. Flink's processing-time-only TTL
therefore has no stated why of its own: it is what was built first, and the
discussion's trend was towards event time.

Source: https://issues.apache.org/jira/browse/FLINK-12005?focusedCommentId=17121272&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-17121272
> We ever had a [discussion in ML|http://apache-flink-mailing-list-archive.1008284.n3.nabble.com/Discuss-Semantics-of-event-time-for-state-TTL-td28113.html] about the semantic of event time in state TTL but it seems to be no explicit conclusion.

**Constraints.**

- TTL is about state-size control and regulatory expiry (FLIP-25 motivation). Which
  clock those requirements refer to was itself disputed on the dev list (Krettek versus
  Kloudas, quoted above).
- Event time in Flink is out-of-order by design. A per-key stamp taken from it can move
  backwards; keeping it monotonic costs a read-before-write.

**Costs and dissent.**

- Users ask for event-time TTL (FLINK-12005 comments 17120701, 17362401).
- The developer who raised the out-of-order objection concluded for event time of the
  record being processed, accepting that cost with a caveat (Zagrebin's wrap-up, quoted
  above).
- The storage cost is documented: 8 bytes per value or entry in RocksDB.

### K4. Apache Kafka: compacted topics and Kafka Streams KTables

**Analogy.**

- A compacted topic is a keyed changelog: the log keeps at least the last value per
  key.
- A KTable materialises it as keyed state.
- Each record carries one timestamp, and the KTable stores the latest record's
  timestamp with its value (KIP-258).
- **Caveat.** By default the stamp is the record's embedded time (producer or broker),
  not a last-written-to-the-table time. A Kafka Streams application can change which
  time a KTable stores through its `TimestampExtractor` (below).

**What it does.**

- **Who stamps.** Per topic, `message.timestamp.type`:
  - `CreateTime` (default): the producer library stamps `System.currentTimeMillis()`
    unless the application passes a timestamp.
  - `LogAppendTime`: the broker overwrites with its local time.
- **Who stamps, in Kafka Streams.** A KTable stores the timestamp its
  `TimestampExtractor` assigns, which need not be the record's embedded one.
  - The default, `FailOnInvalidTimestamp`, returns the embedded timestamp: event time
    under `CreateTime`, ingestion time under `LogAppendTime`.
  - `WallclockTimestampExtractor` returns `System.currentTimeMillis()` when the record
    is processed: processing time. That is not documented as the instant of the store
    write.
  - A custom extractor may compute any time from the record.
  - The extractor is set for the application (`default.timestamp.extractor`) or per
    source (`Consumed.with(...)`).
  - When the KTable is materialised, a record whose timestamp is older than the stored
    one is logged as an out-of-order update and still handed to the store, which keeps
    what its own rule says (above: by offset, or by timestamp for a versioned store).
- **Field.** Record timestamp, int64 milliseconds since the Unix epoch. Negative values
  are rejected by the client.
- **Future and too old (`CreateTime` only).** The broker rejects the whole batch with
  `INVALID_TIMESTAMP` when the record is earlier than
  `broker - message.timestamp.before.max.ms` or later than
  `broker + message.timestamp.after.max.ms`.
  - `before.max.ms` defaults to `Long.MAX_VALUE`.
  - The `after.max.ms` default went from `Long.MAX_VALUE` (3.9.0) to 1 hour (4.0.0).
- **Out of order, compaction.** Compaction keeps the highest *offset* per key,
  regardless of timestamp.
- **Out of order, KTable.** A non-versioned KTable `get(key)` returns the latest by
  offset. A versioned store (KIP-889/914) returns the latest by timestamp, and its
  aggregations and joins ignore out-of-order records.

Version: `4.4.0` (and `3.9.0`, `4.0.0` for the default change).

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerRecord.java
>  * The record also has an associated timestamp. If the user did not provide a timestamp, the producer will stamp the
>  * record with its current time. The timestamp eventually used by Kafka depends on the timestamp type configured for
>  * the topic.

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerRecord.java
>      * @param timestamp The timestamp of the record, in milliseconds since epoch. If null, the producer will assign
>      *                  the timestamp using System.currentTimeMillis().

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerRecord.java
>                     String.format("Invalid timestamp: %d. Timestamp should always be non-negative or null.", timestamp));

Source: https://github.com/apache/kafka/blob/3.9.0/server-common/src/main/java/org/apache/kafka/server/config/ServerLogConfigs.java
>     public static final long LOG_MESSAGE_TIMESTAMP_AFTER_MAX_MS_DEFAULT = Long.MAX_VALUE;

Source: https://github.com/apache/kafka/blob/4.0.0/server-common/src/main/java/org/apache/kafka/server/config/ServerLogConfigs.java
>     public static final long LOG_MESSAGE_TIMESTAMP_AFTER_MAX_MS_DEFAULT = 3600000; // 1 hour

Source: https://github.com/apache/kafka/blob/4.4.0/docs/design/design.md
> Log compaction ensures that Kafka will always retain at least the last known value for each message key within the log of data for a single topic partition.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=247827010
> returns the latest record by timestamp rather than the latest record by offset.

Source: https://github.com/apache/kafka/blob/4.4.0/streams/src/main/java/org/apache/kafka/streams/processor/WallclockTimestampExtractor.java
>  * Using this extractor effectively provides <i>processing-time</i> semantics.

>         return System.currentTimeMillis();

Source: https://github.com/apache/kafka/blob/4.4.0/streams/src/main/java/org/apache/kafka/streams/processor/FailOnInvalidTimestamp.java
>  * If the embedded metadata timestamp represents <i>CreateTime</i> (cf. Kafka broker setting
>  * {@code message.timestamp.type} and Kafka topic setting {@code log.message.timestamp.type}),
>  * this extractor effectively provides <i>event-time</i> semantics.
>  * If <i>LogAppendTime</i> is used as broker/topic setting to define the embedded metadata timestamps,
>  * using this extractor effectively provides <i>ingestion-time</i> semantics.

Source: https://github.com/apache/kafka/blob/4.4.0/streams/src/main/java/org/apache/kafka/streams/StreamsConfig.java
>     public static final String DEFAULT_TIMESTAMP_EXTRACTOR_CLASS_CONFIG = "default.timestamp.extractor";

>                     FailOnInvalidTimestamp.class.getName(),

Source: https://github.com/apache/kafka/blob/4.4.0/docs/streams/core-concepts.md
> Kafka Streams assigns a **timestamp** to every data record via the `TimestampExtractor` interface.

Source: https://github.com/apache/kafka/blob/4.4.0/streams/src/main/java/org/apache/kafka/streams/processor/internals/RecordQueue.java
> timestamp = timestampExtractor.extract(deserialized, partitionTime);

Source: https://github.com/apache/kafka/blob/4.4.0/streams/src/main/java/org/apache/kafka/streams/kstream/internals/KTableSource.java
>                                 "Detected out-of-order KTable update for {}, "

>                 putReturnCode = store.put(record.key(), record.value(), record.timestamp(), new RecordHeaders());

**Stated why.**

KIP-32 (page version 60), the choice between broker time and application time:

Listed as the good things about LogAppendTime:

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> Monotonically increasing.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> Deterministic behavior for log rolling and retention.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> If CreateTime is required, it can always be put into the message payload.

Listed as the good things about CreateTime:

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> User may want to have log retention based on when the message is created instead of when the message enters the pipeline.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> Immutable after entering the pipeline.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> Because both LogAppendTime and CreateTime have their own use cases, the proposed change provides users with the flexibility to choose which one they want to use.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> The timestamp might not be monotonically increasing if message.timestamp.type=CreateTime.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=61318265
> I.e. by default the server will not override any user timestamp.

KIP-937 (future timestamps):

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=255071414
> While there can be valid use cases for messages with past timestamps for the purpose of replaying old messages, messages with future timestamps are inherently inaccurate and can lead to unexpected log rotation behavior. Kafka users have encountered problems due to misconfigured producers, such as using nanoseconds instead of milliseconds for the message timestamp.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=255071414
> However, in a future major version bump, we will change this default value to 3600000 milliseconds (one hour).

KIP-258 (why a KTable stores the timestamp with the value):

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=75972306
> we want to be able to store record timestamps in KTables. This allows us to address multiple issues like

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=75972306
> return the timestamp of the latest update in Interactive Queries

KIP-280 (compaction by producer timestamp; accepted, never shipped):

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=75978496
> Current log compaction is based on the server side view i.e. compacted based on record offset and the offset is by the order when the record was received on the broker side.

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=75978496
> To resolve the above issue, we are proposing to add a feature to support compaction based on producer signal (i.e. adding 2 more compaction strategies, record timestamp and header sequence/version) and keeping the current compaction (i.e. offset based) as the default compaction for the backward compatibility. By this way, the producer will have an option to own and control the record ordering.

Its implementation pull request, https://github.com/apache/kafka/pull/8103, was closed
unmerged on 2024-12-23, and `TopicConfig` at 4.4.0 has no `compaction.strategy` key
(https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/common/config/TopicConfig.java,
searched). https://issues.apache.org/jira/browse/KAFKA-7061 remains In Progress.

Kafka Streams documentation (why the time a stream uses is pluggable):

Source: https://github.com/apache/kafka/blob/4.4.0/docs/streams/core-concepts.md
> Concrete implementations of the `TimestampExtractor` interface will then provide different semantics to the stream time definition.

> Developers can thus enforce different notions of time depending on their business needs.

**Constraints.**

- Retention and segment rolling are driven by record timestamps, so bad future stamps
  have operational effects (KIP-32, KIP-937).
- Producers are independent processes; ordering per key is by broker offset (KIP-280).

**Costs and dissent.**

- The `Long.MAX_VALUE` default, in place from KIP-32 until 4.0.0, let nanosecond-unit
  mistakes through (KIP-937). The default was tightened only for future stamps, at a major version.
- Compaction by offset keeps the "wrong" value when producers race (KIP-280). The fix
  was voted but never landed.
- KIP-32's monotonic `LogAppendTime`, quoted above as a stated advantage, is not clamped
  across a change of leader in the 4.4.0 code read (T12, Costs and dissent).

### K5. Redis

**Analogy.** Loose. Keyed store with no general per-key write time. The only per-key time
is an eviction clock in the object's 24-bit `lru` field. Under the LRU policies it is set
on access as well as write; under the LRM policies (Redis 8.6 and later) on writes only;
under the LFU policies the field holds LFU data instead. Included because none of these
is a documented last-written field: each is an eviction clock with one-second resolution
that wraps.

**What it does.**

- **Who stamps.** The server, into the 24-bit `lru` field of the object, from its own
  wall clock (`mstime()`, which reads `gettimeofday`). Which operations stamp it depends
  on `maxmemory-policy`:
  - LRU policies, and the policies that are neither LFU nor LRM: reads and writes.
  - LRM policies (`volatile-lrm`, `allkeys-lrm`; added in 8.6, checked against
    `redis.conf` at tags `8.4.0` and `8.6.0`): writes only.
  - LFU policies: the field holds LFU data instead.
- **Resolution and range.** 1 second, wrapping at 2^24 s.
- **Reading it.** `OBJECT IDLETIME` is documented as the time since the last access. The
  command is refused only under LFU. Under LRM reads do not stamp the field, so it returns
  the time since the last write (Inferred from `object.c` and `evict.c` at 8.12.0; not
  documented).
- **May the application supply it.** Not on the ordinary write path. `RESTORE … IDLETIME
  seconds` (since 5.0), which recreates a key from a `DUMP` payload, sets the field to
  the current LRU clock minus the given idle time. It is documented "for LRU eviction",
  but the code applies it under every policy that is not LFU. Under LRM it therefore
  sets the write clock too (Inferred from `cluster.c` and `object.c` at 8.12.0). It
  restores eviction metadata; it is not an API for a last-write time.

Version: `8.12.0`.

Source: https://github.com/redis/redis/blob/8.12.0/src/object.h
> #define LRU_BITS 24
> #define LRU_CLOCK_MAX ((1<<LRU_BITS)-1) /* Max value of obj->lru */
> #define LRU_CLOCK_RESOLUTION 1000 /* LRU clock resolution in ms */

Source: https://github.com/redis/redis/blob/8.12.0/src/object.h
>     unsigned lru:LRU_BITS; /* LRU time (relative to global lru_clock) or
>                             * LFU data (least significant 8 bits frequency
>                             * and most significant 16 bits access time). */

Source: https://github.com/redis/redis/blob/8.12.0/src/commands/object-idletime.json
>         "summary": "Returns the time since the last access to a Redis object.",

Source: https://github.com/redis/redis/blob/8.12.0/src/evict.c
> /* Given an object returns the min number of milliseconds the object was never
>  * requested, using an approximated LRU algorithm. */

Source: https://github.com/redis/redis/blob/8.12.0/redis.conf
> # LRM means Least Recently Modified (only write operations update the timestamp)

> # LRU vs LRM: Both use similar eviction logic based on access time, but:
> # - LRU updates the timestamp on both read (GET) and write (SET) operations
> # - LRM only updates the timestamp on write (SET, INCR, etc.) operations

Source: https://github.com/redis/redis/blob/8.12.0/src/db.c
> /* Update LRM when an object is modified. */
> void updateLRM(robj *o) {
>     if (o->refcount == OBJ_SHARED_REFCOUNT)
>         return;
>     if (server.maxmemory_policy & MAXMEMORY_FLAG_LRM) {
>         o->lru = LRU_CLOCK();
>     }
> }

> /* LRM policy should NOT update timestamp on reads. */

Source: https://github.com/redis/redis/blob/8.12.0/src/evict.c
> return (mstime()/LRU_CLOCK_RESOLUTION) & LRU_CLOCK_MAX;

Source: https://github.com/redis/redis/blob/8.12.0/src/server.c
> mstime_t mstime(void) {
>     return ustime()/1000;
> }

> gettimeofday(&tv, NULL);

Source: https://github.com/redis/redis/blob/8.12.0/src/commands/restore.json
> "Added the `IDLETIME` and `FREQ` options."

The `RESTORE` command page on redis.io (unversioned page, read 2026-11-24):

Source: https://redis.io/docs/latest/commands/restore/
> Set the key's idle time (for LRU eviction) to this many seconds.

Source: https://github.com/redis/redis/blob/8.12.0/src/cluster.c
> /* RESTORE key ttl serialized-value [REPLACE] [ABSTTL] [IDLETIME seconds] [FREQ frequency] */

> objectSetLRUOrLFU(kv, lfu_freq, lru_idle, lru_clock, 1000);

Source: https://github.com/redis/redis/blob/8.12.0/src/object.c
>  * The lru_idle and lru_clock args are only relevant if policy
>  * is MAXMEMORY_FLAG_LRU.

> } else if (lru_idle >= 0) {

**Stated why.**

For the LRM policies, the pull request that added them (redis/redis#14624, by sundb,
merged 2026-01-06 as `0cb1ee0`) and the shipped `redis.conf` state the purpose:
evicting keys by when they were last written, whatever their reads.

Source: https://github.com/redis/redis/pull/14624
> LRM (Least Recently Modified) is similar to LRU but only updates the timestamp on write operations, not read operations. This makes it useful for evicting keys that haven't been modified recently, regardless of how frequently they are read.

Source: https://github.com/redis/redis/blob/8.12.0/redis.conf
> # This makes LRM useful when you want to evict keys that haven't been updated
> # recently, regardless of how often they are read.

**No stated rationale found** for omitting a general, readable per-key write time, as
opposed to an eviction clock. Where I looked:

- redis/redis#1258, titled `no command to find when a key was last modified/set` (2013). It
  was closed with no maintainer answer; the user replies only suggest TTL arithmetic.
- redis/redis#8399 on widening the LRU field. A maintainer comments on precision but
  not on write times.
- GitHub searches for `modification time`, `last write time` and `idletime`.

**Constraints.**

Inferred: per-object memory. The whole object header is 16 bytes in 8.12.0 (`object.h`
layout comment), and the 24-bit field is shared with LFU data. The clock exists for
eviction, not for reporting.

**Costs and dissent.**

The access stamp has misled about writes. In 2017 a shared-integer optimisation made many
keys share one idle time (antirez, redis/redis#4403, opened 2017-10-27 and still open on
the date read):

Source: https://github.com/redis/redis/issues/4403#issuecomment-340387689
> Every integer object has *a single* shared idle time. So every string set to "5" will be like sharing the same idle time. So if you set a string to a new integer, the result is that you see the idle time that the number you set happen to have.

That describes the code of 2017. At 8.12.0 a stored key's value is its own object. Adding
or overwriting a key copies a shared integer into a new object with a reference count of
1, stamps it, and hands that object on, so `updateLRM`'s early return for shared objects
(quoted above) is not reached for it, under LRM or any other policy (Inferred from
`object.c` and `db.c` at 8.12.0, read for the `SET` path through `setKey`; other write
paths were not traced, and nothing was run).

Source: https://github.com/redis/redis/blob/8.12.0/src/object.c
> kv = kvobjCreate(val->type, key, valptr, keyMetaBits);

> kv->refcount = 1;

Source: https://github.com/redis/redis/blob/8.12.0/src/db.c
> kvobj *kv = kvobjSet(key->ptr, val, spec->metabits);
>     initObjectLRUOrLFU(kv);

> *valref = kvNew;

> /* Signal key modification and update LRM timestamp. */
>     keyModified(c,db,key,*valref,!(flags & SETKEY_NO_SIGNAL));

Separately, when `maxmemory` is set under an LRU, LFU or LRM policy, integer values are
not taken from the shared pool at all; the code comment gives the reason, per-key
eviction data:

Source: https://github.com/redis/redis/blob/8.12.0/src/server.h
> #define MAXMEMORY_FLAG_NO_SHARED_INTEGERS \
>     (MAXMEMORY_FLAG_LRU|MAXMEMORY_FLAG_LFU|MAXMEMORY_FLAG_LRM)

Source: https://github.com/redis/redis/blob/8.12.0/src/object.c
> /* The function avoids returning a shared integer when LFU/LRU info
>  * are needed, that is, when the object is used as a value in the key
>  * space(for instance when the INCR command is used), and Redis is
>  * configured to evict based on LFU/LRU, so we want LFU/LRU values
>  * specific for each key. */

Source: https://github.com/redis/redis/issues/8399#issuecomment-869139727
> so 1 second resolution is not ideal for a small db which can replace the entire keyspace in one second.

Source: https://github.com/redis/redis/issues/8399#issuecomment-869139727
> and also the it means the range is about 6 months.

### K6. etcd

**Analogy.** Close in shape, opposite in kind: each key records when it was created and
last modified, but as cluster-wide logical revisions, not wall time. Keyed state.

**What it does.**

- **Fields.** `KeyValue.create_revision`, `mod_revision` and `version` (int64).
- **Who stamps.** The server, from a single Raft-ordered counter.
- **May the application supply it.** No.
- **Wall time.** No wall-clock time is stored on keys. Leases use wall-clock TTLs,
  measured by each party's own clock.
- **Future and out of order.** Not applicable.

Version: etcd `v3.7.4`; docs from etcd-io/website at SHA `e60635a` (`v3.7` pages).

Source: https://github.com/etcd-io/etcd/blob/v3.7.4/api/mvccpb/kv.proto
>   // create_revision is the revision of last creation on this key.
>   int64 create_revision = 2;
>   // mod_revision is the revision of last modification on this key.
>   int64 mod_revision = 3;

Source: https://github.com/etcd-io/website/blob/e60635a46b57b7d74ca80c52c59aa0d37bed01a8/content/en/docs/v3.7/learning/api.md
> etcd maintains a 64-bit cluster-wide counter, the store revision, that is incremented each time the key space is modified. The revision serves as a global logical clock, sequentially ordering all updates to the store.

Source: https://github.com/etcd-io/website/blob/e60635a46b57b7d74ca80c52c59aa0d37bed01a8/content/en/docs/v3.7/learning/api_guarantees.md
> revision of the operation. The revision can be used as a logical clock for key
> value store. A key value pair that has a larger revision is modified after a key
> value pair with a smaller revision.

**Stated why.**

The docs state what revisions are for: ordering, MVCC history and watch resumption.

Source: https://github.com/etcd-io/website/blob/e60635a46b57b7d74ca80c52c59aa0d37bed01a8/content/en/docs/v3.7/learning/api.md
> This revision information orders keys by time of creation and modification, which is useful for managing concurrency for distributed synchronization.

The one place the docs discuss physical time is the lease caveat:

Source: https://github.com/etcd-io/website/blob/e60635a46b57b7d74ca80c52c59aa0d37bed01a8/content/en/docs/v3.7/learning/why.md
> The most important aspect of the lease mechanism is that TTL is defined as a physical time interval. Both of the server and client measures passing of time with their own clocks. It allows a situation that the server revokes the lease but the client still claims it owns the lease.

**No stated rationale found** for omitting a wall-clock modification time. Where I looked:

- the v3.7 `api.md`, `data_model.md`, `api_guarantees.md` and `why.md` pages;
- GitHub issue searches in etcd-io/etcd: `timestamp in:title`, `modified time key`,
  `last modified`, `creation time of key`;
- a web search.

Issue #6518 (fields explained) is a usage question, not a design rationale.

**Constraints.**

- A single Raft log orders every write cluster-wide, so a server-assigned counter gives
  a total order without clocks.
- The store is MVCC: revisions are the keys of the history and of watch resumption.

**Costs and dissent.**

None found. Applications that need wall time on a key write it into the value
themselves; that this is common practice is **Unverified** (no source read).

### K7. Kubernetes

**Analogy.** Several keyed-state cases in one system. Each API object is a value at a key,
with times recorded on it:

- **`metadata.creationTimestamp`.** Stamped by the API server; clients may not set it.
- **`metadata.managedFields[].time`.** The API server's `time.Now()` when a manager last
  changed its fields.
- **Node `status.conditions[].lastHeartbeatTime`** and **Lease `spec.renewTime`.**
  Stamped by the *writing client* (kubelet) from its own clock. These are the last-seen
  case.
- **`lastTransitionTime`.** The writer of the condition sets it (Inferred from the
  types; the rule for what it should mean is quoted below).

Version: `v1.37.2`; API conventions at kubernetes/community SHA `175f04b`; KEP-589 at
kubernetes/enhancements SHA `cac930c`.

**What it does.**

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/apis/meta/v1/types.go
> 	// CreationTimestamp is a timestamp representing the server time when this object was
> 	// created. It is not guaranteed to be set in happens-before order across separate operations.
> 	// Clients may not set this value. It is represented in RFC3339 form and is in UTC.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/apis/meta/v1/types.go
> 	// Time is the timestamp of when the ManagedFields entry was added. The
> 	// timestamp will also be updated if a field is added, the manager
> 	// changes any of the owned fields value or removes a field. The
> 	// timestamp does not update when a field is removed from the entry
> 	// because another manager took it over.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/util/managedfields/internal/managedfieldsupdater.go
> 		managed.Times()[manager] = &metav1.Time{Time: time.Now().UTC()}

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/api/core/v1/types.go
> 	// Last time we got an update on a given condition.
> 	// +optional
> 	LastHeartbeatTime metav1.Time `json:"lastHeartbeatTime,omitempty" protobuf:"bytes,3,opt,name=lastHeartbeatTime"`

The general `metav1.Condition` rule for `lastTransitionTime`:

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/apis/meta/v1/types.go
> 	// lastTransitionTime is the last time the condition transitioned from one status to another.
> 	// This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.

Kubelet stamps heartbeats and lease renewals with its own clock:

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/nodestatus/setters.go
> 		currentTime := metav1.NewTime(nowFunc())

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/component-helpers/apimachinery/lease/controller.go
> 	lease.Spec.RenewTime = &metav1.MicroTime{Time: c.clock.Now()}

Precision and representation:

- `Time` marshals to RFC 3339 in UTC with whole seconds.
- `MicroTime` uses microseconds, as `RFC3339Micro`.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/apis/meta/v1/time.go
> 	buf = t.UTC().AppendFormat(buf, time.RFC3339)

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/apis/meta/v1/micro_time.go
> const RFC3339Micro = "2006-01-02T15:04:05.000000Z07:00"

**Treatment of the writer's stamp.** The node lifecycle controller does not trust the
kubelet's clock for liveness. It compares the writer's stamps only with the writer's own
earlier stamps: a changed `lastHeartbeatTime`, or a lease `renewTime` strictly later
than the one it last saved, counts as a sign of life. An equal or earlier `renewTime`
(out of order, or a clock that went backwards) does not. It then records its *own*
local time (`probeTimestamp`) as the last-seen time:

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/controller/nodelifecycle/node_lifecycle_controller.go
> 	// This timestamp is to be used instead of LastProbeTime stored in Condition. We do this
> 	// to avoid the problem with time skew across the cluster.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/controller/nodelifecycle/node_lifecycle_controller.go
> 	// per Node map storing last observed health together with a local time when it was observed.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/controller/nodelifecycle/node_lifecycle_controller.go
> 	if observedLease != nil && (savedLease == nil || savedLease.Spec.RenewTime.Before(observedLease.Spec.RenewTime)) {
> 		nodeHealth.lease = observedLease
> 		nodeHealth.probeTimestamp = nc.now()
> 	}

**Stated why.**

- **Time skew** is the stated reason for the reader-side last-seen time (controller comment
  above).
- **`creationTimestamp`.** "Clients may not set this value" is stated as a rule, with no
  rationale. **No stated rationale found** in the types or API conventions.
- **Naming convention.**

Source: https://github.com/kubernetes/community/blob/175f04bc631df9d949b1d4b9265f7b631041ac32/contributors/devel/sig-architecture/api-conventions.md
> * The name of a field that specifies the time at which `something` occurs should
> be called `somethingTime`. Do not use `stamp` (e.g., `creationTimestamp`).

- **Moving node heartbeats to Leases (KEP-589).** The why is etcd size and write
  volume, not time:

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/589-efficient-node-heartbeats/README.md
> - node heartbeats being pontetially very large objects (note that images
>   are only one potential problem, the second are volumes and customers
>   want to mount 100+ volumes to a single node) - they may easily exceed 15kB;
>   even though the patch send over network is small, in etcd we store the
> 	whole Node object
> - Kubelet sending heartbeats every 10s

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/589-efficient-node-heartbeats/README.md
> The only difference is using `MicroTime` instead of `Time` for better precision.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/589-efficient-node-heartbeats/README.md
>    Note that it doesn't reduce frequency by which Kubelet sends "meaningful"
>    changes - it only impacts the frequency of "lastHeartbeatTime" changes.

**Constraints.**

- Many independent writers (kubelets on thousands of nodes) with unsynchronised clocks.
- One authoritative store, written through the API server.
- Heartbeat writes are expensive at scale (KEP-589).

**Costs and dissent.**

KEP-589's Risks and Mitigations section warns that updating NodeStatus less often
"may potentially break clients" relying on frequent updates. Its author read client
code that uses `LastHeartbeatTime` and found a few places incompatible with leases,
which "would already be broken" by the then-current one-minute frequency. These are
incompatibilities found by reading code, not reported incidents.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/589-efficient-node-heartbeats/README.md
> Increasing default frequency of NodeStatus updates may potentially break clients
> relying on frequent Node object updates.

> There are couple places that
> are incompatible with node leases, but they would already be broken by current
> 1m frequency, e.g.:

The API conventions say historical condition info is best-effort:

Source: https://github.com/kubernetes/community/blob/175f04bc631df9d949b1d4b9265f7b631041ac32/contributors/devel/sig-architecture/api-conventions.md
> Historical information status (e.g., last transition time, failure counts) is
> only provided with reasonable effort, and is not guaranteed to not be lost.

### K8. Amazon DynamoDB

**Analogy.**

- Keyed store (item per primary key).
- It records **no** last-modified time on items. Nothing in the developer guide pages
  read describes one; this absence is inferred from those pages, not stated by AWS.
- Applications that want one write an ordinary attribute themselves, or have AWS's Java
  SDK v2 Enhanced Client stamp a tagged attribute for them (opt-in; below).
- The service stamps change-stream records instead.

**What it does.**

- **Item attributes.** The service sets none; every attribute is written by the caller.
  TTL is an application-written Number attribute, epoch seconds.
- **SDK stamping (Java SDK v2 Enhanced Client, opt-in).**
  `AutoGeneratedTimestampRecordExtension` stamps each attribute the application tags,
  which must be an `Instant`, on every write made through the Enhanced Client. It is not
  loaded by default. Pull request 2757's description pairs it with
  `@DynamoDbUpdateBehavior(WRITE_IF_NOT_EXISTS)` to keep the first stamp, for a creation
  time; that combination was not checked in the code (Unverified). The clock is
  `Clock.systemUTC()` unless the application configures a `baseClock`. In the source
  read, the stamp replaces any value the application put in the tagged attribute (read
  from the code, not run). Writes made through other clients or the low-level API are
  not stamped (Inferred). How the `Instant` is stored follows the attribute's converter
  (Unverified). Version `2.59.8`.

  Source: https://github.com/aws/aws-sdk-java-v2/blob/2.59.8/services-custom/dynamodb-enhanced/src/main/java/software/amazon/awssdk/enhanced/dynamodb/extensions/AutoGeneratedTimestampRecordExtension.java

  >  * This extension enables selected attributes to be automatically updated with a current timestamp every time they are written
  >  * to the database.

  >  *     This extension is not loaded by default when you instantiate a
  >  *     {@link software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient}. Thus you need to specify it in custom extension
  >  *     while creating the enhanced client.

  >         this.clock = builder.baseClock == null ? Clock.systemUTC() : builder.baseClock;

  >         itemToTransform.put(key, converter.transformFrom(instant));

- **DynamoDB Streams.** `StreamRecord.ApproximateCreationDateTime` is stamped by the
  service, epoch seconds, rounded down.
- **Kinesis Data Streams destination.** The same field in milliseconds by default, or
  microseconds if configured (`ApproximateCreationDateTimePrecision`). It is documented
  as the way to order and de-duplicate records that may arrive out of order.
- **Global tables.** Two consistency modes, chosen when the global table is created and
  not changeable afterwards.
  - Multi-Region eventual consistency (MREC, the default): concurrent writes in
    different Regions are resolved by "the latest internal timestamp" (last writer
    wins). No API to supply that timestamp appears in the pages read (Inferred).
  - Multi-Region strong consistency (MRSC): writes replicate synchronously. A write to
    an item being modified in another Region fails with
    `ReplicatedWriteConflictException` and may be retried. No timestamp decides it.
- **Too-old TTL values.** Ignored when more than five years in the past.

Pages read from `docs.aws.amazon.com/amazondynamodb/latest/...` as `.md` renditions
(unversioned; date read 2026-11-24).

Source: https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_streams_StreamRecord.html
> The approximate date and time when the stream record was created, in [UNIX epoch time](http://www.epochconverter.com/) format and rounded down to the closest second.

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/kds.html
> The Kinesis data stream records might appear in a different order than when the item changes occurred. The same item notifications might also appear more than once in the stream. You can check the `ApproximateCreationDateTime` attribute to identify the order that the item modifications occurred in, and to identify duplicate records. 

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/kds.html
> When you enable a Kinesis data stream as a streaming destination of a DynamoDB table, you can configure the precision of `ApproximateCreationDateTime` values in either milliseconds or microseconds. By default, `ApproximateCreationDateTime` indicates the time of the change in milliseconds.

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_HowItWorks.html
> If the same item is modified in multiple Regions simultaneously, DynamoDB will resolve the conflict by using the modification with the latest internal timestamp on a per-item basis, referred to as a "last writer wins" conflict resolution method.

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_HowItWorks.html
> If you do not specify a consistency mode when creating a global table, the global table defaults to multi-Region eventual consistency (MREC). A global table cannot contain replicas configured with different consistency modes. You cannot change a global table's consistency mode after creation.

> A write operation fails with a `ReplicatedWriteConflictException` when it attempts to modify an item that is already being modified in another Region. Writes that fail with the `ReplicatedWriteConflictException` can be retried and will succeed if the item is no longer being modified in another Region.

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/time-to-live-ttl-before-you-start.html
> The computed expiration time must be in epoch format, in seconds. To be considered for expiry and deletion, the TTL can't be more than five years in the past. If you use any other format, the TTL processes ignore the item.

**Stated why.**

For the choice between the two global-table modes, AWS states the trade-off:

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_HowItWorks.html
> The key criteria for choosing a multi-Region consistency mode is whether your application prioritizes lower latency writes and strongly consistent reads, or prioritizes global strong consistency.

**No stated rationale found** for the absence of an item write time or for the stream
time's precision. Where I looked:

- the StreamRecord, EnableKinesisStreamingConfiguration, Kinesis Data Streams, TTL
  (three pages), global tables how-it-works and core components pages;
- a web search for the launch announcement of microsecond precision.

None was found, so the launch date is **Unverified**. A search summary claimed an AWS CDK
page gives microseconds as the default. That contradicts `kds.md`, which says
milliseconds, and was not verified: **Unverified**, not relied on.

For the SDK extension, the stated reason is parity with SDK v1, not a reason for stamping
in the library rather than the service. No stated rationale was found for that choice;
where I looked: issue 1920 and its comments, pull request 2757, and the v1
`@DynamoDBAutoGeneratedTimestamp` Javadoc at `1.12.797`.

Source: https://github.com/aws/aws-sdk-java-v2/issues/1920

> V1 can automatically generate timestamps for newly created or updated records with the @DynamoDBAutoGeneratedTimestamp annotation. This could be added as an extension to V2.

**Constraints.**

- Managed, multi-tenant service; the application never sees server clocks except
  through stream records.
- Multi-Region replication needs a conflict rule. Under MREC, the default, the service
  uses its own internal timestamp (last writer wins); under MRSC it replicates
  synchronously and rejects the conflicting write (global tables page). The mode is fixed
  when the table is created.
- Change streams can deliver out of order and more than once (Kinesis destination), so
  the service-stamped time is offered as the ordering and de-duplication key.
- The SDK extension stamps from the writing host's clock, so items written by different
  hosts carry times from different clocks (Inferred).

**Costs and dissent.**

None found in the pages read. The finer Kinesis precision option (milliseconds or
microseconds) suggests that whole seconds were too coarse for ordering; that is
Inferred, not stated.

### K9. OpenTelemetry metrics: Gauge / last-value

**Analogy.** Partial. A Gauge point holds the last measured value per attribute set (a
"key"), with the time of that measurement. That is keyed, last-value state, but it lives
in an SDK aggregation, not a store.

**What it does.**

- **Who stamps.** The SDK, at measurement and collection.
- **May the application supply it.** No. The API spec's Gauge `Record` lists a value
  and attributes, and no timestamp (quoted below).
- **Field.** `time_unix_nano`, fixed64 nanoseconds since the Unix epoch.
- **Start time.** `StartTimeUnixNano` is ignored for Gauge.

Version: opentelemetry-proto `v1.11.1`; specification `v1.63.0`.

Source: https://github.com/open-telemetry/opentelemetry-proto/blob/v1.11.1/opentelemetry/proto/metrics/v1/metrics.proto
> // Gauge represents the type of a scalar metric that always exports the
> // "current value" for every data point. It should be used for an "unknown"
> // aggregation.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md
> - The last `Measurement`.
> - The timestamp of the last `Measurement`.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/api.md
> Record the Gauge current value.
>
> This API SHOULD NOT return a value (it MAY return a dummy value if required by
> certain programming languages or systems, for example `null`, `undefined`).
>
> This API MUST accept the following parameter:
>
> * A numeric value. The current absolute value.

The only other parameter listed is attributes.

**Stated why.**

A request to let application code pass a timestamp on `record`/`add` was closed "not
planned" (open-telemetry/opentelemetry-specification#4343):

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/4343#issuecomment-2607964405
> @ThePlenkov makes sense, I'm just not sure if there's an easy solution to this, as adding custom timestamp to the metrics API would probably add considerable complexity to all of the language implementations since they would then need to bucket things by timestamp as well, and it's unclear when you would export out those old buckets (how do you know when the last timestamp for an old bucket was received), or can a single old bucket be sent across multiple exports, which adds even more complexity

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/4343#issuecomment-2615351984
> After discussing in the project triage session from 2025-01-27, we agree with @trask that there is no easy solution to this in the Metrics API; it seems like a Collector receiver or considering using the Events API are more suitable solutions for this problem.

**Constraints.**

- The SDK aggregates in memory and exports on a collection cycle. A caller-supplied
  time would need per-timestamp buckets and a rule for when an old bucket is final
  (trask, quoted above).

**Costs and dissent.**

The requester in #4343 built a workaround (a hidden attribute rewritten at collection)
and later reported it did not work; the issue stays closed as not planned.

(OpenTelemetry logs and spans, where a caller-supplied timestamp is allowed, are T1 and
T2.)

### K10. Apache ZooKeeper

**Analogy.** Each znode is a value at a path, and its stat records when it was created and
last modified twice over: as transaction ids from one total order, and as wall-clock
milliseconds. Keyed state.

**What it does.** Tag `release-3.9.4`.

- **Fields.** `czxid` and `mzxid` (transaction ids, int64), `ctime` and `mtime`
  (milliseconds since the Unix epoch), with version counters, in the node's stat.
- **Who stamps.** The server. The request processor that turns a request into a
  transaction stamps the transaction header with its wall clock
  (`Time.currentWallTime()`, which is `System.currentTimeMillis()`). In a quorum that
  processor runs on the leader. Every server applies the header's time, so a change has
  one `mtime` on every replica.
- **May the application supply it.** No: the create and set-data requests carry no time.
- **Future and out of order.** Not applicable, since no time is supplied. Whether
  `mtime` can move backwards when leadership passes to a server with a slower clock is
  not documented (Unverified).

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-docs/src/main/resources/markdown/zookeeperProgrammers.md
> This exposes the total ordering of all changes to ZooKeeper. Each
>   change will have a unique zxid and if zxid1 is smaller than zxid2
>   then zxid1 happened before zxid2.

>   ZooKeeper doesn't use real time, or clock time, at all except
>   to put timestamps into the stat structure on znode creation and
>   znode modification.

>   The time in milliseconds from epoch when this znode was last
>   modified.

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-jute/src/main/resources/zookeeper.jute
>     class SetDataRequest {
>         ustring path;
>         buffer data;
>         int version;
>     }

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/server/PrepRequestProcessor.java
> Time.currentWallTime(), type));

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/common/Time.java
>     public static long currentWallTime() {
>         return System.currentTimeMillis();
>     }

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/server/quorum/LeaderZooKeeperServer.java
>  * processors: PrepRequestProcessor -&gt; ProposalRequestProcessor -&gt;

Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/server/DataTree.java
>             n.stat.setMtime(time);
>             n.stat.setMzxid(zxid);

**Stated why.**

No stated rationale found for keeping a wall-clock time beside the zxid. Where I looked:

- the programmer's guide at `release-3.9.4` ("Time in ZooKeeper" and "ZooKeeper Stat
  Structure");
- Apache JIRA, `project = ZOOKEEPER AND text ~ "mtime"` (43 issues, titles read).

The one related author statement comes from ZOOKEEPER-1366 (fixed in 3.5.1 and 3.6.0).
That issue moved timers from wall time to elapsed time, after the reporter, Ted Dunning,
showed that a clock change expired every session at once. Reviewing it, Benjamin Reed
asked that the time used for `mtime` stay wall time, and proposed `Time.currentWallTime()`
to mark each remaining wall-clock use:

Source: https://issues.apache.org/jira/browse/ZOOKEEPER-1366
> If you want to wreak havoc on a ZK based system just do [date -s "+1hour"] and watch the mayhem as all sessions expire at once.

> The absolute times are subject to adjustment when the clock is set while a timer is not subject to this problem.

> in ZooKeeperServer.java getTime() should return the wall time since that is used for the mtime.

> after crawling through everything, i think it would be nice if Time also had Time.currentWallTime() that did System.currentMillis(). that way if we saw an instance of System.currentMillis() in the code it would be a flag that the use should be reviewed.

**Constraints.**

- One leader orders every write, and the zxid exposes the total order. The guide says
  real time is used for nothing except the stat timestamps (quoted above). The same
  release qualifies that: the `ContainerManager`, which `LeaderZooKeeperServer` starts,
  compares the server's wall clock with a node's `mtime` to decide when an optional TTL
  node (added in 3.5.3, disabled by default) or a never-used container node becomes a
  candidate for deletion. That the wall-clock stamp plays no part in ordering is Inferred
  from the guide and the zxid definition; the TTL use is expiry, not ordering.

  Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/server/ContainerManager.java

  > return Time.currentWallTime() - node.stat.getMtime();

  > if ((ttl != 0) && (getElapsed(node) > ttl)) {

  > if ((maxNeverUsedIntervalMs != 0) && (getElapsed(node) > maxNeverUsedIntervalMs)) {

  Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-server/src/main/java/org/apache/zookeeper/server/quorum/LeaderZooKeeperServer.java

  > containerManager = new ContainerManager(

  Source: https://github.com/apache/zookeeper/blob/release-3.9.4/zookeeper-docs/src/main/resources/markdown/zookeeperProgrammers.md

  > you can optionally set a TTL in milliseconds for the znode. If the znode
  > is not modified within the TTL and has no children it will become a candidate
  > to be deleted by the server at some point in the future.

  > Note: TTL Nodes must be enabled via System property as they
  > are disabled by default.
- The stamp is taken once and replicated in the transaction header, so replicas agree on
  it (code quoted above).

**Costs and dissent.**

- Using wall time for elapsed-time measures cost mass session expiry on a clock change
  (ZOOKEEPER-1366). The fix moved timers to elapsed time and kept `mtime` on wall time.
- TTL expiry still measures elapsed time as wall clock minus `mtime`, so a step in the
  wall clock, or a difference between the clock that stamped `mtime` and the clock of the
  server that checks it, moves when a TTL node becomes eligible for deletion (Inferred
  from `ContainerManager.java` at `release-3.9.4`; not documented in what was read, not
  tested). It is the kind of clock dependence ZOOKEEPER-1366 removed from session timers.
- No dissent about `mtime` itself was found in the JIRA titles searched.

### K11. Cloud Firestore

**Analogy.** Close in shape: a document store that records, for each document, when it
was last changed, stamped by the service and never by the caller. Family: keyed state. A
managed database service, not an embedded library.

**What it does.** `googleapis/googleapis` at `9c0bfc06db6841da058b88c7054153ac22fc2465`,
and the Firebase REST reference (unversioned; read 2026-11-24).

- **Who stamps.** The service, into `create_time` and `update_time` on every document.
- **May the application supply it.** No: both are output only. Separately, a write may ask
  the service to put its own time into an application field (`REQUEST_TIME`, millisecond
  precision).
- **What counts as a change.** A write that does not change the document leaves
  `update_time` as it was.
- **Field, precision, epoch.** `google.protobuf.Timestamp`; RFC 3339 over REST, with 0, 3,
  6 or 9 fractional digits. A precondition on `update_time` must be microsecond aligned,
  which suggests microsecond precision (Inferred).
- **Ordering.** `update_time` increases with each change to a document, and is documented
  as comparable across documents and with a query's `read_time`.
- **Future, too old, out of order.** Not applicable: no supplied time.

Source: https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents

> Uses RFC 3339, where generated output will always be Z-normalized and use 0, 3, 6 or 9 fractional digits.

Source: https://github.com/googleapis/googleapis/blob/9c0bfc06db6841da058b88c7054153ac22fc2465/google/firestore/v1/document.proto

>   // Output only. The time at which the document was last changed.
>   //
>   // This value is initially set to the `create_time` then increases
>   // monotonically with each change to the document. It can also be
>   // compared to values from other documents and the `read_time` of a query.
>   google.protobuf.Timestamp update_time = 4;

Source: https://github.com/googleapis/googleapis/blob/9c0bfc06db6841da058b88c7054153ac22fc2465/google/firestore/v1/write.proto

>   // The last update time of the document after applying the write. Not set
>   // after a `delete`.
>   //
>   // If the write did not actually change the document, this will be the
>   // previous update_time.

>       // The time at which the server processed the request, with millisecond
>       // precision. If used on multiple fields (same or different documents) in
>       // a transaction, all the fields will get the same server timestamp.
>       REQUEST_TIME = 1;

Source: https://github.com/googleapis/googleapis/blob/9c0bfc06db6841da058b88c7054153ac22fc2465/google/firestore/v1/common.proto

>     // When set, the target document must exist and have been last updated at
>     // that time. Timestamp must be microsecond aligned.
>     google.protobuf.Timestamp update_time = 2;

**Stated why.**

**No stated rationale found** for making `update_time` service-only. Where I looked: the
three protos above and their commit history (synchronisation commits with no message
body), the Firebase `Document` REST reference, the "Add data" guide's section on server
timestamps, the "Transaction serializability and isolation" page (quoted below), the
"Transactions" guide, and Cloud Firestore "Best practices".

**Inferred why.** `update_time` doubles as the document's version: a write can be made
conditional on it, and the mobile and web SDKs build their transactions on preconditions
on document versions. A caller-set value could not serve as that version. Inferred; no
author states it.

Source: https://firebase.google.com/docs/firestore/transaction-data-contention

> Mobile and web SDKs emulate optimistic concurrency transactions using write
> preconditions on document versions.

**Constraints.**

- Managed service; every write passes through it, so it can stamp every change (Inferred).
- The stamp is used for conditional writes (`Precondition.update_time`, quoted above).
- What clock produces the stamp, and how cross-document comparability is achieved, is
  not documented in the pages read (Unverified).

**Costs and dissent.** None found in the pages read.

## Comparables that chose otherwise

The comparables named here let application code supply a time, and differ in what happens when it does not:

- **The same field is stamped instead:** Log4j 2 through `TimestampMessage` (T4), Fluentd's clients (T8), InfluxDB (T10), Kafka under `CreateTime` (T12, K4), Cassandra (K1) and HBase (K2).
- **That field stays unset, and a separate field is stamped:** OpenTelemetry logs (T1) leave `Timestamp` unset and fill `ObservedTimestamp`.
- **A time is expected in every entry, and no fallback is documented:** Loki's push API (T9). Its shipping agents can assign one instead (T9, "Costs and dissent").

These chose otherwise, each with a stated why:

- **Rust `tracing` (T6): the event carries no time at all, and each consumer stamps it.** A timestamp in the core would cost every layer that does not want one, and would force `std` time on `no_std` users.
- **Prometheus (T11): the server stamps at scrape, and client timestamps are discouraged.** Different times within one scrape break features that assume one, and most users who asked for client timestamps did not need them.
- **Kafka topics set to `LogAppendTime` (T12, K4): the broker overwrites the producer's time.** KIP-32 lists the broker as more robust, its time as monotonically increasing, and retention as deterministic. The monotonic claim is the KIP's stated rationale; the 4.4.0 code read does not clamp the time across a change of leader, and a user has reported it going backwards (T12, Costs and dissent).
- **OpenTelemetry metrics (K9): a gauge's measurement takes no caller-supplied time.** A request for one was declined, because each SDK would have to bucket measurements by time and decide when an old bucket is final.
- **Kubernetes' node lifecycle controller (K7): the reader does not trust the writer's stamp for liveness.** It records its own local time when it sees a newer heartbeat, "to avoid the problem with time skew across the cluster".

Within those that accept a supplied time, two moved the default stamper in opposite directions:

- **Cassandra (K1) moved it from the server to the client library**, in Java driver 3.0, so that one client thread's writes stay in order and a retry keeps its first timestamp. Server stamping stays available, because of resistance to removing it.
- **HBase (K2) proposed moving it the other way**: a server-stamped hybrid logical clock, with client timestamps deprecated. Users who supply event-time timestamps objected, and the deprecation has not proceeded.

Python `logging` (T3) and Logback with SLF4J (T5) also give a logging call no time parameter, but no stated rationale was found for either. Flink's state TTL (K3) accepts no supplied time; event-time TTL was discussed and never built, with no stated rejection.

etcd (K6) and DynamoDB (K8) record no wall-clock write time on a key. Redis (K5) records one only as an eviction clock under its LRM policies, at one-second resolution and wrapping. No stated rationale was found, in any of the three, for omitting a general write time. For DynamoDB that holds for the service; AWS's Java SDK v2 can stamp a tagged attribute client side, opt-in (K8).

ZooKeeper (K10) and Cloud Firestore (K11) are the reverse case: the server stamps each change itself, and callers cannot set the time. ZooKeeper stamps a wall-clock `mtime` beside its transaction id; no stated rationale was found for keeping the wall time, beyond ZOOKEEPER-1366's decision to leave `mtime` on it. Firestore stamps each document's last change; no stated rationale was found.

The systemd journal (T13) also takes no client-set time for its own stamps: it stamps every entry on receipt on a wall clock and a monotonic clock, and keeps a client's syslog timestamp only as an unvalidated field. Its design document gives the reason for the trusted fields a client cannot set: syslog stored the client's metadata, timestamp included, unverified. Its documentation states why it keeps the reception time, the boot id and a sequence number; no rationale specific to refusing a client-set reception time was found.

## Candidates not examined, or dropped

- **The OpenTelemetry Collector's `filelog` receiver.** Covered through the issue that led to `ObservedTimestamp` (T1), which drew on it; not read separately.
- **Telegraf, StatsD and Graphite.** Not reached.
- **Java's `java.util.logging`.** Not read, so not reported.
- **Prometheus's design document for out-of-order ingestion.** Hosted on Google Docs and not fetchable as raw text (Unverified).
- **Kafka KIP-1030**, which made the one-hour future bound the default. Known only from the upgrade note quoted in T12 (Unverified beyond that note).
- **Kafka KIP-33**, the time index. It concerns retention mechanics, not who stamps; quoted once in T12 for that reason.
- **CASSANDRA-5153.** Fetched and dropped: it concerns SSTable timestamp metadata, not who stamps.
- **etcd issue 6518.** A usage question about the revision fields, with no design rationale.
- **OpenTelemetry's cumulative `StartTimeUnixNano`.** A series-start time, not a last-write time.

## Fit

### The constraints of this client

From the specification and `CONTEXT.md`. A leaning is cited as a leaning.

- **C1. An embedded library.** The client runs in the application's own process. The code that writes a row is the application itself, and the client is the first code to see the write (the specification's Scope).
- **C2. A write never fails, never blocks and returns nothing** (`NeverFailsNeverBlocks`). A supplied time that is wrong cannot be refused loudly. It can only be kept, changed, or refused and counted.
- **C3. Within one process the client's clock never moves backwards, and there is no ordering promise across processes** (`ClockNeverMovesBackwards`, settled).
- **C4. Order within a run is the position, not the time.** Each accepted row gets the next position when it is accepted, and a lost row leaves a gap (marked "Derived" in `AcceptRow`). Nothing in the specification orders rows by time.
- **C5. A keyed value records when it was last written** (settled: the ticket, and the specification's `TableKind` comment). Which value is a slot's latest is decided by position: the one with the highest position, whatever order the rows were stored in (marked "Derived" in the specification, above `StoreSupersededKeyedRow`). The analysis below uses that rule as the current proposal, not as a settled promise. The maintainer's leaning is that time-to-live belongs to the final data store, which would read that time ("Leanings, not decisions").
- **C6. The time is handed over** with each row to a collector, whose form is open question 15. A collector leans towards a pull (leaning). The client is not the store that keeps the rows in the end.
- **C7. One behaviour for Rust and Python.**
- **C8. The standing guidance:** follow practice rather than invent; prefer coordination-free solutions; keep the MVP simple without closing off later options.
- **C9. The host.** The most common host is an ephemeral cloud pod (leaning). Nothing in the specification assumes the host's wall clock is synchronised.

### Fit of each comparable

"Justifies" means the comparable has a stated why and its constraints hold here; "informs" means one of the two is missing.

| Comparable | Stated why leaned on | Holds here | Does not hold | Verdict |
| --- | --- | --- | --- | --- |
| T1 OpenTelemetry logs | `ObservedTimestamp` is when OpenTelemetry's code first saw the event, "only context about how the event was processed"; the gap between the two times diagnoses lag | The client is the in-process code that first sees a write (C1); the collector downstream can compare times (C6) | OpenTelemetry also lets a bridge supply either time, for logging libraries that stamped already; this client has no such upstream library | Justifies: the client's stamp is an observation time |
| T2 OpenTelemetry traces, Java clock | Java's epoch time is coarse and reading it is slow, so wall time is anchored once and advanced by `nanoTime` | A wall clock that must not go backwards in a process (C3) | Span times are operations, not rows | Informs: a way to build the clock |
| T3 Python `logging` | No stated rationale for the missing time parameter | In-process stamping (C1, C7) | — | Informs |
| T4 Log4j 2 | Applications needing accurate times, and late decisions to log a milestone, need to supply the time (LOG4J2-53); a commenter cited MiFID II for finer precision (LOG4J2-1883) | In-process stamping (C1) | Log4j's event time is the only time on the event, so supplying it replaces the stamp; here the application can declare a column without losing the client's stamp | Informs, as dissent |
| T5 Logback / SLF4J | No stated rationale for the missing caller time; a reporter's reason for sub-millisecond precision was ordering by time in a store | In-process stamping (C1) | Rows here are ordered by position (C4), so precision is not needed for order | Informs |
| T6 Rust `tracing` | A timestamp in the core costs every layer that does not want one, and forces `std` time on `no_std` | — | The client must stamp: the time is handed over (C6), and the client is not `no_std` | Informs, as a choice that does not fit |
| T7 Elastic Common Schema | `event.ingested` exists because sources go offline, pipelines back up and an attacker can move a source clock; `event.created` measures agent lag | Three parties, three named times; the client's place is the agent's (C1, C6) | ECS stamps nothing itself | Informs: the client's stamp is one of several downstream may keep |
| T8 Fluentd, Fluent Bit | A substituted current time cannot be told from a parsed one (pull request 370) | A time the client substitutes should be distinguishable (C6) | Collectors across hosts and protocols | Informs |
| T9 Loki | The in-order rule lost logs from agents that retry independently; a window still bounds the chunks | — | Server-side store with chunks per stream; ordering is by time there, by position here (C4) | Informs: a store downstream may bound times the client hands over |
| T10 InfluxDB | Include a time if you want observation, not receipt; coarser precision for performance; NTP for the host | — | Server-side store; the "observation" it means is the application's, which a column carries here | Informs |
| T11 Prometheus | Different times in one scrape break features, and most requests for client times were mistaken | A collector may pull (C6, leaning) | Staleness per scrape has no counterpart here | Informs |
| T12 Kafka | KIP-32 listed among the broker time's advantages that a create time "can always be put into the message payload", but decided to let each topic choose, because "both LogAppendTime and CreateTime have their own use cases", and rejected a broker-time-only format because "Instead of asking each application to do this, it is better to include the timestamp in the message"; KIP-937: future times are inaccurate, and producers sent nanoseconds as milliseconds | The client is where a row is appended and given its position, as the broker is (C4); a write cannot be rejected loudly (C2), so a bounds check like KIP-937's would have to count | Retention by time has no counterpart: the client purges by confirmation. The monotonic claim is not enforced across Kafka leaders, but this client has one writer per run. Kafka's stated reason for its decision favours a per-topic choice (D), and its rejected Option 2 is A's design | Informs: KIP-937 records the risks of a supplied time; KIP-32's decision leans towards D |
| T13 systemd journal | Trusted fields "cannot be faked by the client side" and are "not supplied by a potentially rogue client", because syslog stored client metadata, timestamp included, unverified. No stated rationale found for keeping the reception stamps in particular from the client | A process-local receiver that stamps on receipt (C1, C3) | A separate daemon; clients are other, untrusted processes. The trust boundary the stated reason defends does not exist here: the writer is the host application, in the client's own process (C1), and an application can reach whatever a library in its own process holds, so the client's stamp is no defence against the application (Inferred) | Informs: a receiver stamps its own reception time. That the writer may not set it is Inferred |
| K1 Cassandra | Server stamps reorder one client thread's writes; client stamps keep them in order and make retries idempotent (CASSANDRA-6178); applications choose nonsensical times and mix up units (CASSANDRA-18352) | The client is the writer's own process, so its stamp is the client-side stamp Cassandra moved to (C1, C3); a supplied time can be wrong in units (C2) | Cassandra orders values by time (last write wins); here position orders them (C4) | Justifies the clock rule (monotonic in one process) and the risk of supplied times |
| K2 HBase | The cell timestamp drives TTL, so set it yourself only with care; prefer a separate timestamp attribute (reference guide); server-only stamps break replication (HBASE-10247) | Downstream expiry reads the keyed time (C5, leaning) | HBase orders versions by time; replication replays edits | Justifies: keep the application's time in its own column |
| K3 Flink state TTL | Zagrebin, opening the thread: event time can decrease, which "is unnatural for the notion of time"; Kloudas: event time is "just another user-defined column". Which clock regulatory expiry runs from was disputed: Kloudas, "not sure about the regulatory requirements of GDPR", assumed ingestion, and Krettek argued from GDPR for event time, so it is not leaned on. Zagrebin's "preliminary wrap-up" then named event time of the record being processed as the trend for the last-access time | A keyed last-write time used for expiry (C5); a time that must not go back (C3) | A stream processor. The discussion's trend went the other way; event-time TTL never shipped, and processing time, which shipped first, has no stated why of its own | Informs, and its discussion leans the other way |
| K4 Kafka KTables, compaction | KIP-258 stores the latest record's time with the value; compaction is by offset, and KIP-280's time-based compaction was never shipped | Latest value by position (C4, C5; Derived) | The time stored is the record's, not the table write's, unless an extractor substitutes processing time | Informs |
| K5 Redis | LRM evicts by last write regardless of reads | A write-only clock (C5) | An eviction clock, not a readable field | Informs |
| K6 etcd | Revisions are a logical clock for ordering; no reason for omitting wall time | Order by a counter, not a clock (C4) | Cluster-wide consensus | Informs |
| K7 Kubernetes | The node controller uses its own local time "to avoid the problem with time skew across the cluster" | No ordering across processes (C3); a collector may prefer its own clock (C6) | Many writers to one store | Informs |
| K8 DynamoDB | No stated rationale for omitting a write time | — | — | Informs |
| K9 OpenTelemetry gauge | A caller time would need per-time buckets and a rule for when an old bucket is final | An in-process SDK (C1) | Aggregation in memory before export | Informs |
| K10 ZooKeeper | No stated rationale for keeping wall time beside the zxid | A wall time beside an order counter (C4) | Consensus server | Informs |
| K11 Cloud Firestore | No stated rationale found | Service-owned last-change time | Managed service | Informs |

## Options the settled promises rule out

- **Refusing a bad supplied time loudly**, by raising, panicking or returning an error. A write never fails (C2).
- **Blocking a write** to wait for a clock to be synchronised or to settle. A write never blocks (C2).
- **A row time that moves backwards within a process while still described as the client's clock.** The clock never moves backwards (C3). An application-supplied time can therefore be the row's time only if the promise is restated to cover the client's clock alone, or the client changes the supplied time.
- **A keyed value whose only time is not the time of its write.** A keyed value records when it was last written (C5, settled). An application-supplied time can therefore be a keyed value's only time only if it is the time of the write itself, which the client cannot check (C2), or if the client keeps its own time beside it, which is B.

## Options

In every option the client keeps its own clock and its promise. The options differ in what the application may do.

### A. The client stamps every row; application code supplies no time

As today. An application that has its own time for an event, such as when it happened, declares an ordinary column for it and writes it as a value. The client neither reads nor checks that column.

- **Time series tables.** Every row carries one client time, never moving backwards within a process. The application's own time, if any, is data.
- **Keyed state tables.** A value's time is when the client accepted its latest write. The application's time, if any, is a column of the value.
- **Monotonic promise.** Holds for every row's time without change.
- **Costs.** An application that replays or backfills old events cannot give them their original time as the row's time, only as a column (LOG4J2-53's case, KIP-937's replay case, CASSANDRA-4947's replay case). A collector that wants event time has to know which column holds it.

### B. As A, plus an application time in a field the client defines

The client stamps its time as in A. A write may also carry an application time, stored in a separate field that every table has, like OpenTelemetry's `Timestamp` beside `ObservedTimestamp` (T1), ECS's `@timestamp` beside `event.created` (T7), or the journal's `SYSLOG_TIMESTAMP` beside its own stamps (T13).

- **Monotonic promise.** Holds for the client's time. The application's field carries no promise.
- **What a bad supplied time does.** Nothing to the client's time or to order. Whether the field is checked (in the future, too old, in the wrong unit) is a further choice; a check could only count, not refuse loudly (C2).
- **Costs.** A field the client adds to every table collides with a column of the same name (open question 20). The write API gains a parameter in Rust and Python (C7). It adds what A already allows as a column, under a fixed name.

### C. The application may supply the row's time, replacing the client's

As Log4j's `TimestampMessage` (T4), Kafka's `CreateTime` (T12), Loki (T9), InfluxDB (T10) and Cassandra's `USING TIMESTAMP` (K1).

- **Monotonic promise.** No longer holds for the row's time. Rows of one process may carry times out of order, in the future or in the past.
- **Keyed state tables.** Either the latest value by position may carry an older time than the value it replaced, or values are ordered by the supplied time, which changes the slots (C4) and brings Cassandra's and HBase's costs: a far-future time wins over every later write (CASSANDRA-18352's "doomstone"), and a wrong unit leaves a value that cannot be replaced (CASSANDRA-18374).
- **The settled keyed record.** Under C a keyed value's only time is the one the application supplied, so the value records when it was last written (C5, settled) only if the application supplies the time of the write itself. The cases C exists for, a replayed, backfilled or event time (A's costs), are not that time, even when they arrive in increasing order, and the client cannot tell one from the other (C2). A keyed table keeps the settled record and an application's time together only by keeping the client's time beside it, which is B.
- **What a bad supplied time does.** The client can keep it, clamp it to a window (as Loki and Kafka bound theirs), or refuse the row and count it. It cannot refuse loudly (C2).
- **Costs.** The collector can no longer tell client lag from application time, which is what OpenTelemetry's and ECS's second time exists for (T1, T7).

### D. A per-table choice between A and C

As Kafka's per-topic `message.timestamp.type` (T12). The declaration says which time a table's rows carry. KIP-32's stated reason for the choice is that "both LogAppendTime and CreateTime have their own use cases" (T12).

- **Costs.** C's costs for tables that choose it, and a declaration field that identical redeclaration must match (open question 16). A keyed table that chose C would lose the settled record of when its value was last written, unless the supplied time is the time of the write (C5); a D that offered C to time series tables only would avoid that, and is a further choice.

### The clock itself, under every option

The settled promise says the client's clock never moves backwards within a process. A wall clock can step back (NTP, a manual change). Two ways to honour the promise:

- **Clamp.** Read the wall clock; if the reading is earlier than the last value the process took from the client's clock, for a stamp or for anything else, use that value again. Cassandra's Java driver does nearly this by default, for the reason CASSANDRA-6178 gives (one client thread's writes must not go back in time): when the clock falls behind its last stamp, its stamps "will be artificially incremented to guarantee monotonicity", and it warns when they drift ahead of the clock (K1). Using the last value again, without the increment, is this client's adaptation (argued after these two bullets). The Java OpenTelemetry SDK's anchored clock is another way: read the wall clock once, then advance by a monotonic clock (T2).
- **Use a monotonic clock as the stamp.** Ruled out by the hand-over (C6): a monotonic reading "is NOT time since any particular epoch" (Jonathan Ellis in CASSANDRA-6106, after quoting the `nanoTime` Javadoc, which says the method "can only be used to measure elapsed time"; K1), and HBase's maintainers declined it for the same reason (HBASE-8927, K2).

Because position orders rows (C4), two rows may share a time; the clamp need not add a tick, as Cassandra's does, where the timestamp is the conflict order.

**What each treatment does to the queue's age.** The specification derives `Run.oldest_queued_age` as `now - oldest_client_time(queued_rows)` and shows it to the host. It does not say whether that `now` is the client's clock; `AcceptRow` stamps `client_time: now` and calls it the client's clock. The age is a duration and the stamps are instants, so a treatment that suits one need not suit the other. With rows queued and a wall clock that steps back by S:

- **Clamp, with the age read from the same clock.** The age never goes negative, and stops growing until the wall clock passes the last value the process used. It holds its last reported value and never falls: read from the client's clock, the age's reading is one the promise covers (C3), so it counts as a value the process used, as a stamp does, and no later reading, the age's or a stamp's, is earlier. It under-reports by up to S. A forward step of S over-reports by S, under any treatment that reads the wall clock.
- **Clamp for the stamps, the raw wall clock for the age.** The age is negative until the wall clock passes the oldest queued stamp.
- **The anchored clock (T2), for both.** The age is elapsed monotonic time, unaffected by a step either way; the method's own comment says its time "can be used for computing durations". The stamps never go back, but they keep the wall clock's error at the anchor and drift from it by every correction made afterwards (Inferred from the source). OpenTelemetry anchors at each local root span; a client that anchored once per process would carry that error for the life of the process, and re-anchoring brings back the step.
- **A clamped wall clock for the stamps, and a monotonic reading kept with each queued row for the age.** The age is elapsed time and the stamps stay on the wall clock. It changes how `oldest_queued_age` is derived, and keeps one more value per queued row, in memory and never handed over.

`Run.last_store_at` reads `now` too, and so does the run id (`uuid_v7(now)`). `last_store_at` is an instant, not a duration. If these read the client's clock, the promise covers their readings as it covers a stamp, so each counts as a value the process used: under a clamp `last_store_at` repeats the last value used while the wall clock is behind and never comes out earlier than the previous `last_store_at`, and no later stamp is earlier than either reading; an anchored clock moves them with the stamps. If they read another clock, the promise does not cover them. The specification does not say which clock they read, nor which clock the age reads; this research does not settle it either ("What A leaves open").

## Recommendation

**A, for both kinds of table: the client stamps every accepted row from its own clock, and application code supplies no time.** An application's own time for an event is a column it declares. B is named as an addition A does not close off (C8).

It rests on four claims.

1. **The client's stamp is an observation time, and is the client's to set.** That it is an observation time rests on OpenTelemetry (T1), whose observed time is set by the first OpenTelemetry code that sees an event and is "only context about how the event was processed", while the source time "is fundamentally associated with the event itself". The fit is C1 and C6: the client is the first code to see a write, and the collector downstream can compare the observation time with any time the application keeps. That it is the client's alone to set has no justifying comparable: OpenTelemetry lets a bridge supply either time (T1). It is the researcher's argument (Inferred): a time the observed code sets is no longer an observation of it, and a time the application set, made the row's time, would take the row's time out of the promise that the clock never moves backwards (C3), though the client's clock itself keeps that promise under every option, and a wrong one could not be refused loudly (C2); in a keyed table, a supplied time that is not the time of the write itself would also lose the settled record of when the value was last written (C5). Claim 2 gives the comparables for the risk of a supplied time. The systemd journal (T13) informs it: its receiver stamps each entry itself and a client cannot write the reception stamps, but its stated reason covers the trusted fields, kept from "a potentially rogue client", not the reception stamps, and it defends a boundary between the daemon and the processes that send to it, which this client, a library in the writing process, does not have (C1).
2. **An application's own time is data, not the row's time.** This rests on Cassandra (K1), whose CASSANDRA-18352 says applications "can choose timestamps that may be nonsensical", and on HBase's reference guide (K2), which advises a separate timestamp attribute because the cell time drives TTL. Kafka (T12) informs it in both directions: KIP-937 records producers sending nanoseconds as milliseconds and future times as "inherently inaccurate"; KIP-32 lists among the broker time's advantages that a create time "can always be put into the message payload", but its decision was to let each topic choose, and it rejected a broker-time-only format, A's design, because "Instead of asking each application to do this, it is better to include the timestamp in the message." The fit is C2, C3 and C5, and what is at risk is the row's time, not the client's clock, which keeps its promise under every option: a wrong supplied time cannot be refused loudly (C2); a supplied time made the row's time takes the row's time out of the monotonic promise (C3); and in a keyed table a supplied time that is not the time of the write itself loses the settled record of when the value was last written (C5), and a wrong one would feed the expiry the maintainer leans towards leaving to the final store. K1 establishes the risk, not the rule: CASSANDRA-18352 itself opens "In several cases it is desirable to have client provided timestamps generated at the application-level". K2's advice justifies a separate column where expiry reads the keyed time, which is a leaning (C5). That the risk is reason enough to keep a supplied time from being the row's time in both kinds of table, rather than bound it (C) or let each table choose (D), is the researcher's inference (Inferred).
3. **A keyed value's time is when the client accepted its latest write.** No comparable justifies this. The researcher's argument (Inferred): it follows from claim 1 and from the specification's settled requirements that a keyed value records when it was last written (C5) and that the client's clock never moves backwards within a process (C3). Which write is a slot's latest is decided by position, a rule the specification marks Derived (C5); the claim uses that rule to name the write, not as a reason for it. Flink's state TTL (K3) informs it, in both directions. Flink ships processing time only. On its dev list, the developer who opened the discussion of event-time TTL wrote that event time "can not only increase but also decrease if records come out of order", rewriting the state's time to an earlier one, "which is unnatural for the notion of time", and another Flink developer called event time "just another user-defined column". But the same developer's wrap-up named event time of the record being processed as the trend for the last-access time, leaving out-of-order records to a caveat in the documentation, and a third developer offered to build it. The developer who wrote the wrap-up later recorded on the JIRA, "It looks we have an agreement there." The wrap-up was a "preliminary wrap-up", no event-time TTL has shipped since, and there is no stated rejection: the feature was agreed in outline on the list and left unimplemented.
4. **The clock is the wall clock, clamped so it never goes back.** This rests on Cassandra (K1): CASSANDRA-6178's reason for client-side, per-thread monotonic stamps, and Jonathan Ellis's warning in CASSANDRA-6106, after quoting the `nanoTime` Javadoc, that a monotonic reading is not a time since any epoch. Cassandra's driver keeps its stamps increasing by incrementing them; using the last value again instead is this client's adaptation, argued in "The clock itself", not Cassandra's practice. The fit is C3 and C6. Its cost falls on the queue's age: read from the clamped clock, the age stops growing while the wall clock is behind the last value used ("The clock itself"). Which clock that age reads is left open.

Claims 1, 2 and 4 have comparables that justify them (T1; K1 and K2; K1), each as far as its Fit verdict goes: for claim 2, K1 justifies the risk of a supplied time, and K2 keeping the application's time in its own column where expiry reads the keyed time, a leaning (C5); the step from those to A for both kinds of table is the researcher's inference (Inferred), as claim 2 says. The second half of claim 1 and all of claim 3 rest on the specification's settled requirements and the researcher's argument; the comparables cited there (T13, K3) inform them, and K3's discussion leans the other way. Kafka (T12), cited in claim 2, informs it in both directions, and its decision leans towards D.

**What leans the other way.** Log4j (T4) added a caller-supplied time for applications that need accurate event times or log a milestone late; KIP-937 calls the client time the one that "closely represents the actual event timestamp" and the broker's "an implementation detail"; HBase's users rely on supplying a time to keep the latest value by data time (HBASE-18642); a Logback user asked for control of the clock (LOGBACK-1682); and Flink's users ask for event-time TTL (FLINK-12005). KIP-32 itself chose a per-topic time over asking each application to carry one in its payload, and rejected A's design for Kafka (claim 2, T12). On Flink's dev list one developer argued from a GDPR perspective that only event time makes sense for the last-access time, and the discussion's own wrap-up named event time of the record being processed for it (K3). Under A each of these can keep its own time as a column the table declares, but none gets all it asked for: the column is not the row's time, its name and meaning are each table's own, and a collector has to be told which column holds the event time (A's costs). B answers that last part with one field every table has. Neither A nor B makes the application's time the row's time; only C does. Keeping the latest keyed value by the application's time A does not offer at all.

**What would turn the choice.** If the maintainer wants a replayed or backfilled row's original time carried in a field every table has, which a collector finds without being told, B is the answer: it adds the application's time beside the client's and keeps the client's promise. If the maintainer wants that time to be the row's only time, that is C, with C's costs, among them, in a keyed table, the settled record of when the value was last written (C5). If the maintainer wants a keyed table to keep the latest value by the application's time, that changes how slots are decided (C4, and the Derived rule in C5) and is a separate question from who stamps; it would also need the client's time kept beside the application's, or the value would no longer record when it was last written (C5, settled).

### Name, precision and epoch

These rest more on the researcher's argument than the choice above, because few comparables state a reason for them.

- **Name: `observed_time`.** OpenTelemetry's wire name for the same meaning is `observed_time_unix_nano`, and its stated meaning, the time the first observing code saw the event, is the client's (T1). It reads for both kinds: for a keyed value, when the client observed its latest write. It answers the maintainer's wish, quoted in the ticket, for "something more standard" than `last_seen`. ECS's experience informs against a name that reads as the event's own time: `event.created` was found ambiguous (T7). `observed_at`, the elicitation's lead, is not OpenTelemetry's name. Keeping `client_time` is the alternative if the maintainer prefers a name that says who stamps.
- **Epoch and representation: the Unix epoch, UTC, as an integer.** Every comparable that states an epoch uses the Unix epoch.
- **Precision: microseconds.** In the researcher's view, not a stated reason: rows are ordered by position (C4), so precision serves people and downstream analysis, not order; Cassandra's driver documents that clocks commonly give milliseconds and that a finer part is a counter (K1); in CASSANDRA-6106 Sylvain Lebresne wrote "As far as conflict resolution goes, microsecond resolution is imo rather useless", given NTP's accuracy and network latency, while allowing it "if it's easy" (K1), a point about order across machines rather than about what people and analysis need; microseconds meet the finest requirement found for a stamp the recording code takes (MiFID II's 100 µs, cited by a commenter on LOG4J2-1883, T4) and match the journal (T13), Kubernetes' `MicroTime` (K7) and Cassandra (K1). HBASE-21476's nanoseconds, for "applications that timestamp updates at the source with nanoseconds" (K2), are a source time the application supplies, which under A is a column; the specification does not state a `timestamp` column's precision. Nanoseconds, OpenTelemetry's unit, are the alternative if handing over to OpenTelemetry without conversion matters; microseconds convert to nanoseconds without loss. No comparable states why it chose nanoseconds.

**What A leaves open.**

- Whether a clamp is counted or logged. Cassandra's driver logs a warning when its stamps drift (K1); the specification counts and logs only failures of the kinds it names.
- The hand-over's representation of the time, which is open question 15.
- Which clock `Run.oldest_queued_age` reads. Read from the clamped client's clock, it never goes negative or falls, its reading being one the process used (C3), and stops growing while the wall clock is behind; read from the raw wall clock, it can go negative; read from a monotonic clock, it is elapsed time, but needs either the anchored clock for the stamps, with its drift, or a monotonic reading kept with each queued row ("The clock itself"). The settled promise does not choose between them, and this research does not.
- Whether a reading taken for a diagnostic, not a stamp, counts as one the process used under the clamp. It decides whether `oldest_queued_age` can fall and `Run.last_store_at` can come out earlier than its previous value, and it applies to the run id's reading too ("The clock itself"). The settled promise does not say, and this research does not.

## Proposed wording

Text for the maintainer to accept or change. It is written only here: the specification is not edited, and open question 11 stays open. It was not run through the pinned checker, because `just check-specs` checks only the tracked module.

**`Row`** (the field, renamed):

```text
    observed_time: Timestamp        -- the client's clock when the row was accepted; for a keyed value, when its latest write was accepted
```

**`AcceptRow`** (the comment's last sentence, and the field in `Row.created`):

```text
-- ... The row is offered to the
-- queue at once, given the next position and stamped from the client's
-- clock (Derived: both happen at acceptance, so a row lost afterwards
-- leaves a visible gap in the positions).
            run: run, counters: counters, position: run.last_position + 1, observed_time: now,
```

**The vocabulary comment and `Run.oldest_queued_age`**: `oldest_client_time` becomes `oldest_observed_time`. The derivation keeps reading `now`. If that `now` is the client's clock, which the specification does not say, the age under the clamp below stops growing while the wall clock is behind the last value the process used, and never falls, because its reading is then one the process used. Which clock the age reads is left open for the maintainer ("What A leaves open"), and no wording is proposed for it.

**The hand-over surface**: `row.client_time` becomes `row.observed_time`.

**`ClockNeverMovesBackwards`**:

```text
    @guarantee ClockNeverMovesBackwards
        -- The client's clock is the wall clock in UTC, in microseconds
        -- since the Unix epoch. Within one process it never moves
        -- backwards, whatever a reading is taken for: a reading earlier
        -- than the last one the process used is not used, and the last
        -- one is used again. There is no ordering promise across
        -- processes.
```

Under this wording every reading of the client's clock counts as one the process used, a stamp or not, because the settled promise covers the clock and not only its stamps (C3). So if `oldest_queued_age`, `Run.last_store_at` or the run id reads the client's clock, none of them goes back, the age holds its value rather than falling, and no later stamp is earlier than such a reading ("The clock itself"). Which clock those readings take the specification does not say; it is left open for the maintainer ("What A leaves open"), and no wording is proposed for it.

**The writing surface's `@guidance`** (its last sentence):

```text
        -- Application code does not supply a row's time. A time of the
        -- application's own, such as when an event happened, is a column
        -- the table declares.
```

**Open question 11** is removed in the same change, and its number is not reused.

**Other places adoption would touch**, not drafted here:

- The handbook page on working with the specifications gives the number of open questions.
- The glossary would gain an entry for observed time: the time the client accepted a row, from its own clock; for a keyed value, when its latest write was accepted.
- The worked hand-over examples in `CONTEXT.md` use `client_time`. A ticket does not edit `CONTEXT.md`; the maintainer would.
- If the maintainer keeps `client_time`, only the guarantee, the guidance and the open question change.

## What the findings bear on in the specification

This section reports, and decides nothing.

- **Open question 11**: who stamps a row's time, whether application code may supply one, and the field's name and precision. It stays open.
- **The interim rule in `AcceptRow`** that stamps every accepted row with `client_time: now`, marked "Derived" because both the position and the stamp are taken at acceptance.
- **The `ClockNeverMovesBackwards` guarantee** on the writing surface: within one process the client's clock never moves backwards. Any application-supplied time would sit beside it, and the findings on out-of-order and future times (T9, T11, T12, K1, K4) bear on what such a time would do to a row's time if it replaced the client's.
- **The `client_time` field on `Row`**, which for a keyed value records when it was last written, and its place in the hand-over.
- **The keyed state slots.** The latest value per key is decided by position today. Comparables that order a key's values by a supplied time (K1, K2, and K4's versioned stores) bear on whether a supplied time could change which value is latest.
- **The `@guidance` on the writing surface**, which says whether application code may supply a row's time is open question 11.
- **The glossary**, which has no entry for a row's time.
