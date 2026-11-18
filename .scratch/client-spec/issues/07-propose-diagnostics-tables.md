# 07: Propose diagnostics tables

**What to build:** Someone debugging a failing instance can read the client's own health from tables the client keeps, after the process that wrote them has gone. This ticket delivers diagnostics tables as a proposal in the client specification. It adopts nothing and adds no code.

What the specification proposes today: two channels and no tables. An in-process diagnostics snapshot gives counters per table, the run's state, and the confluence-wide discards. The host's logs get structured records under the client's own logger name, at warning level for lost data. Nothing about the client's health survives the pod except what the host application logged. Both channels stay as they are.

The maintainer's notes from the elicitation, verbatim:

> I do like in general the idea of a diagnostics table(s).

> Lets try to make sure that these tables + Any other diagnostic or status tables that would help us to debug a failing system at a high level? Let's try to make sure that they are well bounded and never grow beyond a fixed size that's reasonably sized, preferably smaller is better while still containing sufficient data. And then let's also look to see if we can pre allocate space on disk or whatever for these tables so that even if the disk fills up, we can keep rewriting to the same place. Let me know if this is possible and if it works even in the cloud environment like Google's GKE.

The requirements that follow, as recorded in the approved plan:

- Bounded: the tables never grow beyond a fixed size.
- Small: the smallest size that still holds enough to debug a failing system at a high level.
- Space reserved up front where the platform allows, so the tables can still be rewritten in place when the disk is full.
- Candidate contents: counters, recent events and run info.

The MVP was chosen without these tables partly because it needs no reserved namespace and no special case in storage. The proposal must say whether the tables need either.

Findings on reserving disk space, from a survey of official documentation run during the elicitation. "Unverified" marks what no primary source confirmed. Check them again before building on them:

- Reserving is possible, with conditions. Linux `fallocate` guarantees that later writes into the reserved range "will not fail because of lack of disk space".
- A file created in the container or on an `emptyDir` volume is overwritten in place on the node's disk.
- The guarantee does not hold on copy-on-write filesystems: ZFS, btrfs, reflinked XFS and APFS.
- A reservation never prevents the kubelet evicting a pod over its ephemeral-storage limit.
- Unverified: that GKE node disks are ext4.
- Unverified: the behaviour on network and FUSE volumes.

The proposal must say:

- Which tables exist and what each holds, with a fixed bound for each and what is overwritten at the bound.
- Whether they are handed to a collector like any other table, and whether a row in them has a position and a tenant.
- Who writes them. If the data writer does, the proposal says what is recorded when the data writer is failing or stopped, which is when they are most needed.
- What is promised where the platform cannot reserve space, and how the host application learns which case it is in.
- That writing them never blocks or fails a write, and never harms the host application.

Related entries, by number and gist. Do not resolve them:

- Open question 8: what bounds the local databases when no collection happens, and what is lost at the bound.
- Open question 6: what establish does with local databases a previous run left in the same location.
- Open question 22: when a kind of failure counts as stopped, and whether unattributed rows and the confluence-wide discards are logged.
- Open questions 9 and 10: what a namespace promises, and whether there is a default namespace.
- The open-decisions register's Product entry on how the client reports its own failures to the host application. It leaves the register only when a decision record answers it, and that record is the maintainer's to make.

**External precondition:** The local databases' on-disk format, which is undecided. The specification says only that the on-disk form is private to the client, and neither its numbered open questions nor the open-decisions register names the format as an entry. Bounding a table to a fixed size and rewriting it in place depend on that format, so this ticket waits for the maintainer to decide it.

**Blocked by:** None in this set.

**Status:** deferred until after the MVP

- [ ] The behaviour is elicited with the maintainer before the specification changes
- [ ] The specification states it as a proposal; anything unconfirmed is marked "Derived" or recorded as an `open question`; no existing open question is resolved by the agent
- [ ] The diagnostics snapshot and the host logs stay as proposed, so nothing already proposed changes meaning
- [ ] Each diagnostics table has a fixed bound, and the proposal says what is overwritten when it is reached
- [ ] The proposal names what each table holds and shows, with one failing-system scenario traced through it, that the contents are enough to debug at a high level
- [ ] The proposal says where space is reserved up front, what is promised where the platform cannot reserve it, and carries the disk-reservation findings with each "Unverified" mark either confirmed from a primary source or kept
- [ ] The proposal says what is recorded when the data writer is failing or stopped
- [ ] Writing the diagnostics tables never blocks or fails a write, and every row the client loses is still counted exactly once
- [ ] The register's entry on reporting failures is left for a decision record; the proposal does not close it
- [ ] Handbook text that restates the specification (the glossary, and the count of open questions) is updated in the same change
- [ ] `just check-specs` and `just analyse-specs` report zero diagnostics and zero findings, and `just check` ends green
- [ ] No code is added
