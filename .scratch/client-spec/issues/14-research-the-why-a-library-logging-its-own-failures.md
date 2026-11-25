# 14: Research the why: a library logging its own failures

**What to build:** The maintainer can see why libraries log their own failures into a host's logs the way they do, and whether the rule the specification proposes is in fact the common one. During the elicitation these libraries were surveyed for what they do. Why they do it was not captured, and no link was kept. This ticket checks the what again, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

What the specification proposes today, and what it was said to rest on:

- **The standard facade.** Records go through the language's standard logging facade, under the client's own logger name. The client installs no handlers. Records are structured, and lost data is logged at WARNING. The survey reported this as common practice.
- **Onset, then a total.** The first occurrence of a kind of failure for a table is logged at once. Nothing more is logged for that kind and table until it stops or establish ends, when one record gives the total. The maintainer chose this from the survey's options, where it was described as what the OTel Rust SDK does.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- Common practice is the standard logging facade, a library-named logger, no handlers installed, WARNING for dropped data, a stable name per kind of event, and the first occurrence logged at once, then throttled.
- ddtrace: one record per call site per 60 s, with "[N skipped]".
- OTel Java: 5 per minute, then 1.
- OTel Python: identical repeats suppressed within 20 s.
- Linux kernel: 10 per 5 s, then "N callbacks suppressed".
- OTel Rust: the onset once, and a total at shutdown.
- Separate periodic summary logs are uncommon.

The maintainer's note from the elicitation, verbatim:

> Also generally speaking we should log to the hosts logs (structured), but we need to make sure that it is not too noisy, And that once we've logged about one kind of failure, we don't log about it for a while or something. Maybe more of a summary kind of situation. Though, the moment some sort of failure starts to happen, we should probably log as it's more likely to go through, versus if we hold off, it may be the case that it's less likely to go through. But I'm also interested in knowing what other systems do. With this, we should generally follow best practice and do what most other frameworks and libraries do. We shouldn't be novel here (Specifically referring to logging to the host logs).

What the research must find out, beyond the fields every comparable gets:

- **No handlers, a named logger.** Why a library leaves handlers to the application, in Python and in Rust. A lead from the agent's own knowledge, not checked: the Python logging documentation has guidance written for libraries. Start there, and find the equivalent for the Rust logging facades.
- **WARNING for lost data.** Whether any of these libraries says why it chose that level.
- **Each throttle rule.** Why each library throttles as it does: what it was protecting, and what was reported against it. Give each rule's numbers from source at a named version.
- **Is the chosen rule common?** The maintainer asked not to be novel here. Say plainly whether "the onset once, then a total at the end" is what most of these libraries do, or what one of them does. If it is one library's rule, that is a finding to report, not to soften.
- **What the rule costs.** What an operator cannot see between the onset and the total in a process that lives for days, and what is lost when a pod is killed before the total is written. The maintainer's own note weighs logging at the onset because it is "more likely to go through".
- **A comparable that chose otherwise**, with its why: for example a library that logs a periodic summary, or one that logs every occurrence.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related open question, by number and gist. Say what the evidence bears on it. Do not resolve it and do not recommend an answer:

- 22: when a kind of failure for a table counts as stopped, so that its total is logged before establish ends, and whether unattributed rows and the confluence-wide discards are logged.

The open-decisions register's Product entry on how the client reports its own failures to the host application is the maintainer's to close with a decision record. This ticket does not touch it.

**Ticket 16's findings:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md` bears on this ticket. "What the findings bear on" records, for the register's entry on how the client reports its own failures, that the facades leave it to the backend (A1 to A3), that OpenTelemetry says a suppressed error SHOULD be logged (C1), and that Python's `logging` uses `lastResort` and `raiseExceptions` (B1). B1 also records CPython's stated reason for swallowing handler errors, and stated behaviour 3 the comparables that count what they drop. Read it before starting. Its fits and verdicts are findings, not decisions: the maintainer has said they are not guaranteed to be applied, and they stay open for the tickets they bear on.

**Research file:** `.scratch/client-spec/research/14-a-library-logging-its-own-failures.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Is each throttle rule, with its numbers, shown from documentation or from source at a named version?
2. Is the chosen rule shown to be common, or is one library's practice presented as what most do?
3. Are the costs faced: what goes unseen between the onset and the total, and what a killed pod never logs?
4. Does the file recommend or imply an answer to open question 22, or to the register's entry on reporting failures?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] The file says, with a count of the libraries read, whether the onset-then-total rule is common practice or one library's
- [x] For each of the two stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [x] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [x] The file says what the evidence bears on open question 22 and recommends no answer; the question is still open in the specification, and the register's entry is untouched
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/14-a-library-logging-its-own-failures.md`, beside the issues folder. This section summarises it. Open question 22 is still open, and the open-decisions register's entry on how the client reports its own failures is untouched: nothing here decides either.

### Findings

Twelve libraries were fixed as the count before any source was read, and each was read at its latest release tag:

- ddtrace;
- the OpenTelemetry SDKs for Java, Python, Rust, Go, .NET and JS;
- the Linux kernel's `printk` rate limiting;
- sentry-python;
- urllib3;
- the OpenTelemetry Collector;
- Vector.

Nine of them are in-process libraries, as this client is. The Python logging documentation, the Rust `log` and `tracing` crates and the OpenTelemetry specification were read as guidance, not counted. Eight more were read after the count was fixed, and are reported apart: dd-trace-go, log4j2, Logback, Elastic APM Python, libhoney-go, librdkafka, Fluent Bit and CPython's `QueueHandler`.

Every quotation was checked by machine against the author's own re-fetch of its source: 230 block quotations, five of them matching only with line breaks collapsed, and 62 inline fragments.

- **The claims from the elicitation, checked again.** Each has a status in the file.
  - **Confirmed:** a library-named logger, the kernel's 10 per 5 s, and ddtrace's 60 s per call site (with two corrections).
  - **Confirmed for part of their scope:**
    - OTel Java's 5 per minute then 1, for `ThrottlingLogger`, which does not cover the batch processors;
    - OTel Rust's onset then a total at shutdown, for queue-full drops only;
    - separate periodic summaries being uncommon, which is confirmed with a qualification.
  - **Corrected:**
    - no handlers installed: ddtrace and sentry-python add one, and OTel Go writes to standard error;
    - a stable name per kind of event: only OTel Rust and OTel .NET have one;
    - OTel Python's 20 s: a fixed bucket remembering only the last record, with the queue-full warning now logged on every drop.
  - **Corrected in part:** the standard facade, WARNING for dropped data, and the first occurrence logged at once, then throttled.
  - **Confirmed in part:** records are structured, in OTel Rust, OTel Go, OTel .NET, the Collector and Vector; the Python libraries and OTel Java format a text message.
- **Is the rule common? It is one library's rule.**
  - Of the twelve, one, OTel Rust, logs the first occurrence at once, nothing more while it continues, and one total at the end. It does so in its default processors, and only for a full queue.
  - None of the twelve applies it to a failed store or export.
  - Two more have two of its three parts: OTel .NET, a total at shutdown with no onset, and OTel JS, an onset at Debug with a total when drops stop.
  - No rule is used by a majority.
- **What the rule costs.**
  - Between the onset and the total, the log cannot tell an operator whether a failure continues, stopped, or came back. One read of the diagnostics snapshot cannot tell that either.
  - A pod killed by SIGKILL never writes a pending total. That covers the end of the grace period, a hard eviction about 2 s after the stop signal, and an OOM kill of the host's process. An unhandled stop signal usually means the same.
  - The onset is emitted when the failure starts. Whether it reaches a sink depends on the host's logging.
- **`StandardFacade`: a stated why that fits this client.** The Python HOWTO and the Rust crates give reasons that hold for an in-process library. The basis as written ("common practice") is wrong in part, and the file gives replacement text for the maintainer to place.
- **`StandardFacade`'s clause on dropped tenants, judged on its own: no stated why.** No source read gives a reason for logging a dropped tenant at WARNING. The maintainer asked for this split after the reviews.
- **`OnsetThenTotal`: no stated why, as the specification applies it.**
  - No source gives a reason for holding the total until the end, nor for applying the rule to all six kinds.
  - Stated whys that fit support the onset (OTel JS's author) and, for a full queue, counting instead of logging each drop (OTel Rust, OTel .NET).
  - The file gives proposed wording, beginning "Informs, and does not justify". It changes only the stated basis.
- **What it bears on in open question 22,** reported without a recommendation:
  - Of the comparables, two test that a failure stopped (OTel JS, the Collector's memory limiter). The others report at a boundary that does not.
  - Under the rules as written, a later occurrence opens no new onset.
  - The nearest analogue for the confluence-wide discards is data offered after shutdown. OTel Rust logs it at WARN each time, OTel Python makes an INFO call each time, and OTel Java logs nothing.
- **The specification's wording.** `StandardFacade` now covers dropped tenants, added when A2 was adopted after ticket 02. The ticket quotes the older wording. Nothing was edited.

### Adversarial review

Every review ran on Codex, codex-cli 0.172.0, with `gpt-6.2-sol`. That was the user's choice for this ticket, over the preference in `REVIEW.md` for `gpt-6-astra`.

- Each session header recorded the model.
- Every reviewer had live web search under this ticket's authorisation, and a read-only sandbox.
- Before the first review, a preflight confirmed that Codex ran `gpt-6.2-sol` and could open a URL.
- Each key moment ran two rounds, with two reviewers per round, one per lens.
- Every finding was triaged, independently, by two fresh Claude Code subagents on Claude Opus 5.5 (`claude-opus-5-5`). Neither was the author or a reviewer.
- The two judges never split a finding between valid and invalid. Six times one judged a finding valid and the other valid only in part, or with a sub-point invalid. The table records the narrower verdict each time.

The reviews, triage files and prompts are under `ai_tmp/client-spec-review/14/`, which is not committed.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | OTel Rust takes the total when shutdown begins; the async processors count any failed send | Valid | L5 and its row: snapshot at shutdown entry, written even if shutdown fails; the experimental processors recorded |
| 1, 1, sources | 2 | "At once" mixed a logging call with what a host sees; urllib3 never throttles | Valid | "At once" redefined; the OTel Rust and urllib3 cells qualified; the claim row rewritten |
| 1, 1, sources | 3 | ddtrace has two keys, and DEBUG turns the limit off | Valid | L1 rewritten, with PR #12928's stated motive |
| 1, 1, sources | 4 | Java's 5 is a token bucket, not a per-minute ceiling | Valid | L2 and the claim row describe the bucket |
| 1, 1, sources | 5 | Sentry has three report triggers; the logging-bill reason is about the debug gate | Valid, in part | L9 triggers corrected; the reason attached to the debug gate only |
| 1, 1, sources | 6 | Vector's 2 s tick is not its log cadence; buffers block by default | Valid | L12 and its row split the buffer path from the limiter; the default-on reason added |
| 1, 1, sources | 7 | The JS entry quoted a description as its reason | Valid | The author's stated reasons quoted |
| 1, 1, sources | 8 | The pod paragraph made SIGTERM the only route | Valid | preStop and STOPSIGNAL added; the inference reworded |
| 1, 1, sources | 9 | dd-trace-go's aggregate is timed from the first error and caps at 200 | Valid | A1 retitled and rewritten |
| 1, 1, sources | 10 | log4j2 warns once per policy instance | Valid | A2 rewritten: opt-in, per instance, TRACE total, hidden by default |
| 1, 1, sources | 11 | OTel Go also logs structured fields | Valid | Added to the structured-records row |
| 1, 1, sources | 12 | Fluent Bit also logs an error; CPython's traceback is conditional | Valid | A3 qualified |
| 1, 1, sources | Suspicion | Ten review comments could not be opened | Invalid | Each fetched through the API: verbatim, roles as stated |
| 1, 1, reasoning | 1 | As sources 2 | Valid | As sources 2 |
| 1, 1, reasoning | 2 | As sources 1; the comparison with `LogTotal` | Valid, in part | As sources 1; the comparison deferred to fit |
| 1, 1, reasoning | 3 | Vector row combined two paths; the count's condition | Valid, in part | As sources 6; the condition the reviewer gave was refuted by source, and the right one stated |
| 1, 1, reasoning | 4 | As sources 4 | Valid | As sources 4 |
| 1, 1, reasoning | 5 | Go writes a running span count at shutdown | Valid | L6 corrected |
| 1, 1, reasoning | 6 | "Periodic summaries uncommon" was ruled on without evidence of prevalence | Valid | Recorded by trigger; final status given under "Is the rule common?" |
| 1, 1, reasoning | 7 | As sources 7, and the spec asks for no count | Valid | As sources 7 |
| 1, 1, reasoning | 8 | As sources 5 | Valid | As sources 5 |
| 1, 1, reasoning | 9 | log4j2 also writes a TRACE total at shutdown | Valid | As sources 10 |
| 1, 1, reasoning | 10 | As sources 8 | Valid | As sources 8 |
| 1, 1, reasoning | Suspicion | Whether #2357 gave a reason for the onset | Invalid | The thread read in full: no reason given |
| 1, 2, sources | 1 | Sentry's flush is best effort | Valid | L9 and its cell qualified |
| 1, 2, sources | 2 | Vector's limiter covers the console, not `internal_logs`, and counts records | Valid | L12 qualified |
| 1, 2, sources | 3 | A container's process 1 does not get an unhandled TERM; preStop gets 2 s more | Valid | Pod facts rewritten, with pid_namespaces(7) |
| 1, 2, sources | 4 | OTel Go returns some export failures to the caller | Valid | L6 and its row corrected |
| 1, 2, sources | 5 | OTel Rust does not log every other failure | Valid | L5 and its row: flush timeout unlogged, timed-out shutdown losses uncounted |
| 1, 2, sources | 6 | zap's hashed counters can hide a first occurrence | Valid | L11 and its "At once" cell qualified |
| 1, 2, sources | 7 | The kernel comment is on the shared limiter | Valid | Reason attached correctly; the header's reason for per-call-site state added |
| 1, 2, sources | 8 | ddtrace's per-message interval applies to every record | Valid, low | Applied in one sentence |
| 1, 2, sources | 9 | `startNodeSDK()` is a deprecated alias | Valid, low | Applied in one sentence |
| 1, 2, sources | Suspicion 1 | The dd-trace-go comments | Invalid | Verified through the API |
| 1, 2, sources | Suspicion 2 | The LOG4J2-1080 exchange | Invalid | Verified through Jira's REST API; one precision applied |
| 1, 2, reasoning | 1 | A hard eviction leaves about 2 s | Valid | Kubelet and containerd source added |
| 1, 2, reasoning | 2 | The Rust cell lost the shutdown-entry snapshot | Valid | Cell narrowed |
| 1, 2, reasoning | 3 | One OTel Python processor's warning can hide another's first | Valid | L3, its cell and the claim row qualified |
| 1, 2, reasoning | 4 | The export-cycle rows omit worker triggers | Valid | Java defaults and Go's wake path added |
| 1, 2, reasoning | 5 | As sources 1 | Valid | As sources 1 |
| 1, 2, reasoning | 6 | As sources 6 | Valid | As sources 6 |
| 1, 2, reasoning | 7 | Go's `Warn` is `logr` V(1) Info | Valid | L6 and its cells |
| 1, 2, reasoning | 8 | Vector's records carry no event name | Valid | Stable-name count now two of twelve |
| 1, 2, reasoning | Suspicion | The Collector's documented start and stop events | Valid, in part | Found only in the memory limiter at the tag; the exporter queue logs each rejection |
| 2, 1, sources | 1 | The wording overstated how SDKs report failed exports | Valid | Four places rewritten, scoped to the twelve |
| 2, 1, sources | 2 | Vector's "1 per 10 s" changed meaning | Valid, low | Cell qualified |
| 2, 1, sources | 3 | "First occurrence, then throttled" is not shared by most | Valid | Recounted: six of twelve, three of nine in-process |
| 2, 1, sources | 4 | A tie between two uncommon practices is not a correction | Valid | Status changed to "Confirmed, with a qualification" |
| 2, 1, sources | 5 | One snapshot read cannot show recovery or recurrence | Valid | Costs rewritten: the cost reaches a reader of one snapshot too |
| 2, 1, sources | 6 | An onset was treated as a delivered record | Valid | Costs and verdict reworded: emitted, not delivered |
| 2, 1, sources | 7 | More rationale was attributed than stated | Valid | "Show warning log" removed as a reason; no stated why for the total's timing |
| 2, 1, sources | 8 | The basis conflated the maintainer's guidance with the rule's provenance | Valid | Both records quoted; a question for the maintainer |
| 2, 1, sources | 9 | Reporting boundaries were treated as tests of recovery | Valid | Question 22's first half rewritten: two test, the rest are boundaries |
| 2, 1, sources | 10 | Python's post-shutdown INFO is filtered | Valid, low | Qualified |
| 2, 1, sources | Suspicion 1 | The dd-trace-go comments | Invalid | Verified through the API |
| 2, 1, sources | Suspicion 2 | Other anchored threads | Invalid | Each verified through the API |
| 2, 1, reasoning | 1 | As sources 5 | Valid | As sources 5 |
| 2, 1, reasoning | 2 | The verdict conflated a reason not to log each drop with a reason to defer the total | Valid, one sub-point invalid | The total's timing rests on no stated why; the fit gains a fourth misfit. Rust's off-by-default metric does not change the fit |
| 2, 1, reasoning | 3 | As sources 3 | Valid | As sources 3 |
| 2, 1, reasoning | 4 | As sources 4 | Valid | As sources 4 |
| 2, 1, reasoning | 5 | As sources 6 | Valid | As sources 6 |
| 2, 1, reasoning | 6 | `StandardFacade` support is stronger for application-owned logging | Valid, one sub-point invalid | WARNING basis narrowed; dropped tenants raised as a third point for the maintainer; "most follow it" counted. urllib3's `NullHandler` does follow the HOWTO |
| 2, 1, reasoning | 7 | As sources 9 | Valid | As sources 9 |
| 2, 1, reasoning | 8 | As sources 1 | Valid | As sources 1 |
| 2, 1, reasoning | 9 | Vector and Python qualifications lost in summaries | Valid, low | As sources 2 and 10 |
| 2, 1, reasoning | 10 | JS's onset use needs an export interval | JS half valid, low; Java half invalid | L8 fit narrowed; Java's fit already conditional |
| 2, 1, reasoning | Closing | "Two channels. Settled" should say "in the proposal" | Valid, low | Reworded, noting the register's entry stays open |
| 2, 1, reasoning | Suspicion | "Common practice" as the basis cannot be confirmed | Valid | As sources 8 |
| 2, 2, sources | 1 | The `StandardFacade` verdict covered the dropped-tenant clause, which has no stated why; "follow all of it" counted only three properties | Valid | The verdict names the exception; the counts are labelled by test; the proposed basis covers the clause without changing the level |
| 2, 2, sources | 2 | The `OnsetThenTotal` verdict ran together the reason to count and a reason to wait | Valid | Label changed to "no stated why", with a grid of part against kind; the onset's stated purpose recorded |
| 2, 2, sources | 3 | ddtrace's first full-buffer warning can be hidden by another warning in the same bucket | Valid | L1 cell, claim row and tally qualified |
| 2, 2, sources | 4 | The tallies used different events and visibility tests | Valid | Each count labelled by its test; call-alone counts added; Vector's placement stated |
| 2, 2, sources | 5 | The signal path and the .NET outcome were too absolute | Valid | "Main process", the shared PID namespace, and the .NET timing qualified |
| 2, 2, sources | 6 | The snapshot is the latest run's | Valid | Run boundary stated, cited as Derived; comparison of reads needs the same `run.id` |
| 2, 2, sources | 7 | Vector's notice takes the original event's level | Valid, low | Added to L12 |
| 2, 2, sources | 8 | `tracing`'s `log` feature forwards to `log` | Valid | G2, the G2 fit, L5 and two cells corrected |
| 2, 2, sources | 9 | The Collector's recovery log is not emitted on every transition; Rust also writes an onset | Valid | L11 and question 22's first half corrected |
| 2, 2, sources | 10 | Two attributions to `CONTEXT.md` and the survey were collapsed | Valid, low | Each attributed to its own record |
| 2, 2, sources | 11 | OTel JS also chose logs to avoid changing its API, and Debug to be filterable | Valid, low | Both reasons quoted |
| 2, 2, sources | Suspicion 1 | The dd-trace-go comments | Invalid | Verified through the API |
| 2, 2, sources | Suspicion 2 | Author associations | Invalid | All checked through the API; none differs |
| 2, 2, reasoning | 1 | As sources 2, and Rust's metric is off by default | Valid | As sources 2; the fit records the off-by-default metric |
| 2, 2, reasoning | 2 | As sources 1 | Valid | As sources 1 |
| 2, 2, reasoning | 3 | As sources 4 | Valid | As sources 4 |
| 2, 2, reasoning | 4 | As sources 3; the skipped count can mix warnings | Valid | As sources 3; the mixing added to L1's inference |
| 2, 2, reasoning | 5 | As sources 10 | Valid, low | As sources 10 |
| 2, 2, reasoning | 6 | The .NET total also counts enqueues that give up under contention | Valid, low | L7 corrected, with source |
| 2, 2, reasoning | 7 | OTel JS returns flush and shutdown failures to the caller | Valid, low | L8, its cell and the verdict corrected |
| 2, 2, reasoning | 8 | Vector's buffer count is triggered by a timer, not the next record | Valid, low | Costs and question 22 add the timer |
| 2, 2, reasoning | 9 | As sources 8 | Valid, low | As sources 8 |
| 2, 2, reasoning | 10 | As sources 5; a child process may not receive the signal | Valid, low | As sources 5; the child case added as Inferred |
| 2, 2, reasoning | 11 | As sources 9 | Valid, low | As sources 9 |

**The final consistency pass.** The `code-review` skill ran at a low level on `main...HEAD` before this hand-back. It returned no findings and reported that the branch holds one Markdown file and no code, so it did not compare the file with the ticket. The author then made that comparison against each acceptance box; see "Acceptance" below.

### Open points, and the maintainer's answers

The maintainer answered these on 2026-11-24, after the reviews. Each answer is quoted as the option they chose, with any note they added. None is decided by this ticket.

1. **On what basis was onset-then-total chosen?** `CONTEXT.md` records the survey's general practice and the maintainer's choice separately, and no record linked them.
   - **Answer:** "OTel Rust's rule, adopted". The option read: "Chosen knowingly as OTel Rust's queue-full rule, then extended to all six failure kinds. The basis would name that library instead of saying 'common practice'."
2. **Which Rust facade does "the language's standard logging facade" mean?** `log` and `tracing` are both de facto facades, and neither is standard.
   - **Answer:** "Leave it open".
3. **Does a `NullHandler` count as installing a handler?** The Python HOWTO allows one, and regards printing WARNING to standard error when nothing is configured as "the best default behaviour".
   - **Answer:** "Leave it open".
4. **What is the basis for WARNING on a dropped tenant?** No source read gives one.
   - **Answer:** "Reconsider the level", with the note "Leave as an open question.."
5. **Does a verdict that excepts one clause meet the "one verdict" box for `StandardFacade`?**
   - **Answer:** "Split into two verdicts". The research file now gives `StandardFacade` a stated why that fits, and its clause on dropped tenants no stated why. The split moved text and changed no finding. It was not reviewed, and both quotation checks still pass.
6. **Neither proposed wording is placed anywhere tracked.** This ticket edits neither `CONTEXT.md` nor the specification.
   - **Answer:** record the answers here, and carry the questions and the basis wording into the specification through a new ticket. That is `18-carry-ticket-14s-answers-into-the-specification.md`, added on this branch at the maintainer's request.
7. **The second key moment's second-round fixes were not reviewed again.** Two rounds is the limit. They passed both quotation checks.
   - **Answer:** "No, accept as is".

### Gates and files

- **Baseline**, at `90f0abb`, on the untouched worktree:

  > All checks passed and the worktree is unchanged.

- **Final**, at `b55f816`, the research file and this hand-back with the maintainer's answers recorded:

  > All checks passed and the worktree is unchanged.

- **Changed files:** `git diff main...HEAD --stat`, against the merge base `90f0abb`, shows this ticket, its research file, and ticket 18, which the maintainer asked for. `main` has moved on since this branch was cut, by pull request #7, which closed tickets 01 and 02. So a two-dot `git diff main` also shows those files' changes on `main`, which this branch did not make. The specification is unchanged, and open question 22 is still in it. `docs/project/open-decisions.md` is unchanged. No code was added.
- **`git status --short`** is empty.

### Acceptance

- [x] Each claim checked again from a primary source, with a link and the date read, under "The claims, checked again"; the claims found wrong are reported as wrong.
- [x] Every field under "Citing a comparable" for each system, L1 to L12 and G1 to G3, with fit under "Fit".
- [x] Comparables that chose otherwise, with their why, under "Comparables that chose otherwise".
- [x] The count of libraries read, and the plain answer, under "Is the rule common?": one library's rule.
- [x] One verdict for each of `StandardFacade` and `OnsetThenTotal`, under "Verdicts". At the maintainer's request, `StandardFacade`'s clause on dropped tenants has a verdict of its own (open point 5).
- [x] Proposed wording where a verdict is not the first: for `OnsetThenTotal`, and for `StandardFacade`'s clause on dropped tenants. The specification is not edited.
- [x] What the evidence bears on open question 22, with no recommendation; the question is still open, and the register's entry is untouched.
- [x] This hand-back, pointing to the research file, both committed.
- [x] The adversarial review at both key moments, with reviewers that opened the sources; every finding is listed above with its verdict, its resolution and the reviewing model.
- [x] No tracked file other than this ticket and its research file changed against the merge base, and no code added, apart from ticket 18, a new file the maintainer asked for on this branch (open point 6).
