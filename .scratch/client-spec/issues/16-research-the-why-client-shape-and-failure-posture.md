# 16: Research the why: client shape and failure posture

**What to build:** The maintainer can see whether what the agent said about idiom and usual practice, when the client's shape and failure posture were settled, is true, and why the libraries it named are built as they are. No survey was run for any of it: every claim below came from the agent's own knowledge. This ticket checks each claim for the first time, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

The shape itself is the maintainer's design and is not reopened here. What is under test is the agent's account of other libraries, which the maintainer relied on.

What the specification proposes today, and what it was said to rest on:

- **A confluence, establish and a client handle.** A confluence is created at global scope and tables are declared against it. Establish is a top-level block that gives the confluence a core for its duration: the production core, or a fake core in tests. Application code opens a client handle for one unit of work. The maintainer proposed this shape and asked whether it is idiomatic Rust. The agent answered that it is.
- **The failure posture.** Declaring a table and establish may fail loudly. Opening a client handle and every write never fail and never block, and a write returns nothing. The maintainer delegated this choice, and the agent chose it as "the usual posture of observability libraries".
- **Inert without establish.** With no establish in force, writes are discarded and counted, and nothing fails.
- **The establish block owns the data writer.** The agent framed the lifetime questions with structured concurrency: every background activity lives inside a scope that someone visibly opens and closes.
- **The fake core.** A test establishes a fake core, which records every write with its outcome. The specification marks its rules "Derived".

Claims to check for the first time. Each came from the agent's own knowledge:

- The shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests".
- A Python `with` block maps to a Rust guard value or a closure scope.
- Observability libraries usually let set-up fail loudly and never let a call on the serving path fail or block.
- Structured concurrency says every background activity lives inside a scope that someone visibly opens and closes.

The maintainer's notes from the elicitation, verbatim. Asked who starts and ends the client:

> A mix of this and option1. Have a "Confluence" object created at the global scope. It is then used within the application code to request the client via a factory-ish method (with block in python). Then at the different top level contexts the Confluence is configured with either the production core (which links to the writer) or a fake in the context of tests. Let me know if this does or does not feel like idiomatic Rust. If it doesn't feel like idiomatic Rust, then we can just focus on the Python client for now, or we can just consider this overall approach for something that can be idiomatic for both. Or maybe if full threading explicit is more idiomatic for Rust, but then we could still build something like this for Python based on that, we could consider that as well.

Asked which calls may fail loudly and which must be swallowed and counted:

> Whatever option is most idiomatic while also within those boundaries, what's considered idiomatic, normal, and acceptable, whatever will allow for the most, the best developer experience and the best operator experience.

The maintainer made the Rust answer a condition: the note offers other courses if the shape does not feel idiomatic. So a claim that fails here matters, and is reported plainly.

What the research must find out, beyond the fields every comparable gets:

- **The Rust facades.** For each of the `log`, `tracing` and `metrics` crates, check each of the three parts of the claim separately: a global entry point, a backend installed at the top level, and a scoped override for tests. The claim may hold for some crates and not for others. Capture why each crate's authors chose a global facade, what they say it costs, and what they say about tests.
- **Python logging.** How the standard library's logging is shaped along the same three parts, and why.
- **OpenTelemetry's split.** Why OpenTelemetry separates an API from an SDK, what the API does when no SDK is installed, and what its specification says about errors. This bears on "inert without establish" and on both halves of the posture.
- **Both halves of the posture.** The claim has two halves and neither was checked: that set-up may fail loudly, and that the serving path never fails or blocks. Find libraries that swallow set-up failures too, and libraries whose serving path can raise or block, and capture why.
- **Structured concurrency.** Where the idea was stated by those who introduced it and by the languages that built on it, what it promises, and what it says about a background worker that outlives or dies inside its scope.
- **Fakes for tests.** What comparable libraries give a test to capture what was recorded, and whether any promises that the fake applies the same rules as the real thing.
- **A comparable that chose otherwise**, with its why: for example a library that passes its client explicitly and has no global, or one that raises on the serving path.
- **The names, for open question 18.** What "confluence", "establish" and "core" already name elsewhere, including the well-known product called Confluence. These are facts for the maintainer, not comparables, and need no why.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related entries, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- Open question 18: whether confluence, establish and core are the final names.
- The "Derived" statements about the fake core, nested establish and a handle shared between threads. Ticket 11 puts them to the maintainer. This ticket confirms none of them.
- The open-decisions register's Product entries. Each leaves the register only when a decision record answers it, and that record is the maintainer's to make.

**Research file:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Is each of the three parts of the facade claim checked for each of the three crates from documentation or source, and is every place it does not hold reported?
2. Are both halves of the posture claim checked, and were libraries that do otherwise looked for?
3. Does the file keep apart the maintainer's own design, which is not reopened, and the agent's claims about other libraries, which are under test?
4. Does the file recommend a name for open question 18, confirm a "Derived" statement, or close a register entry?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] Each claim listed above is checked from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] The facade claim is checked part by part for each of the `log`, `tracing` and `metrics` crates, and the file says for which it holds
- [x] Both halves of the failure-posture claim are checked, each against at least three libraries
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] For each stated behaviour above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [x] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [x] The file lists what the three names already mean elsewhere and recommends no name; open question 18 is still open in the specification
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/16-client-shape-and-failure-posture.md`, beside the issues folder. This section summarises it. The specification is not edited, and open question 18 is still open in it.

### Findings

The survey covers 57 systems in nine groups, each with the fields under "Citing a comparable" and a fit:

- the Rust facades (A1 to A4);
- Python's `logging` (B1);
- OpenTelemetry's API and SDK (C1 to C3);
- guard values and closure scopes (D1 to D4);
- a posture survey of fourteen libraries (E1 to E14);
- values and blocks that own a background worker (G1 to G7);
- comparables that chose otherwise (H1 to H7);
- structured concurrency (S1 to S7);
- fakes for tests (T1 to T10).

What the three names already mean elsewhere is in N1 to N3, as facts only. Every blockquote, 976 at the last check (775 in the draft, the rest added in review), was checked by machine as a substring of source text that the last check fetched again into an empty cache.

The facade claim, part by part (the file's two tables at the top give each cell):

- **`log`:** a global entry point holds. A top-level install holds, by convention and once per linked copy of the crate. A scoped override for tests does not hold: there is none, shown from the full item index, and requests for one were declined.
- **`tracing`:** the first two parts hold. The scoped override holds with limits: it is per thread, and it has open defects with guards sent between threads, guards dropped out of order, and an interest cache that silences a scoped subscriber in parallel tests.
- **`metrics`:** the first two parts hold. The scoped override holds with limits: it is per thread, it does not redirect a handle registered before it, and nested guards restore correctly only when dropped innermost first.
- **In none of the three** is the global an object the application creates and declares things against, which a confluence is. In none can the top-level install be given again. In none can it end, except that `metrics-util`'s `RecoverableRecorder` lets the application end the recorder behind `metrics`' global, which then cannot be installed again. In `metrics` and OpenTelemetry Rust, a handle or tracer obtained before a backend is installed stays a no-op.

### Verdicts

On the agent's four claims:

1. **The facade claim:** holds in part, and is wrong for `log`.
2. **A `with` block maps to a guard or a closure:** holds in part. The three differ in what the end of a scope can guarantee or report.
3. **The posture is usual:** wrong under one reading of the sentence, and Unverified under the other. The sample was chosen to cover both directions, so it shows the posture is one of several and cannot show how common it is.
4. **Structured concurrency puts every background activity in a visible scope:** holds in part. Every system keeps a sanctioned way out for long-lived work.

On the five stated behaviours, one verdict each:

1. **Confluence, establish and client handle:** rests on a stated why that does not transfer. The facades' reasons do not cover a backend with a duration that is given again, or declaring against an object before any backend exists.
2. **The failure posture:** rests on no stated why for the whole behaviour. OpenTelemetry's reason fits the serving half, and `client_golang`'s fits declaring a table loudly. None found covers establish failing loudly: `sentry`'s reason for one panic moved to initialisation, to avoid a deadlock after the first capture, informs it. None covers a write that returns nothing: `cadence`'s reason for a `send` that returns nothing informs it.
3. **Inert without establish:** rests on no stated why for the whole behaviour. Discarding fits OpenTelemetry's and `log`'s reasons. A stated reason for counting fits an establish that has ended. It reaches a failed establish the host caught only by the file's own argument, and is not shown for a host that never established or a forked child's copy.
4. **The establish block owns the data writer:** rests on a stated why that fits. Structured concurrency's lifetime reasons fit the end condition as the specification states it today, which stays Derived. Open question 26 stays open.
5. **The fake core:** rests on no stated why. None of the ten fakes surveyed promises that it applies the real rules.

Proposed wording for the maintainer is in the research file for behaviours 1, 2, 3 and 5, and as an optional note for 4. It is for `CONTEXT.md` and for comments in the specification, neither of which this ticket edits.

### Adversarial review

- **Reviewers.** Every review ran on Codex (codex-cli 0.172.0) with `gpt-6.2-sol`, at reasoning effort `ultra`, in a read-only sandbox with live web search. That model was the maintainer's choice in this session, in place of `REVIEW.md`'s preferred `gpt-6-astra`. Each session header recorded the model.
- **Preflight.** Before the first review, a preflight confirmed that Codex ran `gpt-6.2-sol` and opened two URLs. The author's own shell checked docs.rs, raw GitHub and the GitHub API before the survey. The research subagents fetched with `curl` and `gh` from that shell; no subagent ran a separate preflight.
- **Triage.** Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), which was neither the author nor a reviewer. One triager (first key moment, round 2, sources) split its 39 findings across six further Opus 5.5 subagents and re-checked four findings' sources itself.
- **Applying.** A fifth subagent per round applied the valid solutions to the file's sections. After the last round the author read Fit, both verdict sections and "What the findings bear on" in full, checking that nothing recommends a name, confirms a Derived statement or answers an open question.
- **Files.** The review, triage and apply files are under `ai_tmp/client-spec-review/16/`, which is not committed.
- **Coverage, from each review's own table.** Each reviewer listed the distinct links it opened in each section. The author compared those counts with the distinct links in each section at the commit the round reviewed.
  - First key moment, round 1 (`7ccfb0b`): both reviewers opened every link in A1 to A4. In each other section, the sources reviewer opened one to three links and the reasoning reviewer one to five.
  - First key moment, round 2 (`c8b33d9`): the sources reviewer opened three to 22 links per section. The reasoning reviewer opened two to 13, covering only the changed passages in A1 to A4. Both opened at least three in each section from B1 to N3.
  - Second key moment, round 1 (`2933106`): both reviewers' counts equal the file's distinct links in every section except where a link could not be opened: D1, S1, S7 and N1 for both, and B1 for the sources reviewer. The sources reviewer shows those as fractions (B1 38 of 39, D1 11 of 12, S1 5 of 7, S7 4 of 5, N1 14 of 15) and checked author or pinned copies instead.
  - Second key moment, round 2 (`06a728b`): the sources reviewer's counts equal the file's distinct links, with the same exceptions apart from B1. The reasoning reviewer opened two to 15 per section.

**Every finding and suspicion, 170 in all.** 162 were judged valid, in whole or in part (a few needing no edit), and 8 invalid; none was out of scope. The first key moment's first round, sources, finding 22, is counted once, as invalid: its B1 part was invalid and its D4 part valid in part, and the D4 part was applied.

The resolution column gives the triage's solution. There, `r:` and a number give a line of the research file at the commit that round reviewed: `7ccfb0b`, `c8b33d9`, `2933106` and `06a728b`, in order. Each valid solution was applied, merged into one edit where the two lenses overlapped. A few were applied in a changed form, as the appliers' logs record:
- **Duplicates left out:** a duplicate `Drop` quotation in A4.
- **Cited inline:** a `Cargo.toml` default, rather than quoted.
- **Dropped:** a JDK schedule quotation whose table cells run together once the HTML is stripped (S4).
- **Source changed:** a Swift forum post is quoted from its raw form (S6).
- **Narrowed:** a few merged passages, where the combined text would otherwise have argued past its sources.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | `tracing` recursion guard skipped on the global-only path | valid | Qualify r:554 and r:717; quote the `SCOPED_COUNT` fast path |
| 1, 1, sources | 2 | `log` saved `logger()` reference and `logger:` route | valid in part | Qualify r:71 and r:88; quote the `&NOP` return and the `Off` default |
| 1, 1, sources | 3 | `metrics` local recorder before global install | valid | Reword r:843 and r:73 with the selection order |
| 1, 1, sources | 4 | `metrics` guard restoration depends on drop order | valid | Qualify r:929, r:1101 and r:64; quote the destructor and PR #523; add Unverified on the crash |
| 1, 1, sources | 5 | `metrics` compatibility reason at introduction | valid in part | Replace r:1079 with the contributor's stated reason; narrow r:1090 |
| 1, 1, sources | 6 | `metrique` global sink panics before attach | valid | Add a bounded dissent bullet at r:1166 (0.1.34, no stated rationale found) |
| 1, 1, sources | 7 | OTel Rust replacement drops and can shut down the old provider | valid | Correct r:1190, r:1357, r:1474, r:1556, r:3900 and r:4230; quote the setter and `Drop` |
| 1, 1, sources | 8 | OTel Rust simple processor lock wait outside timeout | valid | Split r:1491 by processor |
| 1, 1, sources | 9 | OTel Rust span after shutdown skipped silently | valid | Rewrite r:1492; quote `span.rs` and the provider docs |
| 1, 1, sources | 10 | OTel Java autoconfiguration throwing branch | valid in part | Add the reflection-failure branch at r:2147 and r:2187 |
| 1, 1, sources | 11 | Log4j 2 `AsyncAppender` start failure propagates | valid in part | E1 set-up cell "Mostly no", r:2820 and r:3667 qualified; both entry points traced in E1's Unverified; from code, not run |
| 1, 1, sources | 12 | Python `MemoryHandler.emit` unguarded | valid in part | Qualify r:1650 and E3's failure cell; quote `BufferingHandler.emit` and `MemoryHandler.flush` |
| 1, 1, sources | 13 | Kafka `max.block.ms` scope | valid | Narrow r:2808 and r:3665 with the serializer clause |
| 1, 1, sources | 14 | Micrometer 1.18 moved scrape failures to registration | valid | Add the 1.18 change and its stated reason to E5, wiki pinned at `8f46ab2` |
| 1, 1, sources | 15 | `prometheus_client` multiprocess I/O | valid | Split E6's blocking cell and r:3170 by mode; every update writes, not only first use |
| 1, 1, sources | 16 | Sentry no capacity wait is not never blocking | valid in part | Reword E10 and E11 blocking cells around synchronous `before_send`; the locks are brief |
| 1, 1, sources | 17 | Sentry Rust non-nil UUID on queue drop | valid | Correct E11's failure cell; quote `event_id` and the overflow arm |
| 1, 1, sources | 18 | tracing-appender lines handled are not necessarily written | valid | Reword r:3697; quote the ignored-error branch |
| 1, 1, sources | 19 | slog collaborator's guard rationale | valid | Add the hedged "IIRC" quotation after r:4305 |
| 1, 1, sources | 20 | Rust `scope` panic and thread-local caveats | valid | Rewrite S7 "When a child fails" (own panic message, automatic joins only); add the destructor caveat |
| 1, 1, sources | 21 | pytest T5 speaker attribution | valid | Attribute 4707909507 to the reporter `vallsv` (`NONE`) |
| 1, 1, sources | 22 | B1 and D4 version citations | invalid (B1), valid in part (D4) | B1 anchors land correctly at `v3.15.2`; reword D4's "version-pinned path" |
| 1, 1, sources | S1 | `metrics` crash at 0.24.6 | valid (open item) | Unverified line under finding 4; no crash asserted |
| 1, 1, sources | S2 | No rationale for keeping both `metrics` APIs | valid | Covered by finding 5's edits |
| 1, 1, reasoning | 1 | Different tests for one facade part | valid | A2 relabelled "Holds, with limits"; A4 install "Holds, by convention", with repeatability kept separate |
| 1, 1, reasoning | 2 | Objects obtained before install | valid | Answer for `log::logger()`, tracing `Span` and metrics handles registered under a local recorder (lines 71 to 73, 843, 904) |
| 1, 1, reasoning | 3 | Discarded without a subscriber | valid | Qualify line 717 with the non-default `log` feature and quote it |
| 1, 1, reasoning | 4 | Metrics guard drop order | valid | Add the innermost-first condition and the `Drop` source to line 929 and the table |
| 1, 1, reasoning | 5 | Static slot versus its contents | valid | Replacement drops the old global clone; fix lines 1190, 1357, 1556 and 4230 |
| 1, 1, reasoning | 6 | Global lookup takes a lock | valid | Add the `RwLock::read` wait to line 74 and to A4 |
| 1, 1, reasoning | 7 | Frequency claim judged by counterexamples | valid | Rewrite line 2820 half by half, with "usually" Unverified; fix E2 flattening and E12's stated reason |
| 1, 1, reasoning | 8 | E1 missing versus invalid configuration | valid | E1 cell "Mostly no" naming the `AsyncAppender` throw; fix the posture lead |
| 1, 1, reasoning | 9 | Sentry serving call judged by enqueue | valid | Narrow E10 and E11 to the full-queue case; add the worker-lock and `before_send` paths |
| 1, 1, reasoning | 10 | Prometheus multiprocess file access | valid | Split E6's blocking cell and body by mode |
| 1, 1, reasoning | 11 | `OnEmit` SHOULD NOT block | valid | List the upper-case no-block texts found by grep, and drop "only" |
| 1, 1, reasoning | 12 | Shutdown request, drain and termination | valid | Fix lines 3681, 3697, 3865 and 3911 on undelivered shutdown, lost lines and the discarded export result |
| 1, 1, reasoning | 13 | `slog` tree inference | valid | Restate the inference as following logical structure, not "collapse" |
| 1, 1, reasoning | 14 | Rust `scope` exit guarantees | valid | Automatic versus manual join, a new panic message, and the thread-local destructor caveat in S7 and the S summary |
| 1, 1, reasoning | 15 | `caplog` coverage and raising | valid | Loggers non-propagating at start only; raise conditional on `logging.raiseExceptions` |
| 1, 1, reasoning | 16 | Loss visible in captures | valid | T6 bounded eviction is silent; T8 gains the per-span totals, and the batch-processor half stays Unverified |
| 1, 1, reasoning | 17 | `core::` resolution | valid | "unless a declaration in the module shadows the name", with the Reference quote |
| 1, 1, reasoning | S | Whether loud set-up is usual | valid | Covered by finding 7: the "usually" half is Unverified on a purposive sample |
| 1, 2, sources | 1 | `log` fallback keyed to "ever set" | valid | r:468 attributes "no subscriber is active" to the docs and adds the `has_been_set` mechanism with three quotations; r:750 bullet gains the condition. |
| 1, 2, sources | 2 | Recursion guard only inside `get_default` | valid | r:580 and r:750 limit the guard to `event` and `new_span`; two quotations after r:592 show the guard and `do_enter`'s direct call. Source read, not run. |
| 1, 2, sources | 3 | OTel Rust setter histories and poisoned lock | valid (both parts) | r:65, 1254, 1299, 1307, 1435, 1601 and 1654 separate the trace and meter histories and add the poisoned-lock exception, with 0.30.0 and current quotations. |
| 1, 2, sources | 4 | OTel Rust "no panic by design" | valid | r:1577 reports ADR 001's aim and the inline sampler and `on_start` calls with no `catch_unwind`; quotations inserted before r:1380. |
| 1, 2, sources | 5 | Batch shutdown: acknowledgement bounded, join not | valid | r:1424 and r:1577 say the join has no deadline, with the `span_processor.rs` quotation; the G3 Inferred bullet at r:4113 restates the mechanism. |
| 1, 2, sources | 6 | `log` no-op cost conditional on level `Off` | valid | r:301 makes the cost conditional on the default level and adds the macro quotation; round 1's "through the global" is kept. |
| 1, 2, sources | 7 | `metrique` pending sink omitted | valid | r:1229 adds the opt-in `pending_sink` (0.1.25), with the PR #275 author's reason and the resolver docs; the panic keeps "No stated rationale found". |
| 1, 2, sources | 8 | CPython handler policies: `RecursionError`, `SocketHandler`, quiet `SysLogHandler` set-up | valid in part ((a), (c) and (d) valid; (b) in part) | B1: the re-raise is limited to `StreamHandler` and the handlers that call it, and `SocketHandler`'s emit and send are quoted. E3: the failure text and cell get the `RecursionError` and `SocketHandler` exceptions, the set-up text, cell and summary sentence get `SysLogHandler`'s quiet construction, and its stated reason is quoted. |
| 1, 2, sources | 9 | `put_nowait` is not an enqueue that cannot block | valid in part (the lock is real but is not a capacity wait, per round 1's finding 16) | B1 and E3: "never blocks" becomes "never waits for queue space"; the lock and the documented `multiprocessing.Queue` deadlock are named and quoted. |
| 1, 2, sources | 10 | No reversal of `handleError` is shown | valid | B1: the bullet and the Unverified line no longer presume a change; printing at `v2.3.1` to `v2.6` is cited, and the trunk gap is stated. |
| 1, 2, sources | 11 | "PEP 282 and PEP 391 unpinnable" | valid in part (docs part: no change) | B1: the header and four `Source:` lines are re-pinned to python/peps `af21ad1`, and two quotations get the rst's straight quotes. |
| 1, 2, sources | 12 | C1's "Off it" puts all `Export` off the serving path | valid | C1: round 1's "Off it" is dropped, and the simple processor's "as soon as they are finished" is quoted, with A4 cited for Rust's caller-thread export. |
| 1, 2, sources | 13 | C2: `_logs` proxy and set-once | valid | C2: the `_logs` behaviour is added with two quotations, and the file list is updated; the Unverified bullet is removed. |
| 1, 2, sources | 14 | C3: `get()` identity and null arguments | valid in part (the reflection quotation is accurate) | C3: the first autoconfigured `get()` returns a separate wrapper (chain quoted), the Guarantees bullet is narrowed, and the null text is limited to lookups, `set(null)` throwing. |
| 1, 2, sources | 15 | D2 automatic versus explicit join | valid | Qualify r:2573, and add the `ScopedJoinHandle::join` quotation (L296-297) after r:2503. |
| 1, 2, sources | 16 | Log4j recursion route on a full queue | valid | Keep r:2993's policy sentence and add `AsyncAppender`'s `getRecursionDepth() > 1` route (L167-172), scoped to the appender. |
| 1, 2, sources | 17 | Logback XML errors and LOGBACK-898 | valid in part (a valid in part, b valid) | Quote the `SAXException` branch (L97-99) and `fatalError` (L204-207), and narrow r:3115. Add the reporter's LOGBACK-898 reason, read through the REST API as of 2026-11-24. |
| 1, 2, sources | 18 | Micrometer identity, histogram and discard scope | valid in part (a and b valid, c valid in part) | The identity is name plus tags (Meter L359). The check is on family type. The meter is not exposed through any registered collector, but is still returned and stored. Round-1 text is made precise, not reverted. |
| 1, 2, sources | 19 | Micrometer first-registration lock | valid | Lock scope from L711, L727 and L738-741 added to the body. The table cell and Unverified now say the timing is unmeasured. |
| 1, 2, sources | 20 | `prometheus_client` in-memory-only Constraints | valid | r:3367 split by mode. This completes round 1. |
| 1, 2, sources | 21 | `ddtrace` sync-mode reason and buffer size | valid | Add the `_use_sync_mode` docstring, the 20 MB default with its 10 MB agentless cap, and the class note. Update r:3823, r:3850, r:3854, r:3862, r:2941 and r:3878. |
| 1, 2, sources | 22 | G1 failed flush skips the rendezvous | valid | Add the failed-flush path to "Ending it", widen the `Err(_)` intro, quote `flush()?` |
| 1, 2, sources | 23 | G2 reqwest request deadline | valid | Answer from Sentry's builder, its lockfile and reqwest 0.13.5's doc; narrow the Unverified item to `tcp_user_timeout` and the version an application resolves |
| 1, 2, sources | 24 | G3 provider vs processor errors; warning condition | valid (both parts) | Name the receiver of each error and quote the provider's aggregation; add worker death to the warning's condition and quote the `Disconnected` comment; A4 unchanged |
| 1, 2, sources | 25 | G5 `kill()` can wait and fail | valid | Attribute "Returns immediately" to the docstring, add the lock and full-queue paths with a quote, fix the lead at r:4440 |
| 1, 2, sources | 26 | G6 30 s is per batch processor | valid | Quote sequential shutdown and the per-processor join; Constraints say "per batch processor", with no shared deadline |
| 1, 2, sources | 27 | G7 5 s does not bound the exit path | valid (both parts) | Quote the unbounded lock wait outside a microVM, the per-processor timeout, and the native join with no timeout; reword Constraints |
| 1, 2, sources | 28 | H6 process collector is optional | valid | State the `process` feature and Linux conditions; quote the `cfg` and `default` features |
| 1, 2, sources | 29 | S1 live republication of `blog:71` | valid in part | The 404 claim stands. Record the 2024 post on the author's site and the verbatim match of the five `blog:71` quotations; `blog:124` and `blog:137` stay uncompared. |
| 1, 2, sources | 30 | S2 Trio grouping as unconditional | valid in part | "Always grouped" becomes "grouped by default"; add the deprecated `strict_exception_groups=False` quotation. r:5132 already named the option. |
| 1, 2, sources | 31 | S3 spawning during teardown | valid | Limit "accepting new tasks" to before shutdown; quote the docs and the `RuntimeError` source; add van Rossum's stated reason from the comment the file already cites. |
| 1, 2, sources | 32 | S4 Java misuse exceptions and JDK 28 | valid | Split `WrongThreadException` (non-owner fork) from `StructureViolationException` (close and nesting); answer the JDK 28 question as not GA as of 2026-11-24 (GA 2027/03/09). |
| 1, 2, sources | 33 | S5 `GlobalScope` failure route and opt-in level | valid | The last-resort route applies to `launch`; `async`/`produce` leave the exception to the consumer; record `RequiresOptIn.Level.WARNING`. |
| 1, 2, sources | 34 | T1 captured handle used from another thread | valid | r:5579 limits "not captured" to lookups on another thread and says a captured handle records from any thread, with three quotations. |
| 1, 2, sources | 35 | T3 scope filter is a substring test | valid | r:5744 and r:5799 describe a textual ` name:` match on the formatted line, not span membership, with the macro and filter quotations; real line 47 (and 26). |
| 1, 2, sources | 36 | T5 reverse propagation change; unconditional format failure | valid (both parts) | r:5914 gains the double capture with source and issue 15064 quotations. r:5960 (and r:5936, r:6346) gain the `raiseExceptions` condition. bluetech's WONTFIX lean goes under dissent. r:5991 corrected: 15138 is a PR. |
| 1, 2, sources | 37 | T8 log attribute loss; sampling filter | valid (both parts) | r:6157 adds `LogRecordData` totals and the sampled-only filter of both span processors (the extension uses the simple one). r:6197 Unverified resolved. r:6138 read list extended. |
| 1, 2, sources | 38 | T9 cached loggers and `capture_logs` | valid in part | r:6246 attributes the caveat to the docs and states from source which loggers see capture: those holding the configured list object. Changelog entry is 22.1.0, PR 412. "Stale" is not asserted. |
| 1, 2, sources | 39 | T10 Rust client reports by default | valid | r:6298 says no option gates counting, naming the no-op conditions, with four quotations. r:6340 Unverified bullet removed. The test-API sub-part is already covered at r:6298. |
| 1, 2, sources | A3 | `metrics` crash at 0.24.6 | valid, no change | Already Unverified at r:1237 and "read from source, not run" at r:962. No edit. |
| 1, 2, sources | E3 | No primary explanation of synchronous dispatch | valid in part (not "maintainer discussion") | E3: "No stated rationale found" stands; the Discourse thread is added as a place looked, as of 2026-11-24. |
| 1, 2, sources | S4 | Why Java narrowed `fork` | valid, no defect | Already recorded as no stated rationale; optional edit records JEP 505's Alternatives read in full and the JBS 403. |
| 1, 2, sources | S6 | Why Swift never implemented the rule | valid in part | No design reason found; add the co-author's PR #2537 comment and the LSG revision post, quoted separately; narrow the Unverified line. |
| 1, 2, reasoning | 1 | "By convention" applied unevenly | Valid (extended to A3) | Mark A2 and A3 install "by convention" in the table and bodies, as A1 and A4 are |
| 1, 2, reasoning | 2 | `log` fallback is "ever set", not "active" | Valid | Reword line 468; quote the macro, `has_been_set` and `set_default` |
| 1, 2, reasoning | 3 | Recursion guard misses span callbacks | Valid | Limit the guard to `get_default` callbacks; quote `do_enter` and `Dispatch::enter` |
| 1, 2, reasoning | 4 | Metrique `sink_or_discard` omitted | Valid (source is `global.rs`, not README) | Add `sink_or_discard` and its stated library rationale; keep "no rationale" for the panic only |
| 1, 2, reasoning | 5 | Logging registry is per interpreter | Valid (low) | Reword B1 and E3 "process-wide" to per interpreter; quote the C-API page |
| 1, 2, reasoning | 6 | Provider-load failure raises | Valid in part ("lazy" holds only as deferred load) | Add the env-var load path that logs and re-raises; quote `_load_provider` |
| 1, 2, reasoning | 7 | Java `get()` identity | Valid | Qualify "same instance" for the autoconfigured first `get()`; quote the two wrappers |
| 1, 2, reasoning | 8 | Readings and scope of E's claim | Valid | State readings (a) and (b) and the handle-lookup boundary; no reading chosen |
| 1, 2, reasoning | 9 | `RecursionError` across handlers | Valid | Name the handlers that re-raise and those that swallow, in B1 and E3; add the silent case to E3 |
| 1, 2, reasoning | 10 | Export placement inferred from a deadline | Valid | Say the simple processor exports from `OnEnd`; quote the spec's simple processor |
| 1, 2, reasoning | 11 | Log4j `null` from `initialize` | Valid | Report the `null` return in E1's text and table; no classification |
| 1, 2, reasoning | 12 | E6 "only in-memory" | Valid | Split default and multiprocess modes; quote `write_value` and `truncate` |
| 1, 2, reasoning | 13 | E8 UDP "in practice brief", Unix omitted | Valid (low) | Mark UDP duration Unverified; add Unix socket to the cell |
| 1, 2, reasoning | 14 | D2 merges join guarantees | Valid | Separate std automatic and explicit join; crossbeam read from source |
| 1, 2, reasoning | 15 | G1 failed first flush | Valid | Describe the failed-flush path that skips the rendezvous; quote `flush()?` and the branch |
| 1, 2, reasoning | 16 | G3 and G6 shutdown export | Valid | G3: batches, timeout bounds only the caller; G6: stops at the join timeout |
| 1, 2, reasoning | 17 | G5 `kill()` can fail | Valid | Describe the full-queue path; quote `kill` |
| 1, 2, reasoning | 18 | Trio "not awaited" | Valid | Replace with cancelled at exit and shielded before; quote #1521 |
| 1, 2, reasoning | 19 | Kotlin cancel versus completion | Valid in part (Kotlin; Java wording only) | Distinguish `cancel()` from `Job.cancelAndJoin()`; note Java's explicit `close()` |
| 1, 2, reasoning | 20 | T10 needs an outgoing envelope | Valid | Say reports ride only on a sent envelope; quote the test's empty send |
| 1, 2, reasoning | 21 | N3 `no_implicit_prelude` | Valid (low) | Add the attribute to the condition; quote the Reference rule |
| 1, 2, reasoning | A | S1, S4 archived sources | Invalid | All 23 quotations and the JEP phrase counts match the fetched pages |
| 1, 2, reasoning | B | A3, A4, N3 docs.rs and Reference | Invalid | All 8 quotations match the fetched pages |
| 2, 1, sources | 1 | Writer-ownership verdict leans on failure delivery | valid | Fit rewritten around the lifetime reasons. Behaviour 4 becomes "Rests on a stated why that fits this client", with an optional note in place of the wording. Pointer to the register's reporting entry added. |
| 2, 1, sources | 2 | Posture verdict covers only the serving half | valid | OpenTelemetry's qualifiers quoted exactly. Sentry and C3 narrowed, and E7 cited for declaring. Behaviour 2 becomes "Rests on no stated why", because no stated why covers establish failing loudly (C1, C3, B1 and E1 to E14 swept). "Returns nothing" is marked not examined. Proposed wording for `CONTEXT.md`. |
| 2, 1, sources | 3 | Inert verdict leaves the count uncovered | valid | Behaviour 3 becomes "Rests on no stated why", because the count has no stated why. Proposed wording for the comment before `DiscardWriteWithoutRun`. |
| 2, 1, sources | 4 | One-shot install loses its linked-copy boundary | valid | "Once per process" replaced for `log` and `metrics` in both tables, A3, claim 1 and the proposed wording. `tracing` is left, as unsourced. |
| 2, 1, sources | 5 | Scoped-override summary drops `metrics` and generalises defects | valid | Fit → A2 corrected. `LogTracer` added to the head cell. `RecoverableRecorder`'s reason quoted in A3 and placed in Fit → A3. |
| 2, 1, sources | 6 | Claim 3 credits lossy writers with the whole posture | valid | Limited to the overflow default. E13's `Fatal`/panic and E14's unexamined set-up stated. |
| 2, 1, sources | 7 | Worker fit assumes one process-wide lifecycle | valid (G2 in part) | Ownership per system set out. Queue default attributed to `dictConfig`. Restart and `Hub::current` sourced in G4 and G2. K5 marked mixed. |
| 2, 1, sources | 8 | Fake wording says real rules apply by construction | valid | Narrowed to the test-configured pipeline, in Fit and in the proposed wording. |
| 2, 1, sources | 9 | Fit missing for several comparables | valid | Fit lines added for E8, E9, E14, T1 to T5, T9 and H6. H1, H3 and H4 split, with the go-kit and `prometheus-client` quotations added to their sections. |
| 2, 1, sources | 10 | Claim 2 drops the guard and closure qualifiers | valid | Panic-only reporting, the abort and exit gap, and the narrower async statement restored, in claim 2 and in all three Fit → D lines. |
| 2, 1, sources | 11 | Proposed wording groups `prometheus-client` with a global | valid | Attributed separately, as an application-owned registry with no global (combined with 4f). |
| 2, 1, sources | 12 | Fork summary blurs when workers restart | valid | Lazy on submit (G5) versus an after-fork hook (G6). |
| 2, 1, sources | 13 | Naming summary blurs confluence and monotonicity | valid | Brought back to N1's own definition. |
| 2, 1, sources | A | python-dev message did not open | invalid | It opens, and both quotations match verbatim. |
| 2, 1, sources | B | PyPI totals not reproducible | invalid | 134 reproduces at a later serial, and N1 names its serial. |
| 2, 1, reasoning | 1 | Worker-ownership verdict rests on a separate failure policy | valid | Fit S rewritten (E3). Behaviour 4 becomes **rests on a stated why that fits**, conditional on the Derived `writer_has_stopped` and open question 26's "until decided" rule, confirming neither (E5). "Visibly" now uses Trio's system nursery (E4). |
| 2, 1, reasoning | 2 | Fit G gives repeatable per-instance workers a per-process lifetime | valid | Fit G rewritten per worker, with G1's blocking mode. `QueueListener`'s restart is added to G4 from CPython source and cited by Fit G (E6). |
| 2, 1, reasoning | 3 | K6 treats the provisional wait as settled and drops the settled queue rule | valid | K6 and behaviour 4's statement mark open question 26's settled and provisional parts (E1, E2). The drain difference goes in Fit G (E6) and behaviour 4 (E5). |
| 2, 1, reasoning | 4 | Claim 3 gets partial credit for content it does not assert | valid | Verdict becomes **wrong under (a), Unverified under (b)**, and the lead-in admits Unverified. The E12 and E13 qualifiers are added (E14). |
| 2, 1, reasoning | 5 | Behaviour 2's first verdict overstates the OpenTelemetry rationale | valid | Verdict becomes **rests on no stated why**. Every part is covered (unconditional by Sentry's aim) except a write returning nothing, for which no stated why is found in the file. Fit C1 and Fit E corrected. Neutral proposed wording for `CONTEXT.md` (E11, E12, E15). |
| 2, 1, reasoning | 6 | Behaviour 3's first verdict covers only discarding | valid | Verdict becomes **rests on no stated why**. Counting has no stated why in the file: the libraries that count drops do so with a backend installed and give no reason. Proposed wording for the comment before `DiscardWriteWithoutRun` (E13). |
| 2, 1, reasoning | 7 | "Once per process" loses `log`'s per-linked-copy qualification; Fit A2 contradicts claim 1 | valid | Qualification added in the tables, claim 1 and behaviour 1's wording. A2's "So" names both scoped mechanisms (E7, E8, E9). |
| 2, 1, reasoning | 8 | Fit A1 and A2 attribute `log`'s and `tracing`'s hazards to the client | valid | A1 now says the spec does not say how a core is reached or released. A2 keeps only the per-thread limit (E7). |
| 2, 1, reasoning | 9 | No fit for E8, E9 and E14 | valid | A fit line for each, from its own section (E15). |
| 2, 1, reasoning | 10 | Fit H merges distinct reasons and treats K7's silence as a mismatch | valid | Per-system lines for H1 to H7. K7 becomes "not established" in A1 and A3 (E7, E16). |
| 2, 1, reasoning | 11 | The Python logging analogy drops ownership and disabling qualifications | valid | Fit B1 notes the registry is not application-created and gives the full disabling rule. Behaviour 1's wording is qualified (E9, E10). |
| 2, 1, reasoning | 12 | `Drop` "cannot report" and closures "guarantee" overstated | valid | "Report" becomes "return", with the API Guidelines' "ignore or log/trace" quoted. The closure's end is limited to return or unwind (E17). |
| 2, 1, reasoning | 13 | "The real rules apply by construction" overstated | valid | Fit T and behaviour 5's wording say the test-configured pipeline applies, citing T7, T8 and T10 (E18). |
| 2, 1, reasoning | 14 | Shared-handle bullet leans on scope guards | valid | T1's `Send + Sync` handle added. The guards are relabelled as bearing on who ends a scope (E19). |
| 2, 1, reasoning | S1 | `ddtrace` "often" in forked servers | valid | Prevalence replaced by what G7's sources show (E20). |
| 2, 1, reasoning | S2 | Original D1, S1 and N1 pages did not load | invalid (no defect) | The file already records each one, and nothing depends on them. |
| 2, 2, sources | 1 | Behaviour 3: post-shutdown count and reasons for counting | Valid | G6, E10 and C1 get the OpenTelemetry Python count, PR #5509, the blueprint, Sentry's client reports and the no-op's "disable" reason. Behaviour 3 goes through the four inert cases and stays third on a corrected basis, with a question for the maintainer. |
| 2, 2, sources | 2 | Behaviour 2 misses Sentry Rust's panic-at-initialisation reason | Valid | The changelog and PR #773 go in E11. Behaviour 2, its wording and Fit E say the reason informs establish failing loudly. The verdict is unchanged. |
| 2, 2, sources | 3 | Shutdown bounds overstated | Valid | Behaviour 4 and Fit G say each library attempts a drain, waits up to a bound, and `sentry` then joins with no bound. |
| 2, 2, sources | 4 | Behaviour 4 and the one data writer | Valid in part | The verdict stays first. A sentence says `OneDataWriter`'s exclusivity is not judged here, being the DuckDB leaning, ticket 17 and open question 1. |
| 2, 2, sources | 5 | Claim 1 erases `RecoverableRecorder`'s lifetime | Valid | Claim 1 and Fit A2 name it. Fit A3 and A3 add the last-active-reference rule, with its source. |
| 2, 2, sources | 6 | Behaviour 2 wording conflates OpenTelemetry guarantees; Sentry "never fails" | Valid | The wording separates the error handler from "by default" blocking. The "never fail" line is narrowed, with Sentry's panics. |
| 2, 2, sources | 7 | Fit G claims all of K2 from full-queue drops | Valid | "Holds in part, for a full queue". G4's unbounded queue and `put_nowait` under the handler lock are named. |
| 2, 2, sources | 8 | Claim 3 generalises async-appender defaults | Valid | Both lines say "asynchronous appenders". |
| 2, 2, sources | 9 | Opening a handle called a lookup | Valid | Reworded: a step of that kind, though `OpenClientHandle` creates a handle. |
| 2, 2, sources | 10 | Thread-local limit understated | Valid | Fit A2: no other thread sees it, even one the test spawns. |
| 2, 2, sources | 11 | Python `__exit__` lacks the exit qualification | Valid | D4 adds `os._exit()` with its pinned docs. Claim 2 and Fit D say "Inferred not to run" on it. |
| 2, 2, sources | 12 | zap and go-kit misstated | Valid in part | H2's line names a `SetLogger` method and `ReplaceGlobals`. H4 adds "attractive", and the cost line names slog and zap only. |
| 2, 2, sources | 13 | Swift failure policy generalised | Valid | Fit S names SE-0381's rethrow and its reason beside Smith's. |
| 2, 2, sources | 14 | Metric-reader capture omitted | Valid | Fit T and behaviour 5's wording add "the metric reader". |
| 2, 2, sources | 15 | Java global summaries omit autoconfigure and `resetForTest()` | Valid | Fit C3 and the nesting entry are qualified. |
| 2, 2, sources | 16 | C1 metrics no-op unlinked | Valid | A `Source:` line and blockquote are added to C1. |
| 2, 2, sources | S | KAFKA-3539 Ninos quotation unverified | Invalid | Jira's REST API shows comment `16798792` with the quotation verbatim. |
| 2, 2, reasoning | 1 | Cadence's reason for a send that returns nothing overlooked | valid | Owner's reason added to E9 (X1); it informs a write that returns nothing, limited by K1 and by `try_send` beside it (F10, BH2c, BH2d). Behaviour 2 stays **no stated why**: establish failing loudly is still uncovered. |
| 2, 2, reasoning | 2 | Early detection read as a reason for the error channel | valid | Fit E now says what `client_golang`'s reason is for and makes the link to failing loudly the file's own, labelled argument; both start-up reasons are limited to the usual case; K4's heading no longer implies a timing rule (X5, F1, F8, BH2b, BH2d). Behaviour 2's verdict is unchanged. |
| 2, 2, reasoning | 3 | Serving-path evidence overstated in behaviour 2 | valid | `performance.md`'s own reason for not blocking added to C1 (X3, F6); the handler exception moved to the error-handling principles; "never fail" narrowed to "no error path" (BH2a, BH2c, BH2d). |
| 2, 2, reasoning | 4 | Sentry's reason for counting overlooked; where counting happens misstated | valid | Client-reports reason added to E10 (X2), with OpenTelemetry's request to make loss visible added to C1 (X3); counting places corrected; both reasons inform and do not cover counting with no backend in force (BH3a, BH3c). Behaviour 3 stays **no stated why**. |
| 2, 2, reasoning | 5 | Both shutdown guarantees overstated | valid | "Drain within a bound" becomes "attempt to drain", with each limit stated (F13, BH4b). |
| 2, 2, reasoning | 6 | Full-queue handling generalised to all of K2; hub identity overstated | valid | G4's unbounded default and caller-side work excluded from K2 (F12); `Hub::run` added to G2 and Fit G (X7, F11). |
| 2, 2, reasoning | 7 | Global slot's lifetime conflated with the recorder's | valid | Last-reference quotation added to A3 (X6); "only mechanisms with a duration" narrowed to overrides in Fit A2, Fit A3, claim 1 and behaviour 1's wording (F4, F5, CL1, BH1a). |
| 2, 2, reasoning | 8 | Thread-pool constraint assumed under K1; spawned-thread limit understated | valid | Tokio's reason informs, its constraint unrecorded in K1 to K7 (F2); the limit covers threads spawned inside the scope (F3). |
| 2, 2, reasoning | 9 | Metrique's and Micrometer's reasons unweighed | valid | Metrique weighed in Fit A3 (F5); Micrometer's two reasons weighed in Fit E, with the third-party sentence added to E5 (X4, F9). |
| 2, 2, reasoning | 10 | Scope exit summarised too broadly | valid | "The join" limited to thread scopes (CL2); Python's `os._exit` limit added to D4, Fit D and claim 2 (X8, F7, CL3); behaviour 4 keeps S7's limit (BH4a). |
| 2, 2, reasoning | 11 | go-kit given a cost it avoids | valid | H4 removed from the per-call cost, with its package-scoped option (F14). |
| 2, 2, reasoning | 12 | CPython logging's conditions flattened | valid | Disabling rule given in full in behaviour 1's wording (BH1b); `lastResort` tied to a record with no handler (BH3b, BH3c). |
| 2, 2, reasoning | 13 | Metrics capture point misidentified | valid | Fit T and behaviour 5 name the metric reader (Python, Java) and exporter (Rust) (F15, BH5). |
| 2, 2, reasoning | S | JEP 543 wording and status unconfirmed | invalid (no defect) | The page loads (HTTP 200); status, release and "Updated" stamp match S4, and all ten S4 quotations match. |

### Open points

- **A question for the maintainer, from behaviour 3:** is a host that never establishes, or a forked child's copy, one that has turned the client off, or one whose writes were meant to be recorded? The answer decides which comparable's reason bears on counting in those two cases. The research file records the question and does not answer it.
- **The verdict rule is the author's.** The ticket gives the three verdicts. How they are applied is this file's rule ("Verdicts on the stated behaviours"): the record's reason is taken first, and another comparable's stated why gives the first verdict only if it fits the whole behaviour. Behaviours 2 and 3 get the third verdict because of it, and one triager applied it to give behaviour 4 the first. The maintainer may read the ticket's verdicts otherwise.
- **After the review, Fit gained a line for S3.** Before, S3 was named only within ranges. The line reports S3's stated reason and says it informs; no reviewer saw it.
- **The last round was not reviewed after it was applied.** The second key moment's second round was the last allowed. Its fixes passed the quotation and structure checks and were read by the author, but no reviewer saw them.
- **Unverified items** stay marked "Unverified" in the research file, each with where was looked. Examples are the formal roles of several speakers, and whether `metrics`' out-of-order guard drop crashes at 0.24.6.
- **Kept as it is:** the `tracing` cell in the head table still says "once per process". The file has no source on per-copy globals for `tracing`.
- **Read dates.** The sources were read on 2026-11-25 (UTC), which was 2026-11-24 in the maintainer's local time. The research subagents' briefs called the local date UTC. The file's head states the true times, and the sections give the local date.

### Gates and files

- **Baseline**, at `90f0abb`. The first run failed only because the author had written its log to the worktree root. The run with the log outside the worktree ended:

  > All checks passed and the worktree is unchanged.

- **After the draft**, at `7ccfb0b`, the same.
- **`just check-docs`** passed after every round.
- **`/code-review`** (low, on `main...HEAD`) reported nothing: the diff holds only Markdown, with no code for it to check.
- **Final**, at FINAL_COMMIT, the research file and this hand-back as reviewed and fixed. The commit that records this line changes only the line itself.

  > FINAL_LINE

- **Changed files:** `git diff main...HEAD --stat`, against the merge base `90f0abb`, shows only this ticket and its research file. `main` has since moved on (pull request #7, which closed tickets 01 and 02 and narrowed ticket 11); this branch does not touch those files. The specification is unchanged, and open question 18 is still in it. No code was added.

### Acceptance

- [x] Each claim checked from a primary source, with a link and date, or marked "Unverified" with where was looked; claims found wrong are reported as wrong.
- [x] The facade claim checked part by part for `log`, `tracing` and `metrics`, with where it holds.
- [x] Both halves of the posture claim checked, each against at least three libraries (fourteen in E).
- [x] Every "Citing a comparable" field for each system, with fit in its own section.
- [x] Comparables that chose otherwise, with their why (H1 to H4, and the contrasts H5 to H7).
- [x] One verdict for each stated behaviour.
- [x] Proposed wording where a verdict is not the first; the specification is not edited.
- [x] What the three names already mean, with no name recommended; open question 18 is still open.
- [x] This hand-back, summarising the findings and pointing to the research file, committed with it.
- [x] The adversarial review at both key moments, with reviewers that opened the sources; every finding listed above with its verdict, resolution and reviewing model.
- [x] No tracked file other than this ticket and its research file changed, and no code added.
