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

- [x] Each claim listed above is checked again from a primary source, with a link and the date read, or is marked "Unverified" with where was looked; a claim found wrong is reported as wrong
- [x] Each of the two "Unverified" marks is either confirmed from a primary source or kept, with where was looked
- [x] For each fact the file gives its mechanism and the conditions under which it holds, and says which of those conditions hold on the hosts `CONTEXT.md` records as leanings
- [x] The file separates a container's writable layer, an `emptyDir` and a mounted volume, and says for each whether a reserved file is rewritten in place
- [x] The file reports what DuckDB documents about more than one writer process and why, with one other embedded engine as a contrast, and weighs no engine against another
- [x] The OTel Arrow posts are identified with their links, or the file says they could not be and the maintainer is asked
- [x] Where a source's authors explain a design, the file records the fields under "Citing a comparable" in `CONTEXT.md`
- [x] The file says what the evidence bears on open questions 8 and 17 and recommends an answer to neither; both are still open in the specification, and ticket 07 is unchanged
- [x] A "Hand-back" section appended to this ticket summarises the findings and points to the research file, and both are committed
- [x] The adversarial review ran at each key moment as `REVIEW.md` says, with reviewers that could open the sources, and the hand-back lists every finding with its verdict, its resolution and the reviewing model
- [x] No tracked file other than this ticket and its research file is changed, and no code is added

## Hand-back

The work is in `research/17-platform-facts.md`, beside the issues folder. This section summarises it. The file reports and recommends nothing: open questions 8 and 17 are still open in the specification, and ticket 07, `CONTEXT.md` and the specification are unchanged.

### The maintainer's answers before the work

Given on 2026-11-24, before the work started:

- **Web research** is authorised for this ticket, for the author, its survey subagents and its Codex reviewers. It is read-only, and nothing was posted, filed or sent.
- **Network recipes:** `just sync`, `just install-allium` and `just install-tools` could run if the baseline needed them. It did not, and none was run.
- **Review model:** Codex with `gpt-6.2-sol` at both key moments. The maintainer named this model; it is not the `gpt-6-astra` that `REVIEW.md` prefers.

### Findings

Every source was fetched again by the author and pinned: source and documentation at a tag or commit, man pages by their man-pages release, vendor pages by their last-updated date. Every quotation was checked by script as a substring of that text: 358 quotations at the last check, none missing.

- **C1, the `fallocate` guarantee.** The substance holds for mode 0 and `KEEP_SIZE`, under conditions: on a local filesystem, the blocks are allocated and overwritten in place, and the range is not truncated or punched; on ext4 a write may still need metadata space to split the extent. On NFS only a v4.2 server's `ALLOCATE` makes the promise. The quotation is wrong: it is in none of the 224 man-pages releases, and the page says "are guaranteed not to fail because of lack of disk space".
- **C2, in place on the node's disk.** Holds only under conditions. A runtime file in the writable layer, or on a disk `emptyDir`, is on the filesystem that holds containerd's or the kubelet's root; a file from an image layer is copied up first; a memory `emptyDir` is tmpfs, where a reservation is memory.
- **C3, copy-on-write.** ZFS emulates mode 0 and reserves nothing, and its authors say why. btrfs holds in part: a preallocated extent's first write, or a `NOCOW` file, goes in place only while no snapshot, taken or pending, or other reference shares the extent and the kernel's other checks pass, and still needs metadata space. XFS with reflink fails only for shared blocks. APFS is Unverified.
- **C4, eviction.** Confirmed where the kubelet measures local ephemeral storage and the pod is not critical, and stronger: on ext4 a reservation counts towards the measured usage wherever the kubelet's scan or quota sees it, so it can bring an eviction nearer (Inferred from source). Google's 2023 Local SSD post states the measuring for its option; elsewhere on GKE it is Inferred.
- **C5, "usually an eviction".** No source says it, and KEP 1029 says a pod can fill the partition first. The rest holds under P7's conditions.
- **C6, GKE ext4.** Partly sourced: two COS release notes, the image layout of one COS build GKE ships, and a 2023 Google post on Local SSD name ext4. The Ubuntu image, the newer Local SSD layout and image streaming's writable layer stay Unverified, with where was looked.
- **C7, network and FUSE.** Now sourced: Filestore returns `EOPNOTSUPP` (Inferred from source), Cloud Storage FUSE does not implement `fallocate`, and a FUSE daemon decides for itself.
- **C8, the OTel Arrow posts.** Identified by content as the posts of 2024-09-25, 2025-05-12 and 2026-06-12 on opentelemetry.io. Every part of the claim holds.
- **C9, DuckDB's one writer.** Holds for a file opened directly, enforced on POSIX by an advisory record lock where the filesystem supports one, for the stated reason that state is cached in memory. A read-only open asks for a shared lock, so it too is refused while a writer holds the file (Inferred from source). The documentation says nothing on fork; DuckDB's two locking tests and the Python client's instance cache are recorded, and a child that keeps using an inherited instance is covered by no source. Quack and DuckLake route around the rule rather than break it. SQLite is recorded as the contrast and weighed against nothing.

The fit tables give, per condition, whether it holds on GKE Standard with the boot disk, GKE Standard with Local SSD, and Autopilot, with the Ubuntu image left Unverified. "What the findings bear on" reports on open questions 8 and 17, tickets 07 and 08, and the on-disk format, and resolves none.

### Proposed wording

Replacement text for ticket 07's six bullets on reserving disk space, and for three passages of `CONTEXT.md` (reserving disk space, the OTel posts, and the sentence that says DuckDB's rule was never checked). It is in the research file only, for the maintainer to accept, change or reject. The specification states none of these facts, so no wording is proposed for it.

### Adversarial review

Every review ran on Codex (codex-cli 0.172.0) with `gpt-6.2-sol`, the model the maintainer named for this ticket. `REVIEW.md` prefers `gpt-6-astra`; it was not used, on the maintainer's instruction. Each session header recorded the model. Every reviewer had a read-only sandbox and live web search under this ticket's authorisation. Every finding was triaged by a fresh Claude Code subagent on Claude Opus 5.5 (`claude-opus-5-5`), which was neither the author nor a reviewer.

Before the first review, a preflight confirmed that Codex ran `gpt-6.2-sol` and could open a URL. Each key moment ran two rounds, the most `REVIEW.md` allows. The review and triage files are under `ai_tmp/client-spec-review/17/`, which is not committed. Every valid finding was resolved; where the two triages proposed different wording for one passage, the author merged them, and the triage's one optional addition, an Arm-board COS layout, was not made. The sources each fix cites were fetched again by the author, and the quotation check passed after each round.

| Key moment, round, lens | # | Finding | Verdict | Resolution |
| --- | --- | --- | --- | --- |
| 1, 1, sources | 1 | Pod-limit eviction holds only where the kubelet measures; the scan and quota prerequisites were missing | Valid | Measuring condition added to P7, P9, C4 and C5, with the scan's blind spot and the quota prerequisites quoted |
| 1, 1, sources | 2 | P9's "with no eviction" missed a `hostPath`, which is node pressure | Valid | Narrowed to volumes on their own device; the `hostPath` passage quoted in P7 |
| 1, 1, sources | 3 | Google sources name ext4: COS release notes (m69, dev) and the 2023 Local SSD post | Valid | Added to P8 and P4; C6 now "Partly sourced"; question put to the maintainer |
| 1, 1, sources | 4 | Overlay copy-up need not write the whole file (clone, holes, `O_TRUNC`) | Valid | P4, summary row and C2 corrected, with `copy_up.c` quoted |
| 1, 1, sources | 5 | A memory-backed `emptyDir` has its own tmpfs size | Valid | `size=` from node allocatable, the pod's limit and `sizeLimit` added to P5 and the summary, with `ENOSPC` past it |
| 1, 1, sources | 6 | XFS implements `WRITE_ZEROES` at v7.3 | Valid | Attributed "ext4 only" to the 6.20 page; XFS dispatch and exclusions quoted |
| 1, 1, sources | 7 | The ext4 reserve is a changeable default, and a failed split has a zero-out fallback | Valid | P1 rewritten, with `sysfs.c` and `extents.c` quoted; what the application sees marked Unverified |
| 1, 1, sources | 8 | The btrfs summary dropped the shared-extent condition; the zoned quotation lacked its heading | Valid | Summary and C3 qualified; the zoned heading and the kernel's refusal quoted |
| 1, 1, sources | 9 | ZFS: 110% is a tunable's default, and mode 0 extends only past the end of the file | Valid | P3 corrected, with the code quoted |
| 1, 1, sources | 10 | glibc's stride is capped at 4096 with skips; Filestore NFSv4.1 depends on the GKE version and the tier | Valid | P2 and P6 corrected, with both passages quoted |
| 1, 1, sources | 11 | Quack first shipped in 1.5.3 and is beta | Valid | Added to P10 and the comparables, with the FAQ quoted |
| 1, 1, sources | 12 | The 2024 post's stated why for a synchronous path, and the cost of more streams | Valid | Both quoted in P13 |
| 1, 1, sources | Suspicion 1 | The Ubuntu, mixed Local SSD and per-image COS filesystems | Valid, folded into 3 | Kept Unverified, with where was looked |
| 1, 1, sources | Suspicion 2 | APFS overwriting unshared data in place | Invalid | Already marked Unverified in the file |
| 1, 1, sources | Suspicion 3 | The two OpenZFS #326 quotations | Invalid | Both verbatim through the API; triage also found "years earlier" wrong, now "eight months earlier" |
| 1, 1, reasoning | 1 | As sources 1, plus the unlinked-file blind spot | Valid | As sources 1; the counting inference now carries both conditions |
| 1, 1, reasoning | 2 | More usage does not by itself raise the rank; ranking depends on signal and layout | Valid | Ranking branches quoted; inference, P9 and C5 reworded |
| 1, 1, reasoning | 3 | `emptyDir` usage is cached on a one-minute period, not refreshed every 10 s | Valid | `volumeStatsAggPeriod`, the cache and its call site quoted; P7 and P9 corrected |
| 1, 1, reasoning | 4 | As sources 5 | Valid | As sources 5 |
| 1, 1, reasoning | 5 | btrfs in place is no guarantee (metadata reservation); `NOCOW` has the sharing exception | Valid | `btrfs_cross_ref_exist` and the metadata reservation quoted; C3 now "partly" |
| 1, 1, reasoning | 6 | As sources 7 | Valid | As sources 7 |
| 1, 1, reasoning | 7 | As sources 4 | Valid | As sources 4 |
| 1, 1, reasoning | 8 | The runtime raises the 1 s eviction grace to 2 s | Valid | The floor and its path quoted in P7 |
| 1, 1, reasoning | 9 | gcsfuse staging is not universal: a streamed write holds memory | Valid | Streaming passages quoted; inference, summary and C7 corrected |
| 1, 1, reasoning | 10 | Quack and DuckLake are not exceptions to the one-writer rule, and predate 2.0 | Valid | P10, the comparables and C9 reworded, with the Quack overview and the 1.5 page quoted |
| 1, 1, reasoning | 11 | duckdb-python #292 is a child opening its own connection, not using an inherited one | Valid | Split into a third case; the inherited-instance inference narrowed |
| 1, 1, reasoning | 12 | SQLite's WAL reason for one writer, and its checkpoint mechanism and cost | Valid | Quoted in P11 |
| 1, 1, reasoning | 13 | The 2026 measurement on larger batches qualifies the 2024 CPU cost | Valid | Quoted side by side in P13 |
| 1, 1, reasoning | 14 | "To the same place" is in the first note, not the second | Valid | Corrected |
| 1, 1, reasoning | Suspicion 1 | GKE backing filesystems | Valid as stated, no edit | C6 kept partly Unverified |
| 1, 1, reasoning | Suspicion 2 | APFS on an unshared range | Valid as stated, no edit | Already Unverified |
| 1, 2, sources | 1 | A COS build GKE ships (`cos-133-19999-44-159`) has an ext4 stateful partition in its image layout | Valid | Changelog, build page, manifest and layout chain quoted in P8; P4, C6 and candidates updated; a running node is still Inferred |
| 1, 2, sources | 2 | The overlay snapshotter's root is configurable (`root_path`) | Valid | Plugin and server code quoted in P4; summary row reworded |
| 1, 2, sources | 3 | A direct-I/O write gets ext4's conversion error; truncation frees a `posix_fallocate` reservation | Valid | Direct-I/O path quoted in P1 and the buffered path kept Unverified; POSIX truncation quoted in P2, with a new condition |
| 1, 2, sources | 4 | btrfs copies for more reasons than sharing | Valid | The other checks quoted in P3, with an inference on which apply; summary and C3 qualified |
| 1, 2, sources | 5 | Project quotas cover `emptyDir` only, and the writable layer is always walked | Valid | KEP 1029 and `AssignQuota` quoted in P7; the counting inference and C4 narrowed |
| 1, 2, sources | 6 | Three separate limit checks; the critical-pod and dedicated-image-filesystem exceptions | Valid | Code and docs quoted in P7; P9, summary and C5 qualified |
| 1, 2, sources | 7 | The stop signal can differ from SIGTERM, and `preStop` runs first | Valid | Pod-termination docs, the feature gate and the `preStop` line quoted in P7 |
| 1, 2, sources | 8 | P9 cited `fallocate(2)` for a write's `ENOSPC`; short writes and late `fsync` errors were missing | Valid | `write(2)` and `fsync(2)` quoted; P9 reworded |
| 1, 2, sources | 9 | With streaming writes, `fsync` does not finalize the object | Valid | Quoted in P6; the inference updated |
| 1, 2, sources | 10 | Quack's introduction and first core shipment, and the authors' reason for it | Valid | The 1.5.3 post and the Quack post quoted in P10 |
| 1, 2, sources | Suspicion 1 | What a buffered writer sees after a failed conversion | Valid | Kept Unverified, with where was looked |
| 1, 2, sources | Suspicion 2 | The Ubuntu image and the mixed Local SSD layout | Valid | Kept Unverified; the mixed Local SSD page added to where was looked |
| 1, 2, sources | Suspicion 3 | Writes through an inherited DuckDB instance | Invalid | Already stated in the file |
| 1, 2, sources | Suspicion 4 | The OTel posts identified by content only | Invalid | Already stated; the live URLs added to P12 |
| 1, 2, reasoning | 1 | In-place overwrite treated as a general condition, and copy-on-write as filesystem-wide | Valid | P1's condition scoped; P3's opening and C2 aligned with P3's own sections |
| 1, 2, reasoning | 2 | btrfs: a pending snapshot also forces copy-on-write | Valid | As sources 4 |
| 1, 2, reasoning | 3 | As sources 5 | Valid | As sources 5 |
| 1, 2, reasoning | 4 | As sources 6 | Valid | As sources 6 |
| 1, 2, reasoning | 5 | As sources 8 | Valid | As sources 8 |
| 1, 2, reasoning | 6 | Streaming writes can be switched off, and need a recent GKE | Valid | Quoted in P6; inference, summary and C7 conditioned |
| 1, 2, reasoning | 7 | Boot-disk types depend on the machine series; the 10% threshold applies to boot-disk ephemeral storage | Valid | Quoted in P8 |
| 1, 2, reasoning | 8 | The huge-page `emptyDir` medium was not covered | Valid | A paragraph added to P5 |
| 1, 2, reasoning | 9 | As sources 7 | Valid | As sources 7 |
| 1, 2, reasoning | Suspicion 1 | The Ubuntu image and the split Local SSD layout | Valid, no edit | As sources suspicion 2 |
| 1, 2, reasoning | Suspicion 2 | What an application sees after a failed conversion | Valid, no edit | As sources suspicion 1 |
| 1, 2, reasoning | Suspicion 3 | The direction of DuckDB's fork test | Valid | P10 reworded: the child takes the lock first; test lines quoted |
| 2, 1, sources | 1 | A reserved write can still need ext4 metadata; a full disk can also give a short write | Valid in part | The fit row, the `CONTEXT.md` wording and the open question 8 bearing carry the metadata split and the short write; the ticket 07 bullet already had them |
| 2, 1, sources | 2 | An append can use a range reserved past the end of the file | Valid | The man page's "append workloads" quoted in P1; the on-disk format bearing rewritten |
| 2, 1, sources | 3 | H1 and H2 stated the writable layer's placement as fact; H3 dropped the Local SSD case | Valid in part | H1 and H2 conditioned on the default roots and image streaming (Inferred); H3 rows carry Local SSD; the ticket 07 bullet names the snapshotter's root |
| 2, 1, sources | 4 | Holes reduce what copy-up copies; they are no exception to needing space | Valid | Copy-up row corrected |
| 2, 1, sources | 5 | The writable layer is lost on a container restart; a memory `emptyDir` is charged to the writing container | Valid | Both quoted in P4 and P5; the ephemeral-pod line and the ticket 07 bullet corrected |
| 2, 1, sources | 6 | Autopilot's figures have exceptions; an `emptyDir` counts towards the pod's limit, not a container's | Valid | DaemonSet default, 56 TiB exception and the pod-level rule quoted; P8, H3 and the usage row corrected |
| 2, 1, sources | 7 | Allocatable storage does not by itself show the kubelet measures; the ranking signal was dropped | Valid in part | The `localStorageCapacityIsolation` code quoted in P8, still Inferred; the comparable, the ticket 07 and `CONTEXT.md` wording and C5 conditioned |
| 2, 1, sources | 8 | The btrfs wording dropped conditions; copy-on-write was generalised in the bearing | Valid in part | Ticket 07 bullet carries P3's conditions and label; the format bearing gives P3's in-place cases. The glibc point stood |
| 2, 1, sources | 9 | DuckDB's read-only conflict was left wholly inferred | Valid | The read-only mode, the lock types and `fcntl_locking(2)` quoted in P10; the pull row and the open question 17 bearing rest on them, still Inferred from source |
| 2, 1, sources | 10 | The OTel wording dropped "generally" and read the identification as settled | Valid | "Generally" restored in P13 and the wording; the identification labelled unconfirmed in the proposed text |
| 2, 1, sources | Suspicion 1 | The COS layout trace and other Unverified GKE layers | Invalid | The trace matches the pinned sources; the Unverified marks stand. An optional Arm-board addition was not made |
| 2, 1, sources | Suspicion 2 | ext4's buffered error path; APFS private data | Invalid | Already Unverified in the file |
| 2, 1, reasoning | 1 | Image streaming on Standard, and Autopilot's Local SSD layout | Valid in part | As sources 3; Autopilot's Local SSD layout Inferred from the shared node label, with the label and mixed-layout pages quoted in P8 |
| 2, 1, reasoning | 2 | The eviction wording dropped its conditions; an `emptyDir` is not under a container's limit | Valid in part | As sources 6 and 7; the eviction-manager lines quoted in P7 |
| 2, 1, reasoning | 3 | Node pressure conflated with per-volume sampling | Valid in part | `nodefs.available` quoted in P7; P9 and the fit row separate the two, with the refresh of free space Unverified; C5 and `CONTEXT.md` wording conditioned |
| 2, 1, reasoning | 4 | H3 dropped the Autopilot exceptions | Valid | As sources 6 |
| 2, 1, reasoning | 5 | The wording omitted that the range must still be allocated | Valid | `PUNCH_HOLE` quoted in P1; P1's conditions and the ticket 07 bullet carry truncation and holes |
| 2, 1, reasoning | 6 | Conditional reservation behaviour made categorical | Valid in part | As sources 2 and 8; the P1 comparable names which network and FUSE volumes do not hold |
| 2, 1, reasoning | 7 | Containers meet on a file only through a shared volume; any reader refused | Valid | The shared process namespace quoted in P4; the advisory-lock limit quoted in P10; the pull row and the open question 17 bearing corrected |
| 2, 1, reasoning | 8 | "Whichever opens second fails" dropped the held-lock condition | Valid in part | The fork row and the ticket 08 bearing condition it, and report duckdb-python #292 |
| 2, 1, reasoning | 9 | The OTel fit left out the caller constraint behind backpressure | Valid in part | The P13 comparable records it against `CONTEXT.md`'s guidance; the identification as sources 10 |
| 2, 1, reasoning | Suspicion 1 | The COS layout chain | Invalid | Fetched again by triage; matches P8 |
| 2, 1, reasoning | Suspicion 2 | DuckDB's fork test at the pinned tag | Invalid | Fetched again by triage; matches P10 |
| 2, 2, sources | 1 | DuckDB's read-lock fork test, with a native file the parent used, was missed | Valid | Quoted in P10, with what it does not assert; the fork row and the ticket 08 bearing name both tests |
| 2, 2, sources | 2 | Google's 2023 post states kubelet measurement for its Local SSD option | Valid | Quoted in P8; the measuring row, the P7 comparable and the ticket 07 wording say stated there, Inferred elsewhere |
| 2, 2, sources | 3 | Placement and filesystem format conflated in H2, H4 and the P1 comparable | Valid | Google's placement sentence quoted in P8; H2, H4 and the comparable each scoped to what P6 and P8 source |
| 2, 2, sources | 4 | DuckDB's lock: only `ENOTSUP` lets a read-only open go unlocked, and the rule is POSIX's | Valid | The `ENOTSUP` branch quoted in P10; the fit note, the comparable, the `CONTEXT.md` wording and the open question 17 bearing scoped |
| 2, 2, sources | 5 | glibc's fallback stated as a claim about every copy-on-write filesystem | Valid in part | P2 and the ticket 07 bearing keyed to the mechanism; the bearing's conclusion stood for the cases P3 shows |
| 2, 2, sources | 6 | ZFS success and the sparse file read as unconditional | Valid | The `ENOSPC` check quoted in P3; P3's closing line, the ticket 07 wording and the bearing conditioned |
| 2, 2, sources | 7 | The full-disk summaries dropped P9's delayed errors | Valid | Added to the fit note, the `CONTEXT.md` wording and the open question 8 bearing |
| 2, 2, sources | 8 | Close is not the only event that finalizes a streamed Cloud Storage FUSE write | Valid | Rename, read and truncate quoted in P6; P6's inference corrected |
| 2, 2, sources | Suspicions 1–3 | The COS chain, the OTel identification, the POSIX page | Invalid | Each fetched again by triage, or already stated in the file |
| 2, 2, reasoning | 1 | NFSv4.2 `ALLOCATE` gives the guarantee without in-place overwrite | Valid | The RFC's deferred allocation and the client's mode-0 path quoted in P6; P1's condition and the ticket 07 wording scoped to local filesystems |
| 2, 2, reasoning | 2 | A new Python connection need not open the file: the instance cache | Valid | The cache paths quoted in P10, with the inference labelled; the fork row and the ticket 08 bearing distinguish a new open from a new connection |
| 2, 2, reasoning | 3 | Two pods can share a file on a volume both mount | Valid | `ReadWriteOnce` on one node quoted in P6; the same-file row corrected |
| 2, 2, reasoning | 4 | The DuckDB wording dropped the filesystem condition | Valid in part | As sources 4; the one-writer half stood |
| 2, 2, reasoning | 5 | An `emptyDir` is not under a container's limit; the pod limit includes init containers | Valid | The summary row corrected; `PodLimits` and its helper quoted in P7; the usage row cites them |
| 2, 2, reasoning | 6 | A `LimitRange` default can give a Standard pod a limit | Valid | The blog and the admission code quoted in P8; H1, the limit row and the open question 8 bearing carry it; whether GKE sets one is Unverified |
| 2, 2, reasoning | 7 | Cloud Storage FUSE stages writes in ephemeral storage | Valid | The 10 GiB passage quoted in P6, with the inference labelled; the mounted-volume note corrected |
| 2, 2, reasoning | 8 | As sources 6 | Valid | As sources 6; the P3 comparable reworded too |
| 2, 2, reasoning | 9 | The 2024 gateway's synchronous path was extended to all the posts | Valid | P13 says what the 2026 post does and does not say, with the search; the P13 comparable scoped |
| 2, 2, reasoning | Suspicions 1–3 | A forked child's native-file connection; the Unverified GKE layers; the OTel identification | Folded into 2, or invalid | Already in the file |

**Open points.** No review finding is left open: all 81 numbered findings, and the suspicions, were applied or settled. What remains is for the maintainer, and is stated in the research file:

- **C6.** Do two COS release notes, one COS build's image layout and Google's 2023 Local SSD post confirm that GKE node disks are ext4? Each speaks for its own release, build or layout. A `mount` on a running node would settle it, and was not within this ticket's authority.
- **The OTel Arrow posts.** Please confirm that the posts of 2024-09-25, 2025-05-12 and 2026-06-12 are the three `CONTEXT.md` means (P12).
- **The proposed wording** for ticket 07 and `CONTEXT.md` is for the maintainer to accept, change or reject. Neither file was edited.
- **Still Unverified, with where was looked:** the Ubuntu node image's filesystem; the newer split Local SSD layout's filesystem; the writable layer under image streaming; what a buffered ext4 writer sees when an extent cannot be split; APFS's in-place rewrite of unshared data; how often the kubelet refreshes the node's free space; whether a GKE Standard cluster sets a `LimitRange` default for ephemeral storage; what a forked DuckDB child sees when it is handed an inherited instance; and how DuckDB writes its own file, in place or appending.
- **The last round's fixes.** The second key moment's second-round fixes were checked by the quotation script but not reviewed by anyone after they were applied.

### Gates and files

- **Baseline**, at `c3a33eb`, on the untouched worktree. No network recipe was needed, and none was run.

  > All checks passed and the worktree is unchanged.

- **Final**: recorded in the commit after the hand-back.
- **Changed files:** `git diff main --stat` shows only this ticket and its research file. The specification, `CONTEXT.md`, `REVIEW.md` and ticket 07 are unchanged. Open questions 8 and 17 are still open in the specification. No code was added.

### Acceptance

- [x] Each claim C1 to C9 checked again from a primary source, with its link and the date read; the wrong quotation in C1 and the unsourced "usually an eviction" in C5 are reported as wrong.
- [x] Both "Unverified" marks settled: network and FUSE volumes now sourced; GKE's ext4 partly sourced, and kept Unverified where nothing confirms it, with where was looked.
- [x] Each fact's mechanism and conditions, and which conditions hold on GKE Standard, Local SSD and Autopilot, in the fit tables.
- [x] The writable layer, `emptyDir` on disk and in memory, and each mounted volume kept apart, each with whether a reserved file is rewritten in place.
- [x] DuckDB's rule and its stated why, with SQLite as the contrast, weighing neither.
- [x] The OTel Arrow posts identified with their links, and the maintainer asked to confirm.
- [x] "Citing a comparable" fields recorded wherever a source's authors explain a design.
- [x] What the evidence bears on open questions 8 and 17, recommending neither; both still open, and ticket 07 unchanged.
- [x] Written to the research file, summarised here, and committed.
- [x] Adversarial review at both key moments, with reviewers that opened the sources; every finding listed above with its verdict, resolution and model.
- [x] No tracked file other than this ticket and its research file changed, and no code added.
