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

- [ ] The survey covers at least three comparables at the broader system level and at least three at the framework and client level, each read from its official documentation or source code
- [ ] For each comparable the findings state what happens to the write (stored without the scope, refused, raised as an error, or stored with it), and whether and how the mismatch is made visible
- [ ] Every claim cites its source with a link and the date read, and anything no primary source confirmed is marked "Unverified"
- [ ] For each comparable the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] The findings say which behaviour surprises a developer least and why, and which options the settled promises above rule out
- [ ] The options are listed with trade-offs, including where each would be counted in the diagnostics, and one is recommended with its reasons
- [ ] The recommendation rests only on comparables that have a stated why and a fit argument, and names them; any other comparable it mentions is marked as informing only
- [ ] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [ ] The findings, options, recommendation and proposed wording are written to the research file; a "Hand-back" section appended to this ticket summarises them and points to it, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] Question 19 is still open in the specification, no tracked file other than this ticket and its research file is changed, and no code is added
