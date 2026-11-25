# 08: Propose fork and multi-process support

**What to build:** A host application that forks, or that runs more than one process against the same instance, can use the client in each process. This ticket delivers what a forked child and a second process may do as a proposal in the client specification, replacing "inert" and "refused". It adopts nothing and adds no code.

What the specification proposes today:

- One writer process per instance. The local database location is the instance. While a live process holds it, another establish on it fails loudly. A dead process's claim never blocks the next start.
- No fork support. A forked child's inherited confluence has no run and is inert: its writes are discarded and counted. Any establish of the production core in that child fails loudly, at any location.
- An accepted row lives in the memory of the process that wrote it.

The specification lists more than one process per instance, and fork support, under what it excludes.

The maintainer's notes from the elicitation, verbatim:

> Lets hold off for now on explicitly supporting forking, we want make sure we do not design the api in a way that will overly limit our options in the future but for now lets keep the initial implementation as simple as possible while still beeing sufficient and correct.

Asked what happens when a forked child of an established parent calls establish with a different location, the maintainer chose "Refused: a forked child stays inert", with this note:

> This should fail loudly. There can be only one writer process, Especially if we go with DuckDB.

On the local database location being the instance, with one writer process each:

> The sounds fine, but if we end up going with a pull model for collection, then this may not work. We may need to restrict it to one per "Container".

Standing guidance from the same elicitation: prefer coordination-free, or at least low-coordination, solutions. The common host is an ephemeral Kubernetes worker pod.

DuckDB is a leaning, not a decision, and what it allows more than one process to do was never checked. Ticket 17 checks it: if `.scratch/client-spec/research/17-platform-facts.md` exists, read it.

This is the coarsest ticket in the set, on purpose. Any slice would guess the process model, and that model is what open questions 1 and 17 decide. Split it once they are decided.

The proposal must say:

- What a forked child may do with an inherited confluence: write, establish, or neither, and where its rows go.
- Which process owns the data writer and the local databases, and what happens to the others' rows when that process dies.
- What a second process on the same instance may do, and whether the instance is still the local database location.
- How run ids and positions behave with more than one process, so that a collector still recognises a repeated row and positions still only increase within a run.
- What the diagnostics snapshot describes in each process.
- What stays true: a write never fails and never blocks, and every row lost while its process lives is counted exactly once.

Related entries, by number and gist. Do not resolve them:

- Open question 1: who keeps the one data writer alive once more than one process is supported.
- Open question 17: whether the one-process rule must hold per container if collection is a pull.
- Open question 23: whether a fake core may be established on an inherited confluence in a forked child.
- Open question 15: whether the hand-over is a push or a pull.
- Open question 7: which collector confirms positions when more than one reads an instance.
- The open-decisions register's Product entry on how the client behaves when the host application forks. It leaves the register only when a decision record answers it, and that record is the maintainer's to make.

**Ticket 16's findings:** `.scratch/client-spec/research/16-client-shape-and-failure-posture.md` bears on this ticket. Stated behaviour 3 leaves a question open for the maintainer: is a forked child's copy of a confluence one that has turned the client off, or one whose writes were meant to be recorded? The maintainer left it open on 2026-11-24. "What the findings bear on" records what comparables do after a fork: Python's `logging` re-initialises its locks in the child (B1), `sentry-sdk` and OpenTelemetry Python start a new worker in the child (G5, G6), and `ddtrace` supports forked servers (G7). The file surveyed fork behaviour no further. Read it before starting. Its fits and verdicts are findings, not decisions: the maintainer has said they are not guaranteed to be applied, and they stay open for the tickets they bear on.

**Research file:** `.scratch/client-spec/research/08-fork-and-multi-process-support.md`, written only if the proposal cites another system. "Citing a comparable" in `CONTEXT.md` says what it records.

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the conformance and breakage lenses, at two key moments: after the maintainer's answers are recorded verbatim in this ticket's hand-back and before the specification changes; and before hand-back. Questions to put to the reviewers:

1. Were open questions 1 and 17 decided by the maintainer, in recorded words, before anything was proposed?
2. Is there a sequence of forks, second processes and process deaths in which a row is lost uncounted while its process lives, counted twice, or two processes write one location?
3. Are positions still unique and increasing within a run, and is a repeated row still recognisable, once more than one process is involved?
4. Is a leaning (DuckDB, a pull) treated as decided, is the register's entry on forking closed, or is open question 7, 15 or 23 quietly answered?

**External precondition:** Open questions 1 and 17, decided by the maintainer.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] Open questions 1 and 17 are decided by the maintainer before any proposal is written, and this ticket is split then if the decided model allows narrower tickets
- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] A host application that neither forks nor runs a second process sees the behaviour proposed today, so nothing already proposed changes meaning
- [ ] The proposal says what a forked child and a second process may each do, and which process owns the data writer and the local databases
- [ ] Positions are still unique and increasing within a run, and a repeated row is still recognisable to a collector
- [ ] Every row lost while its process lives is counted exactly once, in a place the proposal names, and no write blocks or fails
- [ ] The register's entry on forking is left for a decision record; the proposal does not close it
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] Any comparable the proposal cites has its stated why and its fit in the research file, as "Citing a comparable" in `CONTEXT.md` requires; a comparable without both informs the proposal and does not justify it
- [ ] The maintainer's answers are recorded verbatim in the hand-back before the first review; the adversarial review ran at each key moment as `REVIEW.md` says; and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No code is added
