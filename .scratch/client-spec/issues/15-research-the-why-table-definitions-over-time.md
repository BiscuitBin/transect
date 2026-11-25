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

- [ ] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] The three claims that came from the agent's own knowledge are each checked from a primary source for the first time
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] The file says whether the reasons given by libraries for metrics carry over to tables with typed and required columns
- [ ] For each of the two stated behaviours above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [ ] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [ ] The file says what the evidence bears on open questions 13 and 20 and recommends an answer to neither; both are still open in the specification
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
