# 16: Research the why: client shape and failure posture

**What to build:** The maintainer can see whether what the agent said about idiom and usual practice, when the client's shape and failure posture were settled, is true, and why the libraries it named are built as they are. No survey was run for any of it: every claim below came from the agent's own knowledge. This ticket checks each claim for the first time, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

The shape itself is the maintainer's design and is not reopened here. What is under test is the agent's account of other libraries, which the maintainer relied on.

What the specification proposes today, and what it was said to rest on:

- **A confluence, establish and a client handle.** A confluence is created at global scope and tables are declared against it. Establish is a top-level block that gives the confluence a core for its duration: the production core, or a fake core in tests. Application code opens a client handle for one unit of work. The maintainer proposed this shape and asked whether it is idiomatic Rust. The agent answered that it is.
- **The failure posture.** Declaring a table and establish may fail loudly. Opening a client handle and every write never fail and never block, and a write returns nothing. The maintainer delegated this choice, and the agent chose it as "the usual posture of observability libraries".
- **Inert without establish.** With no establish in force, writes are discarded and counted, and nothing fails.
- **The establish block owns the data writer.** The agent framed the lifetime questions with structured concurrency: every background activity lives inside a scope that someone visibly opens and closes.
- **The fake core.** A test establishes a fake core, which records every write with its outcome. The specification marks its rules "Derived".

Claims to check for the first time. Each came from the agent's own knowledge:

- The shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests".
- A Python `with` block maps to a Rust guard value or a closure scope.
- Observability libraries usually let set-up fail loudly and never let a call on the serving path fail or block.
- Structured concurrency says every background activity lives inside a scope that someone visibly opens and closes.

The maintainer's notes from the elicitation, verbatim. Asked who starts and ends the client:

> A mix of this and option1. Have a "Confluence" object created at the global scope. It is then used within the application code to request the client via a factory-ish method (with block in python). Then at the different top level contexts the Confluence is configured with either the production core (which links to the writer) or a fake in the context of tests. Let me know if this does or does not feel like idiomatic Rust. If it doesn't feel like idiomatic Rust, then we can just focus on the Python client for now, or we can just consider this overall approach for something that can be idiomatic for both. Or maybe if full threading explicit is more idiomatic for Rust, but then we could still build something like this for Python based on that, we could consider that as well.

Asked which calls may fail loudly and which must be swallowed and counted:

> Whatever option is most idiomatic while also within those boundaries, what's considered idiomatic, normal, and acceptable, whatever will allow for the most, the best developer experience and the best operator experience.

The maintainer made the Rust answer a condition: the note offers other courses if the shape does not feel idiomatic. So a claim that fails here matters, and is reported plainly.

What the research must find out, beyond the fields every comparable gets:

- **The Rust facades.** For each of the `log`, `tracing` and `metrics` crates, check each of the three parts of the claim separately: a global entry point, a backend installed at the top level, and a scoped override for tests. The claim may hold for some crates and not for others. Capture why each crate's authors chose a global facade, what they say it costs, and what they say about tests.
- **Python logging.** How the standard library's logging is shaped along the same three parts, and why.
- **OpenTelemetry's split.** Why OpenTelemetry separates an API from an SDK, what the API does when no SDK is installed, and what its specification says about errors. This bears on "inert without establish" and on both halves of the posture.
- **Both halves of the posture.** The claim has two halves and neither was checked: that set-up may fail loudly, and that the serving path never fails or blocks. Find libraries that swallow set-up failures too, and libraries whose serving path can raise or block, and capture why.
- **Structured concurrency.** Where the idea was stated by those who introduced it and by the languages that built on it, what it promises, and what it says about a background worker that outlives or dies inside its scope.
- **Fakes for tests.** What comparable libraries give a test to capture what was recorded, and whether any promises that the fake applies the same rules as the real thing.
- **A comparable that chose otherwise**, with its why: for example a library that passes its client explicitly and has no global, or one that raises on the serving path.
- **The names, for open question 18.** What "confluence", "establish" and "core" already name elsewhere, including the well-known product called Confluence. These are facts for the maintainer, not comparables, and need no why.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related entries, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- Open question 18: whether confluence, establish and core are the final names.
- The "Derived" statements about the fake core, nested establish and a handle shared between threads. Ticket 11 puts them to the maintainer. This ticket confirms none of them.
- The open-decisions register's Product entries. Each leaves the register only when a decision record answers it, and that record is the maintainer's to make.

**Research file:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Is each of the three parts of the facade claim checked for each of the three crates from documentation or source, and is every place it does not hold reported?
2. Are both halves of the posture claim checked, and were libraries that do otherwise looked for?
3. Does the file keep apart the maintainer's own design, which is not reopened, and the agent's claims about other libraries, which are under test?
4. Does the file recommend a name for open question 18, confirm a "Derived" statement, or close a register entry?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Each claim listed above is checked from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] The facade claim is checked part by part for each of the `log`, `tracing` and `metrics` crates, and the file says for which it holds
- [ ] Both halves of the failure-posture claim are checked, each against at least three libraries
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] For each stated behaviour above, the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [ ] Where a verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [ ] The file lists what the three names already mean elsewhere and recommends no name; open question 18 is still open in the specification
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
