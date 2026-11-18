# 17: Research the why: platform facts

**What to build:** The maintainer can rely on the facts about platforms that the specification and its tickets lean on, each with the mechanism that makes it true and the conditions under which it holds. These are facts about an operating system, a filesystem, an orchestrator and a database engine, not design choices to imitate. So "why" here means the mechanism, from a primary source, and "fit" means whether the conditions hold on the hosts this client expects. This ticket checks each fact again, confirms or keeps each "Unverified" mark, and follows "Citing a comparable" in `CONTEXT.md` where a source's authors explain a design. It delivers findings. It recommends no design, chooses no storage engine and does not edit the specification.

What leans on these facts today:

- **Ticket 07, diagnostics tables.** The maintainer asked whether space can be reserved up front so the tables can still be rewritten in place when the disk is full. Ticket 07 carries the findings below.
- **The one-writer rule.** The specification proposes one writer process per instance, and refuses establish in a forked child. The maintainer's note on that names DuckDB.
- **Open question 8.** The question was put with the claim that a pod over its ephemeral-storage limit is evicted.
- **The storage format.** `CONTEXT.md` records that the OTel Arrow posts do not settle the local databases' on-disk format.

Claims from the elicitation to check again. Each is recorded in `CONTEXT.md` with no link, so treat each as a claim, not a finding:

- Linux `fallocate` guarantees that later writes into the reserved range "will not fail because of lack of disk space".
- A file created in the container or on an `emptyDir` volume is overwritten in place on the node's disk.
- The guarantee does not hold on copy-on-write filesystems: ZFS, btrfs, reflinked XFS and APFS.
- A reservation never prevents the kubelet evicting a pod over its ephemeral-storage limit.
- A full disk on Kubernetes usually shows up as an eviction, not as a failed write. So reserved space helps when a neighbour fills the node, and not when the pod itself is over its limit.
- Marked "Unverified" at the time: that GKE node disks are ext4; the behaviour on network and FUSE volumes.
- The OTel Arrow posts (2024, 2025, 2026) treat Arrow as a wire and in-pipeline format. None covers on-disk storage, durability, shutdown or schema evolution. Their useful signals are bounded channels and memory, overload made visible, and larger batches compressing better.
- Never checked: that DuckDB allows only one writer process.

The maintainer's notes from the elicitation, verbatim. On diagnostics tables:

> And then let's also look to see if we can pre allocate space on disk or whatever for these tables so that even if the disk fills up, we can keep rewriting to the same place. Let me know if this is possible and if it works even in the cloud environment like Google's GKE.

On a forked child that calls establish with a different location:

> This should fail loudly. There can be only one writer process, Especially if we go with DuckDB.

DuckDB, GKE and the ephemeral pod are leanings, recorded in `CONTEXT.md` under "Leanings, not decisions". Nothing here treats one as decided.

What the research must find out:

- **Reserving space.** What `fallocate` promises and in which modes, quoted from its manual page, and why the promise fails on a copy-on-write filesystem, from each filesystem's own documentation.
- **Which filesystem a container writes to.** A container may write to its writable layer, to an `emptyDir`, or to a mounted volume. For each, name the filesystem underneath and say whether a write into a reserved file there is in place. The earlier survey did not separate these.
- **Eviction.** How the kubelet measures a pod's ephemeral storage, whether a reserved but unwritten file counts, what triggers an eviction, and what the pod's processes see when it happens. Quote the Kubernetes documentation.
- **GKE.** Which filesystem GKE node disks use, from Google's documentation, for each node image if they differ. If the documentation does not say, keep the "Unverified" mark and say where was looked.
- **Network and FUSE volumes.** What reserving space means on each, or that no primary source says.
- **DuckDB's concurrency.** What DuckDB documents about more than one process opening a database, the reason its authors give, and what they say about a process that forks. Record the same for one other embedded engine as a contrast. This checks a fact behind a leaning. It does not weigh engines.
- **The OTel Arrow posts.** Their links were not kept. Identify the posts with confidence before citing them; if that cannot be done, say so and ask the maintainer for the links. Then check the claims above, and capture why their authors chose Arrow for the wire and what they say about bounding memory.

Where a fact turns out wrong, or holds only under a condition the specification or ticket 07 does not state, report it in the research file with proposed wording for the maintainer. Do not change the specification or ticket 07.

Related entries, by number and gist. Say what the evidence bears on each. Do not resolve them and do not recommend an answer:

- Open question 8: what bounds the local databases when no collection happens, and what is lost at the bound.
- Open question 17: whether the one-process rule must hold per container if collection is a pull.
- Ticket 07, on diagnostics tables. It reads this ticket's research file if the file exists.
- Ticket 08, on fork and more than one process. It reads this ticket's research file too.
- The local databases' on-disk format, which is undecided and is not an entry on any register.

**Research file:** `.scratch/client-spec/research/17-platform-facts.md`

**Adversarial review:** Follow `.scratch/client-spec/REVIEW.md` with the sources and reasoning lenses, at two key moments: after the findings are drafted in the research file and before any fit verdict is written; and before hand-back. The reviewers need the same web authorisation as this ticket. Questions to put to them:

1. Does each primary source state the mechanism and its conditions as the file reports them, and is each "Unverified" mark either confirmed with a link or kept with where was looked?
2. Is each claim about the filesystem a container actually writes to (its writable layer, an `emptyDir`, a mounted volume), or about a different layer?
3. Is DuckDB, GKE or a pull treated anywhere as decided, when each is a leaning?
4. Does the file recommend a design to ticket 07 or 08, choose an engine, or imply an answer to open question 8 or 17?

**External precondition:** Web research must be authorised in the session that picks this up. Nothing else gates it.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [ ] Each of the two "Unverified" marks is either confirmed from a primary source or kept, with where was looked
- [ ] For each fact the file gives its mechanism and the conditions under which it holds, and says which of those conditions hold on the hosts `CONTEXT.md` records as leanings
- [ ] The file separates a container's writable layer, an `emptyDir` and a mounted volume, and says for each whether a reserved file is rewritten in place
- [ ] The file reports what DuckDB documents about more than one writer process and why, with one other embedded engine as a contrast, and weighs no engine against another
- [ ] The OTel Arrow posts are identified with their links, or the file says they could not be and the maintainer is asked
- [ ] Where a source's authors explain a design, the file records the fields under "Citing a comparable" in `CONTEXT.md`
- [ ] The file says what the evidence bears on open questions 8 and 17 and recommends an answer to neither; both are still open in the specification, and ticket 07 is unchanged
- [ ] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [ ] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [ ] No tracked file other than this ticket and its research file is changed, and no code is added
