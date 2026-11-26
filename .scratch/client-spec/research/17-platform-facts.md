# Research: platform facts

- **Ticket:** `issues/17-research-the-why-platform-facts.md`. It checks the platform facts that the specification, ticket 07 (diagnostics tables), ticket 08 (fork and more than one process) and open question 8 lean on.
- **Sources read:** every source on 2026-11-25 (UTC). That was 2026-11-24 in the researcher's local time, except the last fetches for the addition on how DuckDB writes its own file, which ran into 2026-11-25.
- **Web research:** authorised by the maintainer on 2026-11-24 for this ticket, for the agent working it, for its survey subagents and for its reviewers. It is read-only: nothing was posted, filed or sent.
- **Network recipes:** the maintainer allowed `just sync`, `just install-allium` and `just install-tools` if the baseline needed them. It did not, and none was run.
- **State of this file:** complete for hand-back. The findings, up to "The claims, checked", were reviewed at the first key moment. The fit on the leaning hosts, the proposed wording and what the findings bear on were written after it, and the whole file was reviewed at the second, in two rounds. The second round's fixes were checked by the quotation script, not reviewed again. "How DuckDB writes its own file" under P10, and the rows, bearings and candidates that cite it, were added after the second key moment and reviewed in one round of their own, by the maintainer's choice; that round's fixes were not reviewed again. On 2026-11-25 the maintainer answered the hand-back's open points: C6 stays "Partly sourced", with no node inspected; the three OTel Arrow posts in P12 are the ones `CONTEXT.md` means; and the proposed wording stays in this file only, with the note under "Proposed wording for the maintainer". The sentences added for those answers were not reviewed.

## How the sources were checked

Four survey agents found the candidate sources and saved raw text. The addition on how DuckDB writes its own file used no survey agent: the author searched full copies of the DuckDB v2.0.1 and duckdb-web `c53d1db` trees. The author then fetched every cited source again, independently:

- source and documentation files at a pinned tag or commit, through the GitHub API or `git.kernel.org`;
- issue, pull request and discussion comments through the GitHub REST and GraphQL APIs, each comment saved alone, so a quotation cited to one comment is checked against that comment only;
- manual pages as rendered by man7.org, whose footer names the man-pages release;
- vendor pages and blog posts as HTML, with the tags stripped and the whitespace that HTML ignores collapsed;
- PDFs through macOS PDFKit's text extraction.

Each quotation below was then checked by machine as a substring of that text. A quotation under a source marked "(line breaks collapsed)" may match only once line breaks and indentation are collapsed; its wording is verbatim.

A quotation from source code keeps the comment markers it has in the file.

Where this file says a source is silent, the author ran the search on their own copies. Each such search is described where it is reported, with the corpus and the terms.

A man7.org page and its git tag carry different dates. man7.org's footer gives the page's own date (for example "Linux man-pages 6.19 2026-02-08"), and the `man-pages-6.19` tag is later. Each date below is given as its source gives it.

## The claims being checked

The ticket lists these, each recorded in `CONTEXT.md` with no link:

- **C1.** Linux `fallocate` guarantees that later writes into the reserved range "will not fail because of lack of disk space".
- **C2.** A file created in the container or on an `emptyDir` volume is overwritten in place on the node's disk.
- **C3.** The guarantee does not hold on copy-on-write filesystems: ZFS, btrfs, reflinked XFS and APFS.
- **C4.** A reservation never prevents the kubelet evicting a pod over its ephemeral-storage limit.
- **C5.** A full disk on Kubernetes usually shows up as an eviction, not as a failed write. So reserved space helps when a neighbour fills the node, and not when the pod itself is over its limit.
- **C6.** Marked "Unverified": that GKE node disks are ext4.
- **C7.** Marked "Unverified": the behaviour on network and FUSE volumes.
- **C8.** The OTel Arrow posts (2024, 2025, 2026) treat Arrow as a wire and in-pipeline format. None covers on-disk storage, durability, shutdown or schema evolution. Their useful signals are bounded channels and memory, overload made visible, and larger batches compressing better.
- **C9.** Never checked: that DuckDB allows only one writer process.

The maintainer's notes that lean on them, quoted in the ticket:

Source: `.scratch/client-spec/issues/17-research-the-why-platform-facts.md`

> And then let's also look to see if we can pre allocate space on disk or whatever for these tables so that even if the disk fills up, we can keep rewriting to the same place. Let me know if this is possible and if it works even in the cloud environment like Google's GKE.

> This should fail loudly. There can be only one writer process, Especially if we go with DuckDB.

The first note asks for a rewrite "to the same place", not a first write. Several findings below differ between the first write into a reserved range and a later rewrite of it.

A verdict table for C1 to C9 closes the findings, under "The claims, checked".

---

## Reserving space

### P1. Linux `fallocate(2)`: what it promises, per mode

**What it does.** Read at Linux man-pages 6.19, as rendered by man7.org (footer "Linux man-pages 6.19 2026-02-08").

- **Mode 0 (the default)** allocates the range and states the guarantee.

  Source: https://man7.org/linux/man-pages/man2/fallocate.2.html (line breaks collapsed)

  > allocates the disk space within the range specified by offset and size.

  > After a successful call, subsequent writes into the range specified by offset and size are guaranteed not to fail because of lack of disk space.

- **`FALLOC_FL_KEEP_SIZE`** behaves the same way without changing the file size. The page says the call is "similar", in the paragraph that follows the guarantee, so the guarantee is read as covering it.

  > If the FALLOC_FL_KEEP_SIZE flag is specified in mode, the behavior of the call is similar, but the file size will not be changed even if offset+size is greater than the file size.

  The page names what reserving past the end of the file is for.

  > Preallocating zeroed blocks beyond the end of the file in this manner is useful for optimizing append workloads.

- **`FALLOC_FL_UNSHARE_RANGE`** carries its own guarantee, worded differently, and is the one mode that addresses shared extents.

  > If the FALLOC_FL_UNSHARE_RANGE flag is specified in mode, shared file data extents will be made private to the file to guarantee that a subsequent write will not fail due to lack of space.

  > This flag may not be supported by all filesystems.

- **`FALLOC_FL_PUNCH_HOLE`, `FALLOC_FL_ZERO_RANGE`, `FALLOC_FL_COLLAPSE_RANGE` and `FALLOC_FL_INSERT_RANGE`** deallocate, zero or shift a range. None of them states a guarantee about later writes. `ZERO_RANGE` "preallocates" the holes it zeroes, and the page says nothing more about later writes into them. `PUNCH_HOLE` gives reserved space back.

  > Specifying the FALLOC_FL_PUNCH_HOLE flag (available since Linux 2.6.38) in mode deallocates space (i.e., creates a hole) in the byte range starting at offset and continuing for size bytes.

  > Within the specified range, blocks are preallocated for the regions that span the holes in the file.

- **`FALLOC_FL_WRITE_ZEROES`** is not on the 6.19 page. It first appears at the `man-pages-6.20` tag. It promises that later writes need no change to the file's mapping metadata, not that they cannot fail for lack of space.

  Source: https://git.kernel.org/pub/scm/docs/man-pages/man-pages.git/plain/man/man2/fallocate.2?h=man-pages-6.20 (line breaks collapsed)

  > subsequent writes to that range do not require further

  > The operation is supported only in ext4 (only for extent-based files)

  That is the page's statement. At Linux v7.3, XFS implements the mode too, except on an `always_cow` inode, a `bigrtalloc` inode, or a device without write-zeroes unmap support.

  Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/xfs/xfs_file.c?h=v7.3 (line breaks collapsed)

  > 	case FALLOC_FL_WRITE_ZEROES:
  > 		error = xfs_falloc_write_zeroes(file, mode, offset, len, ac);

  > 	if (xfs_is_always_cow_inode(ip) || xfs_inode_has_bigrtalloc(ip) ||
  > 	    !bdev_write_zeroes_unmap_sectors(xfs_inode_buftarg(ip)->bt_bdev))
  > 		return -EOPNOTSUPP;

- **An unsupported mode or filesystem** returns `EOPNOTSUPP`.

  Source: https://man7.org/linux/man-pages/man2/fallocate.2.html (line breaks collapsed)

  > The filesystem containing the file referred to by fd does not support this operation; or the mode is not supported by the filesystem containing the file referred to by fd.

**The wording in C1.** The phrase "will not fail because of lack of disk space" appears in no release of `fallocate(2)` or `posix_fallocate(3)`. The author cloned the man-pages repository and read both pages at every one of its 224 tags (`man-pages-1.70` to `man-pages-6.20`), joining line breaks: no hit. `fallocate(1)` at util-linux v2.42.4 states no guarantee at all. The page's own wording is "are guaranteed not to fail because of lack of disk space", unchanged since its first release. The closest wording found anywhere is btrfs's, quoted under P3: "will not fail because of lack of space". The substance of C1 holds for mode 0 and `KEEP_SIZE`. Its quotation is not the man page's.

**Mechanism on ext4, the filesystem without copy-on-write.** The allocation is real: blocks are marked "unwritten", so they read as zeros until written.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/ext4_extents.h?h=v7.3 (line breaks collapsed)

>  * particular extent is an initialized extent or an unwritten (i.e.
>  * preallocated).

A later write converts an unwritten extent to a written one. That can split an extent and so need a new metadata block, and ext4 draws that block from a reserve kept for the purpose.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/extents.c?h=v7.3 (line breaks collapsed)

> 	 * When writing into unwritten space, we should not fail to
> 	 * allocate metadata blocks for the new extent block if needed.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/ext4.h?h=v7.3

> /* Use blocks from reserved pool */

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/super.c?h=v7.3 (line breaks collapsed)

> 	 * By default we reserve 2% or 4096 clusters, whichever is smaller.
> 	 * This should cover the situations where we can not afford to run
> 	 * out of space like for example punch hole, or converting
> 	 * unwritten extents in delalloc path. In most cases such
> 	 * allocation would require 1, or 2 blocks, higher numbers are
> 	 * very rare.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/admin-guide/ext4.rst?h=v7.3 (line breaks collapsed)

> This is RW file and contains number of reserved clusters in the file system which will be used in the specific situations to avoid costly zeroout, unexpected ENOSPC, or possible data loss.

> The default is 2% or 4096 clusters, whichever is smaller and this can be changed however it can never exceed number of clusters in the file system.

The reserve can be changed while mounted, to any value below the filesystem's cluster count.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/sysfs.c?h=v7.3

> 	if (ret || val >= clusters || (s64)val < 0)
> 		return -EINVAL;

Not every conversion needs a new metadata block. A write that covers a whole unwritten extent needs no split. Where a split fails for lack of space, ext4 may instead write zeros over the unwritten part and mark it written, and if it cannot, it returns the original error. The code allows that fallback only for an extent that ends at or before the end of the file, and within a size cap.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/extents.c?h=v7.3 (line breaks collapsed)

> 	/* No split needed */
> 	if (ee_block == map->m_lblk && ee_len == map->m_len)
> 		goto convert;

> 	 * There was an error in splitting the extent. So instead, just zeroout
> 	 * unwritten portions and convert it to initialized as a last resort. If
> 	 * there is any failure here we just return the original error

So on ext4 the guarantee rests on data blocks allocated at the call and, for a conversion that must split an extent, on a reserve shared by the whole filesystem: by default 2% of its clusters or 4096, whichever is smaller, and adjustable. If a split still cannot get space, ext4 falls back to zeroing where it may, and otherwise returns the error.

For a direct-I/O write, the conversion runs when the I/O completes, and its error is the write's result: ext4's completion handler returns it, and iomap returns the handler's result to the caller.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/file.c?h=v7.3 (line breaks collapsed)

> 	else if (!error && size && flags & IOMAP_DIO_UNWRITTEN)
> 		error = ext4_convert_unwritten_extents(NULL, inode, pos, size,

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/iomap/direct-io.c?h=v7.3 (line breaks collapsed)

> 		ret = dops->end_io(iocb, dio->size, ret, dio->flags);

Unverified: what a buffered writer sees. Its conversion runs at writeback. There, ext4 logs the failure, and the deferred worker that runs it discards the returned error (Inferred from the code below). Whether the error reaches a later `fsync` was not traced.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/page-io.c?h=v7.3 (line breaks collapsed)

> 			 "failed to convert unwritten extents to written "

> 	ext4_do_flush_completed_IO(&ei->vfs_inode, &ei->i_rsv_conversion_list);

On ext4 a rewrite of a range already written lands on the same blocks. Overwriting allocated blocks needs no allocation. That is the general behaviour of a filesystem without copy-on-write, and the author found no ext4 document that states it in so many words.

**Conditions under which the guarantee holds**, from the sources above:

- the filesystem implements the mode (otherwise `EOPNOTSUPP`);
- the mode is 0, `KEEP_SIZE` or `UNSHARE_RANGE`;
- on the local filesystems read, a later write keeps the guarantee only where it lands in the allocated blocks in place, as on ext4; P3 shows when each copy-on-write filesystem read does not. On NFS the guarantee is the server's promise instead, made only through NFSv4.2's `ALLOCATE` (P6);
- the range has not been truncated away or punched since the call. POSIX states this for `posix_fallocate` (P2); for `fallocate(2)` it is Inferred. A rewrite that opens the file with `O_TRUNC` gives the space back before it writes, and `PUNCH_HOLE` deallocates it (above);
- on ext4, a conversion that must split an extent gets its metadata block from the reserve, or the zero-out fallback applies; otherwise the original error is returned (`extents.c`, above).

**Stated why.** Not applicable: this is an interface contract, not a design choice. The page says only that mode 0 "is intended as a method of optimally implementing" `posix_fallocate(3)`.

Source: https://man7.org/linux/man-pages/man2/fallocate.2.html (line breaks collapsed)

> This default behavior closely resembles the behavior of the posix_fallocate(3) library function, and is intended as a method of optimally implementing that function.

### P2. `posix_fallocate(3)` and glibc's emulation

**What it does.** The same promise, in the library call that POSIX defines.

Source: https://man7.org/linux/man-pages/man3/posix_fallocate.3.html (line breaks collapsed)

> After a successful call to posix_fallocate(), subsequent writes to bytes in the specified range are guaranteed not to fail because of lack of disk space.

Source: https://pubs.opengroup.org/onlinepubs/9799919799/functions/posix_fallocate.html (line breaks collapsed)

> If posix_fallocate() returns successfully, subsequent writes to the specified file data shall not fail due to the lack of free space on the file system storage media.

POSIX also says when the space is given back. A rewrite that truncates the file first frees it.

> Space allocated via posix_fallocate() shall be freed by a successful call to creat() or open() that truncates the size of the file. Space allocated via posix_fallocate() may be freed by a successful call to ftruncate() that reduces the file size to a size smaller than offset+len.

**Mechanism where the filesystem has no `fallocate`.** glibc calls `fallocate(2)` with mode 0, and on `EOPNOTSUPP` falls back to writing one null byte per stride of the filesystem's reported block size, capped at 4096 bytes, skipping any position inside the file that already reads non-zero.

Source: https://sourceware.org/git/?p=glibc.git;a=blob_plain;hb=refs/tags/glibc-2.44;f=sysdeps/unix/sysv/linux/posix_fallocate.c

>   if (INTERNAL_SYSCALL_ERRNO (res) != EOPNOTSUPP)
>     return INTERNAL_SYSCALL_ERRNO (res);
>   return internal_fallocate (fd, offset, len);

Source: https://sourceware.org/git/?p=glibc.git;a=blob_plain;hb=refs/tags/glibc-2.44;f=sysdeps/posix/posix_fallocate.c (line breaks collapsed)

>   /* Write a null byte to every block.  This is racy; we currently
>      lack a better option.

>   /* Minimize data transfer for network file systems, by issuing
>      single-byte write requests spaced by the file system block size.
>      (Most local file systems have fallocate support, so this fallback
>      code is not used there.)  */

>       /* NFS does not propagate the block size of the underlying
> 	 storage and may report a much larger value which would still
> 	 leave holes after the loop below, so we cap the increment at
> 	 4096.  */

> 	  /* If there is a non-zero byte, the block must have been
> 	     allocated already.  */

The manual page names the emulation's costs.

Source: https://man7.org/linux/man-pages/man3/posix_fallocate.3.html (line breaks collapsed)

> There is a race condition where concurrent writes from another thread or process could be overwritten with null bytes.

> In general, the emulation is not MT-safe.

**Conditions.** The emulation turns the reservation into ordinary writes. A later write reuses what those writes allocated only where the filesystem overwrites in place (Inferred, P1, P3), and the NFS specification says writing zeros is not guaranteed to work on log-structured or deduplicated filesystems (P6). Other C libraries do not emulate.

> This error code can be returned by C libraries that don't perform the emulation shown in CAVEATS, such as musl libc.

### P3. Copy-on-write filesystems

A copy-on-write filesystem writes a modified block to a new place, at least where the block is shared. How far a reservation holds then differs by filesystem: ZFS reserves nothing; btrfs writes a preallocated extent in place once, and a `NOCOW` file's extents each time, under conditions; XFS with reflink overwrites in place a block that is not shared (Inferred, below). A snapshot or a clone can stop even a first write landing in place. Each filesystem's own sources follow.

#### OpenZFS

**What it does.** Read at `zfs-2.4.4`. Mode 0 and `KEEP_SIZE` only check that enough space is free now, in the pool or the project quota, and fail with `ENOSPC` if it is not. The margin is a tunable, `zfs_fallocate_reserve_percent`, 110% of the request by default. Mode 0 then extends the file, sparsely, if the range runs past its end, and `KEEP_SIZE` changes no size. Nothing is reserved.

Source: https://github.com/openzfs/zfs/blob/zfs-2.4.4/man/man4/zfs.4 (line breaks collapsed)

> Since ZFS is a copy-on-write filesystem with snapshots, blocks cannot be preallocated for a file in order to guarantee that later writes will not run out of space.

> space preallocation only checks that sufficient space is currently available

Source: https://github.com/openzfs/zfs/blob/zfs-2.4.4/module/os/linux/zfs/zpl_file.c (line breaks collapsed)

>  * The original mode=0 (allocate space) behavior can be reasonably emulated
>  * by checking if enough space exists and creating a sparse file, as real
>  * persistent space reservation is not possible due to COW, snapshots, etc.

> static unsigned int zfs_fallocate_reserve_percent = 110;

> 		if (len > statfs.f_bavail * (statfs.f_bsize * 100 / percent)) {
> 			error = -ENOSPC;

> 		if (!(mode & FALLOC_FL_KEEP_SIZE) && offset + len > olen) {

**Stated why.** The merge commit that added mode 0, by Andreas Dilger with Brian Behlendorf as co-author, gives the reason, and why an exact implementation was not attempted.

Source: https://github.com/openzfs/zfs/commit/f734301d2267cbb33eaffbca195fc93f1dae7b74 (line breaks collapsed)

> Since ZFS does COW and snapshots, preallocating blocks for a file
> cannot guarantee that writes to the file will not run out of space.
> Even if the first overwrite was guaranteed, it would not handle any
> later overwrite of blocks due to COW, so strict compliance is futile.

The same author, eight months earlier (2019-10-09, against the commit's 2020-06-18), in the issue that asked for `fallocate`.

Source: https://github.com/openzfs/zfs/issues/326#issuecomment-540194092 (line breaks collapsed)

> My reasoning is that _even if_ there was a mechanism to have `fallocate()` reserve space for that file in the pool for preallocated blocks, *this would only work for the first write*.

**Constraints.** Every write in ZFS goes to new blocks, and a snapshot pins the old ones. Space freed by an overwrite may therefore never come back while a snapshot holds it.

**Costs and dissent.**

- Brian Behlendorf, accepting the emulation, called it a lie made for pragmatic reasons.

  Source: https://github.com/openzfs/zfs/issues/326#issuecomment-540186410

  > While I'd rather not lie to user space, I do have to agree that it is the pragmatic thing to do for the `mode == 0` case.  Not supporting this functionality has been causing more harm than good.

- Matthew Ahrens, reviewing, questioned the margin and what the check means with snapshots.

  Source: https://github.com/openzfs/zfs/pull/10408#issuecomment-639608471

  > Would we still want to check for free space, if there are snapshots?

- The emulation can be switched off with `zfs_fallocate_reserve_percent=0`, and then mode 0 returns `EOPNOTSUPP` again.

  Source: https://github.com/openzfs/zfs/blob/zfs-2.4.4/module/os/linux/zfs/zpl_file.c

  > 		/* Legacy mode, disable fallocate compatibility. */

So on ZFS, with the emulation on, a successful `fallocate` in mode 0 guarantees nothing, and a program cannot tell from the return value.

#### btrfs

**What it does.** Read at btrfs-progs v7.3, the source of btrfs.readthedocs.io. btrfs does preallocate. A first write into a preallocated extent goes in place. After that the extent is an ordinary one, and a later rewrite is copy-on-write.

Source: https://github.com/kdave/btrfs-progs/blob/v7.3/Documentation/ch-glossary.rst (line breaks collapsed)

> First data write will turn the preallocated extents into regular ones.

> Instead of directly overwriting data in place, btrfs takes a copy of the data, alters it, and then writes the modified data back to a different (unused) location on the disk.

**Stated why.** The btrfs documentation states the guarantee it is trying to keep, and that copy-on-write makes it hard.

Source: https://github.com/kdave/btrfs-progs/blob/v7.3/Documentation/ch-compression.rst (line breaks collapsed)

> The reason for this is that a successful *fallocate* call must guarantee that future writes to the allocated range will not fail because of lack of space. This is difficult to guarantee in a COW filesystem. To reduce the chances of it happening, btrfs preallocates space and disables compression for the file.

"To reduce the chances" is the authors' own measure of the guarantee on btrfs.

**Mechanism, from the kernel source.** The write path writes in place only for a `NODATACOW` file or a preallocated extent, and only while no snapshot or clone shares the extent and the kernel's other checks pass. Read at Linux v7.3.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/btrfs/inode.c?h=v7.3 (line breaks collapsed)

> 	if (!(inode->flags & BTRFS_INODE_NODATACOW) &&
> 	    extent_type == BTRFS_FILE_EXTENT_REG)
> 		goto out;

> 	 * If the extent was created before the generation where the last snapshot
> 	 * for its subvolume was created, then this implies the extent is shared,
> 	 * hence we must COW.

The same functions name further cases that are copied anyway: a snapshot pending on the root at writeback, an extent that is compressed, encrypted or otherwise encoded, a range that already has checksums, and an extent in a read-only block group.

> 	/* If there are pending snapshots for this root, we must do COW. */

> 	/* Compressed/encrypted/encoded extents must be COWed. */

> 	 * Force COW if csums exist in the range. This ensures that csums for a
> 	 * given extent are either valid or do not exist.

> 	if (btrfs_extent_readonly(fs_info,

Inferred: a preallocated extent is not compressed, because btrfs disables compression for a file touched by `fallocate` (above), and it holds no data, so no checksums. The pending snapshot and the read-only block group remain.

The same function forces copy-on-write when any other reference to the extent exists, such as a clone, whether or not the file is `NODATACOW`.

> 	ret = btrfs_cross_ref_exist(inode, key->offset - args->file_extent.offset,

Even where no new data blocks are needed, the buffered write path still reserves metadata, and that reservation can fail.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/btrfs/file.c?h=v7.3 (line breaks collapsed)

> 		 * If we don't have to COW at the offset, reserve metadata only.

> 	ret = btrfs_delalloc_reserve_metadata(inode, reserve_bytes,

> 		if (nowait && ret == -ENOSPC)
> 			ret = -EAGAIN;
> 		return ret;

Inferred from that code: an ordinary extent in a file without `NODATACOW` is always copied on write. A preallocated extent, or an extent of a `NODATACOW` file, is written in place only while no snapshot, taken or pending, or other reference shares it, and the kernel's other checks pass. Even then the write needs a metadata reservation, which can fail with `ENOSPC`. In place is therefore not a guarantee, which matches the authors' "To reduce the chances".

**The way out btrfs documents.** A file marked `NOCOW` (`chattr +C`) is overwritten in place, and must be marked while empty.

Source: https://github.com/kdave/btrfs-progs/blob/v7.3/Documentation/ch-file-attributes.rst (line breaks collapsed)

> *no copy-on-write*, file data modifications are done in-place

> Due to implementation limitations, this flag can be set/unset only on empty files.

As with a preallocated extent, a snapshot or another reference to the extent still forces copy-on-write (`inode.c`, above), and the metadata reservation still applies. The retired btrfs wiki added that a snapshot still forces copy-on-write on such a file. The current documentation does not say so. Read at the archive, last modified 1 June 2022 by its footer.

Source: https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/FAQ.html

> COW may still happen if a snapshot is taken.

**Costs and dissent.** `NOCOW` gives up data checksums and compression, and risks a torn write.

Source: https://github.com/kdave/btrfs-progs/blob/v7.3/Documentation/ch-mount-options.rst (line breaks collapsed)

> *Nodatacow* implies *nodatasum*, and disables *compression*.

> Updates in-place improve performance for workloads that do frequent overwrites, at the cost of potential partial writes, in case the write is interrupted (system crash, device failure).

On zoned devices btrfs refuses `fallocate` outright. Its documentation lists it among the features that zoned devices rule out, and the kernel returns `EOPNOTSUPP`.

Source: https://github.com/kdave/btrfs-progs/blob/v7.3/Documentation/ch-zoned-intro.rst (line breaks collapsed)

> The main constraint of the zoned devices is lack of in-place update of the data. This is inherently incompatible with some features:

> * fallocate - preallocating space for in-place first write

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/btrfs/file.c?h=v7.3 (line breaks collapsed)

> 	/* Do not allow fallocate in ZONED mode */
> 	if (btrfs_is_zoned(inode_to_fs_info(inode)))
> 		return -EOPNOTSUPP;

The phrase "in-place first write" is btrfs's own summary of what a reservation buys there.

**Searched.** All 86 top-level `.rst` files in btrfs-progs v7.3 `Documentation/` were grepped for `prealloc` and `fallocate`, and the eight files that match were read. Only `ch-compression.rst` states the guarantee.

#### XFS with reflink

**What it does.** Read at Linux v7.3 and xfsprogs v7.3.0. `mkfs.xfs` enables reflink by default. Reflink lets files share blocks, and a write to a shared block goes to a new block.

Source: https://git.kernel.org/pub/scm/fs/xfs/xfsprogs-dev.git/plain/man/man8/mkfs.xfs.8.in?h=v7.3.0 (line breaks collapsed)

> If a program tries to write to a multiply-referenced block in a file, the write will be redirected to a new block, and that file's logical-to-physical mapping will be changed to the new block ("copy on write").

> will create reference count btrees and therefore will enable the reflink feature.

Blocks are shared only once something clones or deduplicates them. A file on a reflink-capable filesystem whose blocks are not shared is overwritten in place (Inferred from the passage above, which redirects only writes to "a multiply-referenced block").

**Mechanism.** Mode 0 does not unshare blocks. Only `FALLOC_FL_UNSHARE_RANGE` does, and an inode in `always_cow` mode refuses preallocation.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/xfs/xfs_file.c?h=v7.3 (line breaks collapsed)

> 	error = xfs_reflink_unshare(XFS_I(inode), offset, len);

> 	 * If always_cow mode we can't use preallocations and thus should not
> 	 * create them.

Inferred from the code: `xfs_falloc_allocate_range`, the mode-0 path, does not call `xfs_reflink_unshare`, so a mode-0 call over shared blocks leaves them shared.

**Stated why.** The reflink source states the principle that forces copy-on-write.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/xfs/xfs_reflink.c?h=v7.3 (line breaks collapsed)

>  * XFS must preserve "the usual" file semantics even when two files share
>  * the same physical blocks.  This means that a write to one file must not
>  * alter the blocks in a different file

The kernel's header says why `UNSHARE_RANGE` exists.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/include/uapi/linux/falloc.h?h=v7.3 (line breaks collapsed)

>  * FALLOC_FL_UNSHARE_RANGE is used to unshare shared blocks within the
>  * file size without overwriting any existing data. The purpose of this
>  * call is to preemptively reallocate any blocks that are subject to
>  * copy-on-write.

**Searched.** The kernel's XFS documentation at v7.3, all five files under `Documentation/filesystems/xfs/`, does not mention `UNSHARE`. The behaviour above is from the man pages and the source.

#### APFS (macOS)

**What it does.** Read at xnu-12377.121.6. macOS offers `F_PREALLOCATE` through `fcntl(2)`, and its page states no guarantee about later writes.

Source: https://github.com/apple-oss-distributions/xnu/blob/xnu-12377.121.6/bsd/man/man2/fcntl.2 (line breaks collapsed)

> Preallocate file storage space.
> Note: upon success, the space that is allocated can be the size requested,
> larger than the size requested, or (if the

The same page says a hole punched in a cloned file can itself need space.

> to satisfy the request. As an example, a filesystem that supports
> cloned files may return this error if punching a hole requires the
> creation of a clone and there is not enough space available to do so.

Apple's developer documentation says a clone's modified blocks are written elsewhere. That page has no version or date.

Source: https://developer.apple.com/documentation/foundation/about-apple-file-system

> Modifications to the data are written elsewhere, and both files continue to share the unmodified blocks.

**What is Unverified.**

- That macOS has no `fallocate`. Inferred: xnu's system-call table at the same tag lists no call with "alloc" in its name. No Apple source states it.
- Whether APFS overwrites the data of a file that is not cloned and not in a snapshot in place. The APFS Reference (2020-06-22) describes copy-on-write for its own objects. It was searched for `prealloc`, `fallocate`, `ENOSPC` and "out of space", with no hit, and it says nothing on file data. The "About Apple File System" page and the retired APFS guide do not say either.

**Searched.** The xnu `fcntl.2` page, the xnu system-call table, the "About Apple File System" page, and the APFS Reference PDF.

---

## Where a container's writes land

### P4. The container's writable layer

**What it does.** containerd's default snapshotter is overlayfs. A running container's root filesystem is an overlay mount: the image layers are read-only lower directories, and the container's own upper directory sits on the node under containerd's root. Read at containerd v2.4.2.

Source: https://github.com/containerd/containerd/blob/v2.4.2/docs/snapshotters/README.md

> - `overlayfs` (default): OverlayFS. This driver is akin to Docker/Moby's "overlay2" storage driver, but containerd's implementation is not called "overlay2".

Source: https://github.com/containerd/containerd/blob/v2.4.2/defaults/defaults_unix.go

> 	DefaultRootDir = "/var/lib/containerd"

Source: https://github.com/containerd/containerd/blob/v2.4.2/plugins/snapshots/overlay/overlay.go

> 	return filepath.Join(o.root, "snapshots", id, "fs")

> 			fmt.Sprintf("upperdir=%s", o.upperPath(s.ID)),

That root is the snapshotter's directory under containerd's root, unless the plugin's `root_path` is set. containerd's own root is a setting too, with `/var/lib/containerd` its default.

Source: https://github.com/containerd/containerd/blob/v2.4.2/plugins/snapshots/overlay/plugin/plugin.go (line breaks collapsed)

> 			if config.RootPath != "" {
> 				root = config.RootPath

Source: https://github.com/containerd/containerd/blob/v2.4.2/cmd/containerd/server/server.go (line breaks collapsed)

> 				plugins.PropertyRootDir:      filepath.Join(config.Root, id),

**A file created at runtime** exists only in the upper directory. Inferred: its reads and writes go to the upper filesystem directly, because the kernel's overlayfs documentation says that once a file is in the upper layer the overlay "simply provides direct access" to it.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/filesystems/overlayfs.rst?h=v7.3 (line breaks collapsed)

> Once the copy_up is complete, the overlay filesystem simply provides direct access to the newly created file in the upper filesystem - future operations on the file are barely noticed by the overlay filesystem

**A file that came from an image layer** is copied up the first time it is opened for writing.

> When a file in the lower filesystem is accessed in a way that requires write-access, such as opening for write access, changing some metadata etc., the file is first copied from the lower filesystem to the upper filesystem (copy_up).

The source confirms that opening for write, or with `O_TRUNC`, triggers it, and that `fallocate` on an overlay file is passed to the real file underneath.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/overlayfs/overlayfs.h?h=v7.3

> 	return ((OPEN_FMODE(flags) & FMODE_WRITE) || (flags & O_TRUNC));

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/overlayfs/file.c?h=v7.3

> 		ret = vfs_fallocate(realfile, mode, offset, len);

Inferred: `fallocate(2)` needs a descriptor open for writing, and opening an image-layer file for writing has already copied it up. So `fallocate` never itself triggers copy-up, and it always reaches the upper filesystem. The copy-up needs space at open time, but not always for the whole file. Within one filesystem, overlayfs first tries a clone, which shares blocks instead of writing them. It skips holes where the lower filesystem supports `SEEK_DATA`. An open with `O_TRUNC` copies up no data at all. Otherwise it writes the file's data into the upper filesystem.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/overlayfs/copy_up.c?h=v7.3 (line breaks collapsed)

> 	/* Try to use clone_file_range to clone up within the same fs */

> 	/* Couldn't clone, so now we try to copy the data */

> 		 * Fill zero for hole will cost unnecessary disk space

> 	/* maybe truncate regular file. this has no effect on dirs */
> 	if (flags & O_TRUNC)
> 		ctx.stat.size = 0;

Inferred: a file copied up by a clone shares its blocks with the image layer, so P3's case for shared blocks applies to it, and a mode-0 `fallocate` on XFS leaves them shared.

**With GKE image streaming.** Autopilot clusters always use image streaming for eligible images, and Standard clusters may enable it. With it, a container's root filesystem is a remote filesystem. The page was last updated 2026-11-10.

Source: https://cloud.google.com/kubernetes-engine/docs/how-to/image-streaming

> Autopilot clusters automatically use Image streaming to pull eligible images.

> With Image streaming, GKE uses a remote filesystem as the root filesystem for any containers that use eligible container images.

The page does not say where a container's own writes to that root filesystem go, or on which filesystem. GKE's changelog names the snapshotter behind it, `gcfs-snapshotter`, which this file did not research. Unverified: the writable layer's filesystem, and whether a write there is in place, for a container whose image is streamed.

**The upper filesystem.** overlayfs refuses NFS as the upper layer.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/filesystems/overlayfs.rst?h=v7.3 (line breaks collapsed)

> The upper filesystem will normally be writable and if it is it must support the creation of trusted.* and/or user.* extended attributes, and must provide valid d_type in readdir responses, so NFS is not suitable.

Which filesystem holds `/var/lib/containerd` on a GKE node is under P8. On COS, the release notes of two releases and the image layout of one current GKE build name ext4 for the stateful partition, and a 2023 Google post names ext4 for the Local SSD ephemeral array. Neither is confirmed for every image.

**Lifetime.** The writable layer belongs to the container, not the pod. A container that restarts starts without what it wrote there. Read at kubernetes/website `adf3bf8`.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/tasks/configure-pod-container/configure-volume-storage.md (line breaks collapsed)

> A Container's file system lives only as long as the Container does. So when a Container terminates and restarts, filesystem changes are lost.

**Another container's writable layer.** Where a pod shares one process namespace, its containers can see each other's filesystems, subject to file permissions.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/tasks/configure-pod-container/share-process-namespace.md (line breaks collapsed)

> **Container filesystems are visible to other containers in the pod through the `/proc/$pid/root` link.** This makes debugging easier, but it also means that filesystem secrets are protected only by filesystem permissions.

**Searched.** `overlayfs.rst` at v7.3 does not mention `fallocate`. The behaviour above is from the source.

### P5. `emptyDir`

**What every `emptyDir` shares.** All containers in a pod see the same `emptyDir`, and its data is deleted when the pod leaves the node, for any reason. Eviction is one such reason. Read at kubernetes/website `adf3bf8`.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/reference/storage/volume-types.md (line breaks collapsed)

> All containers in the Pod can read and write the same files in the `emptyDir` volume

> When a Pod is removed from a node for any reason, the data in the `emptyDir` is deleted permanently.

Its data outlives a restart of a container.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/volumes.md

> For any kind of volume in a given Pod, data is preserved across container restarts.

**On disk (the default).** An `emptyDir` lives on the filesystem that holds the kubelet's root directory.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/volumes.md (line breaks collapsed)

> The storage medium (such as Disk or SSD) of an `emptyDir` volume is determined by the medium of the filesystem holding the kubelet root dir (typically `/var/lib/kubelet`).

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/reference/storage/volume-types.md (line breaks collapsed)

> By default `emptyDir` volumes are stored on whatever medium that backs the node such as disk, SSD, or network storage, depending on your environment.

A write into a file reserved there behaves as that filesystem does: P1 for ext4, P3 for a copy-on-write filesystem.

**In memory (`medium: Memory`).** Kubernetes mounts a tmpfs, and its pages count against the memory limit of the container that wrote them.

> If you set the `emptyDir.medium` field to `"Memory"`, Kubernetes mounts a tmpfs (RAM-backed filesystem) for you instead. While tmpfs is very fast, be aware that, unlike disks, files you write count against the memory limit of the container that wrote them.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/ephemeral-storage.md (line breaks collapsed)

> The kubelet tracks `tmpfs` emptyDir volumes as container memory use, rather than as local ephemeral storage.

tmpfs supports `fallocate` for mode 0, `KEEP_SIZE` and `PUNCH_HOLE`, and allocates the pages at the call. Each page is charged to a memory cgroup. Read at Linux v7.3.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/mm/shmem.c?h=v7.3

> 	if (mode & ~(FALLOC_FL_KEEP_SIZE | FALLOC_FL_PUNCH_HOLE))
> 		return -EOPNOTSUPP;

> 	error = mem_cgroup_charge(folio, fault_mm, gfp);

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/admin-guide/cgroup-v2.rst?h=v7.3 (line breaks collapsed)

> A memory area is charged to the cgroup which instantiated it and stays charged to the cgroup until the area is released.

The tmpfs is also mounted with a size of its own: the smallest of the node's allocatable memory, the pod's memory limit and the volume's `sizeLimit`. Past that size tmpfs refuses with `ENOSPC`, `fallocate` included. Read at Kubernetes v1.37.2 and Linux v7.3.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/emptydir/empty_dir.go

> 	// size limit defaults to node allocatable (pods can't consume more memory than all pods)

> 	// volume local size is  used if and only if less than what pod could consume

> 		options = append(options, fmt.Sprintf("size=%d", ed.sizeLimit.Value()))

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/filesystems/tmpfs.rst?h=v7.3 (line breaks collapsed)

> The limit of allocated bytes for this tmpfs instance.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/mm/shmem.c?h=v7.3 (line breaks collapsed)

> 	/* Try to avoid a swapstorm if len is impossible to satisfy */
> 	if (sbinfo->max_blocks && end - start > sbinfo->max_blocks) {
> 		error = -ENOSPC;

Inferred: on a memory-backed `emptyDir`, a reservation is memory, charged when `fallocate` runs. It is not on the node's disk. Two things can fill there: the tmpfs mount's own size, which refuses with `ENOSPC`, and the memory limit of the cgroup charged for the pages. C2's "on the node's disk" does not apply. The kernel's `tmpfs.rst` does not mention `fallocate`; this is from the source.

**Huge pages (`medium: HugePages`).** A third medium mounts hugetlbfs, bounded by the pod's huge-page request. The kernel's documentation says files there do not support write system calls, so this file does not follow that medium further.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/emptydir/empty_dir.go (line breaks collapsed)

> 	return ed.mounter.MountSensitiveWithoutSystemd("nodev", dir, "hugetlbfs", []string{pageSizeMountOption}, nil)

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/tasks/manage-hugepages/scheduling-hugepages.md (line breaks collapsed)

> EmptyDir volumes backed by huge pages may not consume more huge page memory than the pod request.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/admin-guide/mm/hugetlbpage.rst?h=v7.3 (line breaks collapsed)

> While read system calls are supported on files that reside on hugetlb file systems, write system calls are not.

### P6. Mounted volumes

#### Persistent Disk (GKE)

**What it does.** A Persistent Disk is a block device, and the CSI driver formats it when first mounted. The default filesystem is ext4, in the driver's source at v1.29.1 and in Google's page.

Source: https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver/blob/v1.29.1/pkg/gce-pd-csi-driver/node.go

> 	defaultLinuxFsType           = "ext4"

Source: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver (last updated 2026-11-10)

> The default filesystem type for Compute Engine persistent disks in GKE is ext4. You can also use the xfs storage type as long as your node image supports it.

Inferred: on a Persistent Disk volume with the default filesystem, P1's ext4 behaviour applies. With `xfs` chosen, P3's XFS paragraph applies only to blocks that are shared.

This is the default for a Persistent Disk **volume**. It says nothing about the node's boot disk (P8).

#### Filestore (NFS)

**What it does.** Filestore serves NFSv3 by default, and NFSv4.1 if asked, on GKE 1.33 or later and on the service tiers that offer it. No Google page read lists NFSv4.2.

Source: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/filestore-csi-driver (last updated 2026-11-10)

> Filestore uses the NFSv3 file system protocol on the Filestore instance by default and supports any NFSv3-compatible client.

> It can take the following values: NFS_V3 (default) and NFS_V4_1. The default protocol is NFS_V3.

> The Filestore CSI driver supports the NFSv4.1 file system protocol with GKE version 1.33 or later.

> The required GKE version depends on the Filestore service tier, and the features you intend to use.

**Mechanism.** NFS gained a space reservation only in NFSv4.2, as the optional operation `ALLOCATE`.

Source: https://www.rfc-editor.org/rfc/rfc7862.txt (line breaks collapsed)

> The ALLOCATE operation guarantees that any future writes to the region it was successfully called for will not fail with NFS4ERR_NOSPC.

The promise does not depend on where the blocks are. The server may allocate later, and must still keep it.

> It is not required that the server allocate the space to the file before returning success. The allocation can be deferred; however, it must be guaranteed that it will not fail for lack of space.

The RFC's authors state why the operation was added, and why writing zeros, which is glibc's emulation, is not enough.

> Currently, in order to achieve such a guarantee, applications zero the entire file. The initial zeroing allocates the backing blocks, and all subsequent writes are overwrites of already-allocated blocks. This approach is not only inefficient in terms of the amount of I/O done; it is also not guaranteed to work on file systems that are log-structured or deduplicated.

The Linux client sends `ALLOCATE` only to a server that has the v4.2 capability. NFSv3 has no `fallocate` at all, and the call returns `EOPNOTSUPP`.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/nfs/nfs42proc.c?h=v7.3

> 	if (!nfs_server_capable(inode, NFS_CAP_ALLOCATE))
> 		return -EOPNOTSUPP;

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/open.c?h=v7.3

> 	if (!file->f_op->fallocate)
> 		return -EOPNOTSUPP;

The NFSv2 and NFSv3 file operations in `fs/nfs/file.c` at v7.3 have no `fallocate` entry (searched: no hit), and `NFS_CAP_ALLOCATE` is set only in the v4.2 minor version's capabilities in `nfs4proc.c`.

On NFSv4.2 the client sends mode 0 as `ALLOCATE`.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/nfs/nfs4file.c?h=v7.3

> 	switch (mode) {
> 	case 0:

> 	return nfs42_proc_allocate(filep, offset, len);

Inferred: on Filestore, with either protocol it offers, `fallocate(2)` returns `EOPNOTSUPP`. glibc's `posix_fallocate` then writes a byte every 4096 bytes at most over the network (P2), which the RFC says does not guarantee a reservation.

#### Cloud Storage FUSE

**What it does.** Read at gcsfuse v4.0.0. gcsfuse does not implement `fallocate`.

Source: https://github.com/GoogleCloudPlatform/gcsfuse/blob/v4.0.0/docs/troubleshooting.md (line breaks collapsed)

> - **Fallocate:** Used for pre-allocating disk space for a file so that disk space does not run out before writing. This is usually not implemented for Cloud based FUSE products as the disk space running out is not a concern there.

That is the authors' stated reason, and it is about the bucket. gcsfuse writes nothing in place. It stages a new or modified file in a local temporary directory and uploads the whole object, except for appends to files of at least 2 MB.

Source: https://github.com/GoogleCloudPlatform/gcsfuse/blob/v4.0.0/docs/semantics.md (line breaks collapsed)

> Modifying even a single bit of an object results in the full re-upload of the object. The exception is if an append is done to the end of a file, where the original file is at least 2MB, then only the appended content is uploaded.

> As new and modified files are fully staged in the local temporary directory until they are written out to Cloud Storage, you must ensure that there is enough free space available to handle staged content when writing large files.

Streaming writes are the default since v3, but only for a new file written in order. Modifying an existing file reverts to staging.

> Modifying existing files, or doing out-of-order writes (whether from the same file handle or concurrent writes from multiple file handles) will cause GCSFuse to automatically revert to the existing write path of staging writes to a temporary file on disk.

A streamed write is not staged on disk. It holds memory instead, and falls back to staging past a limit on concurrent files.

> which is a new write path that uploads data directly to Google Cloud Storage (GCS) as it's written without fully staging the file in the temp-dir.

> Each file opened for streaming writes will consume approximately 96MiB of RAM during the upload process.

> on low-spec machines, writes will automatically fall back to legacy staged writes if more than 4 files are concurrently opened for streaming writes.

Streaming can be switched off.

> You can revert to the previous default write path (staging writes to a temporary file on disk) using the `--enable-streaming-writes=false` flag or `write:enable-streaming-writes: false` in the config file.

The two paths finish at different points. A staged file is uploaded on close or on `fsync`. A streamed file is not finalized by `fsync`. It is finalized, and visible, on close, or earlier by a rename, a read or a downward truncate, after which later writes to it are staged.

> Upon closing or fsyncing the file, the file is then written to your Cloud Storage bucket and the temp-file is deleted.

> When streaming writes are enabled, the fsync operation will not finalize the object on GCS. Instead, the object will be finalized only when the file is closed. Only finalized objects are visible to the end user.

> Rename operation on a file undergoing writes via streaming writes will be finalized and then renamed.

> However, performing a read operation will finalize the object on GCS. Any subsequent write operations to that file will then automatically revert to legacy staged writes.

> If a file is truncated downwards using truncate() or ftruncate() while streaming writes are in progress, the file on GCS is finalized, and any subsequent writes revert to legacy staged writes.

On GKE, streaming needs a recent version.

Source: https://cloud.google.com/storage/docs/cloud-storage-fuse/performance (last updated 2026-11-17)

> Enabling streaming writes requires Cloud Storage FUSE version 3.0 which is available on Google Kubernetes Engine versions 1.32.1-gke.1729000 or later.

On GKE the staging directory is an `emptyDir` by default.

Source: https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-storage-fuse-csi-driver-sidecar (last updated 2026-11-24)

> This scenario might apply if you need to replace the default emptyDir volume for Cloud Storage FUSE to stage the files in write operations.

> This is useful if you need to write files larger than 10 GiB on Autopilot clusters.

Inferred: the default staging `emptyDir` is in the pod and counts towards its ephemeral storage, which Autopilot caps at 10 GiB outside its exceptions (P7, P8). The page does not say whether that `emptyDir` is on disk or in memory.

Google's overview states that file locking is not supported either.

Source: https://cloud.google.com/storage/docs/cloud-storage-fuse/overview (last updated 2026-11-17)

> File locking and file patching: Cloud Storage FUSE does not support file locking or file patching.

Inferred: on a Cloud Storage FUSE volume there is no reservation to make, and a rewrite is never in place. A rewrite, or any write that is not sequential into a new file, is staged, and the space that can run out is the staging volume's, an `emptyDir` by default (P5). A sequential write into a new file is streamed and holds memory instead, where streaming writes are on and within their limit, and its object is not finalized by `fsync`, only on close or earlier by a rename, a read or a downward truncate; otherwise it is staged too.

#### FUSE in general

Whether `fallocate` works depends on the FUSE daemon. The kernel turns a daemon's "not implemented" into a permanent `EOPNOTSUPP` for that mount. libfuse documents the same contract as the kernel's man page.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/fuse/file.c?h=v7.3

> 	if (err == -ENOSYS) {
> 		fm->fc->no_fallocate = 1;
> 		err = -EOPNOTSUPP;

Source: https://github.com/libfuse/libfuse/blob/fuse-3.18.3/include/fuse_lowlevel.h (line breaks collapsed)

> 	 * If this request is answered with an error code of ENOSYS, this is
> 	 * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
> 	 * future fallocate() requests will fail with EOPNOTSUPP without being
> 	 * send to the filesystem process.

Source: https://github.com/libfuse/libfuse/blob/fuse-3.18.3/include/fuse.h (line breaks collapsed)

> 	 * request to specified range is guaranteed not to fail because of lack
> 	 * of space on the file system media.

The kernel's `fuse.rst` at v7.3 does not mention `fallocate`.

#### A volume more than one pod mounts

A mounted volume need not belong to one pod. A `ReadWriteOnce` volume can be used by several pods on one node.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/persistent-volumes.md (line breaks collapsed)

> ReadWriteOnce access mode still can allow multiple pods to access (read from or write to) that volume when the pods are running on the same node.

Inferred: two pods that mount one such volume, or one `hostPath` (P7), can open one file. Whether a lock between them holds depends on that filesystem (P10).

### Summary by layer

"Unverified" means no primary source read names the filesystem. "Inferred" means the cell follows from the sources above and no source states it.

| Where the file is | Filesystem underneath | `fallocate` mode 0 | First write into the range in place | A later rewrite in place | What "full" means there |
| --- | --- | --- | --- | --- | --- |
| Writable layer, file created at runtime | The one holding the overlay snapshotter's root: under `/var/lib/containerd` by default, or its `root_path` if set (P4). On GKE: ext4 in the COS releases, the COS build and the Local SSD layout P8 names; otherwise Unverified (P8). Under GKE image streaming: Unverified (P4) | Passed to the upper filesystem (P4) | As the upper filesystem does (Inferred) | As the upper filesystem does (Inferred) | The node filesystem, or the pod's ephemeral-storage limit (P7) |
| Writable layer, file from an image layer | The same, after a copy-up at open (P4) | Passed to the upper filesystem, after copy-up (Inferred) | As the upper filesystem does; if the copy-up cloned, the blocks are shared (Inferred, P3) | As the upper filesystem does; if the copy-up cloned, the blocks are shared (Inferred, P3) | As above, and the copy-up itself may need space for the file's data, less after a clone, a hole or `O_TRUNC` (P4) |
| `emptyDir` on disk | The one holding the kubelet root dir (P5). On GKE: ext4 in the COS releases, the COS build and the Local SSD layout P8 names; otherwise Unverified (P8) | As that filesystem does | ext4: yes (P1). btrfs: in place only while no snapshot, taken or pending, or other reference shares the extent and the kernel's other checks pass, and can still fail on metadata space. ZFS: nothing reserved (P3) | ext4: yes. btrfs: no, unless `NOCOW`, the extent is not shared and the other checks pass, and can still fail on metadata space. ZFS: no (P3) | The node filesystem; or the `sizeLimit` or the pod's limit, each enforced by eviction, not by a failed write. An `emptyDir` does not count towards a container's own limit (P7) |
| `emptyDir`, `medium: Memory` | tmpfs (P5) | Pages allocated and charged to memory (P5) | Yes, into the allocated pages (Inferred) | Yes (Inferred) | The tmpfs size (the smallest of node allocatable memory, the pod's memory limit and `sizeLimit`), with `ENOSPC` past it; or the memory limit of the cgroup charged for the pages (P5) |
| Persistent Disk volume | ext4 by default, or xfs (P6) | ext4: allocates (P1) | ext4: yes (P1) | ext4: yes (P1) | The volume. It is not ephemeral storage (P7) |
| Filestore volume | NFSv3 or NFSv4.1 (P6) | `EOPNOTSUPP` (Inferred, P6) | No reservation exists | Unverified: depends on the server's filesystem | The Filestore instance |
| Cloud Storage FUSE volume | FUSE, backed by a bucket (P6) | Not implemented: `EOPNOTSUPP` (P6) | No: a new file written in order is streamed where streaming writes are on and within their limit; otherwise it is staged and uploaded whole | No | For a staged write, the staging volume, an `emptyDir` by default; for a streamed write, memory (P6) |

---

## Eviction

### P7. How the kubelet measures and enforces ephemeral storage

**What counts.** Read at kubernetes/website `adf3bf8` and Kubernetes v1.37.2.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/ephemeral-storage.md (line breaks collapsed)

> If the kubelet is managing local ephemeral storage as a resource, then the kubelet measures storage use in:

> - `emptyDir` volumes, except _tmpfs_ `emptyDir` volumes
> - directories holding node-level logs
> - writeable container layers

The kubelet measures only in the configurations the page supports: a single filesystem, a separate runtime filesystem, or a split image filesystem. Everything below about a pod's own limit holds only where it measures.

> If you have a different configuration, then the kubelet does not apply resource limits for ephemeral local storage.

> If the kubelet is not measuring local ephemeral storage, then a Pod that exceeds its local storage limit will not be evicted for breaching local storage resource limits.

**How it is measured.** By a periodic scan, or, behind a feature gate that is still beta and off by default at v1.37.2, by filesystem project quotas, which the kubelet applies to `emptyDir` volumes only. Quotas monitor; they do not refuse writes. The writable layer's figure comes from containerd's walk, below, whether or not quotas are on.

> The kubelet performs regular, scheduled checks that scan each `emptyDir` volume, container log directory, and writeable container layer.

> Project quotas let you monitor storage use; they do not enforce limits.

Each method has a condition of its own. A scan does not see a file that was deleted while still open. The quota path needs user namespaces and project quotas on the filesystem.

> In this mode, the kubelet does not track open file descriptors for deleted files.

> To use quotas to track a pod's resource usage, the pod must be in a user namespace.

> Ensure that the root filesystem (or optional runtime filesystem) has project quotas enabled.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/1029-ephemeral-storage-quotas/README.md (line breaks collapsed)

> This proposal applies project quotas to emptydir volumes on qualifying filesystems (ext4fs and xfs with project quotas enabled).

> to monitor storage consumption for ephemeral storage (currently for emptydir volumes only)

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/emptydir/empty_dir.go (line breaks collapsed)

> 			if err := fsquota.AssignQuota(ed.mounter, dir, ed.pod.UID, mounterSize, userNamespacesEnabled); err != nil {

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/features/kube_features.go (line breaks collapsed)

> 		{Version: version.MustParse("1.31"), Default: false, PreRelease: featuregate.Beta},

The scan sums allocated blocks, not the file's apparent size. That holds for the kubelet's walk over `emptyDir` volumes and logs, and for containerd's walk over the writable layer.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/util/fs/fs.go

> 			usage.Bytes += int64(s.Blocks) * int64(512) // blocksize in bytes

Source: https://github.com/containerd/containerd/blob/v2.4.2/plugins/snapshots/overlay/overlay.go

> 		du, err := fs.DiskUsage(ctx, upperPath)

Source: https://github.com/containerd/continuity/blob/v0.5.0/fs/du_unix.go

> 				size += stat.Blocks * blocksUnitSize

The quota path counts blocks too.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/util/fsquota/common/quota_common_linux_impl.go

> 	return getQuantity(v.mountpoint, id, "-b", 1024, v.allowEmptyOutput)

`st_blocks` counts the blocks allocated to a file.

Source: https://man7.org/linux/man-pages/man7/inode.7.html (line breaks collapsed)

> This field indicates the number of blocks allocated to the file, 512-byte units, (This may be smaller than st_size/512 when the file has holes.)

**Does a reserved but unwritten file count?** Inferred, from the pieces above: yes, wherever `fallocate` allocates blocks, the kubelet is measuring local ephemeral storage, and the file is still linked where the scan walks (or, for an `emptyDir` given a quota, project-quota monitoring is on; the writable layer is always walked). ext4 allocates them at the call (P1), so they appear in `st_blocks` and in the pod's measured usage, before any data is written. On ZFS, where mode 0 creates a sparse file (P3), they would not. No Kubernetes or containerd source states the case in words: the docs pages above were searched for `fallocate`, preallocation and reserved space, with no hit. On tmpfs the reservation is counted as memory, not as ephemeral storage (P5).

**When measurement happens.** The kubelet evaluates thresholds on its housekeeping interval, 10 s by default. containerd refreshes the writable layer's figure every 10 s by default.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/scheduling-eviction/node-pressure-eviction.md (line breaks collapsed)

> The kubelet evaluates eviction thresholds based on its configured `housekeeping-interval`, which defaults to `10s`.

Source: https://github.com/containerd/containerd/blob/v2.4.2/internal/cri/config/config_unix.go

> 		StatsCollectPeriod:       10,

The `emptyDir` part of the figure can be older than that. The kubelet computes volume usage in the background on its own period, one minute by default, and serves it from a cache.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/kubelet/config/v1beta1/types.go (line breaks collapsed)

> 	// volumeStatsAggPeriod is the frequency for calculating and caching volume
> 	// disk usage for all pods.
> 	// Default: "1m"

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/server/stats/fs_resource_analyzer.go

> // GetPodVolumeStats returns the PodVolumeStats for a given pod.  Results are looked up from a cache that
> // is eagerly populated in the background, and never calculated on the fly.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/stats/helper.go

> 	if vstats, found := resourceAnalyzer.GetPodVolumeStats(podUID); found {

Inferred: a threshold check every 10 s can see the same cached `emptyDir` figure several times.

**Over its own limit.** Where the kubelet is measuring local ephemeral storage, three limits are checked, each on its own: an `emptyDir`'s `sizeLimit`, the pod's total, and each container's own limit. Going over any one of them evicts the pod, unless the kubelet classes it as critical: a static or mirror pod, or one at system-critical priority. A container's usage is its logs, plus its writable layer unless the node has a dedicated image filesystem. Nothing refuses the writes first: the project quota the kubelet may give an `emptyDir` carries no limit of its own (Inferred from the code below, with the docs' "they do not enforce limits").

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/storage/ephemeral-storage.md (line breaks collapsed)

> If a Pod is using more ephemeral storage than you allow it to, the kubelet sets an eviction signal that triggers Pod eviction.

> For container-level isolation, if a container's writable layer and log usage exceeds its storage limit, the kubelet marks the Pod for eviction.

> For pod-level isolation the kubelet works out an overall Pod storage limit by summing the limits for the containers in that Pod. In this case, if the sum of the local ephemeral storage usage from all containers and also the Pod's `emptyDir` volumes exceeds the overall Pod storage limit, then the kubelet also marks the Pod for eviction.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go (line breaks collapsed)

> 		if m.emptyDirLimitEviction(logger, podStats, pod) {

> 		if m.podEphemeralStorageLimitEviction(logger, podStats, pod) {

> 		if m.containerEphemeralStorageLimitEviction(logger, podStats, pod) {

> 				// the emptyDir usage exceeds the size limit, evict the pod

> 	// pod stats api summarizes ephemeral storage usage (container, emptyDir, host[etc-hosts, logs])

> 		containerUsed := diskUsage(containerStat.Logs)

> 		if !*m.dedicatedImageFs {

> 	if kubelettypes.IsCriticalPod(pod) {

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/types/pod_update.go (line breaks collapsed)

> 	if IsStaticPod(pod) {
> 		return true
> 	}
> 	if IsMirrorPod(pod) {
> 		return true
> 	}
> 	if pod.Spec.Priority != nil && IsCriticalPodBasedOnPriority(*pod.Spec.Priority) {

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/util/fsquota/quota_linux.go (line breaks collapsed)

> 		fsbytes := ibytes
> 		if fsbytes > 0 {
> 			fsbytes = -1
> 		}

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/volume/util/fsquota/common/quota_common_linux_impl.go (line breaks collapsed)

> 	if bytes < 0 || bytes > v.maxQuota {
> 		bytes = v.maxQuota
> 	}

The source's pod limit is not always the docs' sum. The eviction manager takes it from a shared helper, which adds sidecar containers (restartable init containers) to the sum of the containers' limits, then takes the larger of that and what any other init container needs. The helper has further inputs, pod-level limits and pod overhead, not traced here for ephemeral storage.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go

> 	podLimits := resourcehelper.PodLimits(pod, resourcehelper.PodResourcesOptions{})

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/component-helpers/resource/helpers.go

> 	// init containers define the minimum of any resource

> 		// Is the init container marked as a restartable init container?
> 		if isRestartableInitContainer(&container) {
> 			// and add them to the resulting cumulative container requests
> 			addResourceList(result, containerResources)

> 	maxResourceList(result, initContainerResources)

The eviction manager checks the limits before, and apart from, node pressure, and asks for a grace period of one second.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go

> 	// evict pods if there is a resource usage violation from local volume temporary storage

> 	immediateEvictionGracePeriodSeconds = 1

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/helpers.go

> 	podEphemeralStorageMessageFmt = "Pod ephemeral local storage usage exceeds the total limit of containers %s. "

**Under node pressure.** When the node filesystem falls below a threshold (`nodefs.available<10%` by default), the kubelet first reclaims dead containers and unused images, then evicts pods. The signal is the filesystem's own free space, not the per-pod scan. For disk pressure it ranks them by whether usage exceeds the request, then priority, then usage minus request.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/scheduling-eviction/node-pressure-eviction.md (line breaks collapsed)

> - `nodefs.available<10%`

> `nodefs.available` := `node.stats.fs.available`

> The kubelet attempts to [reclaim node-level resources](#reclaim-node-resources) before it terminates end-user pods.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/helpers.go

> 		orderedBy(exceedDiskRequests(stats, fsStatsToMeasure, diskResource), priority, disk(stats, fsStatsToMeasure, diskResource)).Sort(pods)

Which usage is compared depends on the signal and on how the node lays out its filesystems. With no separate image filesystem, every disk signal compares all of a pod's usage. With images and containers together on a separate image filesystem, the node filesystem's signal compares logs and local volumes, and the image filesystem's signal compares the writable layer. With the container filesystem split from the images, the node filesystem's signal compares logs, local volumes and the writable layer. Inode signals compare inodes.

> 		signalToRankFunc[evictionapi.SignalNodeFsAvailable] = rankDiskPressureFunc([]fsStatsType{fsStatsImages, fsStatsRoot, fsStatsLogs, fsStatsLocalVolumeSource}, v1.ResourceEphemeralStorage)

> 		signalToRankFunc[evictionapi.SignalNodeFsAvailable] = rankDiskPressureFunc([]fsStatsType{fsStatsLogs, fsStatsLocalVolumeSource}, v1.ResourceEphemeralStorage)

> 		signalToRankFunc[evictionapi.SignalImageFsAvailable] = rankDiskPressureFunc([]fsStatsType{fsStatsRoot, fsStatsImages}, v1.ResourceEphemeralStorage)

> 		signalToRankFunc[evictionapi.SignalNodeFsAvailable] = rankDiskPressureFunc([]fsStatsType{fsStatsLogs, fsStatsLocalVolumeSource, fsStatsRoot}, v1.ResourceEphemeralStorage)

The four lines come, in order, from the branch with no image filesystem, the two lines of the branch where images and containers share one, and the branch where the container filesystem is split from the images.

Inferred: a reservation adds to the usage the ranking compares, just as the same amount of written data would, but only for a byte signal whose ranking includes that part of the pod's usage. An `emptyDir` reservation counts under the node filesystem's signal. A reservation in the writable layer counts under the image filesystem's signal where images and containers share a separate one, and under the node filesystem's signal otherwise. A reservation in an existing file adds no inodes. More usage can move a pod up the order, or leave it where it is.

**What the pod's processes see.** The pod's phase becomes `Failed` with reason `Evicted`. Any `preStop` hook runs first, inside the grace period. Then each container's main process gets its stop signal: SIGTERM, unless the image's `STOPSIGNAL` names another (or the container's lifecycle does, behind the `ContainerStopSignals` gate, alpha and off by default at v1.37.2). Once the grace period ends, SIGKILL goes to any process still running.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go

> 		status.Phase = v1.PodFailed

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/workloads/pods/pod-lifecycle.md (line breaks collapsed)

> kubelet makes requests to the container runtime to attempt to stop the containers in the pod by first sending a TERM (aka. SIGTERM) signal, with a grace period timeout, to the main process in each container.

> Once the grace period has expired, the KILL signal is sent to any remaining processes

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/workloads/pods/pod-termination.md (line breaks collapsed)

> Many container runtimes respect the `STOPSIGNAL` value defined in the container image and, if different, send the container image configured STOPSIGNAL instead of TERM.

> If a stop signal is defined in the lifecycle, this will override the signal defined in the container image.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/features/kube_features.go (line breaks collapsed)

> 	ContainerStopSignals: {
> 		{Version: version.MustParse("1.33"), Default: false, PreRelease: featuregate.Alpha},

Source: https://github.com/containerd/containerd/blob/v2.4.2/internal/cri/server/container_stop.go (line breaks collapsed)

> 			// Container stopped on first signal no need for SIGKILL

The grace periods in the docs and in the source differ. The docs give hard thresholds a "`0s` grace period", and the eviction manager passes one second for limit and hard-threshold evictions, which the runtime manager raises to two before stopping each container. The docs say the pod's `terminationGracePeriodSeconds` is not respected, and for a soft threshold the source takes the smaller of `evictionMaxPodGracePeriod` and that value.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/concepts/scheduling-eviction/node-pressure-eviction.md (line breaks collapsed)

> If you use [hard eviction thresholds](#hard-eviction-thresholds), the kubelet uses a `0s` grace period (immediate shutdown) for termination.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go

> 				gracePeriodOverride = min(m.config.MaxPodGracePeriodSeconds, *pod.Spec.TerminationGracePeriodSeconds)

The container runtime is not given the one second. The eviction override reaches the runtime manager through the pod worker, and before stopping each container the kubelet subtracts the time any `preStop` hook took, then raises any shorter grace period to two seconds.

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/pod_workers.go

> 	// we allow other parts of the kubelet (namely eviction) to request this pod be terminated faster

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/kuberuntime/kuberuntime_container.go (line breaks collapsed)

> 	// always give containers a minimal shutdown window to avoid unnecessary SIGKILLs
> 	if gracePeriod < minimumGracePeriodInSeconds {
> 		gracePeriod = minimumGracePeriodInSeconds
> 	}

> 		gracePeriod = gracePeriod - m.executePreStopHook(ctx, pod, containerID, containerSpec, gracePeriod)

Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/kuberuntime/kuberuntime_manager.go (line breaks collapsed)

> 	// A minimal shutdown window for avoiding unnecessary SIGKILLs
> 	minimumGracePeriodInSeconds = 2

**Stated why: eviction rather than refusing writes.** Kubernetes' design documents state that eviction is the only enforcement, and that a limit can be overrun before it acts. KEP 361 introduced ephemeral-storage limits.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-storage/361-local-ephemeral-storage-isolation/README.md (line breaks collapsed)

> * evicting pods. (Pod eviction is the only mechanism supported in this feature
>   to limit the resource usage)

> * Enforcing limits such that the pod would be restricted to the desired storage
>   limit (The limit might be exceeded temporarily before Pod can be evicted).

KEP 1029 added quotas for measurement only, and kept eviction as the enforcement.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-node/1029-ephemeral-storage-quotas/README.md (line breaks collapsed)

> * Elimination of eviction as a means of enforcing ephemeral-storage
>   limits.  Pods that hit their ephemeral-storage limit will still be
>   evicted by the kubelet even if their storage has been capped by
>   enforcing quotas.

**Constraints.** The kubelet shares the node filesystem with the runtime, images and system, and measures from outside the container. KEP 1029 names a risk of enforcing with a quota instead: a container that cannot write its log may not be able to exit.

> * The SIG raised the possibility of a container being unable to exit
>   should we enforce quotas, and the quota interferes with writing the
>   log.

**Costs and dissent.** Both KEPs name the cost of acting after the fact.

> * It is reactive rather than proactive.  It does not prevent a pod
>   from overshooting its limit; at best it catches it after the fact.
>   On a fast storage medium, such as NVMe, a pod may write 50 GB or
>   more of data before the housekeeping performed once per minute
>   catches up to it.  If the primary volume is the root partition, this
>   will completely fill the partition, possibly causing serious
>   problems elsewhere on the system.

Source: https://github.com/kubernetes/enhancements/blob/cac930cb9d7c70192016865425f943c339414011/keps/sig-storage/361-local-ephemeral-storage-isolation/README.md (line breaks collapsed)

> * Pod will be evited when resource limit is exceeded. This might not be the ideal
>   way of handling resource over use.

The KEP's "once per minute" is its own figure for the scan at the time. Today the kubelet computes `emptyDir` usage on `volumeStatsAggPeriod`, one minute by default (above). The current docs' 10 s housekeeping interval is how often thresholds are evaluated, not how often `emptyDir` usage is computed.

**Tracked by none of this.** A `PersistentVolume`, including Filestore and Cloud Storage FUSE, is not local ephemeral storage, and the kubelet does not count it towards a pod's limit. Inferred from the list of what counts, above. A `hostPath` volume is not counted either, but it sits on the node's filesystem, so filling it is node pressure.

Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/docs/reference/storage/volume-types.md (line breaks collapsed)

> `hostPath` volume usage is not treated as ephemeral storage usage. You need to monitor the disk usage by yourself because excessive `hostPath` disk usage will lead to disk pressure on the node.

### P8. GKE node disks

**What the sources say.**

- A GKE node's file system is installed on its boot disk: a balanced Persistent Disk by default from GKE 1.24, from the types the machine series offers (N4 takes only Hyperdisk Balanced).

  Source: https://cloud.google.com/kubernetes-engine/docs/how-to/custom-boot-disks (last updated 2026-11-10)

  > When you create a GKE cluster or node pool, you can choose the type of Persistent Disk onto which the Kubernetes node file system is installed for each node.

  > By default, GKE uses balanced Persistent Disks in version 1.24 or later.

  > The available disk types depend on the machine series of your nodes. For example, the N4 machine series only supports hyperdisk-balanced as a boot disk.

- On Container-Optimized OS, writable state such as `/var` is mounted from the stateful partition of the boot disk.

  Source: https://cloud.google.com/kubernetes-engine/docs/concepts/node-images (last updated 2026-11-24)

  > These paths are meant for storing data that persists for the lifetime of the boot disk. They are mounted from /mnt/stateful_partition.

  > GKE Autopilot nodes always use Container-Optimized OS with containerd (cos_containerd), which is the recommended node operating system.

- COS ships ext4 and XFS, and recommends ext4. This is about the filesystems available, not about the stateful partition.

  Source: https://cloud.google.com/container-optimized-os/docs/concepts/supported-filesystems (last updated 2026-11-10)

  > Container-Optimized OS comes with a fully-supported EXT4 filesystem. Container-Optimized OS recommends using the EXT4 filesystem for production workloads.

- With Local SSD for ephemeral storage, GKE mounts the kubelet's and containerd's directories on the Local SSD, and the recommended option puts `emptyDir` volumes, container writable layers and images there. On the current Local SSD concepts page, the recommended option names no filesystem and only the legacy options name ext4.

  Source: https://cloud.google.com/kubernetes-engine/docs/concepts/local-ssd (last updated 2026-11-12)

  > When you configure Local SSDs, GKE automatically mounts the following directories onto the Local SSD volume for improved performance: /var/lib/kubelet, /var/log/pods, and /var/lib/containerd.

  > This approach puts the emptyDir volumes, container-writable layers, and images that together constitute your node ephemeral storage on Local SSD.

  > Format: File System (ext-4)

  A Google engineering post from 2023 says the recommended option, `--ephemeral-storage-local-ssd`, formats the array ext4 and bind-mounts the runtime's and kubelet's directories onto it. The current docs page does not repeat it.

  Source: https://cloud.google.com/blog/products/containers-kubernetes/high-performance-aiml-storage-through-local-ssd-support-on-gke (February 17, 2023)

  > RAID0 all Local SSDs to an array /dev/md/0, format it to an ext-4 file system and mount to path /mnt/stateful_partition/kube-ephemeral-ssd

  > bind mount the ephemeral storage which consists of the container runtime root directory, kubelet root directory and pod logs root directory to the Local SSDs mount point /mnt/stateful_partition/kube-ephemeral-ssd

  The post's option also labels each node, and Autopilot selects Local SSD ephemeral storage by the same label. Inferred from the shared label: an Autopilot node with Local SSD ephemeral storage has the layout the post describes. No source read says so. Autopilot does not offer the mixed layout.

  > create and add the label cloud.google.com/gke-ephemeral-storage-local-ssd=true to each node

  Source: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/local-ssd (line breaks collapsed)

  > You explicitly select a machine series to run your Pods and specify either the cloud.google.com/gke-ephemeral-storage-local-ssd: "true" nodeSelector or a capacity reservation that has Local SSDs.

  Source: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/mixed-local-ssd (line breaks collapsed)

  > GKE Autopilot clusters do not support mixed raw block and ephemeral storage.

- COS release notes name ext4 for the stateful partition, in two releases seven years apart. Each note is about its release, not about every COS image.

  Source: https://docs.cloud.google.com/container-optimized-os/docs/release-notes/m69 (entry `cos-69-10895-102-0`, Dec 20, 2018; page last updated 2026-11-10)

  > Enabled the "metadata_csum" ext4 feature on the stateful partition.

  Source: https://docs.cloud.google.com/container-optimized-os/docs/release-notes/dev (entry `cos-dev-138-20309-0-0`, November 11, 2026; page last updated 2026-11-13)

  > The ext4 journal of the stateful partition is now resized appropriately with the rest of the stateful partition.

- The image layout of one COS build that GKE ships names ext4 for the stateful partition. The GKE 1.37 changelog records an update of COS to `cos-133-19999-44-159`.

  Source: https://docs.cloud.google.com/kubernetes-engine/docs/changelogs/1.37 (page last updated 2026-11-23)

  > Updated Container-Optimized OS (COS) to cos-133-19999-44-159.

  Google's build instructions name the COS boards.

  Source: https://docs.cloud.google.com/container-optimized-os/docs/how-to/building-from-open-source (last updated 2026-11-10) (line breaks collapsed)

  > To build Container-Optimized OS, specify lakitu (x86 image) or lakitu-arm64 (Arm image) for the board name

  The manifest for build `19999.44.159` pins the board overlays and the image scripts.

  Source: https://cos.googlesource.com/cos/manifest-snapshots/+/refs/tags/19999.44.159/snapshot.xml

  > <project name="cos/overlays/board-overlays" path="src/overlays" revision="6f0500e57881f9e42a397c3165a840fc0f573bbd" upstream="refs/heads/release-R133" dest-branch="refs/heads/release-R133"/>

  > <project name="third_party/platform/crosutils" path="src/scripts" revision="de78cf41a49221040144160deee6a7e478a87c9d" upstream="refs/heads/release-R133" dest-branch="refs/heads/release-R133"/>

  The `lakitu` board inherits the project's layout, which inherits crosutils' legacy layout and sets ext4 options on the stateful partition.

  Source: https://cos.googlesource.com/cos/overlays/board-overlays/+/6f0500e57881f9e42a397c3165a840fc0f573bbd/overlay-lakitu/scripts/disk_layout.json

  >   "parent": "../../project-lakitu/scripts/disk_layout.json",

  Source: https://cos.googlesource.com/cos/overlays/board-overlays/+/6f0500e57881f9e42a397c3165a840fc0f573bbd/project-lakitu/scripts/disk_layout.json

  >   "parent": "legacy_disk_layout.json",

  >         # STATE

  >           "ext4": "-O metadata_csum"

  Source: https://cos.googlesource.com/third_party/platform/crosutils/+/de78cf41a49221040144160deee6a7e478a87c9d/build_library/legacy_disk_layout.json (line breaks collapsed)

  >         "label": "STATE",
  >         "type": "data",
  >         "fs_format": "ext4",

  This is the layout the image is built with. Inferred: a node booted from that image has an ext4 stateful partition, from which `/var` is mounted (above). No running node was inspected.

- Where ephemeral storage is on the boot disk, the default, GKE sets the eviction threshold at 10% of that disk. Where Local SSDs back it, the page gives a separate calculation.

  Source: https://cloud.google.com/kubernetes-engine/docs/concepts/plan-node-sizes (last updated 2026-11-10)

  > The eviction threshold is always 10% of the total boot disk capacity.

  > By default, ephemeral storage is backed by the node boot disk. In this case, GKE determines the value of the eviction threshold as follows:

  > If your ephemeral storage is backed by local SSDs, GKE calculates the eviction threshold as follows:

**Ephemeral-storage limits on GKE.**

- On Autopilot, every pod has an ephemeral-storage limit: GKE sets each container's limit equal to its request. The default request is 1 GiB per container, or 100 MiB for a container in a DaemonSet. A pod's total must lie between 10 MiB and 10 GiB unless the page specifies otherwise: Performance-class and accelerator pods, and hardware with Local SSDs, have higher maximums. Ephemeral storage is on the boot disk unless the node has Local SSDs.

  Source: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests (last updated 2026-11-23) (line breaks collapsed)

  > Note: Ephemeral storage limits must always be explicitly set equal to requests. GKE modifies your Pods to enforce this rule.

  > In all other Autopilot Pods regardless of the GKE version, the total ephemeral storage request across all of the containers in the Pod must be between 10 MiB and 10 GiB unless otherwise specified.

  > Ephemeral storage uses the VM boot disk unless your nodes have local SSDs attached.

  > Containers in DaemonSets CPU: 50 mCPU Memory: 100 MiB Ephemeral storage: 100 MiB All other containers Ephemeral storage: 1 GiB

  > In GKE version 1.29.3-gke.1038000 and later, Performance class Pods and hardware accelerator Pods support a maximum ephemeral storage request of 56 TiB unless the hardware includes local SSDs.

- On Standard, a pod has a limit only if its spec sets one (P7), as submitted or as filled in when it is admitted. A namespace's `LimitRange` can give a container a default limit, ephemeral storage included, and the admission plugin writes it into a container that sets none. Unverified, and not searched: whether a GKE Standard cluster has such a default for ephemeral storage.

  Source: https://github.com/kubernetes/website/blob/adf3bf8ca5ad2caf642cbe4d7dd82e8b0eead607/content/en/blog/_posts/2022/local-storage-capacity-isolation-ga.md

  > Similar to CPU and memory, admin could use LimitRange to set default container’s local storage request/limit, and/or minimum/maximum resource constraints for a namespace.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/plugin/pkg/admission/limitranger/admission.go

  > 			container.Resources.Limits[k] = v.DeepCopy()
- Whether the kubelet measures local ephemeral storage on GKE nodes. Google's 2023 post states it for the Local SSD option it describes, in a worked example of a pod with ephemeral-storage limits and an `emptyDir` `sizeLimit`.

  Source: https://cloud.google.com/blog/products/containers-kubernetes/high-performance-aiml-storage-through-local-ssd-support-on-gke (February 17, 2023)

  > kubelet eviction manager will measure the disk usage of all containers usage plus emptyDir usage, evict the pod if the storage usage exceeds its limit 300GiB

  > if the pod's emptyDir used up more local ephemeral storage than 50GiB, the pod will be evicted from the node

  For other GKE configurations it is Inferred, not stated: a GKE node reports allocatable ephemeral storage. At v1.37.2 the kubelet adds ephemeral storage to the node's capacity, and runs its limit evictions, only when the same configuration field, `localStorageCapacityIsolation`, is set. Whether the node's filesystems are laid out as P7's supported configurations require is a separate inference, in the next bullet.

  Source: https://cloud.google.com/kubernetes-engine/docs/concepts/plan-node-sizes (last updated 2026-11-10)

  > ephemeral-storage: "47060071478"

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/cm/container_manager_linux.go (line breaks collapsed)

  > 	if localStorageCapacityIsolation {
  > 		rootfs, err := cm.cadvisorInterface.RootFsInfo()

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/eviction/eviction_manager.go (line breaks collapsed)

  > 	if m.localStorageCapacityIsolation {
  > 		if evictedPods := m.localStorageEviction(logger, activePods, statsFunc); len(evictedPods) > 0 {

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/pkg/kubelet/kubelet.go

  > 	return kl.GetConfiguration().LocalStorageCapacityIsolation

- Whether a GKE node has a separate image filesystem, which decides the ranking and the container-limit findings in P7. Inferred, not stated: on COS, `/var` is mounted from the stateful partition (above), so `/var/lib/containerd` and `/var/lib/kubelet` share it; with Local SSD ephemeral storage, GKE mounts both onto the same Local SSD volume (above). No Google page says so in those terms.

**What is sourced, and what is Unverified.**

- **COS stateful partition:** ext4 in `cos-69-10895-102-0` and `cos-dev-138-20309-0-0`, by their release notes, and in the image layout of `cos-133-19999-44-159`, a build the GKE 1.37 changelog names (Inferred from the layout for a running node). For the other COS releases it is Inferred from those three, not confirmed. The first review's triage searched the notes for milestones 121, 125, 129, 133 and 137 and found no mention; the author did not repeat that search.
- **Local SSD ephemeral array:** ext4 by Google's 2023 post. The current docs do not say. Google's page on the newer layout, which splits Local SSD between ephemeral and raw block storage, names no filesystem.
- **Ubuntu node image's root:** Unverified.

Pages read, each fetched on 2026-11-25 and searched for `ext4`, `ext-4`, `xfs` and `stateful_partition`:

- GKE node images, custom boot disks, plan node sizes, node system configuration, Local SSD concepts, Local SSD ephemeral storage, and mixed Local SSDs for raw block and ephemeral storage;
- COS disks and file system, and COS supported filesystems;
- GKE storage troubleshooting, and NotReady-node troubleshooting;
- the COS release notes for milestone 69 and for the dev channel, and the 2023 Local SSD post, which the first review found.

On the documentation pages, the only "ext4" is in the Persistent Disk support matrix, in the COS example of mounting an attached disk, and in the legacy Local SSD formats. The author's own web search did not find the release notes or the post, so it was not exhaustive. COS's source tree was read only for build `19999.44.159`, at the commits its manifest pins. A `mount` on a node would settle the question; that was not within this ticket's authority.

### P9. A full disk: eviction, or a failed write?

**What the sources say.** No Kubernetes or Google source states that a full disk usually shows up as an eviction. Searched: the Kubernetes pages under P5 and P7, and the GKE and COS pages under P8, for `ENOSPC`, "no space left", "out of disk" and "write fail", with no hit.

Google's pages put eviction and failure side by side.

Source: https://cloud.google.com/kubernetes-engine/docs/troubleshooting/storage (last updated 2026-11-17)

> Continued high disk usage can lead to node instability, Pod evictions, and application failures.

Source: https://cloud.google.com/kubernetes-engine/docs/concepts/plan-node-sizes (last updated 2026-11-10)

> If this disk becomes full, the system may evict workloads or become unstable.

KEP 1029, quoted under P7, says a pod can fill the root partition before the kubelet catches it.

**Inferred**, from P7:

- The kubelet evaluates thresholds every 10 s or so (P7). Node pressure is judged from the filesystem's own free space, at 10% by default; how often that figure is refreshed was not traced (Unverified). A pod's own limits are judged from usage refreshed on its own periods, a minute by default for an `emptyDir` (P7). Between two measurements, or when one pod writes faster than the threshold's headroom, the filesystem can fill. A write that needs new space then fails with `ENOSPC`, or writes fewer bytes than asked. On a filesystem that allocates space after the write, such as NFS, the failure can surface at a later `write`, `fsync` or `close` instead (`write(2)` and `fsync(2)`, below). A write into a reserved range is the case under the last point.
- Writes that need new space on a volume the kubelet does not count towards the pod (P7) fail when that volume is full. Where the volume has its own device, such as a Persistent Disk or Filestore, nothing is evicted. Where it is on the node's own filesystem, such as a `hostPath`, filling it is node pressure, and the kubelet may evict pods.
- A pod over its own limit, over an `emptyDir`'s `sizeLimit`, or with a container over that container's limit, is evicted, not refused, where the kubelet is measuring local ephemeral storage and the pod is not critical (P7). That part of C5 is sourced, under those conditions.
- In DuckDB's opt-in memory-mapped mode, on ext4 at Linux v7.3, a write into an unallocated page of the database file on a full filesystem raises `SIGBUS`, whose default action ends the process, instead of returning `ENOSPC` (Inferred from source, P10).
- Under node pressure a pod's reservation counts towards the usage by which it is ranked, for a byte signal whose ranking includes it (P7). A reservation does let writes into the reserved range succeed after the filesystem is full, where P1's conditions hold. It does not protect the pod from being evicted.

Source: https://man7.org/linux/man-pages/man2/write.2.html (line breaks collapsed)

> Note that a successful write() may transfer fewer than count bytes.

> The device containing the file referred to by fd has no room for the data.

> On some filesystems, including NFS, it does not even guarantee that space has successfully been reserved for the data. In this case, some errors might be delayed until a future write(), fsync(2), or even close(2).

Source: https://man7.org/linux/man-pages/man2/fsync.2.html (line breaks collapsed)

> fd is bound to a file on NFS or another filesystem which does not allocate space at the time of a write(2) system call, and some previous write failed due to insufficient storage space.

---

## DuckDB and SQLite

### P10. DuckDB: more than one process, and fork

**What it does.** Read at DuckDB 2.0 (duckdb-web `c53d1db`, `docs/2.0`, which `/docs/stable` redirects to) and DuckDB v2.0.1.

A database file opened directly takes one read-write process, or any number of read-only ones.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/connect/concurrency.md (line breaks collapsed)

> 1. **Read-write mode:** one process can both read and write to the database.

> 2. **Read-only mode:** multiple processes can read from the database, but no processes can write

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/troubleshooting.md

> DuckDB allows only a single process to write to a database file at a time.

The rule is enforced by a whole-file advisory lock, `fcntl(F_SETLK)` on POSIX, and a second writer fails with "Could not set lock on file".

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp (line breaks collapsed)

> 	int rc = fcntl(fd, F_SETLK, &fl);

> 	throw IOException({{"errno", std::to_string(retained_errno)}}, "Could not set lock on file \"%s\": %s", path,

Where `fcntl` fails with `ENOTSUP`, the code's case for a filesystem without locks, a read-only open goes ahead without a lock, and a read-write open fails. Any other failure to take the lock, a conflicting lock among them, fails the open, read-only included.

> 		if (retained_errno == ENOTSUP) {
> 			if (flags.Lock() == FileLockType::READ_LOCK) {
> 				// file lock not supported here; ignore for read-only
> 				return;

> 			extended_error = "File locks are not supported for this file system, cannot open the file in "
> 			                 "read-write mode. Try opening the file in read-only mode";

A read-only open of the database file asks for a read lock, and a read-write open for a write lock. The lock function maps them to a shared and an exclusive `fcntl` lock.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> 		file_flags = FileFlags::FILE_FLAGS_READ | FileFlags::FILE_FLAGS_NULL_IF_NOT_EXISTS | FileLockType::READ_LOCK;

> 		file_flags = FileFlags::FILE_FLAGS_WRITE | FileFlags::FILE_FLAGS_READ | FileLockType::WRITE_LOCK;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 	fl.l_type = flags.Lock() == FileLockType::READ_LOCK ? F_RDLCK : F_WRLCK;

Source: https://man7.org/linux/man-pages/man2/fcntl_locking.2.html (line breaks collapsed)

> An exclusive lock excludes all other locks, both shared and exclusive.

> Advisory locks are not enforced and are useful only between cooperating processes.

Inferred from source: while one process holds the file for writing, another process's DuckDB open of it fails with "Could not set lock on file", read-only included, where the filesystem honours locks. The lock is advisory, so it does not stop a process that reads the file without DuckDB.

DuckDB 2.0 documents two ways for more than one process to write: its Quack client-server protocol, and the DuckLake format with a PostgreSQL catalog. The DuckDB 1.4 page, at the same commit, said writing from more than one process was not supported.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/connect/concurrency.md (line breaks collapsed)

> Writing to DuckDB's native database format from multiple processes is supported through the [Quack remote protocol]({% link docs/2.0/quack/overview.md %}), which turns DuckDB into a client-server database.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/1.4/connect/concurrency.md (line breaks collapsed)

> Writing to DuckDB from multiple processes is not supported automatically and is not a primary design goal

Quack makes one DuckDB instance a server, and other instances write through it. DuckLake is a different format, coordinated through a catalog. Inferred, with the lock rule above: neither lets two processes write one native file directly.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/quack/overview.md (line breaks collapsed)

> The Quack extension turns a DuckDB instance into a server that other DuckDB instances (clients) can connect to over HTTP.

> A server is started from an existing DuckDB session. Everything that the session can see (in-memory tables, attached files, schemas) becomes reachable over the remote protocol.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/connect/concurrency.md (line breaks collapsed)

> By coordinating through a central PostgreSQL catalog, DuckDB instances can achieve concurrent read-writes on the same database.

Neither came first in 2.0. The 2.0 page says Quack was first released in 1.5.3. The 1.5 page, at the same commit, says Quack was in beta as of 1.5.2, and that DuckLake 1.0 was published in April 2026. The two pages differ on Quack's first release. The 1.5.3 announcement narrows it: Quack was introduced on 12 May 2026 and ships as a core extension from 1.5.3. No source read names the first version that could load it. At this commit Quack's FAQ calls it beta, with a protocol not yet stable.

> (first released in DuckDB 1.5.3) with substantial performance and stability improvements.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/1.5/connect/concurrency.md (line breaks collapsed)

> Quack in beta stage as of DuckDB 1.5.2

> The DuckLake 1.0 specification and its DuckDB implementation, both intended for production use, were [published](https://ducklake.select/2026/04/13/ducklake-10/) in April 2026.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/_posts/2026-05-20-announcing-duckdb-153.md (line breaks collapsed)

> On May 12, we introduced Quack, our new remote protocol that turns DuckDB into a client-server database.

> These include the Quack client-server protocol, which is now available as a core extension

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/quack/faq.md (line breaks collapsed)

> Not yet. Quack is currently in a beta state. You can use Quack for prototyping but it is still in development, and breaking changes are expected to happen.

> but the protocol is not yet stable.

Within the one process, many threads may write.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/connect/concurrency.md (line breaks collapsed)

> As long as there are no write conflicts, multiple concurrent writes will succeed. Appends will never conflict, even on the same table.

**Stated why.** The docs, the DuckDB team's blog and the GitHub user `Mytherin` each give the reason: state kept in memory, which other processes cannot see. `Mytherin`'s profile gives the name "Mark" and says "I'm the co-founder of DuckLabs"; that this is Mark Raasveldt, a co-author of the DuckDB papers, is Inferred. Every DuckDB comment quoted below is by a member of the DuckDB GitHub organisation, by GitHub's own association label, except two pull requests under "How DuckDB writes its own file", whose authors are named there as contributors.

Source: https://github.com/Mytherin

> bio: I'm the co-founder of DuckLabs. I like databases.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/connect/concurrency.md (line breaks collapsed)

> The reason for this concurrency model is to allow for the caching of data in RAM for faster analytical queries, rather than going back and forth to disk during each query.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/_posts/2026-05-12-quack-remote-protocol.md (line breaks collapsed)

> There are very good technical reasons why we could not make this work, most notably, the fact that DuckDB keeps a bunch of state in main memory and would have to synchronize that state if multiple processes start making changes simultaneously.

Source: https://github.com/duckdb/duckdb/discussions/4899#discussioncomment-3812950 (line breaks collapsed)

> Concurrent writes to the same DuckDB file from multiple processes are not supported and are unlikely to be supported in the future. Even if the processes write to disjoint tables, there will still be contention in the storage as the processes will want to write to the same WAL file, the same blocks, etc. This requires coordination between the different processes that is out-of-scope for an in-process database.

On why readers in other processes may not run beside a writer: a checkpoint rewrites the file under them.

Source: https://github.com/duckdb/duckdb/issues/77#issuecomment-907594565 (line breaks collapsed)

> having both readers and writers active at the same time could potentially cause odd behavior when the writer performs a checkpoint of the database while the readers are in the middle of reading from the database file.

Hannes Mühleisen (GitHub `hannes`, whose profile names DuckDB Labs) proposed the lock in 2019, for a stated reason, and `Mytherin` implemented it.

Source: https://github.com/duckdb/duckdb/issues/77#issuecomment-483273715

> We should use fcntl() and windows equivalent to make sure there are only readers or only one writer. Benefit of fcntl() is that it cleans up the locks when process dies.

**Constraints.** DuckDB is in-process and analytical, and caches data, the catalog and checkpointed blocks in memory. Its locks are POSIX record locks, which belong to a process. So a second instance inside the same process is not caught.

Source: https://github.com/duckdb/duckdb/issues/17343#issuecomment-2848633035

> This is expected behavior but for a different reason - on POSIX systems (Linux/MacOS) file-locks are process wide, as such we cannot protect against the same file being opened in read/write mode within the same process.

**How DuckDB writes its own file.** Read at DuckDB v2.0.1 and duckdb-web `c53d1db`. Most of this passage is read from the code. Where the code shows a behaviour that no comment or document states, the statement is marked Inferred from source.

An attached database is opened in one of three I/O modes. Buffered I/O is the default, and the other two are opt-in through the `IO_MODE` option of `ATTACH`. This passage covers the default and the memory-mapped mode; direct I/O is under "Candidates not examined".

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/storage/storage_options.hpp

> 	//! Buffered pread/pwrite via FileHandle (default).
> 	BUFFERED_IO,
> 	//! Memory-map the file; reads/writes go through the mapped region.
> 	MMAP,
> 	//! Unbuffered I/O (O_DIRECT / FILE_FLAG_NO_BUFFERING / F_NOCACHE).
> 	DIRECT_IO,

> 	//! IO_MODE attach option; empty defaults to BUFFERED_IO.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/storage_manager.cpp

> 	auto resolved_io_mode = storage_options.io_mode ? *storage_options.io_mode : FileIOMode::BUFFERED_IO;

*The default path: where a write lands.* The DuckDB CIDR 2020 paper describes the file as fixed-size blocks after a header that lists the free blocks. The block size it gives is the 2020 figure.

Source: https://hannes.muehleisen.org/publications/CIDR2020-raasveldt-muehleisen-duckdb.pdf (line breaks collapsed)

> As an exception, the WAL is written to a separate file until consumed by a checkpoint. The storage file is partitioned into fixed-size blocks of 256KB which are read and written in their entirety.

At v2.0.1 a block is written at an offset fixed by its id. A block that is needed takes the first id on the free list, which is an ordered set, so the lowest free id (Inferred from the container). If the list is empty, it takes the next id past the highest block the header records, which need not be the end of the file (below).

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 	ChecksumAndWrite(context, buffer, BLOCK_START + NumericCast<idx_t>(block_id) * GetBlockAllocSize());

> 	if (!free_list.empty()) {
> 		// The free list is not empty, so we take its first element.
> 		block_id = *free_list.begin();
> 		// erase the entry from the free list again
> 		free_list.erase(free_list.begin());

> 		block_id = max_block++;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/storage/single_file_block_manager.hpp

> 	//! The list of free blocks that can be written to currently
> 	set<block_id_t> free_list;

A checkpoint does not write changed table data over the blocks the current header points to. The checkpointer marks a rewritten segment's old blocks as modified. A block that storage already used is not reused until the next checkpoint.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/table/column_data_checkpointer.cpp

> 	// if there are any persistent segments, we will mark their old block ids as modified
> 	// since the segments will be rewritten their old on disk data is no longer required

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 		// this block was used in storage, we cannot directly re-use it
> 		// add it to the modified blocks indicating it will be re-usable after the next checkpoint

The header is written last. DuckDB syncs the file, then writes the header into whichever of its two header slots is not active, and syncs again. Only then does it return the checkpoint's freed blocks to the free list.

> 	// We need to fsync BEFORE we write the header to ensure that all the previous blocks are written as well

> 	// now write the header to the file, active_header determines whether we write to h1 or h2
> 	// note that if active_header is h1 we write to h2, and vice versa

> 	// switch active header to the other header

> 		for (auto &block : checkpoint_freed_blocks) {
> 			modified_blocks.erase(block);

Inferred from source: in DuckDB's own terms, a checkpoint writes changed data to another block, and switching to the other header slot makes it current. In the filesystem's terms the result differs by block. A block reused from the free list is usually a write over a range of the file that was written before. It is not always one. A checkpoint writes the header, with the free list and the block count, before it truncates free blocks off the tail. So the header on disk still lists those ids as free, and counts them. Once the file is opened again, a write to one of them extends the file (Inferred from source). Where `trim_free_blocks` is set, a reused block can also lie in a hole that a checkpoint punched (Inferred from source). Either write needs new space. If the free list is empty, a block is taken past the highest block the header records. That extends the file where the file ends there. It lands inside the file where the file is longer: in the memory-mapped mode below, or where a mode-0 `fallocate` has extended the file and no checkpoint has yet truncated it (Inferred from source). The two header slots are written at fixed offsets, outside the block allocator, so once the file exists a header write is over a range written before.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 	header.block_count = NumericCast<idx_t>(max_block);

> 	max_block = UnsafeNumericCast<block_id_t>(header.block_count);

> 		auto block = reader.Read<block_id_t>(context);
> 		free_list.insert(block);

> 	auto location = active_header == 1 ? Storage::FILE_HEADER_SIZE : Storage::FILE_HEADER_SIZE * 2;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/checkpoint_manager.cpp

> 	block_manager.WriteHeader(context, header);

> 	// truncate the file
> 	block_manager.Truncate();

Metadata blocks are an exception. Metadata is kept in slots, 64 to a block, and a slot is taken from an existing block that has one free. Inferred from source: such a block is converted to an in-memory copy and written back at its own id, so its other slots are rewritten in place.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/storage/metadata/metadata_manager.hpp

> 	static constexpr const idx_t METADATA_BLOCK_COUNT = 64;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/metadata/metadata_manager.cpp

> 	// check if there is any free space left in an existing block

> 		// this block is a disk-backed block, yet we are planning to write to it
> 		// we need to convert it into a transient block before we can write to it

> 			// Convert the temporary block to a persistent block.

> 			auto new_block = block_manager.ConvertToPersistent(context, kv.first, std::move(block_handle),

*The default path: the file's size.* At the end of a checkpoint, free blocks at the tail of the file are cut off. The block manager also truncates when the file is longer than its last used block. The size it compares is the one the file system reports, and on POSIX the call is `ftruncate`.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 	// reverse iterate over the free-list

> 	auto new_size = NumericCast<idx_t>(BLOCK_START + NumericCast<idx_t>(max_block) * GetBlockAllocSize());
> 	if (blocks_to_truncate > 0 || handle->GetFileSize() > new_size) {
> 		handle->Truncate(new_size);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 	return file_metadata.file_size;

> 	if (ftruncate(fd, new_size) != 0) {

Inferred from source: a mode-0 `fallocate` that extended the file past its last used block would be cut back at the next checkpoint, since the file is then longer than that block. A `KEEP_SIZE` reservation does not change the file's size. Neither `truncate(2)` nor `fallocate(2)` says whether `ftruncate` frees blocks reserved past the end of the file. ext4's code at Linux v7.3 does: for a file that uses extents, an `ftruncate` to the current size or below removes every whole block past the new size, reserved blocks included (Inferred from source). So on ext4 a checkpoint that truncates the file also cuts a `KEEP_SIZE` range past the end (Inferred from source). A checkpoint truncates only when it frees blocks at the tail or the file is longer than its last used block, and a `KEEP_SIZE` range alone makes neither true (Inferred from source).

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/inode.c?h=v7.3

> 		 * Call ext4_truncate() even if i_size didn't change to
> 		 * truncate possible preallocated blocks.
> 		 */
> 		if (attr->ia_size <= oldsize) {
> 			rc = ext4_truncate(inode);

> 		err = ext4_ext_truncate(handle, inode);

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/extents.c?h=v7.3

> 	last_block = (inode->i_size + sb->s_blocksize - 1)
> 			>> EXT4_BLOCK_SIZE_BITS(sb);

> 	err = ext4_ext_remove_space(inode, last_block, EXT_MAX_BLOCKS - 1);

Free blocks inside the file stay allocated on the default path, and the documentation's way to give their space back is to copy the database.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/operations_manual/footprint_of_duckdb/reclaiming_space.md

> DuckDB uses a single-file format, which has some inherent limitations w.r.t. reclaiming disk space.

> To compact the database, you can create a fresh copy of the database using the

**Stated why, for the block layout.** The CIDR 2020 paper gives the reason for a single file. It also states the order of a checkpoint's writes: new blocks first, and last the root pointer and the free list in the header, atomically. The code comments give the same order, and say how recovery tells from the root block whether a checkpoint completed. No stated reason was found for writing changed data to other blocks rather than over the old ones. Inferred: writing elsewhere leaves the blocks the current header points to intact until the header switches. Searched: the SIGMOD 2019 and CIDR 2020 papers, the 2024 post on ACID, and the storage internals page under `docs/2.0`.

Source: https://hannes.muehleisen.org/publications/CIDR2020-raasveldt-muehleisen-duckdb.pdf (line breaks collapsed)

> The fact that the database only consists of a single file was inspired by SQLite [3] and repeated user requests for this feature in MonetDBLite.

> Checkpoints will first write new blocks that contain the updated data to the file and as a last step update the root pointer and the free list in the header atomically.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/checkpoint_manager.cpp

> 	// during recovery we use this:
> 	// * if the root meta block matches the checkpoint entry, we know the checkpoint was completed
> 	// * if the root meta block does not match the checkpoint entry, we know the checkpoint was not completed

*Hole punching.* The block manager can punch holes over the blocks a checkpoint frees. It does so only when `trim_free_blocks` is set, and that option defaults to false. At v2.0.1 it is a field of the C++ configuration with no SQL setting: `settings.json` has no entry for it. The punch is `fallocate(PUNCH_HOLE|KEEP_SIZE)`. On this path it is compiled only on Linux with glibc 2.18 or later. Where `__GLIBC__` is not defined, the guard leaves it out too (Inferred from source).

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 	if (!DBConfig::Get(db).options.trim_free_blocks) {

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/main/config.hpp

> 	//! Whether or not to invoke filesystem trim on free blocks after checkpoint. This will reclaim
> 	//! space for sparse files, on platforms that support it.
> 	bool trim_free_blocks = false;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> #if defined(__linux__)
> 	// FALLOC_FL_PUNCH_HOLE requires glibc 2.18 or up
> #if __GLIBC__ < 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ < 18)
> 	// Nothing

> 	int res = fallocate(fd, FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE, UnsafeNumericCast<int64_t>(offset_bytes),

Under the slow-verifier build flags, the same call first writes zeros over the range. Those flags are for tests, not a default build.

> #if defined(DUCKDB_RUN_SLOW_VERIFIERS) || defined(DUCKDB_ALTERNATIVE_VERIFY)
> 	std::vector<char> zeros(length_bytes, '\0');
> 	Write(handle, zeros.data(), length_bytes, offset_bytes);

The option came from a 2024 pull request by `jkub`, labelled a contributor, which gives the reason: the file system may then free the range. `Mytherin` (a member) welcomed it, and was unsure how well it works across file systems.

Source: https://github.com/duckdb/duckdb/pull/11258

> Add TRIM method to file system, which enables excising a range of the DB file. The OS can drop pages from the page-cache, and the file-system is free to deallocate the range (sparse file support).

> The feature is enabled via a dbconfig.options.trim_free_blocks, which defaults to false.

Source: https://github.com/duckdb/duckdb/pull/11258#issuecomment-2009622498

> I'm very curious how well this works on various file systems/operating systems, but we can experiment with that separately.

On `main`, pull request #28571 by `Robinho-MR` (a contributor), merged on 2026-11-10, makes `trim_free_blocks` a setting, still false by default. It was merged before the v2.0.1 tag, whose commit is dated 2026-11-19, but its commit is not in v2.0.1: GitHub's comparison of the two shows they have diverged.

Source: https://github.com/duckdb/duckdb/pull/28571

> - `trim_free_blocks` -> new setting `trim_free_blocks`

Source: https://github.com/duckdb/duckdb/blob/392cee07532cad39193661814ff35309b7437b1f/src/common/settings.json

>         "name": "trim_free_blocks",
>         "description": "Whether to invoke filesystem trim on free blocks after checkpoint. This reclaims space for sparse files, on platforms that support it.",
>         "type": "BOOLEAN",
>         "scope": "global",
>         "default_value": "false"

Inferred from source: on the default path DuckDB punches no hole in its own file unless the embedding program sets `trim_free_blocks`. With it set, a checkpoint on Linux asks to punch the blocks it frees, except those a live block handle still holds, which return to the free list later without a punch. A punch that fails, as on a filesystem without `PUNCH_HOLE`, is not reported: the database handle drops the result (Inferred from source).

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/single_file_block_manager.cpp

> 	// the block exists - add to blocks in use
> 	free_blocks_in_use.insert(block_id);

> 			if (AddFreeBlock(release_lock, block)) {
> 				fully_freed_blocks.insert(block);

> 		// it is! move it to the regular free list so the block can be re-used

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 	trimmed = (res == 0);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> void DatabaseHandle::Trim(idx_t offset, idx_t length) {
> 	if (mmap_handle) {
> 		mmap_handle->Trim(offset, length);
> 	} else {
> 		handle->Trim(offset, length);

*Preallocation.* DuckDB does not preallocate its own file. Under `src/` at v2.0.1, `fallocate` is called twice, each time with `FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE`, and `posix_fallocate` is never called (searched by the author).

*The WAL.* The write-ahead log is a second file, named after the database file with `.wal` added. The documentation puts it, and the temporary directory below, relative to the database file, and says a clean exit deletes the WAL.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/storage/storage_manager.hpp

> 	string GetWALPath(const string &suffix = ".wal");

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/operations_manual/footprint_of_duckdb/files_created_by_duckdb.md

> DuckDB creates the following files and directories in the working directory (for in-memory connections) or relative to the database file (for persistent connections):

> If DuckDB exits normally, the WAL file is deleted upon exit. If DuckDB crashes, the WAL file is required to recover data.

The WAL is opened for appending. A commit that writes to the WAL flushes it, and the flush syncs the file. With `fsync_mode` at its default, the sync is `fdatasync` where the platform has it and `fsync` otherwise. A commit that fails truncates the WAL back to where it began.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/write_ahead_log.cpp

> 		                                      FileFlags::FILE_FLAGS_APPEND | FileFlags::FILE_FLAGS_MULTI_CLIENT_ACCESS);

> 	// flushes all changes made to the WAL to disk
> 	writer->Sync();

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/storage_manager.cpp

> 	wal.Flush();

> 		// remove any entries written into the WAL by truncating it
> 		wal.Truncate(initial_wal_size);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/serializer/buffered_file_writer.cpp

> void BufferedFileWriter::Sync() {
> 	Flush();
> 	handle->Sync();

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 	bool sync_success = ::fdatasync(fd) == 0;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/settings.json

>         "name": "fsync_mode",
>         "description": "How to synchronize database file changes to stable storage (STANDARD, NONE or FULL). NONE may cause database corruption after an operating system or hardware crash. FULL uses fullfsync on macOS.",
>         "type": "ENUM<FileSyncMode>",
>         "scope": "global",
>         "default_value": "STANDARD"

A commit asks for a checkpoint when the WAL would grow past `checkpoint_threshold`, 16 MiB by default. A count of WAL entries can ask for one too, but that is off by default. A clean close checkpoints the database and deletes the WAL, unless `checkpoint_on_shutdown` is turned off.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/configuration/overview.md

> | `checkpoint_threshold`, `wal_autocheckpoint` | The WAL size threshold at which to automatically trigger a checkpoint, e.g., 1GB. | `VARCHAR` | `16.0 MiB` |

> | `wal_autocheckpoint_entries` | Trigger automatic checkpoint when WAL entry count reaches or exceeds N (0 = disabled). | `UBIGINT` | `0` |

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/storage_manager.cpp

> 	if (expected_wal_size > config.checkpoint_wal_size) {

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/include/duckdb/main/config.hpp

> 	//! Run a checkpoint on successful shutdown and delete the WAL, to leave only a single database file behind
> 	bool checkpoint_on_shutdown = true;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/main/attached_database.cpp

> 				options.wal_action = CheckpointWALAction::DELETE_WAL;

The threshold makes a commit eligible to checkpoint; it does not make the checkpoint run. A commit that cannot take the checkpoint lock does not checkpoint, nor does one that made updates while other transactions are active. The WAL can then grow past the threshold (Inferred from source). A commit whose estimated WAL write reaches `auto_checkpoint_skip_wal_threshold` can skip the WAL and checkpoint instead. A `DETACH` follows `checkpoint_on_detach`, which by default defers to `checkpoint_on_shutdown`.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/transaction/duck_transaction_manager.cpp

> 		return CheckpointDecision("Failed to obtain checkpoint lock - another thread is writing/checkpointing or "

> 				// this transaction has performed updates - we cannot checkpoint

> 		// if we are committing changes and we are not doing a "checkpoint instead of WAL write"

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/configuration/overview.md

> | `auto_checkpoint_skip_wal_threshold` | The estimated WAL write size at which point we will skip writing to the WAL and only checkpoint. Skipping writing to the WAL means concurrent commits are blocked while the checkpoint is happening. | `UBIGINT` | `100000` |

> | `checkpoint_on_detach` | Override checkpoint behavior when detaching a database. ENABLED requests a checkpoint, but the checkpoint does not occur if another connection still references the database. DISABLED never checkpoints, DEFAULT defers to the global checkpoint_on_shutdown setting. | `VARCHAR` | `DEFAULT` |

After a checkpoint, the WAL is deleted and opened again empty. If transactions committed while the checkpoint ran, their log, kept in a second file, is renamed over it instead.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/storage_manager.cpp

> 		fs.TryRemoveFile(wal_path);

> 	// move the secondary WAL over the main WAL
> 	fs.MoveFile(checkpoint_wal_path, wal_path);

> 	return GetWALPath(".wal.checkpoint");

Inferred from source: the WAL is a second file that grows by appends between checkpoints, beside the database file and so in the same directory. A reservation made on the database file does not cover it.

*Spill files.* Intermediates that do not fit in memory go to a temporary directory. It belongs to the DuckDB instance, not to each attached database: by default it is named after the database the instance was opened with, with `.tmp` added, or is `.tmp` for an in-memory instance (Inferred from source). So a file attached to an instance opened on another path has no spill directory of its own beside it. By default the directory may take up to 90% of the disk space available where it is, measured when the cap is set (Inferred from source). Where that space cannot be read, the code's comment says it sets no cap. How DuckDB writes those files was not read.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/docs/2.0/configuration/overview.md

> | `temp_directory` | Set the directory to which temporary files are written. | `VARCHAR` | `⟨database_name⟩.tmp` or `.tmp` (in in-memory mode) |

> | `max_temp_directory_size` | The maximum amount of data stored inside the 'temp_directory' (when set) (e.g., 1GB). | `VARCHAR` | `90% of available disk space` |

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/main/config.cpp

> 	} else if (DBConfig::IsInMemoryDatabase(options.database_path.c_str())) {
> 		options.temporary_directory = ".tmp";
> 	} else {
> 		options.temporary_directory = Path::AddSuffixToPath(options.database_path, ".tmp");

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/main/database.cpp

> 		buffer_manager = make_uniq<StandardBufferManager>(*this, config.options.temporary_directory);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/temporary_file_manager.cpp

> 	auto disk_space = FileSystem::GetAvailableDiskSpace(path);

> 	if (!disk_space.IsValid()) {
> 		// But if it does (i.e because the system call is not implemented)
> 		// we don't cap the available swap space
> 		return DConstants::INVALID_INDEX - 1;

> 	// Only use 90% of the available disk space

*The memory-mapped mode.* `IO_MODE 'MMAP'` maps the file and reads and writes through the mapping. `Mytherin` added it in pull request #22988, merged on 2026-06-02, together with direct I/O. The 2.0 highlights post names both modes in one sentence. No page under `docs/2.0` mentions `IO_MODE`, `MMAP_RESERVE_SIZE` or mmap, the `ATTACH` page included (searched by the author, 475 pages).

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/_posts/2026-08-17-duckdb-20-highlights.md

> along with asynchronous Parquet writes ([#23283](https://github.com/duckdb/duckdb/pull/23283)) and new `MMAP` and `DIRECT_IO` modes ([#22988](https://github.com/duckdb/duckdb/pull/22988)).

The pull request gives the authors' why. It moves caching to the operating system's page cache, for performance. It reserves address space up front so that writes need no remapping.

Source: https://github.com/duckdb/duckdb/pull/22988

> * **MMAP**: Use `mmap` as a back-end for reads and writes. Instead of reading into buffers that we cache explicitly we rely on the OS' page cache to do the caching of data in the files.

> In general these settings should not affect usage - only performance.

> For writing, we rely on reserving address space in the mmaped file up-front. This allows us to just hand out pointers in the file to write to instead of having to do any extending / remapping of the file.

The pull request gives the default reserve as `max(256GB, 2 * file_size)`. The code at v2.0.1 maps the larger of the file's size and the reserve, which is 256 GiB unless `MMAP_RESERVE_SIZE` sets it. With the default reserve the two differ once twice the file's size passes 256 GiB, that is for a file larger than 128 GiB. A file already larger than the reserve is mapped at its own size and not extended (Inferred from source).

> By default we reserve address space is equal to `max(256GB, 2 * file_size)`

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> 	static constexpr idx_t MMAP_DEFAULT_RESERVE_SIZE = idx_t(256) * 1024 * 1024 * 1024; // 256 GiB

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 		mapping_size = MaxValue<idx_t>(initial_file_size, options.reserve_size);
> 		if (initial_file_size < mapping_size) {

A writable mapping first extends the file to the reserve with `ftruncate`, and then maps it shared. DuckDB's comment calls the extension sparse. `truncate(2)` says only that the extension reads as zeros. That it allocates no blocks is DuckDB's statement, not the man page's.

> 	// Writable mappings sparsely extend the file to the reserve size so the region never
> 	// needs to be remapped; read-only mappings just span the existing file.

> 			if (ftruncate(fd, NumericCast<off_t>(mapping_size)) != 0) {

> 		void *mapped = mmap(nullptr, mapping_size, prot, MAP_SHARED, fd, 0);

Source: https://man7.org/linux/man-pages/man2/truncate.2.html (line breaks collapsed)

> If the file previously was shorter, it is extended, and the extended part reads as null bytes ('\0').

The memory-mapped open takes the same lock as the buffered one, so the one-writer rule above holds in this mode too (Inferred from source).

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> // Apply a fcntl advisory lock per flags.Lock(); throws (and closes fd) on failure. Shared
> // by OpenFile and MemoryMapFile.

> 	TryAcquireFileLock(*this, fd, path, flags);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> 		mmap_flags = FileFlags::FILE_FLAGS_READ | FileFlags::FILE_FLAGS_WRITE | FileLockType::WRITE_LOCK;

A block is written by copying it into the mapping, not by a `write` call. A sync is `msync` with `MS_SYNC`. A write past the reserve fails with an error that tells the user to attach again.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/file_buffer.cpp

> 	auto dst = handle.GetDataMutable(location, internal_size);
> 	memcpy(dst, internal_buffer, internal_size);

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> 	if (msync(data, size, MS_SYNC) != 0) {

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> 		throw IOException("Database file \"%s\" would grow to %llu bytes, which exceeds the memory-mapped reserved "
> 		                  "size of %llu bytes. Re-attach with a larger MMAP_RESERVE_SIZE, or without "
> 		                  "IO_MODE='MMAP', to allow further growth.",

In this mode the file stays at its reserve size, and the block manager's size check reads it as 0. So a checkpoint punches a hole over the tail only when it frees blocks at the tail, whether or not `trim_free_blocks` is set (Inferred from source). Its punch is compiled only on Linux, and with glibc only from 2.18. As on the buffered path, a failed punch is not reported (Inferred from source).

> 		// File stays at reserve size in MAP mode; punch a hole to release the tail.
> 		mmap_handle->Trim(new_size, mmap_handle->Size() - new_size);

> idx_t DatabaseHandle::GetFileSize() {
> 	if (mmap_handle) {
> 		return 0;

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/common/local_file_system.cpp

> #if defined(__linux__) && !(defined(__GLIBC__) && (__GLIBC__ < 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ < 18)))
> 	int rc = fallocate(fd, FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE, NumericCast<off_t>(offset),
> 	                   NumericCast<off_t>(length));
> 	return rc == 0;

The mode does not apply to an encrypted database. An encrypted attach in this mode falls back to buffered I/O with a warning, and the memory-map open refuses one as a second guard.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/storage_manager.cpp

> 	// MMAP + encryption would corrupt the file (in-place decryption); demote to BUFFERED_IO.

Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/storage/database_handle.cpp

> 		throw InvalidInputException("MMAP mode is not supported for encrypted databases");

Inferred from source and P7: a writable file in this mode has a size of at least 256 GiB by default. The extension allocates no blocks, so the file's allocated blocks are those already written and any range reserved on it by other means, such as `fallocate`. The kubelet's scan sums allocated blocks, not the apparent size (P7), so it would count those blocks, not the rest of the reserve.

*A full disk in the memory-mapped mode.* A copy into the mapping that lands on a page with no disk block behind it needs space when the page is first written. Under delayed allocation, ext4 reserves the space in the fault and allocates the block later. When free space runs low, or without delayed allocation, it allocates the block in the fault (Inferred from source). On ext4 at Linux v7.3, `ext4_page_mkwrite` retries an `ENOSPC` and then turns the error into `VM_FAULT_SIGBUS`, by way of `vmf_fs_error`. That holds on the delayed-allocation path and on the path that allocates at once.

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/inode.c?h=v7.3

> 	/* Delalloc case is easy... */
> 	if (test_opt(inode->i_sb, DELALLOC) &&
> 	    !ext4_nonda_switch(inode->i_sb)) {
> 		do {
> 			err = block_page_mkwrite(vma, vmf,
> 						   ext4_da_get_block_prep);
> 		} while (err == -ENOSPC &&
> 		       ext4_should_retry_alloc(inode->i_sb, &retries));
> 		goto out_ret;

> 	/* OK, we need to fill the hole... */

> retry_alloc:
> 	/* Start journal and allocate blocks */
> 	err = ext4_block_page_mkwrite(inode, folio, get_block);
> 	if (err == -EAGAIN ||
> 	    (err == -ENOSPC && ext4_should_retry_alloc(inode->i_sb, &retries)))
> 		goto retry_alloc;
> out_ret:
> 	ret = vmf_fs_error(err);

> 	 * a small amount in the end.  Here we just reserve for data.

> 	 * switch to non delalloc mode if we are running low
> 	 * on free block. The free block accounting via percpu

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/include/linux/mm.h?h=v7.3

> 	/* -ENOSPC, -EDQUOT, -EIO ... */
> 	return VM_FAULT_SIGBUS;

`signal(7)` gives `SIGBUS` the default action of terminating the process and dumping core. `mmap(2)` names `SIGBUS` only for access beyond the end of the mapped file, and says nothing about a full disk. DuckDB's `src/` has no handler for `SIGBUS` (searched by the author).

Source: https://man7.org/linux/man-pages/man7/signal.7.html

> Core   Default action is to terminate the process and dump core

> SIGBUS       P2001      Core    Bus error (bad memory access)

Source: https://man7.org/linux/man-pages/man2/mmap.2.html (line breaks collapsed)

> SIGBUS Attempted access to a page of the buffer that lies beyond the end of the mapped file.

Inferred from source, for ext4 at Linux v7.3: in the memory-mapped mode, a write into an unallocated page of the database file on a full filesystem raises `SIGBUS`, whose default action ends the process, rather than returning `ENOSPC` to DuckDB. A write into a page whose blocks are all allocated needs no new data block: on the path that allocates at once, the fault returns early where the page's buffers are all mapped. Whether a write into a reserved, unwritten page can still fail for want of a metadata block, as P1 describes for a buffered write, was not traced for the mapped path. The host application can change the disposition of `SIGBUS`, and DuckDB itself installs no handler. The WAL is still written through the buffered writer, so a full disk fails a WAL write the way P9 describes. OverlayFS hands a mapping to its real file. For a file opened for writing, that is the file in the upper layer (P4). So for a file in a container's writable layer, the fault is the upper filesystem's (Inferred from source). Other filesystems are under "Candidates not examined".

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/ext4/inode.c?h=v7.3

> 	 * Return if we have all the buffers mapped. This avoids the need to do

Source: https://man7.org/linux/man-pages/man7/signal.7.html

> A process can change the disposition of a signal using

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/overlayfs/file.c?h=v7.3

> 	return backing_file_mmap(of->realfile, vma, &ctx);

Source: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/fs/backing-file.c?h=v7.3

> 	vma_set_file(vma, file);

**A process that forks.** No DuckDB documentation page mentions process fork. The author grepped the 475 pages under `docs/2.0` at `c53d1db` for "fork", "forked" and "forking": the two hits use "fork" for a git fork. Of the 176 blog posts, one changelog line mentions it.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/_posts/2026-11-20-announcing-duckdb-201.md

> Fix random functions returning the same values in processes cloned with `fork()`

Three cases are apart here.

- **A child that opens the database itself.** It takes its own lock, so whichever of the two processes holds the write lock makes the other's read-write open fail (Inferred from the per-process lock above). DuckDB's write-lock test has the child open the file for writing first, and asserts that the parent's later read-write open throws. Hannes Mühleisen called the conflict expected.

  Source: https://github.com/duckdb/duckdb/blob/v2.0.1/test/persistence/test_locking.cpp

  > TEST_CASE("Test write lock with multiple processes", "[persistence][.]") {

  > 		// child process
  > 		// open db for writing
  > 		DuckDB db(dbdir);

  > 		// try to open db for writing, this should fail

  Source: https://github.com/duckdb/duckdb/issues/13079#issuecomment-2242260968

  > It looks like Python is forked here, which causes the conflicting lock. You could either switch to read-only locks or somehow disable the forking behaviour.  Either way, it looks like this is expected behaviour.

- **A child that opens its own connection after the parent used DuckDB.** The report in duckdb-python issue #292 is this case. In its reproducer the parent closes its connection before forking, and the child's own `connect` fails, which the reporter puts down to global state copied by `fork()`. The reporter saw it with MotherDuck and not with in-memory connections. A maintainer of the Python client (Evert Lammerts, a member of the DuckDB GitHub organisation) called fork a current limitation.

  Source: https://github.com/duckdb/duckdb-python/issues/292 (line breaks collapsed)

  > When duckdb.connect() is called in a parent process (e.g., a FastAPI/uvicorn server), and a child process is later created via `multiprocessing.Process` using the default fork start method, calling duckdb.connect() in the child process raises:

  > It's worth noting that this doesn't seem to affect in memory connections, looks to be specific to motherduck connections

  Source: https://github.com/duckdb/duckdb-python/issues/292#issuecomment-3852064420

  > As noted in https://github.com/duckdb/duckdb/issues/13079, we are aware that this is a current limitation. We're not planning to fix this in this version of the extension, but we are currently working on an extension that has no global state and is safe for use with fork, with `concurrent.interpreters` and with freethreading.

  For a native file, DuckDB's read-lock test covers one shape of this case. The parent creates and fills the database, and its instance is destroyed, before it forks. The child opens the file read-only. The test asserts that the parent's later read-write open throws and that its read-only open succeeds. It does not assert the child's own open: the parent waits on a counter that the child sets only after opening. A child that opens read-write after the parent used DuckDB is not covered by the test.

  Source: https://github.com/duckdb/duckdb/blob/v2.0.1/test/persistence/test_locking.cpp

  > TEST_CASE("Test read lock with multiple processes", "[persistence][.]") {

  > 	// create the database

  > 	// test read lock
  > 	pid_t pid = fork();

  > 		// open db for reading
  > 		DuckDB db(dbdir, &config);

  > 		// try to open db for writing, this should fail
  > 		REQUIRE_THROWS(db = make_uniq<DuckDB>(dbdir));
  > 		// but opening db for reading should work
  > 		REQUIRE_NOTHROW(db = make_uniq<DuckDB>(dbdir, &config));

  A new connection is not always a new open of the file. The Python client keeps a cache of instances in its process-wide module state, and `connect` on a file path is handed a live instance for the same path, with the same configuration, instead of a new one. Read at duckdb-python v2.0.1 and DuckDB v2.0.1.

  Source: https://github.com/duckdb/duckdb-python/blob/v2.0.1/src/pyconnection.cpp

  > 	bool cache_instance = database_path != ":memory:" && !database_path.empty();

  > 		auto database = GetModuleState().instance_cache.GetOrCreateInstance(database_path, config, cache_instance,

  Source: https://github.com/duckdb/duckdb/blob/v2.0.1/src/main/db_instance_cache.cpp

  > 			auto instance = GetInstanceInternal(database, config_dict, lock);
  > 			if (instance) {
  > 				return instance;

  > 	return make_shared_ptr<DuckDB>(*db_instance);

  Inferred: a forked child has a copy of that cache. Where the parent held a live instance for the path when it forked, the child's new connection to that path is given the inherited instance, opens no file and takes no lock: the third case below, not the first. Where no instance for the path was live, the child opens the file anew. No DuckDB source says what happens in a child that is handed an inherited instance.

- **A child that goes on using an instance the parent opened.** No DuckDB source covers it.

  The operating system's rule bears on this case. A child does not inherit its parent's record locks, and DuckDB's lock is one.

  Source: https://man7.org/linux/man-pages/man2/fcntl_locking.2.html (line breaks collapsed)

  > Record locks are not inherited by a child created via fork(2), but are preserved across an execve(2).

  Inferred: a child that writes through an instance it inherited holds no lock on the file. If the parent still has the file open, the parent holds the lock and the child does not. Whether an inherited instance can reach a write at all is not documented, and no DuckDB source says what happens then.

DuckDB core at v2.0.1 has no fork handler: `src/`, outside `third_party/`, has no `pthread_atfork` (searched, 3,551 files). The Python client at v2.0.1 registers a narrow one for two pieces of its own state.

Source: https://github.com/duckdb/duckdb-python/blob/v2.0.1/src/arrow/python_arrow_scan.cpp

> pthread_atfork(nullptr, nullptr, &AfterForkInChild);

**Costs and dissent.** The 1.4 page listed the workarounds people needed, such as a cross-process mutex or a server process. Quack, first released in the 1.5 series and polished in 2.0, is the authors' answer, and a later choice than the rule. It puts other processes behind one server instance, as clients, and is beta at this commit. DuckDB's FAQ advises against network storage for read-write work.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/faq.md (line breaks collapsed)

> Based on our experience, we **strongly advise against running DuckDB – or any other database management system – for read-write workloads on [network-attached storage (NAS)](https://en.wikipedia.org/wiki/Network-attached_storage).**

The authors give their reason for adding Quack.

Source: https://github.com/duckdb/duckdb-web/blob/c53d1db49ed9869e8a43df1f16d1d1053367745c/_posts/2026-05-12-quack-remote-protocol.md (line breaks collapsed)

> The vast number of workarounds people built to bolt a client-server solution onto DuckDB has at the very least convinced us that this is something people cared about.

**Searched, with no further rationale.** The DuckDB SIGMOD 2019 demo paper and CIDR 2020 paper were read as text for "process" and "fork". Both frame concurrency as threads inside one process, and neither discusses processes sharing a file. The three talks linked from the Quack post were not watched.

### P11. SQLite, for contrast

This is a contrast of what each engine documents. It weighs neither.

**What it does.** Read at sqlite.org (SQLite 3.54.1 current). Many processes may have the file open and read it. One at a time may write.

Source: https://www.sqlite.org/faq.html (page last updated 2024-11-26)

> Multiple processes can have the same database open at the same time. Multiple processes can be doing a SELECT at the same time. But only one process can be making changes to the database at any moment in time, however.

**Stated why**, for the locking and its limits.

> This is because fcntl() file locking is broken on many NFS implementations. You should avoid putting SQLite database files on NFS if multiple processes might try to access the file at the same time.

> If your application has a need for a lot of concurrency, then you should consider using a client/server database. But experience suggests that most applications need much less concurrency than their designers imagine.

In WAL mode, SQLite's documentation gives the reason for one writer, and how readers in other processes run beside it.

Source: https://www.sqlite.org/wal.html (page last updated 2026-08-25) (line breaks collapsed)

> Writers merely append new content to the end of the WAL file. Because writers do nothing that would interfere with the actions of readers, writers and readers can run at the same time. However, since there is only one WAL file, there can only be one writer at a time.

> A checkpoint can run concurrently with readers, however the checkpoint must stop when it reaches a page in the WAL that is past the end mark of any current reader.

**Fork.** SQLite documents it directly.

Source: https://www.sqlite.org/howtocorrupt.html (page last updated 2026-04-13)

> Do not open an SQLite database connection, then fork(), then try to use that database connection in the child process. All kinds of locking problems will result and you can easily end up with a corrupt database. SQLite is not designed to support that kind of behavior. Any database connection that is used in a child process must be opened in the child process, not inherited from the parent.

**Constraints.** The same POSIX locks as DuckDB, with their quirks, which SQLite documents too.

> One particularly pernicious problem is that the close() system call will cancel all POSIX advisory locks on the same file for all threads and all file descriptors in the process.

WAL mode needs shared memory, and so one host.

Source: https://www.sqlite.org/wal.html (page last updated 2026-08-25)

> All processes using a database must be on the same host computer; WAL does not work over a network filesystem.

**Costs and dissent.** SQLite calls network filesystems a risk to the user.

Source: https://www.sqlite.org/useovernet.html (page last updated 2022-06-22)

> SQLite is designed for situations where the data and application coexist on the same machine.

A long-running reader holds back the checkpoint.

Source: https://www.sqlite.org/wal.html (line breaks collapsed)

> If another connection has a read transaction open, then the checkpoint cannot reset the WAL file because doing so might delete content out from under the reader.

DuckDB's authors cite SQLite's approach. Hannes Mühleisen quoted SQLite's FAQ in issue #77, and `Mytherin` compared DuckDB's open-write-close workaround with it.

Source: https://github.com/duckdb/duckdb/discussions/4899#discussioncomment-3812950 (line breaks collapsed)

> This is how SQLite operates internally. DuckDB is not specifically optimized for this use case, however, so opening and closing a connection for every write is not optimized.

---

## The OTel Arrow posts

### P12. Identifying the posts

The links were not kept. The opentelemetry.io blog, at commit `1bd1378`, has four posts on OpenTelemetry Protocol with Apache Arrow:

- 2023-11-14, "Achieve a 10x Reduction in Telemetry Traffic Using OpenTelemetry Protocol with Apache Arrow";
- 2024-09-25, "OpenTelemetry Protocol with Apache Arrow in Production";
- 2025-05-12, "OpenTelemetry Protocol with Apache Arrow - Phase 2 Announcement";
- 2026-06-12, "OTel-Arrow Phase 2: From Efficient Transport to Efficient Telemetry Pipelines".

The posts of 2024, 2025 and 2026 are taken to be the three that `CONTEXT.md` means. That is Inferred, on two grounds: they are the only Arrow posts on the project's blog in those years, and their content carries each of the recorded signals, as checked below. The 2023 post is the launch, and C8 does not list it. Arrow posts elsewhere were not surveyed, because these matched. The maintainer confirmed the identification on 2026-11-25.

Their live URLs are https://opentelemetry.io/blog/2024/otel-arrow-production/, https://opentelemetry.io/blog/2025/otel-arrow-phase-2/ and https://opentelemetry.io/blog/2026/otel-arrow-phase-2/. The sources below are the same posts at the pinned commit.

### P13. What the posts say, and C8

**Arrow as a wire and in-pipeline format.** Confirmed. The 2024 post covers the exporter and receiver that carry Arrow over gRPC between collectors. The 2026 post covers Arrow as the representation inside a pipeline.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

> what happens if Arrow is used not only on the wire, but also as the representation the pipeline works with internally?

**On-disk storage, durability, shutdown, schema evolution.** No post covers any of them. Three passages come nearest:

- the 2024 post names persistence among the collector's batching options, and goes no further:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

  > OpenTelemetry Collector users have several options for batching available to them, which are connected to other factors, including the available options for concurrency, queuing, and persistence.

- the 2026 post says the engine propagates delivery acknowledgements, which bears on delivery, not on storage:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

  > propagates delivery acknowledgments through pipelines

- the 2025 post hopes for integration with data lakes, downstream of the pipeline:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2025/otel-arrow-phase-2.md (line breaks collapsed)

  > we believe that OpenTelemetry users will benefit from more direct integrations with their data lake.

**The recorded signals.** Each is in the posts.

- Bounded channels and memory:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

  > It emphasizes bounded channels and data structures, avoids synchronization in hot paths

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

  > When the memory limit is reached, the receiver terminates the stream with a resource-exhausted status code.

- Overload made visible:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

  > The Dataflow Engine keeps memory bounded even when overloaded as it applies backpressure, making overload visible instead of letting memory absorb it.

  The 2024 post gives the authors' reason, for a gateway collector:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

  > we recommend a fully synchronous request path, where callers wait for the pipeline to acknowledge their request before they let go of the original data.

  > Back-pressure lets telemetry producers know when the pipeline is in trouble, giving them an opportunity to retry on another connection, and it gives the service operator a chance to auto-scale the number of instances to handle the increase in load based on memory utilization.

  The 2026 post's bounded memory is the engine's own: it applies backpressure, and the post does not say that the originating caller waits. Searched: the 2026 post's text, for "synchronous", "caller", "wait" and "acknowledg"; the only hit is the delivery acknowledgements quoted above.

- Larger batches generally compress better, at a cost:

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

  > Larger batches generally achieve better compression, but this improvement comes at a cost. Larger batches require more memory, use more CPU, and add network and CPU latency to a pipeline, so these factors have to be balanced.

  The 2026 post reports a different result for CPU, on its own benchmark at a fixed rate of logs. The two are reported side by side, not reconciled.

  Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

  > The second observation shows that at 400K logs/sec, larger batches reduce CPU cost for every path, but the OTAP path benefits the most. It drops from 21% CPU at 256 logs per batch to 7.8% at 4096 logs per batch

**Stated why they chose Arrow for the wire.** The 2024 post gives the authors' reasons.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

> is a great technical dependency for OpenTelemetry because these projects have many aspects in common.

> it was natural, for our purposes to leverage existing gRPC-configuration, services, authorization extensions, and instrumentation in the OpenTelemetry Collector by embedding Arrow IPC inside gRPC streams.

The design document the 2024 post links to, OTEP 0156, gives the fuller reason: large batches, and a columnar layout that compresses and processes better.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/5239912e97a4df50b206f5fa8241dd6cd8d2dbf8/oteps/0156-columnar-encoding.md (line breaks collapsed)

> This representation works well for small batches (<50 entries) but, as the analytical database industry has shown, a "column-oriented" representation is more optimal for the transfer and processing of *large batches* of entities.

> * **better data compression rate** (arrays of similar data generally compress better),

**What they say about bounding memory.** The 2024 post describes two receiver limits, and recommends them over the general memory limiter.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

> When this limit is reached, individual requests or streams either block or fail immediately, determined by a limit on the number of concurrent waiters. Admission limits protect receivers from running out of memory due to pipeline stalls.

> We recommend use of these limits to control memory in an OTel-Arrow pipeline and not to use the standard memory-limiter processor.

The 2025 post sets the aim for the Rust pipeline.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2025/otel-arrow-phase-2.md (line breaks collapsed)

> We are interested in making OTAP pipelines safely embeddable, through strict controls on memory and through support for thread-per-core runtimes.

**Constraints.** The posts are about collectors: high-volume streams between processes and machines, network cost, and batches of thousands of items. The 2026 engine is incubating, by its authors' own account.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2026/otel-arrow-phase-2/index.md (line breaks collapsed)

> Real-world usage should be limited to controlled experiments; production workloads are not recommended at this stage.

**Costs and dissent.** The authors say the columnar protocol does not suit small streams.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2023/otel-arrow/index.md (line breaks collapsed)

> Deployments with limited resources or those generating minimal telemetry should stick with the standard collector based on OTLP.

A stream's state limits its throughput, and more streams trade compression for throughput.

Source: https://github.com/open-telemetry/opentelemetry.io/blob/1bd13789862174c89d11afd31d3f655de3cd16c9/content/en/blog/2024/otel-arrow-production/index.md (line breaks collapsed)

> Stream requests are encoded and decoded sequentially by both components, allowing them to maintain correct state, which limits how much data each stream can handle. Increasing the number of exporter streams improves throughput, but each stream has some overhead, so fewer streams are generally better for compression results.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/5239912e97a4df50b206f5fa8241dd6cd8d2dbf8/oteps/0156-columnar-encoding.md (line breaks collapsed)

> A columnar-oriented protocol is not necessarily desirable for all scenarios (e.g. devices that do not have the resources to accumulate data in batches).

**What OTEP 0156 says about Parquet.** It is a format the authors considered for the wire and rejected, because it is not an in-memory format for processing online. The OTEP is a design document, not one of the three posts.

> Although a Parquet representation offers some additional encoding modes that can improve the compression ratio, Parquet is not designed as an in-memory format optimized for online data processing.

---

## Comparables that chose otherwise

Where a platform faced the same problem and chose differently, with its stated why.

- **Reserving space on a copy-on-write filesystem: emulate, refuse, or approximate.**
  - ZFS emulates: mode 0 checks free space and makes a sparse file, because "strict compliance is futile" (P3).
  - XFS refuses on an `always_cow` inode, returning `EOPNOTSUPP`: "we can't use preallocations and thus should not create them" (P3).
  - btrfs approximates: it preallocates and disables compression "to reduce the chances" of a failed write (P3).
  - btrfs on zoned devices refuses outright (P3).
- **Cloud Storage FUSE does not implement `fallocate`**, because running out of space "is not a concern" for a bucket (P6).
- **NFSv4.2 made the reservation a server's promise** (`ALLOCATE`), because writing zeros "is also not guaranteed to work on file systems that are log-structured or deduplicated" (P6).
- **Enforcing ephemeral storage with quotas instead of eviction.** Kubernetes left it as future work in both KEPs, and named the risk that a container cannot exit if its log write is refused (P7).
- **More than one process writing one file.**
  - SQLite lets many processes open the file and serialises writers with locks, and says a client-server database is the answer to more concurrency (P11).
  - DuckDB lets only one process write a native file directly. For more writers it offers a client-server protocol (Quack, beta at the commit read), in which clients write through one server instance, and a separate catalog-coordinated format (DuckLake). Both predate 2.0 (P10).
- **A columnar format for small streams.** OTLP's row format stays the recommendation for small sources, by the Arrow authors' own account (P13).

## Candidates not examined, or dropped

- **COS source** (`cos.googlesource.com`) for the stateful partition's filesystem: read for build `19999.44.159` only (P8); other builds not searched.
- **Arrow posts outside opentelemetry.io:** not surveyed, because the project's own blog matched.
- **DuckDB talks** linked from the Quack post: not watched.
- **Filestore's server filesystem**, and whether an NFS write is in place there: no source read speaks to it.
- **Other embedded engines** besides SQLite: the ticket asks for one contrast.
- **DuckDB's direct I/O mode** (`IO_MODE 'DIRECT_IO'`): not read beyond its flag.
- **DuckDB on Windows**: its memory-mapping and trim code was not read.
- **A memory-mapped DuckDB file on other layers**: on tmpfs (a memory `emptyDir`), in an overlay writable layer, staged by Cloud Storage FUSE, or on XFS or btrfs when the disk is full. Each would rest on one inference stacked on another, so none is reported. For the overlay layer, P10 shows only that the mapping is handed to the real file in the upper layer (Inferred from source); which filesystem and kernel that is on a node adds further inferences.
- **DuckDB's spill files**: how it writes them was not read; only their default directory and cap, from the configuration page and the code.
- **DuckDB's writes before a checkpoint**: a commit can write row groups to blocks before a checkpoint; their allocation was not traced beyond the free list.
- **`ftruncate` and a `KEEP_SIZE` range on filesystems other than ext4**: ext4 at Linux v7.3 is read under P10; XFS, btrfs and tmpfs were not.

## The claims, checked

| Claim | Verdict | Where |
| --- | --- | --- |
| C1. `fallocate` guarantees that later writes "will not fail because of lack of disk space" | Substance holds for mode 0 and `KEEP_SIZE`, under conditions. The quotation is wrong: the page says "are guaranteed not to fail because of lack of disk space" | P1, P2 |
| C2. A file created in the container or on an `emptyDir` is overwritten in place on the node's disk | Holds only under conditions: the upper or `emptyDir` filesystem overwrites the file's blocks in place (ext4; XFS where the blocks are not shared, Inferred; btrfs only for a preallocated extent's first write or a `NOCOW` file, under P3's conditions), and the `emptyDir` is on disk. Wrong for `medium: Memory`. An image-layer file is copied up first, by a clone or a copy, or with no data under `O_TRUNC` | P4, P5 |
| C3. The guarantee does not hold on ZFS, btrfs, reflinked XFS and APFS | ZFS: confirmed. btrfs: partly. A first write into a preallocated extent, and a rewrite of a `NOCOW` file, go in place only while no snapshot, taken or pending, or other reference shares the extent and the kernel's other checks pass, and still need metadata space (Inferred from source); the authors call preallocation a way "To reduce the chances" of failure. Otherwise a rewrite is copy-on-write. XFS: confirmed for shared blocks only. APFS: Unverified | P3 |
| C4. A reservation never prevents eviction over the limit | Confirmed where the kubelet measures local ephemeral storage, and stronger: on ext4 a reservation counts towards the measured usage wherever the kubelet's scan, or for an `emptyDir` its quota, sees the file, so it can cause the eviction (Inferred from source) | P7 |
| C5. A full disk usually shows up as an eviction; reserved space helps with a neighbour, not with the pod's own limit | "Usually an eviction" has no source, and KEP 1029 says a pod can fill the partition first. Over its own limit, eviction is sourced, where the kubelet measures local ephemeral storage and the pod is not critical. A reservation keeps writes into it working after a neighbour fills the disk, where P1's conditions hold, and, under node pressure, adds to the usage by which the pod is ranked, for a byte signal whose ranking includes it (Inferred). In DuckDB's opt-in memory-mapped mode on ext4, a write into an unallocated page on a full filesystem raises `SIGBUS`, whose default action ends the process, instead of failing the write (Inferred from source) | P7, P9, P10 |
| C6. GKE node disks are ext4 | Partly sourced. Two COS releases (2018, and a 2026 dev image) name ext4 for the stateful partition, as does the image layout of `cos-133-19999-44-159`, which the GKE 1.37 changelog names, and a 2023 Google post names ext4 for the Local SSD ephemeral array. Other COS releases, the Ubuntu image and the newer Local SSD layout stay Unverified. Persistent Disk volumes default to ext4, which is a different layer | P6, P8 |
| C7. Network and FUSE volumes | Now sourced. Filestore: `EOPNOTSUPP` (Inferred from source). Cloud Storage FUSE: not implemented; no write is in place, a rewrite is staged locally, and a new file written in order is streamed where streaming writes are on and within their limit. Generic FUSE: up to the daemon | P6 |
| C8. The OTel Arrow posts | Identified (Inferred, and confirmed by the maintainer on 2026-11-25). Every part of the claim holds; three passages come near storage and none covers it | P12, P13 |
| C9. DuckDB allows only one writer process | Holds for a database file opened directly. Quack (clients write through one server instance, beta at the commit read) and DuckLake (a different format, coordinated by a catalog) let more than one process write; neither is an exception to the rule for the file itself (Inferred) | P10 |

---

## Fit on the leaning hosts

This section and the ones after it were written after the first adversarial review. They cite the sections above rather than quote them again.

**The leanings.** `CONTEXT.md` records three, under "Leanings, not decisions", and none is a decision:

- **Host:** an ephemeral cloud environment such as a Kubernetes worker pod, with Google's GKE named as an example.
- **Collection:** a pull. Open question 15 is still open.
- **Storage engine:** DuckDB, named once. The on-disk format is undecided.

Each verdict below says whether a fact's condition holds on a host shaped by those leanings. A verdict is never firmer than the finding it rests on: "Inferred" and "Unverified" carry through. A condition is reported, not advised. Nothing here says the client should reserve space, use an `emptyDir`, run on Autopilot or use DuckDB.

**The host shapes**, from P4, P5 and P8:

- **H1. GKE Standard, Container-Optimized OS, ephemeral storage on the boot disk.** The writable layer and a disk `emptyDir` are on the stateful partition that `/var` is mounted from, where containerd's and the kubelet's roots keep their defaults under `/var` and the snapshotter's `root_path` is unset (Inferred: no Google page read says so, P4, P5, P8). A pod has an ephemeral-storage limit only if its spec sets one, or a `LimitRange` default fills one in at admission (P8). A Standard cluster may enable image streaming; for a streamed image the writable layer is Unverified in every row below, as under H3 (P4).
- **H2. GKE Standard, COS, Local SSD ephemeral storage.** GKE mounts the kubelet's and the container runtime's root directories onto the Local SSD volume, and Google's page says the recommended option puts `emptyDir` volumes and container writable layers there (P8). The array is ext4 by the 2023 post, for the layout it describes; the current page names no filesystem, and the newer split layout is Unverified (P8). Image streaming as under H1.
- **H3. GKE Autopilot.** Always COS. Ephemeral storage is on the boot disk unless the node has Local SSDs; with them, the 2023 post's layout is Inferred from the node label Autopilot shares with it, and the mixed layout is not offered (P8). Image streaming is used for eligible images. Every container's ephemeral-storage limit equals its request: 1 GiB by default, 100 MiB in a DaemonSet, and a pod's total between 10 MiB and 10 GiB outside the exceptions the page names, such as up to 56 TiB for Performance-class and accelerator pods (P8).
- **H4. GKE with the Ubuntu node image.** Its root filesystem is Unverified (P8), so every verdict on the writable layer or a disk `emptyDir` is Unverified for H4, and H4 is left out of the tables below. A mounted Persistent Disk volume does not turn on the node's root: the CSI driver formats it, ext4 by default (P6).

"Ephemeral pod" adds one thing to every host: what is stored or reserved in the writable layer lasts only as long as its container, and is gone after a restart (P4); what is stored or reserved in an `emptyDir` survives a container restart and is deleted when the pod leaves the node (P5).

### Reserving space and writing in place

| Condition (where found) | H1 | H2 | H3 | Note |
| --- | --- | --- | --- | --- |
| The file is on a filesystem that implements mode 0 by allocating blocks (P1, P3) | Holds where the stateful partition is ext4: sourced for COS milestone 69, a 2026 dev release and build `cos-133-19999-44-159`; Inferred for a node running another build | Holds where the Local SSD array is ext4: sourced by the 2023 post for the layout it describes; the newer split layout is Unverified | As H1 for a file in an `emptyDir` on the boot disk; with Local SSDs, as H2's 2023 layout (Inferred, P8). Unverified for a streamed image's writable layer | A memory `emptyDir` is tmpfs on every host: the call allocates pages charged to memory (P5) |
| Writes into the range overwrite the reserved blocks in place (P1, P3) | Holds on ext4 (P1), apart from the metadata reserve below | As H1, for the layout the 2023 post describes | As H1, or H2's 2023 layout with Local SSDs (Inferred), for an `emptyDir`; Unverified for a streamed image's writable layer | ZFS, btrfs and XFS with reflink are not among the filesystems the sources name for GKE nodes (P8) |
| ext4 can split the unwritten extent when a write lands inside it (P1) | Depends on the reserve, which is 2% or 4096 clusters by default and can be changed, and on the zero-out fallback. What a buffered writer sees when both fail is Unverified | As H1 | As H1 or H2 | A direct-I/O write gets the conversion error (P1) |
| The file was created at runtime, or truncated on opening (P4) | A file from an image layer is copied up at open, which may need space for its data: less after a clone or where holes are skipped, and none under `O_TRUNC` (P4) | As H1 | As H1 or H2, and Unverified under image streaming | A file the client creates itself is the runtime case |
| Nothing truncates the file or punches the range afterwards (P1, P2) | A condition on the program, not the host | | | POSIX: a truncating `open` or `creat` frees the space; `PUNCH_HOLE` deallocates it. What DuckDB itself truncates and punches is in the DuckDB table below (P10) |
| A mounted volume supports a reservation (P6) | Persistent Disk: yes, ext4 by default. Filestore: no, `EOPNOTSUPP` (Inferred). Cloud Storage FUSE: no, not implemented | As H1 | As H1 | None of these volumes is ephemeral storage (P7). Cloud Storage FUSE stages a write in an `emptyDir` by default, which is ephemeral storage where it is on disk (Inferred, P6, P7) |

### Eviction and a full disk

| Condition (where found) | H1 | H2 | H3 | Note |
| --- | --- | --- | --- | --- |
| The kubelet measures local ephemeral storage (P7) | Inferred: a GKE node reports allocatable ephemeral storage (P8) | Stated by Google's 2023 post for the layout it describes (P8); otherwise as H1 | As H1; with Local SSDs, as H2's 2023 layout (Inferred, P8) | The 2023 post states it for its Local SSD option (P8); for the other layouts no Google page read says it in those terms |
| The pod has an ephemeral-storage limit (P7) | Only if its spec sets one, or a `LimitRange` default fills one in at admission (P8) | As H1 | Holds for every pod: GKE sets each container's limit equal to its request (P8) | |
| A reservation counts towards measured usage (P7) | Inferred, on ext4, wherever the scan or an `emptyDir`'s quota sees the file. A file unlinked while open escapes the scan (P7) | As H1 | As H1. Every pod has limits for it to count towards (P8): a reservation in a disk `emptyDir` counts towards the pod's limit, which the docs give as the sum of its containers' limits and the source also takes from sidecar and init containers (P7), and towards the volume's `sizeLimit` if one is set, but not towards a container's limit; one in the writable layer counts towards its container's limit as well as the pod's, where the node has no dedicated image filesystem (Inferred, P7 and P8) | So a reservation can itself bring an eviction nearer (C4) |
| The pod is not critical (P7) | Holds unless the pod is classed critical | As H1 | As H1 | |
| The node has one filesystem for the kubelet and the images (P7) | Inferred: `/var` holds both (P8) | Inferred: both are mounted on the same Local SSD volume (P8) | As H1 or H2 | Decides how pods are ranked and whether a container limit is checked (P7) |
| The disk can fill before the kubelet acts (P9) | Holds: thresholds are evaluated every 10 s or so. Node pressure is judged from the filesystem's own free space, refreshed on a period not traced (Unverified); a pod's limits from usage refreshed on its own periods, a minute for an `emptyDir`. GKE keeps 10% of the boot disk as the threshold | As H1, against the Local SSD volume | As H1 or H2 | A write that then needs new space gets `ENOSPC` or a short write, or, on a filesystem that does not allocate space at write time, an error at a later `write`, `fsync` or `close` (P9). A write into a reserved range needs no new data blocks; on ext4 one that splits the reserved extent still needs a metadata block from the reserve, and can fail if that and the zero-out fallback both fail (P1, P9) |

### DuckDB, fork and a pull

DuckDB is a leaning, and this checks the conditions of its rule on the leaning hosts. It weighs no engine.

| Condition (where found) | On the leaning hosts | Note |
| --- | --- | --- |
| The database file is opened directly, not through Quack or DuckLake (P10) | A condition on the program | Quack is beta at the commit read (P10) |
| The filesystem supports POSIX locks (P10) | Holds for ext4 and tmpfs as an `emptyDir` (Inferred: no source read says either refuses `F_SETLK`). A Filestore or Cloud Storage FUSE volume is not covered: DuckDB's FAQ advises against network storage for read-write work, and Google states no file locking for Cloud Storage FUSE (P6, P10) | Where `fcntl` fails with `ENOTSUP`, a read-only open goes ahead unlocked and a read-write open fails; any other lock failure fails the open (P10) |
| Two processes open the same file (P10) | Two containers in one pod see the same `emptyDir` (P5) and share the node's kernel, so a second read-write open there fails with "Could not set lock on file" (Inferred). Where the pod shares its process namespace, a container can also reach another's writable layer through `/proc/$pid/root`, subject to file permissions (P4). Two pods each have their own writable layer and `emptyDir`, so a file in either belongs to one pod (Inferred). Two pods can still open one file on a volume both mount, such as a `ReadWriteOnce` volume on one node or a `hostPath` (P6), and the rule applies there where the filesystem honours the lock (Inferred) | Each container has its own writable layer (P4) |
| A process forks (P10) | The lock is not inherited (`fcntl_locking(2)`, P10). A child that opens the file anew asks for its own lock, and a second read-write open fails while the other process still holds its lock (Inferred). A new Python connection is not always a new open: where the parent's instance for the path was live at the fork, the client's instance cache would hand the child that instance, with no lock of its own (Inferred from source, P10). DuckDB's write-lock test covers a child, forked before any open, that opens first. A child opening its own connection after the parent used DuckDB is reported failing for MotherDuck connections (duckdb-python #292). For a native file that the parent closed before forking, DuckDB's read-lock test has the child open it read-only, and asserts that the parent's later read-write open throws and its read-only open succeeds. A child that opens read-write after the parent used DuckDB is not covered (P10). A child that goes on using the parent's instance is covered by no DuckDB source | SQLite says never to carry a connection across `fork` (P11) |
| A pull reads the data from another process (P10) | A read-only DuckDB open takes a shared lock, which the writer's exclusive lock excludes, so another process's DuckDB open of a file a writer holds is refused, read-only included, where the filesystem honours locks (Inferred from source, P10). The lock is advisory: it does not stop a process that reads the file without DuckDB, and what such a reader sees is not covered here | A pull served by the writing process itself opens no second handle (Inferred) |
| DuckDB's writes land on blocks the file already has (P10) | A condition on the engine, not the host. A block reused from the free list is usually a write over a range already written, which lands in place on ext4 (P1, Inferred from source). It needs new space where a checkpoint truncated it off the tail and the file was opened again, or where `trim_free_blocks` punched it (Inferred from source). A block past the highest recorded block extends the file where the file ends there, and lands in reserved blocks only where the range was reserved past the end (P1). Where the file is longer, as in the memory-mapped mode or after a mode-0 extension before the next checkpoint, it lands inside the file (Inferred from source). Which kind a write is depends on the free list at that moment (Inferred from source) | Metadata blocks are rewritten at their own id, and the two header slots at fixed offsets (Inferred from source, P10) |
| DuckDB does not truncate or punch a reserved range (P1, P10) | Default path: no hole is punched unless the program sets `trim_free_blocks`, false by default and not a SQL setting at v2.0.1 (Inferred from source). A checkpoint that frees blocks at the tail, or finds the file longer than its last used block, truncates the file to that block. That cuts a mode-0 reservation that extended the file and, on ext4 at Linux v7.3, a `KEEP_SIZE` range past the end; a `KEEP_SIZE` range alone does not make a checkpoint truncate (Inferred from source). Memory-mapped mode: a checkpoint that frees blocks at the tail punches them instead, on Linux (Inferred from source). A punch that fails is not reported in either mode (Inferred from source) | #28571, merged to `main` before the v2.0.1 tag but not in it, makes `trim_free_blocks` a setting, false by default (P10) |
| The engine writes one file (P10) | Does not hold. The WAL is a second file beside the database file. It grows by appends until a checkpoint. A commit asks for one once the WAL would pass 16 MiB by default, and the checkpoint can be declined, so the WAL can grow past that (Inferred from source). After a checkpoint it is deleted, or replaced by the log of commits made during it, and a clean close that checkpoints deletes it. A reservation on the database file does not cover it (Inferred from source). Spill files go by default to a `.tmp` directory named after the database the DuckDB instance was opened with, which need not be the attached file. It may take up to 90% of the disk space available there when the cap is set, and has no cap where that space cannot be read (Inferred from source) | A commit that writes the WAL syncs it unless `fsync_mode` is `NONE`; a large commit can checkpoint instead of writing it (P10) |
| A memory-mapped database file's size matches its allocated blocks (P7, P10) | Does not hold in the memory-mapped mode: the file is extended to 256 GiB by default unless it is already larger, and the extension allocates no blocks (DuckDB's comment; Inferred on ext4). Where the kubelet's scan walks the file, it sums allocated blocks: those written and any range reserved on the file, not the rest of the reserve (Inferred from P7) | How an `emptyDir` quota counts such a file is not covered here |
| A full disk fails a write with an error the engine sees (P9, P10) | Default path: as P9. Memory-mapped mode, for a file directly on ext4, such as a disk `emptyDir` where the reservation table gives ext4: a write into an unallocated page on a full filesystem raises `SIGBUS`, whose default action ends the process (Inferred from source, Linux v7.3). A file in the overlay writable layer is under "Candidates not examined". Which kernel a GKE node runs was not established, so whether a node's ext4 behaves as v7.3's does is Unverified | DuckDB installs no `SIGBUS` handler; the host application can change the disposition (`signal(7)`). The WAL is written through the buffered writer in either mode (P10) |

### The comparables

Every source here explains a mechanism of a platform the client would run on, not a design the client would copy. So each **informs** and none justifies, under "Citing a comparable" in `CONTEXT.md`.

| § | Choice | Stated why | Holds on the leaning hosts | Does not hold | Use |
| --- | --- | --- | --- | --- | --- |
| P1 Linux `fallocate` | Reserve blocks; later writes into them do not fail for space | The man page states the guarantee, not a design reason | ext4 in the COS releases, the COS build and the 2023 Local SSD layout P8 names, Inferred for other COS builds (P8); a Persistent Disk volume, ext4 by default (P6) | tmpfs, where the reservation is memory (P5); Filestore and Cloud Storage FUSE volumes, and a FUSE volume whose daemon does not implement `fallocate` (P6); shared blocks | Informs |
| P3 OpenZFS | Emulate mode 0 by default: check free space against 110%, and extend the file sparsely where the range runs past its end | Under copy-on-write and snapshots "strict compliance is futile"; not supporting the call "has been causing more harm than good" | None: ZFS is not a GKE node filesystem in any source read | | Informs |
| P3 btrfs | Preallocate, and turn compression off for the file | "To reduce the chances" of a failed write | None: btrfs is not a GKE node filesystem in any source read | | Informs |
| P6 Cloud Storage FUSE | No `fallocate` | Running out of space "is not a concern" for a bucket | A Cloud Storage FUSE volume, if a pod mounts one | The node's own disks | Informs |
| P6 NFSv4.2 `ALLOCATE` | A server's promise of space | Writing zeros "is also not guaranteed to work" on some filesystems | None: Filestore serves NFSv3 or NFSv4.1 (P6) | | Informs |
| P7 Kubernetes | Enforce ephemeral storage by eviction, not quotas | KEPs 361 and 1029: measurement is reactive; a quota could stop a container writing its exit log | Every GKE host, where the kubelet measures local ephemeral storage (stated by the 2023 post for its Local SSD option, Inferred elsewhere, P8) | | Informs |
| P10 DuckDB | One read-write process per file | State cached in memory that other processes cannot see; checkpoints | A file in a pod's `emptyDir` or writable layer, on POSIX, where the filesystem honours `fcntl` locks (Inferred for ext4 and tmpfs, P10) | The rule is per file, not per instance or per container | Informs |
| P10 DuckDB, block layout | One file: changed data goes to free or new blocks, two header slots alternate, and the WAL is a separate file | A single file "was inspired by SQLite [3] and repeated user requests" (CIDR 2020), which also states the order: new blocks, then the header "atomically". No stated reason was found for writing to other blocks rather than over the old ones | A file in a pod's `emptyDir` or writable layer on ext4, where a reused block that the file still has is overwritten in place (Inferred) | A mode-0 reservation past the last used block, or on ext4 a `KEEP_SIZE` range past the end, which a checkpoint that truncates cuts (Inferred from source); the WAL | Informs |
| P10 DuckDB, trim | Punch the blocks a checkpoint frees and no live handle holds, only when `trim_free_blocks` is set; false by default | The file system "is free to deallocate the range (sparse file support)" (#11258, a contributor's pull request) | Linux with glibc 2.18 or later; a punch that fails is not reported (Inferred from source, P10) | A reserved range the program means to keep, where the option is set | Informs |
| P10 DuckDB, memory-mapped mode | Opt-in: extend the file sparsely to a reserve and write through a shared mapping | Rely on the page cache, "only performance"; reserve address space "to just hand out pointers" without remapping (#22988) | ext4, where the extension allocates nothing (Inferred) | An encrypted database; a write past the reserve; on a full ext4 filesystem a write into an unallocated page raises `SIGBUS`, whose default action ends the process (Inferred from source) | Informs |
| P11 SQLite | One writer at a time; no connection across `fork` | `fcntl` locking "is broken on many NFS implementations"; one WAL file means "only one writer at a time" | | | A contrast only |
| P13 OTel Arrow | Arrow on the wire and in the pipeline | Large batches: a column-oriented representation compresses and processes them better (OTEP 0156) | | An in-process library writing to local disk; the posts cover no on-disk format. The 2024 post's overload signal, for a gateway, rests on backpressure to callers that wait for an acknowledgement; the 2026 post bounds memory by backpressure and does not say whether the originating caller waits (P13). `CONTEXT.md`'s standing guidance is that the client never blocks the worker | Informs |

## Proposed wording for the maintainer

Where a fact proved wrong, or holds only under a condition the text does not state, this section offers replacement wording. It is the maintainer's to accept, change or reject. It is written only here, and this ticket changes none of these passages.

**Note, 2026-11-25.** The maintainer chose to leave this wording here, and not to apply it to ticket 07 or `CONTEXT.md`. It was written before "How DuckDB writes its own file" under P10, and does not carry what that section found: among others, that a checkpoint that truncates the file cuts a mode-0 reservation that extended it and, on ext4 at Linux v7.3, a `KEEP_SIZE` range past the end; that the result of a punch DuckDB attempts is not checked; that the WAL is a second file, which a reservation on the database file does not cover, and spill files go to a directory of their own; and that, in the opt-in memory-mapped mode, a write into an unallocated page on a full ext4 filesystem raises `SIGBUS` (each Inferred from source). Where the two differ, P10 and the rows of "Fit on the leaning hosts" that cite it are the later reading. Tickets 07 and 08 each gained a note that points to this file.

The specification states none of these platform facts. It has no `fallocate`, no filesystem and no DuckDB. Its one-writer rule ("One writer process per instance: the location is the instance.") is a proposal, not a fact about a platform, so no wording for it is proposed.

### Ticket 07, its six bullets on reserving disk space

In place of the bullets from "Reserving is possible, with conditions." to "Unverified: the behaviour on network and FUSE volumes.":

```text
- Reserving is possible on Linux, with conditions. After a successful `fallocate` in mode 0 or with `FALLOC_FL_KEEP_SIZE`, `fallocate(2)` says "subsequent writes into the range specified by offset and size are guaranteed not to fail because of lack of disk space". On a local filesystem the guarantee holds where it overwrites the reserved blocks in place, such as ext4; on NFS it is the server's promise, made only by an NFSv4.2 server that supports `ALLOCATE`, which Filestore does not serve. Either way it holds only while the range is still allocated: opening the file with `O_TRUNC` gives the space back (stated by POSIX for `posix_fallocate`, Inferred for `fallocate(2)`), and punching a hole deallocates it. Even on ext4 a write can need metadata space to split the reserved extent. ext4 takes it from a reserve, or zeroes the extent where it may; otherwise a direct-I/O write gets the error, and what a buffered writer sees is Unverified.
- A file the program creates in the container's writable layer is on the node filesystem that holds the overlay snapshotter's root, which is under containerd's root unless configured otherwise; under GKE image streaming that filesystem is Unverified. A file on a disk-backed `emptyDir` is on the filesystem that holds the kubelet's root. A file that came from an image layer is copied up when first opened for writing, which can itself need space. A memory-backed `emptyDir` is tmpfs: a reservation there is memory, counted against the memory limit of the container that made it (Inferred).
- The guarantee does not hold, or holds only in part, on copy-on-write filesystems. ZFS reserves nothing: by default it checks that enough space is free now, failing with `ENOSPC` if not, and in mode 0 extends a file sparsely past its end; with its emulation switched off it returns `EOPNOTSUPP`. btrfs writes a preallocated extent in place once, and a `NOCOW` file's extents each time, only while no snapshot, taken or pending, or other reference shares the extent and the kernel's other checks pass, and still needs metadata space (Inferred from source); its authors call preallocation a way "To reduce the chances" of failure. XFS with reflink copies a shared block on write, and mode 0 does not unshare it. APFS is Unverified.
- A reservation never prevents the kubelet evicting a pod over its ephemeral-storage limit. Where the kubelet measures local ephemeral storage, and its scan (or, for an `emptyDir`, its quota) sees the file, a reservation on ext4 counts towards the measured usage, so it can bring an eviction nearer for a pod that is not critical (Inferred from source). On GKE the measuring is stated only by Google's 2023 Local SSD post, for the option it describes; elsewhere it is Inferred. On GKE Autopilot every pod has such a limit.
- GKE node disks: the COS stateful partition is ext4 in the releases and the build that Google's notes and COS's image layout name, and the 2023 Local SSD post names ext4 for the Standard option it describes; Autopilot's Local SSD layout is Inferred from it. The Ubuntu image, the newer Local SSD layout and image streaming's writable layer are Unverified.
- Network and FUSE volumes: Filestore serves NFSv3 or NFSv4.1, neither of which can reserve, so `fallocate` returns `EOPNOTSUPP` (Inferred from source). Cloud Storage FUSE does not implement `fallocate`. Another FUSE file system reserves only if its daemon does.
```

### `CONTEXT.md`, "Reserving disk space"

The same six points, with one addition for the bullet that begins "It never prevents the kubelet evicting":

```text
No source says a full disk usually shows up as an eviction. The disk can fill before the kubelet acts, and a write that needs new space then fails with `ENOSPC` or writes fewer bytes than asked; on a filesystem that does not allocate space at write time, the error can come at a later `write`, `fsync` or `close` instead. Over its own limit a pod is evicted, where the kubelet measures local ephemeral storage and the pod is not critical. A reservation keeps writes into it working after a neighbour fills the disk, where the conditions above hold, but under node pressure it adds to the usage by which the pod is ranked, for a disk-space signal whose ranking includes the reserved file's layer (Inferred).
```

### `CONTEXT.md`, "OTel Arrow posts"

The substance holds, with the 2024 post's "generally" restored. The links are missing, and the identification is Inferred:

```text
- **OTel Arrow posts (2024-09-25, 2025-05-12, 2026-06-12)**, on opentelemetry.io, taken to be the posts meant from their dates and content; the maintainer has not confirmed them (see `research/17-platform-facts.md`). Arrow there is a wire and in-pipeline format. None covers on-disk storage, durability, shutdown or schema evolution. Useful signals only: bounded channels and memory, overload made visible, larger batches generally compressing better, at a cost. They do not settle the local database format.
```

The maintainer confirmed on 2026-11-25 that these are the three posts meant (P12). The text above predates that answer, so its "the maintainer has not confirmed them" is no longer true.

### `CONTEXT.md`, the "never checked" sentence on DuckDB

In place of "The one-writer rule of DuckDB, named under "Leanings, not decisions", was never checked either; ticket 17 does that.":

```text
The one-writer rule of DuckDB, named under "Leanings, not decisions", is checked in `research/17-platform-facts.md`: a database file opened directly takes one read-write process or many read-only ones, enforced on POSIX systems by an advisory `fcntl` lock where the filesystem supports one. Where `fcntl` reports locks unsupported, a read-write open fails and a read-only open goes ahead without a lock. The documentation says nothing on fork.
```

## What the findings bear on

This section reports what the evidence bears on each entry. It resolves none and recommends no answer.

- **Open question 8: what bounds the local databases when no collection happens, and what is lost at the bound.** The question was put with the claim that a pod over its ephemeral-storage limit is evicted. That holds where the kubelet measures local ephemeral storage and the pod is not critical (P7). On Autopilot every pod has a limit; on Standard, only a pod whose spec sets one or whose namespace's `LimitRange` fills one in (P8). An eviction deletes the pod's `emptyDir` data (P5). With no limit, or before the kubelet acts, the node's filesystem can fill, and a write that needs new space fails or writes fewer bytes than asked, or, on a filesystem that does not allocate space at write time, a later `write`, `fsync` or `close` fails (P9). On Autopilot a pod's total is 10 MiB to 10 GiB outside the exceptions Google names (P8). Data in the writable layer is lost on a container restart, and data in an `emptyDir` when the pod leaves the node (P4, P5). A memory-backed `emptyDir` is bounded by its tmpfs size and by memory (P5). These are the bounds the platform imposes from outside; they say nothing about which bound the client should impose for itself. DuckDB, a leaning, adds its own defaults: a WAL beside the database file, for which a commit asks for a checkpoint once it would pass 16 MiB by default, though the checkpoint can be declined and the WAL grow past that; and the instance's temporary directory, which may take up to 90% of the disk space available there when its cap is set (Inferred from source). In its opt-in memory-mapped mode, a write into an unallocated page on a full ext4 filesystem raises `SIGBUS`, whose default action ends the process (Inferred from source) (P10).
- **Open question 17: whether the one-process rule must hold per container if collection is a pull.** DuckDB's rule is per file and per process, enforced on POSIX by the kernel's record locks where the filesystem supports them (P10). Containers in one pod each have their own writable layer, and those that mount it share an `emptyDir` (P4, P5). Two of them meet on a file through a shared volume or, where the pod shares its process namespace, through `/proc/$pid/root` (P4). Another process's DuckDB open of a file a writer holds, read-only included, is refused where the filesystem honours locks (Inferred from source, P10). The lock does not stop a process that reads the file without DuckDB. That bears on a pull that reads the files from another process, and not on one served by the writing process. Whether the rule must hold per container is not a platform fact, and the evidence does not settle it.
- **Ticket 07, diagnostics tables.** The proposed wording above is offered in place of its six bullets; on 2026-11-25 the maintainer chose to leave it in this file, and the bullets are unchanged. The ticket asks what is promised where the platform cannot reserve space, and how the host application learns which case it is in. The evidence on that: some refusals are visible as `EOPNOTSUPP` (XFS with `always_cow`, zoned btrfs, a FUSE daemon without `fallocate`, Cloud Storage FUSE, Filestore by inference) (P1, P3, P6); ZFS, with its default emulation, can return success and reserve nothing, and with the emulation switched off returns `EOPNOTSUPP` (P3); glibc's `posix_fallocate` falls back to writing a byte per block, ordinary writes whose blocks a later rewrite reuses only where the filesystem overwrites in place (P2, P3, Inferred); and tmpfs reserves memory instead (P5). So a successful call does not by itself show a reservation that holds. Whether a reservation helps at all also depends on how the on-disk format rewrites a table, below.
- **Ticket 08, fork and more than one process.** DuckDB's documentation says nothing about fork. Its lock is not inherited by a child. A child that opens the file anew asks for its own lock, so a second read-write open fails while the other process still holds its lock (Inferred). In the Python client a new connection in the child may not open the file at all: where the parent's instance for the path was live at the fork, the instance cache would hand the child that instance (Inferred from source, P10). DuckDB's write-lock test asserts the case where the child, forked before any open, opens it first. A child opening its own connection after the parent used DuckDB is reported failing for MotherDuck connections. For a native file that the parent closed before forking, DuckDB's read-lock test asserts that, once the child has opened it read-only, the parent's read-write open throws and its read-only open succeeds. A child that opens read-write after the parent used DuckDB is not covered (P10). A child that keeps using the parent's instance is covered by no DuckDB source (P10). SQLite, the contrast, says never to carry a connection across `fork` (P11). The specification's refusal of establish in a forked child is a proposal; these facts are consistent with it and with other answers, and do not decide between them.
- **The local databases' on-disk format.** The OTel Arrow posts do not settle it: they cover the wire and the pipeline (P13), and OTEP 0156 rejected Parquet for the wire as "not designed as an in-memory format optimized for online data processing", which is not a finding about disk. Ticket 07's premise, rewriting a table in place, turns on where each write lands. A write lands in reserved blocks only where it falls inside the reserved range: an append can use a range reserved beyond the end of the file, which `fallocate(2)` names as a use of `KEEP_SIZE`, and a rewrite lands in them only where the filesystem overwrites them in place (P1). On a copy-on-write filesystem a rewrite goes to new blocks, except a btrfs preallocated extent's first write or a `NOCOW` file, and an XFS block that is not shared (Inferred), each under P3's conditions (P3). How DuckDB writes its own file is read from its source at v2.0.1 (P10). By default a checkpoint writes changed data to free blocks in the file or to new blocks past the highest recorded block, switches between two header slots at fixed offsets, frees the old blocks only after the header is on disk, and truncates free blocks off the end (Inferred from source). So, on a filesystem that overwrites in place, a DuckDB write lands in reserved blocks where it falls inside the reserved range: a reused block that the file still has and no punch has freed, a header slot or a metadata block rewritten at its own id, or a new block inside a reserved range, whether past the end of the file or inside a file a mode-0 reservation extended (P1, Inferred from source). A reused block is not always one the file still has: an id truncated off the tail stays free in the header on disk (Inferred from source). A checkpoint that truncates the file cuts a mode-0 reservation that extended it and, on ext4 at Linux v7.3, a `KEEP_SIZE` range past the end (P1, Inferred from source). The WAL is a second file, which a reservation on the database file does not cover. DuckDB attempts to punch holes in its own file only where the program sets `trim_free_blocks`, and in the opt-in memory-mapped mode when a checkpoint frees blocks at the tail; neither checks the result. That mode's file is extended sparsely to at least 256 GiB by default, and there a write into an unallocated page on a full ext4 filesystem raises `SIGBUS` (Inferred from source). These are the conditions on which a reservation would or would not help a DuckDB file; the findings do not settle whether it would.
