# 18: Carry ticket 14's answers into the specification

**What to build:** The specification states the basis of its two host-log guarantees as the maintainer gave it, and records as open questions the three points about them that the maintainer left open. Ticket 14 researched both guarantees and handed back findings without editing the specification. This ticket takes the maintainer's answers to that hand-back into `docs/specs/transect-client.allium`. It changes the basis the specification gives and adds open questions. It changes no behaviour, resolves no open question and adds no code.

What the specification proposes today, on the surface `HostLog`:

- **`StandardFacade`.** Records go through the language's standard logging facade, under the client's own logger name. The client installs no handlers. Records are structured, and lost data and dropped tenants are logged at WARNING.
- **`OnsetThenTotal`.** The first occurrence of a kind of failure for a table is logged at once. Nothing more is logged for that kind and table until it stops or establish ends, when one record gives the total. The rules are `OpenFailureEpisode`, `LogOnset`, `CountIntoEpisode`, `ReportEpisodesAtEnd` and `LogTotal`.

What ticket 14 found, in `research/14-a-library-logging-its-own-failures.md` and its hand-back:

- Onset-then-total is one library's rule among the twelve read: OpenTelemetry Rust's, in its default batch processors, for a full queue only. No source gives a reason for holding the total until the end, nor for applying the rule to all six kinds of failure. Its verdict: no stated why, as the specification applies it.
- `StandardFacade` rests on a stated why that fits this client: the guidance written for libraries. Its clause on dropped tenants, judged on its own, rests on no stated why.
- "The language's standard logging facade" has no referent in Rust, where `log` and `tracing` are both de facto facades.
- "Installs no handlers" leaves unsaid whether a `NullHandler` counts. The Python HOWTO allows one, and once one is attached Python no longer prints WARNING and above to standard error when the host has configured nothing.

The maintainer's answers to ticket 14's hand-back, given on 2026-11-24, verbatim as the options they chose and the note they added:

- **On what basis was onset-then-total chosen?** "OTel Rust's rule, adopted". The option read: "Chosen knowingly as OTel Rust's queue-full rule, then extended to all six failure kinds. The basis would name that library instead of saying 'common practice'."
- **Which Rust facade does the specification mean?** "Leave it open".
- **Does adding a `NullHandler` break the 'installs no handlers' rule?** "Leave it open".
- **What is the basis for WARNING on a dropped tenant?** "Reconsider the level", with the note "Leave as an open question.."
- **Where should these be recorded?** In ticket 14's hand-back, and in a new ticket that carries the three questions and the basis wording into the specification later. This is that ticket.

The change must:

- State `OnsetThenTotal`'s basis as OpenTelemetry Rust's queue-full rule, adopted by the maintainer and extended to every kind of failure, in place of any wording that rests it on common practice. Ticket 14's proposed wording, under "Verdicts" in its research file, is the starting text. Say plainly that the time of the total and the extension to the other five kinds have no stated why from any source.
- State `StandardFacade`'s basis as the guidance written for libraries, the Python logging HOWTO and the `log` and `tracing` crates, and not as common practice.
- Add three `open question` entries, each with its "Until decided" clause keeping today's behaviour:
  - which Rust facade "the language's standard logging facade" means;
  - whether attaching a `NullHandler` counts as installing a handler;
  - at what level a dropped tenant is logged, which is WARNING until decided.
- Put the basis wording where the specification's comments sit beside each guarantee. `CONTEXT.md`'s survey line is not edited by a ticket; if the maintainer wants it changed, raise it with them.

Related open questions, by number and gist. Do not resolve them:

- 22: when a kind of failure for a table counts as stopped, and whether unattributed rows and the confluence-wide discards are logged.

**Research file:** none. This ticket cites no system beyond what ticket 14's research file records. Cite that file for every claim about another library.

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the conformance and breakage lenses, at two key moments: after the specification is edited and before the first `just check`; and before hand-back. Questions to put to the reviewers:

1. Does each change match the maintainer's recorded answers above, and is anything the agent filled in marked "Derived"?
2. Does any edit change behaviour, a level, or a rule, rather than only the stated basis and the list of open questions?
3. Does each new open question's "Until decided" clause keep exactly what the specification does today?
4. Does any edit quietly answer open question 22, or one of the three new questions?

**Blocked by:** ticket 14, whose hand-back carries the answers.

**Status:** ready-for-agent

- [ ] The basis of `OnsetThenTotal` names OpenTelemetry Rust's queue-full rule, adopted by the maintainer, and says that the time of the total and its extension to the other kinds have no stated why
- [ ] The basis of `StandardFacade` names the guidance written for libraries, not common practice
- [ ] Three open questions are added: the Rust facade, `NullHandler`, and the level for a dropped tenant; each "Until decided" clause keeps today's behaviour
- [ ] No behaviour, level or rule changes, and no existing open question is resolved by the agent
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No code is added
