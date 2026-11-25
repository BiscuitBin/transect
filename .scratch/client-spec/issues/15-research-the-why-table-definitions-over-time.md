# 15: Research the why: table definitions over time

**What to build:** The maintainer can see why comparable systems treat a definition that changes between deployments, and a definition declared late, as they do, and whether those reasons hold for this client. During the elicitation one of these topics was surveyed for what the systems do, and the other was answered from the agent's own knowledge. Why the systems behave so was not captured, and no link was kept. This ticket checks the what again, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

What the specification proposes today, and what it was said to rest on:

- **Nothing enforced across runs.** The client enforces nothing about a definition that changed between runs. Each run's local databases carry the definitions they were written with. The survey reported that OpenTelemetry and Prometheus check nothing across processes, and described the maintainer's leaning as matching the mainstream.
- **Declare at any time.** A table may be declared at any time, and one declared during establish is usable at once. The maintainer chose this and asked whether it is common. The agent answered that it is the norm for telemetry libraries, from its own knowledge and without checking.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- OpenTelemetry and Prometheus check nothing across processes and keep conflicting versions side by side downstream.
- Snowplow and OTel's schema URL add a declared version that is validated downstream, with bad data quarantined.
- Only Confluent Schema Registry blocks a producer at write time, and it needs an always-available service.
- "The cheapest upgrade: a declared version or definition hash, and column ids that are never reused." No source is recorded for this. Iceberg was named when the survey was started and no finding names it. Find which system the idea of column ids came from.
- Never checked, from the agent's own knowledge: Prometheus clients register metrics whenever the code runs; OpenTelemetry instruments can be created before or after the provider is set; frameworks that own a schema, such as object-relational mappers, fix everything at start-up.

The maintainer's notes from the elicitation, verbatim. On what the client enforces when a definition changes between deployments, choosing "Nothing; each run describes itself":

> I'm leaning towards this for the MVP, but I'm also interested in understanding what other similar systems do other than just Prometheus to see how we would compare.

On declaring a table at any time, choosing "Any time, effective at once":

> Is this common among similar libraries and frameworks?

What the research must find out, beyond the fields every comparable gets:

- **Checking nothing.** Why OpenTelemetry and Prometheus check nothing across processes, what happens downstream when two processes disagree about one name, and what their users have reported against it.
- **A declared version, validated downstream.** Why Snowplow and OTel's schema URL carry a version, what led to quarantining bad data instead of refusing it, and what that costs.
- **Blocking the producer.** Why Confluent Schema Registry refuses at write time, and what its authors say about needing the service to be available.
- **Column ids.** Why the system that uses stable column ids does so, and which changes to a definition it was written to survive.
- **Declaring late.** Why telemetry libraries allow an instrument or a metric to be created at any time, and what each does when the same name is registered twice with a different definition.
- **A comparable that chose otherwise**, with its why. The agent named frameworks that own a schema as fixing definitions at start-up. Check that, and capture why they do.
- **Whether the comparison is fair.** A metric is a name with a value and labels. A table here has typed columns, some required, and a row that does not fit is refused whole. Say whether the reasons a metric library gives carry over to that, or stop short of it.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related open questions, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- 13: whether a declaration carries a version or a definition hash, and stable column ids.
- 20: what makes a declaration valid, including which names are allowed and which columns may form a key.

**Ticket 16's findings:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md` bears on this ticket. Fit records that a `metrics` handle registered before a recorder stays bound to the recorder current then, which runs against declaring a table at any time (A3, K4), and that OpenTelemetry Python's proxies bind once a provider is set, because import order "is not necessarily in users' control", which fits it (C2). Stated behaviour 2 records `client_golang`'s reason for checking at registration, that an inconsistency "will usually be detected at start-up time of a program" (E7), which covers a declaration made at start-up and not one made with a run in force. Read it before starting. Its fits and verdicts are findings, not decisions: the maintainer has said they are not guaranteed to be applied, and they stay open for the tickets they bear on.

**Research file:** `.scratch/client-spec/research/15-table-definitions-over-time.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does each source say what the file claims the system checks, where it checks it, and what it does with data that fails?
2. Is the fit argued or assumed: are libraries for metrics a fair comparable for tables with typed and required columns?
3. Is the source of "column ids that are never reused" found, and is the comparable that fixes definitions at start-up given with its why?
4. Does the file recommend or imply an answer to open question 13 or 20?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] The three claims that came from the agent's own knowledge are each checked from a primary source for the first time
- [x] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] The file says whether the reasons given by libraries for metrics carry over to tables with typed and required columns
- [x] For each of the two stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [x] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [x] The file says what the evidence bears on open questions 13 and 20 and recommends an answer to neither; both are still open in the specification
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/15-table-definitions-over-time.md`, beside the issues folder. This section summarises it. Open questions 13 and 20 are still open: nothing here decides them, and the specification is not edited.

### Baseline and gates

- Baseline, on the untouched worktree at `90f0abb`: `just check` ended with `All checks passed and the worktree is unchanged.`
- With this hand-back in place, before its commit: `just check` ended with `All checks passed and the worktree is unchanged.`
- Against the branch point, the branch changes only the research file and this ticket.

### Findings

The research file covers thirty comparables (C1 to C30), grouped by the ticket's questions. Each records what it does, read at a pinned version and dated; the stated why, quoted and linked, or "No stated rationale found" with where was looked; any inferred why, labelled; the constraints; costs and dissent; and fit. 512 quotations were checked by machine as substrings of sources the author fetched again: 491 matched exactly and 21 once line breaks, indentation, comment markers or ligatures were collapsed; none was missing.

**The claims from the elicitation**, each checked again, three of them from a primary source for the first time:

- **"OpenTelemetry and Prometheus check nothing across processes"**: confirmed for their client libraries and SDKs, which check only within one process. Wrong for Prometheus's Pushgateway, which by default refuses a push whose type conflicts with another pusher's.
- **"...and keep conflicting versions side by side downstream"**: partly wrong. The Prometheus server keeps series apart by default, but metadata was overwritten per name, federation drops it, the OpenTelemetry Collector's Prometheus exporter drops a metric whose type conflicts, and OpenTelemetry lets a consumer reject a conflict.
- **Snowplow's declared version, validated downstream, with bad data kept apart**: confirmed for self-describing events, with caveats. Since Enrich 6.5.0 a registry outage crashes Enrich instead.
- **OpenTelemetry's schema URL, validated downstream, with bad data quarantined**: the version is confirmed. Validation and quarantine are wrong: the schema URL drives translation.
- **"Only Confluent blocks a producer at write time"**: wrong. Pulsar refuses an incompatible producer and fails a send with an incompatible new schema; AWS Glue's serializer throws; the Pushgateway refuses by default. Confluent's, Glue's and Apicurio's refusal at registration applies only under a compatibility rule, which Apicurio applies only when one is configured.
- **"...and it needs an always-available service"**: partly confirmed. Confluent's serializer needs the registry on a cache miss, not on every write, and has retried since 2024.
- **"The cheapest upgrade: a declared version or definition hash, and column ids that are never reused"**: Unverified as a sentence. Its parts exist, and no source makes the "cheapest" claim.
- **Where column ids came from**: not established. Iceberg's specification states its unused-id rule, in a sentence written no later than 2019-06-23; its 2017 release already allocated ids from a counter. The earliest never-reuse rule found is Protocol Buffers', for message fields, in 2008. No Iceberg source names a predecessor. The elicitation's record is not tracked.
- **Prometheus clients register whenever the code runs**: confirmed; no stated rationale for it.
- **OpenTelemetry instruments before or after the provider**: confirmed for creation in Go, Python and Java. Wrong for Java if it means an early instrument starts working.
- **Frameworks that own a schema fix everything at start-up**: partly wrong. Hibernate and grpc-go do; Entity Framework Core builds on first use; Django accepts a model defined later; SQLAlchemy lets a table be defined at any time.

**Comparables that chose otherwise** are recorded with their why: the Pushgateway, Confluent, Pulsar and Glue, which refuse a conflicting writer; Hibernate, Entity Framework Core, grpc-go, Django and OpenTelemetry's Java global, which fix definitions early; and Delta, Iceberg, Elasticsearch and InfluxDB 3's explicit mode, which refuse typed data that does not fit. Of the start-up fixers, only grpc-go states a reason, a read path with no lock; no stated reason was found for Hibernate's.

**Whether the comparison is fair.** Metric libraries are a fair comparable for where a check can be made and for disagreement during a rollout. Their reasons stop short of what a disagreement costs: their authors move it downstream, and what disagrees is a stream's type, unit or help, not the shape of a row, although a change of instrumentation can turn a float series into a histogram one, which some of Prometheus's functions then leave out. For that cost the typed stores and Avro are the closer comparables, and they place it at the reader.

### Verdicts

- **Nothing enforced across runs: it rests on a stated why that does not transfer.** The guarantee covers every run. Prometheus's maintainer says a library can keep the labels of its pre-defined collectors consistent "over the lifetime of a binary" and "cannot prevent" their changing "globally", without saying why. That limit does not transfer to a run in a new process that follows another at the same location, which can see any databases the earlier run left there (open question 6). It is not shown to fit runs on other instances: that it does rests on an Inferred reading of "cannot", so it informs checking nothing against them and does not justify it. The guarantee also does not mention successive runs of one confluence (Derived), where a changed definition already fails as a redeclaration. Carrying each run's definitions with its rows rests on Avro's stated why, which fits. Proposed wording is in the file.
- **Declare at any time, usable at once: it rests on a stated why that does not transfer.** That it is common among telemetry libraries is confirmed. Their reasons, an identity known only at the call and libraries instrumenting code they do not configure, are not shown to hold for a table. Micrometer's would transfer only to an application that learns a table's name or columns at the call, which nothing shows. "Usable at once" has no stated why of its own: InfluxDB 3 makes a column usable at once on the node that took its declaration, and explains how, not why. The specification's guidance gives start-up as the reason declaring may fail loudly, which does not cover a table declared during a run. Proposed wording is in the file.

### What the findings bear on

- **Open question 13**: each mechanism, a declared version (Snowplow, OpenTelemetry), a definition hash (Avro) and stable column ids (Iceberg, Protocol Buffers, fbthrift, Delta), is given with its authors' reason and its stated cost, beside Avro's stated reason for having no field ids. The hand-over already carries each run's full definition. Whether a later run at the same location would have a use for a version, a hash or ids depends on open question 6, by the researcher's reading. Nothing is recommended.
- **Open question 20**: not surveyed. Incidental evidence only: how comparables treat an identical redeclaration, names that differ only in case, a name colliding with one the library adds itself, and reserved names. One rule bears on which columns may form a key: Iceberg rules out float, double and optional fields as identifier fields, stating its reason only for the optional ones, and leaves uniqueness to engines. Nothing is recommended.

### Questions for the maintainer

1. `NothingAcrossRuns` says the client enforces nothing about a definition that changed between runs. Where one confluence holds successive runs (Derived), `rule DeclareTable` refuses a changed redeclaration in a later run. Should the guarantee name only runs in other processes, or is that check meant to sit outside it as worded?

   **Maintainer's answer, 2026-11-25** (chosen from the options put): "Decide with open Q6". "Leave the wording as is for now and settle it together with open question 6 (what establish does with databases a previous run left at the location), since both are about what a later run sees of an earlier one."
2. The specification gives the reason declaring may fail loudly as "it runs at start-up, where the developer can see it". Should that reason cover a table declared during a run, or should ticket 16 take up that case with the rest of the failure posture?

   **Maintainer's answer, 2026-11-25** (chosen from the options put): "Hand it to ticket 16". "Add this case to ticket 16's scope (failure posture). The research file's proposed @guidance already says 'whether it should is part of the failure posture, which is still being researched'." Ticket 16 is not edited on this branch, which changes only this ticket and its research file; adding the case to it is a follow-up.

3. Asked after the hand-back was first written: how strictly is `CONTEXT.md`'s rule on "justifies" read, here and in later research tickets? (See "How strictly "justifies" is read" under "Open points".)

   **Maintainer's answer, 2026-11-25** (chosen from the options put): "Strict, as filed". "The stated reason itself must fit; if the fit depends on an Inferred step, the comparable only informs. C1 stays 'Informs'. No edit needed."

### Adversarial review

- **Reviewers.** Every review ran on Codex (codex-cli 0.172.0) with `gpt-6.2-sol`, at the default reasoning effort, medium. The maintainer chose that model for this ticket, in place of `REVIEW.md`'s preferred `gpt-6-astra`. Each session header recorded the model.
- **Web access.** Every reviewer had live web search (`-c web_search="live"`) under this ticket's authorisation, and a read-only sandbox. A preflight before the first review confirmed that Codex ran `gpt-6.2-sol` and could open a pinned URL.
- **Triage.** Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), neither the author nor a reviewer, which opened the sources itself.
- **Rounds.** Each key moment ran two rounds, the most `REVIEW.md` allows. The first key moment came before any fit or verdict was written. In its second round, the sources reviewer was pointed first at the first round's fixes. The second key moment covered the whole file, with all four of the ticket's questions. Its second round's fixes were triaged and quotation-checked but, under that limit, not reviewed again.
- **Records.** The review files and triage files are under `ai_tmp/client-spec-review/15/`, which is not committed.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | C11 stated Iceberg's read rule as a rule about writes | Valid | Read and write rules separated; the v3 writer rule quoted |
| 1, 1, sources | 2 | Two Prometheus targets can share a series; the metadata API's scope overstated | Valid in part (`limit_per_metric` point invalid: an optional filter) | `honor_labels` added; API limited to targets currently scraped, marked experimental |
| 1, 1, sources | 3 | Remote write 2.0 metadata given as a guarantee | Valid | Stated as SHOULD, behind a feature flag |
| 1, 1, sources | 4 | client_python's duplicate check misses collectors with no names | Valid | The `auto_describe` gap added, Inferred |
| 1, 1, sources | 5 | The Pushgateway refuses only by default | Valid | The flag and its scrape-time failure added |
| 1, 1, sources | 6 | "First seen wins" for a description presented as OpenTelemetry's rule | Valid | Relabelled as one participant's view; the data model's "longer string" quoted |
| 1, 1, sources | 7 | The Collector exporter keeps the first help only while cached | Valid | `metric_expiration` added |
| 1, 1, sources | 8 | Not every Snowplow event names a schema | Valid | Baked-in events added |
| 1, 1, sources | 9 | Enrich's crash change states its reason; its trigger and release | Valid | Reason moved to "Stated why"; trigger and release 6.5.0 added; #157 found unrelated |
| 1, 1, sources | 10 | Confluent's cache is per client and bounded | Valid | Cache miss defined; bounds quoted |
| 1, 1, sources | 11 | Pulsar also refuses at send time | Valid | PIP-43's send-time check and the client's exception added |
| 1, 1, sources | 12 | Iceberg states the unused-id rule; Protocol Buffers is no provenance for columns | Valid | Rule restated as stated; Protocol Buffers scoped to message fields |
| 1, 1, sources | 13 | The Protocol Buffers `reserved` quotation stopped before its exception | Valid | Full passage quoted; cost restated |
| 1, 1, sources | 14 | Delta's column mapping can be dropped since 3.3.0 | Valid | Both pages quoted; metadata-only rename, drop and widening added |
| 1, 1, sources | 15 | Java's `getOrNoop()` and autoconfigure | Valid | Added; claims row corrected |
| 1, 1, sources | 16 | Hibernate's quoted passages are not reasons for fixing the mapping | Valid | "No stated rationale found" for the fixing; passages relabelled |
| 1, 1, sources | 17 | EF Core builds its model on first use | Valid | Added with the performance documentation |
| 1, 1, sources | 18 | gRPC Python enforces start-only on one path of two | Valid | Both paths described |
| 1, 1, sources | 19 | InfluxDB's default query leaves out unconvertible values | Valid | Added |
| 1, 1, sources | 20 | BigQuery is not add-only, and Google states a reason | Valid | Corrected; the reason quoted |
| 1, 1, reasoning | 1 | "Two targets never share a series" ignores `honor_labels`; the flag is implemented | Valid | Merged with sources 2; the flag's default quoted |
| 1, 1, reasoning | 2 | The Pushgateway's push-time check is a default | Valid | Merged with sources 5; the full passage quoted |
| 1, 1, reasoning | 3 | Duplicate-registration rules compressed; remediation omitted | Valid | The data model's remediation and the SDK's warning cases quoted |
| 1, 1, reasoning | 4 | Snowplow's baked-in events | Valid | Merged with sources 8 |
| 1, 1, reasoning | 5 | Snowtype's validation can throw | Valid | Corrected; the page's new address used |
| 1, 1, reasoning | 6 | The schema processor has three outcomes | Valid | The Resource case and the batch stop added |
| 1, 1, reasoning | 7 | Confluent's cache is per subject | Valid | Merged with sources 10 |
| 1, 1, reasoning | 8 | An Iceberg v3 writer must fail on a missing required field | Valid | Merged with sources 1 |
| 1, 1, reasoning | 9 | fbthrift states a never-reuse rule | Valid in part (the Iceberg half was already in the file) | fbthrift added to C13 |
| 1, 1, reasoning | 10 | Delta's feature-removal page contradicts "irreversible" | Valid | Merged with sources 14 |
| 1, 1, reasoning | 11 | Avro's single-object encoding carries a fingerprint | Valid | Added to C15 |
| 1, 1, reasoning | 12 | Hibernate's why is about cost and named queries; EF Core is not at start-up | Valid | Merged with sources 16 and 17 |
| 1, 1, reasoning | 13 | Delta renames, drops and widens without a rewrite | Valid | Merged with sources 14 |
| 1, 1, reasoning | 14 | Elasticsearch coerces by default; the failure store's default is scoped | Valid | Added |
| 1, 1, reasoning | 15 | InfluxDB's cross-shard query leaves out other types | Valid | Merged with sources 19 |
| 1, 1, reasoning | 16 | BigQuery can drop, rename and change some types | Valid | Merged with sources 20 |
| 1, 1, reasoning | S2 | The Delta design document names Iceberg as a competitor, not a source | Valid | "Lineage" replaced by "a connection" throughout |
| 1, 2, sources | 1 | Glue's and Apicurio's refusals can reach the producer | Valid | C10 and the claims row rewritten |
| 1, 2, sources | 2 | Iceberg's 2017 code allocates fresh ids; the sentence can be dated | Valid | Code quoted; "written no later than 2019-06-23" |
| 1, 2, sources | 3 | An Iceberg author ties ids to type promotion | Valid | Ryan Blue's 2021 message added as a later explanation |
| 1, 2, sources | 4 | Iceberg's read path for a missing id has four rules | Valid (scoped to files written with ids) | All four quoted |
| 1, 2, sources | 5 | Delta's whole-write refusal is the batch rule | Valid | Other write paths described |
| 1, 2, sources | 6 | Confluent's outage reports omit the retry fix | Valid | Retries and pinned defaults added |
| 1, 2, sources | 7 | client_python's merge can raise in one case | Valid (lowered to low; read, not run) | Added, Inferred |
| 1, 2, sources | 8 | `honor_labels` collides only on conflict; one duplicate-timestamp path | Valid (narrowed) | Added |
| 1, 2, sources | 9 | OpenTelemetry's SHOULDs written as behaviour; one anecdote as a pattern | Valid | Reworded |
| 1, 2, sources | 10 | Protocol Buffers' outcomes include a parse error | Valid | Added |
| 1, 2, sources | 11 | .NET's cache covers only synchronous instruments; #77514 states its purpose | Valid | Added |
| 1, 2, sources | 12 | EF Core's model is cached, not fixed for the process | Valid | Reworded; no eviction asserted |
| 1, 2, sources | 13 | Elasticsearch's failure store has a boundary | Valid | Added |
| 1, 2, sources | 14 | BigQuery's entry point and a nested `REQUIRED` exception | Valid | Added |
| 1, 2, reasoning | 1 | Iceberg's 2017 release already allocates unused ids | Valid | Merged with sources 2 |
| 1, 2, reasoning | 2 | Glue and Apicurio producers get an exception; Glue states why | Valid (Apicurio scoped as Inferred) | Glue's launch post quoted under "Stated why" |
| 1, 2, reasoning | 3 | The Java OpenTelemetry row conflates creating an instrument with installing the global | Valid in part (C17's body was accurate) | Claims row and "chose otherwise" corrected |
| 1, 2, reasoning | 4 | The claims row omits client_python's multiprocess merge | Valid | Added |
| 1, 2, reasoning | 5 | Delta's DataFrame rule applied to every write; NOT NULL enforcement | Valid | Merged with sources 5; the enforcing code quoted |
| 1, 2, reasoning | 6 | A re-added Iceberg column is not always null | Valid | Merged with sources 4 |
| 1, 2, reasoning | 7 | EF Core "for the life of the process" | Valid | Merged with sources 12 |
| 1, 2, reasoning | 8 | .NET's cache does not apply to every instrument | Valid | Merged with sources 11 |
| 1, 2, reasoning | 9 | SQLAlchemy does not compare definitions | Valid | Claims row corrected |
| 1, 2, reasoning | 10 | Hibernate's implementation note; grpc-go's rationale | Valid in part (grpc-go half invalid: already quoted as late-68) | Hibernate's note quoted under "Constraints" |
| 1, 2, reasoning | S3 | A missing schema can still crash Enrich | Valid | The resolver's rule quoted from the pinned library's sources jar |
| 2, 1, sources | 1 | Prometheus's limit read as "cannot see"; successive runs of one confluence missed | Valid | Limit quoted for what it says, reach marked Inferred; successive runs named; question 1 for the maintainer |
| 2, 1, sources | 2 | Metric libraries do refuse a measurement against its definition | Valid | Fairness bullet rewritten with their checks quoted |
| 2, 1, sources | 3 | OpenTelemetry's authors did not call passing the ambiguity downstream cheap | Valid (the temporality excerpt not used) | Rewritten with jmacd's stated cost |
| 2, 1, sources | 4 | The client refuses rows before storing them, as the typed stores do | Valid | Corrected |
| 2, 1, sources | 5 | Reasons about start-up counted as reasons for late declaration | Valid in part (the duplicate point was already in the file) | Scoped; the crash comparison qualified by `LoudFailure` |
| 2, 1, sources | 6 | Fit C23 assumes writes look a table up | Valid | Made conditional |
| 2, 1, sources | 7 | The `honor_labels` collision condition is too narrow; "should work" is not verbatim | Valid | Corrected; bboreham quoted exactly |
| 2, 1, sources | 8 | Confluent's retry waits are random; pull request 3424 is quoted | Valid | Corrected; "not fetched" amended |
| 2, 1, sources | 9 | Where Snowplow and Glue validate is blurred | Valid in part (the Apicurio point was already hedged) | Corrected |
| 2, 1, sources | 10 | Iceberg's irreversibility and the Flink mechanism overstated | Valid | Corrected |
| 2, 1, sources | 11 | Delta's code settles removability; the rationale is about physical names | Valid | Code quoted; ids and names kept apart |
| 2, 1, sources | 12 | The question-20 summary drops two conditions | Valid | Restored |
| 2, 1, reasoning | 1 | The cross-run verdict widens beorn7's statement | Valid | Merged with sources 1; "Justifies" kept for runs out of reach, as the researcher's argument |
| 2, 1, reasoning | 2 | "Usable at once" has no why; the wording does not say what it replaces | Valid in part (the claimed contradiction and dropped text refuted) | Paragraph added; the wording's place stated; the two `@guidance` proposals marked as one |
| 2, 1, reasoning | 3 | Metric libraries check measurement inputs too | Valid | Merged with sources 2 |
| 2, 1, reasoning | 4 | Passing the ambiguity downstream is not shown to be cheap | Valid | Merged with sources 3 |
| 2, 1, reasoning | 5 | The grpc-go fit assumes a lookup on every write | Valid | Merged with sources 6 |
| 2, 1, reasoning | 6 | The Avro fit leaves the local databases implicit | Valid | Qualified, pointing at open question 6 |
| 2, 1, reasoning | 7 | The question-13 summary overstates Iceberg's costs | Valid | Merged with sources 10 |
| 2, 1, reasoning | 8 | The question-20 summary drops Protocol Buffers' run-time exception | Valid | Merged with sources 12 |
| 2, 2, sources | 1 | C1's "Justifies" rests on the Inferred cause of beorn7's limit | Valid in part (beorn7 does state the limit) | "Justifies" became "Informs" in the fit table and the verdict; the proposed `@guidance` keeps the researcher's clause apart from what it attributes to Prometheus |
| 2, 2, sources | 2 | "A sample is a number with labels" leaves out histograms | Valid | Merged with reasoning 5; the type-and-unit feature flag noted |
| 2, 2, sources | 3 | The multiprocess merge takes a gauge's mode from the last file read | Valid | Added to C1, the fit table and the claims table, Inferred from the code |
| 2, 2, sources | 4 | The multiprocess documentation and issue #275 give reasons for keeping a dead worker's files | Valid | Both quoted, scoped to one run; "no stated rationale" narrowed to wiping between runs |
| 2, 2, sources | 5 | OpenTelemetry's SHOULDs summarised as what happens | Valid | "Should" restored in the fit table and the fairness section; "can be expected to export data" quoted |
| 2, 2, sources | 6 | A registry's refusal depends on its compatibility setting | Valid | Confluent's default and `NONE`, Apicurio's no-rule default and `NONE`, and Glue's `NONE` quoted; Apicurio's Debezium outcome added |
| 2, 2, sources | 7 | The question-13 summary leaves out Avro's reason for having no field ids | Valid | Added with its cost and the dissent, judging nothing |
| 2, 2, sources | 8 | Iceberg gives a reason for limiting identifier fields | Valid | Merged with reasoning 7 |
| 2, 2, sources | 9 | BigQuery's fit row drops the nested exception; a refused request can return HTTP success | Valid | "At the top level" added; the streaming guide quoted |
| 2, 2, sources | 10 | .NET's issue #77514 listed as not examined although its body is quoted | Valid | Reworded to say what was read |
| 2, 2, reasoning | 1 | The cross-run "Justifies" rests on an Inferred reading of "cannot"; "for the pre-defined collectors" dropped | Valid | Merged with sources 1; the qualifier restored in three places; the fairness lead-in keeps fairness apart from fit |
| 2, 2, reasoning | 2 | The first verdict leaves its scope to the reader; "enforces nothing"; a predecessor's databases taken as present | Valid in part ("enforces nothing" invalid: question 1 for the maintainer already holds it) | The headline states its scope; "any databases ... left there" |
| 2, 2, reasoning | 3 | Micrometer's reason transfers conditionally; use before configuration grouped with declaring late | Valid in part (the grouping is sound: `DeclareTable` covers "with or without a run in force") | The condition stated in the verdict and the C18 row |
| 2, 2, reasoning | 4 | InfluxDB 3's same-node immediacy left out of the late-declaration verdict; grpc-go's policy | Valid in part (grpc-go is already cited as late-68) | A paragraph added; it informs and gives no why |
| 2, 2, reasoning | 5 | A sample can be a histogram, and its type can change between deployments | Valid | The native histograms specification quoted; "a sample has neither" narrowed to fields an application declares |
| 2, 2, reasoning | 6 | Reconciliation placed both at and after the collector; question 13 narrowed to downstream | Valid | "At the collector or after it"; the dependency on open question 6 named as the researcher's reading |
| 2, 2, reasoning | 7 | Iceberg's identifier-field restrictions bear on key columns | Valid | Quoted under question 20, recommending nothing |
| 2, 2, reasoning | 8 | The fit row applies Thrift's reason to Parquet and says both lack names | Valid | The row split by system; Parquet's required name quoted |

### Open points

- **The elicitation's record is not tracked.** Where the sentence "The cheapest upgrade: a declared version or definition hash, and column ids that are never reused" came from cannot be checked. It stays Unverified as a sentence, and where column ids came from is not established.
- **The two questions for the maintainer** above are answered, and neither changes this file: the case of successive runs of one confluence waits on open question 6, and a declaration that fails loudly during a run goes to ticket 16.
- **How strictly "justifies" is read.** The second key moment's two rounds of triage read `CONTEXT.md`'s rule differently. The first kept "Justifies" for runs on other instances, on the ground that the limit is stated and the fit is argued about this client. The second required the stated reason itself to fit, and the file follows the second. If the maintainer reads the rule the first way, C1's "Use" cell and the verdict's second sub-bullet can say "justifies" again. The verdict's headline does not change either way. The maintainer chose the stricter reading, so the file stands.
- **Read only in part**, as the file records: KIP-467 was not fetched; of Confluent pull request 3424 only its description, and of .NET issue #77514 only its body, were read; what Hibernate does with two entities of one name was not examined.
