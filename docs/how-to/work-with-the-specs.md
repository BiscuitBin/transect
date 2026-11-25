---
title: "Work with the specifications"
kind: "how-to"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["specification_workflow"]
requires: []
---

# Work with the specifications

`docs/specs/` holds Allium specifications. Today there is one module,
[`transect-client.allium`](../specs/transect-client.allium): the in-application client,
from declaring a table to handing stored rows to a collector.

## What the module is, and is not

The module is a proposal. It was elicited from the maintainer between 2026-11-15 and
2026-11-17, and its header says so. It is not a decision record, and nothing in it is
adopted: the client's design is still on the
[open-decisions register](../project/open-decisions.md), and no code implements it.

Three kinds of statement sit in it, and they carry different weight:

| Statement | Meaning |
| --- | --- |
| A rule, invariant or guarantee with no marker | What the maintainer answered, during the elicitation or since. |
| A comment that says "Derived" | Follows from those answers but was never put to the maintainer directly. Confirm it before building on it. |
| An `open question` | Nobody has decided. Where it says "Until decided", that behaviour holds in the module in the meantime. |

The module opens with Scope, Includes, Excludes and Vocabulary. Read the whole module
before editing it. A behaviour listed under Excludes belongs outside it.

## Change the module

1. Use the `tend` skill for an edit and the `elicit` skill for new behaviour. State the
   rule, its trigger, its guards and its outcomes.
2. Mark anything the maintainer has not confirmed as "Derived", or record it as an
   `open question`.
3. Run `just check-specs`, then `just analyse-specs`. Fix every diagnostic and finding
   at its root.
4. Update the [glossary](../project/glossary.md) when a term is added or renamed.
5. Run `just check-docs`, then `just check`.

## Handle an open question

The module carries 24 open questions, numbered in its last section. A decided
question's number is not reused, so the numbers have gaps. None is permission to choose
an answer in code or in another rule.

- If a change depends on an unanswered question, raise it with the maintainer.
- If a new gap appears, add an `open question` rather than guess.
- When a question is decided, state the decision in the module and remove the question
  in the same commit. If the decision also answers an entry on the open-decisions
  register, a decision record closes that entry.

## Lean on another system

A rule may be proposed because another system behaves that way only when two things are
written down beside the proposal. The first is the reason that system's own authors
gave, quoted and linked from a primary source. The second is an argument that the
constraints behind that reason also hold for this client. What the other system does is
checked from a primary source when it is cited, with the link and the date. A reason
the writer worked out, and no author stated, is labelled "inferred": it may inform a
proposal and does not justify one. "No stated reason found", with where was looked, is
a valid result. Each ticket under `.scratch/client-spec/` writes these findings to a
research file of its own, and `CONTEXT.md` there gives the rule in full.

## Tooling

The checker is the `allium` binary from `juxt/allium-tools`, version 3.6.1, pinned and
checksummed by the tooling package and installed into the gitignored `.tools/bin/`
([decision 0012](../decisions/0012-project-managed-allium-cli.md)). `just initialize`
installs it; `just install-allium` installs it on its own. Both reach the network.

`just check-specs` runs `allium check`, which reports syntax and reference
diagnostics. `just analyse-specs` runs `allium analyse`, which repeats those and adds
findings about reachability, deadlocks and conflicting rules. Both recipes run the
pinned binary by path, so use them and not another `allium` on `PATH`. A clean
`just analyse-specs` does not prove that every guard can be satisfied; read the rule.

## Diagnostics and waivers

Both recipes are gates in `just check`, and both run as hooks, so a commit that touches
`docs/specs/` is held to them. Every module must report an empty `diagnostics` array and
an empty `findings` array. The recipes read those arrays because neither exit code
means clean: `allium check` exits 0 on an `info` diagnostic, and `allium analyse` exits 0
on a module that carries diagnostics.

A finding cannot be waived. A diagnostic can be waived only when the diagnostic itself
is wrong, meaning the construct is valid Allium that the pinned checker cannot resolve:

```text
-- Why the checker is wrong here, in a sentence.
-- allium-ignore allium.field.unused
```

The directive is a whole-line comment that holds the diagnostic code and nothing else,
and it covers only the line beneath it. Prose on the directive line disables it, so the
reason goes on the line above. Upstream documents none of this; it was verified against
3.6.1 on 2026-11-17, and a waiver must be verified again whenever the pin moves. The
module carries no waiver.

### What the pinned checker does not see

Each of these was met while writing the module, at 3.6.1, and answered without a waiver:

- **A status change inside a `for` in an `ensures` block.** The checker reports the
  status as never assigned. Emit a trigger for each element and change the status in
  the rule that answers it, as `TakeBatch` and `TakeRow` do.
- **A status value that two entities share.** `open` and `closed` on two entities left
  one of them reported as never leaving `open`. The module gives each status field its
  own words.
- **A derived value read only in a `where` predicate.** It is reported as unused. Read
  it from an invariant that states something true, or write the predicate inline.
- **An `external entity` in a module with no `use` import.** It draws a warning, so the
  host process and the collector are plain entities that no rule creates.
- **A rule that answers a state change and sets a status another rule sets.** The
  analyser reports a conflict. The module makes the data writer's stop its own action
  for this reason.

## Related pages

- [Quality gates](../reference/quality-gates.md)
- [Open decisions](../project/open-decisions.md)
- [Glossary](../project/glossary.md)
- [Decision 0012: A project-managed Allium binary](../decisions/0012-project-managed-allium-cli.md)
