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

- [ ] The survey covers at least four application logging frameworks or collection systems and at least three keyed-state systems, each read from its official documentation or source code
- [ ] For each system the findings state who stamps the time, whether the application may supply one, the field's name, and its precision and epoch
- [ ] Every claim cites its source with a link and the date read, and anything no primary source confirmed is marked "Unverified"
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] The findings say how each option sits with the settled monotonic clock within one process, and what an application-supplied time would do to that promise
- [ ] The options are listed with trade-offs, and one is recommended with its reasons, for time series tables and keyed state tables separately where they differ
- [ ] The recommendation rests only on comparables that have a stated why and a fit argument, and names them; any other comparable it mentions is marked as informing only
- [ ] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [ ] The findings, options, recommendation and proposed wording are written to the research file; a "Hand-back" section appended to this ticket summarises them and points to it, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] Question 11 is still open in the specification, no tracked file other than this ticket and its research file is changed, and no code is added
