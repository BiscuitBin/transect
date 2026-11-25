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

- [ ] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] The file says, with a count of the libraries read, whether the onset-then-total rule is common practice or one library's
- [ ] For each of the two stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [ ] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [ ] The file says what the evidence bears on open question 22 and recommends no answer; the question is still open in the specification, and the register's entry is untouched
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
