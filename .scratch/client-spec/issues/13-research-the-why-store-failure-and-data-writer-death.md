# 13: Research the why: store failure and data writer death

**What to build:** The maintainer can see why comparable libraries and agents treat a failed batch and a dead background worker as they do, and whether those reasons hold for this client. During the elicitation these systems were surveyed for what they do. Why they do it was not captured, and no link was kept. This ticket checks the what again, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

What the specification proposes today, and what it was said to rest on:

- **A failed store drops its batch and the data writer carries on.** The rows are counted as lost, and the data writer reports itself as failing until a store succeeds. A failure handling one batch costs only that batch. The survey reported that in-process libraries drop and carry on.
- **No retry.** Until open question 12 is decided, a failed store drops its batch at once. The survey reported that pipeline agents retry within limits and then drop.
- **A dead data writer stays stopped.** A failure that escapes the handling of one batch stops the data writer. Until open question 14 is decided it stays stopped for the rest of the run, and the specification marks that "Derived". The survey reported that almost no library restarts a dead worker.
- **Containing panics.** The specification's guidance says that in Rust the handling of one batch must contain panics as well as errors. The survey reported that the Rust libraries it read do not.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- OTel SDK batch processors drop a failed export and carry on.
- Python logging handlers do the same. This one came from the agent's own knowledge and was never checked.
- Fluent Bit retries once by default, then drops.
- The OTel Collector retries while its queue fills, then drops.
- Prometheus remote-write retries for up to two hours.
- Seven libraries' worker loops were read from source: OTel Python, OTel Java, OTel Rust, tracing-appender, CPython's QueueListener, ddtrace and sentry-python. None restarts a worker a limited number of times.
- The usual pattern catches failures around handling one batch, logs, drops the batch and keeps looping. Anything that escapes that guard kills the worker for the life of the process.
- Only sentry-python restarts a dead worker: lazily, on the next submit, with no limit.
- The Rust libraries read do not contain panics.

The maintainer's notes from the elicitation, verbatim. Asked what happens to a batch whose store fails, and to the data writer:

> What do other similar systems do?

Asked what the establish scope does about a dead data writer:

> Look at other similar libraries and frameworks and see what they do and let me know. We still want to make sure that we pick the decision that's most well aligned with our client, our framework, and what we want and what we desire. But I think it's good to factor in what others have done before.

What the research must find out, beyond the fields every comparable gets:

- **Dropping a failed batch.** Why an in-process library drops a failed batch and does not retry or hold it. Their batch fails at an export over a network; this client's fails at a store on a local disk. Say whether each stated reason is about the network, or about being a guest inside a host application.
- **Retrying.** Why a pipeline agent retries, why each has the limit it has, and what the retry costs. A pipeline agent is a process of its own whose job is delivery; say which of its reasons carry over to a library inside an application.
- **Not restarting.** Whether leaving a dead worker dead is a decision its authors explained, or only something nobody wrote. Look in issue threads and pull requests for a request to restart and the maintainers' reply. "No stated rationale found" is a likely and valid result here.
- **Restarting.** Why sentry-python restarts its worker, and which failure the restart was written for. Check whether it answers a crash, a fork, or something else.
- **Panics.** Whether the authors of the Rust libraries say why a panic in the worker is not contained.
- **A comparable that chose otherwise**, with its why: for example an in-process library that does retry a failed batch, or one that restarts a worker with a limit.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related open questions, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- 12: whether a bounded retry comes before a failed batch is dropped.
- 14: whether a data writer that has died stays stopped or is restarted.

**Research file:** `.scratch/client-spec/research/13-store-failure-and-data-writer-death.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does the documentation, or the source at a named version, show the behaviour the file claims for each library, including each of the seven worker loops?
2. Is "does not restart" shown to be a choice its authors explained, or is an absence of code presented as a decision?
3. Does each fit argument face the differences: their batch fails at a network export and this one at a local store, and a pipeline agent is its own process while this client is a guest?
4. Does the file recommend or imply an answer to open question 12 or 14?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] Source code is cited at a named version or commit, for each of the seven libraries
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] For the stated behaviour (a failed store drops its batch and the data writer carries on), the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [x] Where the verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [x] The file says what the evidence bears on open questions 12 and 14 and recommends an answer to neither; both are still open in the specification
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/13-store-failure-and-data-writer-death.md`, beside the issues folder. This section summarises it. Open questions 12 and 14 are still open in the specification: nothing in the research answers either, and the specification is not edited.

### Findings

The survey covers the OpenTelemetry specification and the seven libraries whose worker loops the elicitation read (L1 to L8), three pipeline agents (P1 to P3), and six comparables that chose otherwise (O1 to O6: Kafka's producer, Logback, Log4j 2, Erlang/OTP, Akka and Pekko, OpenTelemetry .NET). Every library is read in source at a named version or commit. For each, the file records what it does, the stated why, quoted and linked, or "No stated rationale found" with where was looked, any inferred why, labelled, the constraints, the costs and dissent, and the fit. Every quotation was checked as a substring of source text fetched again: 213 blockquotes at the last check, 212 exactly and 1 once whitespace is collapsed, and 82 quotations inside sentences, all found.

- **The nine claims, checked again.** One is wrong: Prometheus remote-write retries with no limit in attempts or time; "two hours" is the tuning page's account of what the write-ahead log keeps. Four are partly right: Python's handlers, the Collector (bounded by time, not by the queue; the claim describes a processor removed in 2021), the usual guard pattern, and sentry-python's restart, which was written for fork and restarts a crashed thread as a side effect. Four are confirmed, two of them with a qualification or exceptions.
- **Where the failure happens splits the comparables.** Of the five libraries the elicitation read that export over a network, four retry a retryable error within a bound before they drop; sentry-python never re-sends a failed envelope. None of those that fail at a write to a local file or disk retries the failed write (CPython's file handlers, tracing-appender, Logback, Log4j 2, OpenTelemetry .NET's disk buffer, the Collector's persistent queue); CPython's `SysLogHandler` resends once to a local daemon over a Unix socket, which the file counts as a send. What becomes of the write varies, and the file says how.
- **Carrying on has stated whys that fit.** sentry-python's batcher (#7186) and OpenTelemetry .NET's resend thread each say why one failed item must not end a background worker.
- **Not restarting has no stated why.** None of the seven libraries restarts with a limit, and none says why it leaves a dead worker dead. The field reports read were each answered with a wider guard or a fix. Erlang/OTP, Akka and RabbitMQ's fork of the OTP supervisor restart with limits or delays, in runtimes built for it.
- **No library read contains a panic.** Neither Rust library has `catch_unwind` outside tests, and each panic reported in the field killed the worker.

### Verdict

**The behaviour (a failed store drops its batch and the data writer carries on) rests on a stated why that does not transfer.** Carrying on has stated whys that fit this client. Dropping the batch at once, rather than retrying it first, has stated whys that are about a remote server (Sentry's transport specification), about a handler that hangs its thread while a retry with no limit keeps failing (CPython), or against retrying without limit (Sentry's offline caching). Most of the comparables that fail at a local write state none. No stated why that transfers chooses between dropping at once and a bounded retry: that choice is open question 12.

**A question for the maintainer**, raised by the triage of the second key moment under `REVIEW.md` section 3: does "drops its batch" in this ticket's verdict box mean "at once, with no retry", or only "dropped rather than held", with the timing left to the "No retry" bullet? The file reads it as the first, because this ticket's research ask defines dropping as "does not retry or hold it" and `FailBatch` drops at once. On the second reading, the guest's reasons and Sentry's rule against an endless retry loop would lean toward "a stated why that fits".

### Proposed wording

The file gives replacement comments for `FailBatch` and `DataWriterDiesUnexpectedly`, an addition to the guidance on panics, and corrected text for the "Failed stores" survey in `CONTEXT.md`. Each changes only what the text says the behaviour rests on ("informs", not "because"), never the behaviour. None is applied, and none was run through the pinned checker, because `just check-specs` checks only the tracked module.

### What the findings bear on

The file reports what the evidence bears on open question 12, open question 14 and the guidance on panics, and recommends nothing. For each question it gives what comparables do, the stated reasons on each side, and the costs recorded with each answer. What it reads from this specification is labelled Inferred. Unknown: how often a local store fails for a reason that passes; no source measured it.

### Adversarial review

Every review ran on Codex (codex-cli 0.172.0) with `gpt-6.2-sol`, which the maintainer chose in place of `REVIEW.md`'s preferred `gpt-6-astra`. Each session header recorded the model. Every reviewer had live web search under this ticket's authorisation and a read-only sandbox. Before the first review, two preflights confirmed that Codex ran `gpt-6.2-sol` and could open a URL. Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), neither the author nor a reviewer. The review and triage files are under `ai_tmp/client-spec-review/13/`, which is not committed.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | L1 omitted the specification's exception to a bounded export, and its reason | Valid | Exception and its reason quoted |
| 1, 1, sources | 2 | L2 said the PR author "declined" a restart | Valid | Reworded: unsure, left open; the third comment quoted |
| 1, 1, sources | 3 | L2's "six attempts" missed HTTP's immediate second request | Valid | Added, with the code comment's reason |
| 1, 1, sources | 4 | L3's guard summary said every `Throwable` lets the loop go on | Valid | Fatal ones rethrown and end the worker |
| 1, 1, sources | 5 | L4's `AlreadyShutdown` missed the `InternalFailure` case | Valid | Added |
| 1, 1, sources | 6 | L5 bounded a failed write's loss to one line | Valid | A failed flush added; no bound in the code |
| 1, 1, sources | 7 | L5 said tracing #3467 was closed | Valid | Open at the date read; the reporter's comment quoted |
| 1, 1, sources | 8 | L6: `MemoryHandler` has no guard and can resend | Valid, high | Bullet and quotations added; table rows 2 and 7 |
| 1, 1, sources | 9 | L7: `PyErr_Print` exits the process on `SystemExit` | Valid, high | Added as Inferred, with the CPython documentation |
| 1, 1, sources | 10 | L7 omitted PR #14163's why and cost | Valid | Both quoted |
| 1, 1, sources | 11 | L8 omitted the async worker's fresh queue | Valid | Added, with the transport's switch |
| 1, 1, sources | 12 | P2: the 5 minutes gate the next retry, not an attempt in flight | Valid | P2 and table row 4 reworded |
| 1, 1, sources | 13 | P3 missed the log-based commit's stated why | Valid | Commit `1ef17db` quoted |
| 1, 1, sources | 14 | P3's "4xx never" ignored 429 | Valid | Corrected, specification quoted |
| 1, 1, sources | 15 | O2 said the failed write's bytes are lost | Valid | Narrowed; buffered stream and reopen quoted |
| 1, 1, sources | 16 | O3: failover needs `ignoreExceptions=false` | Valid | Prerequisite stated and quoted |
| 1, 1, sources | 17 | O4 missed OTP PR #1287's backoff proposal | Valid | Added as dissent, with the OTP team's replies |
| 1, 1, sources | 18 | O5: classic default stops on three exception types | Valid | Corrected and quoted |
| 1, 1, sources | 19 | aiosqlite, a local-database comparable, was missed | Valid, not required | Named under "Candidates not examined" |
| 1, 1, sources | S1, S2 | No stated reason for not restarting, or for the default values | Invalid | The file already records both |
| 1, 1, sources | S3 | The buffered-file probe was not reproduced | Invalid | Reproduced by the triage on CPython 3.9.6 |
| 1, 1, reasoning | 1 | The specification's SHOULD NOT and "significantly" read as absolutes | Valid, high | Table row 1, L1, L2 and L4 restored to the text's scope |
| 1, 1, reasoning | 2 | Python ignores a returned `FAILURE`; one class, not one instance | Valid | Table row 1 and L2 corrected |
| 1, 1, reasoning | 3 | L2 said no PR asked for a restart, beside one that did | Valid | Scoped to the searches |
| 1, 1, reasoning | 4 | L2's 30 s bounds the join, not shutdown | Valid | Corrected |
| 1, 1, reasoning | 5 | L3's timed wait does not cancel the export; daemon why missing | Valid | Both added, with #1093 and PR #1120 |
| 1, 1, reasoning | 6 | L4's retry deadline does not bound an export in flight | Valid | L4 and "chose otherwise" qualified; full note quoted |
| 1, 1, reasoning | 7 | As sources 5 | Valid, low | As sources 5 |
| 1, 1, reasoning | 8 | As sources 6 | Valid | As sources 6 |
| 1, 1, reasoning | 9 | `SocketHandler` is silent; `MemoryHandler` keeps its buffer | Valid | Table row 2 and L6 corrected |
| 1, 1, reasoning | 10 | `QueueListener` can be restarted by its caller | Valid, low | Table row 6 and L6 say "on their own" |
| 1, 1, reasoning | 11 | ddtrace's child rebuilds its writer whatever the parent's state | Valid | Corrected; the Celery comment quoted |
| 1, 1, reasoning | 12 | As sources 11; the fork claim scoped to the threaded worker | Valid | Table row 8 and L8 scoped; PR #4591 quoted |
| 1, 1, reasoning | 13 | Fluent Bit's limit counts retries, not time; S3 quarantines | Valid | P1 and table row 3 corrected |
| 1, 1, reasoning | 14 | As sources 12; the old processor also dropped at once | Valid | P2 history corrected |
| 1, 1, reasoning | 15 | The Collector's persistent queue fails at a local write | Valid | Added to the local-write inventory |
| 1, 1, reasoning | 16 | Prometheus agent mode, and 429 | Valid | Table row 5 and P3 corrected |
| 1, 1, reasoning | 17 | As sources 16 | Valid | As sources 16 |
| 1, 1, reasoning | S1, S2 | Java's 10 s across senders; ddtrace's `PanicException` | Invalid | Checked by the triage; the file's labels hold |
| 1, 1, reasoning | S3 | Two negatives stated as facts | Valid in part | Scoped to "found in these searches" |
| 1, 2, sources | 1 | L2: Requests' timeout does not cap a request | Valid, low | Added, with the Requests documentation |
| 1, 2, sources | 2 | Table row 1: a returned `FAILURE` may go unlogged | Valid, low | Reworded |
| 1, 2, sources | 3 | L4: a shutdown waiting on a panicked worker logs an error | Valid, low | Added |
| 1, 2, sources | 4 | L5: a failed flush can swallow the shutdown message | Valid | Added; the final flush's print quoted |
| 1, 2, sources | 5 | L6: `StreamHandler` re-raises `RecursionError` | Valid, low | L6 and table row 2 corrected |
| 1, 2, sources | 6 | L6: `stop()` on a full bounded queue raises | Valid, low | Added; table row 6 qualified |
| 1, 2, sources | 7 | P2: the persistent queue stops reading at shutdown | Valid | Corrected and quoted |
| 1, 2, sources | 8 | Table row 5 stated the tuning page's two hours as exact | Valid, low | Reworded |
| 1, 2, sources | 9 | P3: PR #8549's design document is readable | Valid | Read; the author's why and Tom Wilkie's objection quoted |
| 1, 2, sources | 10 | O4: only `permanent` children always restart | Valid | Corrected and quoted |
| 1, 2, sources | 11 | O4: the 2012 board decision | Valid, low | Added |
| 1, 2, sources | 12 | O6: the .NET disk path's local write and per-blob guard | Valid | Added and quoted; local-write inventory updated |
| 1, 2, sources | S | hawkw's attribution on PR #673 | Invalid | Confirmed by the API |
| 1, 2, reasoning | 1 | L3: Java's retry policy does not reach the `ManagedChannel` sender | Valid | Added and quoted; table row 1 qualified |
| 1, 2, reasoning | 2 | L4: queued requests also get `InternalFailure`; the exporter's shutdown can panic | Valid | Corrected |
| 1, 2, reasoning | 3 | L6: `HTTPHandler` ignores an error status | Valid | Added; table row 2 |
| 1, 2, reasoning | 4 | L8: "chose a guard over a restart" | Valid | No restart was discussed; reworded |
| 1, 2, reasoning | 5 | P1: the backoff cap bounds waits, not retention; "declined" | Valid | Reworded |
| 1, 2, reasoning | 6 | L1: the SDK is not at most once | Valid | Reworded |
| 1, 2, reasoning | 7 | As sources 4 | Valid | As sources 4 |
| 1, 2, reasoning | 8 | L8: 413, 429 and rate-limit headers counted differently | Valid | Corrected and quoted |
| 1, 2, reasoning | 9 | As sources 8; agent mode bounds the cut, not deletion | Valid | Table row 5 and P3 corrected |
| 1, 2, reasoning | 10 | As sources 10 | Valid | As sources 10 |
| 1, 2, reasoning | 11 | aiosqlite: `executemany` and its `BaseException` guard | Valid in part | Added; the awaiting point was already there |
| 1, 2, reasoning | 12 | O2: `flush()` can end recovery without a reopen | Valid | Added and quoted |
| 1, 2, reasoning | 13 | L3: PR #1120 is not quoted "in full" | Valid, low | Reworded |
| 1, 2, reasoning | S | ddtrace's `PanicException` path | Valid in part | `block_on` quoted; a spawned task's panic left untraced |
| 2, 1, sources | 1 | The verdict said every local write is dropped at once | Valid, high | "None retries the failed write", with what becomes of it in each |
| 2, 1, sources | 2 | SQLite's bounded lock wait is a local wait the file missed | Valid in part | Added, with its sources; no stated why, so not a reason for retrying |
| 2, 1, sources | 3 | The loss trade assumed outcomes; a kill loses rows uncounted | Valid | Constraints, verdict and question 12 corrected; the Derived wait at the end of establish added |
| 2, 1, sources | 4 | The network count mixed retry layers and overrated time bounds | Valid | Budgets an attempt can outlast, and sentry-python's in-request retry, named |
| 2, 1, sources | 5 | OTel Python's review "declined" a liveness check | Valid | Left open, as L2 says |
| 2, 1, sources | 6 | OTel Rust's worker is joined on a normal shutdown | Invalid | The sentence is about a panicked worker; made explicit, with the join quoted |
| 2, 1, sources | 7 | The question 14 wording overweights non-restart; the fresh queue has a why | Valid in part | "Informs" kept; crashed workers restart too; "to avoid stale items" added |
| 2, 1, sources | 8 | CPython's hang can fall on a `QueueListener` thread | Valid | Five places corrected, the cookbook quoted; the verdict's category kept, the hang transferring only as a stalled data writer |
| 2, 1, sources | 9 | tracing-appender can spin on a failing flush after disconnection | Valid | Added, Inferred from the code |
| 2, 1, sources | 10 | .NET's guard is about resending a stored blob, which it keeps | Valid | Fit, verdict and question 14 say so |
| 2, 1, sources | 11 | The agents' limits "set against" hold time was unsupported | Valid | Retries and retention named as separate bounds |
| 2, 1, sources | 12 | RabbitMQ's delayed restart was missing as a counterweight | Valid in part | Pinned and quoted in O4; added to the fit and question 14, with no stated why |
| 2, 1, sources | 13 | Java v1.64.0's date; #7099 describes the design | Valid | Date corrected to 2026-07-10; #7099 described as a design, not an incident |
| 2, 1, sources | S1 | The 2012 OTP board decision | Invalid | Already marked as recalled |
| 2, 1, sources | S2 | Full disk shown as eviction | Out of scope | Ticket 17; already marked unchecked |
| 2, 1, reasoning | 1 | The verdict covered only the drop half | Valid, high | One verdict on the whole behaviour, still "does not transfer"; a question for the maintainer below |
| 2, 1, reasoning | 2 | As sources 1, and Log4j's failover | Valid, high | As sources 1 |
| 2, 1, reasoning | 3 | As sources 3 | Valid, high | As sources 3 |
| 2, 1, reasoning | 4 | As sources 11; one Collector path generalised to agents | Valid | As sources 11; the Collector's returned error quoted |
| 2, 1, reasoning | 5 | As sources 5; the restart wording lost its qualifications | Valid | As sources 5; the proposed comment scoped to the searches |
| 2, 1, reasoning | 6 | As sources 7; OTP's sub-millisecond cost misattributed | Valid | As sources 7; the threaded restart keeps its queue; the OTP cost tied to no delay |
| 2, 1, reasoning | 7 | "No level above it except stopping" assumed part of question 14 | Valid | Restated as the current proposal, with question 14 owning it |
| 2, 1, reasoning | 8 | As sources 4 | Valid | As sources 4, with the failure class |
| 2, 1, reasoning | 9 | OTel Python evicts the oldest; this client refuses the arriving row | Valid | Added and quoted |
| 2, 1, reasoning | 10 | As sources 6 | Valid in part | As sources 6 |
| 2, 1, reasoning | 11 | The panic wording lost abort and unwind safety | Valid | Proposed guidance and the file corrected; `catch_unwind` quoted |
| 2, 1, reasoning | 12 | Claims row 2: the rotating handlers catch `RecursionError` | Valid | Row 2 and L6 corrected and quoted |
| 2, 1, reasoning | S1 | Fluent Bit's and Prometheus's failed local write | Invalid | Already disclosed as not examined |
| 2, 1, reasoning | S2 | "Each failure came from a defect" | Valid | Restated as how the reports were treated |
| 2, 2, sources | 1 | The verdict tied queue refusals to a failed retry only | Valid | Refusals follow either outcome while the retry lasts (`TakeBatch`) |
| 2, 2, sources | 2 | SQLite documents retrying a `COMMIT` refused because of a reader | Valid in part | Added as the nearest thing, quoted; not a stated reason for retrying a batch |
| 2, 2, sources | 3 | "Two do" counted Sentry's rule as a local-write why | Valid in part | "The second only by analogy"; CPython's was a local write and stands |
| 2, 2, sources | 4 | The OTP sentence merged an interim concern, a disputed argument and the closure | Valid | Each position attributed; the closure's reason quoted |
| 2, 2, sources | 5 | RabbitMQ's delay has a different trigger and a stated use | Valid | Trigger corrected; Tim Watson's stated use quoted; fit and question 14 updated |
| 2, 2, sources | 6 | "Crashed or not" blurred sentry-python's not-alive check | Valid, low | The condition stated |
| 2, 2, sources | S1 | RabbitMQ's original motivation | Valid, folded into 5 | Not searched for, and said so |
| 2, 2, sources | S2 | The 2012 OTP board decision | Invalid | Already marked as recalled |
| 2, 2, reasoning | 1 | The verdict's whys did not establish its category | Valid | Category kept, "does not transfer"; PR #511 removed as a why for dropping at once; why not "no stated why" said |
| 2, 2, reasoning | 2 | The CPython thread was closed as too uncommon, after a capped retry | Valid | The closure, the reporter's cap and the console context quoted; fit, verdict and question 12 corrected |
| 2, 2, reasoning | 3 | Effects tied to the wrong retry outcome; establish waits | Valid | As sources 1; hand-over delay for either outcome; the CPython fit names the wait at the end of establish |
| 2, 2, reasoning | 4 | The proposed wording's worker claim overgeneralised | Valid | Scoped to libraries with a background worker; Logback's plain appender stops itself |
| 2, 2, reasoning | 5 | SQLite's busy timeout is accumulated sleep and skips `SQLITE_LOCKED` | Valid, low | Corrected in both places, quoted |
| 2, 2, reasoning | 6 | RabbitMQ's delayed restart resets the count | Valid, low | Added and quoted; not OTP's spacing |

**Code review.** The `code-review` skill (Claude Code, Claude Opus 5.5, high effort) then ran on the whole diff. Its eight findings were all applied. In the research file: `QueueListener`'s restart by its caller qualified in question 14; CPython's `SysLogHandler`, which resends once over a Unix socket, named and counted as a send, with "a local write" narrowed to a write to a local file or disk in the verdict, the proposed `FailBatch` comment and the survey text; the list of local-write comparables made the same in the overview as in the verdict; Java's first comment described as saying what its catch is for, not why; the network count scoped to the libraries the elicitation read, with Kafka and OpenTelemetry .NET added as retrying too; tracing-appender #3467 described as one stale request; and "a sentence" corrected to three. Its eighth finding, that the work was not yet committed or gated, is answered under "Gates and files".

**Open points.** Every numbered finding, 98 in all, and every suspicion was applied or settled. What remains is for the maintainer, and is stated in the research file or above:

- The question above on what "drops its batch" in the verdict box covers.
- The proposed wording was not run through the pinned checker.
- The second key moment's second-round fixes, a few follow-on edits made to agree with them (the proposed comments rewrapped; Logback's plain appender added to the verdict's list), and the code review's fixes were not reviewed again after they were applied.
- Several local-write comparables (the .NET disk buffer, the Collector's persistent queue, Fluent Bit's and Prometheus's own buffers) were not searched for a stated why, and the file says so. Elastic APM, the OpenTelemetry Go exporter and the Datadog Go and Java tracers were not researched.

### Gates and files

- **Baseline**, at `90f0abb`, the untouched branch:

  > All checks passed and the worktree is unchanged.

- **Final**, at `62ad652`, the research file and this hand-back as reviewed and fixed. The commit that records this line changes only this section's lines.

  > All checks passed and the worktree is unchanged.

- **Changed files:** this ticket and its research file only. The specification is unchanged, and open questions 12 and 14 are still in it. No code was added.
