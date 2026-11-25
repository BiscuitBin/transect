# 01: Research: who stamps a row's time

**What to build:** The maintainer can decide open question 11 of the proposed client specification from evidence instead of from instinct. The question reads: "Is a row's time stamped by the client only, or may application code supply it, and what are its name and precision? Until decided, the client stamps every accepted row." This ticket delivers a survey from primary sources, the options it supports with their trade-offs, a recommendation, and proposed wording for the specification. It decides nothing: question 11 stays open until the maintainer closes it.

The survey covers two families, as the maintainer asked:

- For time series tables: application logging frameworks and collection systems.
- For keyed state tables: comparable keyed-state systems.

For each system it reports who stamps the time (the library, the application, the receiver, or more than one of them, each under its own name), whether application code may supply or override a time, what the field is called, and its precision and epoch. It also reports what each system does when a supplied time is in the future, in the past, or out of order.

For each system it also captures why, following "Citing a comparable" in `CONTEXT.md`: the reason its authors gave for who stamps the time and for letting application code supply one or not, quoted and linked; the constraints behind that choice; what the choice has cost; and whether those constraints hold for this client. What a system does, without its stated why and its fit, may inform the recommendation and does not justify it.

One lead from the elicitation, never checked. The agent proposed calling the client's stamp "observed at", said it is the name OpenTelemetry uses for when the collecting side saw an event as opposed to when the event happened, and proposed the wall clock in UTC with microsecond precision. The maintainer left all of it undecided. Check what OpenTelemetry does, and capture why it keeps two times.

What is already settled, and is not reopened here:

- Within one process the client's clock never moves backwards. There is no ordering promise across processes.
- A keyed value records when it was last written.

What holds only in the meantime, and is in scope for the research:

- Every accepted row is stamped from the client's clock when it is written. This is question 11's interim behaviour, and the specification marks it "Derived": it follows from the maintainer's answers and was never put to them directly.
- A hand-over row carries the time under the name `client_time`. The name is part of question 11.

The maintainer's notes from the elicitation, verbatim:

> In any case, within a process, we do want a monotonic clock so that within a process time never moves backwords and the events are ordered (at least with respect to when the observed the clock), outside of a single process that's a different story. For timeseries tables we should look at application logging frameworks and collection systems for inspiration. For keyed state based TBD, we should look for similar systems to compare against.

On the keyed value's time:

> Instead of having an explicit lifetime (aka ttl), lets just record the "last_seen" timestamp (can be called somethings else, maybe something more standard).

Standing guidance from the same elicitation: where practice exists, follow it rather than invent; prefer coordination-free solutions; keep the MVP as simple as possible while sufficient and correct, without closing off later options.

**Research file:** `.scratch/client-spec/research/01-who-stamps-a-rows-time.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict or recommendation is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does each source say who stamps the time, under what name and at what precision, as the file reports, and is each why its authors' own words?
2. Is each system's reason for letting application code supply a time, or for refusing one, tied to constraints this client shares: one process, a clock that never moves backwards within it, and no ordering promise across processes?
3. Which comparable that chose otherwise is missing, for time series tables and for keyed state tables?
4. Does the recommendation rest only on comparables with a stated why and a fit argument, and is question 11 still open?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] The survey covers at least four application logging frameworks or collection systems and at least three keyed-state systems, each read from its official documentation or source code
- [x] For each system the findings state who stamps the time, whether the application may supply one, the field's name, and its precision and epoch
- [x] Every claim cites its source with a link and the date read, and anything no primary source confirmed is marked "Unverified"
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] The findings say how each option sits with the settled monotonic clock within one process, and what an application-supplied time would do to that promise
- [x] The options are listed with trade-offs, and one is recommended with its reasons, for time series tables and keyed state tables separately where they differ
- [x] The recommendation rests only on comparables that have a stated why and a fit argument, and names them; any other comparable it mentions is marked as informing only
- [x] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [x] The findings, options, recommendation and proposed wording are written to the research file; a "Hand-back" section appended to this ticket summarises them and points to it, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] Question 11 is still open in the specification, no tracked file other than this ticket and its research file is changed, and no code is added (true at hand-back; the maintainer has since decided question 11, and its adoption is folded into the same pull request: see "The maintainer's decision" below)

## Hand-back

The work is in `research/01-who-stamps-a-rows-time.md`, beside the issues folder. This section summarises it. Question 11 was still open at hand-back: nothing in the research decides it. The maintainer has since decided it, and the specification adopts the decision in the same pull request: see "The maintainer's decision".

### Findings

The survey covers thirteen time series comparables (T1 to T13: logging frameworks, telemetry data models and collection systems) and eleven keyed-state systems (K1 to K11). For each it records:

- who stamps the time, whether application code may supply one, the field's name, its precision and epoch, and what happens to a supplied time in the future, in the past or out of order;
- the stated why, quoted and linked, or "No stated rationale found" with where was looked;
- any inferred why, labelled;
- the constraints, the costs and dissent, and the fit.

Every quotation was checked as a substring of source text the researcher fetched again: 396 quotations at the last check, 383 exactly and 13 once whitespace is collapsed.

- **The elicitation's lead is corrected.** OpenTelemetry's name is `ObservedTimestamp` (`observed_time_unix_nano`), not "observed at". It is the time OpenTelemetry's own code first saw the event, so the in-process SDK sets it too, usually equal to the source `Timestamp`; it is not only the collecting side's time (T1).
- **Several comparables accept a supplied time.** Log4j, Fluentd's clients, InfluxDB, Kafka under `CreateTime`, Cassandra and HBase stamp the same field when none is given; OpenTelemetry stamps a separate field; Loki expects a time in every entry.
- **Chose otherwise, with a stated why:** Rust `tracing` (no time in the event), Prometheus (the server stamps), Kafka's `LogAppendTime`, OpenTelemetry gauges, and Kubernetes' node controller, which trusts its own clock for liveness.
- **The default stamper moved both ways.** Cassandra moved it from the server to the client library, to keep one client thread's writes in order; HBase proposed the reverse and met users who supply their own times.
- **Server-owned write times exist without a stated reason:** ZooKeeper's `mtime`, Firestore's `update_time`, Kubernetes' `creationTimestamp`.

### Options

**Ruled out by the settled promises:** refusing a bad supplied time loudly, blocking a write for the clock, and a row time that moves backwards while still described as the client's clock.

**The options:**

- **A:** the client stamps every row, and application code supplies no time; an application's own time is a column it declares.
- **B:** as A, plus an application time in a field the client defines.
- **C:** the application may supply the row's time, replacing the client's.
- **D:** a per-table choice between A and C.

Each is given with its effect on `ClockNeverMovesBackwards`, on keyed values and their settled last-write record, and on a write that never fails. A section on the clock itself compares a clamped wall clock, an anchored clock and a monotonic one, and what each does to the queue's age.

### Recommendation

**A, for both kinds of table**, with B named as an addition A does not close off. It rests on four claims:

1. **The client's stamp is an observation time** (OpenTelemetry, T1, justifies). That it is the client's alone to set is the researcher's argument; the systemd journal (T13) informs it.
2. **An application's own time is data, not the row's time** (Cassandra, K1, and HBase, K2, justify the risk and the separate column). The step to A for both kinds of table is the researcher's inference. Kafka (T12) informs it both ways: KIP-32 rejected a broker-time-only design.
3. **A keyed value's time is when the client accepted its latest write.** No comparable justifies it; it follows from the settled requirements. Flink (K3) informs it, and its discussion leaned the other way.
4. **The clock is the wall clock, clamped so it never goes back** (Cassandra, K1, justifies). Every reading of the client's clock, a stamp or not, counts as a use.

On weaker evidence, labelled as the researcher's argument: the name `observed_time`, and microseconds since the Unix epoch in UTC.

**What would turn the choice:** a replayed or backfilled row's original time in a field every table has points to B; that time as the row's only time is C, with its costs; keeping the latest keyed value by the application's time changes how slots are decided, a separate question.

### Proposed wording

Allium text for A covers the renamed field, `AcceptRow`, the vocabulary, the hand-over surface, the `ClockNeverMovesBackwards` guarantee and the writing surface's guidance, and removes question 11. It is in the research file only, and was not run through the pinned checker, because `just check-specs` checks only the tracked module. The glossary would gain an entry, and the worked examples in `CONTEXT.md` would need the new name.

### Adversarial review

Every review ran on Codex (codex-cli 0.169.1) with `gpt-6-astra`, the preferred model; each session header recorded the model. Every reviewer had live web search under this ticket's authorisation and a read-only sandbox. Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), neither the author nor a reviewer. Before the first review, a preflight confirmed that Codex ran `gpt-6-astra` and could open a URL. The review and triage files are under `ai_tmp/client-spec-review/01/`, which is not committed.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | K5 missed Redis's write-only LRM clock (8.6+) | Valid | K5's analogy, table row and synthesis rewritten, with PR 14624's stated purpose |
| 1, 1, sources | 2 | K5: `RESTORE … IDLETIME` lets a client set the clock | Valid | Added as a restore path, not a write option |
| 1, 1, sources | 3 | K4 omitted Kafka Streams' timestamp extractor | Valid | Added, with processing time not claimed as the store-write instant |
| 1, 1, sources | 4 | K8 applied last-writer-wins to all global tables | Valid | Scoped to MREC; MRSC rejects a concurrent write |
| 1, 1, sources | 5 | T5 missed Logback's precision history | Valid, narrower | LOGBACK-1374, the seconds regression and its repair added |
| 1, 1, sources | 6 | T5 missed a request for a configurable clock | Valid | LOGBACK-1682 added as a user's request |
| 1, 1, sources | 7 | T10 missed InfluxDB's precision guidance | Valid, narrower | Precision reason and its collision cost added |
| 1, 1, sources | 8 | T9 omitted Loki's per-stream window | Valid | `max_chunk_age`/2 added beside the wall-clock bounds |
| 1, 1, sources | 9 | T11 omitted Prometheus's future limit | Valid | The 10-minute scrape limit added |
| 1, 1, sources | 10 | ZooKeeper was missing | Valid | K10 added |
| 1, 1, sources | 11 | The systemd journal was not examined | Valid | T13 added |
| 1, 1, sources | 12 | T8 made Fluentd's fallback unconditional | Valid | Qualified as the default |
| 1, 1, sources | 13 | K7 read KEP-589's risk as observed breakage | Valid | Reworded as a predicted incompatibility |
| 1, 1, reasoning | 1 | Kafka's monotonic claim read as a guarantee | Valid | Separated from the 4.4.0 code, with a user's report |
| 1, 1, reasoning | 2 | K8 missed the Java SDK's opt-in stamping | Valid | Added; service and SDK told apart |
| 1, 1, reasoning | 3 | As sources 8 | Valid | As sources 8, plus the summary row |
| 1, 1, reasoning | 4 | As sources 4 | Valid | As sources 4 |
| 1, 1, reasoning | 5 | As sources 11 | Valid | As sources 11, with the design document's stated why |
| 1, 1, reasoning | 6 | Firestore was missing | Valid | K11 added |
| 1, 1, reasoning | 7 | The synthesis conflated accepting and fallback stamping | Valid | Split into three groups, no majority claimed |
| 1, 1, reasoning | 8 | As sources 2 | Valid | As sources 2 |
| 1, 1, sources | Suspicions | Quotations the reviewer could not open | Not findings | All verbatim against their sources |
| 1, 2, sources | 1 | K5's new LRM shared-integer claim | Valid | Withdrawn: 8.12.0 gives each key its own object |
| 1, 2, sources | 2 | T8 missed Fluentd PR 370's stated why | Valid | Added, for the parser fallback only |
| 1, 2, sources | 3 | T8 omitted the forward input's zero-time rule | Valid | Added |
| 1, 2, sources | 4 | K10's "real time used for nothing else" | Valid | TTL and container expiry by wall time added |
| 1, 2, sources | 5 | T10 kept "no constraints" beside an NTP note | Valid | The NTP dependency added |
| 1, 2, sources | 6 | T13 said one daemon per machine | Valid | Qualified: one per namespace |
| 1, 2, reasoning | 1–4 | As sources 1, 4, 5, 6 | Valid | As those |
| 1, 2, both | Suspicions | Kafka users@, ZOOKEEPER-1366, LOGBACK-1374 quotations | Not findings | All verbatim and correctly attributed |
| 2, 1, sources | 1 | KIP-32's argument against payload times dropped | Valid | T12 to "informs"; quoted in claim 2 and the dissent |
| 2, 1, sources | 2 | Flink's wrap-up supported event-time TTL | Valid, raised to high | K3 to "informs"; claim 3 left with no justifying comparable |
| 2, 1, sources | 3 | Kloudas's GDPR assumption stated as fact | Valid | Hedge restored; not leaned on |
| 2, 1, sources | 4 | systemd's trusted-field reason stretched to reception stamps | Valid | T13 to "informs"; the link labelled Inferred |
| 2, 1, sources | 5 | Cassandra's driver increments, it does not repeat | Valid | Repeating named as this client's adaptation |
| 2, 1, sources | 6 | "NOT time since any particular epoch" is Ellis's | Valid | Attribution corrected in three places |
| 2, 1, sources | 7 | Lebresne's point broadened beyond conflict resolution | Valid | Scope restored |
| 2, 1, reasoning | 1 | C5 called a Derived rule settled | Valid | Split into the settled record and the Derived rule |
| 2, 1, reasoning | 2 | As sources 4 | Valid | As sources 4, plus the trust-boundary argument |
| 2, 1, reasoning | 3 | C and D lose the settled keyed last-write record | Valid | Added to the ruled-out list, C, D and the turning points |
| 2, 1, reasoning | 4 | The clamp freezes the queue's age | Valid | Four clock treatments worked through; the choice left open |
| 2, 1, reasoning | 5 | As sources 1: a column is not a standard field | Valid | Dissent no longer called satisfied |
| 2, 1, reasoning | 6 | "Finest requirement found" missed HBase's nanoseconds | Valid | Qualified to a stamp the recording code takes |
| 2, 1, reasoning | Suspicion | As sources 3 | Valid | As sources 3, plus Krettek's opposing argument |
| 2, 2, sources | 1 | "Nothing was decided either way" for Flink | Valid | Agreed in outline, never built |
| 2, 2, reasoning | 1 | C confused the row's time with the client's clock | Valid | Claim 2 and the summary say what is at risk; the step to A labelled Inferred |
| 2, 2, reasoning | 2 | A diagnostic reading could break the clock's promise | Valid | Every reading of the client's clock counts as a use; which clock diagnostics read left open |
| 2, 2, reasoning | 3 | As sources 1 | Valid | As sources 1 |
| 2, 2, reasoning | Suspicion | FLINK-12005 comments could not be opened | Not a finding | Verified verbatim through the JIRA REST API |

**Open points.** No review finding is left open: all 48 numbered findings, and the suspicions, were applied or settled. What remains is for the maintainer, and is stated in the research file:

- Claim 3 has no justifying comparable, and the second half of claim 1 rests on the researcher's argument; the name and the precision do too.
- Which clock `Run.oldest_queued_age`, `Run.last_store_at` and the run id read; whether a clamp is counted or logged; and the hand-over's representation of the time (open question 15). Since decided by the maintainer, except open question 15: see "The maintainer's decision".
- The proposed wording was not run through the pinned checker.
- The second key moment's second-round fixes, and one follow-on edit to "What A leaves open" that made it agree with them, were not reviewed again after they were applied.

### Gates and files

- **Baseline**, at `9dfe6d6`, the untouched branch:

  > All checks passed and the worktree is unchanged.

- **Final**, at `270c50c`, the research file and this hand-back as reviewed and fixed. The commit that records this line changes only this section's lines.

  > All checks passed and the worktree is unchanged.

- **After the adoption**, at `dee338d`, the specification, handbook and `CONTEXT.md` changes, this hand-back's record of the decision and the review fix. The commit that records this line changes only this section's lines.

  > All checks passed and the worktree is unchanged.

- **Changed files:** at hand-back, this ticket and its research file only. The specification was unchanged, and open question 11 was still in it. No code was added. The adoption since changes the specification, two handbook pages and `CONTEXT.md`: see "The maintainer's decision".
- **`git status --short`** shows only `?? notes_2.md`, the user's own file, which this ticket did not touch.

### The maintainer's decision

Put to the maintainer after the hand-back, on 2026-11-24, and decided as follows. At the maintainer's request, the adoption is folded into this ticket's pull request rather than left to a separate one.

- **Who stamps: A.** The client stamps every accepted row from its own clock, and application code supplies no time. An application's own time, such as when an event happened, is a column the table declares.
- **Name: `observed_time`**, replacing `client_time`.
- **Precision and epoch:** microseconds since the Unix epoch, UTC.
- **Clock:** the wall clock, clamped. A reading earlier than the last one the process used is not used, and the last one is used again.
- **Other readings:** `oldest_queued_age`, `Run.last_store_at` and the run id (`uuid_v7(now)`) all read the client's clock. So no reading goes back, and the age stalls, never going negative, while the wall clock is behind.
- **Clamp reporting:** silent, so neither counted nor logged.
- **`CONTEXT.md`:** rename the `client_time` column header in its two worked examples, in this pull request.

This answers "What A leaves open" in the research file, except the hand-over's representation of the time, which is still open question 15. The research file records the decision in its own closing section and is otherwise unchanged.

**The adoption**, commit `fb8b7fa`, starts from the research file's proposed wording:

- `docs/specs/transect-client.allium`: `Row.observed_time` and its comment, `AcceptRow`, `oldest_observed_time` and `Run.oldest_queued_age`, the hand-over surface, a vocabulary sentence that every `now` in the module is the client's clock, `ClockNeverMovesBackwards` with the clamp and its silence, and the writing surface's guidance. Open question 11 is removed and its number is not reused.
- `docs/how-to/work-with-the-specs.md`: 24 open questions.
- `docs/project/glossary.md`: "Observed time".
- `.scratch/client-spec/CONTEXT.md`: the column header in both worked examples, with the columns re-aligned and nothing else changed.

`AcceptRow`'s "Derived" marker stays: it covers both the position and the stamp being taken at acceptance, which the maintainer was not asked. Ticket 11 still lists "Every accepted row is stamped from the client's clock when it is written" among the Derived statements; the stamp's source is now decided, and its timing is ticket 11's to confirm.

**Review of the adoption.** One review ran on Codex (codex-cli, read-only sandbox) with `gpt-6-astra`, the preferred model, which the session header recorded, against the maintainer's decisions above and the research file's proposed wording. A fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), neither the author nor the reviewer, triaged its finding. The prompt, review and triage are under `ai_tmp/spec-review/q11/`, which is not committed.

| # | Finding | Severity | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1 | The handbook defines an unmarked statement as one answered "during the elicitation", so a later decision such as this one is described wrongly | Low | Valid; present since `2d563fd` adopted A2, not introduced here | `docs/how-to/work-with-the-specs.md`: "What the maintainer answered, during the elicitation or since." |

The reviewer found nothing else: no stale name or reference to question 11, no departure from the decisions, no contradiction with another rule or open question, the count of 24 correct, and the `CONTEXT.md` change whitespace-only. It had no suspicions it could not confirm.

### Acceptance

- [x] At least four logging or collection systems and three keyed-state systems, from official documentation or source: thirteen and eleven.
- [x] Who stamps, whether the application may supply, the field's name, precision and epoch, for each.
- [x] Every claim linked with the date read, and "Unverified" where no primary source confirmed it.
- [x] Every field under "Citing a comparable" recorded, with fit in its own section.
- [x] Comparables that chose otherwise, with their why.
- [x] How each option sits with the monotonic clock, and what an application-supplied time would do to it.
- [x] The options with trade-offs, and one recommended, with time series and keyed state treated separately where they differ.
- [x] The recommendation rests only on comparables with a stated why and a fit argument, names them, marks the rest as informing, and labels where it rests on the researcher's argument instead.
- [x] Proposed wording for the recommended option.
- [x] Written to the research file, summarised here, and committed.
- [x] Adversarial review at both key moments, with reviewers that opened the sources; every finding listed above.
- [x] Question 11 still open, no other tracked file changed, and no code added: true at hand-back. The maintainer has since decided question 11, and the adoption changes the specification, two handbook pages and `CONTEXT.md` (see "The maintainer's decision").
