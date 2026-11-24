# 02: Research: a tenant named for a tenant-free table

**What to build:** The maintainer can decide open question 19 of the proposed client specification from evidence. The question reads: "What happens to a write that names a tenant for a tenant-free table: stored without a tenant and counted, or refused? Until decided, this module gives that write no outcome: it is not counted, it does not fail, it does not block, and no tenant is stored for a tenant-free table." This ticket delivers a survey from primary sources, the options it supports with their trade-offs, a recommendation, and proposed wording for the specification. It decides nothing: question 19 stays open until the maintainer closes it.

The case is narrow. A client handle's bound tenant is simply not applied to a tenant-free table, and that is ordinary: a unit of work for one tenant may also record a platform row. The question is only about a single write that names a tenant itself, for a table declared tenant-free.

The two answers put to the maintainer during the elicitation, neither chosen:

- Store the row without a tenant and count the mismatch, so that it shows in the diagnostics.
- Refuse the row whole and count it as invalid, like a row with an unknown column.

The maintainer's note, verbatim:

> We should think this through, maybe do some research on similar systems and consider what would be the least surprising, most expected option. Consider other comparables both at the broader system level, but then also at the framework and client level.

The survey looks at what comparable systems do when a write carries a scope its target does not have, at the two levels the maintainer named:

- The broader system level: multi-tenant data stores and telemetry back ends.
- The framework and client level: multi-tenancy libraries for web frameworks and object-relational mappers, and telemetry client libraries given an attribute or label the target does not declare.

For each comparable it also captures why, following "Citing a comparable" in `CONTEXT.md`: the reason its authors gave for storing, dropping, refusing or raising, quoted and linked; the constraints behind that choice; what the choice has cost; and whether those constraints hold for this client. What a comparable does, without its stated why and its fit, may inform the recommendation and does not justify it.

What is already settled, and is not reopened here:

- Every write never fails and never blocks.
- Every write is counted exactly once. This one write is the exception today: with no outcome, it is not counted. Whatever is recommended must end that.
- A tenant-free table never stores a tenant.
- No row is attributed to a tenant that was not explicitly bound.
- Every row the client loses while its process lives is counted exactly once.
- A row that does not fit its table (a missing required column, an unknown column, a wrong type) is refused whole and counted. Nothing is converted.

Standing guidance from the same elicitation: where practice exists, follow it rather than invent.

**Research file:** `.scratch/client-spec/research/02-a-tenant-named-for-a-tenant-free-table.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict or recommendation is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Is each comparable really a write that carries a scope its target does not have, or a looser analogy presented as one?
2. Does each source say what the file reports happens to the write, and is each why its authors' own words?
3. On what evidence does the file say which behaviour surprises a developer least: a stated reason, a reported complaint, or the researcher's own view presented as a finding?
4. Does the recommendation keep every settled promise listed in the ticket, rest only on comparables with a stated why and a fit argument, and leave question 19 open?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] The survey covers at least three comparables at the broader system level and at least three at the framework and client level, each read from its official documentation or source code
- [x] For each comparable the findings state what happens to the write (stored without the scope, refused, raised as an error, or stored with it), and whether and how the mismatch is made visible
- [x] Every claim cites its source with a link and the date read, and anything no primary source confirmed is marked "Unverified"
- [x] For each comparable the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [x] At least one comparable that chose otherwise is recorded with its why
- [x] The findings say which behaviour surprises a developer least and why, and which options the settled promises above rule out
- [x] The options are listed with trade-offs, including where each would be counted in the diagnostics, and one is recommended with its reasons
- [x] The recommendation rests only on comparables that have a stated why and a fit argument, and names them; any other comparable it mentions is marked as informing only
- [x] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [x] The findings, options, recommendation and proposed wording are written to the research file; a "Hand-back" section appended to this ticket summarises them and points to it, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] Question 19 is still open in the specification, no tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/02-a-tenant-named-for-a-tenant-free-table.md`, beside the issues folder. This section summarises it. Question 19 is still open: nothing here decides it.

### Findings

The survey covers eleven comparables at the system level (S1 to S11) and thirteen at the framework and client level (F1 to F13). For each it records:

- the shape: named or ambient, scope-like or unknown-field-like;
- what happens to the write;
- the stated why, quoted and linked, or "No stated rationale found" with where was looked;
- any inferred why;
- the constraints, the costs and dissent, and the fit.

Every quotation was checked as a substring of source text the author fetched again: 222 quotations at the last check. The closest matches split:

- **Kubernetes (S1) clears a namespace named on a cluster-scoped object silently.** No reason is stated. A reviewer called it "weird", and a downstream security advisory turns on it.
- **Weaviate (S11) rejects a tenant named on a collection without multi-tenancy.** Its code states only an aim.
- **Elasticsearch time series (S3), Spark (S4) and Cosmos DB (S5) also reject.** None states why it refuses rather than ignores.

Among the client libraries, Prometheus raises or fails to compile (F1, F2), OpenTelemetry Views and `tracing` drop (F4, F6), and Micrometer moved four times, each time with a stated reason (F3). acts_as_tenant reversed a silent overwrite of a named tenant because it "was confusing and hid bugs" (F7).

The complaints are consistent that silent handling that loses data surprises developers. On keeping the row against refusing it, they point both ways, and no source compares the two.

### Options

**Ruled out by the settled promises:**

- storing the named tenant;
- failing loudly;
- blocking;
- leaving the write uncounted;
- storing the row under another tenant.

**The options:**

- **A1:** keep the row without the tenant, counted in a counter of its own.
- **A2:** as A1, and logged as a kind of its own.
- **B:** refuse the row as invalid.
- **C:** refuse the row with an outcome, counter and kind of its own.
- **D:** keep the row, counted only as accepted.

Each is given with its effect on `WriteOutcome`, `FailureKind`, the host log, `CountersMatchTheRows`, `RecordedWrite` and the rule order. A Rust typed table that cannot name a tenant is a complement, not an option.

### Recommendation

**A2**, resting on three claims:

1. **The mismatch must not be silent, and should be logged.** The host log is the one channel that can reach a developer who is not looking, though nothing guarantees a record is read. This rests on acts_as_tenant (F7), Micrometer (F3), the ClickHouse maintainer (S6) and OpenTelemetry's error-handling principle (F4), each with a stated why and a fit argument.
2. **Keep the row rather than refuse it.** This is the weakest step, and it is the researcher's own argument: no comparable both states a reason for it and fits.
3. **Never store the tenant.** This is settled, and Hibernate's stated reason (F8) agrees.

The fake-core flag, which lets a test assert that no write named a tenant, rests on Laravel (F11). A Rust typed table rests on client_golang (F2), for Rust only.

Keeping has a cost that refusing would not. A wrongly named write that A2 keeps can replace a correct value in a tenant-free keyed state table. Under the production core it can also take the last queue place from a correct row. The file therefore puts one question to the maintainer, and says what would turn the choice to C. C is preferred to B in that case, because only C's signal tells a named tenant from a column that does not fit.

### Proposed wording

Allium text for A2 covers every place a counter, outcome or kind is listed, and gives wording for C too. It is in the research file only. It was not run through the pinned checker, because `just check-specs` checks only the tracked module. The glossary would need a new entry.

### Adversarial review

Every review ran on Codex (codex-cli 0.169.1) with `gpt-6-astra`, the preferred model. Each session header recorded the model, because the model could not name itself. Every reviewer had live web search under this ticket's authorisation, and a read-only sandbox. Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), which was neither the author nor a reviewer.

Before the first review, a preflight confirmed that Codex ran `gpt-6-astra` and could open a URL. The review files and triage files are under `ai_tmp/client-spec-review/02/`, which is not committed.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | F8 missed Hibernate's stated reason and dissent | Valid | Pull request #3867's review thread added, with its dissent |
| 1, 1, sources | 2 | S7 said the surplus fields were removed | Valid | Corrected: unmapped and listed in `_ignored` |
| 1, 1, sources | 3 | F3 conflated Micrometer's two registries | Valid | Legacy registry recorded at stage 2 |
| 1, 1, sources | 4 | S3 missed the routing discussion | Valid | Pull requests #77731 and #79384 added; refusing rather than ignoring stays unexplained |
| 1, 1, sources | 5 | F9 missed a cost of switching the tenant | Valid | Added as a historical cost, repaired |
| 1, 1, sources | 6 | S9 missed InfluxData's stated reason | Valid | The blog post added |
| 1, 1, sources | 7 | S7 missed Elastic's reason for `strict` | Valid | The 2.x guide added, marked historical |
| 1, 1, sources | 8 | F2 overstated the compile-time check | Valid | Zero-label `CounterVec` recorded |
| 1, 1, sources | 9 | F10 applied mass assignment too broadly | Valid | Limited to `fill()` |
| 1, 1, sources | 10 | S9 said an implicit bucket accepts anything | Valid | Corrected |
| 1, 1, sources | 11 | S6 missed the proposed warning's limit | Valid | Added |
| 1, 1, reasoning | 1 | Weaviate, a close comparable that rejects, was missing | Valid | S11 added |
| 1, 1, reasoning | 2 | S2 treated substitution as removal | Valid | Reworded: the tenant is replaced |
| 1, 1, reasoning | 3 | S7 said surplus values were removed | Valid | As sources 2 |
| 1, 1, reasoning | 4 | Elasticsearch `strict` was called a default | Valid | Default and configured rejection split |
| 1, 1, reasoning | 5 | F2 overstated the compile-time check | Valid | As sources 8 |
| 1, 1, reasoning | 6 | F4 missed OTEP 0126's cardinality motive | Valid | Added |
| 1, 1, reasoning | 7 | S9's claim about implicit schemas was false | Valid | As sources 10 |
| 1, 2, sources | 1 | S1 missed the Capsule security advisory | Valid | Added as a downstream controller's cost |
| 1, 2, sources | 2 | S9 missed the rejection unit and timing | Valid | Added; late rejection under explicit schemas marked Unverified |
| 1, 2, sources | Suspicion | SPARK-16033 near S4 | Recorded | Added as an adjacent API that informs only |
| 1, 2, reasoning | 1 | S7 called an added option a reversal | Valid | Corrected: the index default still rejects |
| 1, 2, reasoning | 2 | As sources 2 | Valid | Merged with sources 2 |
| 1, 2, reasoning | 3 | F13 treated search-path fallback as routing | Valid | django-tenants and Apartment told apart |
| 1, 2, reasoning | Suspicion | S2's unsourced "small install" reason | Valid | Replaced by what Cortex's authors said |
| 2, 1, sources | 1 | "No reversal removed a signal" was false | Valid | The synthesis now records both directions |
| 2, 1, sources | 2 | A reason was attributed to Hibernate that it did not state | Valid | Claim 2 corrected |
| 2, 1, sources | 3 | Pulumi's complaint was reported without its resolution | Valid | Its won't-fix close and pull request #538 added |
| 2, 1, sources | 4 | The fit called the Kubernetes clear an accident | Valid | Back to "no stated rationale" |
| 2, 1, sources | 5 | S7's constraint inverted the shared-stream risk | Valid | Corrected |
| 2, 1, sources | 6 | F12 missed Rails' logging override | Valid | Added, with its stated why; informs only |
| 2, 1, sources | 7 | S2 overstated Loki's proxy requirement | Valid | Corrected |
| 2, 1, sources | Suspicion | F4 "nothing is counted" outran the source | Valid | Narrowed to what the specification requires |
| 2, 1, reasoning | 1 | A2 can let a wrong write replace correct keyed state | Valid | Third mistake added; claim 2 qualified; question put to the maintainer; A2 kept |
| 2, 1, reasoning | 2 | B and C relied on rule order | Valid | Mutually exclusive guards given |
| 2, 1, reasoning | 3 | As sources 1 | Valid | As sources 1 |
| 2, 1, reasoning | 4 | The fit dropped Elasticsearch's telemetry-template default | Valid | Restored |
| 2, 1, reasoning | 5 | A1 was compared without its fake-core flag | Valid | A1 now weighed against rather than ruled out |
| 2, 1, reasoning | 6 | As sources 4 | Valid | As sources 4 |
| 2, 1, reasoning | 7 | As sources 7 | Valid | As sources 7 |
| 2, 1, reasoning | Suspicion | InfluxDB's late rejection was stated as fact in the summary | Valid | Marked Unverified there too |
| 2, 2, sources | 1 | The S7 fit made shared streams a prerequisite of Elasticsearch's reason | Valid | Corrected in five places. S7 still informs, on two misfits that hold: a resource cap, and an unknown field |
| 2, 2, sources | 2 | F3 said Micrometer's current registry rejects only a type mismatch | Valid | Reworded, with the v1.18.0 source |
| 2, 2, sources | 3 | F9 made django-multitenant's guard unconditional | Valid | Its conditions stated, with the source line |
| 2, 2, sources | Suspicion | SPARK-16033's comments could not be opened | Not a finding | Verified through the Jira REST API |
| 2, 2, reasoning | 1 | A kept wrong row can take the last queue place from a correct row | Valid | Added to A's costs and to claim 2 |
| 2, 2, reasoning | 2 | B's signal is ambiguous, not wrong | Valid | Reworded in five places. C over B is now a weighed trade-off |
| 2, 2, reasoning | 3 | A2 and C are equally visible only for otherwise accepted writes | Valid | Qualified |
| 2, 2, reasoning | 4 | The host log is not guaranteed to reach a developer | Valid | Claim 1 qualified, citing `StandardFacade` |

**Open points.** No review finding is left open: all 44 numbered findings, and the suspicions, were applied or settled. What remains is for the maintainer, and is stated in the research file:

- Claim 2 of the recommendation rests on the researcher's own argument.
- One question is put to the maintainer, on tenant-free keyed state tables. Its answer could turn the recommendation to C.
- The proposed wording was not run through the pinned checker.
- Every round's fixes passed the quotation checks. The first key moment's second-round fixes were reviewed again by the second key moment's first round. The second key moment's second-round fixes, and the last edits made after the advisor's read of the whole file, were not reviewed by anyone after they were applied.

### Gates and files

- **Baseline**, at `196156c`. The first runs failed on this fresh worktree:
  - the tools were missing, until `just sync` and `just install-allium` ran;
  - markdownlint failed on `notes_2.md`, until its owner fixed it;
  - `fuzz-build` failed, until `just install-tools` ran with the user's authorisation.

  Then:

  > All checks passed and the worktree is unchanged.

- **Final**, at `671f32f`, the research file and this hand-back as reviewed and fixed. The commit that records this line changes only the line itself.

  > All checks passed and the worktree is unchanged.

- **Changed files:** `git diff main --stat` shows only this ticket and its research file. The specification is unchanged, and open question 19 is still in it. No code was added.
- **`git status --short`** shows only `?? notes_2.md`, the user's own file, which this ticket did not touch.

### Acceptance

- [x] At least three comparables at each level, read from official documentation or source: eleven at the system level, thirteen at the framework level.
- [x] What happens to each write, and whether and how the mismatch is visible.
- [x] Every claim linked with the date read, and "Unverified" where no primary source confirmed it.
- [x] Every field under "Citing a comparable" recorded for each comparable, with fit in its own section.
- [x] Comparables that chose otherwise, with their why.
- [x] Which behaviour surprises least and why, labelled as the researcher's view where it is one, and the options the settled promises rule out.
- [x] The options with their trade-offs and where each is counted, and one recommended with its reasons.
- [x] The recommendation rests only on comparables with a stated why and a fit argument, names them, and marks the rest as informing.
- [x] Proposed wording for the recommended option, and for C.
- [x] Written to the research file, summarised here, and committed.
- [x] Adversarial review at both key moments, with reviewers that opened the sources; every finding listed above.
- [x] Question 19 still open, no other tracked file changed, and no code added.
