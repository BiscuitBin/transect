# Research: who stamps a row's time

- **Ticket:** `issues/01-research-who-stamps-a-rows-time.md`, open question 11 of `docs/specs/transect-client.allium`: "Is a row's time stamped by the client only, or may application code supply it, and what are its name and precision? Until decided, the client stamps every accepted row."
- **Sources read:** 2026-11-24 (UTC). Every link below was read that day.
- **Web research:** authorised by the maintainer in the session that picked this ticket up, for the researcher and for the reviewers.
- **Status:** findings only. Fit, the options, a recommendation and proposed wording come after the first adversarial review. Nothing here decides question 11.

## How the sources were checked

- Each comparable was read from its official documentation, a specification, or source code at a named tag or commit. GitHub links are pinned to a tag or a commit, except issue and pull request threads, which have no version. Apache JIRA issues are linked by their browse URL, Confluence pages (Kafka KIPs) by page id, and Apache mailing-list messages by their thread URL. The AWS documentation is unversioned; its pages were read as the Markdown rendition the site serves.
- Every blockquote sits under the `Source:` line it was copied from. Each was checked as a substring of raw source text the researcher fetched again: GitHub files from `raw.githubusercontent.com`, GitHub threads through the GitHub API, JIRA issues through the JIRA REST API, Confluence pages through the Confluence REST API, and mailing-list messages through the Apache mail archive's API. 263 quotations were checked; 258 match exactly, and 5 match only once whitespace is collapsed (two issue bodies with different line endings, three code comments whose indentation differs).
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

Two families, as the maintainer asked: application logging frameworks and collection systems for time series tables (T1 to T12), and comparable keyed-state systems for keyed state tables (K1 to K9). Kafka appears in both: T12 covers who stamps a record, K4 what a compacted topic and a KTable do with that time.

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
| Fluentd / Fluent Bit | Input plugin, a parser (`time_key`), or the sending client | Yes: forward protocol and logger libraries carry the client's time | `EventTime` (sec + ns) or integer seconds | Not checked | `Time.now` (Fluentd); `timespec_get(TIME_UTC)` (Fluent Bit) |
| Grafana Loki | Client (push API) | Yes; the push format has a timestamp slot in every entry (Inferred: required) | ns since Unix epoch, as a string in JSON | Rejected if older than `reject_old_samples_max_age` (1w) or beyond `creation_grace_period` (10m); out of order accepted by default since 2.4, within a window | Bounds are relative to the current time (Inferred: the server's clock) |
| InfluxDB | Client, or server when absent | Optional per point | Unix timestamp, default ns, `precision` parameter | Points outside retention rejected; same series and timestamp merges fields | Server host clock (UTC) when absent |
| Prometheus | Server at scrape time | Exposition format allows it; docs say not to; `client_golang` exposes it with caveats | `int64` ms since epoch | Out of order rejected unless `out_of_order_time_window` > 0 | Server |
| Apache Kafka | Producer (`CreateTime`) or broker (`LogAppendTime`), per topic | Yes: `ProducerRecord` timestamp | `int64` ms since epoch | Bounded by `message.timestamp.before.max.ms` / `after.max.ms`; whole batch rejected | `System.currentTimeMillis()` in the producer |

### Summary: keyed state

| System | Who stamps by default | May application code supply it? | Field, precision, epoch | Future / too old / out of order | Stated why found? |
|---|---|---|---|---|---|
| Cassandra | Driver (client side) since Java driver 3.0; coordinator if no client time | Yes: `USING TIMESTAMP`, per-statement, pluggable generator | cell `WRITETIME`, int64 microseconds since Unix epoch (by convention) | Accepted; last write wins; optional guardrail since 5.0 rejects outside a window | Yes, extensive (CASSANDRA-6178, -6106, -4947, -18352) |
| HBase | RegionServer | Yes (`Put` with explicit timestamp); docs advise against | cell timestamp, int64 milliseconds since Unix epoch (server `currentTimeMillis`) | Accepted; highest timestamp is the "latest"; future deletes mask later puts | Yes (HBASE-10247, -14070, -18642, -9905) |
| Flink state TTL | Flink runtime (`TtlTimeProvider`) | No (processing time only; the provider is internal) | `lastAccessTimestamp`, long ms from `System.currentTimeMillis()` | n/a (no supplied time) | Partly: event-time TTL debated (FLINK-12005, dev thread), never landed |
| Kafka (compacted topic / KTable) | Producer library (`CreateTime`) or broker (`LogAppendTime`), per topic | Yes (`ProducerRecord` timestamp) under `CreateTime` | record timestamp, int64 ms since Unix epoch | Broker rejects outside `before/after.max.ms` (future default 1 h since 4.0); compaction keeps highest offset, not highest timestamp | Yes (KIP-32, KIP-937, KIP-258, KIP-280, KIP-914) |
| Redis | Server LRU clock (access, not write) | No | 24-bit LRU field, 1 s resolution, wraps | n/a | No stated rationale found |
| etcd | Server (Raft-ordered revision counter, not time) | No | `create_revision`, `mod_revision`, int64 logical | n/a | Revisions documented as a logical clock; no stated reason for omitting wall time found |
| Kubernetes | API server (`creationTimestamp`, `managedFields[].time`); kubelet for `lastHeartbeatTime`, Lease `renewTime` | `creationTimestamp`: no. Heartbeat/renew: the writing client stamps | RFC 3339 seconds (`Time`) or microseconds (`MicroTime`), UTC | Node controller ignores the writer's clock for liveness; uses its own local observation time | Yes (node lifecycle controller comment; KEP-589 for the Lease move) |
| DynamoDB | No item write time at all; stream records stamped by the service | Item attributes: application only. Stream time: no | `ApproximateCreationDateTime`: seconds (Streams), ms or µs (Kinesis destination) | Global tables: last writer wins on an internal timestamp; TTL ignores > 5 years past | No stated rationale found |
| OpenTelemetry metrics (Gauge) | SDK at measurement / collection | No (requested and declined) | `time_unix_nano`, fixed64 ns since Unix epoch | n/a | Yes (spec issue #4343) |

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
time, or for Logback's move to `Instant` in 1.3. Looked at: `qos-ch/slf4j` and
`qos-ch/logback` issues with `timestamp` in the title, `qos-ch/slf4j` issues mentioning
`setTimeStamp`, `qos-ch/logback` commits mentioning `instant`, and
https://logback.qos.ch/news.html (no match for `Instant`, `getInstant` or
`nanosecond`). The old QOS.ch JIRA was not reachable as a
source (Unverified whether it holds a discussion).

**Constraints.** SLF4J is a facade over several backends, and each backend stamps its own
events (Inferred from the reload4j commit and Logback's `Logger.java` above).

**Costs and dissent.** Fluent-API events once reached the reload4j binding with no time
at all, until the 2022 commit above (SLF4J-546).

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

- Parsers take the time from a record field (`time_key`), falling back to the current time
  when the field is absent (Fluentd docs at `cb3c4ca`).

  Source: https://github.com/fluent/fluentd-docs-gitbook/blob/cb3c4ca464a9d0e47d820bf838803ba2a8827f21/configuration/parse-section.md

  > * **`time_key`** \(string\) \(optional\): Specify time field for event time. If
  >
  >   the event doesn't have this field, current time is used.

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

- Future, past or out-of-order times: no validation found in the pages read (Unverified).

**Stated why** (precision only). Fluentd had second granularity until 0.14.0 (2016-05-25,
pull request 653). The discussion in issue 461 weighed float seconds against a split
representation; float was rejected for nanoseconds.

Source: https://github.com/fluent/fluentd/issues/461#issuecomment-61567465

> Given the current seconds since epoch, the latter can only represent microseconds, and that's generally what we have to work with.  So, to support nanoseconds we'd need another representation like separate (integer) seconds and nanoseconds.

Source: https://github.com/fluent/fluentd/pull/653

> This patch introduces new fluentd timestamp, `Fluent::EventTime`, which can have nanosecond granularity and is compatible with current `Integer` timestamp.

For who stamps: No stated rationale found. Looked at the forward protocol specification,
the parse-section docs, Fluent Bit's key concepts, and `fluent/fluent-bit` issues with
`nanosecond` in the title (titles only).

**Constraints.** Events cross several hops (client, forwarder, aggregator), and plugins written for integer seconds had to keep working (pull request 653's backward-compatibility notes, not quoted further).

**Costs and dissent.** Pull request 653 kept integer time on the wire by default
(`time_as_integer`) for backward compatibility, so nanoseconds were lost unless every hop
was upgraded (same pull request body; not quoted further).

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

**Stated why.** Only the documentation note quoted above (include the time if you want
observation time, not receipt time). No further stated rationale found; looked at the
line protocol, duplicate-points, troubleshooting and retention pages of `influxdata/docs-v2`
at `df4a7d5`.

**Constraints.** None stated in the pages read.

**Costs and dissent.** None found in the pages read.

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

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=13800513&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-13800513
> Though on the longer run, I'm starting to be convinced that we should slowly move back to client side timestamps by default (CASSANDRA-6178) so it's unclear to me how much effort is worth putting into this (given that, at the end of the day, this won't ensure timestamp uniqueness anyway and you'd still have to be aware that on timestamp tie, the resolution is based on the value).

Source: https://issues.apache.org/jira/browse/CASSANDRA-6106?focusedCommentId=14307723&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14307723
> It was decided that v3 protocol implementors should ensure their timestamps are high precision, since this is the default source of timestamps going forwards.

Why not use a monotonic clock for the stamp (Jonathan Ellis, comment 13779492, quoting the
`nanoTime` Javadoc):

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

Outcome as recorded on the JIRA (Andrey Zagrebin, comment 17123421, 2020):

Source: https://issues.apache.org/jira/browse/FLINK-12005?focusedCommentId=17123421&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-17123421
> I have attached the full mailing list discussion. It looks we have an agreement there.

No event-time TTL has shipped since. There is no stated rejection: the feature was
proposed, discussed and left unimplemented. Yu Li (comment 17121272) had said the
discussion had no explicit conclusion; Zagrebin's next comment, above, disagreed.

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
- The storage cost is documented: 8 bytes per value or entry in RocksDB.

### K4. Apache Kafka: compacted topics and Kafka Streams KTables

**Analogy.**

- A compacted topic is a keyed changelog: the log keeps at least the last value per
  key.
- A KTable materialises it as keyed state.
- Each record carries one timestamp, and the KTable stores the latest record's
  timestamp with its value (KIP-258).
- **Caveat.** The stamp is a record (event) time, not a last-written-to-the-table
  time.

**What it does.**

- **Who stamps.** Per topic, `message.timestamp.type`:
  - `CreateTime` (default): the producer library stamps `System.currentTimeMillis()`
    unless the application passes a timestamp.
  - `LogAppendTime`: the broker overwrites with its local time.
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

**Constraints.**

- Retention and segment rolling are driven by record timestamps, so bad future stamps
  have operational effects (KIP-32, KIP-937).
- Producers are independent processes; ordering per key is by broker offset (KIP-280).

**Costs and dissent.**

- The `Long.MAX_VALUE` default, in place from KIP-32 until 4.0.0, let nanosecond-unit
  mistakes through (KIP-937). The default was tightened only for future stamps, at a major version.
- Compaction by offset keeps the "wrong" value when producers race (KIP-280). The fix
  was voted but never landed.

### K5. Redis

**Analogy.** Loose. Keyed store with no per-key write time. The only per-key time is an
LRU access clock used for eviction, and it is set on access as well as write. Included
because it is the case with no last-written field at all.

**What it does.**

- **Who stamps.** The server, into the 24-bit `lru` field of the object.
- **Resolution and range.** 1 second, wrapping at 2^24 s.
- **Under LFU.** The field holds LFU data instead.
- **Reading it.** `OBJECT IDLETIME` returns the time since last access, not since last
  write.
- **May the application supply it.** No.

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

**Stated why.**

**No stated rationale found** for omitting a per-key write time. Where I looked:

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

The access stamp can mislead about writes. A shared-integer optimisation makes many keys
share one idle time (antirez, redis/redis#4403):

Source: https://github.com/redis/redis/issues/4403#issuecomment-340387689
> Every integer object has *a single* shared idle time. So every string set to "5" will be like sharing the same idle time. So if you set a string to a new integer, the result is that you see the idle time that the number you set happen to have.

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

KEP-589 records that clients reading `LastHeartbeatTime` frequency broke when the
NodeStatus period lengthened (its Risks and Mitigations list). The API conventions say
historical condition info is best-effort:

Source: https://github.com/kubernetes/community/blob/175f04bc631df9d949b1d4b9265f7b631041ac32/contributors/devel/sig-architecture/api-conventions.md
> Historical information status (e.g., last transition time, failure counts) is
> only provided with reasonable effort, and is not guaranteed to not be lost.

### K8. Amazon DynamoDB

**Analogy.**

- Keyed store (item per primary key).
- It records **no** last-modified time on items. Nothing in the developer guide pages
  read describes one; this absence is inferred from those pages, not stated by AWS.
- Applications that want one write an ordinary attribute themselves.
- The service stamps change-stream records instead.

**What it does.**

- **Item attributes.** Application-set only. TTL is an application-written Number
  attribute, epoch seconds.
- **DynamoDB Streams.** `StreamRecord.ApproximateCreationDateTime` is stamped by the
  service, epoch seconds, rounded down.
- **Kinesis Data Streams destination.** The same field in milliseconds by default, or
  microseconds if configured (`ApproximateCreationDateTimePrecision`). It is documented
  as the way to order and de-duplicate records that may arrive out of order.
- **Global tables.** Concurrent writes in different Regions are resolved by "the latest
  internal timestamp" (last writer wins). No API to supply that timestamp appears in the pages read (Inferred).
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

Source: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/time-to-live-ttl-before-you-start.html
> The computed expiration time must be in epoch format, in seconds. To be considered for expiry and deletion, the TTL can't be more than five years in the past. If you use any other format, the TTL processes ignore the item.

**Stated why.**

**No stated rationale found.** Where I looked:

- the StreamRecord, EnableKinesisStreamingConfiguration, Kinesis Data Streams, TTL
  (three pages), global tables how-it-works and core components pages;
- a web search for the launch announcement of microsecond precision.

None was found, so the launch date is **Unverified**. A search summary claimed an AWS CDK
page gives microseconds as the default. That contradicts `kds.md`, which says
milliseconds, and was not verified: **Unverified**, not relied on.

**Constraints.**

- Managed, multi-tenant service; the application never sees server clocks except
  through stream records.
- Multi-Region replication needs a conflict rule; the service uses its own internal
  timestamp for it (global tables page).
- Change streams can deliver out of order and more than once (Kinesis destination), so
  the service-stamped time is offered as the ordering and de-duplication key.

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

## Comparables that chose otherwise

Most comparables let application code supply a time and stamp only when it does not: OpenTelemetry logs (T1), Log4j 2 through `TimestampMessage` (T4), Fluentd's clients (T8), Loki (T9), InfluxDB (T10), Kafka under `CreateTime` (T12, K4), Cassandra (K1) and HBase (K2). These chose otherwise, each with a stated why:

- **Rust `tracing` (T6): the event carries no time at all, and each consumer stamps it.** A timestamp in the core would cost every layer that does not want one, and would force `std` time on `no_std` users.
- **Prometheus (T11): the server stamps at scrape, and client timestamps are discouraged.** Different times within one scrape break features that assume one, and most users who asked for client timestamps did not need them.
- **Kafka topics set to `LogAppendTime` (T12, K4): the broker overwrites the producer's time.** The broker is more robust, its time increases monotonically, and retention behaves deterministically.
- **OpenTelemetry metrics (K9): a gauge's measurement takes no caller-supplied time.** A request for one was declined, because each SDK would have to bucket measurements by time and decide when an old bucket is final.
- **Kubernetes' node lifecycle controller (K7): the reader does not trust the writer's stamp for liveness.** It records its own local time when it sees a newer heartbeat, "to avoid the problem with time skew across the cluster".

Within those that accept a supplied time, two moved the default stamper in opposite directions:

- **Cassandra (K1) moved it from the server to the client library**, in Java driver 3.0, so that one client thread's writes stay in order and a retry keeps its first timestamp. Server stamping stays available, because of resistance to removing it.
- **HBase (K2) proposed moving it the other way**: a server-stamped hybrid logical clock, with client timestamps deprecated. Users who supply event-time timestamps objected, and the deprecation has not proceeded.

Python `logging` (T3) and Logback with SLF4J (T5) also give a logging call no time parameter, but no stated rationale was found for either. Flink's state TTL (K3) accepts no supplied time; event-time TTL was discussed and never built, with no stated rejection. Redis (K5), etcd (K6) and DynamoDB (K8) record no wall-clock write time on a key at all, and no stated rationale was found for any of the three.

## Candidates not examined, or dropped

- **The OpenTelemetry Collector's `filelog` receiver.** Covered through the issue that led to `ObservedTimestamp` (T1), which drew on it; not read separately.
- **Telegraf, StatsD and Graphite.** Not reached.
- **The systemd journal.** OpenTelemetry added a journal mapping in 2026 (pull request 4995, title only); not read.
- **Java's `java.util.logging`.** Not read, so not reported.
- **Prometheus's design document for out-of-order ingestion.** Hosted on Google Docs and not fetchable as raw text (Unverified).
- **Kafka KIP-1030**, which made the one-hour future bound the default. Known only from the upgrade note quoted in T12 (Unverified beyond that note).
- **Kafka KIP-33**, the time index. It concerns retention mechanics, not who stamps; quoted once in T12 for that reason.
- **CASSANDRA-5153.** Fetched and dropped: it concerns SSTable timestamp metadata, not who stamps.
- **etcd issue 6518.** A usage question about the revision fields, with no design rationale.
- **OpenTelemetry's cumulative `StartTimeUnixNano`.** A series-start time, not a last-write time.

## What the findings bear on in the specification

This section reports, and decides nothing.

- **Open question 11**: who stamps a row's time, whether application code may supply one, and the field's name and precision. It stays open.
- **The interim rule in `AcceptRow`** that stamps every accepted row with `client_time: now`, marked "Derived" because both the position and the stamp are taken at acceptance.
- **The `ClockNeverMovesBackwards` guarantee** on the writing surface: within one process the client's clock never moves backwards. Any application-supplied time would sit beside it, and the findings on out-of-order and future times (T9, T11, T12, K1, K4) bear on what such a time could do to it.
- **The `client_time` field on `Row`**, which for a keyed value records when it was last written, and its place in the hand-over.
- **The keyed state slots.** The latest value per key is decided by position today. Comparables that order a key's values by a supplied time (K1, K2, and K4's versioned stores) bear on whether a supplied time could change which value is latest.
- **The `@guidance` on the writing surface**, which says whether application code may supply a row's time is open question 11.
- **The glossary**, which has no entry for a row's time.
