# 02: Research: a tenant named for a tenant-free table

**What to build:** The maintainer can decide open question 19 of the proposed client specification from evidence. The question reads: "What happens to a write that names a tenant for a tenant-free table: stored without a tenant and counted, or refused? Until decided, this module gives that write no outcome beyond the promises every write has: it does not fail, it does not block, and no tenant is stored for a tenant-free table." This ticket delivers a survey from primary sources, the options it supports with their trade-offs, a recommendation, and proposed wording for the specification. It decides nothing: question 19 stays open until the maintainer closes it.

The case is narrow. A client handle's bound tenant is simply not applied to a tenant-free table, and that is ordinary: a unit of work for one tenant may also record a platform row. The question is only about a single write that names a tenant itself, for a table declared tenant-free.

The two answers put to the maintainer during the elicitation, neither chosen:

- Store the row without a tenant and count the mismatch, so that it shows in the diagnostics.
- Refuse the row whole and count it as invalid, like a row with an unknown column.

The maintainer's note, verbatim:

> We should think this through, maybe do some research on similar systems and consider what would be the least surprising, most expected option. Consider other comparables both at the broader system level, but then also at the framework and client level.

The survey looks at what comparable systems do when a write carries a scope its target does not have, at the two levels the maintainer named:

- The broader system level: multi-tenant data stores and telemetry back ends.
- The framework and client level: multi-tenancy libraries for web frameworks and object-relational mappers, and telemetry client libraries given an attribute or label the target does not declare.

What is already settled, and is not reopened here:

- Every write never fails and never blocks.
- A tenant-free table never stores a tenant.
- No row is attributed to a tenant that was not explicitly bound.
- Every row the client loses while its process lives is counted exactly once.
- A row that does not fit its table (a missing required column, an unknown column, a wrong type) is refused whole and counted. Nothing is converted.

Standing guidance from the same elicitation: where practice exists, follow it rather than invent.

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The survey covers at least three comparables at the broader system level and at least three at the framework and client level, each read from its official documentation or source code
- [ ] For each comparable the findings state what happens to the write (stored without the scope, refused, raised as an error, or stored with it), and whether and how the mismatch is made visible
- [ ] Every claim cites its source, and anything no primary source confirmed is marked "Unverified"
- [ ] The findings say which behaviour surprises a developer least and why, and which options the settled promises above rule out
- [ ] The options are listed with trade-offs, including where each would be counted in the diagnostics, and one is recommended with its reasons
- [ ] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [ ] The findings, options, recommendation and proposed wording are appended to this ticket under a "Hand-back" heading
- [ ] Question 19 is still open in the specification, no tracked file is changed, and no code is added
