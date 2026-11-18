# 01: Research: who stamps a row's time

**What to build:** The maintainer can decide open question 11 of the proposed client specification from evidence instead of from instinct. The question reads: "Is a row's time stamped by the client only, or may application code supply it, and what are its name and precision? Until decided, the client stamps every accepted row." This ticket delivers a survey from primary sources, the options it supports with their trade-offs, a recommendation, and proposed wording for the specification. It decides nothing: question 11 stays open until the maintainer closes it.

The survey covers two families, as the maintainer asked:

- For time series tables: application logging frameworks and collection systems.
- For keyed state tables: comparable keyed-state systems.

For each system it reports who stamps the time (the library, the application, the receiver, or more than one of them, each under its own name), whether application code may supply or override a time, what the field is called, and its precision and epoch. It also reports what each system does when a supplied time is in the future, in the past, or out of order.

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

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The survey covers at least four application logging frameworks or collection systems and at least three keyed-state systems, each read from its official documentation or source code
- [ ] For each system the findings state who stamps the time, whether the application may supply one, the field's name, and its precision and epoch
- [ ] Every claim cites its source, and anything no primary source confirmed is marked "Unverified"
- [ ] The findings say how each option sits with the settled monotonic clock within one process, and what an application-supplied time would do to that promise
- [ ] The options are listed with trade-offs, and one is recommended with its reasons, for time series tables and keyed state tables separately where they differ
- [ ] Proposed wording for the specification is given for the recommended option, as text for the maintainer to accept or change
- [ ] The findings, options, recommendation and proposed wording are appended to this ticket under a "Hand-back" heading
- [ ] Question 11 is still open in the specification, no tracked file other than this ticket is changed, and no code is added
