# Research: a library logging its own failures

- **Ticket:** `issues/14-research-the-why-a-library-logging-its-own-failures.md`. It covers the guarantees `StandardFacade` and `OnsetThenTotal` on the surface `HostLog` of `docs/specs/transect-client.allium`, the rules `OpenFailureEpisode`, `LogOnset`, `CountIntoEpisode`, `ReportEpisodesAtEnd` and `LogTotal`, and open question 22.
- **Sources read:** every source on 2026-11-25 (UTC), which was 2026-11-24 in the researcher's local time.
- **Web research:** authorised by the maintainer on 2026-11-24 for this ticket, for the agent working it, for its survey and triage subagents, and for its reviewers.
- **State of this file:** complete. The findings, up to "Candidates not examined, or dropped", passed the first adversarial review in two rounds. Fit, the answer to "is the rule common?", the costs, the two verdicts, the proposed wording and what the findings bear on were written after it, and passed the second review in two rounds. The second round's fixes were not reviewed again, because two rounds is the limit.

## How the sources were checked

Three survey subagents found the candidates and saved raw text. The author then fetched every cited source again, independently:

- source and documentation files at a pinned tag or commit, through `raw.githubusercontent.com`;
- issue, pull request, review and commit text through the GitHub REST API, and a quotation cited to one comment from that comment alone;
- web pages as HTML, with the tags stripped.

Line endings were normalised from CRLF to LF. Each quotation below was then checked by machine as a substring of that text. The result of the last check is under "Quotation check" at the end of this file.

A quotation from source code keeps the comment markers and indentation it has in the file.

Where a "no" rests on searching code, such as "installs no handler" or "logs nothing", the search was run by the author on a clone at the named commit, and the command is given.

Each "why" says who stated it, in the terms of the author association GitHub records on the comment, read on the day: a **member** of the project's organisation, a **collaborator** on the repository, a **contributor** (someone with a merged commit), or a **user** (none of these). GitHub's terms say nothing finer: a member is not necessarily a maintainer of that repository, and an organisation's members may show as contributors when their membership is private. A user's request, or a pull request author's description, is labelled as what it is.

## What was fixed before reading

**The count.** Twelve libraries were fixed as the count before any source was read. Each is read at its latest release tag, resolved through the GitHub API on the day of reading:

| # | Library | Tag read | In-process library? |
| --- | --- | --- | --- |
| L1 | ddtrace (`DataDog/dd-trace-py`) | `v4.17.2` | yes |
| L2 | OpenTelemetry Java SDK | `v1.68.0` | yes |
| L3 | OpenTelemetry Python SDK | `v1.45.2` | yes |
| L4 | Linux kernel, `printk` rate limiting | `v7.3` | no: an operating system kernel |
| L5 | OpenTelemetry Rust SDK (`opentelemetry_sdk`) | `opentelemetry_sdk-0.33.1`, the same commit as `opentelemetry-0.33.1` (`372ebbc`) | yes |
| L6 | OpenTelemetry Go SDK | `v1.47.0`; `sdk/v1.47.0` and `sdk/log/v1.47.0` are the same commit (`66cfc95`) | yes |
| L7 | OpenTelemetry .NET SDK | `core-1.21.0` | yes |
| L8 | OpenTelemetry JS SDK | `api/v1.10.0` and `v3.1.1` | yes |
| L9 | sentry-python | `3.0.0` | yes |
| L10 | urllib3 | `2.8.0` | yes |
| L11 | OpenTelemetry Collector, its own logs, with zap | `v0.166.0`, zap `v1.28.0` | no: a separate process that is its own host |
| L12 | Vector, its internal-log rate limiting | `v0.62.0` | no: a separate process that is its own host |

So nine of the twelve are in-process libraries, as this client is, and three are not. Every count below is given over both.

**Not counted, because they are guidance and not libraries:** the Python logging documentation, the documentation of the Rust `log` and `tracing` crates, and the OpenTelemetry specification. They are recorded under "Guidance" below.

**How a library is classified.** By what it writes to the host's logs when it loses data it was given, which for most of them is a full queue. Other kinds of failure, such as a failed export, are recorded beside it, because several libraries treat the two differently. The classes are:

- **onset then total:** the first occurrence logged at once, nothing more while it continues, and one total at the end;
- **rate limit:** at most N records per window, with or without a count of what was suppressed;
- **duplicate filter:** a repeat of the same record suppressed while it repeats;
- **sampling:** the first N per window, then one in M;
- **count per cycle:** a count written once per export cycle or timer tick;
- **total at shutdown only;**
- **every occurrence;**
- **none:** nothing in the host's log, at the default level.

Added during the work, outside the count, and never counted: dd-trace-go, log4j2, Logback, Elastic APM Python, Honeycomb libhoney-go, librdkafka, Fluent Bit and CPython's `QueueHandler`. They are under "Additions outside the count".

## The claims, checked again

The elicitation's survey kept no links. Each claim below was checked against the primary sources cited in the sections that follow.

| Claim from `CONTEXT.md` | Status | Where shown |
| --- | --- | --- |
| Common practice is the standard logging facade | **Corrected in part.** The four Python libraries use the standard `logging` module and OTel Java uses `java.util.logging`. Rust has no standard facade, only two de facto ones, and OTel Rust uses `tracing`, not `log`. OTel Go uses its own `ErrorHandler` and a `logr` logger, OTel .NET uses `EventSource`, and OTel JS its own `diag` API. | L1 to L10, G1, G2 |
| A library-named logger | **Confirmed** where the facade has names: every Python library, OTel Java, and OTel Rust (its `tracing` target). OTel Go and OTel JS have no logger name. | L1 to L10 |
| No handlers installed | **Corrected.** It is the Python guidance, and urllib3, OTel Python, OTel Java and OTel Rust follow it. ddtrace and sentry-python each add a `StreamHandler` at import, and OTel Go's defaults write to standard error. | L1, L6, L9, G1 |
| WARNING for dropped data | **Corrected in part.** WARNING for a full queue in ddtrace, OTel Java (spans), OTel Python, OTel Rust, OTel .NET and urllib3. But OTel Go logs span drops only at Debug and log-record drops through a `Warn` helper that `logr` receives as `V(1)` Info, which its default logger hides. OTel JS logs the onset at Debug. sentry-python logs nothing by default. The Collector logs at Error. Vector logs a drop it did not intend at Error, and a full buffer's drops, which happen only with `drop_newest`, at debug. ddtrace logs a failed send at ERROR. | L1 to L12 |
| A stable name per kind of event | **Corrected.** Only OTel Rust (named events) and OTel .NET (numeric event IDs) have one. Vector's internal event types do not put their name on the record. The others log a message template. OTel Rust's own maintainer calls stable names an aim it has "not there yet" reached. | L5, L7, L12 |
| The first occurrence logged at once, then throttled | **Corrected in part.** True of ddtrace (unless another of its writer's warnings, logged through the same helper, already passed in its 60 s window), OTel Python (unless another processor's identical warning came last in the same 20 s bucket), the kernel, OTel Rust, the Collector, and Vector for a drop it did not intend. OTel Rust's record is collected only once the application installs a `tracing` subscriber, or enables `tracing`'s `log` feature and sets a `log` logger. urllib3 logs the first occurrence at once but never throttles, so it bears out only the first half, and its `NullHandler` keeps the record silent until the application configures logging. Not true of OTel Java (spans: at the next export), OTel Go, OTel .NET (only at shutdown), sentry-python (nothing by default), OTel JS, whose onset is at Debug, or Vector's full buffer, reported at debug. | L1 to L12 |
| Records are structured | **Confirmed in part.** Key-value fields in OTel Rust, OTel Go (key-value arguments to `logr`), the Collector (zap fields), Vector and OTel .NET (event payloads). The Python libraries and OTel Java format a text message. | L1 to L12 |
| ddtrace: one record per call site per 60 s, with "[N skipped]" | **Confirmed, with two corrections.** The key is the logger name, level, file and line. The count is a suffix on the next record that passes, never a record of its own, so if no record follows it is never written. | L1 |
| OTel Java: 5 per minute, then 1 | **Confirmed for `ThrottlingLogger`**, read as a token bucket: a burst of 5 refilled at 5 a minute, then, for good, a bucket of 1 refilled at 1 a minute. But that class throttles the exporters and the metrics SDK, not the batch processors. The span processor logs a count per export cycle, and the log-record processor logs no drop at all. Until `v1.48.0` a bug let 5 a minute through when throttled. | L2 |
| OTel Python: identical repeats suppressed within 20 s | **Corrected.** The filter remembers only the last record, and the 20 s is a fixed wall-clock bucket. The queue-full warning was logged once per processor until `v1.33.0`, was absent from `v1.34.0` to `v1.39.0`, and is logged on every drop since `v1.40.0`, subject only to that filter. | L3 |
| Linux kernel: 10 per 5 s, then "N callbacks suppressed" | **Confirmed.** Per call site. The count is printed on the next call after the window, or never if none comes. | L4 |
| OTel Rust: the onset once, and a total at shutdown | **Confirmed for queue-full drops only**, in the default batch span and batch log processors. The experimental async-runtime processors apply it to any failed send. A failed export is logged on every occurrence. A `force_flush` timeout is returned with no log, and records lost when shutdown times out are not counted. The total is written when the processor's shutdown begins, before the worker stops, and a provider's `Drop` also starts that shutdown. | L5 |
| Separate periodic summary logs are uncommon | **Confirmed, with a qualification** (see "Is the rule common?"): two of the nine in-process libraries write a count on a cycle into the host's log, and two write a total at the end; neither is common. A count separate from the failure record is written by OTel Java's span processor at each non-empty export, which runs every 5 s or at 512 spans by default, and on flush and shutdown, at WARNING. OTel Go's log processor writes one each time its worker wakes (1 s by default), on a full batch, on flush and at shutdown, through a `Warn` helper its default logger hides. Vector writes one every 2 s at debug, only with `drop_newest`. sentry-python sends its count to its own service on later sends, not to the host's log. Outside the count, dd-trace-go writes an aggregate 60 s after the first error. | L2, L6, L9, L12, A1 |

## The specification's text at the time of reading

The guarantee `StandardFacade` now reads "lost data and dropped tenants are logged at WARNING". The ticket quotes the older wording, "lost data is logged at WARNING". Dropped tenants were added when the maintainer adopted A2 in ticket 02. Nothing here edits either.

The rules apply onset-then-total to every `FailureKind`: `queue_full`, `oversize`, `invalid`, `store_failed`, `shutdown` and `tenant_dropped`. The total is keyed on one kind for one table within one run, and is written when establish ends.

Neither the specification nor `docs/` states the basis of either guarantee. A search of `docs/`, `docs/decisions/` and the specification's comments for "survey", "common practice", "OTel Rust" and "facade" found only the guarantee text itself. The basis is written only in `CONTEXT.md`, under "Library self-logging", and in this ticket.

---

## Guidance

Not counted as libraries. Each is what a library is told to do, and why.

### G1. Python: the logging HOWTO and the `logging` module documentation

**What it says.** Read at CPython `v3.15.2`. A library adds no handler except `NullHandler`, logs under a logger named for itself, and never to the root logger.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst

> When developing a library which uses logging, you should take care to
> document how the library uses logging - for example, the names of loggers
> used.

> If the using application does not use logging, and library code makes logging
> calls, then (as described in the previous section) events of severity
> ``WARNING`` and greater will be printed to ``sys.stderr``. This is regarded as
> the best default behaviour.

**Stated why.**

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst

> This is
>    because the configuration of handlers is the prerogative of the application
>    developer who uses your library. The application developer knows their
>    target audience and what handlers are most appropriate for their
>    application: if you add handlers 'under the hood', you might well interfere
>    with their ability to carry out unit tests and deliver logs which suit their
>    requirements.

> Logging to the root logger will make it difficult or impossible for
>    the application developer to configure the logging verbosity or handlers of
>    your library as they wish.

The module documentation states why a standard facade exists at all:

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.rst

> The key benefit of having the logging API provided by a standard library module
> is that all Python modules can participate in logging, so your application log
> can include your own messages integrated with messages from third-party
> modules.

**On the level.** The HOWTO's task table offers two rows that could fit a library that drops data without raising, and does not say which applies:

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst

> | Issue a warning regarding a         | :func:`warnings.warn` in library     |

> |                                     | A logger's :meth:`~Logger.warning`   |
> |                                     | method if there is nothing the client|
> |                                     | application can do about the         |
> |                                     | situation, but the event should still|
> |                                     | be noted                             |

> | Report suppression of an error      | A logger's :meth:`~Logger.error`,    |
> | without raising an exception (e.g.  | :meth:`~Logger.exception` or         |
> | error handler in a long-running     | :meth:`~Logger.critical` method as   |
> | server process)                     | appropriate for the specific error   |

**On structure, names and noise.** The documentation asks a library to document its logger names. It states no rule for a stable name per kind of event, nor for throttling. Searched `Doc/howto/logging.rst`, `Doc/library/logging.rst` and `Doc/howto/logging-cookbook.rst` at the tag for "event name", "stable", "structured", "flood", "rate", "throttl", "duplicate" and "once". The cookbook's structured-logging recipe puts JSON in the message.

**Constraints.** The logging module is one shared, process-wide hierarchy, configured once by the application.

### G2. Rust: the `log` and `tracing` crates

**What they say.** Read at `log` `v0.4.35` and `tracing-0.1.44`. A library links only to the facade, and the executable chooses the implementation.

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs

> //! The `log` crate provides a single logging API that abstracts over the
> //! actual logging implementation. Libraries can use the logging API provided
> //! by this crate, and the consumer of those libraries can choose the logging
> //! implementation that is most suitable for its use case.

> //! Libraries should link only to the `log` crate, and use the provided

> //! Executables should choose a logging implementation and initialize it early in the
> //! runtime of the program.

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs

> //! Libraries should link only to the `tracing` crate, and use the provided
> //! macros to record whatever information will be useful to downstream
> //! consumers.

**Stated why.** Each gives a reason for one part of the split. Neither says why the split exists beyond the consumer choosing.

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs

> //!     <strong>Warning</strong>: In general, libraries should <em>not</em> call
> //!     <code>set_global_default()</code>! Doing so will cause conflicts when
> //!     executables that depend on the library try to set the default later.

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs

> //! Libraries should avoid using the max level features because they're global and can't be changed
> //! once they're set.

> //! If no logging implementation is selected, the facade falls back to a "noop"
> //! implementation that ignores all log messages.

**There is no standard Rust facade.** `log` and `tracing` are both third-party crates, and each tells libraries to use itself. A `tracing` event becomes a `log` record when the build enables `tracing`'s `log` feature and no `tracing` subscriber is active, or in every case with `log-always`, which libraries are told not to enable. A `log` record reaches a `tracing` subscriber only through a compatibility layer.

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs

> //! cause [spans] and [events] to emit `log` records. When the "log" feature is
> //! enabled, if no `tracing` `Subscriber` is active, invoking an event macro or
> //! creating a span with fields will emit a `log` record.

Which of the two a Rust client should use is not settled by either crate's documentation.

**On levels, structure and names.**

- Both crates describe the levels only in one line each, "very serious errors" for error and "hazardous situations" for warn, and give no rule for which a library should use.

  Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs

  > /// Designates hazardous situations.

- Both carry structured key-value fields: `log` behind its `kv` feature, `tracing` always.

  Source: https://github.com/rust-lang/log/blob/v0.4.35/src/kv/mod.rs

  > //! Structured logging enhances traditional text-based log records with user-defined
  > //! attributes. Structured logs can be analyzed using a variety of data processing
  > //! techniques, without needing to find and parse attributes from unstructured text first.

- A record's target defaults to the module path in both. `tracing` lets an event carry a name, which defaults to the file and line:

  Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs

  > //! The span macros also take a string literal after the level, to set the name
  > //! of the span (as above).  In the case of the event macros, the name of the event can
  > //! be overridden (the default is `event file:line`) using the `name:` specifier.

  A member of the `tracing` project kept the name optional, and the standard formatter does not print it:

  Source: https://github.com/tokio-rs/tracing/pull/2699#issuecomment-1707106016

  > hmm, my preference is for events to not _require_ a name...i feel like users often just want to record a single field value or an unstructured textual log message, and having to think up a name for each event seems like an extra speed bump to just recording the piece of data you want.

  Source: https://github.com/tokio-rs/tracing/issues/2774#issuecomment-1779722990

  > The `fmt` layer does not currently include event names in its output.

- Neither crate's documentation says anything about throttling. Searched both `lib.rs` files and `log`'s `kv/mod.rs` for "throttl", "rate", "flood", "once" and "spam".

### G3. The OpenTelemetry specification

**What it says.** Read at `v1.63.0`.

- **Error handling.** A suppressed error is logged "using language-specific conventions". The document states no level and no throttle: searched it for "level", "warn", "error", "throttl" and "repeat".

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > Whenever the library suppresses an error that would otherwise have been exposed to the user, the library SHOULD log the error using language-specific conventions.

- **Performance: the one statement on logging lost data.** When an SDK drops data to avoid blocking, it is to "show warning log to inform when information loss starts and when recovered". The sentence is not in RFC 2119 terms.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/performance.md

  > - **Prevent blocking**: Dropping some information under overwhelming load and show warning log to inform when information loss starts and when recovered

- **A discarded attribute.** A message at most once per span or record, "to prevent excessive logging".

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md

  > To prevent excessive logging, the message MUST be printed at most once per
  > span (i.e., not per discarded attribute, event, or link).

- **Self-observability events**, a non-normative guideline: an event sent through the language's native logging still needs its event name.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/self-observability-supplementary-guidelines.md

  > Such an event still needs its event name: use the mechanism's native event-name
  > field if it has one (.NET's `ILogger` and Rust's `tracing` do); otherwise carry

**Stated why.**

- For not throwing, and so for logging instead:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

- For logging separately from callbacks, from the review of pull request #153, which wrote the error-handling document. The member who added the sentence said only:

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/153#discussion_r315925007

  > This is a new line, I thought logging was worth mentioning separately from callbacks.

- For "starts and when recovered": no stated rationale found. Pull request #130 added the sentence. Its review thread, read in full, discusses whether to drop or block by default, not the log.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/130#issuecomment-514934052

  > As discussed, the default option (prefer blocking or information loss) is not obvious, there are various needs.

- For "at most once per span": the member who wrote the rule said he was not certain what the earlier text meant, and offered an unspecified alternative.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/3151

  > I'm not certain what was originally intended to be communicated, so my initial proposal is to state that a message must only be printed once per Span/LogRecord regardless of how many items were dropped or truncated on the Span/LogRecord. However, some may argue this too may lead to excessive logging.

**Costs and dissent.** The level of SDKs' internal logs was never standardised. The issue asking for it is still open, and a member proposed closing it as "wont fix":

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2039#issuecomment-4300297774

> BTW, I think we close this issue as "wont fix". Its been open five years, and the chances of us going back and retroactively standardizing `OTEL_LOG_LEVEL` are minimal.

**Constraints.** The specification governs telemetry SDKs, which run inside an application, are often loaded without the application developer's choice, and must not change its behaviour:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

> OpenTelemetry may be enabled via platform extensibility mechanisms, or dynamically loaded at runtime.
> This makes the use of the library non-obvious for end users, and may even be outside of the application developer's control.

---

## The libraries

### Summary table

What each writes to the host's log for lost data, at the tag read. "At once" means the library makes its logging call for the first occurrence when it happens, at a level its facade passes by default: WARNING or above for most, and the caller's level for the kernel. Whether a host that has configured no logging sees that record is a separate property, noted in the cell where it differs.

| # | Library | Rule for a full queue | Key | Numbers | Other failures | Facade, name | Installs a handler | Level | Stable name | At once |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| L1 | ddtrace | rate limit, count on the next record | logger, level, file, line | 1 per 60 s | failed send: same limit, at ERROR | `logging`, module name | yes, `StreamHandler` | WARNING | no | yes, unless another warning the writer logs through the same `_safelog` line already passed in its 60 s window (inferred, see L1) |
| L2 | OTel Java | spans: count per cycle; log records: none | per processor | spans: once per non-empty export (5 s or 512 spans by default; flush; shutdown) | export failure: every occurrence in the batch processors (FINE for a failed result, WARNING for a thrown exception); the OTLP exporters' own records through `ThrottlingLogger` | `java.util.logging`, class name | no | WARNING | no | no |
| L3 | OTel Python | every occurrence, through a duplicate filter | last record, per logger | 20 s bucket | export failure: ERROR, same filter | `logging`, module name | no (opt-in only) | WARNING | no | yes, unless another processor's identical warning passed last in the same 20 s bucket |
| L4 | Linux kernel | rate limit, count on the next call | call site | 10 per 5 s | — | `printk`, caller's level | n/a | caller's | no | yes |
| L5 | OTel Rust | **onset then total** | per processor | once, then a snapshot when shutdown begins | export failure: every occurrence, ERROR; flush timeout: not logged | `tracing`, target `opentelemetry_sdk` | no | WARN | yes | yes, but collected only once the application installs a `tracing` subscriber, or enables `tracing`'s `log` feature and sets a `log` logger |
| L6 | OTel Go | spans: none at default level; log records: count per cycle, hidden by default | per processor | log records: each worker wake (1 s timer, full batch, flush, shutdown) | export failure: every occurrence to the error handler; returned to the caller on flush, and on log-record shutdown | `ErrorHandler` and `logr`, no name | yes, standard error | Debug; `V(1)` Info, named Warn | no | no |
| L7 | OTel .NET | total at shutdown only | per processor | once, at shutdown | export failure: every occurrence, Error | `EventSource` `OpenTelemetry-Sdk` | no output by default | Warning | yes, event ID | no |
| L8 | OTel JS | spans: onset at Debug, total at recovery; log records: none | per processor | once per episode | export failure: every occurrence on the export timer, through the global error handler (`diag.error` by default); returned to the caller on `forceFlush` and shutdown | `diag`, no name | no (no-op) | Debug, then Warn | no | no |
| L9 | sentry-python | none in the host log; a count to Sentry, carried on later sends | category and reason | at the next send, after 30 s or 60 s; on flush, queued without the time test, best effort | — | `logging`, `sentry_sdk.errors` | yes, gated by `debug` | — | no | no |
| L10 | urllib3 | every occurrence (a discarded connection) | — | — | retry: every occurrence | `logging`, module name | `NullHandler` only | WARNING | no | yes, but silent until the application configures logging (`NullHandler`) |
| L11 | OTel Collector | sampling, no count | level and message | 10 per 10 s, then 1 in 100 | the same sampling | zap, per component | yes; it is the host | Error | no | usually; not when its counter is already spent, by the same message for another reason or by a message hashed to the same counter |
| L12 | Vector | blocks by default; with `drop_newest`, a count every 2 s at debug, through the rate limit | buffer and stage; then call site and component in the limiter | 2 s tick; in the limiter, 1 original event per 10 s, a notice on the 2nd, and the count with the next event after the window | a drop it did not intend: rate limit, count on the next event, at Error | `tracing` | yes; it is the host | debug (full buffer); Error (a drop it did not intend) | no; a fixed message and fields | no for a full buffer (debug); yes for a drop it did not intend |

urllib3's record is a connection discarded from a full pool, not lost telemetry. It is the closest thing urllib3 has, and is counted with that caveat.

---

### L1. ddtrace (dd-trace-py): a rate limit per call site

**What it does.** Read at `v4.17.2`.

- Every internal logger gets a filter that lets one record per key through per 60 s, configurable by `DD_TRACE_LOGGING_RATE`. 0 turns the limit off. A record logged the plain way, as the writer's are, is keyed on its logger name, level, file and line. A record that carries a `product` in `extra` is keyed on its message. For any record, `set_tag_rate_limit` can set the interval for its message, even when `DD_TRACE_LOGGING_RATE` is 0; at this tag only appsec and dynamic instrumentation call it, not the writer. When the logger's effective level is DEBUG, the filter passes every record, at every level, with no limit.

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/logger.py

  > # Allow 1 log record per name/level/pathname/lineno every 60 seconds by default

  >             key = (record.name, record.levelno, record.pathname, record.lineno)

  >             skip_str = f" [{skipped} skipped]"

  >         if hasattr(record, "product"):
  >             key: key_type = record.msg

  >     # If the logger is set to debug, then do not apply any limits to any log

- The skipped count is added to the next record that passes. Inferred from `is_sampled`, which sets the count on the record it lets through: if no record for that key follows, the count is never written.
- A full trace buffer is logged at WARNING and a failed send at ERROR:

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py

  >                 "trace buffer (%s traces %db/%db) cannot fit trace of size %db, dropping (writer status: %s)",

- Each record is a message template, with no event name.
- **It installs a handler.** Importing `ddtrace` adds a `StreamHandler` to the `ddtrace` logger, unless `DD_TRACE_LOG_STREAM_HANDLER` is false:

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/_logger.py

  >     if get_config("DD_TRACE_LOG_STREAM_HANDLER", True, asbool):
  >         ddtrace_logger.addHandler(logging.StreamHandler())

**Inferred.** The writer logs its drops through a helper, `_safelog`, so the file and line in the key are the helper's, not the call site's. All the writer's drop records at one level would then share one 60 s bucket. Nothing in `writer.py` passes `stacklevel`, which would change that. The count on the next record can then include warnings of other kinds from the same helper.

**Stated why.** By its author, a member of Datadog, in the pull request that added the limiter (#822, merged 2019):

Source: https://github.com/DataDog/dd-trace-py/pull/822

> The purpose of this new logger is to ensure that we do not spam user's application logs, especially if we are running in a high volume application.

> This should allow errors to be surfaced to the user without overloading their logs.

No stated rationale was found for the 60 s, nor for WARNING on a full buffer and ERROR on a failed send. Searched the pull request, the writer's comments, and issue searches for the level of dropped traces, downgrades and noisy logs.

**Constraints.** ddtrace is loaded into the application, often by a wrapper the developer did not write. It ships its data to a local agent and keeps its own internal metrics (`buffer.dropped.traces`) beside the log.

**Costs and dissent.**

- A user found the warnings still too many, and asked how to silence them. A collaborator on the repository agreed that the logging could be improved:

  Source: https://github.com/DataDog/dd-trace-py/issues/10995

  > Is there a way to silence them?

  Source: https://github.com/DataDog/dd-trace-py/issues/10995#issuecomment-2688834773

  > I agree the current logging level behavior could be improved though!

- An earlier form of the suffix broke grouping in Sentry, because it rewrote the message template. A contributor reported it:

  Source: https://github.com/DataDog/dd-trace-py/issues/1115

  > When rewriting `msg`, one should not enrich it with arbitrary values, like `logging_bucket.skipped`.

- The format changed: from ", N additional messages skipped" to " [N skipped]", in pull request #12928 (first tag `v3.5.0`), which also moved from wall-clock buckets to a sliding window and added the key by message. Its author, a contributor, gave the reason for the second key:

  Source: https://github.com/DataDog/dd-trace-py/pull/12928

  > Motivation: current default rate limit for the tracer log is based on log position in the file and is the same for all logs. But AppSec would like to be able to get different rate limit for different logs.

  > - At debug level, we still disable any rate limiter.

### L2. OpenTelemetry Java: a count per export, and `ThrottlingLogger` for exporters

**What it does.** Read at `v1.68.0`.

- **A full span queue** is counted, and the count since the last export is logged at WARNING by the worker before each export. So the first drop is logged at the next export, not when it happens.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessor.java

  >             "BatchSpanProcessor dropped "
  >                 + dropped
  >                 + " span(s) since the last export because the queue is full"

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessorBuilder.java

  >   static final long DEFAULT_SCHEDULE_DELAY_MILLIS = 5000;

  >   static final int DEFAULT_MAX_EXPORT_BATCH_SIZE = 512;

- **A full log-record queue** is not logged at all: only an internal metric is recorded. Checked by `git grep -n -E 'logger\.log' -- sdk/logs/src/main/java/io/opentelemetry/sdk/logs/export/BatchLogRecordProcessor.java` on a clone at `6700a70` (`v1.68.0`), which finds only "Exporter failed" at FINE and "Exporter threw an Exception" at WARNING.
- **`ThrottlingLogger`** spends from a token bucket that starts full at 5 and refills at 5 a minute, one token every 12 s. The first time a record finds the bucket empty, the instance switches for the rest of its life to a bucket of 1 that refills at 1 a minute. That bucket is emptied at the switch. The logger logs that it is throttling, and logs the record too. So 5 records can pass at once, more can pass in the first minute if they are spaced out, and a logger that never outruns the refill is never throttled. It wraps the OTLP exporters and parts of the metrics SDK, not the batch processors.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/common/src/main/java/io/opentelemetry/sdk/common/internal/ThrottlingLogger.java

  >   private static final double DEFAULT_RATE_LIMIT = 5;
  >   private static final double DEFAULT_THROTTLED_RATE_LIMIT = 1;
  >   private static final TimeUnit DEFAULT_RATE_TIME_UNIT = MINUTES;

  >               "Too many log messages detected. Will only log %.0f time(s) per %s from now on.",

  >       // spend the balance in the throttled one, so that it starts at zero.
  >       throttledRateLimiter.trySpend(throttledRateLimit);

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/common/src/main/java/io/opentelemetry/sdk/common/internal/RateLimiter.java

  >     this.currentBalance = new AtomicLong(clock.nanoTime() - this.maxBalance);

- Until pull request #7156 (first tag `v1.48.0`), the throttled mode let 5 a minute through, not 1. A member explained why:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/7156#discussion_r1975673849

  > So a noisy logger logging every 12 seconds (or more frequent) will be able to 5 logs per minute, when it should only be 1 log per minute.

- The library installs no handler. `git grep -n -E 'addHandler|LogManager|setUseParentHandlers' -- '*.java' ':!**/src/test/**' ':!**/testing/**' ':!**/jmh/**'` at `6700a70` finds nothing.
- Records are text messages under the class's logger name, with no event name.

**Stated why.**

- `ThrottlingLogger`, from issue #3013 and pull request #3051 (2021). A user's report, and the contributor who wrote the class:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/3013

  > If the collector crash loops, it fills up the logs with this.  Making the logs pretty unreadable.

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/3051#discussion_r603453275

  > My goal here was to have an exporter log noisily initially (up to the 5 per minute limit), but if it's a known noisy logger, then have it just be clamped down to 1 per minute after that. That's a bit different than a rate limiter.

- The count per export, from issue #7103 and pull request #8167 (2026, first tag `v1.61.0`). The issue's author, a user, describes a drop nobody could see without a metrics pipeline:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/7103

  > Typically a user would first go to the logs to figure out what the issue is, but since the java sdk does not produce any logs for this drop it makes it very difficult to know why the spans went missing.

  The pull request began as a `ThrottlingLogger` warning per drop. A contributor asked for the total instead, and the author, also a contributor, moved to a count per export:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/8167#issuecomment-4059198532

  > It would let you know _that_ spans were being dropped, but not how bad the problem is. If a solution could be put together to log the total number dropped per batch (which would certainly require more work!), that would probably be a better solution.

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/8167#issuecomment-4061088862

  > This is naturally throttled by the export cycle, gives visibility into how severe the backpressure is, and the threading model already supports it cleanly since `addSpan()` runs on caller threads and `exportCurrentBatch()` runs on the single worker thread.

- WARNING for the drop. A reviewer, a contributor, suggested INFO. The pull request's author answered, at a time when the change still used `ThrottlingLogger`. This is the author's reason, not a reviewer's:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/8167#discussion_r2910926617

  > Isn't warning too high level? I think INFO would be enough.

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/8167#discussion_r2915351533

  > I think WARNING is appropriate here because dropped spans represent actual data loss, which impacts observability. This warrants immediate attention from operators in production.

**Constraints.** The SDK logs through `java.util.logging`, which most Java applications route to another framework. It also counts drops in internal metrics, and a member questioned logging what a metric already shows:

Source: https://github.com/open-telemetry/opentelemetry-java/pull/8167#pullrequestreview-3939411088

> Given that we already have internal metrics that would allow a user to detect / react to this condition, is it necessary to duplicate with a log signal?

**Costs and dissent.**

- A user found once a minute too often. A contributor declined to go lower, because a rarer message would not be noticed:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/7178#issuecomment-3528558534

  > Once per hour would essentially turn off logging, as no one would ever notice the messages. I don't think that would be a good default for most users.

- A contributor, reviewing pull request #3051, noted that the throttle never recovers:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/3051#discussion_r603692079

  > The main difference is that the jaeger limiter could recover if the exporter stops being noisy. But that's ok I guess?

### L3. OpenTelemetry Python: every drop, through a duplicate filter

**What it does.** Read at `v1.45.2`.

- The shared batch processor, used for spans and log records, logs a WARNING on every full-queue drop, and the queue drops its oldest entry:

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  >         if len(self._queue) == self._max_queue_size:
  >             _logger.warning("Queue full, dropping %s.", self._exporting)

- Its logger has a `DuplicateFilter`, which drops a record equal to the last one that passed, by module, level, message template and a 20 s wall-clock bucket:

  >             # We need to pick a time longer than the OTLP LogExporter timeout
  >             # which defaults to 10 seconds, but not pick something so long that
  >             # it filters out useful logs.
  >             time.time() // 20,

- Inferred from the code: any other record in between resets the filter, two repeats on either side of a bucket boundary both pass, and nothing counts what was suppressed. The logger and its one filter are module-level and shared by every batch processor in the process, and the signal is a formatting argument, not part of the template. So one processor's drop warning can suppress another's first, for spans or log records, in the same bucket.
- **History.** The span processor logged the full queue once per processor, until `v1.33.0`:

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.33.0/opentelemetry-sdk/src/opentelemetry/sdk/trace/export/__init__.py

  >             if not self._spans_dropped:
  >                 logger.warning("Queue is full, likely spans will be dropped.")
  >                 self._spans_dropped = True

  The shared processor of `v1.34.0` had no drop log at all, because of a recursion risk. Pull request #4799 (first tag `v1.40.0`) restored it on every drop.
- The SDK installs no console handler. Its auto-configuration adds an exporting handler to the root logger only when `OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED` is `true`, which is not the default and is deprecated. Checked by `git grep -n 'addHandler(' -- '*.py' ':!**/tests/**' ':!docs/**'` at `ad75594` (`v1.45.2`), which finds only that path and a benchmark.

**Stated why.**

- For logging once, in the review of the first batch processor (#153, 2019), by two members. The second also named a rate-limited count as better:

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r327482275

  > Dropped span counter sounds like a plan. Or we could log a warning the first time a span is dropped.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r328124492

  > Good idea, I'd just log the first time a span is dropped. A better approach could be a rate-limited logging system that actually prints the number of spans being dropped per second or so.

- For removing the drop log, and for the filter, by the same contributor:

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/4588

  > Any log calls in that function can get routed back to `emit` and ultimately result in a maximum recursion depth exceeded exception.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/4695

  > Filter duplicate logs out of some `logger`'s logs on the export logs path that might otherwise endlessly log or cause a recursion depth exceeded issue in cases where logging itself results in an exception.

- For the 20 s, in that pull request's review:

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/4695#discussion_r2294636577

  > I think we do want it to be longer than the log exporter timeouts (OTLP we default that to 10 seconds), because otherwise we risk the endless loop issue again..

- For restoring the drop log on every drop: the author found the recursion was in the simple processor, not the batch one. No reason is stated for every drop rather than once:

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/4799

  > I think the batch processor should be safe from recursion because it is sending batches on a different thread periodically and not via a synchronous blocking call...

- No stated rationale was found for dropping the once-per-processor rule in `v1.34.0`. Pull request #4580 says only that the span processor now uses the shared class.

**Constraints.** The SDK can export Python log records itself, so a record it logs about its own failure can be fed back into the pipeline that failed. That is the recursion each change above guards against.

**Costs and dissent.** A member, in 2024, on a user's report of noise:

Source: https://github.com/open-telemetry/opentelemetry-python/issues/4323#issuecomment-2504660150

> Yes, this problem keeps coming up. We have a "meta" bug here for it #4261 and I agree we need to rethink the approach like the recommendations you mentioned:

### L4. Linux kernel: `printk` rate limiting per call site

**What it does.** Read at `v7.3`.

- `printk_ratelimited()` keeps a static state per call site: 10 messages per 5 s.

  Source: https://github.com/torvalds/linux/blob/v7.3/include/linux/ratelimit_types.h

  > #define DEFAULT_RATELIMIT_INTERVAL	(5 * HZ)
  > #define DEFAULT_RATELIMIT_BURST		10

- When a call arrives after the window, the count of suppressed calls is printed at `KERN_WARNING`. If no call arrives, nothing is printed. Inferred from the code: the print sits inside the branch that handles the next call.

  Source: https://github.com/torvalds/linux/blob/v7.3/lib/ratelimit.c

  > 				printk_deferred(KERN_WARNING
  > 						"%s: %d callbacks suppressed\n", func, m);

- The shared `printk_ratelimit()` uses one state for every caller, and the header says not to use it.

**Stated why.** For rate limiting `printk` at all, a code comment of unknown date on the shared limiter, `__printk_ratelimit`:

Source: https://github.com/torvalds/linux/blob/v7.3/kernel/printk/printk.c

>  * This enforces a rate limit: not more than 10 kernel messages
>  * every 5s to make a denial-of-service attack impossible.

And the 2008 commit that made the limiter a library of its own:

Source: https://github.com/torvalds/linux/commit/5f97a5a8799b8d7d0afdb9d68a50a4e0e8298a05

> Due to the rcupreempt.h WARN_ON trigged, I got 2G syslog file.  For some
> serious complaining of kernel, we need repeat the warnings, so here I isolate
> the ratelimit part of printk.c to a standalone file.

For a state per call site, the header that declares the shared limiter:

Source: https://github.com/torvalds/linux/blob/v7.3/include/linux/printk.h

>  * Please don't use printk_ratelimit(), because it shares ratelimiting state
>  * with all other unrelated printk_ratelimit() callsites.  Instead use
>  * printk_ratelimited() or plain old __ratelimit().

No stated rationale was found for 10 and 5 s themselves, which predate git. Searched the 33 commits on `lib/ratelimit.c` up to `v7.3`.

**Constraints.** The kernel is not a library inside an application. Its log is a shared, bounded ring, and any process that can trigger a kernel message can try to flood it.

**Costs and dissent.** A 2016 commit added a summary on release, for short-lived users:

Source: https://github.com/torvalds/linux/commit/6b1d174b0c27b5de421eda55c2731f32b6bd9852

> This use case is aimed at short-termed, burst-like users for which we
> want to output the suppressed lines stats only once, after it has been
> disposed of.

### L5. OpenTelemetry Rust: the onset once, then a total at shutdown

**What it does.** Read at `opentelemetry_sdk-0.33.1`.

- **Only a full queue, in the default batch span and batch log processors**, follows the rule. Each processor keeps a counter for its lifetime, which is never reset. The first drop logs one WARN. The total is one WARN written as the first step of the processor's shutdown, before the worker is asked to stop. It is a snapshot taken when shutdown begins, it counts nothing dropped after that moment, and it is written even if the shutdown then fails or times out. The provider refuses a second shutdown, but a second direct call to a processor's shutdown writes the total again:

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/batch_log_processor.rs

  >                 if self.dropped_logs_count.fetch_add(1, Ordering::Relaxed) == 0 {
  >                     otel_warn!(name: "BatchLogProcessor.LogDroppingStarted",
  >                         message = "BatchLogProcessor dropped a LogRecord due to queue full. No further log will be emitted for further drops until Shutdown. During Shutdown time, a log will be emitted with exact count of total logs dropped.");

  >                 message = "Logs were dropped due to a queue being full. The count represents the total count of log records dropped in the lifetime of this BatchLogProcessor. Consider increasing the queue size and/or decrease delay between intervals."

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs

  >                     otel_warn!(name: "BatchSpanProcessor.SpanDroppingStarted",

  >         let dropped_spans = self.dropped_spans_count.load(Ordering::Relaxed);

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/batch_log_processor.rs

  >     fn shutdown_with_timeout(&self, timeout: Duration) -> OTelSdkResult {
  >         let dropped_logs = self.dropped_logs_count.load(Ordering::Relaxed);

  >         match self.message_sender.try_send(BatchMessage::Shutdown(sender)) {

- **The experimental processors apply the rule to any failed send.** The batch log and batch span processors for an async runtime sit behind the non-default features `experimental_logs_batch_log_processor_with_async_runtime` and `experimental_trace_batch_span_processor_with_async_runtime`. Each counts any failed `try_send`, a closed channel included, and logs the same onset and total.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/log_processor_with_async_runtime.rs

  >         if result.is_err() {

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/Cargo.toml

  > default = ["trace", "metrics", "logs", "internal-logs"]

- **In the default processors, a failed export is ERROR each time**, and so is a shutdown timeout. The shutdown timeout's own comment says records still queued or mid-export are then lost uncounted. A record emitted after shutdown is a WARN each time. A `force_flush` timeout is returned to the caller with no log, and a full control channel is logged only at debug.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/batch_log_processor.rs

  >             otel_error!(
  >                 name: "BatchLogProcessor.ExportError",

  >                             // TODO: When shutdown times out, log records still
  >                             // in the queue or mid-export are silently lost.

  The metrics reader has no queue and no drop counter, and its failed exports are ERROR each time. Checked by `git grep -n -i -E 'thrott|rate.?limit|log_once|Once::new' -- '*.rs'` at `372ebbc`. It finds no throttling helper for internal logs, only a TODO in the async log processor.
- **When the total is written.** Inside the processor's shutdown. A provider's `Drop` calls shutdown when its last reference goes. Inferred: if neither happens, as with a provider held in a `static` or a process that ends by `std::process::exit` or a signal, no total is written.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/logger_provider.rs

  >                 message = "Last reference of LoggerProvider dropped, initiating shutdown."

- **Collected only if the application installs a `tracing` subscriber, or the build enables `tracing`'s `log` feature and the application sets a `log` logger.** OTel Rust does not enable that feature itself; inferred from Cargo's feature unification, a host that enables it for its own use of `tracing` enables it for the SDK's events too. With neither, `tracing` drops the record:

  Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs

  > //! Any trace events generated outside the context of a subscriber will not be collected.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/Cargo.toml

  > tracing = { version = ">=0.1.40", default-features = false }

- **Facade, name and level.** The `otel_warn!` macros call `tracing`, with the crate's package name as target and a `name` for each event. The `internal-logs` feature that enables them is a default feature. The SDK installs no subscriber: `git grep -n -E 'set_global_default|\.init\(\)' -- opentelemetry/src opentelemetry-sdk/src` at `372ebbc` finds nothing.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/docs/design/logs.md

  > OTel itself is instrumented with the `tracing` crate to emit internal logs
  > about its operations. This is feature gated under `internal-logs`, and is
  > enabled by default for all components.

**Stated why.**

- The design, in issue #2273 (2024), by a member. It cites OTel .NET (L7) for the count and the log at shutdown. The onset record is not in it:

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/2273

  > 1. We certainly don't want to log each time the buffer is full
  > 2. A good balance might be to keep a count of items-dropped-due-to-buffer-full.
  > 3. This count can be exposed as a Metric itself.
  > 4. And/Or this count can be emitted as a internal log upon shutdown/drop with severity WARN if non-zero items were dropped.

  > 2,4 is what OTel .NET has implemented:

- The onset record was added in the review of pull request #2357, which implemented the design, by the same member. No reason is given for it:

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/2357#discussion_r1860847298

  > for the very first time, lets also emit an internal log informing the user about data drop.

  The request gives it a purpose, informing the user, and no reason for logging it at the first drop. Its one reply, by the pull request's author, a member, only links the change, and no review summary gives a reason. In the same review a member proposed moving the total into the worker's handling of the shutdown message, to avoid keeping a field only for the log. It was not done at the tag:

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/2357#discussion_r1860944762

  > I believe we can avoid this by moving the logging of dropped logs (otel_warn!) from the shutdown() method to the worker's Shutdown message processing.

- What came before: a user reported the per-drop error flooding standard error, and the same member answered that a count belongs in a metric, with a log at shutdown if one is needed:

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/2175#issuecomment-2394523163

  > Saw issue with using `eprintln` as the default error handler as it causing flood of writes to STDERR like `OpenTelemetry trace error occurred. cannot send message to batch processor as the channel is full`.

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/2175#issuecomment-2394816345

  > For this specific one, I don't think there should be a log entry for channel full for each message. It is best exposed as an internal metric only. If a log is needed, it can be done at the shutdown time "N items were dropped due to buffer full"/similar.

- In the review of pull request #2184 the per-drop error was removed rather than throttled, because no throttle could ship in time. The same member:

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/2184#discussion_r1796241352

  > either of them are fine with me, though I slightly prefer removing altogether, as I don't know if we can ship a throttling solution for next release.

- The level rule, from the same review:

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/2184#discussion_r1792651384

  > No. I think all WARN/ERROR level should be user actionable or conveying some important information that they'd not know otherwise.

  > For debug level logs, its okay to be more liberal as that is unlikely to enabled by end users by default.

- Why not a periodic total, or a rate limit: no stated rationale found. Searched the bodies and reviews of #1660, #2128, #2175, #2177, #2184, #2273, #2357, #2897, #3126, #3210, #3514, #3551 and #3621, and issue searches for internal logging, throttling and dropped logs.

**Constraints.** The count is meant to live in a metric. The log is the fallback, and the metric is behind a non-default feature at this tag:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/docs/design/observability.md

> Self-diagnostics metrics require the `experimental_metrics_bound_instruments`
> feature on `opentelemetry_sdk`. This feature is not enabled by default.

**Costs and dissent.**

- A contributor's open issue objects to the library logging errors at all:

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3210

  > 4. **Policy violations**: The library makes policy decisions (what to log, when, how) that belong to the application

- A member's answer on that issue says stable event names are the aim and are not reached:

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3210#issuecomment-3469370877

  > We have been striving to get to this state, but not there yet.

- A TODO remains where the async processor counts drops:

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/log_processor_with_async_runtime.rs

  >         // TODO - Implement throttling to prevent error flooding when the queue is full or closed.

### L6. OpenTelemetry Go: a count per export cycle, hidden by default

**What it does.** Read at `v1.47.0`.

- **Spans.** A drop is counted and appears only in a Debug line written at each export of a non-empty batch, as a running total. That includes the final export when shutdown drains the queue. No record of its own reports the total at shutdown.

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/sdk/trace/batch_span_processor.go

  > 		global.Debug("exporting spans", "count", len(bsp.batch), "total_dropped", bsp.dropped.Load())

  > 			// There are no more enqueued spans. Make final export.

- **Log records.** The count since the last check is logged through the SDK's `Warn` helper each time the worker wakes: on its timer (1 s by default), on a full batch, at flush and at shutdown. It is logged whether or not there is a batch to export. The same goroutine makes the export call, so a slow export delays the next count.

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/sdk/log/batch.go

  > 		global.Warn("dropped log records", "dropped", d)

  > func (b *BatchProcessor) exportBatch(buf []Record) {
  > 	b.logDroppedRecords()

- **The default logger shows only errors**, so neither line appears unless the application sets a logger:

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/internal/global/internal_logging.go

  > // The default logger uses stdr which is backed by the standard `log.Logger`
  > // interface. This logger will only show messages at the Error Level.

  > func Warn(msg string, keysAndValues ...any) {

  > 	GetLogger().V(1).Info(msg, keysAndValues...)

  `Warn` is not a warning level: `logr` has none, and the helper logs at `V(1)` Info.

- **A failed export** on the timer or full-batch path goes to the error handler, which by default prints every error to standard error. In the log processor, one during `ForceFlush` or `Shutdown` is returned to the caller instead, and so is a failed span export during `ForceFlush`:

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/sdk/log/batch.go

  > 			case req := <-b.flush:
  > 				err := b.flushExporter(req.ctx)
  > 				req.respond(err)


  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/handler.go

  > // The default ErrorHandler instance returned will log all errors to STDERR

**Stated why.**

- Against a Warn per dropped span, by a member:

  Source: https://github.com/open-telemetry/opentelemetry-go/issues/3264#issuecomment-1271874097

  > I'm not sure that logging at the warn level on every dropped span is appropriate.  This is a situation that is likely to occur under load and adding a substantial amount of logging may exacerbate that load.  The number of dropped spans is expected to be able to be reported as a metric.

- For logging the log-record count, a member in a review:

  Source: https://github.com/open-telemetry/opentelemetry-go/pull/5093#discussion_r1561295983

  > Do we need to provide a way to show the # of records that have been dropped instead of dropping records silently?

- No stated rationale was found for a count per export rather than once.

**Constraints.** Go has no standard leveled logging facade older than `slog`, and the SDK predates its use of it. It has one global error handler and one global logger.

**Costs and dissent.** A user, on an open issue, reports that span drops cannot be seen in production:

Source: https://github.com/open-telemetry/opentelemetry-go/issues/5557#issuecomment-2325835540

> In production, we can't use debug logs for all our applications, making it nearly impossible to understand when and which applications are silently dropping spans, especially since these applications are developed by other teams.

A pull request to log a Warn on dropped spans (#3289) was closed as stale, unmerged.

### L7. OpenTelemetry .NET: a total at shutdown, with no onset

**What it does.** Read at `core-1.21.0`.

- A full queue, or an enqueue that gives up after 50,000 spins under contention, increments a counter and a metric; event 32 reports both as "due to buffer full".

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/src/OpenTelemetry/BatchExportProcessor.cs

  >         if (this.circularBuffer.TryAdd(data, maxSpinCount: 50_000, out var count))

  >         // either the queue is full or exceeded the spin limit, drop the item on the floor

  The count is written once, as `EventSource` event 32 at Warning, inside the processor's shutdown, and as event 31 at Informational when it is zero. Checked by `git grep -n DroppedExportProcessorItems -- src` at `51c6db1` (`core-1.21.0`): the only call is in `OnShutdown`.

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/src/OpenTelemetry/Internal/OpenTelemetrySdkEventSource.cs

  >     [Event(32, Message = "'{0}' exporting to '{1}' dropped '{2}' item(s) due to buffer full.", Level = EventLevel.Warning)]

- A failed OTLP export is an Error event each time.
- Nothing is written by default. `EventSource` events go nowhere until a listener or the SDK's self-diagnostics is enabled:

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/docs/troubleshooting/README.md

  > Self-diagnostics is off by default. Every sink is disabled until you enable one,
  > so a stock SDK writes nothing unless configured.

**Stated why.**

- For the count at shutdown, by the pull request's author, a contributor (#2331, merged 2021). The description also floats an alternative it did not take, "every N drops":

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/pull/2331

  > This feature is important as we want to let users know somehow that we are dropping items.

  > - We may consider writing to the log the current number of dropped items every N drops. In this case, the first item dropped should write and then every subsequent Nth dropped item will write to the log.

- For Warning when the count is not zero, a member in that review:

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/pull/2331#discussion_r706287809

  > 2. If droppedCount is non-zero, we should be logging at higher severity than informational.

- For `EventSource`, a member's stated preference in an issue. The repository's documentation states no reason:

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/issues/1258#issuecomment-694956683

  > EventSource based logging should be available at the earliest stage of application startup. But Ilogger based ones, requires someone to inject Ilogger, which typically requires DI to be ready, etc.

- For Warning as the self-diagnostics default:

  Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/docs/troubleshooting/README.md

  > > value until something is actually being investigated. Since this channel is
  > > meant to be safe to leave enabled in production, the more economical level is
  > > the more useful default.

- No stated rationale was found for writing nothing until shutdown, rather than an onset. Searched pull request #2331's body, comments and review comments.

**Constraints.** `EventSource` is the .NET runtime's own event mechanism, read by tools outside the process or by an in-process listener. It is not the application's `ILogger` pipeline.

**Costs and dissent.** A user could not read the diagnostics in a container. A contributor proposed writing to the console, which pull request #7588 (merged 2026-10-01) added:

Source: https://github.com/open-telemetry/opentelemetry-dotnet/issues/3881#issuecomment-2398343995

> The crux of the problem we want to solve here is the inability to access the file-on-disk in containerized environments.

### L8. OpenTelemetry JS: the onset at Debug, a total at recovery

**What it does.** Read at `v3.1.1` (`@opentelemetry/sdk-trace`; `sdk-trace-base` was removed at that tag) and `api/v1.10.0`.

- For spans, the first drop of an episode logs at Debug. The next span that is accepted ends the episode, and a Warn gives the count, which is then reset:

  Source: https://github.com/open-telemetry/opentelemetry-js/blob/v3.1.1/packages/sdk-trace/src/export/BatchSpanProcessorBase.ts

  >       if (this._droppedSpansCount === 0) {
  >         diag.debug('maxQueueSize reached, dropping spans');
  >       }

  >       // some spans were dropped, log once with count of spans dropped
  >       diag.warn(
  >         `Dropped ${this._droppedSpansCount} spans because maxQueueSize reached`
  >       );

- Inferred: if no span is accepted after the drops, as at shutdown, the Warn is never written.
- Log records are dropped with a metric and no log.
- A failed span export on the export timer goes to the global error handler, which by default logs it at error through `diag`. On `forceFlush` and shutdown the failure is returned to the caller instead.

  Source: https://github.com/open-telemetry/opentelemetry-js/blob/v3.1.1/packages/sdk-trace/src/export/BatchSpanProcessorBase.ts

  >           globalErrorHandler(e);

  Source: https://github.com/open-telemetry/opentelemetry-js/blob/v3.1.1/packages/opentelemetry-core/src/common/logging-error-handler.ts

  >     diag.error(stringifyException(ex));
- The `diag` logger is a no-op until the application sets one. Since pull request #6668, `startNodeSDK()` sets a console logger at INFO by default. At `v3.1.1` it is deprecated and delegates to `startNodeSdk()`, which also defaults to INFO.

**Stated why.** By the pull request's author, a contributor (#3610, merged 2023). The review discussed the onset line:

Source: https://github.com/open-telemetry/opentelemetry-js/pull/3610

> The current JS SDK does not provide any sort of indication that the batch span processor is dropping spans, resulting in difficult to identify missing spans.

> Adds diagnostic logging when spans begin and stop being dropped.

> This change only adds diagnostic logging with minimal logic to prevent flooding diagnostic logs, which is not externally visible.

> An alternate would be to add a private event emitter that would emit an event any time a span were dropped, allowing the consumer to subscribe and perform whatever action they deemed appropriate in reaction. However, this would require changing the publicly exposed API, so the diagnostic logging mechanism is utilized instead.

Source: https://github.com/open-telemetry/opentelemetry-js/pull/3610#discussion_r1113714666

> This debug diagnostic can be used to identify at what time those drops started.

> It's recorded as debug, which should be able to be filtered out if debug diagnostics aren't interesting or desired.

> I found it useful as there are two knobs that can be adjusted to prevent dropping spans: queue size and the export interval. The warning message makes it easier to adjust the queue size, but the debug message can make it apparent how often one should be exporting if they don't want to carry a larger memory load associated with a larger queue.

No stated rationale was found for the no-op default. Searched pull requests #1880 and #1925, `doc/contributing/diag-logging.md`, `api/README.md`, and the history of `api/src/api/diag.ts`.

**Constraints.** JavaScript has no standard logging facade, and `diag` is a single global.

**Costs and dissent.** A member in review thought the Debug onset "_very_ chatty":

Source: https://github.com/open-telemetry/opentelemetry-js/pull/3610#discussion_r1113585093

> This will be _very_ chatty in a system overloaded enough to be dropping spans.

### L9. sentry-python: nothing in the host log by default, a count to Sentry

**What it does.** Read at `3.0.0`.

- A full transport queue writes no log line. It records a lost event, which the SDK reports to Sentry itself as a client report, aggregated by category and reason. Client reports are on by default. No timer sends one. A pending report is attached to the next envelope sent once 30 s have passed since the transport last checked, and is sent as an envelope of its own after a send once 60 s have passed. Each check that passes the time test restarts the clock, even when there is nothing to report. `flush` with a positive timeout queues a report that skips the time test, but ignores whether the worker accepted it, so a full queue can lose it. A timeout of 0 queues nothing:

  Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/transport.py

  >         if not self._worker.submit(send_envelope_wrapper):
  >             self.on_dropped_event("full_queue")
  >             for item in envelope.items:
  >                 self.record_lost_event("queue_overflow", item=item)

  >         client_report_item = self._fetch_pending_client_report(interval=30)

  >         client_report = self._fetch_pending_client_report(force=force, interval=60)

  >         if timeout > 0:
  >             self._worker.submit(lambda: self._flush_client_reports(force=True))

  >         discarded_events = self._discarded_events
  >         self._discarded_events = defaultdict(int)
  >         self._last_client_report_sent = time.time()
  >
  >         if not discarded_events:
  >             return None

  Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/worker.py

  >         except FullError:
  >             return False

- Its logger `sentry_sdk.errors` gets a `StreamHandler` at import and a filter that passes records only when `debug` is on. Inferred from the filter sitting on the logger: with `debug` off, the application's own handlers see nothing either.

  Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/debug.py

  >     _handler = logging.StreamHandler(sys.stderr)

- Version `1.0.0` logged a full queue at ERROR on every occurrence. Pull request #1100 (2021) removed it and gave no reason.

**Stated why.**

- For the debug gate, a collaborator on the repository:

  Source: https://github.com/getsentry/sentry-python/issues/5426#issuecomment-3915351255

  > As a library we have to be very mindful of our footprint on people's apps, and logging too much by default can be problematic since e.g. a single network hiccup could then blow up people's logging bills.

  The comment answers an issue about a failing hook. It states the SDK's policy for its diagnostics in general, and the history behind it:

  > (This is not a made-up example, something like this has happened and is one of the reasons why we've made the decision to not log unless absolutely necessary.)

- For client reports, Sentry's developer documentation:

  Source: https://develop.sentry.dev/sdk/telemetry/client-reports/

  > SDKs might drop events in several places — transport queue overflow, rate limit backoff, sampling, before_send, event processors — and this loss can be invisible to a customer.

**Constraints.** The SDK sends to its own service, which can display the counts. A host that does not use Sentry's service sees none of them.

**Costs and dissent.** A user went months without knowing a hook was failing:

Source: https://github.com/getsentry/sentry-python/issues/5426

> We went **3 months** with zero visibility because there was **no way to know** the hook was crashing.

### L10. urllib3: every occurrence, and only a `NullHandler`

**What it does.** Read at `2.8.0`.

- A `NullHandler` on the `urllib3` logger, and an opt-in helper that adds a stream handler:

  Source: https://github.com/urllib3/urllib3/blob/2.8.0/src/urllib3/__init__.py

  > logging.getLogger(__name__).addHandler(NullHandler())

  So in a host that has configured no logging, its warnings are not shown. The Python HOWTO says what a do-nothing handler does:

  Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst

  > This avoids the message being printed, since a handler
  > will always be found for the library's events: it just doesn't produce any
  > output.

- A connection returned to a full pool is discarded, and a WARNING is logged every time, with no throttle:

  Source: https://github.com/urllib3/urllib3/blob/2.8.0/src/urllib3/connectionpool.py

  >                     "Connection pool is full, discarding connection: %s. Connection pool size: %s",

**Stated why.** For `NullHandler`, the 2011 commit:

Source: https://github.com/urllib3/urllib3/commit/93b3472d9c471538b0837b0fd2cb962ce2901e3c

> Properly silence the logger by default, using NullHandler.

No stated rationale was found for warning every time. Searched the blame of `connectionpool.py`, and pull request #2470, which added the pool size to the message.

**Constraints.** urllib3 is a dependency of many other libraries, so its logger often sits in an application that never chose it.

**Costs and dissent.** An open issue by a user, and an open pull request, would warn once per pool and move later records to debug:

Source: https://github.com/urllib3/urllib3/issues/3167

> The warning only really needs to be displayed once (per pool), and future logs could probably be debug-level. Reducing the verbosity of logging will make it more informative and less likely to be ignored.

### L11. OpenTelemetry Collector: sampling by level and message

**What it does.** Read at `v0.166.0`, with zap `v1.28.0`.

- Every log the Collector writes about itself goes through zap's sampler, on by default: per level and message, the first 10 in each 10 s pass, then one in 100. Nothing records what was sampled out. Counters are kept 4,096 per level and chosen by a hash of the message, so two messages can share one, and a message seen for the first time can be sampled out.

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/service/telemetry/otelconftelemetry/factory.go

  > 				Enabled:    true,
  > 				Tick:       10 * time.Second,
  > 				Initial:    10,
  > 				Thereafter: 100,

  Source: https://github.com/uber-go/zap/blob/v1.28.0/zapcore/sampler.go

  > // Zap samples by logging the first N entries with a given level and message
  > // each tick. If more Entries with the same level and message are seen during
  > // the same interval, every Mth message is logged and the rest are dropped.

  > 	_countersPerLevel = 4096

  > 	j := fnv32a(key) % _countersPerLevel

- A request refused by a full queue is logged at Error, with the count of rejected items, through that sampler:

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/internal/base_exporter.go

  > 		be.Set.Logger.Error("Exporting failed. Rejecting data."+be.ExportFailureMessage,

  The message does not change with the reason, which is in an error field, so a rejection by a full queue shares its counter with the same exporter's other rejections.

**Stated why.** The configuration's own comment, then two pull requests by members (#2020, 2020; #9282, 2024):

Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/service/telemetry/otelconftelemetry/config.go

> // LogsSamplingConfig sets a sampling strategy for the logger. Sampling caps the
> // global CPU and I/O load that logging puts on your process while attempting
> // to preserve a representative subset of your logs.

Source: https://github.com/open-telemetry/opentelemetry-collector/pull/2020

> All logging is heavily sampled to avoid flooding the logs.

Source: https://github.com/open-telemetry/opentelemetry-collector/pull/9282

> 1. Ensure an error message is logged every time and only once when data is dropped/rejected due to export failure.

The project's coding guidelines prefer a metric for frequent events:

Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/docs/coding-guidelines.md

> For such high-frequency events
> instead of logging consider adding an internal metric and incrementing it when
> the event happens.

**Constraints.** The Collector is its own host: a separate process that owns its logger and handles many thousands of items a second.

**Costs and dissent.** A member, reviewing the change that made sampling global and on by default (#8134, 2023):

Source: https://github.com/open-telemetry/opentelemetry-collector/pull/8134#discussion_r1308565674

> I do not think merely passing a single sampled logger to every component to be used for every message is good enough since it can result in critical one-off messages being lost.

The Collector's documentation also lists, as events it logs, both when dropping begins and when it stops. The page names no version. At `v0.166.0` the memory limiter logs such a pair, with no count: a Warn when it starts refusing data, and an Info when a check that starts below its soft limit follows refusal. It enters and leaves refusal on the one soft-limit test. When a forced GC brings memory below that limit within the same check, it reports the change through component status and writes no Info. The exporter queue in the table logs each rejection and no stop. The project's own observability document lists start and stop events among the aspects that "need to be observable":

Source: https://opentelemetry.io/docs/collector/internal-telemetry/

> Data dropping begins due to throttling for a specified reason, such as local
> saturation, downstream saturation, downstream unavailable, etc.
> Data dropping due to throttling stops.

Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/internal/memorylimiter/memorylimiter.go

> 		ml.logger.Warn("Memory usage is above soft limit. Refusing data.", memstatToZapField(ms))

> 			ml.logger.Info("Memory usage back within limits. Resuming normal operation.", memstatToZapField(ms))

> 	return ms.Alloc >= d.memAllocLimit-d.memSpikeLimit

> 		// GC brought memory back within limits in this same tick — report OK immediately.

Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/docs/observability.md

>   - For start or stop events, an appropriate hysteresis must be defined to avoid
>     generating too many events.

### L12. Vector: a rate limit per call site and component

**What it does.** Read at `v0.62.0`.

- A layer over its `tracing` output, on by default: per call site and component, the first event in a 10 s window passes, the second is replaced by a notice that suppression has begun, and the rest are silent. If the window saw a second event, the next event after it brings a count first, and the count includes the event the notice replaced. It counts suppressed log records, not the events they reported: a suppressed drop record's own count of dropped events is not carried into it.

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/tracing-limit/src/lib.rs

  > //! Within each rate limit window (default 10 seconds):
  > //! - **1st occurrence**: Event is emitted normally
  > //! - **2nd occurrence**: Emits a "suppressing" warning
  > //! - **3rd+ occurrences**: Silent until window expires
  > //! - **After window**: Emits a summary of suppressed count, then next event normally

  > //! window expiry itself. If the event stops firing, no summary is ever emitted.

  >             if previous_count > 1 {

  >                     "Internal log [{}] has been suppressed {} times.",

  The notice and the count are built from the original event's metadata, so they carry its level, not a fixed warning. An event whose metadata has neither a `message` nor an `internal_log_rate_limit` field gets neither.

  >             let event = Event::new(metadata, &valueset);

  >             // If the event metadata has neither a "message" nor "internal_log_rate_limit" field,

- Unintended dropped events are logged at error, as an internal event type with a count field, whose name is not on the record. Intended drops are logged at debug.

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/vector-common/src/internal_event/component_events_dropped.rs

  >         let message = "Events dropped";

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/vector-common/src/internal_event/mod.rs

  > #[cfg(not(any(test, feature = "test")))]
  > pub fn emit(event: impl InternalEvent) {
  >     event.emit();
  > }

- **A full buffer** blocks by default, and loses nothing. Only with `when_full` set to `drop_newest` does it drop. Then a reporter task checks every 2 s and, when the count has changed, emits a `BufferEventsDropped` event with the delta, at debug. An unintended drop of unprocessable events is the same event at error. On Vector's standard output and error, the event then passes through the same level filter and rate limiter as every other. The `internal_logs` source, which feeds Vector's own pipeline, applies the level filter and no rate limit unless `--internal-logs-source-rate-limit` is set. The 2 s is the reporter's tick, not how often a line reaches the log. At the default level, info, the debug line is not shown.

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/vector-buffers/src/lib.rs

  >     /// Wait for free space in the buffer.

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/vector-buffers/src/buffer_usage_data.rs

  >     /// Reports usage for the given stages every 2 seconds until they have all been dropped.

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/lib/vector-buffers/src/internal_events.rs

  >         if self.intentional {
  >             debug!(
  >                 message = "Events dropped.",

  Source: https://github.com/vectordotdev/vector/blob/v0.62.0/src/trace.rs

  >             RateLimitedLayer::new(formatter).with_default_limit(internal_log_rate_limit);

  >     // The broadcast layer feeds the internal_logs source. By default it is NOT rate limited so

**Stated why.** Both by contributors: issue #418 (2019) and pull request #971 (2019).

Source: https://github.com/vectordotdev/vector/issues/418

> In this case, we should be logging an event at the `warn` level that is rate limited. Failing to rate limit could saturate IO and bring Vector to a halt.

Source: https://github.com/vectordotdev/vector/pull/971

> The primary reason for including this is for events that may be important for a user to see but may arrive in large bursts. This can cause issues around saturating IO and in general making it difficult to diagnose the issue.

For turning the limiter on by default, a member, in issue #22410 (2025):

Source: https://github.com/vectordotdev/vector/issues/22410

> This is opens up the possibility of forgetting to add this tag. Instead, we should just opt-in when we want to output every single event with `internal_log_rate_limit = false`.

**Constraints.** Vector is its own host, a separate process on the data path.

**Costs and dissent.**

- Keyed only on the call site, errors in one component masked another's, so the key gained the component. A contributor:

  Source: https://github.com/vectordotdev/vector/pull/6563

  > This causes problems when sharing code across components as errors in one component could mask errors in another.

- The default-on change was reverted for bugs, then restored (#22899, #23566, #24024).

---

## Comparables that chose otherwise

Against "the onset once, then a total at the end", with the reason each gave where one was given:

- **A rate limit, with the count on the next record:** ddtrace (L1), the kernel (L4), and Vector (L12) for a drop it did not intend. A full Vector buffer reports a count every 2 s at debug, and only with `drop_newest`. Their stated reason is keeping errors visible without flooding: "surfaced to the user without overloading their logs" (ddtrace), "saturate IO and bring Vector to a halt" (Vector). Each writes the suppressed count only when the next record arrives.
- **A count once per export cycle:** OTel Java's span processor (L2), whose stated reason is that a count shows "how severe the backpressure is" and is "naturally throttled by the export cycle"; and OTel Go's log processor (L6), with no stated reason for the cycle.
- **Every occurrence:** OTel Python (L3) and urllib3 (L10), each with no stated reason for every occurrence. OTel Python's earlier once-per-processor rule was dropped with no stated reason, and urllib3 has an open proposal to warn once.
- **A total at shutdown with no onset:** OTel .NET (L7), the precedent OTel Rust cites. Its author's reason is "to let users know somehow that we are dropping items".
- **The onset, then the total when it stops:** OTel JS (L8). Its author's stated reason is that, without it, the SDK gave no "indication that the batch span processor is dropping spans". The total helps size the queue. The onset's time helps set the export interval for someone who does not "want to carry a larger memory load associated with a larger queue". The onset is at Debug, so a default configuration does not show it. The OTel specification's performance principle names the same two moments, "when information loss starts and when recovered" (G3). It asks for a warning at each, asks for no count, and no rationale was found for it.
- **Sampling with no count:** the Collector (L11), to cap "the global CPU and I/O load".
- **Nothing in the host's log, a count sent elsewhere:** sentry-python (L9). For logging nothing by default, a collaborator gives the SDK's general policy, "to not log unless absolutely necessary", because "a single network hiccup could then blow up people's logging bills". For the count, Sentry's developer documentation says the loss "can be invisible to a customer". Neither source says why the count goes to Sentry instead of the host's log.

## Additions outside the count

Read during the work, after the count was fixed. Not counted.

### A1. dd-trace-go: an aggregate 60 s after the first error

Read at `v2.12.0`. `log.Error` aggregates records by format string. The first error after a quiet period starts a 60 s timer, configurable by `DD_LOGGING_RATE`. When the timer fires, it writes one line per format string at Error, with the first occurrence's text, the count of the rest and the time of the first. Past 200 the count stops and the line says "200+". `Flush` writes the aggregate at once, and a rate of 0 writes each error at once. So the first occurrence is not written when it happens, nothing is written in a minute with no error, and an exact count above 200 is lost.

Source: https://github.com/DataDog/dd-trace-go/blob/v2.12.0/internal/log/log.go

> // Error reports an error. Errors get aggregated and logged periodically. The
> // default is once per minute or once every DD_LOGGING_RATE number of seconds.

> 		time.AfterFunc(errrate, Flush)

> const defaultErrorLimit = 200

> 			extra = fmt.Sprintf(", %d+ additional messages skipped (first occurrence: %s)", defaultErrorLimit, report.first.Format(time.RFC822))

**Stated why**, from pull request #442 (2019). A reviewer, a contributor, asked for the first occurrence at once. The author, also a contributor, kept the aggregate, citing an internal RFC:

Source: https://github.com/DataDog/dd-trace-go/pull/442#discussion_r287197026

> I think the first occurrence of an error needs to be reported, then additional ones counted and eventually flushed.

> Assuming the logger emits timestamps, that gives at least one useful timestamp to look at when troubleshooting.

Source: https://github.com/DataDog/dd-trace-go/pull/442#discussion_r287243933

> I've implemented this based on our internal RFC:
> > Tracer loggers should all default rate limiting to 1 unique message per 60 seconds.

> However, I think that doing it as you suggest will create a bad user experience and confusion because the user will see an error message and then the rest will be suppressed without a hint at the fact that there are more error messages being aggregated in the background.

> * Flushing all messages when the tracer stops.

### A2. log4j2: warn once per policy instance, and a total at shutdown at TRACE

Read at `rel/2.26.1`. `DiscardingAsyncQueueFullPolicy` is opt-in. The default policy discards nothing: it enqueues the event, or logs it synchronously when the caller is a log4j thread. `log4j2.AsyncQueueFullPolicy=Discard` selects this one. When the queue is full, it discards events at or below a threshold level, INFO by default. Its counter belongs to the policy instance and is never reset, so it warns to the status logger on the first discard of the instance's life only, whatever the message says about capacity returning. Each async logger disruptor creates its own instance. When the disruptor shuts down, it logs that instance's total at TRACE to the status logger. Inferred from the status logger's default fallback level, ERROR: a default configuration shows neither the warning nor the total.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/async/DiscardingAsyncQueueFullPolicy.java

>                         "Async queue is full, discarding event with level {}. "
>                                 + "This message will only appear once; future events from {} "
>                                 + "are silently discarded until queue capacity becomes available.",

>     private final AtomicLong discardCount = new AtomicLong();

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/async/AsyncQueueFullPolicyFactory.java

>  * Property {@code "log4j2.AsyncQueueFullPolicy"} controls the routing behaviour. If this property is not specified or has
>  * value {@code "Default"}, this factory creates {@link DefaultAsyncQueueFullPolicy} objects.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/async/AsyncLoggerDisruptor.java

>             LOGGER.trace(
>                     "AsyncLoggerDisruptor: {} discarded {} events.",

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-api/src/main/java/org/apache/logging/log4j/status/StatusLogger.java

>     static final Level DEFAULT_FALLBACK_LISTENER_LEVEL = Level.ERROR;

In the discussion that led to it, LOG4J2-1080 (2015), one commenter asked for a start and a stop event, and the reporter, who attached the first patch, agreed. The policy that shipped was written later by another participant. No stated rationale was found for logging only the start. The issue was read through Jira's REST API.

Source: https://issues.apache.org/jira/browse/LOG4J2-1080

> - it logs some kind of start and stop discarding event so the log reader will know where information is missing.

> 2. Discard logging start and stop is a good idea, and will be easy to add.

### A3. Others read briefly

- **Logback `AsyncAppender`** (`v_1.6.8`) drops silently, with no status message, on both its discard paths. Inferred from `AsyncAppenderBase`, where the result of `offer` is ignored.
- **Elastic APM Python** (`v6.26.3`) logs every dropped event at debug. No stated rationale found, not searched beyond the file.
- **Honeycomb libhoney-go** (`v1.27.1`) logs every overflow to a logger that is a no-op by default.
- **librdkafka** (`v2.16.0`) reports statistics through a callback the application registers, off by default, not through a log.
- **Fluent Bit** (`v5.2.0`) counts dropped records in metrics. When a chunk's retries are exhausted, it also logs an error for that chunk.

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/src/flb_engine.c

  >             flb_error("[engine] chunk '%s' cannot be retried: "
- **CPython `QueueHandler`** (`v3.14.10`) passes every failed enqueue to a full bounded queue to `Handler.handleError`. That prints a traceback to standard error while `logging.raiseExceptions` is true, its default, and `sys.stderr` is set.

  Source: https://github.com/python/cpython/blob/v3.14.10/Lib/logging/__init__.py

  >         if raiseExceptions and sys.stderr:  # see issue 13807

## Facts about a killed pod

These bear on what a total at the end can reach. They are facts about the platform and the runtimes, not comparables.

- **Graceful termination.** If a container defines a `preStop` hook, the kubelet runs it first. The runtime then sends the stop signal: typically TERM, or the image's `STOPSIGNAL` where it sets one. A stop signal set in the container's lifecycle is alpha and off by default. After the grace period, 30 s by default and shared with the hook, it sends SIGKILL. The stop signal goes to the main process in each container. If a `preStop` hook is still running when the grace period ends, the kubelet extends it once, by 2 s.

  Source: https://kubernetes.io/docs/concepts/workloads/pods/pod-termination/

  > The default terminationGracePeriodSeconds setting is 30 seconds.

  > The container runtime sends SIGKILL to any processes still running in any container in the Pod.

  > to the main process in each container.

  > Many container runtimes respect the STOPSIGNAL value defined in the container image and,
  > if different, send the container image configured STOPSIGNAL instead of TERM.

  > If one of the Pod's containers has defined a preStop
  > hook and the terminationGracePeriodSeconds
  > in the Pod spec is not set to 0, the kubelet runs that hook inside of the container.

  > If the preStop hook is still running after the grace period expires, the kubelet requests
  > a small, one-off grace period extension of 2 seconds.

- **Node-pressure eviction.** Hard eviction allows no grace period.

  Source: https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/

  > A hard eviction threshold has no grace period. When a hard eviction threshold is
  > met, the kubelet kills pods immediately without graceful termination to reclaim
  > the starved resource.

  In the kubelet at `v1.36.0`, a hard eviction passes a grace period of 1 s, and the kubelet raises any grace period under 2 s to 2 s before asking the runtime to stop the container. containerd `v2.2.0` sends the stop signal first and SIGKILL when that time is up. Other runtimes were not checked.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.36.0/pkg/kubelet/eviction/eviction_manager.go

  > 	immediateEvictionGracePeriodSeconds = 1

  Source: https://github.com/kubernetes/kubernetes/blob/v1.36.0/pkg/kubelet/kuberuntime/kuberuntime_manager.go

  > 	// A minimal shutdown window for avoiding unnecessary SIGKILLs
  > 	minimumGracePeriodInSeconds = 2

  Source: https://github.com/containerd/containerd/blob/v2.2.0/internal/cri/server/container_stop.go

  > 		// sigTermCtx was exceeded. Send SIGKILL

- **An OOM kill.** The kernel's OOM killer sends SIGKILL. No kubernetes.io page found says so; the kernel source does.

  Source: https://github.com/torvalds/linux/blob/v7.3/mm/oom_kill.c

  > 	do_send_sig_info(SIGKILL, SEND_SIG_PRIV, victim, PIDTYPE_TGID);

  Source: https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

  >      reason: OOMKilled

- **SIGKILL cannot be handled**, so no code in the process runs.

  Source: https://man7.org/linux/man-pages/man7/signal.7.html

  > The signals SIGKILL and SIGSTOP cannot be caught, blocked, or ignored.

  (line breaks collapsed)

- **SIGTERM, unhandled, ends the process, unless the process is its PID namespace's init, as a container's main process is unless the pod shares its process namespace.** Its default action is to terminate. But a signal from an ancestor namespace reaches init only if init has a handler for it, SIGKILL and SIGSTOP excepted. So a host that is its namespace's init and handles no TERM keeps running until SIGKILL.

  Source: https://man7.org/linux/man-pages/man7/pid_namespaces.7.html

  > a process in an ancestor namespace can—subject to the usual permission checks described in kill(2)—send signals to the "init" process of a child PID namespace only if the "init" process has established a handler for that signal.

  (line breaks collapsed)

  Source: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

  > The container process no longer has PID 1.

  - Python installs no SIGTERM handler, and its exit handlers do not run when a signal it does not handle kills it:

    Source: https://docs.python.org/3.15/library/signal.html

    > A small number of default handlers are installed: SIGPIPE is ignored (so write errors on pipes and sockets can be reported as ordinary Python exceptions) and SIGINT is translated into a KeyboardInterrupt exception if the parent process has not changed it.

    (line breaks collapsed)

    Source: https://docs.python.org/3.15/library/atexit.html

    > Exit handlers are not called when the program is killed by a signal not handled by Python, when a Python fatal internal error is detected, or when os._exit() is called.

    (line breaks collapsed)

  - Rust's standard library is not documented to install a SIGTERM handler. Inferred from signal(7)'s default action: an unhandled SIGTERM ends the process without unwinding, so no destructor runs. The standard library's documentation states the same for `exit`:

    Source: https://doc.rust-lang.org/std/process/fn.exit.html

    > Note that because this function never returns, and that it terminates the process, no destructors on the current stack or any other thread’s stack will be run.

    (line breaks collapsed)

  Inferred from the above: a total still pending when the pod is told to stop is written only if the host ends establish before SIGKILL arrives. On a graceful termination, that means the host acts on the stop signal, or a `preStop` hook leads it to shut down in order, within the grace period. Once SIGKILL is sent, nothing more runs in that process and the pending total is never written. SIGKILL is sent at the end of the grace period; at a hard eviction, about 2 s after the stop signal, with containerd; and at once when the OOM killer picks the host's own process.

## Candidates not examined, or dropped

- **Not examined, as fixed before reading:** librdkafka's own log rate limiting, Fluent Bit's own log, botocore, gRPC, and log4j's `BurstFilter`. librdkafka and Fluent Bit were then read briefly for their statistics (A3), not their logging.
- **Not checked:** the Datadog agent, Go's `slog`, and the dropped statistics of Elastic APM agents other than Python's.
- **Read only in part:** the comment threads of OTel Python issue #4261, OTel Java issue #7178, and Vector issues #22410 and #23566.

## Fit

### The constraints of this client

Each is cited for what it is: a settled promise of the specification, the maintainer's standing guidance, or a leaning.

- **In-process, inside a host application.** Settled by the specification's shape: the client is a library the host calls. The host owns the process and its logging.
- **The client never harms the host.** Standing guidance: a queue is bounded and never blocks the worker. Logging that floods the host's logs, or that adds load when the host is already overloaded, is a harm of this kind.
- **One behaviour for Rust and Python.** Standing guidance.
- **Two channels.** Settled in the proposal, while the register's entry on how the client reports its own failures stays open: the guarantee `TwoChannels` says the client reports on itself through the diagnostics snapshot and the host's logs, and nothing else. The snapshot exposes the latest run's counters, by table and kind, at any time, so the log is not the only place a count can be read. That it describes the most recent run, and keeps describing it after that run has ended, is marked "Derived" in the specification.
- **Six kinds of failure, all under one rule.** Settled in the proposal: `FailureKind` is `queue_full`, `oversize`, `invalid`, `store_failed`, `shutdown` and `tenant_dropped`, and the rules apply onset-then-total to each, keyed on one kind for one table within one run.
- **Ephemeral pods.** A leaning, not a fact: the most common host is "an ephemeral cloud environment such as a Kubernetes worker pod". A process may also live for days.
- **Not novel.** The maintainer's guidance on this topic: "we should generally follow best practice and do what most other frameworks and libraries do. We shouldn't be novel here".
- **The onset matters.** The maintainer's own reasoning, not a comparable's: "the moment some sort of failure starts to happen, we should probably log as it's more likely to go through".

### Fit of each comparable

- **G1, the Python logging documentation.** Its reasons, that handlers are "the prerogative of the application developer" and that a library's handlers "might well interfere" with the developer's tests and logs, hold for this client. It is an in-process library, and the host owns its logging. The HOWTO also regards printing WARNING and above to standard error, when the application has configured nothing, as "the best default behaviour". A library that adds a `NullHandler` gives that up, as urllib3 does (L10). The specification says only "installs no handlers", which leaves `NullHandler` unsaid.
- **G2, the Rust `log` and `tracing` crates.** Their reasons, that a global default set by a library "will cause conflicts" with the executable's, and that the max level features should be avoided "because they're global and can't be changed", hold for this client. But neither crate is the language's standard facade, because Rust has none, and a record sent through one reaches the other only through a feature of `tracing` or a compatibility layer, each chosen by the build or the executable. The phrase "the language's standard logging facade" names nothing definite for Rust.
- **G3, the OpenTelemetry specification.** Its reason for logging instead of failing, that users "would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application", holds: it is the same posture as this client's promise never to harm the host. Its one sentence on lost data asks for a warning "when information loss starts and when recovered". No rationale for that sentence was found.
- **L1, ddtrace.** Its reason, "do not spam user's application logs", holds. Its key, a call site, and its count, carried on the next record, are Python-specific mechanisms that a Rust core would have to reproduce. Its handler, added at import, is the practice G1 advises against.
- **L2, OpenTelemetry Java.** The reason for its count per export, that it shows "how severe the backpressure is" and is "naturally throttled by the export cycle", holds where the client has a cycle. The client's data writer takes batches, but the specification gives it no export interval. The member's question, whether a log should "duplicate" what a metric shows, holds too, because the client has its snapshot.
- **L3, OpenTelemetry Python.** Its reasons concern recursion when the SDK's own log feeds its own pipeline. That holds for this client only if a host routes the client's log records back into the client as rows, which nothing in the specification does.
- **L4, the Linux kernel.** Its reason, making "a denial-of-service attack impossible" on a shared kernel log, does not hold. The client is not a kernel, and only the host's own writes reach it.
- **L5, OpenTelemetry Rust.** Its stated reason, "We certainly don't want to log each time the buffer is full", with keeping a count as "A good balance", holds for the client's `queue_full`. Its design gives no reason for logging that count at shutdown rather than earlier. Its constraint that the count is "best exposed as an internal metric" holds too, through the client's snapshot, with one difference: at the tag read, OTel Rust's self-diagnostics metrics need a feature that is not enabled by default, so by default its log is the only place its count appears. Four things do not hold:
  - it applies the rule to a full queue only, and logs every failed export at ERROR, while the specification applies the rule to `store_failed` as well;
  - its key is a processor's lifetime, while the client's is a table and a kind within one run;
  - no reason is stated for logging its onset at the first drop, beyond "informing the user about data drop";
  - its total is a snapshot taken when shutdown begins and counts nothing dropped after it, while the specification's is written when the run has ended and counts every occurrence until then.
- **L6, OpenTelemetry Go.** Its member's reason against a Warn on every drop, that logging "may exacerbate that load", holds. Its default of showing only errors, which a user calls "nearly impossible to understand", is the cost of a level the host does not see.
- **L7, OpenTelemetry .NET.** Its reason, "to let users know somehow that we are dropping items", holds. Its channel, `EventSource`, is a .NET runtime mechanism and has no counterpart in Rust or Python.
- **L8, OpenTelemetry JS.** Its reasons hold in part. A count at recovery helps size a queue, and the client's tables have a capacity. An onset gives the time drops started, which holds for troubleshooting; the use its author gave for that time, judging "how often one should be exporting", needs an export interval, which the specification does not give the client's data writer (see L2). Its onset at Debug is not shown by default, which its author chose so that it "should be able to be filtered out". Its end of an episode, "a span is received that is successfully enqueued", is a definition of "stopped" for a full queue.
- **L9, sentry-python.** Its reason for logging nothing by default, a "network hiccup could then blow up people's logging bills", holds as a cost. Its alternative, sending the count to its own service, does not exist for this client, whose only other channel is the snapshot.
- **L10, urllib3.** No reason is stated for logging every discarded connection. Its `NullHandler` follows G1.
- **L11, the OpenTelemetry Collector, and L12, Vector.** Their reasons, capping the "global CPU and I/O load that logging puts on your process" and not letting logging "saturate IO", hold as costs to avoid. Each is its own host, though, and owns its logger, so a sampler or a rate-limiting layer is configuration it can impose. A library cannot impose one on its host's logger.

## Is the rule common?

**It is one library's rule.** Of the twelve libraries read, one, OpenTelemetry Rust (L5), logs the first occurrence at once, nothing more while it continues, and one total at the end: a snapshot taken when its processor's shutdown begins. It does so for one kind of failure, a full queue, in its default processors. Of the nine in-process libraries, the same one does. No library among the twelve applies the rule to a failed store or export, and none holds a failed export back for a total. Each that reports one does so when it happens, on every occurrence or through a rate limit, duplicate filter or sampler, or returns it to the caller, as OTel Go does on flush and on its log processor's shutdown.

Each library was tested on the three parts of the rule. Two more of the twelve have two of the three parts:

- **OpenTelemetry .NET (L7)** logs nothing while drops continue and one total at shutdown, but no onset. OTel Rust cites it as the precedent.
- **OpenTelemetry JS (L8)** logs an onset and nothing more, but the onset is at Debug, and its total comes when drops stop, not at the end.

Outside the count, log4j2 (A2) has all three parts, at levels a default configuration does not show: a WARN to its status logger on the first discard, and a TRACE total at shutdown.

What the other nine do, for lost data:

| Rule | Libraries | Of the 9 in-process |
| --- | --- | --- |
| A rate limit, with the count on the next record | ddtrace, the kernel, Vector (a drop it did not intend) | 1 |
| A count per export cycle | OTel Java (spans), OTel Go (log records, hidden by default) | 2 |
| Every occurrence, or every occurrence through a duplicate filter | OTel Python, urllib3 | 2 |
| Sampling, with no count | the Collector | 0 |
| Nothing in the host's log by default | sentry-python | 1 |

Vector is placed by a drop it did not intend. Placed by its full buffer, which drops only with `drop_newest`, it would be a count every 2 s at debug. It is not an in-process library, so the last column does not change.

No rule is used by a majority, and neither is the elicitation's general description. Two elements are each shared by some:

- **the first occurrence logged when it happens:** counted, as the summary table's "At once" is, by a call at a level the facade passes by default: ddtrace, OTel Python, the kernel, OTel Rust, urllib3, the Collector and Vector for a drop it did not intend, seven of the twelve, or six with Vector counted by its full buffer; and four of the nine in-process libraries. Counted by the call alone, whatever its level, OTel JS's Debug onset makes it eight of the twelve, or seven, and five of the nine. For ddtrace, OTel Python and the Collector it holds unless a shared rate limit, filter or sampling counter is already spent: ddtrace's writer logs its warnings through one helper, so they share one 60 s bucket (L1, inferred);
- **something that limits repeats:** every library but urllib3. OTel Python's filter passes any record that differs from the last one it passed, and OTel JS writes a pair of records for each episode, with no limit on the number of episodes.

Both together, the elicitation's "the first occurrence logged at once, then throttled", describe ddtrace, OTel Python, the kernel, OTel Rust, the Collector and Vector for a drop it did not intend: six of the twelve, or five with Vector counted by its full buffer, and three of the nine in-process libraries. Its claim about OTel Rust is accurate for a full queue. It does not claim that the chosen rule is common practice. It records the rule as OTel Rust's and, separately, as the maintainer's choice, and on the evidence read the rule is not common.

**The claim "Separate periodic summary logs are uncommon" gets its final status here: confirmed, with a qualification.** Two of the nine in-process libraries make a call that writes a count on a cycle into the host's log: OTel Java's span processor, at WARNING, before each non-empty export, and OTel Go's log processor, at each worker wake, whether or not there is a batch, through a `Warn` helper its default logger hides. Counted, as the onset is, by a call at a level the facade passes by default, one does: OTel Java. Two write a total at the end: OTel .NET, through `EventSource`, which writes nothing until configured, and OTel Rust, after an onset. Outside the in-process libraries, a full Vector buffer with `drop_newest` reports a count every 2 s at debug (L12). Neither practice is common among the libraries read.

## What the rule costs

This section describes. It weighs nothing against the maintainer's choice.

**Between the onset and the total.** For a kind of failure on a table, an operator reading the host's log sees one record at the onset, then nothing until establish ends. In a process that lives for days, the log alone cannot tell the operator any of these:

- whether the failure is still happening, stopped an hour later, or stopped and came back. A second episode of the same kind on the same table within one run opens no new onset, because the episode stays open until establish ends;
- how many rows have been lost so far;
- whether another kind, or another table, is the cause of what they see now. Each of those has its own onset, so this one at least is visible.

The snapshot (`TwoChannels`) answers the second at any moment, since `RunDiagnostics` exposes each table's counters by kind, and it gives the counts behind the third. It answers the first only in part. One read shows the counts so far and some current state, such as `queued_now` against the table's capacity, `last_store_at` and the data writer's status, but not when a count last grew: a failure still happening, one that stopped an hour ago, and one that stopped and came back can leave the same counts. A host that reads the snapshot more than once can see whether a count grew between two reads that show the same `run.id`. So the whole cost falls on an operator who reads only the log, and its first part also on one who reads the snapshot once. Four comparables state this cost or its remedy:

- the OTel Java contributor who asked for a count per batch, because a log of the first few drops shows "_that_ spans were being dropped, but not how bad the problem is" (L2);
- the dd-trace-go author, who rejected an onset followed by silence because the user would "see an error message and then the rest will be suppressed without a hint" (A1). OTel Rust's onset record answers that hint in its own text: "No further log will be emitted for further drops until Shutdown";
- the OTel Go user for whom drops shown at a level they did not enable were "nearly impossible to understand" (L6);
- the Collector member who warned that a single sampled logger can lose "critical one-off messages" (L11).

**What a killed pod never logs.** The total is written when establish ends. Under the facts above ("Facts about a killed pod"):

- **SIGKILL.** A host whose process receives SIGKILL never writes the total of any episode still open. SIGKILL comes at the end of the grace period; at a hard eviction, about 2 s after the stop signal, with containerd; and at once when the OOM killer picks the host's process. Each onset was handed to the host's logging facade when its failure began. Whether it reached a sink before the kill depends on the host's logging: a Rust host with no `tracing` subscriber drops it, unless its build enables `tracing`'s `log` feature and it sets a `log` logger (G2, L5), and, inferred, a host that buffers its log output can lose what it holds with the process.
- **An unhandled stop signal.** The stop signal goes to the main process in each container. It is TERM unless the image or the container's lifecycle sets another, which has its own default action. A host that is that process and does not handle TERM is either ended by it, when it is not its PID namespace's init, as in a pod that shares its process namespace, and then a Python host runs no exit handlers and a Rust host no destructors; or, when it is its namespace's init, it does not receive the signal and runs on until SIGKILL. Inferred: a host that runs as a child of the container's main process receives the signal only if that process passes it on. In each case, the total is not written on a graceful termination unless the host acts on the signal, or a `preStop` hook leads it to end establish, within the grace period.
- **The host's own logging may be closing.** A record written at shutdown may meet streams that are already closed. ddtrace's writer guards each of its drop records against exactly that:

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py

  >     During interpreter shutdown or when test frameworks (like pytest) close
  >     captured stdout/stderr streams, logging calls may fail with:

- **The diagnostics snapshot.** It does not survive the process either.

The onset is emitted when a failure starts, before any later kill. The total is the record a killed pod may never emit. Among the comparables that log a count before the end, the count is emitted while the process is alive only when a later event triggers it: the next record for the same key (L1, L4, L12), the next non-empty export (L2), the next worker wake (L6, hidden by default), the buffer reporter's next 2 s tick after a drop (L12, with `drop_newest` only, at debug and through the same rate limit), or, in OTel JS, the next span accepted after the drops (L8). Where no such event comes before the kill, that count is not written either. OTel .NET writes its only record inside its processor's shutdown, so it logs nothing at all for a pod killed before that record is written.

## Verdicts

### `StandardFacade`

**Verdict: it rests on a stated why that fits this client, except for one clause, WARNING for dropped tenants, which rests on no stated why.** The guarantee is judged as the specification words it now (see the section on the specification's text, above).

- No handlers, a named logger, and leaving configuration to the application are each given a reason by the guidance written for libraries: the Python documentation (G1), and the `log` and `tracing` crates (G2). Each reason holds for an in-process library in a host's process.
- Structured records have a stated purpose in `log`: they can be analysed "without needing to find and parse attributes from unstructured text first".
- WARNING for lost data has one stated reason, and two criteria, that fit:
  - an OTel Java pull request author's "dropped spans represent actual data loss, which impacts observability" (L2), given for WARNING over the INFO a reviewer proposed;
  - the Python HOWTO's row for `logger.warning`, where the client application can do nothing about the situation but the event should still be noted (G1);
  - an OTel Rust member's rule that WARN and ERROR be "user actionable or conveying some important information that they'd not know otherwise" (L5), which bounds both levels and does not choose between them.

  The OTel specification asks for a "warning log" when information loss starts and when recovered (G3), and no rationale for it was found. None of these is a project's documented rule. The Python HOWTO also has an ERROR row, for reporting the suppression of an error without raising an exception, and does not say which row applies.
- WARNING for dropped tenants has no stated why in any source read. A dropped tenant is an accepted row whose tenant was not stored, not lost data. The clause was added in ticket 02, after the elicitation's survey, and that ticket's research widened the guarantee's wording without giving a basis for the level.

The verdict is about the basis. The behaviour is unchanged. Three points the evidence raises are for the maintainer, and this file decides none of them:

- "the language's standard logging facade" has no referent in Rust, where `log` and `tracing` are both de facto facades (G2);
- "installs no handlers" leaves unsaid whether a `NullHandler` counts (G1, L10);
- the basis for WARNING on a dropped tenant, which the proposed text below states as having none.

**The basis as written today is wrong in part.** The ticket says the survey "reported this as common practice", and `CONTEXT.md` records it as "The common practice is the standard logging facade, a library-named logger, no handlers installed". "No handlers" is not what every library read does: ddtrace and sentry-python add a handler at import, and OTel Go's defaults write to standard error. The practice is the guidance's. Counted from the summary table's columns for the facade and name and for installing a handler, over the nine in-process libraries, and on those three properties only:

- three log through a standard or de facto facade, under a named logger, and add no handler: OTel Java, OTel Python and OTel Rust. urllib3 does the same but adds a `NullHandler`, which the HOWTO allows, so four do if that exception is taken;
- five add no handler of their own: those three, OTel .NET and OTel JS. With urllib3's `NullHandler`, which writes nothing, six add nothing that writes output. ddtrace and sentry-python add a `StreamHandler`, and OTel Go's default logger and error handler write to standard error.

Proposed text for that line, for the maintainer to place, since `CONTEXT.md` is not edited by this ticket:

```text
Rests on the guidance written for libraries: the Python logging HOWTO's "Configuring Logging for a Library", and the `log` and `tracing` crates' advice to libraries. Of the nine in-process libraries read for ticket 14, three log through a standard or de facto facade under a named logger and add no handler (OTel Java, OTel Python, OTel Rust), and a fourth, urllib3, adds only the NullHandler the HOWTO allows; ddtrace and sentry-python add a handler, and OTel Go writes to standard error by default. WARNING for lost data rests on one stated reason, an OpenTelemetry Java pull request author's, that dropped data is actual data loss. WARNING for dropped tenants rests on none; it was added when ticket 02's A2 was adopted.
```

### `OnsetThenTotal`

**Verdict: it rests on no stated why, as the specification applies it.** No source read gives a reason for holding the total until the end, and none for applying the rule to every kind of failure. Stated whys that fit this client support two of its parts: logging the onset at once, and, for a full queue, keeping a count instead of logging each drop. The stated whys the rule draws on, OTel Rust's, OTel .NET's, OTel JS's and the dd-trace-go reviewer's, each fit within its own scope, so the verdict is not "does not transfer": the time of the total and the extension to five more kinds have no stated why to transfer.

| Part | `queue_full` | `store_failed`, `invalid`, `oversize`, `shutdown`, `tenant_dropped` |
| --- | --- | --- |
| The onset at once | Stated, fits: OTel JS's author (L8), and a dd-trace-go reviewer, whose request that library's author declined (A1). OTel Rust gives a purpose only | Stated, fits, for errors in general: the dd-trace-go reviewer's request, declined. No other source states one |
| Nothing more while it continues | Stated, fits: OTel Rust (L5) | Not stated. OTel Rust itself logs a failed export on every occurrence |
| One total, at the end | The count: stated, fits (OTel Rust, OTel .NET). Its time: not stated | Not stated |

- **The recorded basis is in two separate records.** `CONTEXT.md` records the survey's general practice as "the first occurrence logged at once, then throttled", and, separately, "OTel Rust: onset once, total at shutdown. The maintainer chose this rule." The maintainer's note asks to "do what most other frameworks and libraries do". No record says on which basis the rule was chosen. On the evidence read it is one library's rule among the twelve (see "Is the rule common?"). The survey's description of it as what the OTel Rust SDK does is accurate.
- **OTel Rust's stated reason fits a full queue.** "We certainly don't want to log each time the buffer is full", with the count kept in a metric and logged at shutdown. The constraint behind it holds for this client, whose snapshot keeps the count.
- **That reason was stated for a full queue only, and OTel Rust does not apply it to its other failures.** OTel Rust logs a failed export on every occurrence, at ERROR, under a member's rule that a WARN or an ERROR be "user actionable". The other OpenTelemetry SDKs read report a failed export when it happens, and none holds it back for a total. OTel Java's batch processors log a failed result at FINE and a thrown exception at WARNING each time, and its OTLP exporters log through `ThrottlingLogger`. OTel Python logs an exception each time, through its duplicate filter, and its shared processor does not read the result the exporter returns. OTel Go passes a failure to its error handler each time, or returns it to the caller on flush and on log-record shutdown. OTel .NET logs one each time. OTel JS passes one to its global error handler each time on its export timer, and returns one from flush and shutdown to the caller. The specification applies onset-then-total to `store_failed`, `invalid`, `oversize`, `shutdown` and `tenant_dropped` too, and no library read gives a reason for that.
- **The onset has a stated why, though not OTel Rust's.**
  - OTel Rust's reviewer gives only its purpose, "informing the user about data drop", and no reason for logging it at the first drop.
  - OTel JS's author does: the onset shows "at what time those drops started" (L8).
  - A dd-trace-go reviewer does too: it gives "at least one useful timestamp to look at when troubleshooting" (A1).

  Each holds for this client. So does the maintainer's own reason, that the onset is "more likely to go through": under "What the rule costs", the onset is emitted when the failure starts, while the total can be lost to a kill; whether either reaches the operator also depends on the host's logging.
- **The total at the end has stated whys for keeping a count rather than logging each drop,** for a full queue: OTel Rust's "A good balance might be to keep a count of items-dropped-due-to-buffer-full", and OTel .NET's "to let users know somehow that we are dropping items". Neither states why the count waits for shutdown. OTel Rust's design lists a metric and a log "upon shutdown/drop" as outputs (L5), and OTel .NET's author floated a log "every N drops" and did not take it (L7). So the time of the total rests on no stated why, for any kind. Neither addresses a process killed before shutdown, which a killed pod is.

**Proposed wording for the maintainer.** It changes only the stated basis, not the behaviour, and is for `CONTEXT.md`'s survey line, or a comment beside the guarantee, wherever the maintainer chooses to place it:

```text
Informs, and does not justify: OpenTelemetry Rust logs the first queue-full drop of a batch processor at once and its total at shutdown. The count and the total come from issue #2273, after OpenTelemetry .NET, which logs the total at shutdown only (pull request #2331); the onset comes from the review of pull request #2357, where it is given a purpose, informing the user, and no reason for its timing. Neither project states why the total waits for shutdown. Among the twelve libraries read for ticket 14 it is one library's rule, and no library among the twelve applies it to a failed store or export: each reports a failed export when it happens, or returns it to the caller. The onset is informed by OpenTelemetry JS, whose pull request author states that it shows when drops began, by a dd-trace-go reviewer's request for it, which that library's author declined, and by the maintainer's reason that it is more likely to go through.
```

Whether the behaviour itself changes is the maintainer's choice, not this file's. A total logged before establish ends is what open question 22 asks about.

## What the findings bear on in the specification

This section reports, and decides nothing.

- **Open question 22, its first half: when a kind of failure counts as stopped.** It stays open. The comparables read end what they report in four ways. Two test that the condition changed. OTel JS writes its total when the next span is accepted (L8). The Collector's memory limiter logs that memory use is back within its limits when a check that starts below its soft limit follows refusal (L11). It enters and leaves refusal on the same soft-limit test, and when a forced GC ends refusal within one check it reports the change through component status and writes no such log. The project's guideline says start and stop events need "an appropriate hysteresis". The others write at a boundary that is not a test that the failure stopped, so their count can be written while it continues: the next record after a window (ddtrace, the kernel and Vector: L1, L4, L12), the next export or worker wake (OTel Java and OTel Go: L2, L6), or a timer tick (a full Vector buffer with `drop_newest`, every 2 s at debug: L12). OTel Rust and OTel .NET write their totals only at shutdown (L5, L7), as the specification does until the question is decided.

  The OTel specification asks for a warning "when information loss starts and when recovered" (G3). The Collector's documentation lists "Data dropping due to throttling stops" as an event it logs (L11). The log4j2 discussion asked for a start and a stop event, and only the start was built (A2). Under the rules as written, an episode is kept after its total: `OpenFailureEpisode` opens one only when none exists for that table and kind, `LogTotal` marks it reported without removing it, and `CountIntoEpisode` counts a later occurrence into it. So, as written, a later occurrence opens no new onset, and a definition of stopped would not by itself change that.
- **Open question 22, its second half: unattributed rows and the confluence-wide discards.** It stays open. The nearest analogue read is telemetry offered to a processor that is not running, after it has shut down:
  - OTel Rust logs it at WARN on every occurrence;
  - OTel Python makes an INFO call on every occurrence, through the same duplicate filter as its other records and below the WARNING a host with no logging configured shows, and counts it in a metric;
  - OTel Java counts it in a metric and logs nothing.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/logs/batch_log_processor.rs

  >                     name: "BatchLogProcessor.Emit.AfterShutdown",

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  >             _logger.info("Shutdown called, ignoring %s.", self._exporting)

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessor.java

  >         spanProcessorInstrumentation.dropSpansAlreadyShutdown(1);
  >         return;

  No source read speaks to rows kept without a tenant.
- **`OnsetThenTotal` and the rules `OpenFailureEpisode` to `LogTotal`.** The verdict above, no stated why, is not the first. The proposed wording changes only the stated basis.
- **`StandardFacade`.** The verdict is the first, except for WARNING on a dropped tenant, which rests on no stated why; the proposed text gives that clause's basis. Three points are raised for the maintainer: the Rust facade, `NullHandler`, and the basis for the level on a dropped tenant.
- **`TwoChannels`.** The diagnostics snapshot is what makes OTel Rust's constraint, a count kept outside the log, hold for this client.
- **The open-decisions register's Product entry**, on how the client reports its own failures to the host application. It is untouched. The maintainer closes it with a decision record.

## Quotation check

Run on 2026-11-25 (UTC) by `check_quotes.py`, against the author's own fetch of every source and not the survey agents' copies. Every quotation is a substring of its source, except the five marked "(line breaks collapsed)". Those come from rendered web pages, match only once runs of whitespace are collapsed, and their wording is verbatim. Every blockquote has a `Source:` line above it, which the check enforces.

A second check, `check_inline.py`, finds every quoted fragment of twelve characters or more from "Fit" onwards, and checks it against all the fetched sources and this repository's ticket, `CONTEXT.md` and specification, with whitespace collapsed. Every one was found. The two blocks of proposed wording are the author's, are fenced as text, and are not quotations.
