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
- [ ] No code is added
