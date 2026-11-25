# Research: store failure and data writer death

- **Ticket:** `issues/13-research-the-why-store-failure-and-data-writer-death.md`. It bears on open questions 12 ("Should a bounded retry come before a failed batch is dropped? Until decided, a failed store drops its batch at once.") and 14 ("Does a data writer that has died stay stopped, or is it restarted? Settled: a failure handling one batch costs only that batch. Until decided, it stays stopped for the rest of the run.") of `docs/specs/transect-client.allium`.
- **Sources read:** 2026-11-25 (UTC). Every link below was read that day.
- **Web research:** authorised by the maintainer in the session that picked this ticket up, for the researcher and for the reviewers.
- **Status:** findings, the fit of each comparable, one verdict on the stated behaviour and proposed wording, for the maintainer. Nothing here answers question 12 or 14, and the specification is not edited.

## How the sources were checked

- Each comparable was read from its official documentation, a specification, or source code at a named tag or commit. GitHub file links are pinned to a tag or a commit; the tag's commit is given beside each system. Issue, pull request and commit links have no version. The `prometheus/docs` and `getsentry/sentry-docs` repositories have no release tags and are pinned to the commit read. CPython's documentation is quoted from its reStructuredText source at the tag.
- Every blockquote sits under the `Source:` line it was copied from. Each was checked as a substring of source text fetched again by a script: GitHub files from `raw.githubusercontent.com` at the pinned ref, and issue, pull request and commit threads through the GitHub API (the body, every comment, every review comment and review, and the pull request's commit messages). Pages outside GitHub (Apache Confluence, the QOS.ch and Apache JIRA browse pages, logback.qos.ch, a Google Groups thread, an erlang-questions archive page, the Rust standard library's documentation) were fetched as HTML with tags stripped; two JIRA comments are linked by their REST URL, which returns the comment as JSON, a Google Docs design document by its plain-text export, and SQLite's documentation source by its raw text at a tag. At this draft, 213 blockquotes were checked: 212 match exactly, and 1 matches once whitespace is collapsed (the Google Groups page uses non-breaking spaces).
- A quotation inside a sentence was checked the same way, against the sources the file cites, or against this repository's own files where it quotes them: 82, all found.
- Each researcher's notes recorded who said what and whether they maintain the project, taken from the project's maintainer list at the time where one exists. A commit message or code comment that says only what changed is not treated as a stated why.
- Where the result is "No stated rationale found", the searches run are listed beside it. GitHub's search rate limit blocked some searches; those that could not be re-run are named.
- What no primary source confirmed is marked "Unverified". A reason the researcher worked out, and no author stated, is marked "Inferred". Behaviour traced through code and not run is marked "Inferred" too; a few behaviours were confirmed by running small probes, and say so.

## What the specification proposes

- **`FailBatch`.** A failed store drops its batch: the rows are counted as lost, and the data writer reports itself as failing until a store succeeds. The guarantee `FailureCostsOneBatch` says a failure handling one batch costs only that batch.
- **No retry.** Until open question 12 is decided, a failed store drops its batch at once.
- **`DataWriterDiesUnexpectedly`.** A failure that escapes the handling of one batch stops the data writer. Until open question 14 is decided it stays stopped for the rest of the run, and the batch in hand is lost (marked "Derived").
- **Containing panics.** The guidance says that in Rust the handling of one batch must contain panics as well as errors, "or one bad batch stops the data writer for the run".

Two differences from the comparables matter throughout. This client's batch fails at a store on a local disk; most of the libraries' batches fail at an export over a network, and only tracing-appender (L5), CPython's file handlers (L6), Logback (O2), Log4j's file appenders (O3) and, read only in part, OpenTelemetry .NET's disk buffer (O6) fail at a local write; among the pipeline agents, so does the OpenTelemetry Collector's persistent queue (P2) when its storage cannot accept data. And this client is a guest inside an application; a pipeline agent (P1 to P3) is a process of its own whose job is delivery.

## The elicitation's claims, checked again

Each claim is from "Failed stores" and "Background worker death" in `CONTEXT.md`. The section named in the last column holds the evidence and its links.

| # | Claim | Result | What the sources show | Where |
| --- | --- | --- | --- | --- |
| 1 | OTel SDK batch processors drop a failed export and carry on. | Confirmed, with a qualification | The processors in Python, Java and Rust drop a failed batch and carry on; Java's and Rust's log a returned failure, while Python's logs only a raised exception and ignores a returned `FAILURE`, which is reported only if the exporter logs it itself (the OTLP HTTP exporter does); none retries, as the specification advises ("SHOULD NOT"). But the OTLP exporter beneath each retries inside the export first, by default: about 10 s in Python, five attempts within 10 s in Java (since 1.41.0; not on the sender built on grpc-java's `ManagedChannel`), three retries in Rust (since 0.33.0). An exporter that does not retry is dropped on its first failure. | L1 to L4 |
| 2 | Python logging handlers drop a failed record and carry on. | Partly | Each standard handler that writes or sends catches the error in its own `emit` (`StreamHandler`, `FileHandler` and `WatchedFileHandler` re-raise a `RecursionError`; the rotating file handlers catch it in their own `emit` and pass it to `handleError`), reports a raised error once on stderr by default (except `SocketHandler`, which drops a failed send silently, and `HTTPHandler`, which ignores an HTTP error status), does not requeue the record and tries the next. But `SysLogHandler` on a Unix socket resends the failed record once; the guard is a convention each handler must follow, not something `Handler.handle` does, and `MemoryHandler` does not follow it, so a target's error can escape it and records can be sent twice; and a probe showed a buffered file keeping a failed record's bytes and writing them later. | L6 |
| 3 | Fluent Bit retries once by default, then drops. | Confirmed, with exceptions | `Retry_Limit` defaults to 1, meaning one retry, so two sends; then the chunk is discarded and counted. An `Error` return is never retried; the S3 output defaults to 5 and quarantines an exhausted chunk by default; a dead-letter queue, when on, keeps the chunk. | P1 |
| 4 | The OTel Collector retries while its queue fills, then drops. | Partly | Retry is bounded by time, not by the queue: each batch is retried while another attempt can start within 5 minutes, and then dropped, whether or not the queue has room. A full queue is a second, separate drop point that refuses new data. The claim describes the `queued_retry` processor removed in 2021. | P2 |
| 5 | Prometheus remote-write retries for up to two hours. | Wrong | A recoverable failure is retried with no limit in attempts or time; `max_retries` was removed in 2.11.0. "Two hours" is the tuning page's account of an outage: data not sent within about two hours is lost when the local write-ahead log is truncated, which in server mode does not wait for remote-write (the source's own comment says up to around three hours of log is kept); in agent mode, truncation every 2 hours cuts the log at a point between 5 minutes behind what remote-write has sent and 4 hours back, by default. | P3 |
| 6 | Of seven libraries read from source, none restarts a worker a limited number of times. | Confirmed | None of OTel Python, Java and Rust, tracing-appender, CPython's `QueueListener`, ddtrace and sentry-python restarts with a limit. Six never restart on their own a worker that died in the same process (CPython's `QueueListener` can be restarted by its caller with `stop()` then `start()`, within the limits in L6); sentry-python's transport worker restarts with no limit. | L2 to L8 |
| 7 | The usual pattern catches failures around one batch, logs, drops it and keeps looping; anything escaping the guard kills the worker for the life of the process. | Partly | The guard differs in each: around the export call only (OTel Python, Java); a match on a returned error, not a catch (OTel Rust); a write or flush error discarded without a log, with no bound in the code on what it loses (tracing-appender); no guard in the loop at all, only inside each handler, and not in `MemoryHandler` (`QueueListener`); after a retry, not instead of one (ddtrace). An escape does kill the worker in six (in ddtrace a `SystemExit` can end the process, Inferred), but OTel Python, ddtrace and sentry-python start a new worker in a forked child, and sentry-python restarts its transport worker on the next submit. | L2 to L8 |
| 8 | Only sentry-python restarts a dead worker: lazily, on the next submit, with no limit. | Partly | Lazily, on the next submit (and on a transport flush), with no limit: confirmed. But the threaded worker's restart was written for fork, not for a crash: it came from raven-python for gunicorn and uWSGI, and restarts a crashed thread as a side effect. Only its transport worker does it; its batcher threads do not. OTel Python and ddtrace also start a new worker after a fork, but not after a crash. sentry-python's experimental async transport also restarts its worker on submit, on a fresh queue. | L8, L2, L7 |
| 9 | The Rust libraries read do not contain panics. | Confirmed | Neither OTel Rust nor tracing-appender has `catch_unwind` outside tests. OTel Rust's experimental runtime variant leaves a panic to tokio, which ends the task: the runtime contains it, not the library. | L4, L5 |

Every library was read in source at a named version: OTel Python `v1.45.2`, OTel Java `v1.68.0`, OTel Rust `opentelemetry_sdk-0.33.1`, `tracing-appender-0.2.5`, CPython `v3.15.2`, `dd-trace-py` `v4.17.2` (with libdatadog `v46.1.2`) and `sentry-python` `3.0.0`.

## In-process libraries

L1 is the specification the three OpenTelemetry SDKs follow. L2 to L8 are the seven libraries whose worker loops the elicitation read.

### L1. The OpenTelemetry specification

**Analogy.** Not a library but the rules the three OpenTelemetry SDKs below follow. It says where retry lives, what a processor does with a failed batch, and what a background task should do on an internal error.

**What it does.** Specification `v1.63.0` (`7390341e59b7`), OTLP protocol `opentelemetry-proto` `v1.11.1` (`b3f75588eb23`). The specification repository's `protocol/otlp.md` now only redirects to the proto repository.

- A processor does not retry. A failed batch is dropped.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md

  > Concurrent requests and retry logic is the responsibility of the exporter. The
  > default SDK's Span Processors SHOULD NOT implement retry logic, as the required
  > logic is likely to depend heavily on the specific protocol and backend the spans
  > are being sent to.

  > * `Failure` - exporting failed. The batch must be dropped. For example, this
  >   can happen when the batch contains bad data and cannot be serialized.

  The logs SDK page says the same of `LogRecordProcessors`.

- An export is bounded in time, except a synchronous write through an API that cannot set a deadline or cancel a blocked write.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md

  > `Export` MUST NOT block indefinitely, except when performing synchronous
  > output through an API that does not support deadlines or
  > cancellation of a blocked write.

  > In all other cases, there MUST be a reasonable finite upper limit after which
  > the call times out with an error result (`Failure`).

  The note beside the rule gives the reason: bounding the caller's wait by running the write in the background can leave the write blocked and holding resources after the export returns, or let the output complete after the timeout. "These costs motivate this exception."

- The OTLP exporter must retry a transient error, within the export's time limit.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/protocol/exporter.md

  > Transient errors MUST be handled with a retry strategy. This retry strategy MUST implement an exponential back-off with jitter to avoid overwhelming the destination until the network is restored or the destination has recovered.

  > Each request attempt and wait between retries MUST be bounded by the remaining
  > time allowed by the exporter timeout. Any earlier deadline provided by the caller
  > (for example, a span processor, log processor, or metric reader) MUST take
  > precedence. When either limit is reached, the exporter MUST stop attempting to
  > export the batch, including any waits between retries, and complete the export
  > with a failure result.

  Source: https://github.com/open-telemetry/opentelemetry-proto/blob/v1.11.1/docs/specification.md

  > - Non-retryable errors indicate that telemetry data processing failed, and the
  >   client MUST NOT retry sending the same telemetry data. The client MUST drop
  >   the telemetry data.

- Error handling: never throw into the application at runtime, though failing fast at initialization is allowed, and a long-running background task should not fail permanently in response to internal errors.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > OpenTelemetry implementations MUST NOT throw unhandled exceptions at runtime.

  > 2. The API or SDK MAY _fail fast_ and cause the application to fail on initialization, e.g. because of a bad user config or environment, but MUST NOT cause the application to fail later at runtime, e.g. due to dynamic config settings received from the Collector.

  > 2. Background tasks (e.g. threads, asynchronous tasks, and spawned processes) should run in the context of a global error handler to ensure that exceptions do not affect the end user application.
  > 3. Long-running background tasks should not fail permanently in response to internal errors.
  >    In general, internal exceptions should only affect the execution context of the request that caused the exception.

**Stated why.**

- **Dropping rather than holding data, in general.** The error-handling page gives the principle.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/11#discussion_r290907973

  The page came from specification PR #153 (2019). Its reviewer traced that line to a comment by reyang, a member of the organisation, on opentelemetry-python PR #11: "the monitoring SDK will try to keep silent instead of changing the application behavior". Inferred: the reason is about being a guest in the application, not about the network.

- **Why the processor does not retry.** Before 2020 the export API had three results, one of them `FailedRetryable`, which let the caller retry. Issue #509 and PR #511 removed it and moved retry into each exporter.

  John Watson, who opened both (a maintainer of the Java SDK):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/509

  > I would suggest that retry logic should be the responsibility of the exporter itself, rather than trying to design an exporter API that would cover all the cases.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/511#issuecomment-598250150

  > Every protocol and backend has their own retry semantics. For New Relic, our SDK for writing metrics and spans already handles retries, based on how our APIs behave. It's fairly complex, and figuring out how to communicate that logic into the SDK for every possible protocol/backend seems like a fools-errand.

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/2452

  Inferred: the reason is about how varied network protocols and backends are. It does not say a failed batch should not be retried: it says the exporter, which knows the protocol, does it. When PR #2452 (2022) extended the sentence to concurrency, trask (a member of the organisation) added that retry "could even include storing to disk and retrying later".

- **Why the OTLP exporter retries.** OTEP 0035, which proposed OTLP, and the protocol specification state reliable delivery as a goal.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0035-opentelemetry-protocol.md

  > - Ensures high reliability of data delivery and clear visibility when the data cannot be delivered. OTLP uses acknowledgements to implement reliable delivery.

  Source: https://github.com/open-telemetry/opentelemetry-proto/blob/v1.11.1/docs/specification.md

  > received yet. The client will typically choose to re-send such data to guarantee
  > delivery, which may result in duplicate data on the server side. This is a
  > deliberate choice and is considered to be the right tradeoff for telemetry data.

- **Why a background task should not fail permanently.**

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/153

  No stated rationale found. Blame puts the line in specification PR #153; the review comment beside it says only "New line to expand on the point above." Searched in the specification repository: `"fail permanently" background`, `restart worker thread background task`, `error handling background thread crash`.

**Constraints.** The specification governs in-process SDKs that export over a network to a collector or backend, and what it promises is that the SDK throws no unhandled exception at runtime and does not "significantly change" the application's behaviour; it may fail fast at initialization. The processor hands each batch to the exporter once and drops it on failure; the exporter's bounded retry can resend a request whose acknowledgement was lost, so a batch can arrive twice or not at all; the protocol itself aims at at-least-once between one client and one server, accepting duplicates.

**Costs and dissent.** The move of retry into exporters was contested in PR #511, by Tigran Najaryan, a member of the organisation.

Source: https://github.com/open-telemetry/opentelemetry-specification/pull/511#issuecomment-598243718

> First, I think we all agree that retries have to happen somewhere since temporary failures are a thing and we cannot afford to lose data on every random sending problem.

> This also requires non-trivial code duplication in exporters. Each exporter has to implement the retrying logic, timeouts, backoff, etc. Here we have an opportunity for bugs since it is not trivial to implement this correctly (my hope was we could do this once in the SDK, which see more scrutiny and code reviews).

The PR merged with two results and John Watson's note that a retryable result could come back "When/if we specify retry logic for the SDK". It has not come back at `v1.63.0`. A search of the specification repository for `FailedRetryable`, `processor retry SHOULD NOT` and `batch processor failed export retry drop` found nothing reversing the rule.

### L2. OpenTelemetry Python SDK

**Analogy.** Close: an in-process library with one background thread that takes batches from a bounded queue and hands them to an exporter. Its batch fails at a network export, not a local store.

**What it does.** `opentelemetry-python` `v1.45.2` (`ad755945ad69`). Spans and log records share one `BatchProcessor` class (since PRs #4562 and #4580, 2025); each span or log processor builds its own instance, with its own queue and daemon thread.

- **The guard.** A `try` around the one call to `export()` catches `Exception`, logs it, and the loop goes on. The batch has already been popped from the queue, so it is gone.

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  >                 # Record on submission to the exporter.
  >                 self._metrics.finish_items(count)
  >                 try:
  >                     self._exporter.export(batch)
  >                 except Exception:  # pylint: disable=broad-exception-caught
  >                     _logger.exception("Exception while exporting %s.", self._exporting)

  The processor does not read `export()`'s result: a `FAILURE` is treated like a success. The pop, the metrics call and the context calls sit outside the `try`; PR #5472 (2026-08) moved the pop and the metrics call out, for a reason about metric semantics only.

- **What escapes.** A `BaseException` that is not an `Exception`, and any error in the lines outside the `try`. Inferred from the code and CPython's thread semantics: it ends the worker thread, and nothing restarts it. There is no `is_alive` check or restart in the three processor files. After that, `emit()` keeps queuing until the queue is full and then, for each new item, counts a drop and adds the item while the bounded `deque` evicts the oldest, so the newest are kept, where this client's full queue refuses the arriving row (`RefuseRowWhenQueueFull`); `force_flush()` still exports on the caller's thread; and `shutdown()` skips the final drain (Inferred).

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  >         self._queue = collections.deque([], max_queue_size)

  >         # This will drop a log from the right side if the queue is at _max_queue_size.
  >         self._queue.appendleft(data)

  >                 batch = [self._queue.pop() for _ in range(count)]

- **Retry.** Not in the processor. The OTLP gRPC and HTTP exporters retry inside `export()`: up to six rounds (in HTTP, a round that meets a connection error sends a second request at once, with no backoff, if time remains), backoff `2**n` seconds with ±20% jitter, the server's `RetryInfo` or `Retry-After` honoured, all bounded by the export timeout (10 s by default) and cut short by shutdown. Over HTTP the budget reaches Requests only as its timeout, which bounds a wait for bytes, not the whole request, so one request in flight can outlast it (Inferred from the code and the Requests documentation).

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/exporter/opentelemetry-exporter-otlp-proto-grpc/src/opentelemetry/exporter/otlp/proto/grpc/exporter.py

  >                         error.code() not in self._retryable_error_codes  # type: ignore [reportAttributeAccessIssue]
  >                         or retry_num + 1 == _MAX_RETRYS
  >                         or backoff_seconds > (deadline_sec - time())
  >                         or self._shutdown

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/exporter/opentelemetry-exporter-otlp-common/src/opentelemetry/exporter/otlp/common/http.py

  >             # Immediately retry connection errors once without backoff. These
  >             # usually indicate a stale pooled connection that the transport will
  >             # reestablish on the next attempt.

  Source: https://github.com/psf/requests/blob/v2.34.2/docs/user/quickstart.rst

  >     ``timeout`` is not a time limit on the entire response download;
  >     rather, an exception is raised if the server has not issued a
  >     response for ``timeout`` seconds (more precisely, if no bytes have been
  >     received on the underlying socket for ``timeout`` seconds).

  Inferred from the arithmetic: with the 10 s default, about four attempts fit before `FAILURE`.

- **Fork.** A hook registered with `os.register_at_fork` clears the inherited queue and starts a new worker in the child. A fallback in `emit()` does the same when the process id has changed, once per processor.

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py

  >         if self._pid != os.getpid():
  >             self._bsp_reset_once.do_once(self._at_fork_reinit)

  This runs whether or not the parent's worker was alive. It is not a liveness check, and it never runs in the parent.

**Stated why.**

- **Dropping and not retrying in the processor:** the specification's, under L1.
- **Restarting after a fork.** Lzchen, a maintainer, in PR #2242 (2021):

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/2242#discussion_r742381328

  > We've had some complaints from guicorn users not getting telemetry because the worker thread is not copied.

- **Not restarting a dead worker.** The only discussion found is in the review of the original batch processor, PR #153 (2019). Oberon00, a code owner, suggested a restart; the PR's author, mauriciovasquezbernal, a member of the organisation, was unsure and floated a health check elsewhere; Oberon00 replied with a cheaper place for the check, and the thread ends there unanswered.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r328101842

  > Another thing we should maybe do is check https://docs.python.org/3/library/threading.html#threading.Thread.is_alive for our worker and restart it (logging a warning) if it crashed.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r328147028

  > I am not sure about this one. Maybe if that thread could crash we should implement a health check somewhere else I think. I don't want to make this `onEnd` slower because it's called to each span.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r328182655

  > Although, about the slowness, we could maybe only check it in cases where we notify the condition.

  The stated reason is the cost of a check on every span, and doubt that the thread could crash; it is not a reason against restarting. The suggestion was left open, not refused, and no restart was added then or later. Searched (`repo:open-telemetry/opentelemetry-python`): `is_alive`, `worker thread dead`, `worker thread died`, `restart worker thread`, `thread died BatchSpanProcessor`, `BatchSpanProcessor thread crashed`, `BatchSpanProcessor stops exporting`, `BatchLogRecordProcessor stops`, `worker thread exception stops exporting`, `"worker thread" dead`, `worker thread not running`, `threading.excepthook`, `BaseException worker`, `BaseException export`, `KeyboardInterrupt worker thread`, `SystemExit BatchSpanProcessor`, `retry BatchSpanProcessor`, `retry in BatchSpanProcessor`, `processor retry export failed`, `retry queue BatchSpanProcessor failed spans`, `requeue failed spans`, `BatchSpanProcessor export result ignored`, `persistent queue disk retry exporter`. Beyond that review comment, no issue or PR found in these searches asks to restart a dead worker, or to retry in the processor.

- **A daemon thread.** Oberon00, in the same PR, preferred losing data to hanging the host at exit.

  Source: https://github.com/open-telemetry/opentelemetry-python/pull/153#discussion_r326973261

  > If you forget to shut down the SpanProcessor with damon=False, your process will not end because the span processor thread keeps idling around. With daemon=True, you get lost traces. In the spirit of https://github.com/open-telemetry/opentelemetry-specification/pull/153 I think that lost traces should be preferred to processes deadlocking on shutdown, but I have no strong opinion.

**Constraints.** In-process; a daemon thread that never keeps the process alive; the specification's rule not to throw; pre-fork servers (gunicorn, uWSGI) behind the fork handling; a 30 s default for joining the worker at shutdown, after which the exporter's own `shutdown` gets the remaining time only if it accepts a `timeout_millis` argument (PR #4638).

**Costs and dissent.**

- Retrying inside a synchronous `export()` on the worker thread hung shutdown for a minute or more against an unreachable collector (#2663, #3309, #4043). PR #4564 (2025) made the timeout cover all retries; PR #4638 let shutdown interrupt the backoff.
- The fork fallback recovers once only, and a second bypassed fork stops export silently. The issue is open at the pin.

  Source: https://github.com/open-telemetry/opentelemetry-python/issues/5843

  > Consequence: this fallback can recover from exactly **one** bypassed fork, ever, in the lifetime of a `BatchProcessor`. A second one in the same process's lifetime is silently ignored:

- The specification's guidance that a long-running background task "should not fail permanently in response to internal errors" (L1) is not met when an error in the lines outside the `try` ends the worker for good. The specification does not say whether an exporter's `BaseException` is an internal error; its guidance also says to expect overridable interfaces to throw. No source presents either as an intended exception (Inferred).

### L3. OpenTelemetry Java SDK

**Analogy.** Close: the same design as L2 in another runtime, a daemon thread that exports batches over a network.

**What it does.** `opentelemetry-java` `v1.68.0` (`6700a7060109`).

- **The guard.** `exportCurrentBatch()` wraps the export call and a timed wait, 30 s by default. A failed or timed-out result is logged at FINE; a thrown `Throwable` that is not fatal at WARNING. Either way the batch is cleared, which drops it, and the loop goes on; a timed-out export is not cancelled (Inferred from the code). A fatal one is rethrown after the batch is cleared, and ends the worker (below).

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessor.java

  >         CompletableResultCode result = spanExporter.export(Collections.unmodifiableList(batch));
  >         result.join(exporterTimeoutNanos, TimeUnit.NANOSECONDS);
  >         if (!result.isSuccess()) {
  >           logger.log(Level.FINE, "Exporter failed");
  >         }

  >       } catch (Throwable t) {
  >         ThrowableUtil.propagateIfFatal(t);
  >         logger.log(Level.WARNING, "Exporter threw an Exception", t);
  >       } finally {
  >         batch.clear();
  >       }

  The processor counts no row lost to a failed export; the OTLP exporters count failures in their own metrics.

- **What escapes.** Three things end the worker: the fatal errors `propagateIfFatal` rethrows on purpose (`VirtualMachineError`, `ThreadDeath`, `LinkageError`); anything thrown while each span or log record is converted for export, which happens outside the guard; and an interrupt, which ends the loop with a plain `return`. The thread is a daemon, and its uncaught-exception handler only passes the error on. The processor keeps no reference to the thread after starting it, so nothing can check or restart it. Inferred from the code, not tested: after that, spans queue until the queue is full and are then counted as dropped in a metric only, with no log line, and `forceFlush()` and `shutdown()` never complete.

- **Retry.** Not in the processor. The OTLP exporters retry by default since 1.41.0 (PR #6588, 2024): five attempts including the first, backoff from 1 s to 5 s by ×1.5 with jitter, for HTTP 429, 502, 503 and 504, a set of gRPC codes, and connect, timeout, unknown-host and socket errors, all inside the exporter's 10 s timeout.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/common/src/main/java/io/opentelemetry/sdk/common/export/RetryPolicy.java

  >   private static final int DEFAULT_MAX_ATTEMPTS = 5;

  An exporter that is not OTLP retries only if it implements retry itself. The policy reaches the OkHttp sender but not the gRPC sender built on grpc-java's `ManagedChannel` (the `grpc-managed-channel` sender artifact), which is given only a deadline; any retry there is the channel's own, not checked (Inferred from the code).

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/exporters/sender/grpc-managed-channel/src/main/java/io/opentelemetry/exporter/sender/grpc/managedchannel/internal/UpstreamGrpcSenderProvider.java

  >     return new UpstreamGrpcSender(
  >         managedChannel,
  >         extendedSenderConfig.getFullMethodName(),
  >         extendedSenderConfig.getCompressor(),
  >         shutdownChannel,
  >         extendedSenderConfig.getTimeout(),
  >         extendedSenderConfig.getHeadersSupplier(),
  >         extendedSenderConfig.getExecutorService());

**Stated why.**

- **Dropping in the processor:** the specification's, under L1. Jack Berg, a maintainer, answering a request for a persistent batch processor in 2024:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/6940#issuecomment-2539475611

  > The behavior of batch span processor is dictated by the [specification](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md#batching-processor), so changing its behavior to have a persistent queue would require changing the spec, which I expect would be an involved process.

  > This could be local persistence on disk, but this is not without problems. Something still has to serialize to disk and deserialize later. Can this serialization keep up with bursts of spans?

- **Retrying in the exporter by default.** Jack Berg, in PR #6588:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/6588

  > - My employer (New Relic) has recommended it for production use for that entire time without any reports of issues

  > By defaulting to not retrying, I believe we've technically been non-compliant this whole time. This was justified by the desire to wait for some additional emerging standard describing more details about how that retry strategy should work. I now believe its impossible to unify the implementations with a common algorithm and options, since there are many stable implementations with different designs.

  The reason is the specification's MUST (L1) and experience in production. Inferred: the retries are about transient network failure.

- **Letting fatal errors kill the worker.** Anuraag Agrawal, a maintainer at the time, in the review of PR #4402 (2022):

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/4402#discussion_r854812422

  > Yes for fatal exceptions like OutOfMemory this needs to happen to let the runtime know of the unrecoverable problem. We always propagateIfFatal in this sort of pattern.

- **A daemon thread.** The report behind it, by Oberon00 (role in the Java project not verified), in issue #1093 (2020), when the processor's thread was not yet a daemon:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/1093

  > This is a real problem especially for auto-instrumentation where `TracerProvider.shutdown` is usually called from `java.lang.Runtime.addShutdownHook`, which would not get invoked if the JVM never shuts down.

  The fix, PR #1120 (2020), by johnbley (role not verified); its description, which ends "Closes #1093":

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/1120

  > Our SDK shouldn't prevent apps/cli tools/etc. from exiting.  Mark all threads/pools as daemon.

  Inferred: the reason is about being a guest that must not keep the host process alive, not about the network.

- **The guard's width.** The first processor (PR #456, 2019) caught `Throwable`, with a comment saying what the catch is for.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/98bea4a9f64d9122b97dd0d656dd505ac6a8c122/sdk/src/main/java/io/opentelemetry/sdk/trace/export/BatchSampledSpansProcessor.java

  >       // In case of any exception thrown by the service handlers continue to run.

  PR #1428 (2020) narrowed it to `Exception`, and PR #2618 (2021), a dependency update, to `RuntimeException`, with no reason given; Inferred: an Error Prone check drove it.

- **Not restarting the worker.** No stated rationale found. No issue or PR found in these searches asks for a restart. Searched (`repo:open-telemetry/opentelemetry-java`): `BatchSpanProcessor WorkerThread`, `BatchSpanProcessor stopped exporting`, `BatchSpanProcessor retry`, `BatchSpanProcessor stuck`, `BatchLogRecordProcessor WorkerThread`, `BatchSpanProcessor thread died`, `worker thread restart`, `processor retry export`, `retry dropped spans`, `worker thread killed`, `BatchSpanProcessor OutOfMemoryError`, `BatchSpanProcessor no longer exporting`; blame and `git log -S` on the guard lines through PRs #456, #1428, #2618 and #4402.

**Constraints.** In-process, often loaded by the Java agent; a daemon thread; behaviour bound by the specification. The exporter owns transient network failure within its 10 s timeout; the processor waits up to 30 s for the export's result and then clears the batch; the wait does not cancel the export, which may still complete afterwards (Inferred from the code). A fatal JVM error is handed to the runtime on purpose.

**Costs and dissent.**

- The narrowing to `RuntimeException` killed workers. A Kotlin exporter threw a checked `ConnectException` and the worker died for the life of the process.

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4348

  > Still, it would be great that if such an error happens, it only results in a warning log than in a stuck exporter.

  PR #4402 (2022) fixed spans by widening the catch. Log records kept the defect until v1.64.0, released on 2026-07-10.

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/8528

  > TLDR: Custom exporter throwing non-runtime exception will kill the worker thread

  Each reported death was fixed by widening the guard, not by a restart.

- A user objected to dropping a batch in 2026, and the maintainer pointed to the exporter's retry. The issue is open.

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/7099#issuecomment-4810909312

  > See `BatchSpanProcessor`: it waits for a limited amount of time and no matter what, it calls `batch.clear()`, even if the collector was unavailable for a moment and the data didn't get sent.

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/7099#issuecomment-4814947372

  > Otlp exporters rety on transient errors by default

- A persistent processor was asked for (#6940); an approver pointed to the contrib `disk-buffering` module, and a stale bot closed the issue.

### L4. OpenTelemetry Rust SDK

**Analogy.** Close, and the nearest in language: a Rust library whose batch processor runs on its own OS thread, as this client's data writer would. Its batch fails at a network export.

**What it does.** `opentelemetry_sdk-0.33.1` and `opentelemetry-otlp-0.33.1`, one commit (`372ebbc74d4d`).

- **The worker.** Since 0.28 each batch processor runs on a dedicated OS thread and drives the async `export()` with `futures_executor::block_on`. The older processors, run as a task on a runtime the user supplies, sit behind `experimental_*_with_async_runtime` features (PRs #2436 and #2456, 2024).

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/CHANGELOG.md

  > - Redesigned PeriodicReader, BatchSpanProcessor, BatchLogProcessor to no longer
  >   require an async runtime. They create its own background thread instead.

  The stated why is to serve applications with no async runtime.

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1437

  > We need to support metrics aggregation and batchprocessors for user who do not use any async runtimes. We might be able to spin up a dedicated background thread to achieve this.

- **The per-batch guard is a match, not a catch.** `export_batch_sync` matches on the `Result`: an `Err` is logged with `otel_error!` and returned. The batch has already been moved into the call (spans) or is cleared after it (logs), so it is dropped. On the timer and batch-size paths the result is discarded with `let _ =`, and the loop goes on.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs

  >         Err(err) => {
  >                 otel_error!(
  >                     name: "BatchSpanProcessor.ExportError",
  >                     error = format!("{}", err)
  >                 );
  >                 OTelSdkResult::Err(err)

  No counter records a row lost to a failed export; the drop counter counts only a full queue (Inferred from the code).

- **Panics.** There is no `catch_unwind` in any SDK or OTLP code outside two tests. Traced from the source: a panicking exporter unwinds out of the thread, which ends and drops its receivers; the SDK logs nothing at the panic itself and only Rust's panic hook prints. Each later span then meets a closed channel and is logged as if the application had shut down too early.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs

  >                 // Given background thread is the only receiver, and it's
  >                 // disconnected, it indicates the thread is shutdown

  `force_flush()` and `shutdown()` then return `AlreadyShutdown`; a call whose request was accepted before the worker died, whether the worker had taken it or it was still queued, returns `InternalFailure` instead, unless its own timeout expires first, and a `shutdown()` in that case also logs `BatchSpanProcessor.Shutdown.Error`. A thread that died this way is never joined, since `shutdown()` joins only after the worker's reply, which a worker that panicked first never sends; and the exporter's own `shutdown()` runs only if the worker reached it while handling a shutdown request, so the panic may also come from inside it (Inferred from the code). There is no restart, respawn or liveness check. Inferred: the worker is dead for the life of that provider, which is the life of the process unless the application builds another; under `panic = "abort"` the process dies instead. In the experimental runtime variant, tokio ends a panicking task and the SDK discards its handle: the runtime contains the panic, not the library.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs

  >                         // join the background thread after receiving back the
  >                         // shutdown signal
  >                         if let Some(handle) = self.handle.lock().unwrap().take() {
  >                             handle.join().unwrap();

- **This has happened.** Issue #3432 shows a panic raised inside the batch worker's export by the then experimental gRPC retry.

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3432

  > there is no reactor running, must be called from the context of a Tokio 1.x runtime

  PR #3621 removed that trigger. The issue is open at the pin.

- **Retry.** Not in the processor. Since 0.33.0 the OTLP exporter retries by default inside `export()`, on the worker thread, with a blocking sleep: three retries, backoff from 100 ms to 1.6 s with jitter, the exporter timeout deciding whether another retry starts and capping each wait but not cutting off an export in flight (below), for HTTP 429, 502, 503, 504 and a failed connection, and the retryable gRPC codes.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry-otlp-0.33.1/opentelemetry-otlp/src/retry_policy.rs

  > /// Returns the recommended policy: 3 retries with exponential backoff
  >     /// (100ms initial, 1600ms maximum, and up to 100ms jitter).

  The source notes that on the dedicated thread a single slow export is not itself bounded.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry-otlp-0.33.1/opentelemetry-otlp/src/retry.rs

  > /// **Note:** The deadline governs whether to start another retry and caps inter-retry
  > /// sleep durations, but it does not cancel an in-flight export operation. On dedicated
  > /// threads (the SDK's default batch processors), individual export calls do not have a
  > /// timeout today, so a single slow export can exceed the deadline. This is an existing
  > /// limitation.

- **Fork.** None: a search of the tree for `atfork`, `fork` and `getpid` finds nothing relevant.

**Stated why.**

- **Dropping and not retrying in the processor:** the specification's (L1), repeated in the trait's documentation.

  Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/export.rs

  > /// Any retry logic that is required by the exporter is the responsibility
  >     /// of the exporter.

  Blame on the guard lines leads to PRs #2526, #3116, #2613, #2596 and #2661, each of which says what changed and not why. Lalitb, a maintainer, on where recovery belongs:

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3210#issuecomment-3458300421

  > When exporters fail due to certificate rotation, network issues, or endpoint downtime, the recovery logic should live inside the processor or exporter - using retries, exponential backoff, and buffering - not in application code.

  > But once the application is running, background exporter failures shouldn’t interrupt or bubble up through user code.

- **Retrying in the exporter.** The OTLP specification's MUST (L1). Scottgerring, a maintainer, in PR #3621 (2026), which kept retry off by default:

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3621

  > We can flip the default in a couple versions, but for now we're aiming to hit the feature requirements of the OTLP exporters with a safe change.

  PR #3660 turned it on about three weeks later. No stated rationale found for the change beyond the specification's MUST: its body says what it does, and its reviews are about documentation.

- **Not containing panics.** For panics in metric callbacks, scottgerring gave a reason in issue #3640.

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3640#issuecomment-5406513337

  > TBH this feels more like an enhancement to me; panicking in user code is a pretty big deal, as you point out the spec doesn't require anything from us here, and it's not really clear to me that the complexity cost of supporting unwinding across this point (reasoning about `UnwindSafe` bounds, deciding what state to recover, what to skip vs retry, etc.) is low enough that you'd just do it defensively by default.

  PR #3777 then added a one-time error log when the metric reader's thread dies, and documented that callbacks must not panic. For a panicking exporter in the batch processors: no stated rationale found. The same issue raised that case, and nobody answered it.

  Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3640

  > - The same shape of gap (dedicated worker thread, no `catch_unwind` around user-supplied code) exists
  >   in `BatchSpanProcessor`/`BatchLogProcessor` around `exporter.export(...)` — worth deciding if that's
  >   in scope here or a follow-up.

- **Not restarting.** No stated rationale found. Searched (`repo:open-telemetry/opentelemetry-rust`): `catch_unwind`, `unwind`, `"thread died"`, `"worker thread" panic`, `exporter panic` (first 40 of 83 read), `panic BatchSpanProcessor`, `panic BatchLogProcessor`, `"panic=abort"`, `restart thread`, `respawn`, `fork process thread`, `retry BatchSpanProcessor`, `failed export dropped`; issues and PRs #3640, #3777, #3375, #3538, #3542, #3432, #3793, #2066, #2454, #2456, #3621, #3660 read in full.

**Constraints.** In-process; a dedicated thread so that applications without an async runtime are served; the project's own rule that SDK code does not panic during regular operation (ADR 001), which is about the SDK's code, not an exporter's. Logs SDK and metrics SDK are stable, traces beta.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/docs/adr/001_error_handling.md

> ### 1. No panics from SDK APIs
> Failures during regular operation should not panic, instead returning errors to the caller where appropriate, _or_ logging an error if not appropriate.

**Costs and dissent.**

- The specification's guidance (L1) says long-running background tasks should not fail permanently in response to internal errors, and that external callbacks and overridable interfaces should be expected to throw. Inferred: the batch processors do not meet it for a panicking exporter, and no maintainer statement addresses that.
- PR #3538 (2026) would have joined a dead worker and reported its panic at shutdown. Its author closed it unmerged with no reason given. In its review lalitb said the existing join misses a panic that happens before the worker replies.

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3538#discussion_r3369896718

  > This only joins the worker after it sends the shutdown response. If the worker panics before that, like during the final export or exporter shutdown, `recv_timeout` will return `Disconnected` and we never join the thread. That means we still lose the real panic message.

- In the same review, cijothomas defended panicking when the thread cannot be started.

  Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3538#discussion_r3367961873

  > While OTel does not allow panic/exceptions, there are actually allowed (and encouraged) in startup/setup code where fail-fast is better than continue to run - There is no recovery - if thread is not started, then this processor will not be able to export anything ever.

- Issue #3210 (open) asks that export errors reach the application through a callback rather than only a log. Cijothomas replied that a callback was always the plan; there is none in the batch processors at the pin.

### L5. tracing-appender

**Analogy.** The closest in what fails: a Rust library whose background thread writes to a local file, so its failure is a failed local write, not a network export. It handles lines, not batches.

**What it does.** `tracing-appender-0.2.5` (`53e14901f484`), the latest release. The repository's `main` branch is the release line; `v0.2.x` holds unreleased work. No runtime behaviour below was observed: a small probe crate could not be run, so everything marked Inferred is read from source.

- **A failed write.** The worker blocks for one line, drains whatever else is queued, then flushes; the first `io::Error` returns from that pass. The loop discards it.

  Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/worker.rs

  >                         Err(_) => {
  >                             // TODO: Expose a metric for IO Errors, or print to stderr
  >                         }

  >         self.writer.flush()?;

  Inferred from the code: the line whose write failed is not retried, and the lines still queued stay queued for the next pass. A failed `flush()` at the end of a pass takes the same silent path; if that pass took the guard's shutdown message, the error discards it, the worker goes back to waiting for lines, and the guard's wait gives up after 1 s without a word. Only the last flush, after the loop ends, prints its error to stderr. What a failed write or flush loses then depends on the writer: the code does not bound it to one line. The error is not logged, printed or counted. There is no retry of that line; each later line is tried against the same writer, so a writer that keeps failing loses every line silently, and writing resumes on its own if the writer recovers. Once the guard and every writer have been dropped, each pass meets the closed channel at once and flushes before it can stop; a flush that keeps failing takes the same silent path, so the worker loops without waiting until a flush succeeds (Inferred from the code, not run).

  >                 if let Err(e) = self.writer.flush() {
  >                     eprintln!("Failed to flush. Error: {}", e);
  >                 }

  Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs

  >                 let _ = self.shutdown.send_timeout((), Duration::from_millis(1000));

- **A failed rotation.** `RollingFileAppender` prints to stderr and keeps writing to the old file; it does not try again until the next rotation (Inferred: the next rotation time has already moved on).

  Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/rolling.rs

  >             Err(err) => eprintln!("Couldn't create writer for logs: {}", err),

- **A panic.** No `catch_unwind` exists in the crate's source, at the tag or on `v0.2.x`. Inferred: a panic in the inner writer ends the thread and closes the channel. Afterwards the default lossy mode drops each line and counts it; non-lossy mode returns an error for each line. The released `WorkerGuard` never joins the thread, and on a closed channel its `drop` returns without a word; only Rust's panic hook prints anything.

  Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs

  >             Err(SendTimeoutError::Disconnected(_)) => (),

  The only tolerance of panics is that the crate ignores lock poisoning.

- **Restart.** None, and no liveness check or API to see that the worker died. The thread is spawned once. Inferred: a caller can only build a new writer and swap it in.

**Stated why.**

- **Discarding a write error.** No stated rationale found. The TODO has been there since the crate was added (PR #673, 2020); it says what was meant to be added, not why it was left out. For the rotation path, hawkw, a maintainer, in the review of that PR:

  Source: https://github.com/tokio-rs/tracing/pull/673#discussion_r406843313

  > Later on, if we decide that we _do_ need to expose this error elsewhere, we can always change this method to return it...

- **Moving writes off the caller's thread.** The guest's reason: latency.

  Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs

  > /// as they are emitted, an application might find the latency profile to be unacceptable.
  > /// `NonBlocking` moves the writing out of an application's data path by sending spans and events
  > /// to a dedicated logging thread.

- **Not containing panics.** No stated rationale found. The nearest is in PR #673's review, where hawkw floated letting the caller own the thread, so as to control "how panics are propagated":

  Source: https://github.com/tokio-rs/tracing/pull/673#discussion_r405741033

  > That way, the user can spawn the worker thread manually, allowing them to control things like the thread's name and how panics are propagated.

  The design that landed spawns the thread inside the library. A real panic on the worker, a `debug_assert!` during rotation in 0.2.1 (#1987), was answered by fixing the bug (PR #1989), not by containing panics.

- **Not reporting a dead worker.** Not a choice.

  Source: https://github.com/tokio-rs/tracing/blob/134f9371c67d241d147f9284cf5570135b577dc3/tracing-appender/src/non_blocking.rs

  PR #1713 (2021) makes the guard join the worker and print "Logging worker thread panicked"; it is on `v0.2.x`, not in the release. Its backport, opened by davidbarsky, a maintainer, is open and unmerged; its whole description:

  Source: https://github.com/tokio-rs/tracing/pull/2807

  > We missed this change, which, whoops.

  Inferred: even that code reports only a panic during shutdown, since a worker that already died has closed the channel and the guard takes the silent path.

- **Not restarting.** No stated rationale found. A user asked for a way to restart, and no maintainer replied; the reporter later wrote that they were closing it as stale, but the issue is open at the date read.

  Source: https://github.com/tokio-rs/tracing/issues/3467

  > or at least provide some API so that the caller can restart the tracing threads when they crash (but the storage is available again).

  > Closing my own ticket as stale.

  Searched (`repo:tokio-rs/tracing`): `appender panic`, `appender catch_unwind`, `appender "worker thread"`, `appender "write error"`, `appender "disk full"`, `appender "No space"`, `appender restart`, `non_blocking panic`, `non_blocking error`, `appender "io error"`, `appender eprintln`, `appender "Expose a metric"`, `non_blocking dropped`, `appender lossy`, `appender "error_counter"`, `appender stderr`, `appender "dropped_lines"`, `appender "Logging worker thread panicked"`, `non_blocking "backpressure"`, `appender "unwind"`, `appender "backport"`; blame on the loop through PR #2219 to PR #673.

**Constraints.** In-process; one thread per writer; a local file as the usual target; the queue bounded and lossy by default; `WorkerGuard` exists to flush on exit, including after a panic elsewhere in the program.

**Costs and dissent.**

- Silent write errors were reported in 2020 and the issue has no reply.

  Source: https://github.com/tokio-rs/tracing/issues/1155

  > Basic IO errors when writing in the appender thread can cause the logger to not print any logs (in lossy mode) or lock on the queue (in lossless locking mode).

  Inferred: the second half does not match the code at the tag, where a write error does not stop the worker.

- The lossy default drew dissent; the maintainer's reply asked only for documentation.

  Source: https://github.com/tokio-rs/tracing/issues/2865

  > Silently, losing logs in a production environment is hard to diagnose, and should not be a default.

- The constructors panic when the first file cannot be opened. Maintainers agree they should return a `Result` and have kept them for compatibility (#1953, #3631).

### L6. CPython `logging` and its `QueueListener`

**Analogy.** Close in two ways: handlers that write to a local file, so a failure can be a failed local write; and `QueueListener`, a background thread that takes records from a queue and hands them to handlers. Records are handled one at a time, not in batches.

**What it does.** CPython `v3.15.2` (`5e58eaad7c58`): `Lib/logging/__init__.py`, `Lib/logging/handlers.py`, and the documentation's sources at the same tag. Probes ran on CPython 3.15.0; the differences between the two versions do not touch the code probed.

- **A failed handler.** `Handler.handle` runs the filters and calls `emit` with no `try`. Each standard handler that writes or sends wraps its own `emit` and passes any `Exception` that reaches it to `handleError` (`StreamHandler`, and so `FileHandler` and `WatchedFileHandler`, re-raise a `RecursionError` instead, which under `QueueListener` ends the thread, Inferred; the rotating handlers wrap `FileHandler.emit` in a `try` of their own and pass it to `handleError`, below; `SocketHandler` swallows a failed send before that, below, and `HTTPHandler` ignores the response, so an HTTP error status raises nothing), which prints a `--- Logging error ---` block and the traceback to stderr when `raiseExceptions` is true (the default), and does nothing otherwise. It re-raises only a `RecursionError` met while printing, and nothing re-queues the record.

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py

  >         try:
  >             msg = self.format(record)
  >             stream = self.stream
  >             # issue 35046: merged two stream.writes into one.
  >             stream.write(msg + self.terminator)
  >             self.flush()
  >         except RecursionError:  # See issue 36272
  >             raise
  >         except Exception:
  >             self.handleError(record)

  A probe with a stream whose first write fails with `ENOSPC` showed the next record written normally. `RecursionError`, `KeyboardInterrupt` and `SystemExit` are not caught. The guard is a convention each handler must follow, not something the framework enforces. Opening a file lazily was outside it until gh-135683, fixed after 3.15.0.

  The rotating handlers' own `emit`, which catches what `FileHandler.emit` raises, a `RecursionError` included:

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py

  >         try:
  >             if self.shouldRollover(record):
  >                 self.doRollover()
  >             logging.FileHandler.emit(self, record)
  >         except Exception:
  >             self.handleError(record)

- **A buffering handler.** `BufferingHandler.emit`, which `MemoryHandler` inherits, has no guard, and `MemoryHandler.flush` passes every buffered record to its target and clears the buffer only after the loop. If the target raises (a target whose `emit` has no guard, an error in its filters, or a `RecursionError`), the exception leaves `MemoryHandler.handle`, and under `QueueListener` it ends the listener thread (Inferred, from the probe below). The buffer is kept, so the next flush hands the target again the records it already took: a probe by the triage on CPython 3.9.6, whose code here has the same logic, showed `r0, r1, r0, r1, r2` delivered.

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py

  >         self.buffer.append(record)
  >         if self.shouldFlush(record):
  >             self.flush()

  >             if self.target:
  >                 for record in self.buffer:
  >                     self.target.handle(record)
  >                 self.buffer.clear()

- **A buffered file.** In a probe with a buffered text stream over a writer that failed three times, the bytes of records whose `emit` had reported an error stayed in the I/O buffer and reached the writer on a later flush. `logging` retries nothing; the I/O layer kept the bytes. This was a simulated writer, not a full disk.

- **A failed network send.** `SocketHandler` drops the record silently, with nothing on stderr, and backs off reconnecting, from 1 s doubling to 30 s, trying again only on a later record. `SysLogHandler` on a Unix socket reconnects and sends the same record once more; it is the only standard handler found that resends a failed record.

  Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py

  >             if self.unixsocket:
  >                 try:
  >                     self.socket.send(msg)
  >                 except OSError:
  >                     self.socket.close()
  >                     self._connect_unixsocket(self.address)
  >                     self.socket.send(msg)

  `HTTPHandler` reads the response and discards it, so an HTTP error status is not reported:

  >             h.getresponse()    #can't do anything with the result

- **`QueueListener`.** Its loop catches only `queue.Empty`; there is no guard around handling one record. A record is protected only by the handler's own `try`.

  >             except queue.Empty:
  >                 break

  A probe with a handler whose `emit` raised showed the thread dead after the first record, the next record left in the queue, and the second handler never seeing the first. Nothing restarts it on its own; there is no `is_alive` check in the package. `start()` on a dead listener raises `Listener already started`, because it tests whether a thread was set, not whether it lives. A user can call `stop()` then `start()`, but the stale stop marker makes the new thread exit once it has handled the backlog (probe). On a bounded queue that has filled, `stop()` raises `queue.Full` before it clears the thread, so `start()` still refuses (Inferred from the code).

**Stated why.**

- **Swallowing errors in handlers.** The documentation states it.

  Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst

  > The logging package is designed to swallow exceptions which occur while logging
  > in production. This is so that errors which occur while handling logging events
  > - such as logging misconfiguration, network or other similar errors - do not
  > cause the application using logging to terminate prematurely.

  Vinay Sajip, who wrote and maintains the package, in 2004 and 2020:

  Source: https://github.com/python/cpython/issues/40446#issuecomment-1093998127

  > production environments). This is because logging-related 
  > errors should not be treated in the same way as application 
  > errors (it's a pseudo-philosophical point, and not everyone will 
  > agree).

  Source: https://github.com/python/cpython/issues/84532#issuecomment-1093869632

  > I wouldn't go that far: logging is not a primary program function (i.e. the library or application should work exactly the same if logging were to be disabled).

  Inferred: both reasons are about being a guest in the application, not about the network.

- **Not retrying a failed write to a stream.** Vinay Sajip, on a proposed loop that retried a write for as long as it failed with `EAGAIN`:

  Source: https://github.com/python/cpython/issues/69645#issuecomment-1093696566

  > The problem with your suggested fix is that if you keep getting EAGAIN, the handler will appear to hang. If you want to suggest that maybe we limit the number of tries, then what number of retries would you pick, and why? Also, a caller might want to know about EAGAIN, so I'm not sure you'd want to (effectively) swallow it in the handler.

  > Perhaps a different strategy (than just trying for ever) would be better.

  The stream was the console, in an application with a custom `SIGPIPE` handler, which the reporter thought had triggered the error:

  Source: https://github.com/python/cpython/issues/69645#issuecomment-1093696565

  > The stream in this case (where I hit the bug) is just the console, but I

  > A key piece of information is that this is probably triggered by having a
  > custom SIGPIPE handler, which my particular application has.

  The reporter replied that they had capped their own retry, and the maintainer closed the issue as not a bug:

  Source: https://github.com/python/cpython/issues/69645#issuecomment-1093696567

  > In my particular case, I ended up implementing what your first
  > suggestion alludes to (a retry capped by a maximum).

  Source: https://github.com/python/cpython/issues/69645#issuecomment-1093696568

  > I will close this as not a bug. If you have custom signal handling which interacts with logging in an undesirable way, you will need to subclass the handler. The use case isn't common enough to be addressed in the base handler, IMO.

  Inferred: the reply objects to a loop with no limit and asks a limit to justify its number; it does not reject a capped retry, and the issue was closed because the case was not common enough for the base handler.

  And on a full local disk, in 2010:

  Source: https://github.com/python/cpython/issues/51913#issuecomment-1093489591

  > In any event, if you believe you can recover from the error, the right thing to do is to subclass the file handler you are using and override its handleError method to attempt recovery.

- **Not retrying a socket send on the same call.**

  Source: https://github.com/python/cpython/issues/84532#issuecomment-1093869634

  > Otherwise, if the remote end goes down and you keep retrying to connect on the same call, the handler would keep trying to connect and failing, and this could slow things down.

- **The guard in each `emit` rather than in `Handler.handle`.** A proposal to move it was declined for backward compatibility, and closed in 2022.

  Source: https://github.com/python/cpython/issues/70892#issuecomment-1093711465

  > Thanks for the suggestion, but I'm not sure this can be accepted without violating backward compatibility.

- **No guard and no restart in `QueueListener`.** No stated rationale found. Searched (`repo:python/cpython`): `QueueListener` (all 53 titles read), `QueueListener thread dies`, `QueueListener dies`, `QueueListener "stops processing"`, `QueueListener _monitor exception`, `QueueListener restart`, `QueueListener is_alive`, `QueueListener exception`, `QueueListener handleError`, `QueueListener silently`. The history followed (bpo-27930, bpo-36813, gh-114706, gh-132106) does not discuss an exception escaping a handler. PEP 282 says nothing on handler errors.

- **`SysLogHandler`'s resend.**

  Source: https://github.com/python/cpython/commit/a1974c1459a424fdc9d8bbce55500f6006d0297d

  No stated rationale found: the 2005 commit says "Improved SysLogHandler error recovery (patch by Erik Forsberg)".

**Constraints.** In-process; the logging package is meant never to change what the application does. The handler lock is held during `emit`; Inferred: a handler that retried in place would block every thread logging through it. The `EAGAIN` reply says only that the handler "will appear to hang". `QueueListener` is a daemon thread, and `dictConfig` creates one but never watches it. The cookbook puts handlers that block behind a `QueueListener`, so that they run on its thread; there a hang would hold up the records queued behind it, not the application (Inferred).

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging-cookbook.rst

> Sometimes you have to get your logging handlers to do their work without
> blocking the thread you're logging from.

>    application, to use the above approach for logging, so that any blocking code
>    runs only in the ``QueueListener`` thread.

**Costs and dissent.**

- Records lost over TCP drew dissent in 2020 (gh #84532), answered with "logging is not a primary program function". In 2026 Serhiy Storchaka, a core developer, reopened it with a PR that resends the record once after a reconnect, as `SysLogHandler` does. It is open.

  Source: https://github.com/python/cpython/pull/154540

  > It now reopens the socket and sends the record again, like `SysLogHandler.emit()` has done for the Unix socket since 2.5.

- In 2004 to 2007 the maintainer described `raiseExceptions` as raising the error; the code has printed and returned since the first commit. A user pointed out the mismatch in 2016 (gh #70892).

### L7. ddtrace (dd-trace-py)

**Analogy.** Close: an in-process library whose periodic thread flushes batches of traces over a network to a local agent. Unlike L2 to L6, it retries a failed batch in the writer itself before dropping it.

**What it does.** `dd-trace-py` `v4.17.2` (`214d58422664`), and libdatadog `v46.1.2` (`f7f0da73e2d7`), the revision its native code builds against. The default trace writer is `NativeWriter`, which sends through libdatadog in Rust; the Python `HTTPWriter` remains only for CI Visibility uploads.

- **Retry, then drop.** The native exporter retries a failed send five times, so up to six attempts, with exponential backoff from 100 ms (3.1 s of waiting in all, plus each attempt's own timeout, Inferred). It retries HTTP 4xx and 5xx and transport errors.

  Source: https://github.com/DataDog/libdatadog/blob/v46.1.2/libdd-trace-utils/src/send_with_retry/retry_strategy.rs

  > impl Default for RetryStrategy {
  >     fn default() -> Self {
  >         RetryStrategy {
  >             max_retries: 5,
  >             delay_ms: Duration::from_millis(100),
  >             backoff_type: RetryBackoffType::Exponential,
  >             jitter: None,
  >         }
  >     }
  > }

  The Python `HTTPWriter` makes three attempts (five for CI Visibility) with Fibonacci jitter, under 0.2 s of waiting, and retries exceptions only, not HTTP error responses. Both run on the writer's thread and block it until done (Inferred for the native one).

- **The guard.** After the retries, an `except Exception` drops the payload, logs at ERROR (one record per call site per 60 s through the ddtrace logger) and the loop goes on at the next interval.

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py

  >         try:
  >             self._send_payload(encoded, n_traces, client)
  >         except Exception as e:
  >             if raise_exc:
  >                 raise
  >
  >             msg = "failed to send, dropping %d traces to intake at %s: %s"

- **What escapes.** The periodic thread has been C++ since PR #7659 (2024). An exception that leaves the target is printed and ends the loop, as the thread's own documentation says. The printing is CPython's `PyErr_Print()`, which exits the process when the exception is `SystemExit`; Inferred from the code, not run: a `SystemExit` that leaves the target can end the application's process, not only the loop.

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/_threads.pyi

  >     The target callable is invoked repeatedly at interval seconds. If
  >     target returns the PERIODIC_STOP sentinel the loop exits cleanly
  >     after that iteration (on_shutdown is still called). Returning any other
  >     value continues the loop; raising an exception prints the traceback and also
  >     stops the loop.

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/_threads.cpp

  >     if (result == NULL)
  >         PyErr_Print();

  Source: https://github.com/python/cpython/blob/v3.15.2/Doc/c-api/exceptions.rst

  >    Print a standard traceback to ``sys.stderr`` and clear the error indicator.
  >    **Unless** the error is a ``SystemExit``, in that case no traceback is
  >    printed and the Python process will exit with the error code specified by
  >    the ``SystemExit`` instance.

  Inferred: a Rust panic in the send's own future, which libdatadog's runtime polls on the writer's thread, reaches Python as `PanicException`, a `BaseException` that `except Exception` does not catch, so it stops the writer. At the tag a panic is caught only on the exporter's shutdown path.

  Source: https://github.com/DataDog/libdatadog/blob/v46.1.2/libdd-shared-runtime/src/shared_runtime/fork_safe.rs

  >     fn block_on<F: std::future::Future>(&self, f: F) -> Result<F::Output, io::Error> {
  >         let runtime = match self.runtime.lock_or_panic().as_ref() {
  >             None => Arc::new(Builder::new_current_thread().enable_all().build()?),
  >             Some(runtime) => runtime.clone(),
  >         };
  >         Ok(runtime.block_on(f))
  >     }

  A panic in a task spawned onto that runtime would end only that task; whether the HTTP client spawns one was not traced.

- **Restart.** None after a crash. The writer's status is a flag set by `start()` and `stop()`; a dead thread leaves it at `RUNNING`, so the check that starts the writer on its first write never fires again (Inferred from the code). Around a fork, ddtrace stops every running periodic thread and restarts it afterwards in the parent; in the child the writer opts out, and the tracer builds a new writer on the next span. A thread that has already died has left the map of running threads, so the parent's restart after a fork does not bring it back. In the child, the fork hook marks the writer for rebuilding whatever the parent's writer's state, and the next span builds a new one, so a forked child starts with a live writer even if the parent's had died (Inferred from the code).

**Stated why.**

- **Retrying in the native exporter.** Ekump, a libdatadog collaborator, in PR #433 (2024):

  Source: https://github.com/DataDog/libdatadog/pull/433

  > In order to turn the sidecar on by default for PHP there needs to be support for retries when flushing traces fail. Adding the retry logic to trace_utils made the most sense (and can be used outside of the sidecar)

  Inferred: the reason is a product need for one runtime's sidecar; the PR gives no reason about failures as such.

- **Retrying in the Python writer.** P403n1x87, a maintainer, in PR #2459 (2021):

  Source: https://github.com/DataDog/dd-trace-py/pull/2459

  > This change introduces a Fibonacci retry policy (with jitter) to the agent writer to mitigate networking issues (e.g. timeouts, broken pipes, ...), similar to what the profiler does already.
  >
  > Memory usage might increase up to an extra payload buffer size, meaning that occasionally the tracer would require about 8MB more memory for processing. That is because the buffer will start filling up again while the writer retries flushing the previous payload.

  Inferred: the reason is about the network. The PR names its cost in memory. The issue behind it, #1413, reported timeouts to the agent; a maintainer then thought the agent was overloaded.

- **Restarting after a fork.** PR #14163 (2026):

  Source: https://github.com/DataDog/dd-trace-py/pull/14163

  > We refactor the native periodic thread implementation to be fork-safe whereby all such threads that are running at the time of a fork are automatically stopped before the fork, then restarted after it.

  > Some of the implications of this change are that there is no longer the need for fork-safe synchronisation objects, such as Locks and Events. This is because all (ddtrace) threads are guaranteed to be stopped before a fork, and restarted afterwards.

  > Stopping and restarting threads can be expensive but gives good fork-safety guarantees. Because threads have to be joined before the fork can continue, a forked process might get delayed by a thread currently busy on I/O.

  The reason given is fork safety without fork-safe locks and events; the cost named is a fork delayed while a busy thread is joined. Why the child's new writer waits for the next span, from the tracer's code:

  Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/_trace/tracer.py

  >         # Celery and other process managers close inherited file descriptors after Python's
  >         # at-fork callbacks return. Recreating the native writer here would start Tokio early
  >         # enough for those descriptor sweeps to invalidate its I/O driver.

- **Stopping the loop on an exception, not restarting a dead writer, and catching `Exception` rather than `BaseException` around a send.** No stated rationale found for any of the three. Searched (`repo:DataDog/dd-trace-py`): `"writer thread" died`, `"stopped sending traces"`, `writer thread dead`, `restart writer thread` (top results read), `periodic thread exception stops`, `PanicException writer`, `AgentWriter thread not running`, `traces stop after` (top results read), `"writer thread is not alive"`, `"Exception in thread ddtrace.internal.writer"`, `writer "restart the application" traces`, `periodic thread died`, `"cannot fit trace" "writer status: running"`, `watchdog writer thread`; blame on the guard, the retry, `autorestart=False` and the C++ loop through PRs #2459, #5998, #13071, #18262, #18277, #7659 and #14163.

**Constraints.** In-process; it sends to a Datadog agent (Inferred: usually on the same host or node), and the issue behind the Python retry was timeouts to that agent. The thread is C++ so as to depend less on Python's `threading` module, which gives trouble under gevent (PR #7659). Pre-fork servers drive the fork handling.

**Costs and dissent.**

- A writer thread died in the field and stayed dead until the application restarted (#7411, 2023).

  Source: https://github.com/DataDog/dd-trace-py/issues/7411

  > this keeps happening for several of our Python applications. The only way to fix it is to restart the application.

  The fix (PR #7413) removed the code path that raised; it added no restart and no wider guard.

- The retry delays later batches and costs memory (PR #2459's own note above), and the PR's author named a cost when the agent is down.

  Source: https://github.com/DataDog/dd-trace-py/pull/2459#issuecomment-844976018

  > However, when the agent is not available, or unreachable over the majority of the connection attempts, there is a slight impact from attempting to connect multiple times in a row.

### L8. sentry-python

**Analogy.** Close: an in-process library whose background thread sends queued envelopes over a network. It is the one comparable whose worker comes back after it stops.

**What it does.** `sentry-python` `3.0.0` (`cf984b15a3d7`); its predecessor `raven-python` at `6.10.0` (`d7d14f61b7fb`) for history; Sentry's SDK development documentation (`getsentry/sentry-docs` at `feaece23fe2a`, unversioned).

- **The restart.** `BackgroundWorker.is_alive` is false when the process id differs from the one that started the thread, when there is no thread, or when the thread is not alive. Every `submit` first calls `_ensure_thread`, which starts a new thread on the same queue whenever `is_alive` is false.

  Source: https://github.com/getsentry/sentry-python/blob/cf984b15a3d7d6c96b22d8f572d63ff8777eb418/sentry_sdk/worker.py

  >         if self._thread_for_pid != os.getpid():
  >             return False
  >         if not self._thread:
  >             return False
  >         return self._thread.is_alive()

  >     def submit(self, callback: "Callable[[], Any]") -> bool:
  >         self._ensure_thread()

  There is no counter, backoff or cap. The transport's `flush` submits before it waits, so it restarts the worker too. No timer or watchdog checks the worker (Inferred: a dead worker is noticed only on the next submit). The callback that was running when the thread died is lost. The experimental async transport (`_experiments.transport_async`, with `AsyncioIntegration`) uses an `AsyncWorker` that restarts the same way on the next submit, but `start()` makes a new queue, so the callbacks still waiting in the old one are lost too (Inferred from the code).

  >                 # Always create a fresh queue on start to avoid stale items
  >                 self._queue = asyncio.Queue(maxsize=self._queue_size)

  Source: https://github.com/getsentry/sentry-python/blob/cf984b15a3d7d6c96b22d8f572d63ff8777eb418/sentry_sdk/transport.py

  >     use_async_transport = options.get("_experiments", {}).get("transport_async", False)

- **The guard.** One `except Exception` around each callback logs "Failed processing job" and the loop goes on. Envelope sends are also wrapped in `capture_internal_exceptions()`, whose `__exit__` returns true for every exception, `SystemExit` included. Only a few things can still escape: the flush callback, which is not wrapped, the queue calls and the logging call.

  Source: https://github.com/getsentry/sentry-python/blob/cf984b15a3d7d6c96b22d8f572d63ff8777eb418/sentry_sdk/worker.py

  >                 try:
  >                     callback()
  >                 except Exception:
  >                     logger.error("Failed processing job", exc_info=True)

- **The queue.** Bounded at 100 by default; on overflow the envelope is dropped and counted as `queue_overflow`.

- **A failed send.** Dropped and never re-sent by sentry-python. A network error or an unexpected status is counted as `network_error`, a 413 as `send_error`. A 429 drops the envelope without counting it, since Sentry's server has recorded it already. An `x-sentry-rate-limits` header, on any status, sets back-offs for later sends; a 429 without it sets one from `Retry-After`, or 60 s. Inferred from urllib3's defaults, which sentry-python does not override: a connection timeout is retried up to three times inside the one request. The httpcore transports set three retries explicitly.

- **Other threads.** The log, metric and span batchers, the health monitor and the session flusher compare only the process id. A thread of theirs that dies in the same process is not restarted.

**Stated why.**

- **The restart was written for fork, not for a crash.** The liveness check came from raven-python PR #583 (2015):

  Source: https://github.com/getsentry/raven-python/commit/251a8728edc6f1365cfd3592c8bd63f976bfe7b4

  > Forking a process doesn't clone the threads. If the worker was already
  > active in the parent process, the child process would be stuck with
  > a worker with a stopped thread which wouldn't send any messages.

  Pankrat, a contributor, in the pull request; a maintainer merged it without further reason:

  Source: https://github.com/getsentry/raven-python/pull/583

  > This is relevant when using Gunicorn in preload mode when messages are already logged in the preload phase:

  The process-id check and the restart on enqueue came from raven-python PR #700 (2015), by Armin Ronacher, fixing lost events under uWSGI's pre-fork model (raven #590).

  Source: https://github.com/getsentry/raven-python/pull/700

  > This spawns a thread again first time on queue if the process was forked in the meantime.
  >
  > Fixes GH-590

  sentry-python PR #45 (2018) ported it.

  Source: https://github.com/getsentry/sentry-python/pull/45

  > This uses the same logic as the old raven python background worker which is to block in the atexit running thread on the lock the background worker has.

  The experimental async worker's restart: no stated rationale found beyond its PR's description, by srothh (role not verified). Searched: `repo:getsentry/sentry-python AsyncWorker is:pr` (PRs #4572, #4591, #4614, #5646, read in full).

  Source: https://github.com/getsentry/sentry-python/pull/4591

  > This worker mostly mirrors the same functionality as the thread-based worker, with the exception that it exposes a non-blocking async flush (which can be awaited from an async context).

  > I have kept the fork check from the threaded worker, but I am not sure if it is necessary as forking in an async application would also break the event loop.

  No stated rationale found for recovering from a crash. Inferred: a thread that an escaping exception killed is not alive, so the same path restarts it, as a side effect of a check written for fork.

- **A crash was answered by a guard, twice.** In 2013 raven's worker died on a `urllib` timeout:

  Source: https://github.com/getsentry/raven-python/issues/254

  > This is because the urllib timeout exception terminates the AsyncWorker thread, and there's nothing left to process the queue.

  Source: https://github.com/getsentry/raven-python/commit/7a49a5ad2d8f521ec55fd653058e91324f01d341

  The fix added the per-callback `try`, not a restart ("Gracefully handle errors in threaded worker (fixes GH-254)"). In 2026 sentry-python's log batcher thread died on a `RuntimeError` (#7138); its process-id-only guard did not restart it. The fix, PR #7186, approved by a maintainer, catches each flush instead, and its code comment gives the why.

  Source: https://github.com/getsentry/sentry-python/blob/cf984b15a3d7d6c96b22d8f572d63ff8777eb418/sentry_sdk/_batcher.py

  >             # A failure to serialize or send one batch must not kill the
  >             # flusher thread. If it did, the buffer would keep filling with
  >             # nothing draining it, and every later log or metric would be
  >             # dropped for the rest of the process lifetime. Swallow and log
  >             # the error instead so the loop keeps running.

- **Not retrying a failed send.** Sentry's SDK specification:

  Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/transport/index.mdx

  > We do not recommend that SDKs retry event submissions automatically on error — not even if `Retry-After` is declared in the response headers. If a request fails once, it is very likely to fail again on the next attempt. Retrying too often may cause further rate limiting or blocking by the Sentry server.

  Inferred: the reason is about a remote server that may be down or limiting the client. The same specification allows retry only with an optional disk buffer meant for clients that are often offline, with a cap on what it stores; sentry-python does not implement it.

  Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/transport/offline-caching.mdx

  > This feature is mostly useful on mobile and desktop apps, where stable connectivity is often not available.

  A failure in that disk buffer that is the SDK's own, not the network's, is not retried:

  > When other failures occur, like those caused by processing the file in the SDK itself, SDKs **MUST** discard the envelope and record a [client report](/sdk/telemetry/client-reports/#network-failure-recording) with the discard reason `internal_sdk_error`. Otherwise, the SDK might end up in an endless retry loop.

- **Not raising a failed send.** Ericapisani, a member of the organisation, in 2026:

  Source: https://github.com/getsentry/sentry-python/issues/7844

  > If an exception were to be raised at this point without a custom transport to catch it, the SDK could break user applications.

- **The bounded queue.** An application ran out of memory when events queued faster than a slow server drained them (#586); a maintainer replied "the queue is unbounded. We'll fix that."

  Source: https://github.com/getsentry/sentry-python/issues/586

  Searched (`repo:getsentry/sentry-python` unless noted): `BackgroundWorker`, `"worker thread"`, `fork thread`, `_ensure_thread`, `restart worker`, `uwsgi threads`, `gunicorn preload`, `"thread died"`, `"Failed processing job"`, `retry transport`; `repo:getsentry/raven-python`: `fork thread`, `AsyncWorker`, `restart thread`; blame and `git log -S` through PR #45 to raven commits `251a8728` and `6f0ad823`.

**Constraints.** In-process; pre-fork web servers (gunicorn with preload, uWSGI) behind the restart; a remote service that rate-limits behind the refusal to retry; the rule that the SDK never raises into the application.

**Costs and dissent.**

- The process-id-only guard on the batchers let a dead thread go unnoticed, and every later log, metric and span was dropped for the life of the process (#7138). The fix added a guard, as the issue's title asked; no restart was discussed in the issue or the pull request (#7138, PR #7186).
- In 2020 a design whose thread quits when idle and is started again on demand was tried and closed unmerged: "thread restart was deemed too risky if the queue often hits zero" (PR #819). That is a deliberate stop, not a crash.

  Source: https://github.com/getsentry/sentry-python/pull/819

- An open issue (#6164) reports that after a fork the lock the worker inherits can deadlock the child.
- No issue was found asking to cap restarts or reporting restart churn.

## Pipeline agents

Each is a process of its own whose job is delivery.

### P1. Fluent Bit

**Analogy.** Loose: a delivery agent, a process of its own, that buffers chunks in memory or on its own disk and retries a failed output. It is not a guest in an application.

**What it does.** Fluent Bit `v5.2.0` (`e0149076aeff`); documentation branch `5.2` of `fluent-bit-docs` (`adb8533c5491`).

- **The default retry limit is 1, and it counts retries, not attempts.** An output returns OK, Retry or Error; the engine decides what happens.

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/src/flb_output.c

  >         FLB_CONFIG_MAP_STR, "retry_limit", "1",

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/src/flb_task.c

  >         retry->attempts = 1;

  >             if (retry->attempts >= ins->retry_limit && ins->retry_limit >= 0) {

  Inferred from the code: a chunk is sent at most N + 1 times, so twice by default. Users measured the same: `Retry_Limit 5` gave six sends (#12739). The documentation calls N "the maximum number of retries".

- **At the limit the chunk is discarded and counted.**

  Source: https://github.com/fluent/fluent-bit-docs/blob/5.2/administration/scheduling-and-retries.md

  > When a chunk exhausts all retry attempts or retries are disabled, the data is discarded by default.

  The counters `fluentbit_output_retries_failed_total` and `fluentbit_output_dropped_records_total` go up. If the dead-letter queue (`storage.keep.rejected`) is on, the chunk is kept on disk instead.

- **Exceptions.** An `Error` return is dropped with no retry. The S3 output raises its own default to 5, and by default moves a chunk that exhausts it to a quarantine directory rather than deleting it. Waiting out a throttle cooldown or a flush limit does not count against the limit. Separately, with disk buffering, `storage.total_limit_size` evicts the oldest chunks whatever their retry count.

  > - `Error`: An unrecoverable error occurred and the engine shouldn't try to flush that data again.

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/plugins/out_s3/s3.c

  >      FLB_CONFIG_MAP_STR, "retry_exhausted_action", "quarantine",

- **Backoff.** "Full jitter": a wait drawn between the base (5 s) and `min(cap, base × 2^n)`, the cap 2000 s; both configurable since 1.8.7.

**Stated why.**

- **The default of 1.** No stated rationale found. It was added in commit `26768d96bc` (2016), whose whole message is "scheduler: engine: functional buffer retry". The only later change was the documentation corrected from "2" to "1" to match the code (docs PR #272).

  Source: https://github.com/fluent/fluent-bit/commit/26768d96bc9938163561b99616a829ad686e1ea7

  Searched: `repo:fluent/fluent-bit "retry_limit" default` (474 hits, titles skimmed), `"Retry_Limit" default value`, `retry_limit default 1`, `"retry limit" default unlimited`, `retry_limit default "data loss"`, `"chunk cannot be retried"`, `commenter:edsiper retry_limit default`, `"retry_limit" default "no_limits" is:issue`, `retry_limit infinite`, `Retry_Limit no_limits default`, `retry limit default 1`; `repo:fluent/fluent-bit-docs`: `retry_limit default`, `"Retry_Limit"`. The tags from v0.8.0 to v0.13.0 were read to date the default.

- **Plugins report and the engine decides; jitter spreads retries; no retry timeout.** Eduardo Silva, the maintainer, in 2020:

  Source: https://github.com/fluent/fluent-bit/issues/2377#issuecomment-662759900

  > Note that output plugins never drops a message, it only reports FLB_OK (success), FLB_RETRY (ask for a retry), FLB_ERROR (unrecoverable error).

  > That one exists because we don't want to have all the retries at the same time. Implementing a retry timeout can generate other bad side-effects.

- **The S3 output's 5.** Its code comment:

  Source: https://github.com/fluent/fluent-bit/blob/v5.2.0/plugins/out_s3/s3.c

  >      * The engine default retry_limit (1) is too low for S3's internal
  >      * retry system — partially uploaded multipart data is wasted when
  >      * retries are exhausted too early. Default to MAX_UPLOAD_ERRORS (5)

**Constraints.** A process of its own, often a node agent or sidecar, whose job is delivery. A chunk under retry can be moved to disk. Inferred, as no author says so: the limit bounds how many times the engine retries a chunk that an output asked to retry, and with the backoff cap it bounds the scheduled waits between those retries. It is not a limit on how long the chunk is held: the attempts themselves and waits for a throttle cooldown or a flush limit do not count against it, and the maintainer questioned the use case for a retry timeout and warned of side effects, without a recorded decision (above).

**Costs and dissent.**

- A user lost what was buffered during an outage of the destination, with the default (#5774, 2022).

  Source: https://github.com/fluent/fluent-bit/issues/5774

  > First we used the default value for `Retry_Limit` (=1). In a previous loki incident we noticed for all applications that log via fluentbit into loki all logs that were buffered to disk in time where loki was unhealthy were lost.

- The 2000 s cap was too long for others: "Because the retry is *so* long, it backs up an enormous amount of data, and then drops."

  Source: https://github.com/fluent/fluent-bit/issues/3597#issuecomment-856741067

- `storage.total_limit_size` drops the oldest data rather than pausing inputs, so data already read from a tailed file is gone (#12693, open, no reply).

### P2. OpenTelemetry Collector

**Analogy.** Loose: a delivery agent or gateway, a process of its own, with a sending queue in memory or on its own disk and retry in each exporter.

**What it does.** `opentelemetry-collector` `v0.166.0` (`4b5ae43f8998`), `exporter/exporterhelper`. The OTLP exporters turn retry and the sending queue on.

- **Two separate drop points.** (a) Time: a queued batch is retried in place with backoff (5 s, ×1.5, to 30 s) until the next retry would start after `max_elapsed_time` (5 minutes by default) has passed, and then dropped, whether or not the queue has room. The budget is checked before each wait and does not cut short an attempt already sent (Inferred from the code).

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/internal/retry_sender.go

  > 		if !maxElapsedTime.IsZero() && maxElapsedTime.Before(nextRetryTime) {
  > 			// The delay is longer than the maxElapsedTime.
  > 			return fmt.Errorf("no more retries left: %w", err)
  > 		}

  (b) Capacity: when the queue is full (1000 requests by default), new data is refused as it arrives, unless `block_on_overflow` is set, and never reaches retry.

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/README.md

  > If data is rejected before entering the queue, it does not reach the exporter retry logic. Such enqueue failures are reported by the `otelcol_exporter_enqueue_failed_*` metrics.

  The persistent queue on the Collector's own disk drops in the same way when its storage fails:

  > **Failure behavior**: If data cannot be added to the sending queue, it is typically dropped. This occurs when the queue has reached its configured capacity or, for persistent queues, when the underlying storage cannot accept additional data (for example, due to insufficient disk space or I/O errors).

  The queue itself does not retry a write its storage refuses: `Offer` returns the error from the storage batch to its caller (Inferred from the code).

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > 	if err := pq.client.Batch(ctx, ops...); err != nil {
  > 		// At this moment, metadata may be updated in the storage, so we cannot just revert changes to the
  > 		// metadata, rely on the sizes being fixed on complete draining.
  > 		return err

  A batch under retry keeps its queue slot until it finishes, in both queue types, so in an outage the batches being retried and the new arrivals fill the queue together (Inferred). `max_elapsed_time: 0` retries forever (since v0.96.0).

- **Permanent errors are dropped at once.** The exporter decides: OTLP/HTTP retries only 429, 502, 503 and 504; OTLP/gRPC only the retryable codes.

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/internal/retry_sender.go

  > 		// Immediately drop data on permanent errors.

- **Shutdown.** Retry stops first. The memory queue gives each queued item one more attempt, then loses what is left; the persistent queue stops reading at once and keeps what it has not read, untried, for the next start (the persistent queue's behaviour Inferred from the code).

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/exporter/exporterhelper/internal/queue/persistent_queue.go

  > 		if pq.stopped {
  > 			var req T
  > 			return context.Background(), req, nil, false
  > 		}

- **History.** The claim describes the old `queued_retry` processor, which dropped a permanent failure at once, dropped any failure when retry was off, and otherwise put a failed batch back at the end of the queue, dropping it only when the queue was full. PR #1386 replaced it from July 2020, and PR #2380 removed it in January 2021. The persistent queue also re-queued until v0.92.0 (PR #9090).

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/cf07737f906cd8460dd451761a07ecc36a407c9c/processor/queuedprocessor/queued_processor.go

  > 	if !sp.queue.Produce(item) {
  > 		item.onDropped(sp.logger, fmt.Errorf("failed to re-enqueue: %w", err))

**Stated why.**

- **Retrying in place rather than re-queuing.** Bogdan Drutu, a maintainer, in PR #1386:

  Source: https://github.com/open-telemetry/opentelemetry-collector/pull/1386#discussion_r456551760

  > It will retry the same request until either the exporter returns a permanent error, or the max elapsed time expires. Will not add it back to the queue, because we should try to preserve the order of exporting as much as possible.

  Dmitrii Anoshin, a maintainer, when re-queuing was removed from the persistent queue:

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1852517892

  > The amount of data kept in memory is always restricted by the number of queue workers. And they are always busy, it doesn't matter if we keep the same data for backoff retry or keep pushing data back and forth to the queue. In fact, the latter takes even more memory due to constant marshaling/unmarshaling with GC catching up.

- **Refusing rather than blocking when full.** Bogdan Drutu in 2022, before `block_on_overflow` was added as an option:

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/5456#issuecomment-1145100515

  > We try to keep the design very simple, and ensure that the pipeline returns immediately and the "caller" will take the right action. This is because in case of a "push" receiver you don't want to block the call, but let the caller know that you are having troubles.

- **The queue size.** Reduced from 5000 to 1000 in v0.77.0 for memory. The issue, by swiatekm, a contributor, said the queue "shouldn't try to cover for a prolonged remote unavailability"; the size was settled at a SIG meeting.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/7359

- **The 5 minutes.** No stated rationale found. PR #1386 set it; no comment in its thread mentions it. The OTLP exporter it replaced had a hard-coded 15 minutes:

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/cf07737f906cd8460dd451761a07ecc36a407c9c/exporter/otlpexporter/otlp.go

  > 	// Spend max 15 mins on this operation. This is just a reasonable number that
  > 	// gives plenty of time for typical quick transient errors to resolve.

  Searched (`repo:open-telemetry/opentelemetry-collector`): `max_elapsed_time default`, `"queued_retry" exporterhelper retry queue is:pr`, `retry_on_failure data loss drop`, `queued retry exporterhelper is:pr created:2020-06-01..2020-09-30`, `"MaxElapsedTime" is:pr created:2020-01-01..2020-12-31`. Three more searches hit the rate limit; their subjects were covered through `CHANGELOG.md` and by opening #5456.

**Constraints.** A process of its own, an agent or a gateway. Receivers are mostly push, so the pipeline returns an error to the sender rather than block it. Memory is bounded by the queue and the number of consumers. The persistent queue is the documented way to survive a restart.

**Costs and dissent.**

- Users expect nothing to be dropped while the queue has room.

  Source: https://github.com/open-telemetry/opentelemetry-collector/issues/8382#issuecomment-1719017233

  > Requeueing as implemented is how a lot of users intuitively expect the queue to work, in my experience. That is, they expect no data to be dropped if the queue still has room. And this behaviour is difficult to reproduce by adjusting retry settings.

- A retry count rather than a time limit was asked for (#15274, open); the maintainer wants more demand first.
- A maintainer drafted re-queuing as an option, including for the memory queue (#8993), and dropped it after Bogdan Drutu worried it would confuse users.

### P3. Prometheus remote-write

**Analogy.** Loose: a long-running server, or an agent, that tails its own write-ahead log on local disk and sends to a remote store. The local log is its buffer.

**What it does.** Prometheus `v3.16.0` (`e2e28adeee2c`). The tuning page and the remote-write specifications live in `prometheus/docs`, which has no release tags; read at `main`, `31957d4da93d`.

- **A recoverable failure is retried with no limit.** Network errors and HTTP 5xx are recoverable, and so is 429 when `retry_on_http_429` is set (off by default). The loop leaves only on success, a non-recoverable error, or the queue being shut down or resharded; the attempt counter is never compared with a limit. Backoff doubles from 30 ms to 5 s.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/storage/remote/queue_manager.go

  > 		// If we make it this far, we've encountered a recoverable error and will retry.
  > 		onRetry()
  > 		t.logger.Warn("Failed to send batch, retrying", "err", err)
  >
  > 		backoff = min(sleepDuration*2, t.cfg.MaxBackoff)
  >
  > 		try++

  A non-recoverable failure (any other 4xx, a request that cannot be built) drops the batch and counts it in `prometheus_remote_storage_samples_failed_total`. Shutdown drops what is buffered and counts it the same way.

- **"Two hours" is not a retry limit.** It is a sentence on the tuning page about the local log.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/practices/remote_write.md

  > When one shard backs up and fills its queue, Prometheus will block reading from
  > the WAL into any shards. Failures will be retried without loss of data unless
  > the remote endpoint remains down for more than 2 hours. After 2 hours, the WAL
  > will be compacted and data that has not been sent will be lost.

  Truncating the log does not ask remote-write how far it has read, and its own comment puts the figure nearer three hours.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/tsdb/head.go

  > 	// With the default 2h blocks, this will keeping up to around 3h worth
  > 	// of WAL segments.

  Inferred from the code, no source states the sequence: while a batch retries, its queue fills and reading from the log stops; truncation deletes segments not yet read; the reader restarts from the current time and skips what it missed; the batch in memory keeps retrying. In agent mode, truncation runs every two hours by default and cuts the log at a point that keeps at least 5 minutes behind what remote-write has sent and at most 4 hours; these bound the cut, not when data is deleted.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/tsdb/agent/db.go

  > // walTruncationTime returns the timestamp before which inactive series may be
  > // truncated from the WAL, keeping between MinWALTime and MaxWALTime of data.

- **`max_retries` was removed** in 2.11.0 (PR #5649): "We retry endlessly for recoverable errors."

  Source: https://github.com/prometheus/prometheus/pull/5649

- **`sample_age_limit`** (2.50.0, PR #13002) drops samples older than a limit, on each retry too; it is off by default and does not stop the loop.

**Stated why.**

- **Retrying without limit.** Callum Styan and Tom Wilkie, who wrote the log-based remote-write, in 2019 (both members of the organisation, not then listed as maintainers):

  Source: https://github.com/prometheus/prometheus/issues/5636#issuecomment-499536539

  > Yes, the new remote write is intended to never drop samples. So there is no max retries, it retries until it succeeds or the queue manager is shut down for some reason.

  Source: https://github.com/prometheus/prometheus/issues/5636#issuecomment-499577509

  > The ongoing aim for remote write is for reliability and to not drop samples.

  Brian Brazil, a maintainer, on the log being deleted: "The WAL files will typically get deleted after a few hours, as that's all independent of the remote write logic."

  Source: https://github.com/prometheus/prometheus/issues/5636#issuecomment-499637268

- **Retrying 5xx, and not 4xx other than 429.** The 1.0 specification:

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/specs/prw/remote_write_spec.md

  > They MUST NOT retry write requests on HTTP 2xx and 4xx responses other than 429. They MAY retry on HTTP 429 responses, which could result in senders "falling behind" if the server cannot keep up.

  > This is done to ensure data is not lost when there are server side errors, and progress is made when there are client side errors.

- **The local log as the buffer.** Callum Styan, a maintainer by then, in 2024:

  Source: https://github.com/prometheus/prometheus/issues/13539#issuecomment-1930446215

  > The WAL is used as an additional on-disk buffer for remote write, regardless of whether agent mode is being used. If you disabled the WAL you'd need to buffer all data in memory and then either start dropping samples when the buffer is full or buffer infinitely and OOM the process.

- **Order.** Chris Marchbanks, a maintainer: "We cannot prioritize sending newer samples as a guarantee of remote write is that samples are ordered." A batch that retries therefore holds up its shard.

  Source: https://github.com/prometheus/prometheus/issues/7912#issuecomment-737544041

- **Moving remote-write onto the log.** PR #4588's body says what, not why, and its review links no design document. Its first commit, by Callum Styan, gives the why and the limits it started with:

  Source: https://github.com/prometheus/prometheus/commit/1ef17dbf3d019b13bc5adba3247ab9bacc51809d

  > This change switches the remote_write API to use the TSDB WAL.  This should reduce memory usage and prevent sample loss when the remote end point is down.

  > As part of this change, we attempt to guarantee that samples are not lost; however this initial version doesn't guarantee this across Prometheus restarts or non-retryable errors from the remote end (eg 400s).

  No design document was found. Searched (`repo:prometheus/prometheus`): `remote write read from WAL`, `author:tomwilkie remote write WAL`, `"docs.google.com" remote write WAL tailing`, `remote write WAL in:title created:<2019-03-01`, `remote write design doc WAL "docs.google.com" created:2018-01-01..2019-06-01`, `"max_retries" remote write`, `sample_age_limit`, `remote write drop old samples is:issue`, `remote write "2 hours" data lost is:issue`.

**Constraints.** A process of its own whose purpose includes delivery; a local log on disk as the buffer; per-series order promised by the protocol; the receiver says what may be retried (5xx yes, 4xx no, except that a sender may retry 429). No remote-write position survives a restart (#8809, open).

**Costs and dissent.**

- A bounded retry was asked for three times and never adopted. In 2019 a user wanted `max_retries` "as a circuit breaker" after retry storms took down a gateway; the answer was to raise `max_backoff`.

  Source: https://github.com/prometheus/prometheus/issues/5636#issuecomment-499563362

  > However in a use case of persistent 500 e.g. due to problem on the server side, this can cause retry storms, in fact I've observed this in large scale testing. If sharding is set fairly high and all samples are failing, the effect is aggravated and can cause connection storming as well. I brought down our QA gateway that way. I think max_retries is needed as a circuit breaker.

  PR #8549 (2021), a retry policy by age and by count, was closed unmerged in 2023; a maintainer noted "disagreements over this on the mailing list and the doc". Issue #10785 (2022) asked again and was closed with no change.

  Source: https://github.com/prometheus/prometheus/pull/8549#issuecomment-787842864

- Retrying forever then losing data: "the agent keeps retrying forever, which prevents sending the new samples to prometheus server. Then all samples are lost after several hours."

  Source: https://github.com/prometheus/prometheus/issues/14126

- PR #8549's design document (Harkishen Singh, 2021) and its mailing-list thread were read through the document's text export and the thread's public page; neither has a version. The author proposed dropping a batch after a number of retries because some "samples will always be rejected by the system", and resending them costs both sides:

  Source: https://docs.google.com/document/d/1pC5GjMkSe4YHFqVMp0ZX9C1Iih8QLOnnBG-HguKzwrM/export?format=txt

  > The above are some problems that lead to an unnecessary increase in bandwidth in both the parties (Prometheus and Remote-storage system). Further, the memory and CPU increases are significant as well.

  Tom Wilkie answered on the list:

  Source: https://groups.google.com/g/prometheus-developers/c/2PEY4o5tgoI

  > My main concerns are that we preserve the lossless nature of the remote write, and I worry limiting the number retries on 500s will undermine this.

  Stuart Clark and Chris Marchbanks preferred a limit by age; Chris Marchbanks cited outages "much harder to recover from due to a thundering herd scenario once the service was restored".

## Comparables that chose otherwise

Within the systems above, three already chose otherwise on one point: the OTLP exporters beneath the OpenTelemetry SDKs retry a failed batch within a time limit before the processor drops it (L1 to L4; in Rust the limit stops further retries but does not cut off an export in flight); ddtrace's writer retries before it drops (L7); and sentry-python's transport worker restarts after it stops, for fork (L8). The pipeline agents retry by design (P1 to P3). The systems below were looked for because they chose otherwise outside that set: an in-process client that retries within a bound, a file appender that recovers after a failed write, and supervisors that restart a worker with a limit.

### O1. Apache Kafka Java producer

**Analogy.** An in-process client library whose background I/O thread sends batches from an in-memory buffer to remote brokers. It fails over a network, not at a local disk.

**What it does.** Kafka `4.4.0` (`1156b2752aaa`). `retries` defaults to `Integer.MAX_VALUE` and `delivery.timeout.ms` to 120 s, both since 2.1.0: a send is retried until it succeeds, fails with an error that is not transient, or the time runs out. Backoff grows from 100 ms to 1 s with jitter.

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerConfig.java

>                                 .define(RETRIES_CONFIG, Type.INT, Integer.MAX_VALUE, between(0, Integer.MAX_VALUE), Importance.HIGH, RETRIES_DOC)

>                                 .define(DELIVERY_TIMEOUT_MS_CONFIG, Type.INT, 120 * 1000, atLeast(0), Importance.MEDIUM, DELIVERY_TIMEOUT_MS_DOC)

> Setting a value of zero will disable this automatic retry behaviour, so that the transient errors will be propagated to the application to be handled.

The I/O thread catches `Exception` on each pass and keeps running; an `Error` ends it, and nothing restarts it (no rationale searched).

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/internals/Sender.java

>         while (running) {
>             try {
>                 runOnce();
>             } catch (Exception e) {
>                 log.error("Uncaught error in kafka producer I/O thread: ", e);
>             }
>         }

**Stated why.** KIP-91 (adopted in 2.1.0) is about bounding time, not about retrying as such: it gives the user one upper bound on when a send succeeds or fails. The one sentence on why retries are otherwise unbounded:

Source: https://cwiki.apache.org/confluence/display/KAFKA/KIP-91+Provide+Intuitive+User+Timeouts+in+The+Producer

> This config enables applications to delegate error handling to Kafka to the maximum possible extent

**Constraints.** A client whose job is delivery to a broker, which acknowledges; transient broker and network errors; idempotence (on by default since KIP-679) requires retries to be on. Inferred: what Kafka carries is usually the application's own data, not telemetry about it.

**Costs and dissent.** Records held for retry fill `buffer.memory`, and then `send()` blocks up to `max.block.ms`; without idempotence, retries can duplicate; the KIP warns that the new default can reorder records ("reordering becomes a possibility by default"). The dissent recorded before the KIP was against dropping records too early, not against retrying too long (KAFKA-5886). KIP-98 and the KIP-91 mailing-list threads were not read.

### O2. Logback's resilient file output

**Analogy.** Close in what fails: an in-process logging library writing to a file, local or network-mounted, that recovers after a failed write.

**What it does.** Logback `v_1.6.8` (`2f625e4c587b`). `FileAppender` wraps its file in a `ResilientFileOutputStream`. On an `IOException` it records the failure and starts a recovery coordinator; while the stream is presumed in error, each write is discarded and may trigger a reopen of the file, on a backoff from 20 ms, ×4, up to about 5.5 minutes, with no limit on attempts. `flush()` skips that check and flushes the existing stream; if that succeeds, the error state ends with no reopen and later writes go to the old stream (Inferred, not run). It recovers the file, not the data: every write made while the stream is presumed in error is discarded, including the one that reopens the file, and nothing is replayed. Of the write that failed, the source shows only that it is not retried; the stream is buffered and recovery closes it first, so some of its bytes may still reach the file (Inferred, not run).

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/recovery/ResilientOutputStreamBase.java

>     public void write(byte b[], int off, int len) {
>         if (isPresumedInError()) {
>             if (!recoveryCoordinator.isTooSoon()) {
>                 attemptRecovery();
>             }
>             return; // return regardless of the success of the recovery attempt
>         }

>     void attemptRecovery() {
>         try {
>             close();
>         } catch (IOException e) {

>     public void flush() {
>         if (os != null) {
>             try {
>                 os.flush();
>                 postSuccessfulWrite();

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/recovery/ResilientFileOutputStream.java

>         this.os = new BufferedOutputStream(fos, (int) bufferSize);

The same library's plain `OutputStreamAppender` stops itself on an `IOException`.

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/OutputStreamAppender.java

>             // as soon as an exception occurs, move to non-started state

**Stated why.** Ceki Gülcü, Logback's founder, in LOGBACK-171 and the 0.9.19 release news (2010): a file on a networked file system whose connection was lost. His test for it also fills a local file system.

Source: https://jira.qos.ch/browse/LOGBACK-171

> FileAppender writing to a shared (networked) file system with lost networked connection.

Source: https://logback.qos.ch/news-archive.html

> gracefully deal with IO failures and recover quickly after the

No stated rationale found for the backoff constants.

**Constraints.** In-process; writes on the caller's thread unless wrapped in an `AsyncAppender`. The failure it was written for is a sink that goes away and comes back.

**Costs and dissent.** The report behind it was silence: "LogBack does not write in log files any more but I don't have any error in my application server STDOUT".

Source: https://jira.qos.ch/rest/api/2/issue/LOGBACK-171/comment/11319

### O3. Log4j 2's file appenders and `FailoverAppender`

**Analogy.** An in-process logging library; looked at as a candidate for a file appender that recovers. It does not, as far as was read.

**What it does.** Log4j `rel/2.26.1` (`dd0f9d255e24`). A failed file write throws; with `ignoreExceptions` at its default, true, the event is reported to the status logger and dropped. No path was found that reopens the file after a failure; a rolling appender opens a new file at its next rollover (Inferred). The documentation points to `FailoverAppender` "If logging is important for your business": if the primary appender is set not to ignore exceptions, which the manual requires, it sends a failed event to a secondary appender rather than retrying it, and tries the primary again for later events after 60 s; with the default, the primary swallows the error and nothing fails over (Inferred from the manual).

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/pages/manual/appenders.adoc

> If logging is important for your business, consider using a
> xref:manual/appenders/delegating.adoc#FailoverAppender[`Failover` Appender]
> to redirect log events to a different appender in case of exceptions.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/pages/manual/appenders/delegating.adoc

> <1> The primary appender must set `ignoreExceptions` to `false`.

**Stated why.** No design rationale found for the 60 s, or for rerouting the failed event rather than retrying it. Searched: Apache JIRA `project=LOG4J2 AND text ~ "FailoverAppender"` (22 results; LOG4J2-469, -878 and -3489 read in full).

**Constraints.** In-process; a failed write throws to the appender framework, which by default reports it on the status logger and carries on; logging that must not be lost is pointed at a second appender, not at a retry.

**Costs and dissent.** Two open reports say the primary file appender never comes back after failover (LOG4J2-878, LOG4J2-3489).

Source: https://issues.apache.org/jira/browse/LOG4J2-3489

> The FailoverAppender is not able to switch back to Primary.

### O4. Erlang/OTP supervisors

**Analogy.** Loose: a language runtime, not a library inside someone else's process. It is the standard example of restarting a worker with a limit.

**What it does.** OTP `OTP-29.1.3` (`7b8fb15471db`). A supervisor restarts a child that dies, at once, if its restart type allows: a `permanent` child (the default) always, a `transient` child only after an abnormal exit, a `temporary` child never. If more than `intensity` restarts happen within `period` seconds (1 in 5 s by default), it stops its children and itself, and its own supervisor decides; escalation can end the runtime.

Source: https://github.com/erlang/otp/blob/OTP-29.1.3/system/doc/design_principles/sup_princ.md

> If more than `MaxR` number of restarts occur in the last `MaxT` seconds, the
> supervisor terminates all the child processes and then itself. The termination
> reason for the supervisor itself in that case will be `shutdown`.

> The keys `intensity` and `period` are optional in the supervisor flags map. If
> they are not given, they default to `1` and `5`, respectively.

>   - A `permanent` child process is always restarted.
>   - A `temporary` child process is never restarted (not even when the supervisor
>     restart strategy is `rest_for_one` or `one_for_all` and a sibling death
>     causes the temporary process to be terminated).
>   - A `transient` child process is restarted only if it terminates abnormally,
>     that is, with an exit reason other than `normal`, `shutdown`, or
>     `{shutdown,Term}`.

OTP has no delay between restarts. RabbitMQ forked the supervisor to restart after a delay instead of giving up, resetting its count of restarts when it does (`supervisor2`, `v4.4.1`, `aa914c53d2f4`); its header comment says what the delay does, not why, and no issue or pull request was searched.

Source: https://github.com/rabbitmq/rabbitmq-server/blob/v4.4.1/deps/rabbit_common/src/supervisor2.erl

> %%    MaxR parameters, and a Delay is specified, then rather than
> %%    stopping the supervisor, the supervisor instead continues and
> %%    tries to start up the child again, Delay seconds later.

> %%    Note that if a child is delay-restarted this will reset the
> %%    count of restarts towrds MaxR and MaxT. This matters if MaxT >
> %%    Delay, since otherwise we would fail to restart after the delay.

The delay comes only once the restart limit is exceeded, so it replaces giving up rather than spacing the restarts, and a `permanent` child is restarted without end. Tim Watson, on the erlang-questions list in 2013, writing as one of RabbitMQ's developers (role not verified), gave its use; what first motivated it was not searched for, and the archive page has no version.

Source: https://erlang.org/pipermail/erlang-questions/2013-June/074128.html

> With Type set to permanent for example, that basically means the supervisor will keep trying to restart forever. We use this in some plugins to provide a reconnect/retry delay option.

**Stated why.** The OTP team, in the design principles:

Source: https://github.com/erlang/otp/blob/OTP-29.1.3/system/doc/design_principles/sup_princ.md

> The intention of the restart mechanism is to prevent a situation where a process
> repeatedly dies for the same reason, only to be restarted again.

Source: https://github.com/erlang/otp/pull/1289

The guidance on choosing values was written in 2016 by Richard Carlsson, a contributor, not the OTP team (PR #1289), who said the documentation had "nothing much helpful to say about this important choice". No stated rationale from the original authors for 1 in 5 s was found.

Source: https://github.com/erlang/otp/blob/OTP-29.1.3/system/doc/design_principles/sup_princ.md

> The default values were chosen to be safe for most systems, even with
> deep supervision hierarchies, but you will probably want to tune the
> settings for your particular use case.

**Constraints.** Workers are lightweight processes in one runtime; a supervisor that gives up hands the failure to the one above it, up to the application and the node. There is always a level above.

**Costs and dissent.** A backoff between restarts was proposed and not merged (PR #1287, 2016 to 2020), though Sirihansen recalled in 2017 an OTP Technical Board decision of 2012 on the feature, "allow it, but don't make it default" (the 2012 decision itself was not looked for). Its author, richcarl (Inferred: the Richard Carlsson of PR #1289), had seen supervisors use up their restart limit almost at once while a resource was still held:

Source: https://github.com/erlang/otp/pull/1287

> We have encountered situations in production where a supervisor would use up all restart attempts within less than a millisecond, not giving transient errors any time to be cleared, which can bring down a whole system due to something as simple as a TCP port being held briefly by the OS before being reusable again, or even due to Erlang's own process registry not freeing a name quickly enough because of multicore cpu scheduling.

Ferd argued that a worker should not need a transient resource to start, and should handle it itself:

> Supervised processes provide guarantees in their initialization phase, not a best effort.

Sirihansen, writing for the OTP team (role not verified), summed up its doubt, and garazdawi, a member of the organisation, closed the PR:

> In summary, we are a bit reluctant to include this solution since it does not eliminate the possibility of the problem to occur, it only reduces the probability of it happening.

> I'm closing this for now as we don't think this is important enough to spend time on at the moment and there are too many unknowns to make a quick decision.

The design guidance names the cost of a high limit: a child "filling your logs with crash reports until someone intervenes manually".

Source: https://github.com/erlang/otp/blob/OTP-29.1.3/system/doc/design_principles/sup_princ.md

> intensity to 10 and set the period as low as 1, the supervisor will allow child
> processes to keep restarting up to 10 times per second, forever, filling your
> logs with crash reports until someone intervenes manually.

### O5. Akka and Apache Pekko

**Analogy.** An in-process actor library on the JVM; supervision is from parent to child inside one actor system.

**What it does.** Pekko `v2.0.0` (`9fbd2283b1cf`), whose documentation came from Akka. By default a classic actor is restarted on an `Exception`, with no limit, except that `ActorInitializationException`, `ActorKilledException` and `DeathPactException` stop it, and a `Throwable` that is not an `Exception` is escalated to the parent; a typed actor is stopped unless a strategy is set. Backoff supervisors and restartable streams wait longer between restarts; their limits are opt-in and unlimited by default.

Source: https://github.com/apache/pekko/blob/v2.0.0/docs/src/main/paradox/typed/fault-tolerance.md

> An important difference between @ref:[Typed actors](actors.md) and @ref:[Classic actors](../actors.md) is that 
> by default: the former are stopped if an exception is thrown and no supervision strategy is defined while in Classic they are restarted.

Source: https://github.com/apache/pekko/blob/v2.0.0/actor-typed/src/main/scala/org/apache/pekko/actor/typed/SupervisorStrategy.scala

>    * If the actor behavior is deferred and throws an exception on startup the actor is stopped
>    * (restarting would be dangerous as it could lead to an infinite restart-loop)

**Stated why.** For backoff, the documentation: restarting at once may "only trigger the same failure right away".

Source: https://github.com/apache/pekko/blob/v2.0.0/docs/src/main/paradox/fault-tolerance.md

> The supervision strategy to restart a classic actor only provides immediate restart. In some cases that will only trigger
> the same failure right away and giving things a bit of time before restarting is required to actually resolve the failure.

For the typed default of stopping, Roland Kuhn, its designer (his role in 2018 not verified):

Source: https://github.com/akka/akka-core/issues/25571#issuecomment-419028028

> Technically, failure–stop is preferable because it is strictly less complex to implement and uses less resources: holding on to the initial behavior by default certainly is not always warranted. Hence any strategy that goes beyond this very simple default is offered on an opt-in basis.

**Constraints.** Supervision is inside one actor system; the typed documentation frames a restart as starting a new actor "with a fresh state that we know is valid".

**Costs and dissent.** Akka reversed its own default between classic and typed. The typed code names the infinite restart loop as the danger of restarting a behaviour that fails as it starts.

### O6. OpenTelemetry .NET OTLP exporter

**Analogy.** Close: an in-process telemetry library, and the same specification as L1, with retry that the user turns on.

**What it does.** `opentelemetry-dotnet` `core-1.21.0` (`51c6db11dadd`). Retry is opt-in and experimental (`OTEL_DOTNET_EXPERIMENTAL_OTLP_RETRY`), either in memory or through a buffer on disk resent every 60 s. In memory, it retries until the export's deadline, with no cap on attempts; without a deadline it does not retry. On disk, a failed `TryCreateBlob` returns failure with no retry of the write; the resend thread catches an unexpected failure for one blob, logs it, and leaves the blob for a later pass.

Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/Implementation/ExportClient/OtlpRetry.cs

> /// Furthermore, since the OTLP spec does not specify a max number of attempts,
> /// this implementation will retry until the deadline is reached.

Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/Implementation/Transmission/OtlpExporterPersistentStorageTransmissionHandler.cs

>         return this.persistentBlobProvider.TryCreateBlob(request.AsSpan(0, contentLength), out _);

>                         // An unexpected failure transmitting one blob must not terminate this
>                         // thread. Leave the blob on disk; its lease will expire and it will be
>                         // retried on a later pass.

**Stated why.** Vishwesh Bankwar, an approver at the time:

Source: https://github.com/open-telemetry/opentelemetry-dotnet/issues/4791

> Transient server errors results in complete data loss.

**Constraints.** Network export; the specification's MUST to retry transient errors (L1).

**Costs and dissent.** The maintainers' own comment names the cost of no cap:

Source: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.21.0/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/Implementation/ExportClient/OtlpRetry.cs

>         //    1) When using a batch processor, a longer delay due to repeated
>         //       retries up to the deadline may lead to a higher chance that the queue will be exhausted.

## Candidates not examined

Five comparables have a failure at a local write examined: tracing-appender (L5), CPython's file handlers (L6), Logback (O2), Log4j's file appenders (O3), and the OpenTelemetry Collector's persistent queue (P2), which drops what it cannot enqueue when its storage fails. Prometheus's write-ahead log (P3) and Fluent Bit's filesystem buffer (P1) are on a local disk too; how they handle a failed local write was not examined. OpenTelemetry .NET's disk buffer (O6) is on a local disk too; only that a failed `TryCreateBlob` is not retried, and that its resend thread guards each blob, was read. The others fail at a network export or send. None of the comparables examined stores batches of rows to a local database, as this client does. aiosqlite (`v0.22.1`, `9b127cecc7de`) runs each SQLite connection on one worker thread fed by a queue, but each call, an `executemany` batch the caller built included, is awaited by its caller, who gets the error back: the worker catches `BaseException` around each call, hands it to the caller and takes the next. It does not batch or drop on its own, and was not examined further.

Source: https://github.com/omnilib/aiosqlite/blob/v0.22.1/aiosqlite/core.py

>         except BaseException as e:  # noqa B036
>             LOG.debug("returning exception %s", e)
>             if future:
>                 future.get_loop().call_soon_threadsafe(set_exception, future, e)

One more thing was read beneath it. Its `connect` passes its options to Python's `sqlite3.connect`, whose `timeout`, five seconds by default, it passes to SQLite as a busy timeout: while another connection holds a lock, SQLite sleeps until at least that much sleeping has accumulated, then fails, so the timeout counts time asleep, not time elapsed. SQLite does not wait where waiting could deadlock, nor on a conflict it reports as `SQLITE_LOCKED`, within one connection or a shared cache (`sqlite/sqlite` at `version-3.54.1`, `57520227c953`; the result codes page, unversioned). That is a bounded wait inside one storage operation, for a lock to pass, and not a retry of a failed batch; the text describes the mechanism and gives no reason for it. This client's on-disk format is undecided, and nothing here says it is SQLite.

Source: https://github.com/omnilib/aiosqlite/blob/v0.22.1/aiosqlite/core.py

>         return sqlite3.connect(loc, **kwargs)

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/sqlite3.rst

>    :param float timeout:
>        How many seconds the connection should wait before raising
>        an :exc:`OperationalError` when a table is locked.
>        If another connection opens a transaction to modify a table,
>        that table will be locked until the transaction is committed.

Source: https://github.com/sqlite/sqlite/blob/version-3.54.1/src/sqlite.h.in

> ** The presence of a busy handler does not guarantee that it will be invoked
> ** when there is lock contention. ^If SQLite determines that invoking the busy
> ** handler could result in a deadlock, it will go ahead and return [SQLITE_BUSY]

> ** for a specified amount of time when a table is locked.  ^The handler
> ** will sleep multiple times until at least "ms" milliseconds of sleeping
> ** have accumulated.  ^After at least "ms" milliseconds of sleeping,
> ** the handler returns 0 which causes [sqlite3_step()] to return
> ** [SQLITE_BUSY].

Source: https://github.com/python/cpython/blob/v3.15.2/Modules/_sqlite/connection.c

>         (void)sqlite3_busy_timeout(db, (int)(timeout*1000));

Source: https://sqlite.org/rescode.html

>   The SQLITE_LOCKED result code differs from SQLITE_BUSY in that
>   SQLITE_LOCKED indicates a conflict on the same database connection
>   (or on a connection with a shared cache) whereas SQLITE_BUSY indicates
>   a conflict with a different database connection, probably in a different
>   process.

SQLite's documentation also says that a `COMMIT` that returns `SQLITE_BUSY` because another connection has an open read leaves the transaction active, so that the caller can retry the commit once the reader clears (`sqlite.org/docsrc` at `version-3.54.1`, `afd7af2397`, read raw). That is a retry of one commit in place, with its cause named, and not a retry of a failed batch.

Source: https://sqlite.org/docsrc/raw/pages/lang_transaction.in?ci=version-3.54.1

> if another thread or process has an open read connection.
> ^When COMMIT fails in this
> way, the transaction remains active and the COMMIT can be retried later
> after the reader has had a chance to clear.

Elastic APM agents, the OpenTelemetry Go exporter, and the Datadog Go and Java tracers were not researched for lack of time. Vector was left out as an agent, not an in-process library.

## Fit

### The constraints of this client

From the specification and `CONTEXT.md`. A leaning is marked as one.

- **A guest in the host application.** The client never harms its host; a write never fails and never blocks; every queue is bounded (standing guidance; `AcceptRow` and its surface).
- **One data writer per production run**, a background worker that takes queued rows of its run as one batch, holds one batch at a time, and stores it (`TakeBatch`, `StoreBatch`).
- **The store is local.** A batch is stored to the client's local databases on a local disk, not sent over a network. The on-disk format is undecided; DuckDB was named once, as a leaning, with its one-writer rule (unchecked; ticket 17).
- **What the store holds is kept until collected.** A collector later takes the stored rows; rows are kept until a confirmation purges them, and how the local databases are bounded is open question 8. Inferred, the researcher's reading: the store is then the client's own durable buffer, as a pipeline agent's disk buffer is, and not the final destination.
- **Every loss is counted once while the process lives** (`EveryLossIsCountedOnce`; `lost.store_failed`, `rejected.queue_full`), and the data writer reports itself as failing until a store succeeds. A kill, a restart or power loss before a row is stored loses it, and nothing counts it (`KilledProcessLosesUncounted`).
- **One behaviour for Rust and Python.**
- **The host.** The most common host is an ephemeral pod (a leaning). The elicitation's survey reported that a full disk there usually shows up as an eviction, not a failed write (not checked here; ticket 17).

Inferred, from the spec and not from any comparable: a local store can fail for reasons that pass, such as a lock held by another writer or a moment of full disk that something else frees, and for reasons that do not, such as a disk that stays full, an I/O error, a corrupt file, a row the store cannot take, or a defect in the client. No source above measured which is more common for a local store.

### Fit of each comparable

**OpenTelemetry specification (L1).**

- *Holds:* the guest's principle, "users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application": this client is a guest with the same standing guidance. The guidance that a long-running background task "should not fail permanently in response to internal errors" is about a background worker, as this client's is; no rationale was found for it.
- *Does not hold:* the reason processors do not retry is that the right retry "is likely to depend heavily on the specific protocol and backend". This client has one store, its own, and no protocol or backend to vary. And the same specification puts a bounded retry in the exporter, as a MUST for transient network errors, for reliable delivery. So the specification does not say a failed batch is dropped at once; it says the processor drops what the exporter, having retried, could not deliver.

**OpenTelemetry Python, Java and Rust (L2 to L4).**

- *Holds:* an in-process worker thread, a bounded queue, the guest's principle; in Rust, a dedicated thread, as this client's would be.
- *Does not hold:* the failure is a network export, and each SDK's exporter retries it first. The stated reasons for that retry (the specification's MUST; Jack Berg's production experience) are about transient network failure, which a local store shares only in part (Inferred).
- *The worker:* each has a guard around one batch and keeps looping after a failure; Java's first processor's comment says what its catch is for ("In case of any exception thrown by the service handlers continue to run"), not why. Each killed worker that was reported (Java #4348 and #8528, Rust #3432) was answered by a wider guard or a fix, not by a restart. None gives a reason for leaving a dead worker dead; OTel Python's one discussion (2019) left a suggested liveness check and restart open: the PR's author objected to its cost on every span and doubted the thread could crash, a cheaper place for the check was offered, and the thread ends there (L2).

**tracing-appender (L5).**

- *Holds:* closest in what fails (a local write) and in language (a Rust background thread).
- *Does not hold as a reason:* its handling of a failed write has no stated why; the code carries a TODO saying the error was meant to be reported. Its loop keeps going after a failed write or flush, with no bound in the code on what is lost; and a writer that keeps failing loses every line silently. So it informs, as an example of carry-on at a local write, and justifies nothing.

**CPython `logging` (L6).**

- *Holds:* the guest's reasons, in the maintainer's words: "logging-related errors should not be treated in the same way as application errors" and "logging is not a primary program function". A local write, in the file handlers.
- *Partly holds:* against a retry, "if you keep getting EAGAIN, the handler will appear to hang", and "what number of retries would you pick, and why?" The hang is that of the thread the handler runs on, under the handler lock: the application's, or a `QueueListener`'s where the cookbook's advice for handlers that block is followed (L6). This client's data writer is in the second position, and a write never waits for it, so a retry there would not hang a write; it would hold the batch in hand and let queues fill (Inferred from `TakeBatch`), and a retry under way when establish ends would lengthen its wait for the batch in hand (`NothingWaitsAtTheEnd`, Derived). The question of which number and why is not about threads; it asks a bounded retry to justify its bound. The issue was closed not on that question but because its use case, a console stream under custom `SIGPIPE` handling, was not common enough for the base handler, after the reporter had capped their own retry (L6).
- *Does not hold:* `QueueListener`'s loop has no guard and no stated why for that.

**ddtrace (L7).** It retries a failed batch before dropping it, and the stated reasons are a product need (the PHP sidecar) and "to mitigate networking issues". Neither is about a local store. Its periodic thread stops on an escaping exception, with no stated why. It informs on cost: retry delays later batches and costs memory.

**sentry-python (L8).**

- *Holds, and is one of the two clearest stated whys for carrying on (the other is O6's):* the 2026 fix for a dead batcher thread gives its reason in the code (quoted in L8): one failed batch must not kill the thread, or the buffer fills with nothing draining it and every later item is dropped for the life of the process. Its cost is this client's: a dead data writer leaves queues filling and every later row rejected. In-process, a background thread, a bounded buffer. It does not depend on the network.
- *Does not hold:* "If a request fails once, it is very likely to fail again on the next attempt. Retrying too often may cause further rate limiting or blocking by the Sentry server." It is about a remote server and rate limits. Whether a local store that failed once is likely to fail again is not shown by any source here (Inferred, both ways: a full disk probably stays full; a held lock passes).
- *Holds, in part:* the same specification's offline-caching rule discards an envelope whose failure is the SDK's own, "Otherwise, the SDK might end up in an endless retry loop". That is about a local, internal failure, as a failed store can be, and it argues against retrying without limit, not against a bounded retry. sentry-python does not implement offline caching.
- *The restart:* written for fork, so it does not bear on a crashed data writer except as a side effect. Fork is outside this ticket (ticket 08).

**Fluent Bit, the OpenTelemetry Collector and Prometheus (P1 to P3).**

- *Does not hold:* each is a process of its own whose job is delivery to a remote destination. Its retry exists because the destination may be down; its limit (Fluent Bit's 1, no stated why; the Collector's 5 minutes, no stated why; Prometheus's none, "to not drop samples") bounds, where there is one, the retries of a send to that destination, and Fluent Bit's counts retries, not time (P1). None is stated as a bound on how long data is held: what each holds is bounded separately (Fluent Bit's `storage.total_limit_size`, the Collector's queue, Prometheus's write-ahead log truncation), and no source read ties the one to the other. This client's store is not a remote destination: it is the step that corresponds to an agent writing to its own buffer.
- *Holds, at that step:* where an agent's own local buffer fails, the Collector's persistent queue does not retry a write its storage refuses, "for example, due to insufficient disk space or I/O errors": it returns the error to its caller (Inferred from the code, P2), and its documentation says the data is then "typically dropped". No why was searched for that, and Fluent Bit's and Prometheus's handling of a failed write to their own buffer was not examined. Inferred, from the Collector alone: it retries the network step and does not retry its local one. One agent's enqueue path does not show what agents in general do.
- *Dissent that bears on it:* the case against bounding retries in Prometheus is that it would undermine "the lossless nature of the remote write" (Tom Wilkie); the case for it is the bandwidth, memory and CPU spent resending what will be rejected (PR #8549's design document). Both are about a remote receiver.
- *Costs that may carry over in shape:* holding a failing batch fills the queue behind it (the Collector's two drop points; Prometheus's blocked shard), and order is a reason to retry in place rather than requeue (the Collector).

**Kafka producer (O1).** An in-process client that retries within a time bound, so that the application has one bound on success or failure. The failure is a broker over a network, and what it carries is usually the application's own data (Inferred), with a delivery promise this client does not give for a single batch. It informs that a bounded retry inside a library is ordinary, and on its costs (buffer memory, blocking the sender, reordering).

**Logback (O2).** Closest in what fails among the choices otherwise: a file that went away, on a network file system, and came back. It recovers the file and drops the data, so it chose otherwise on restart of the sink, not on retry of the batch. Its stated why (a file system that returns) fits a local disk only where the cause passes.

**Log4j 2 (O3).** Drops by default and points to a second appender; it informs, with no stated why.

**aiosqlite (named under "Candidates not examined").** A worker thread on a local database that catches `BaseException` around each call and takes the next; but each caller awaits its call and gets the error, which this client's writers never do. It informs, with no stated why for the guard.

**Erlang/OTP and Akka (O4, O5).**

- *Does not hold:* both are runtimes or toolkits where a worker is cheap, restarting it gives "a fresh state that we know is valid", and a supervisor that gives up hands the failure to a level above. In the current proposal nothing above this client's data writer restarts it: the establish block owns it and the local databases (`OneDataWriter`), and whether a dead one is restarted is open question 14. Its batch in hand is lost when it dies. Inferred: the "fresh state" in Pekko's reason is the actor's own state; a new data writer would be fresh in memory but would start against the same local databases, whose state after the failure no source here examined.
- *Dissent that bears on it:* OTP has not adopted a delay between restarts (PR #1287, closed; a 2012 board decision recalled as "allow it, but don't make it default"), proposed after supervisors used up their limit in under a millisecond while a port was still held. Sirihansen's interim summary of the team's concerns was that a delay "only reduces the probability" of that; Ferd argued that a worker should handle a transient resource itself, and richcarl answered that such resources "are managed outside the scope of the code; by the VM, or the OS"; the PR was closed as not important enough to spend time on, with "too many unknowns to make a quick decision". RabbitMQ's fork of the supervisor ships a different delay (O4): it restarts at once, as OTP does, until the limit is exceeded, and then, instead of giving up, starts the child again after a delay and resets its count of restarts; Tim Watson said some of its plugins use it "to provide a reconnect/retry delay option".
- *Holds:* the stated why for a limit, "to prevent a situation where a process repeatedly dies for the same reason, only to be restarted again", is about any restart. Akka's reason for stopping by default, that failure-stop "is strictly less complex to implement and uses less resources", is about defaults, not about runtimes.

**OpenTelemetry .NET (O6).**

- *Does not hold:* its in-memory retry, opt-in, to a deadline, is for "Transient server errors" (network).
- *Holds:* its disk buffer is the nearest thing found to this client's store: an in-process library writing batches to a local disk. A failed local write there is not retried (no stated why was searched). Its resend thread guards each blob, with a stated why, in its code (quoted in O6), that is about a background thread: an unexpected failure transmitting one stored blob must not end the thread. What it guards is the reading and resending of a blob already stored, not the failed local write, and the blob is kept for a later pass, not dropped. Its own TODO names a cost of retrying that would carry over: a longer delay "may lead to a higher chance that the queue will be exhausted".

## Verdict on drop-and-carry-on

The behaviour: a failed store drops its batch, counts its rows as lost, and the data writer carries on (`FailBatch`, `FailAnotherBatch`), with no retry until open question 12 is decided.

Two halves are in it: the data writer carries on after one failed batch, which `FailureCostsOneBatch` settles; and the batch is dropped, not retried or held, which until open question 12 is decided happens at once. The elicitation's survey, "in-process libraries drop and carry on", was offered for both. The verdict is on the behaviour as a whole, both halves together: it rests on a stated why that fits only if stated whys that fit cover each half.

**Verdict: it rests on a stated why that does not transfer.**

- **The comparables split by where the failure happens.** Of the five libraries the elicitation read that export over a network, four retry an error they class as retryable within a bound, by default, before they drop: the OpenTelemetry exporters, by time (not on Java's sender built on grpc-java's `ManagedChannel`; in Rust, and in Python over HTTP, a budget that an attempt in flight can outlast, L2 and L4), and ddtrace, by count; the OpenTelemetry exporters drop at once an error they do not class as retryable. sentry-python never re-sends a failed envelope, though its HTTP layer retries a failed connection up to three times within one request (L8; Inferred for the default transport). Of those that fail at a write to a local file or disk, none retries the failed write: CPython's file handlers, tracing-appender, Logback, Log4j 2, OpenTelemetry .NET's disk buffer (read only in part, O6) and the Collector's persistent queue. CPython's `SysLogHandler`, sending to a local daemon over a Unix socket, reconnects and resends a failed record once, with no stated why found (L6); the file counts it as a send, not a write to storage. What becomes of it varies: most drop it; Logback's plain stream appender stops itself (O2); its file appender discards writes while it reopens the file, and some bytes of the write that failed may still reach the file (Inferred, O2); in a CPython probe a buffered stream kept a failed record's bytes and wrote them on a later flush (L6); Log4j 2 can be configured to send it to a second appender (O3); the Collector's persistent queue returns the error to its caller (Inferred from the code, P2), and its documentation says the data is then "typically dropped" (P2). Kafka's producer (O1) and OpenTelemetry .NET (O6), which chose otherwise, retry too. So the elicitation's "in-process libraries drop and carry on" holds for local writes, with those qualifications, and not for network exports.
- **The stated whys for dropping at once.** For network exports, one, from the one library there that never re-sends a failed batch: a failed request is likely to fail again and retrying invites rate limiting (Sentry's transport specification, which sentry-python follows). It is about a remote server and does not transfer to a local store. OpenTelemetry's reason, that protocols and backends vary (PR #511), is not one: it puts the retry in the exporter, which retries before the processor drops (L1), so it says where a retry belongs, not that a failed batch is dropped at once. For local writes, most give none: tracing-appender, Log4j 2, the .NET disk buffer and the Collector's persistent queue have no stated why found or searched. Two bear on it, the second only by analogy:
  - CPython's maintainer, against a loop that retried a write to the console for as long as it failed (L6): the handler "will appear to hang", and "what number of retries would you pick, and why?" The hang falls on the thread the handler runs on: the application's, or a `QueueListener`'s, which the cookbook recommends for handlers that block (L6). This client's data writer is in the second position, and a write never waits for it, so the reason transfers only as a stalled data writer whose queues fill, and a longer wait at the end of establish (below), not as a stalled write (Inferred). The question of which number and why is not a reason for dropping; it asks a bounded retry to justify its bound. The maintainer did not reject a capped retry, which the reporter had already written: the issue was closed because the use case "isn't common enough to be addressed in the base handler" (L6). Inferred: that last reason is about how common one case is among the base handler's users, and does not transfer.
  - Sentry's offline-caching rule: a failure "caused by processing the file in the SDK itself", for an envelope already cached on disk and waiting to be sent, is discarded, "Otherwise, the SDK might end up in an endless retry loop." Inferred: it transfers in part, to a failure that is the client's own, though it is about processing a file already stored and not about a failed write; and it is a reason against retrying without limit, not against a bounded retry.
- **The guest's reasons** (OpenTelemetry's "users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application"; CPython's "logging is not a primary program function") transfer, and make loss an accepted price. Inferred, the researcher's argument: they do not choose between dropping at once and a bounded retry on a background thread that no write waits for. Neither makes a write wait. A retry under way when establish ends would lengthen a wait the host has, since the end of establish waits for the batch in hand (`NothingWaitsAtTheEnd`, Derived; its bound is open question 26). Dropping at once loses the batch for certain; a bounded retry that succeeds loses none of it, and one that fails loses it. Either way, while the retry lasts the data writer takes no other batch, so rows are refused on any queue that fills meanwhile (`TakeBatch`).

So the behaviour as a whole rests on a stated why that does not transfer. It does not rest on no stated why: two comparables that drop a failed item at once state why they do not retry it, sentry-python's transport (Sentry's specification, about a remote server) and CPython's stream handler (about a loop with no limit, in a case its maintainer judged too uncommon for the base handler), though most of those that fail at a local write state none. Carrying on has two stated whys that fit this client: sentry-python's for its batcher (#7186) and OpenTelemetry .NET's for its disk resend thread, both about a background worker that must outlive one item's failure. They do not choose what becomes of the failed item: sentry-python's batcher swallows the batch, and .NET's thread guards the resend of a blob already stored, not a failed local write, and leaves that blob on disk for a later pass. Dropping the batch, not retrying or holding it, has stated whys that are about the network, about a handler that hangs the thread it runs on while a retry keeps failing (which transfers only as a stalled data writer and a longer wait at the end of establish), or against retrying without limit; the guest's reasons, which transfer, accept loss but do not choose between dropping at once and a bounded retry; and the comparables closest in what fails, at a local write, mostly give no stated why (tracing-appender, Log4j 2) or were not searched for one (the .NET disk buffer, the Collector's persistent queue). No stated why that transfers chooses either dropping at once or a bounded retry first; that choice is open question 12.

### Proposed wording for the maintainer

The specification cites no comparable for `FailBatch`; `CONTEXT.md` records the survey that informed it. The wording below changes only what the text says the behaviour rests on. It does not change the behaviour, and it leaves open question 12 as it is. It is for the maintainer and is not applied, and none of it was run through the pinned checker.

For the comment above `FailBatch`:

```text
-- A failed store costs only its batch: the rows are dropped and counted,
-- and the data writer carries on. Comparable libraries inform this. Those
-- read that run a background worker keep it running after a failed
-- batch, so that one failure does not stop later data. Those read that
-- fail at a write to a local file or disk do not retry it; most drop it,
-- and one, Logback's plain stream appender, stops itself. Most of those that
-- export over a network retry a transient failure within a bound first.
-- The reasons they state for dropping at once are about the network,
-- about a handler hanging its thread, or against retrying without limit.
-- Whether a bounded retry should come first is open question 12.
```

For the comment above `DataWriterDiesUnexpectedly`, which no comparable's stated why supports either way, three sentences added after the existing comment, which keeps its "Derived" marker:

```text
-- Comparable libraries inform this: of seven read, none restarts on its
-- own a worker that died in the same process, except sentry-python's
-- transport worker, which starts a new thread on the next submit when
-- its thread is not alive in this process, however it ended, by a check
-- written for fork. In the issues, pull requests and code searched, none
-- states why it leaves a dead worker dead; one, OpenTelemetry Python,
-- left a suggested restart open. Neither answer to open question 14
-- rests on these libraries.
```

For the guidance on panics:

```text
@guidance
    -- In Rust the handling of one batch must contain panics as well as
    -- errors, or one bad batch stops the data writer for the run. Only an
    -- unwinding panic can be contained: under `panic = "abort"` a panic
    -- ends the host's process. No comparable read contains one; the Rust
    -- libraries read let a panic end the worker. OpenTelemetry Rust's
    -- stated reason, about user callbacks, is the cost of reasoning about
    -- `UnwindSafe` and of deciding what state to recover.
```

For the "Failed stores" survey in `CONTEXT.md`, if the maintainer chooses to correct it (no ticket edits that file):

```text
In-process libraries that run a background worker keep it running after a failed batch. Most of those that export over a network retry first, within a time limit (the OpenTelemetry exporters) or a count (ddtrace), and then drop; those that fail at a write to a local file or disk do not retry it, and most drop it (CPython's file handlers, tracing-appender, Logback's file appender, Log4j 2), though Logback's plain stream appender stops itself. Pipeline agents retry, then drop: Fluent Bit once by default; the OTel Collector while another attempt can start within 5 minutes of a batch's first, and refuses new data when its queue is full; Prometheus remote-write without limit, losing what its write-ahead log has truncated. See `research/13-store-failure-and-data-writer-death.md`.
```

## What the findings bear on in the specification

This section reports. It decides nothing, and it recommends no answer to question 12 or 14.

### Open question 12: a bounded retry before a failed batch is dropped

- **What comparables do.** A bounded retry before dropping is common among in-process telemetry libraries that export over a network: by time within one export (OpenTelemetry Python and Java, on by default, though not on Java's `ManagedChannel` sender; Rust, where the limit stops further retries but not an export in flight; .NET, opt-in and experimental), by count (ddtrace), by time per send (Kafka). Libraries writing to a local file or disk do not retry the failed write (CPython's file handlers, tracing-appender, Logback, Log4j 2, OpenTelemetry .NET's disk buffer); CPython's `SysLogHandler`, sending to a local daemon over a Unix socket, resends a failed record once, with no stated why found (L6), which the file counts as a send, not a retry of a write to storage; Logback recovers the file and discards writes meanwhile. The agents retry a remote send; the Collector's persistent queue does not retry a write its own storage refuses, and returns the error to its caller (Inferred from the code, P2), after which the data is "typically dropped". Nearest to a local store, and not a retry of a batch: Python's `sqlite3`, beneath aiosqlite, sets SQLite's busy timeout, five seconds by default: on a lock another connection holds, SQLite sleeps until at least that much sleeping has accumulated, then fails; it does not wait on a conflict it reports as `SQLITE_LOCKED`, within one connection or a shared cache, nor where waiting could deadlock (under "Candidates not examined"). None of these gives a stated why for not retrying a local write, except CPython's maintainer, whose reasons are quoted below.
- **The stated reasons for retrying** are about transient failure over a network or at a remote service. None found is about a local store. Nearest to one, and not a retry of a batch: SQLite's documentation says that when a `COMMIT` fails with `SQLITE_BUSY` because another connection is reading, "the transaction remains active and the COMMIT can be retried later", once the reader clears; it names a transient local cause and a way to retry one commit, not a reason to retry before dropping (under "Candidates not examined").
- **The stated reasons against** are: protocols and backends vary, so the retry belongs to the exporter (OpenTelemetry, which then retries); a failed request is likely to fail again, and retrying invites rate limiting (Sentry, about a remote server); a failure in the SDK's own processing must not be retried, or the SDK "might end up in an endless retry loop" (Sentry's offline caching, about retrying without limit); a retry that keeps failing makes the handler appear to hang, and what number of retries, and why (CPython, about a handler that hangs the thread it runs on, the application's or a `QueueListener`'s; said of a loop with no limit, and the issue was closed because its use case was not common enough for the base handler, after the reporter had capped their own retry).
- **Costs recorded with dropping:** data buffered through an outage lost with Fluent Bit's default of one retry (#5774); a user's account that a batch is "dropped on the floor" if the exporter fails, "even if the collector was unavailable for a moment" (OpenTelemetry Java #7099, describing the design, not an incident); "complete data loss" on transient server errors (OpenTelemetry .NET #4791); in PR #511, "we cannot afford to lose data on every random sending problem" (Tigran Najaryan). All are about a remote destination.
- **Costs recorded with retry:** a fuller queue behind a retrying batch (OpenTelemetry .NET's TODO; the Collector; Prometheus's blocked shard); a shutdown held up by retries in progress (OpenTelemetry Python, until its timeout covered retries); memory (ddtrace); retry storms against a failing server (Prometheus, a user report); duplicates and reordering (Kafka).
- **In this specification**, Inferred, the researcher's reading and not decided: the data writer holds one batch at a time, so a batch under retry would hold back every queue of the run while it lasts: rows are refused as `rejected.queue_full` only on a queue that fills in that time, and a retry that succeeds counts nothing as `lost.store_failed`; `TakeBatch` makes no promise on how long a row waits. The end of establish waits for the batch in hand (`NothingWaitsAtTheEnd`, Derived), so a retry under way then would lengthen that wait, whose bound is open question 26. And a retry, whether it succeeds or fails, delays the point at which its batch's rows are stored, or lost and counted, and the stored position, so the hand-over, waits for that point (`stored_position`, Derived).
- **Unknown:** how often a local store fails for a reason that passes. No source here measured it.

### Open question 14: a dead data writer stays stopped or is restarted

- **What comparables do.** None of the seven libraries restarts on its own a worker that died in the same process, except sentry-python's transport worker, which starts a new thread on the next submit when its thread is not alive in this process, however it ended, by a check written for fork (CPython's `QueueListener` can be stopped and started again by its caller, but the stale stop marker then ends the new thread once it has handled the backlog, and on a full bounded queue `stop()` raises; L6). None restarts with a limit. Erlang/OTP and Akka restart with limits, in runtimes built for it; OTP has not adopted a delay between restarts (PR #1287), and RabbitMQ's fork of its supervisor, once the limit is exceeded, restarts after a delay instead of giving up and resets its count of restarts, so it does not give up on such a child (Inferred from its header comment); Tim Watson said some of its plugins use this "to provide a reconnect/retry delay option" (O4).
- **Stated reasons.** For leaving a dead worker dead: none found, in any of the seven. For keeping a worker alive past one failure, two about a background worker that must outlive one item's failure: sentry-python's (#7186) and OpenTelemetry .NET's disk resend thread, which keeps the failed blob for a later pass. OTel Python's one discussion (2019) left a suggested restart open, after the PR's author objected to the cost of a check on every span and doubted the thread could crash (L2). For a limited restart: OTP's, to stop a process that "repeatedly dies for the same reason" being restarted again; Akka's, for stopping by default, simplicity and resources.
- **A restart without limit, on the same queue or a fresh one:** sentry-python's threaded transport worker restarts on the next submit on the same queue, so the callbacks still waiting there are handled by the new thread (Inferred from the code), though the one running when the thread died is lost (L8). Its experimental async worker restarts on a fresh queue, losing what the old one held; its code gives the reason, "to avoid stale items", and its PR says only that it mirrors the threaded worker.
- **What maintainers did when a worker died in the field:** widened or added the guard around one batch, or fixed the bug (OTel Java #4348 and #8528; raven #254; sentry-python #7138; ddtrace #7411; tracing-appender #1987). One user asked for a restart in tracing-appender #3467; no maintainer replied, and the reporter later called it stale (open at the date read).
- **Costs recorded with a dead worker:** every later item dropped for the rest of the process, often silently, or with a misleading message (OTel Rust); flush and shutdown that never complete (OTel Java); a status that still says running (ddtrace).
- **Costs recorded with restarting:** a child restarting "forever, filling your logs with crash reports until someone intervenes manually" when the limit is high, and a limit used up "within less than a millisecond" by restarts with no delay between them, "not giving transient errors any time to be cleared" (OTP's guidance and PR #1287); "an infinite restart-loop" for a behaviour that fails as it starts (Akka typed); what was queued lost when sentry-python's async worker restarts on a fresh queue; a design whose thread stopped when idle and restarted on demand judged "too risky" (sentry-python PR #819, a deliberate stop, not a crash).
- **In this specification**, Inferred, the researcher's reading and not decided: `FailureCostsOneBatch` is settled, so what question 14 decides is what happens after a failure that escapes that guarantee. In the field reports read here (listed above), each such failure was treated as a defect: answered by adding or widening the guard, or by fixing the code that raised. Whether such failures have other causes was not examined.

### The guidance on panics

- No Rust library read contains a panic in its worker: neither OpenTelemetry Rust nor tracing-appender has `catch_unwind` outside tests. Panics on those workers have happened (OTel Rust #3432, tracing-appender #1987) and killed the worker each time.
- The one stated reason for not containing panics is OpenTelemetry Rust's, about user callbacks: the complexity of `UnwindSafe` and of deciding what state to recover, and that the specification does not require it.
- In Python the same gap is `BaseException`: the guards in OTel Python and ddtrace catch `Exception`, so `SystemExit` or `KeyboardInterrupt` raised in an export ends the worker, and in ddtrace's C++ thread a `SystemExit` that escapes can end the process (Inferred, L7).
- So the guidance rests on no comparable; the reason it gives, "or one bad batch stops the data writer for the run", matches sentry-python's stated why for its per-flush guard (L8). Under `panic = "abort"` nothing in the process can contain a panic, and the panic ends the host's process.

  Source: https://doc.rust-lang.org/1.100.0/std/panic/fn.catch_unwind.html

  > This function only catches unwinding panics, not those
  > that abort the process.
