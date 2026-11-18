# 13: Research the why: store failure and data writer death

**What to build:** The maintainer can see why comparable libraries and agents treat a failed batch and a dead background worker as they do, and whether those reasons hold for this client. During the elicitation these systems were surveyed for what they do. Why they do it was not captured, and no link was kept. This ticket checks the what again, captures each why in its authors' own words, and argues the fit, following "Citing a comparable" in `CONTEXT.md`. It delivers findings. It recommends no answer to an open question and does not edit the specification.

What the specification proposes today, and what it was said to rest on:

- **A failed store drops its batch and the data writer carries on.** The rows are counted as lost, and the data writer reports itself as failing until a store succeeds. A failure handling one batch costs only that batch. The survey reported that in-process libraries drop and carry on.
- **No retry.** Until open question 12 is decided, a failed store drops its batch at once. The survey reported that pipeline agents retry within limits and then drop.
- **A dead data writer stays stopped.** A failure that escapes the handling of one batch stops the data writer. Until open question 14 is decided it stays stopped for the rest of the run, and the specification marks that "Derived". The survey reported that almost no library restarts a dead worker.
- **Containing panics.** The specification's guidance says that in Rust the handling of one batch must contain panics as well as errors. The survey reported that the Rust libraries it read do not.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- OTel SDK batch processors drop a failed export and carry on.
- Python logging handlers do the same. This one came from the agent's own knowledge and was never checked.
- Fluent Bit retries once by default, then drops.
- The OTel Collector retries while its queue fills, then drops.
- Prometheus remote-write retries for up to two hours.
- Seven libraries' worker loops were read from source: OTel Python, OTel Java, OTel Rust, tracing-appender, CPython's QueueListener, ddtrace and sentry-python. None restarts a worker a limited number of times.
- The usual pattern catches failures around handling one batch, logs, drops the batch and keeps looping. Anything that escapes that guard kills the worker for the life of the process.
- Only sentry-python restarts a dead worker: lazily, on the next submit, with no limit.
- The Rust libraries read do not contain panics.

The maintainer's notes from the elicitation, verbatim. Asked what happens to a batch whose store fails, and to the data writer:

> What do other similar systems do?

Asked what the establish scope does about a dead data writer:

> Look at other similar libraries and frameworks and see what they do and let me know. We still want to make sure that we pick the decision that's most well aligned with our client, our framework, and what we want and what we desire. But I think it's good to factor in what others have done before.

What the research must find out, beyond the fields every comparable gets:

- **Dropping a failed batch.** Why an in-process library drops a failed batch and does not retry or hold it. Their batch fails at an export over a network; this client's fails at a store on a local disk. Say whether each stated reason is about the network, or about being a guest inside a host application.
- **Retrying.** Why a pipeline agent retries, why each has the limit it has, and what the retry costs. A pipeline agent is a process of its own whose job is delivery; say which of its reasons carry over to a library inside an application.
- **Not restarting.** Whether leaving a dead worker dead is a decision its authors explained, or only something nobody wrote. Look in issue threads and pull requests for a request to restart and the maintainers' reply. "No stated rationale found" is a likely and valid result here.
- **Restarting.** Why sentry-python restarts its worker, and which failure the restart was written for. Check whether it answers a crash, a fork, or something else.
- **Panics.** Whether the authors of the Rust libraries say why a panic in the worker is not contained.
- **A comparable that chose otherwise**, with its why: for example an in-process library that does retry a failed batch, or one that restarts a worker with a limit.

Where a stated behaviour rests on a why that does not transfer to this client, or on no stated why at all, report it in the research file with proposed wording for the maintainer. Do not change the specification.

Related open questions, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- 12: whether a bounded retry comes before a failed batch is dropped.
- 14: whether a data writer that has died stays stopped or is restarted.

**Research file:** `.scratch/client-spec/research/13-store-failure-and-data-writer-death.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does the documentation, or the source at a named version, show the behaviour the file claims for each library, including each of the seven worker loops?
2. Is "does not restart" shown to be a choice its authors explained, or is an absence of code presented as a decision?
3. Does each fit argument face the differences: their batch fails at a network export and this one at a local store, and a pipeline agent is its own process while this client is a guest?
4. Does the file recommend or imply an answer to open question 12 or 14?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] Source code is cited at a named version or commit, for each of the seven libraries
- [ ] For each system the research file records every field under "Citing a comparable" in `CONTEXT.md`: the stated why quoted and linked, or "No stated rationale found"; any inferred why labelled "Inferred"; the constraints behind the choice; costs and dissent; and fit
- [ ] At least one comparable that chose otherwise is recorded with its why
- [ ] For the stated behaviour (a failed store drops its batch and the data writer carries on), the file gives one verdict: it rests on a stated why that fits this client, on a stated why that does not transfer, or on no stated why
- [ ] Where the verdict is not the first, the file gives proposed wording for the maintainer, and the specification is not edited
- [ ] The file says what the evidence bears on open questions 12 and 14 and recommends an answer to neither; both are still open in the specification
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
