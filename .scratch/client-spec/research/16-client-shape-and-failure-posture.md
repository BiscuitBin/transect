# Research: the client's shape and failure posture

- **Ticket:** `issues/16-research-the-why-client-shape-and-failure-posture.md`. It bears on open question 18 of `docs/specs/transect-client.allium` (whether confluence, establish and core are the final names), on the "Derived" statements that ticket 11 puts to the maintainer, and on the register's Product entries.
- **Sources read:** on 2026-11-25 (UTC), from 01:10 to 04:10, which was 2026-11-24 in the maintainer's local time (UTC−8). The sections below give the local date, 2026-11-24.
- **Web research:** authorised by the maintainer on 2026-11-24 for this ticket, for the agent working it, for its research subagents and for its reviewers. All of it was read-only: nothing was posted, filed or sent.
- **State of this file:** findings only. Fit, the verdict on each claim, the verdict on each stated behaviour and what the findings bear on are written after the first adversarial review.

## How the sources were checked

- **Survey.** Thirteen research subagents each surveyed one group of systems. They fetched every source with `curl` or the GitHub CLI, saved the raw text, quoted from that text, and checked their own quotations by machine. Every link is pinned to a version, a tag or a commit, except pages that have no versions; those are marked where they are cited.
- **The author's own reading.** The author read the sources for the nine facade cells (three parts for each of `log`, `tracing` and `metrics`) independently of the subagents: `src/lib.rs` of `log` at `v0.4.35`, `tracing-core/src/dispatcher.rs` at `tracing-core-0.1.36`, and `metrics/src/recorder/mod.rs` at `metrics-v0.24.6`. The findings in A1 to A3 agree with that reading.
- **Condensing.** The subagents' reports were condensed into the sections below. Quotations were moved unchanged, with the `Source:` line before each.
- **Re-check.** The author then fetched every cited source again, into an empty cache:
  - source and documentation files at their tag or commit, through `raw.githubusercontent.com`;
  - issue, pull request, review-comment and commit text through the GitHub REST API, with a quotation cited to one comment checked against that comment alone;
  - every other page as HTML, with the tags stripped and entities unescaped. Inline code on such a page appears without backticks.

  Each blockquote was then checked by machine as a substring of that text. Every one matched character for character, except those marked "line breaks collapsed". Those match only once whitespace is collapsed, because the source uses CRLF line endings or wraps differently, and their wording is verbatim.
- **What the machine check does not cover.** Only blockquotes were checked by machine. A short phrase quoted inside a sentence was checked by searching the saved source text, and by hand where that search could not reach it. Words in quotation marks that are a claim's or a lead's own wording are marked as such. The repository files quoted in N3 are in code blocks and were checked against the worktree.
- A quotation from source code keeps the comment markers and indentation it has in the file.
- **Leads.** Each research subagent was given the names, numbers and defaults it was to check, such as an API name, an issue number or an RFC. They came from the agent's memory and were unverified. Each section ends with the leads that did not hold: a name that does not exist, an item that behaves otherwise, or a default that differs.
- **Speakers.** Each stated why names its speaker and their role. A role comes from the project's own record where one exists (an authors list, CODEOWNERS, a maintainer's own statement), and otherwise from GitHub's association field (MEMBER, OWNER, COLLABORATOR, CONTRIBUTOR, NONE) as it reads today. A reason given by a user, a reviewer or a third party is labelled as such and is not the authors' stated why.
- **Absence.** Where the file says a project has no such item or states no reason, it says how that was shown: the full item index at the pinned version, a search of the source at the tag, or the tracker searches that were run.

## The maintainer's design, not under test

The shape is the maintainer's design. This file does not reopen it, and nothing below argues for or against it. The maintainer's notes from the elicitation, as the ticket records them verbatim. Asked who starts and ends the client:

> A mix of this and option1. Have a "Confluence" object created at the global scope. It is then used within the application code to request the client via a factory-ish method (with block in python). Then at the different top level contexts the Confluence is configured with either the production core (which links to the writer) or a fake in the context of tests. Let me know if this does or does not feel like idiomatic Rust. If it doesn't feel like idiomatic Rust, then we can just focus on the Python client for now, or we can just consider this overall approach for something that can be idiomatic for both. Or maybe if full threading explicit is more idiomatic for Rust, but then we could still build something like this for Python based on that, we could consider that as well.

Asked which calls may fail loudly and which must be swallowed and counted:

> Whatever option is most idiomatic while also within those boundaries, what's considered idiomatic, normal, and acceptable, whatever will allow for the most, the best developer experience and the best operator experience.

The first note makes the Rust answer a condition: it offers other courses if the shape does not feel idiomatic. The second delegates the failure posture.

What the specification proposes today, in `docs/specs/transect-client.allium`. These are the five stated behaviours that receive a verdict later in this file:

1. **A confluence, establish and a client handle.** A confluence is created at global scope and tables are declared against it. Establish gives the confluence a core for its duration, the production core or a fake core. Application code opens a client handle for one unit of work (the module's header, and the rules `CreateConfluence`, `EstablishProductionCore`, `EstablishFakeCore` and `OpenClientHandle`). The maintainer proposed this shape.
2. **The failure posture.** Declaring a table and establish may fail loudly. Opening a client handle and every write never fail and never block, and a write returns nothing (the comments on `EstablishProductionCore` and `OpenClientHandle`, and the comment that opens the writing rules). The maintainer delegated this choice; the agent chose it as "the usual posture of observability libraries".
3. **Inert without establish.** With no establish in force, writes are discarded and counted, and nothing fails (`DiscardWriteWithoutRun`).
4. **The establish block owns the data writer.** A production run starts the one data writer and ends only once it has stopped (`StartDataWriter`, and the Derived `writer_has_stopped`). The agent framed the lifetime questions with structured concurrency.
5. **The fake core.** A test establishes a fake core, which records every write with its outcome (`RecordedWrite`). The specification marks its rules "Derived": it applies the same declaration, row and tenant rules as the production core, and has no location, data writer, local databases or queue bound.

## The agent's claims under test

Each came from the agent's own knowledge, and no survey was run for any of them. They are the subject of this file.

1. **The facade claim.** The shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests". Checked part by part for each crate in A1 to A3, with OpenTelemetry Rust (A4), Python's `logging` (B1) and OpenTelemetry's globals (C1 to C3) beside them, and the libraries that chose otherwise in H1 to H7.
2. **The scoping claim.** "A Python `with` block maps to a Rust guard value or a closure scope." Checked in D1 to D4, and in what each facade offers (A1 to A4).
3. **The posture claim.** "Observability libraries usually let set-up fail loudly and never let a call on the serving path fail or block." Checked against fourteen libraries in E1 to E14, both halves, and against the facades' own promises (A1 to A4, B1, C1).
4. **The structured concurrency claim.** "Structured concurrency says every background activity lives inside a scope that someone visibly opens and closes." Checked in S1 to S7. The values and blocks that own a background worker in comparable libraries are in G1 to G7.

The test fakes comparable libraries offer are in T1 to T10. What the three names already mean elsewhere is in N, as facts only.

## The facade claim at a glance

Each cell is a summary of the section named. The sections hold the sources.

| | Global entry point | Backend installed at the top level | Scoped override for tests |
| --- | --- | --- | --- |
| `log` 0.4.35 (A1) | **Holds.** An implicit process-wide `static`. Since 0.4.27 a macro may also name its own logger. | **Holds, by convention.** Once per process; a second call returns an error. Nothing enforces that the executable is the one to call it. | **Does not hold.** None, shown from the full item index and the source. Declined on request (issue 81, PR 450). |
| `tracing` 0.1.44 (A2) | **Holds.** Process-wide statics: a global default and a thread-local default. | **Holds, by convention.** Once per process; a second call returns an error. The docs tell libraries not to call it; nothing enforces that the executable is the one to call it. The subscriber is leaked and cannot be cleared. | **Holds, with limits.** A closure and a guard, both thread-local. Open bugs: a `Send` guard that is unsafe to send, out-of-order drops, and interest-cache bugs that silence a scoped subscriber in parallel tests. |
| `metrics` 0.24.6 (A3) | **Holds.** An implicit process-wide `static`, with a thread-local slot consulted first. | **Holds, by convention.** Once per process; a second call returns an error that hands the recorder back. The crate docs assign it to executables; nothing enforces that the executable is the one to call it. The recorder is leaked. | **Holds, with limits.** A closure (0.22.0) and a `!Send` guard (0.24.0), both thread-local. Neither redirects a handle registered before it, and nested guards restore correctly only when dropped innermost first (raised in PR #523, not addressed). |
| OpenTelemetry Rust 0.33.1 (A4) | **Holds, as an option.** The application builds the provider and owns it; the global holds a clone. No global for logs. | **Holds, by convention.** The setters' docs say libraries should not call them and that they are intended for applications. Separately: they can be called any number of times (the last call wins; a call that finds the lock poisoned logs an error and changes nothing), and the global cannot be shut down. | **Does not hold.** None at 0.33.1. A guard existed up to 0.12 and was removed as "a common footgun". |

Four more questions were put to each facade, because the three parts of the claim do not answer them:

| | Is the global an object the application creates and declares things against? | Can the top-level install end, or be repeated? | Does something obtained before install work after it? | Does the facade itself promise anything about a call failing or blocking? |
| --- | --- | --- | --- | --- |
| `log` (A1) | No: an implicit static. | No. Once per process; teardown was removed in 0.4.0. | Macro calls look the logger up each time, so a macro call after install works. The public `logger()` returns a `&'static dyn Log` that is the no-op logger before install, and a reference kept from then stays the no-op. Calls through the global before install are dropped; a call naming its own `logger:` reaches that logger once the maximum level (default `Off`) allows it. | No. `Log::log` returns nothing; only the no-op path's cost is promised. |
| `tracing` (A2) | No: implicit statics. The application builds a `Dispatch` but hands it over once. | Global: no. Scoped: yes, for its closure or guard. | Callsites cache interest; the cache is rebuilt when a `Dispatch` is created, and open bugs can leave a callsite muted. A `Span` keeps the `Dispatch` that created it, and one created disabled stays disabled. | No. No error channel and no `catch_unwind`. |
| `metrics` (A3) | No: an implicit static. | Global: no. Scoped: yes. | **No.** A handle stays bound to the recorder current when it was registered: one obtained with no recorder set, global or local, stays a no-op for good, and one obtained under a local recorder keeps recording to it. A fresh macro call after install records. | No. Only the no-op path's cost is promised. |
| OpenTelemetry Rust (A4) | The provider is an object the application creates and owns; the global is optional. | Global: repeatable; no call ends it, but replacing it drops the previous provider's clone, which shuts that provider down if it was the last. Provider: ends with `shutdown`. | **No.** A tracer or meter obtained before a provider is set stays a no-op. | The global degrades to a no-op rather than panic (since 0.31), and the project's decision record says regular operation should not panic. Recording returns nothing. Whether recording blocks depends on the processor the application chose: the simple processor exports on the calling thread. Obtaining a tracer or meter through the global takes a read lock, which waits while a setter holds the write lock. |
| Python `logging` (B1) | No: an implicit module-level registry. | Repeatable: `dictConfig` and `fileConfig` may run again; `basicConfig` is one-shot unless forced. | Yes: a logger obtained early works once logging is configured, unless `dictConfig` or `fileConfig` disables it (their default). | Handlers swallow their own errors by convention; some errors still reach the caller. |

## A. The Rust facades

The three crates the facade claim names, and OpenTelemetry Rust as a fourth data point.

### A1. `log` (rust-lang/log) (0.4.35)

The Rust `log` crate, read as one of the three facades in the claim that Transect's shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests". Pinned at 0.4.35, the current crates.io release (published 2026-10-30; tag `v0.4.35`, commit `a46450ba763280c29d35b53aa8ad0ff1fc1d78d0`; its changelog entry says it has no source changes). Read 2026-11-24, against the source at the tag and the docs.rs item index (`https://docs.rs/log/0.4.35/log/all.html`, built with `std`, `serde`, `kv_std`, `kv_sval`, `kv_serde`).

**The claim, part by part**

1. Global entry point: holds, with two qualifications. Macros read an implicit process-wide `static mut LOGGER` guarded by an atomic `STATE`. (a) Since 0.4.27 every macro also accepts an explicit `logger:` argument that bypasses the global, though the global maximum level still applies. (b) The static is per linked copy of the crate, so a dynamically loaded library has its own uninitialised copy (issue 421).
2. Backend installed at the top level: holds in convention, not in mechanism. Whoever calls `set_logger` first wins; install is one-shot, a second call returns `Err(SetLoggerError)` without panicking, and there is no uninstall, replace or guard (teardown existed in 0.1 to 0.3 and was removed in 0.4.0). Calls through the global before install are discarded, and a `&'static dyn Log` taken from `logger()` before install stays the no-op; a macro given its own `logger:` is not discarded once `set_max_level` allows its level.
3. Scoped override for tests: does not hold. No scoped, thread-local, guard or closure override exists; maintainers point users at shims built on the global, and third-party test aids (`testing_logger`, `env_logger`'s `is_test`) still install through it.

**What it does**

*Global entry point.* The crate is a facade over an implementation the consumer chooses:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> //! The `log` crate provides a single logging API that abstracts over the
> //! actual logging implementation. Libraries can use the logging API provided
> //! by this crate, and the consumer of those libraries can choose the logging
> //! implementation that is most suitable for its use case.

The logger is an implicit `static`:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> // The LOGGER static holds a pointer to the global logger. It is protected by
> // the STATE static which determines whether LOGGER has been initialized yet.
> static mut LOGGER: &dyn Log = &NopLogger;

The macros (`error!`, `warn!`, `info!`, `debug!`, `trace!`, `log!`, `log_enabled!`) without a `logger:` argument expand to a proxy, `__private_api::GlobalLogger`, which calls `logger()` on each method (`src/macros.rs`, `src/__private_api.rs`). `logger()` is public:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> /// Returns a reference to the logger.
> ///
> /// If a logger has not been set, a no-op implementation is returned.
> pub fn logger() -> &'static dyn Log {

Read from source: while `STATE` is not `INITIALIZED`, `logger()` returns a reference to a local `static NOP: NopLogger`. A caller that keeps that reference keeps the no-op after `set_logger` succeeds; the macros are unaffected because they call `logger()` each time:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
>     if STATE.load(Ordering::Acquire) != INITIALIZED {
>         static NOP: NopLogger = NopLogger;
>         &NOP

A macro given its own `logger:` does not go through the global, but the global maximum level still limits it, and that level defaults to `Off` (quoted below). So a `logger:` call before `set_logger` reaches its logger only once `set_max_level` has been called, which can be done on its own.

Since 0.4.27 (PR 664, by tisonkun, merged 2025-03-23) every macro accepts an optional `logger` argument in place of the global logger, and the global level filter still applies:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/macros.rs
> /// Note that the global level set via Cargo features or through `set_max_level` will
> /// still apply, even when a custom logger is supplied with the `logger` argument.

The global is per copy of the crate in a binary. The README's entry for dynamic libraries:

Source: https://github.com/rust-lang/log/blob/v0.4.35/README.md
> * For dynamic libraries:
>     * You may need to construct [an FFI-safe wrapper over `log`](https://github.com/rust-lang/log/issues/421) to initialize in your libraries.

*Backend installed at the top level.* The application, not libraries, installs:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> //! Libraries should link only to the `log` crate, and use the provided
> //! macros to log whatever information will be useful to downstream consumers.

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> //! Executables should choose a logging implementation and initialize it early in the
> //! runtime of the program. Logging implementations will typically include a
> //! function to do this. Any log messages generated before
> //! the implementation is initialized will be ignored.

Install goes through `set_logger` (takes `&'static dyn Log`), `set_boxed_logger` (takes `Box<dyn Log>` and leaks it) or `set_logger_racy` (an `unsafe` variant for targets without pointer-sized atomics). `set_max_level` is separate and can be called again at any time:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> /// This function may only be called once in the lifetime of a program. Any log
> /// events that occur before the call to `set_logger` completes will be ignored.

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> /// An error is returned if a logger has already been set.

`set_boxed_logger` is gated on `alloc`, not `std`, since 0.4.34 (PR 737); `std` turns `alloc` on:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> #[cfg(all(feature = "alloc", target_has_atomic = "ptr"))]
> pub fn set_boxed_logger(logger: Box<dyn Log>) -> Result<(), SetLoggerError> {
>     set_logger_inner(|| Box::leak(logger))

Install is a compare-and-swap on `STATE`. A second call gets `Err`; a concurrent caller that finds `INITIALIZING` spins until the winner finishes, then gets `Err`:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
>         Err(INITIALIZING) => {
>             while STATE.load(Ordering::Relaxed) == INITIALIZING {
>                 std::hint::spin_loop();
>             }
>             Err(SetLoggerError(()))
>         }

No function uninstalls, replaces or scopes the logger, and none returns a guard. The item index lists exactly: `logger`, `max_level`, `set_boxed_logger`, `set_logger`, `set_logger_racy`, `set_max_level`, `set_max_level_racy`. Teardown was removed in 0.4.0:

Source: https://github.com/rust-lang/log/blob/v0.4.35/CHANGELOG.md
> * The `shutdown` and `shutdown_raw` functions have been removed. Supporting shutdown significantly
>     complicated the implementation and imposed a performance cost on each logging operation.

The maximum level starts at `Off`, so until it is raised no macro call reaches any logger:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> //! messages at levels that are disabled. It's important to set it, as it
> //! defaults to [`Off`][filter_link], so no log messages will ever be captured!

*Scoped override for tests.* None. Shown by the item index (no thread-local, scoped, guard or closure item); a grep of every file under `src/` at the tag (`lib.rs`, `macros.rs`, `__private_api.rs`, `serde.rs`, `kv/*.rs`) for `thread_local|catch_unwind|guard|scope|with_default|set_default`, which matched nothing; and the README and crate docs, which have no section on testing (a grep for "test" finds only the MSRV paragraph, the `RecordBuilder`/`MetadataBuilder` line "for testing and \"shim loggers\"", and the crate's own unit tests).

*Facade guarantee versus backend.* The `Log` trait (`Sync + Send`) returns nothing from `log` and `flush`, and leaves filtering to the implementation:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
>     /// Note that `enabled` is *not* necessarily called before this method.
>     /// Implementations of `log` should perform all necessary filtering
>     /// internally.
>     fn log(&self, record: &Record);

The crate, trait and macro docs make no statement on whether a log call can fail, panic or block (grep of `src/lib.rs`, `src/macros.rs`, `src/__private_api.rs` and `README.md` for `panic` and `block`: the only `panic!` is in `__private_api::log_impl` behind `#[cfg(not(feature = "kv"))]`, a case the public macros already turn into a `compile_error!` in `__log_key`). The facade does promise a cheap no-op path when nothing is installed:

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/lib.rs
> //! If no logging implementation is selected, the facade falls back to a "noop"
> //! implementation that ignores all log messages. The overhead in this case
> //! is very small - just an integer load, comparison and jump.

*Guard or closure.* Neither. Install takes a `'static` reference or a leaked `Box` and returns `Result<(), SetLoggerError>`; no item takes a closure or returns a guard.

**The stated why**

The facade and its install rules were proposed in issue 3 ("Transform liblog into a logging facade", 2014-12-24) and landed in PR 12 ("Rewrite liblog into a logging facade", merged 2015-01-27 by alexcrichton). Both are by Steven Fackler (sfackler; GitHub association MEMBER). alexcrichton, the repository's owner in 2014, reviewed and merged.

Why a facade. Steven Fackler, author of the proposal, issue 3:

Source: https://github.com/rust-lang/log/issues/3
> There are two competing concerns here: we want a single logging interface that libraries can use - it would be crazy to expect someone to provide different versions of a single crate that only differ by their choice of logging framework! But at the same time, we want the libraries to be usable in all of the contexts mentioned above, with their logging intact.

Source: https://github.com/rust-lang/log/issues/3
> One solution is to turn `liblog` into a logging "facade". It provides the infrastructure to allow libraries to send log messages, while allowing the downstream application to chose the actual logging framework that will process the log messages.

Why one global logger rather than thread-local ones. Steven Fackler, issue 3:

Source: https://github.com/rust-lang/log/issues/3
> There is now a single global logger instead of thread-local loggers. The current `liblog` implementation does provide the ability to set the logger, but since it's task local, it's impossible to make sure the right logger is installed in each thread - think of threads started by `TaskPool` for example.

Source: https://github.com/rust-lang/log/issues/3
> In addition, it's not totally clear to me that anyone actually wants to have different loggers on different threads. Even if one does, it's pretty easy to make a thread local logger implementation for the logging facade.

Why one-shot install with no teardown or replacement. Steven Fackler, issue 3:

Source: https://github.com/rust-lang/log/issues/3
> The logger may only be initialized once, and isn't torn down when a program exits. It's possible to support logger replacement and teardown with `atexit` but it would require storing the logger in an `Arc` and adding a couple extra atomic reads and writes every time a message is logged.

Why messages before install are dropped rather than sent to a fallback. Steven Fackler, issue 3:

Source: https://github.com/rust-lang/log/issues/3
> Log messages generated when the logger is not initialized are ignored. Some logging facades like slf4j fall back to a simple logging implementation that dumps messages at the higher levels to the console. We could do this, but I'm a bit hesitant to do something that'll clutter the console for programs that don't want logging information as well as slow them down.

Why install is explicit. Steven Fackler, issue 3:

Source: https://github.com/rust-lang/log/issues/3
> We may be able to do some dark magick with weak linkage, but I think that explicit is better than implicit here.

Why teardown was later removed. alexcrichton, MEMBER, opening the 2017 libs-team evaluation item "Remove logger shutdown":

Source: https://github.com/rust-lang/log/issues/117
> This adds some complexity to the logger plus extra cost on all logger calls.

Steven Fackler, MEMBER, reviewing PR 450 (2021), which proposed `unset_logger` for tests:

Source: https://github.com/rust-lang/log/pull/450#discussion_r605622646
> Older versions of the log crate used to have the ability to deregister a logger, but that was removed due to the overhead required to make the operation safe.

Source: https://github.com/rust-lang/log/pull/450#discussion_r605607282
> This is not memory safe. It can free the logger while another thread is actively using it.

Why a second install returns an error and does not panic. Steven Fackler, PR 230 (2017, merged by alexcrichton), which settled the current `set_logger`/`set_boxed_logger` shape:

Source: https://github.com/rust-lang/log/pull/230
> We also don't want to encourage logger
> implementations to only provide an init function that panics because a
> common way of working with logging in tests is to try to init the system
> in each test and ignore the result.

(Line breaks collapsed: the PR body uses CRLF.)

Why there is no scoped override for tests. Steven Fackler, issue 81 (2016), declining "Make the global logger thread local":

Source: https://github.com/rust-lang/log/issues/81#issuecomment-216287328
> More generally, the log crate used to have a thread local logger, but we explicitly moved away from that in #12.

Steven Fackler, PR 450 review:

Source: https://github.com/rust-lang/log/pull/450#discussion_r605840409
> If you want to test different configurations of a logger, I would recommend having some kind of shim in your code that allowed you to install a thread local logger.

Source: https://github.com/rust-lang/log/pull/450#discussion_r605899007
> If a thread local approach doesn't work, you can use something else (e.g. make a logger that just buffers up log messages and lets you grab all of them at once, and then run tests sequentially).

KodrAus (GitHub association CONTRIBUTOR; has merge rights, as he merged PR 664), closing issue 18 ("Feature request: Logging only for testing") in 2019:

Source: https://github.com/rust-lang/log/issues/18#issuecomment-451059615
> I think this is a bit out-of-scope for `log`, but definitely something we could look at supporting more smoothly in `env_logger`, or another alternative crate specifically for logging in tests.

Why the explicit `logger:` argument was added in 2025, in part to stop assuming a single global. KodrAus, who merged PR 664:

Source: https://github.com/rust-lang/log/pull/664#issuecomment-2638205107
> From a maintenance perspective it also keeps us a bit honest in not being able to assume that everything is shared by a single global logger.

**Inferred**

- Inferred: a panic inside an installed backend's `Log::log` unwinds into the macro's caller. `log` has no `catch_unwind` anywhere in `src/` (grep above), and `GlobalLogger::log` calls `logger().log(record)` directly. No author states this.
- Inferred: whether a log call blocks depends wholly on the backend. The facade's own path is a level check plus an atomic `Acquire` load in `logger()`, and `Log::log` returns `()`, so the caller has nothing to observe or recover from. No author states a blocking guarantee either way.
- Inferred: the facade itself can block a caller only during installation, when a concurrent `set_logger` caller spins while another thread is in `INITIALIZING`.
- Inferred: "top level" is a convention the facade does not enforce. Any crate, a library included, can call `set_logger` first and win; env_logger's docs (below) treat "another library has already initialized a global logger" as an expected failure.

**No stated rationale found**

Not applicable: the authors' why was found (issues 3, 81, 117; PRs 230, 450, 664).

**Constraints**

- Deployment model: libraries depend on the `log` library crate directly; one backend crate per binary installs itself through `set_logger`. `no_std` by default since 0.4.0; `set_boxed_logger` needs `alloc` (0.4.34 onward). `set_logger` needs pointer-sized atomics; `set_logger_racy` is the `unsafe` fallback.
- Guarantees promised: install happens at most once (`Err` after). Calls at disabled levels cost "an integer load, comparison and jump"; the crate docs promise that cost for the no-op path, and it holds while the maximum level is `Off`, its default. If `set_max_level` has raised the level before install (its docs leave that to the implementation: "Generally, this should only be called by the active logging implementation."), a call through the global passes the level check, builds its `format_args!` arguments and a `Record`, and calls the no-op logger, which discards it (read from source, not run). Either way, calls through the global before install are dropped. A compile-time maximum level is available through Cargo features, which the crate docs warn libraries off "because they're global and can't be changed once they're set" (`src/lib.rs`, "Compile time filters").

Source: https://github.com/rust-lang/log/blob/v0.4.35/src/macros.rs
>         if lvl <= $crate::STATIC_MAX_LEVEL && lvl <= $crate::max_level() {
>             $crate::__private_api::log(
>                 $logger,
>                 $crate::__private_api::format_args!($($arg)+),

- Failure model: the facade's only reported failure is `SetLoggerError` at install. Log calls return `()`. Filtering, flushing, buffering, I/O failure and back-pressure belong to the backend; `flush` is "called manually on shut-down" (`Log::flush` doc).
- History: 2014-12 issue 3 proposes the facade (single global, init once, no teardown, ignore before init, manual install). 2015-01 PR 12 lands it. 2016-03 PR 76 stops dropping the logger in an atexit callback (it deadlocked on Windows); PR 78 adds an explicit `shutdown_logger`. 2017-05 the libs-team "libz blitz" evaluation (tracking issue 150) files issue 117 "Remove logger shutdown" and issue 146 "Change set_logger to panic on error". 2017-10 PR 230 keeps `Result` and declines panicking variants, citing tests. 2017-12 0.4.0 removes `shutdown` and adds `Log::flush`. 2025-03 0.4.27 adds the `logger:` macro argument. 2026-08 0.4.34 moves `set_boxed_logger` from `std` to `alloc`.

**Costs and dissent**

- The designer named testing as the unsolved cost from the start. Steven Fackler, issue 3, under "Remaining problems/blockers":

Source: https://github.com/rust-lang/log/issues/3
> Since the logger has to be manually initialized, it becomes very hard to use when running tests. You could make a Once and use that to initialize the logger in every test, but that adds a huge amount of pain to adding new tests.

- The first reviewer named per-test capture as the one use case for thread-local loggers, and worried about the lack of teardown. alexcrichton, then the repository's owner, issue 3:

Source: https://github.com/rust-lang/log/issues/3#issuecomment-68194482
> The one use case I know of for this is a unit testing framework where you want to capture each test's output individually. As you mentioned though you can build this on top of a global framework so it's probably not that bad to lose.

Source: https://github.com/rust-lang/log/issues/3#issuecomment-68194482
> The lack of teardown seems somewhat worrying to me, but the one-time initialization is probably fine.

- Reversal on teardown: absent (2014 proposal), then an atexit drop (removed in PR 76 because Windows runs atexit callbacks after killing other threads, so shutdown could deadlock), then an explicit `shutdown_logger` (PR 78), then removed again in 0.4.0 (issue 117, CHANGELOG).
- Requests for a thread-local or resettable logger were declined: issue 81 (2016, thread-local global, declined by sfackler); PR 450 (2021, `unset_logger` for tests, closed unmerged after review); issue 560 (2023, "Is it possible to reset the global logger", closed by Thomasdezeeuw, CONTRIBUTOR):

Source: https://github.com/rust-lang/log/issues/560#issuecomment-1871111861
> Closing this as not possible with the current design.

Thomasdezeeuw (CONTRIBUTOR) gave the reason in the same thread:

Source: https://github.com/rust-lang/log/issues/560#issuecomment-1671310192
> If the logging implementation could be de-initialised or switched it could means that the logger would be deallocated while references to it still exists.

- Idempotent install requested for tests (issue 415, 2020, by a user), closed by KodrAus (CONTRIBUTOR, merge rights):

Source: https://github.com/rust-lang/log/issues/415#issuecomment-968564127
> It sounds like we don't have any really compelling alternative initialization strategies.

- Race in user test setups. Issue 650 (2024): a user's test logger raced `set_logger` against `set_max_level`. sfackler (MEMBER):

Source: https://github.com/rust-lang/log/issues/650#issuecomment-2548822361
> When called concurrently, the thread that loses the race to call set_logger first can return before set_max_level has been called.

- Dynamic libraries: each copy of `log` has its own uninitialised global (issue 421, 2020; users' workarounds pass the host's `&'static dyn Log` across the boundary). The README now points there.
- Partial move away from the sole global: PR 664 (0.4.27) lets a call name its logger. Thomasdezeeuw (CONTRIBUTOR) dissented on complexity:

Source: https://github.com/rust-lang/log/pull/664#issuecomment-2642416057
> I'm not convinced the additional complexity is worth the use case that is already possible via the log implementation.

- Comparable that chose otherwise, raised in the same thread: a user (NobodyXu, association NONE) compared PR 664 with `tracing`'s thread-local `with_default`. The PR's author (tisonkun, CONTRIBUTOR) rejected that model for this case; a contributor's view, not the maintainers' stated why:

Source: https://github.com/rust-lang/log/pull/664#issuecomment-2644456757
> This is a thread-local default, which can be even worse than a global default to tune with.

- Third-party test aids, not part of `log`. `testing_logger` 0.1.1 (third-party, last published 2018-08-07) captures log events into a thread-local behind the global logger so that multithreaded test runs behave correctly. `env_logger` 0.11.12 (third-party, rust-cli/env_logger) offers `Builder::is_test`, which lets the test framework capture records instead of printing them. It is not a scoped override: install still goes through the one global, and `try_init` fails on a second call:

Source: https://docs.rs/env_logger/0.11.12/env_logger/struct.Builder.html
> This function will fail if it is called more than once, or if another
> library has already initialized a global logger.

**Unverified**

- The 2017 libs-team crate evaluation thread on internals.rust-lang.org ("Crate evaluation for 2017-05-16: log", linked from issues 109 and 150) was not fetched; its reasons for removing shutdown and wanting panicking `set_logger` variants are known only through issues 117, 146 and PR 230.
- Formal maintainer roles. crates.io lists one owner, `rust-lang-owner`. GitHub's `author_association` is today's value: MEMBER for sfackler, alexcrichton and dtolnay; CONTRIBUTOR for KodrAus and Thomasdezeeuw. KodrAus's merge rights rest on PR 664's `merged_by`. Not confirmed: who the current maintainers are, or whether sfackler was "the maintainer" in 2014 (in issue 3 alexcrichton speaks as the owner).
- Whether a panic in a backend's `Log::log` propagates (Inferred above from the absence of `catch_unwind`; no test or document confirms it).
- The 2016 atexit deadlock rationale is from PR 76's description (sfackler), summarised under Constraints, not reproduced or quoted.

#### Leads that did not hold (`log`)

- "A rust-lang RFC that redesigned the log crate (around 2015, by its then maintainer)." No such RFC exists in rust-lang/rfcs: the `text/` tree at commit `f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07` (648 entries) has no file whose name contains "log", and a search `repo:rust-lang/rfcs author:sfackler` (25 results) has no logging RFC. The redesign was proposed in rust-lang/log issue 3 (2014-12-24, sfackler) and landed in PR 12 (2015-01-27). The only RFC in the log repository, `rfcs/0296-structured-logging.md` (2018, KodrAus), covers structured logging. On "its then maintainer": in issue 3 alexcrichton writes as owner and sfackler as proposer; the record does not show sfackler as maintainer in 2014.
- "`set_boxed_logger` requires a `std` feature." At 0.4.35 it requires `alloc` (`#[cfg(all(feature = "alloc", target_has_atomic = "ptr"))]`), which `std` implies. The change came in 0.4.34 (PR 737, "Add alloc support for boxed loggers"); the 0.4.0 changelog's "It requires the `std` feature." was true until then.
- "A scoped override for tests" (part 3 of the claim). Absent: item index, source grep, issue 81, PR 450, issue 18.
- "A global entry point" taken as the only entry point. Since 0.4.27 the macros also accept an explicit `logger:` argument, so the global is the default, not the only route; the global maximum level still applies to that route.
- `set_logger`, `set_max_level`, `set_boxed_logger` all exist with the described roles; in addition, `set_logger_racy` and `set_max_level_racy` exist as `unsafe` variants for targets without pointer-sized atomics.

### A2. `tracing` and `tracing-core` (tokio-rs/tracing) (`tracing` 0.1.44, `tracing-core` 0.1.36)

Tokio's instrumentation crates, tested against the claim that Transect's shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests". Pinned: `tracing` 0.1.44 (tag `tracing-0.1.44`, commit `2d55f6faf9be83e7e4634129fb96813241aac2b8`), `tracing-core` 0.1.36 (tag `tracing-core-0.1.36`, commit `10a9e838a35e6ded79d66af246be2ee05417136d`), `tracing-subscriber` 0.3.23 (commit `54ede4d5d85a536aed5485c5213011d9ec961935`, cited only for installation); unreleased `v0.2` on `master` at `74fc079d2308a959d3a17907b3ba592ffd0a98f7`. Read 2026-11-24.

Speakers: `hawkw` is Eliza Weisman (GitHub profile name; first listed author in `tracing/Cargo.toml`; signs her own pull requests, e.g. tokio #1033). `carllerche` is Carl Lerche (GitHub profile name), tokio-rs `MEMBER`. Roles come from each comment's `author_association`.

**The claim, part by part**

1. *A global entry point: holds.* The macros take no handle; they reach the subscriber through process-wide statics in `tracing-core` (a `static mut GLOBAL_DISPATCH`, a `thread_local!` current default, a global callsite registry and a global registry of every live `Dispatch`). The application builds a `Dispatch` and hands it over once to be installed, never to call sites.
2. *A backend installed at the top level: holds, by convention.* `set_global_default` installs it once for the life of the process; a second call returns `Err`, nothing removes or replaces it, the subscriber is deliberately leaked, and the docs tell libraries not to call it. History: the 2018 prototype had a `log`-style global, prototype issue #30 (2018) removed it, `tokio-trace` entered Tokio (#827, February 2019) with only a thread-local default, and a contributor's #1152 (June 2019) added a global back as a fallback.
3. *A scoped override for tests: holds, with limits.* `with_default` (closure) and `set_default` (returns a `DefaultGuard`) exist and tests are a named motivation. It is not test-specific (from #30 until #1152 it was the only mechanism), which the claim does not require. The limits: the override is thread-local (not reaching spawned threads or runtime workers), and it is not isolated: the `Send` guard dropped on another thread rewrites that thread's default (fix proposed 2023, open); out-of-order drops leave the wrong dispatcher (open since 2021); any new `Dispatch` changes the interest cached at every callsite for every thread, and open bugs make a scoped subscriber silently miss events under parallel `cargo test` (#2874, #3611); bugs aside, several dispatchers cost weaker caching, not different results (#927); and a scoped default sets a process-wide `EXISTS` flag that is never cleared (#1102).

Whether `tracing` is a "facade": it never calls itself one. A case-insensitive grep for `facade` across `tracing/src`, `tracing-core/src` and the three READMEs in the `tracing-0.1.44` tarball finds a single hit, describing `log`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //! The [`log`] crate provides a simple, lightweight logging facade for Rust.

**What it does**

Checked 2026-11-24 against source at the pinned tags.

*1. Global entry point.* Every thread has a current default subscriber:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> //! Every thread in a program using `tracing` has a _default subscriber_. When
> //! events occur, or spans are created, they are dispatched to the thread's
> //! current subscriber.

The global default is a `static mut GLOBAL_DISPATCH`; the per-thread default is a `std::thread_local!`. An event macro ends in `Event::dispatch`, which calls `get_default`. That reads the global without touching the thread-local while no scoped default exists anywhere in the process:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> // fast path if no scoped dispatcher has been set; just use the global

A thread-local default, when set, overrides the global, which is only the fallback:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> /// Will be used as a fallback if no thread-local dispatch has been set in a thread

Building a `Dispatch` is not inert: `Dispatch::new` registers it in a process-wide registry whether or not it is ever installed.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> callsite::register_dispatch(&me);

A span keeps the dispatcher that created it, so later operations on it go to that subscriber whatever the current thread's default is:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/span.rs
> /// The subscriber that will receive events relating to this span.

*2. Backend installed at the top level.* `set_global_default` installs it once:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> /// Can only be set once; subsequent attempts to set the global default will fail.
> /// Returns `Err` if the global default has already been set.

A second call returns `SetGlobalDefaultError`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> const MESSAGE: &'static str = "a global default trace dispatcher has already been set";

It cannot be ended or replaced; the subscriber is leaked when installed:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> // safety: this leaks the subscriber onto the heap. the

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> // global default will never be dropped.

The absence of an unset or replace function was shown from the docs.rs item indexes (`tracing-core` 0.1.36 and `tracing` 0.1.44 `all.html`, read 2026-11-24): `dispatcher` lists only `get_default`, `set_default`, `set_global_default` and `with_default`; `tracing::subscriber` only `set_default`, `set_global_default` and `with_default`. A subscriber whose configuration must change at runtime does so itself, for example through `tracing-subscriber`'s `reload` layer (linked from the 2019 blog post; not examined).

The global is used in all threads for the rest of the program, "similar to setting the logger in the `log` crate" (crate docs), and belongs in the executable:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //!     <strong>Warning</strong>: In general, libraries should <em>not</em> call
> //!     <code>set_global_default()</code>! Doing so will cause conflicts when
> //!     executables that depend on the library try to set the default later.

`tracing-subscriber` installs through `SubscriberInitExt`: `try_init` returns an error, `init` panics:

Source: https://github.com/tokio-rs/tracing/blob/tracing-subscriber-0.3.23/tracing-subscriber/src/util.rs
> /// This method returns an error if a global default subscriber has already
>     /// been set, or if a `log` logger has already been set (when the
>     /// "tracing-log" feature is enabled).

Source: https://github.com/tokio-rs/tracing/blob/tracing-subscriber-0.3.23/tracing-subscriber/src/util.rs
> /// This method panics if a global default subscriber has already been set,

*Before any subscriber is installed*, the current default is a no-op that drops everything; events outside a subscriber "will not be collected" (crate docs), and nothing is buffered:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> //! By default, the current subscriber is an empty implementation that does
> //! nothing.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/subscriber.rs
> /// never being interested in any callsite, and dropping all spans and events.

With the non-default `log` feature (`tracing/Cargo.toml` has `default = ["std", "attributes"]`), the crate docs say an event or a span with fields is not discarded when no subscriber is active:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //! This crate provides two feature flags, "log" and "log-always", which will
> //! cause [spans] and [events] to emit `log` records. When the "log" feature is
> //! enabled, if no `tracing` `Subscriber` is active, invoking an event macro or
> //! creating a span with fields will emit a `log` record.

The macro tests something narrower: whether a dispatcher has ever been set in the process, not whether one is active now (read from source, not run). Without `log-always`, the `log` record is emitted only while `has_been_set()` is false. Both `set_global_default` and the scoped `set_default`, which `with_default` calls, set that flag, and nothing clears it (`DefaultGuard`'s drop does not). So once a scoped default has been set and dropped, an event with no active subscriber is neither recorded nor emitted as a `log` record (#1102, under Costs and dissent):

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/macros.rs
>         if $crate::level_to_log!($lvl) <= $crate::log::STATIC_MAX_LEVEL {
>             if !$crate::dispatcher::has_been_set() {
>                 $if_log
>             } else {
>                 $else_block
>             }

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> /// Returns true if a `tracing` dispatcher has ever been set.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
>         EXISTS.store(true, Ordering::Release);
>         SCOPED_COUNT.fetch_add(1, Ordering::Release);
>         DefaultGuard(prior)

*Callsites registered before a subscriber is installed.* Each callsite caches the combined `Interest` of the live dispatchers. The module docs say the cache is rebuilt when a `Dispatch` is created:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/callsite.rs
> //! When a new [`Dispatch`] is created (i.e. a new subscriber becomes
> //! active), any previously cached [`Interest`] values are re-evaluated
> //! for all callsites in the program.

In the source it is rebuilt in exactly two places: `register_dispatch` (called by `Dispatch::new`, `callsite.rs:487`) and the public `rebuild_interest_cache()` (`callsite.rs:223`), per a grep of `tracing-core/src` for `rebuild_interest`. `set_global_default`, `set_default`, `with_default` and `DefaultGuard::drop` do not rebuild it. So:

- A callsite first hit before any `Dispatch` exists caches `never`; creating the `Dispatch` later rebuilds it, so it recovers.
- A callsite first hit after `Dispatch::new` but before that dispatcher is installed on the hitting thread can cache `never` for good while it is the only dispatcher in the process (#2874, #3611 below). The `Rebuilder::JustOne` path asks the current thread's default, not the registered dispatcher:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/callsite.rs
> Rebuilder::JustOne => {

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/callsite.rs
> dispatcher::get_default(f);

The module docs also say dropping a subscriber re-evaluates the cache:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/callsite.rs
> //! subscriber is dropped, the interest cache is also re-evaluated, so

The 0.1.36 source does not bear this out (docs and source disagree). `Dispatch` has no `Drop` impl (a grep of `dispatcher.rs` for `impl Drop` finds only `Entered` and `DefaultGuard`, neither of which rebuilds), and a dropped dispatcher is only pruned (`dispatchers.retain(|d| d.upgrade().is_some())`) when the next `Dispatch` is registered. An open pull request by Hayden Stainsby (`hds`, CONTRIBUTOR) says the same:

Source: https://github.com/tokio-rs/tracing/pull/3530
> `with_default` has returned), the interest cache is not rebuilt.

*Spans created before a subscriber is installed.* A `Span` holds the `Dispatch` that created it, and a span that no subscriber enabled has no inner value. Its `inner` is set only when it is constructed, so a disabled span stays disabled after a subscriber is installed:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/span.rs
>     /// The subscriber that will receive events relating to this span.
>     ///
>     /// This should be the same subscriber that provided this span with its
>     /// `id`.
>     subscriber: Dispatch,

*3. Scoped override for tests.* Two forms, both thread-local:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //! This approach allows trace data to be collected by multiple subscribers
> //! within different contexts in the program. Note that the override only applies to the
> //! currently executing thread; other threads will not see the change from with_default.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> //! It's important to note that `with_default` will not propagate the current
> //! thread's default subscriber to any threads spawned within the `with_default`
> //! block.

`set_default` returns `pub struct DefaultGuard(Option<Dispatch>);`, which restores the prior default when dropped:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> #[must_use = "Dropping the guard unregisters the dispatcher."]

The guard is `Send` (and `Sync`) at 0.1.36, by auto-trait:

Source: https://docs.rs/tracing-core/0.1.36/tracing_core/dispatcher/struct.DefaultGuard.html
> impl Send for DefaultGuard

The unreleased `v0.2` line has the same definition (`tracing-core/src/dispatch.rs` at `74fc079d`, no `PhantomData` or `NotSend` marker). Its drop writes to whichever thread runs it:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> let prev = CURRENT_STATE.try_with(|state| state.default.replace(self.0.take()));

The `set_default` and `DefaultGuard` docs say nothing about threads, `Send` or `.await` (read `dispatcher.rs` lines 230 to 276 and `tracing/src/subscriber.rs` in full). The only `.await` warning is on `Span::enter`, about span guards, not dispatcher guards.

For async code the supported carrier is `WithSubscriber`, which sets the default for the duration of each `poll`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/instrument.rs
> /// This can be used to propagate the current dispatcher context when
>     /// spawning a new future that may run on a different thread.

`Instrument` attaches a span to a future, not a subscriber.

Interest is combined across all live dispatchers, so when they disagree a callsite falls back to asking the current subscriber each time (changelog: "the current subscriber is now always asked"):

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/callsite.rs
> //! When registering a new callsite, the [`Interest`]s returned by every
> //! currently active subscriber are combined, and the result is stored at
> //! each callsite.

`tracing-subscriber`'s own `set_default` has a process-wide, one-shot side effect with its default `tracing-log` feature on: it tries to install the `log` crate's global logger and discards the error:

Source: https://github.com/tokio-rs/tracing/blob/tracing-subscriber-0.3.23/tracing-subscriber/src/util.rs
> let _ = tracing_log::LogTracer::init();

Source: https://github.com/tokio-rs/tracing/blob/tracing-subscriber-0.3.23/tracing-subscriber/Cargo.toml
> default = ["smallvec", "fmt", "ansi", "tracing-log", "std"]

*4. Facade guarantee versus backend.* `tracing` promises nothing about a subscriber call failing, panicking or blocking. Subscriber methods return no error:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/subscriber.rs
> fn event(&self, event: &Event<'_>);

`grep -rn catch_unwind` over `tracing-core/src` and `tracing/src` finds nothing, so a panicking subscriber unwinds into the instrumented code. A case-insensitive grep of the same directories for panic and blocking guidance (`never panic`, `must not block`, `non-blocking` and similar) finds only an unrelated `span::Id` note and the `tracing-appender` description below. The only panic guidance to subscribers concerns `try_close`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/subscriber.rs
> /// implementations should ensure that they are unwind-safe. Panicking from

Non-blocking output belongs to the backend, as a separate crate:

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //!    including a file appender and non blocking writer.

What the dispatch layer does guarantee: `set_global_default` returns `Err` rather than panicking; during thread-local teardown `try_with` fails and `get_default` falls back to `NONE`; and it blocks recursion only on the scoped path, and there only for subscriber calls made inside `get_default`: an event or span emitted from inside a subscriber's `event` or `new_span` goes to a no-op dispatcher while a scoped default is live on some thread. `Span::enter`, its exit, `Span::record` and the span's drop call the subscriber held in the span directly, so an event emitted from inside `Subscriber::enter` finds the re-entry flag clear and reaches the thread's current default (read from source, not run). When no scoped default is live, the fast path added in 0.1.31 (#2593) returns the global before the re-entry check, so a subscriber that emits reaches itself again:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
>     if SCOPED_COUNT.load(Ordering::Acquire) == 0 {
>         // fast path if no scoped dispatcher has been set; just use the global
>         // default.
>         return f(get_global());
>     }

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> /// Note that calls to `get_default` should not be nested; if this function is
> /// called while inside of another `get_default`, that closure will be provided
> /// with `Dispatch::none` rather than the previously set dispatcher.

The guard is taken in `get_default`, which `Event::dispatch` and span creation go through. A span's own calls are made on the `Dispatch` it holds (read from source, not run):

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
>             if let Some(entered) = state.enter() {
>                 return f(&entered.current());
>             }

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/span.rs
>         if let Some(inner) = self.inner.as_ref() {
>             inner.subscriber.enter(&inner.id);
>         }

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
>     pub fn enter(&self, span: &span::Id) {
>         self.subscriber().enter(span);
>     }

The dispatch layer can itself panic. The callsite and dispatcher registries use `.lock().unwrap()`, `.read().unwrap()` and `.write().unwrap()` (`callsite.rs` lines 428, 476, 548, 552); with the default `std` feature these are the standard library's locks, which report poisoning, so they panic on a poisoned lock. Only the `no_std` build's vendored spin lock never reports poisoning.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/lib.rs
> pub(crate) use std::sync;

Calling `set_default` from inside `get_default` panics. Lily Ballard (`lilyball`, CONTRIBUTOR) reported it; still open:

Source: https://github.com/tokio-rs/tracing/issues/1655
> Despite this, calling `set_default()` from within `get_default()` panics with `already borrowed: BorrowMutError`, which appears to be entirely unintentional.

*5. Guard or closure.* The closure came first. The guard was added in `tracing-core` 0.1.7 by #388, at Eliza Weisman's request in #383; `with_default` is now a thin wrapper that holds the guard for the closure's duration.

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/CHANGELOG.md
> - Added `dispatcher::set_default` API which returns a drop guard (#388)

**The stated why**

*Why the scoped default came first and the global was resisted.* Carl Lerche (MEMBER of tokio-rs on #1152; COLLABORATOR on the prototype repository), prototype design issue, 2018-10-02:

Source: https://github.com/hawkw/tokio-trace-prototype/issues/30
> Following Tokio patterns (and departing from `log`), there should be no global subscriber state.

Source: https://github.com/hawkw/tokio-trace-prototype/issues/30
> The Tokio runtime will handle setting up the subscriber at the root of the task.

Source: https://github.com/hawkw/tokio-trace-prototype/issues/30
> We can always back out of this by adding global state later, but we cannot remove global state without a breaking change.

Eliza Weisman, author (OWNER of the prototype repository), replying:

Source: https://github.com/hawkw/tokio-trace-prototype/issues/30#issuecomment-426410827
> I'm onboard with this change as well --- the current global subscriber was based on what the `log` crate does, and I'm not sure if replicating that was the right thing to do.

Source: https://github.com/hawkw/tokio-trace-prototype/issues/30#issuecomment-426410827
> This would also have the nice side benefit of making testing much easier.

The removal was carried out: the dispatcher as introduced into Tokio (#827, commit `c08e73c8d4f3353e93658aa4eb488c0080d0cab0`) holds its default only in a thread-local, with a closure-based `with_default`; a grep of that file for `static`, `global` and `set_global` finds only:

Source: https://github.com/tokio-rs/tokio/blob/c08e73c8d4f3353e93658aa4eb488c0080d0cab0/tokio-trace/tokio-trace-core/src/dispatcher.rs
> static CURRENT_DISPATCH: RefCell<Dispatch> = RefCell::new(Dispatch::none());

*Why a global default was then added (June 2019).* james gilles (`kazimuth`, CONTRIBUTOR), in the pull request the maintainers merged as commit `36ed35c52c88` in `tokio-rs/tokio`:

Source: https://github.com/tokio-rs/tokio/pull/1152
> In that thread pool, there's no way to set a tokio-trace subscriber for the duration of each thread, since you don't control the thread initialization.

Source: https://github.com/tokio-rs/tokio/pull/1152
> Performance-wise, thread-local `Dispatch` lookup goes from ~4.5ns to ~5ns, according to the benchmarks.

The added `set_global_default` "works similarly to the `log` crate" (same pull request).

Eliza Weisman, maintainer, reviewing #1152, on why libraries must not call it:

Source: https://github.com/tokio-rs/tokio/pull/1152#discussion_r294057074
> I think it's worth cautioning that libraries should generally not call this function, to avoid conflicting with a global subscriber set by their dependents.

David Barsky (`davidbarsky`, MEMBER), reviewing #1152, on why a second call returns a `Result`:

Source: https://github.com/tokio-rs/tokio/pull/1152#discussion_r294049075
> With `Result`, one could write `set_global_default(SomeSubscriber).expect("Unable to set default subscriber");` and crash immediately if there is some sort of logic failure (e.g., a global subscriber was set twice).

*Why the global default cannot be cleared.* Eliza Weisman, maintainer, declining #652 (2020), which added an `unsafe` function to drop it:

Source: https://github.com/tokio-rs/tracing/pull/652#issuecomment-606327616
> Hmm...I'm sympathetic to your use-case, but this is a pretty dangerous API to provide, and I'd prefer not to without good reason.

She pointed to the scoped API instead:

Source: https://github.com/tokio-rs/tracing/pull/652#issuecomment-606327616
> Since a `Dispatch` is internally reference counted, if you use those functions, your subscriber _will_ be dropped once all scopes using it have completed, without needing new unsafe APIs.

*Why the flag recording whether a dispatcher has ever been set is never cleared.* Eliza Weisman, maintainer, #1102 (2020):

Source: https://github.com/tokio-rs/tracing/issues/1102#issuecomment-727053306
> However, I think it's important to ensure that the case where `tracing` is never enabled, and the case where a global tracing subscriber is set for the entire run time of the program both remain fast paths.

*Why the closure form.* Crate documentation (authors: Eliza Weisman and Tokio Contributors):

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //! [`with_default`] function. This follows the `tokio` pattern of using
> //! closures to represent executing code in a context that is exited at the end
> //! of the closure.

*Why the guard was added.* Eliza Weisman, maintainer, feature request #383, 2019-10-15:

Source: https://github.com/tokio-rs/tracing/issues/383
> For example, if I wanted to use a fresh subscriber in each of my tests, I would need to use `with_default`, requiring indenting the entire test into a closure.

Source: https://github.com/tokio-rs/tracing/issues/383
> When adding `tracing` to an existing codebase, this can result in unnecessarily large diffs.

The same issue gives the case against a guard:

Source: https://github.com/tokio-rs/tracing/issues/383
> The existing API was chosen for consistency with existing `tokio` APIs, and adding a new way to set the default subscriber could introduce confusion.

and why `with_default` already used a guard internally:

Source: https://github.com/tokio-rs/tracing/issues/383
> This is in order to unset the default subscriber on panics.

Later in the thread she removed the objection:

Source: https://github.com/tokio-rs/tracing/issues/383#issuecomment-542404759
> Therefore, the "consistency with `tokio`" argument against adding a drop-guard-based API is pretty much moot, and I think we should probably go ahead and add `set_default` to `tracing` as well.

and named what scoping buys for tests:

Source: https://github.com/tokio-rs/tracing/issues/383#issuecomment-541984396
> And, since `tracing` (unlike `log`) has a notion of scoped subscribers, we can do really nice stuff like separating the output from each test, as well.

*Why the global path is made fast at the expense of the scoped one.* Eliza Weisman, maintainer, #2593 (2023), which removed thread-local caching of the global default:

Source: https://github.com/tokio-rs/tracing/pull/2593
> In my opinion, this performance change is acceptable, as a
> global default dispatcher is the common case for most users, and is
> generally expected to perform better than the scoped default.

(Line breaks collapsed: the source uses CRLF.)

*Why recursion is guarded in the dispatch layer.* Eliza Weisman, tokio #1033 (2019):

Source: https://github.com/tokio-rs/tokio/pull/1033
> This prevents infinite loops if the subscriber calls code paths which
> emit events or construct spans.

(Line breaks collapsed: the source uses CRLF.)

**Inferred**

- Inferred: the thread-local default (`thread_local!`, read through `RefCell`) means a scoped override costs no synchronisation on the hot path, and the `SCOPED_COUNT` atomic lets processes that never use a scoped default skip the thread-local entirely. No author states this pairing as the reason; #2593 and #1152 state only the measured costs.
- Inferred: `DefaultGuard` is `Send` by accident of its field types (`Option<Dispatch>`, an `Arc` of a `Send + Sync` subscriber), not by decision. It carries no marker, and the maintainer's reply on #2482 treats `!Send` as the intended fix.
- Inferred: the global subscriber is leaked so that `get_global()` can hand out a `&'static` reference with no reference counting. The source comment states the leak but not why.

**No stated rationale found**

Not applicable: a why was found for each part, including the refusal to clear the global default (#652). One narrower absence: the Tokio blog post introducing `tracing` (2019-08-14, `content/blog/2019-08-tracing.md` in `tokio-rs/website` at `71cdb3858fbb943843e8cf0e8baf547fe22180f7`) gives no reason for a global or a scoped default; a grep for `global`, `default`, `subscriber`, `thread`, `test` and `facade` finds passages on threads in async systems, on `log` as a facade and on `Subscriber` as the extension point, and the one passage on installation is:

Source: https://github.com/tokio-rs/website/blob/71cdb3858fbb943843e8cf0e8baf547fe22180f7/content/blog/2019-08-tracing.md
> A [`Subscriber`][subscriber] implementation collects and records trace data,
> similarly to a logger in conventional logging. Applications must set up a
> [default subscriber][default-sub].

**Constraints**

- *Deployment model:* an in-process library linked into both libraries and executables; the executable chooses and installs the subscriber, and `tracing-core` is the kernel every subscriber and instrumentation crate shares.

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/lib.rs
> //! Libraries should link only to the `tracing` crate, and use the provided

- *Async runtime:* the design starts from Tokio's work-stealing pools, where a task can move between threads. That is why thread-local scoping has to be carried per future (`WithSubscriber`), and why a contributor needed a process-wide default for pools whose threads the user does not start (#1152).
- *`no_std`:* the thread-local scoped default needs `std`; `no_std` users have only `set_global_default`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> //!     Rust standard library. <code>no_std</code> users should use

- *Guarantees:* the global default is set at most once and never dropped; events and spans outside any subscriber are discarded unless the non-default `log` feature is enabled and no dispatcher, global or scoped, has ever been set in the process, in which case they are emitted as `log` records to whatever `log` backend is installed (read from source, not run); recursion from inside a subscriber's `event` or `new_span` goes to a no-op dispatcher only while a scoped default is live; otherwise the fast path skips that guard, and calls a span makes on its own subscriber (`enter`, `exit`, `record`, close) are not guarded at all (read from source, not run). No guarantee on panics, errors or blocking in the subscriber: those belong to the backend.
- *Failure model:* installation fails loudly once (`Err`, or a panic from `init`). Recording has no error channel. A subscriber panic propagates to the call site, and a poisoned registry lock panics later callers.
- *History:* prototype #30 (2018-10) agreed to remove the `log`-style global; `tokio-trace` entered Tokio with only a thread-local default (#827, 2019-02); tokio #1152 (2019-06) added `set_global_default` back as a fallback; #383 and #388 (2019-10) added `set_default`; #2065 (2022) fixed a scoped guard clobbering a later global default; #2593 (`tracing-core` 0.1.31, 2023-05) removed thread-local caching of the global and added the `SCOPED_COUNT` fast path; both are in the `tracing-core` changelog.

**Costs and dissent**

- *Tests sharing one process-global subscriber* were the original complaint (Eliza Weisman, prototype #30, quoted above, who had to "hack around" it). Benjamin Saunders (`Ralith`, COLLABORATOR, a user voice) in #383:

Source: https://github.com/tokio-rs/tracing/issues/383#issuecomment-541981475
> To be clear, there doesn't seem to be a simple way to set a single global subscriber for tests, so this use case isn't niche.

The maintainers' own workaround for testing the one-shot global is one test binary per global:

Source: https://github.com/tokio-rs/tokio/pull/1152#discussion_r294056829
> This is because each file in `tests` is compiled into its own binary when run, and will thus have its own globals.

- *A `Send` guard that is not safe to send* (open). Benjamin Woodruff (`bgw`, user, NONE) reported it; his #2488 to mark it `!Send` is still open:

Source: https://github.com/tokio-rs/tracing/issues/2482
> However, because `DefaultGuard` is `Send`, that may be a different thread local.

Source: https://github.com/tokio-rs/tracing/issues/2482
> - This avoid footguns with `Send` futures. Somebody might write an async function that thinks it's within a certain guard, but isn't if work stealing happens.

Eliza Weisman, maintainer:

Source: https://github.com/tokio-rs/tracing/issues/2482#issuecomment-1439101937
> We should definitely make the guard `!Send` in v0.2.x.

Source: https://github.com/tokio-rs/tracing/issues/2482#issuecomment-1439101937
> In the meantime, though, we may want to investigate alternate solutions for 0.1.x. I agree that the potential performance penalty for making the guard handle the case where it's sent across threads is quite unfortunate, especially if it's paid in all uses of the scoped dispatcher API...

- *Guards dropped out of order* (open since 2021, Lily Ballard, CONTRIBUTOR). The current default is a single slot holding the previous value, not a stack:

Source: https://github.com/tokio-rs/tracing/issues/1657
> Dropping `DefaultGuard`s in a different order than they were created will leave the wrong dispatch active.

- *Interest-cache bugs that silence a scoped subscriber* (open at the pinned versions). They happen when exactly one dispatcher exists; many dispatchers hide them. Reporter `plietar` (user, NONE):

Source: https://github.com/tokio-rs/tracing/issues/2874
> Under the right set of circumstances, it is possible for all events and spans to be silenced, regardless of the subscriber's configuration.

Users report the effect in tests (`ThomWright` and `andyczerwonka`, both NONE):

Source: https://github.com/tokio-rs/tracing/issues/2874#issuecomment-2334865246
> For what it's worth, I believe this is what is making my tests flaky.

Source: https://github.com/tokio-rs/tracing/issues/3611#issuecomment-6299997622
> We encountered empty thread-local log captures under parallel `cargo test`, while nextest’s process-per-test execution passes.

The reporter of #3611 (`jgxgmxcom`, user) states the masking:

Source: https://github.com/tokio-rs/tracing/issues/3611
> Two concurrently registered dispatches avoid the bug, because then the general path over the global dispatch list is taken.

A user (`Spikhalskiy`, NONE) reports that `set_global_default` alone can hit it too; unconfirmed by a maintainer:

Source: https://github.com/tokio-rs/tracing/issues/2874#issuecomment-6540020515
> FWIW this isn't just a scoped-subscriber thing. Plain `set_global_default` hits it too: `Dispatch::new` registers the dispatch before it's published as global, so a thread that hits a cold callsite in between gets `NoSubscriber` via the `JustOne` path and caches `never`. Nothing rebuilds it afterwards, so that callsite stays muted until some other `Dispatch` gets created, i.e. usually forever.

The fixes are open pull requests #3614 (Xavier Lange, `xrl`, NONE) and #3530 (Hayden Stainsby, CONTRIBUTOR), neither merged as of 2026-11-24.

- *Thread-local caching of the global default*, which caused stale defaults, was reversed in #2593. Eliza Weisman, maintainer:

Source: https://github.com/tokio-rs/tracing/pull/2593
> When `get_default` runs for the first time and
> there is no global default, a `none` dispatcher is cached as the
> thread-local default.

(Line breaks collapsed: the source uses CRLF.) The cost was a slower scoped path ("a noticeable decrease in performance for some benchmarks using the scoped default", same pull request).

- *Panic in the dispatch layer on nested `set_default`* (#1655, open). Eliza Weisman, maintainer, chose a stopgap:

Source: https://github.com/tokio-rs/tracing/issues/1655#issuecomment-947942093
> For now, though, we should probably just add an expect so that the panic message is more friendly, as a stopgap while we experiment with actual solutions for this. :)

- *No way to remove the global default* is still requested: `byte-sourcerer` (user, NONE), #2513 (2023), open:

Source: https://github.com/tokio-rs/tracing/issues/2513
> Some [use case](https://github.com/tokio-rs/tracing/discussions/1626) requires the ability to remove the global default subscriber.

- *Scoped defaults with permanent global side effects.* `bdonlan` (CONTRIBUTOR) reported on #1102 (open) that `with_default` permanently sets the `EXISTS` flag, which turns off `tracing`'s fallback to `log` for the whole process, so tests using scoped subscribers broke other tests:

Source: https://github.com/tokio-rs/tracing/issues/1102#issuecomment-727073999
> Some of its tests tested this, but were broken when other tests (which uses scoped subscribers) ran first.

`tracing-subscriber`'s scoped `set_default` installs the global `log` logger (#2228, open, user report), so a later `init` panics. Open pull request #3637 (`knowrohit`, NONE) proposes removing that call:

Source: https://github.com/tokio-rs/tracing/pull/3637
> Remove the `LogTracer::init()` call from the scoped `set_default` so it no longer
> has this irreversible global side effect.

- *Comparables that chose otherwise.* `log` keeps a single global logger and no scoped override: what prototype #30 departed from and what #1152 copied for the global. `slog` passes a `Logger` explicitly; a user names it as the contrast:

Source: https://github.com/tokio-rs/tracing/issues/383#issuecomment-542373757
> Ah, I'm coming from slog with explicit `Logger` passing where there's no special effort needed.

`slog`'s own stated reasons were not researched.

**Unverified**

- Eliza Weisman's talks and posts other than the 2019 Tokio blog post were not searched; a further stated why may exist there.
- Whether any maintainer has commented on #2874, #3611, #3614 or #3530: the saved threads (read 2026-11-24) contain comments only from users and contributors.
- Hayden Stainsby's role: GitHub marks him `CONTRIBUTOR` on #3530; whether he is a maintainer or release manager was not confirmed from a primary source.
- The Tokio Gitter `#dev` design discussion that Eliza Weisman, on #1152, says had recently taken place: not fetched.
- Carl Lerche's role beyond GitHub's `author_association`.
- The breadth of the issue-tracker survey: three title searches (`repo:tokio-rs/tracing DefaultGuard`, 14 results; `set_global_default in:title`, 4; `"global default" in:title`, 12), of which the cited issues were read. Body-text searches (for example `with_default` and tests) and GitHub Discussions (such as discussion 1626, cited by #2513) were not surveyed.

#### Leads that did not hold (`tracing`)

- **"A scoped override for tests"** behaves otherwise: the scoped default is not a test hook added to a global facade. The prototype's `log`-style global was removed in 2018 (prototype #30), `tokio-trace` entered Tokio with only a thread-local default (#827, February 2019), and a global was added back as a fallback (#1152, June 2019). It is thread-local, so it does not cover threads a test spawns or runtime workers unless carried per future with `WithSubscriber`.
- **"Interest-cache bugs with many dispatchers"** behaves otherwise: the open bugs at 0.1.36 (#2874, #3611) happen when exactly one `Dispatch` is registered (`Rebuilder::JustOne`), and a second live dispatcher masks them (#3611 body). With many dispatchers the documented cost is weaker caching (`sometimes`), not wrong results (#927).
- **The callsite docs' claim that dropping a subscriber re-evaluates the interest cache** does not hold in the 0.1.36 source: only `Dispatch::new` and `rebuild_interest_cache()` rebuild it (grep above, and #3530).
- **`Instrument`** as a way to carry the subscriber across `.await`: it carries a span. The subscriber equivalent is `WithSubscriber` (`with_subscriber`, `with_current_subscriber`).
- **The Tokio blog post (2019) as a source for the why**: it exists ("Diagnostics with Tracing", signed Eliza Weisman) but states no reason for a global or a scoped default. The stated why is in prototype #30, tokio #1152 and tracing #383.
- **"Facade pattern" as `tracing`'s own description**: `tracing` uses "facade" only for `log` (grep above).
- **A guard that is `!Send`**, implied by the question: the guard is `Send` at 0.1.36 and on `master`; the `!Send` change (#2488) is an open pull request, and the docs carry no warning.
- **"Can the global be ended or replaced"**: there is no API for either (docs.rs item index above), and the subscriber is leaked.

### A3. `metrics` (metrics-rs/metrics) (0.24.6)

The Rust `metrics` crate, read as one of the three facades in the claim that Transect's shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests". Pinned at 0.24.6, the current crates.io release (published 2026-05-13; 0.24.4 and 0.24.5 are yanked; tag `metrics-v0.24.6`, commit `23cc597488f119a2d54b0ffd4a0d7d1a50651b76`); the helper crate `metrics-util` is cited once at 0.20.4 (tag `metrics-util-v0.20.4`). Read 2026-11-24. The maintainer throughout is Toby Lawrence (GitHub `tobz`), who calls himself "essentially the only contributor when it comes to design and direction" (quoted under Constraints).

**The claim, part by part**

1. Global entry point: holds. Macros reach the recorder through an implicit process-wide `static`; the application hands its recorder over once and never passes it to call sites. Qualifications: a thread-local override is consulted first, and a stored metric handle stays bound to the recorder current when it was registered.
2. Backend installed at the top level: holds by convention, strictly one-shot. A second `set_global_recorder` returns an error that hands the recorder back; the installed recorder is leaked and never replaced or dropped. Metrics recorded with neither a global nor a thread-local recorder set go to the no-op recorder and are lost, and a handle obtained then stays a no-op for good; under a local recorder set before the global one, metrics go to that local recorder.
3. Scoped override for tests: holds, with limits. A closure form (0.22.0) and a `!Send` guard form (0.24.0), both thread-local: neither reaches other threads or redirects an existing handle. The authors state two purposes: tests, and recorders that are not thread-safe.

The separate question of failure posture: the facade promises nothing about a call failing, panicking or blocking; those belong to the recorder. Its only promise is the cost of the no-op path.

**What it does**

*Global entry point.* `recorder/mod.rs` keeps one process-wide global cell (`static GLOBAL_RECORDER: RecorderOnceCell`), a no-op fallback (`static NOOP_RECORDER`) and a thread-local slot (`LOCAL_RECORDER`, a `Cell<Option<NonNull<dyn Recorder>>>` in `thread_local!`).

Every registration macro (`counter!`, `gauge!`, `histogram!`) ends in the free function `with_recorder`, with no recorder argument from the caller:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/macros.rs
>         $crate::with_recorder(|recorder| recorder.$register(&metric_key, metadata))

`with_recorder` picks the recorder in a fixed order:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// If a local recorder has been set, it will be used. Otherwise, the global recorder will be used.  If neither a local
> /// recorder or global recorder have been set, a no-op recorder will be used.

The global is a static every part of the program shares, dependencies included:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! The global recorder is the recorder that the macros use by default. It is stored in a static variable accessible by
> //! all portions of the compiled application, including dependencies. This is what allows us to provide the same
> //! "initialize once, benefit everywhere" behavior that users are familiar with from other telemetry crates like
> //! `tracing` and `log`.

Libraries declare nothing against an object: they only call the macros.

*Backend installed at the top level.* At 0.24.6 the only install function is `set_global_recorder`:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// This function may only be called once in the lifetime of a program. Any metrics recorded before this method is
> /// called will be completely ignored.

A second call does not overwrite the first. The cell's compare-and-swap fails and the rejected recorder comes back inside the error (`SetRecorderError<R>`, with `into_inner`):

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/cell.rs
>             _ => Err(SetRecorderError(recorder)),

A successful install leaks the recorder, so it is never dropped:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/cell.rs
>                     self.recorder.get().write(Some(Box::leak(Box::new(recorder))));

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! Only one global recorder can be installed in the lifetime of the process. If a global recorder has already been
> //! installed, it cannot be replaced: this is due to the fact that once installed, the recorder is "leaked" so that a
> //! static reference can be obtained to it and used by subsequent calls to the emission macros, and any downstream
> //! crates.

No way exists to end or replace the global. The item index (`https://docs.rs/metrics/0.24.6/metrics/all.html`) lists exactly four functions: `set_default_local_recorder`, `set_global_recorder`, `with_local_recorder`, `with_recorder`. `RecorderOnceCell` (`recorder/cell.rs`) has only `new`, `set` and `try_load`, with no clear or take. An unsafe `clear_recorder` existed until 0.21.1 and was removed in 0.22.0: a grep of `lib.rs`, `recorder/mod.rs` and `recorder/cell.rs` at `metrics-v0.22.0`, and of `metrics/src` at `metrics-v0.24.6`, finds no `clear_recorder`, `set_recorder` or `set_boxed_recorder`.

Metrics emitted before install, with no local recorder set, go to the no-op recorder and are lost:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! Initialization of the global recorder isn't required for macros to function, but any metrics emitted before a global
> //! recorder is installed will not be recorded, so initialization and installation of an exporter should happen as early
> //! as possible in the application lifecycle.

*A handle obtained with no recorder set, global or local, stays a no-op permanently.* The no-op recorder's `register_counter` returns `Counter::noop()`, an empty handle (`Self { inner: None }`, `noop.rs` and `handles.rs`). Every handle operation checks only its own `inner` and never looks the recorder up again:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/handles.rs
>     pub fn increment(&self, value: u64) {
>         if let Some(c) = &self.inner {
>             c.increment(value)
>         }
>     }

`inner` is private (`inner: Option<Arc<dyn CounterFn + Send + Sync>>`). A grep of `handles.rs` at the tag finds no `&mut self` and no `inner =`; `inner` is set only in `noop`, `from_arc` and the `From<Arc<T>>` impls. So a `Counter` obtained before install stays empty after a recorder is installed. A fresh macro call after install (`counter!("x").increment(1)`) does record, because each macro call registers again through `with_recorder`. The docs state the same binding rule for the local override:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// This function is suitable for capturing metrics in asynchronous code, particularly when using a single-threaded
> /// runtime. Any metrics registered prior to the returned guard will remain attached to the recorder that was present at
> /// the time of registration, so this cannot be used to intercept existing metrics.

*Who installs.* The crate docs assign installation to executables ("Executables, which themselves can emit their own metrics, are intended to install a global recorder", `lib.rs`), and `set_global_recorder` says the exporter's own initializer normally calls it ("Metrics implementations should provide an initialization method that installs the recorder internally"). Since 0.24.0 the recorder must be `Sync` (`R: Recorder + Sync + 'static`).

*Scoped override.* The closure form:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// This only applies as long as the closure is running, and on the thread where `with_local_recorder` is called. This
> /// does not extend to other threads, and so is not suitable for capturing metrics in asynchronous code where multiple
> /// threads are involved.

The guard form is `set_default_local_recorder(recorder: &dyn Recorder) -> LocalRecorderGuard<'_>`, `#[must_use]`. It nests and restores the previous recorder on drop, provided guards are dropped innermost first: `Drop` writes back the recorder it replaced without checking that it is the innermost guard, so dropping an outer guard first replaces the active inner recorder, and the inner guard's later drop restores the outer one, even if that recorder has since been dropped (read from source, not run). The saved `prev_recorder` is a bare `Option<NonNull<dyn Recorder>>`; the guard's `PhantomData<&'a dyn Recorder>` bounds only its own recorder:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// Additionally, local recorders can be used in a nested fashion. When setting a new default local recorder, the
> /// previous default local recorder will be captured if one was set, and will be restored when the returned guard drops.

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> impl<'a> Drop for LocalRecorderGuard<'a> {
>     fn drop(&mut self) {
>         // Clear the thread-local recorder.
>         LOCAL_RECORDER.with(|local_recorder| local_recorder.replace(self.prev_recorder.take()));
>     }
> }

Matei David (`mateiidavid`, `CONTRIBUTOR`), the guard's contributor, not a maintainer, raised this in PR #523 after the maintainer's review and before the merge:

Source: https://github.com/metrics-rs/metrics/pull/523#issuecomment-2389078754
> There is also a bit of an issue with the current implementation, for example, suppose you have something like this:

His example drops the outer guard, then the outer recorder, then the inner guard, whose drop "will now restore the previous recorder (in this case `root_recorder`)"; the test is named `it_will_segfault`. No reply on the thread addresses it: the later issue comments are about signing and release, the inline review comments about naming, a SAFETY comment and doc wording, and of the eight review bodies all but one are empty.

The closure form is built on the same guard, which clears the slot even when the closure unwinds:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// closure. However, we must store this reference in a static variable (thread-local storage) so that it can be
> /// accessed by the macros. This guard ensures that the pointer we store to the reference is cleared when the guard is
> /// dropped, so that it can't be used after the closure has finished, even if the closure panics and unwinds the stack.

The guard is neither `Send` nor `Sync` (rustdoc's auto-trait listing):

Source: https://docs.rs/metrics/0.24.6/metrics/struct.LocalRecorderGuard.html
> impl<'a> !Send for LocalRecorderGuard<'a>

On threads and `.await`: the docs speak only of threads and runtimes. `with_local_recorder` is "not suitable for capturing metrics in asynchronous code where multiple threads are involved"; `set_default_local_recorder` is "suitable for capturing metrics in asynchronous code that uses a single threaded runtime". Neither mentions `.await` (a grep of `metrics/src` for `await` finds nothing), and neither says what happens when a task holding the guard moves between worker threads.

When the override was added: the closure in 0.22.0 (2023-12-24, PR #414), the guard in 0.24.0 (2024-10-12, PR #523, closing issue #502). The 0.22.0 changelog lists "Support for local recorders" (#414). The 0.24.0 changelog does not list `set_default_local_recorder`; its only local-recorder line is "Updated the documentation for `with_local_recorder` to better explain limitations." The guard's release in 0.24.0 rests on the maintainer's comment on #523 ("Released as part of `metrics@v0.24.0`.", comment 2408650482) and on the function appearing in `recorder/mod.rs` at `metrics-v0.24.0` and not at `metrics-v0.23.0`.

*Failure posture of the facade.* Handle methods return `()`. `Recorder`'s methods return handles or `()`, never a `Result`, and the handle forwards straight to the recorder's `CounterFn`, `GaugeFn` or `HistogramFn`. The only fallible facade call is `set_global_recorder`. The one quantitative promise covers the no-op path:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! In cases where no global recorder is installed, a "noop" recorder lives in its place, which has an incredibly
> //! low overhead: an atomic load and comparison.  Libraries can safely instrument their code without fear of ruining
> //! baseline performance.

A case-insensitive grep of `metrics/src` for `panic|block|fail|error|overhead` finds only the no-op overhead sentence, one guard comment about unwinding, one internal `panic!` for a `usize::MAX` capacity in `cow.rs`, the `Level::ERROR` constants, and test code. None of the docs on `Recorder`, `CounterFn`, `GaugeFn` or `HistogramFn` says whether a call may panic, block or fail. The crate's own test recorder implements `absolute` as `unimplemented!()`, so the trait accepts a recorder that panics. Failing, panicking and blocking are the recorder's behaviour, passed straight to the caller.

**The stated why**

*For a global facade.* The design began as a user's proposal to copy `log`. kazimuth, a user, issue #18 (2019):

Source: https://github.com/metrics-rs/metrics/issues/18
> The design I was contemplating is something like [`log`](https://github.com/rust-lang-nursery/log), where there's a tiny facade crate with simple macros that library authors can use freely, that calls into a global trait object for functionality; binaries can then install an implementation that does what they want.

Toby Lawrence, maintainer, replying in issue #18:

Source: https://github.com/metrics-rs/metrics/issues/18#issuecomment-496942451
> I love the idea of providing a path for "simplest possible metrics configuration" based on macros and a global receiver.

Toby Lawrence, maintainer, PR #20, which introduced the facade (2019):

Source: https://github.com/metrics-rs/metrics/pull/20
> There's a global recorder instance that can be overridden at runtime, and is used as the recorded/sink for all macro-based calls.

Toby Lawrence, maintainer, issue #338, "Meta issue: roadmap to 1.0." (2022):

Source: https://github.com/metrics-rs/metrics/issues/338
> My intent was always to match the ubiquity and simplicity of crates like `log` and `tracing`: the usage side where the macros live have simple, approachable interfaces. The hard work is pushed to the underlying implementations.

Toby Lawrence, maintainer, issue #271:

Source: https://github.com/metrics-rs/metrics/issues/271#issuecomment-1039246350
> This is an explicit goal of `metrics`: just like `tracing`, an application can get metrics from its dependencies for "free", just by installing a recorder.

The crate documentation (maintainer-authored) on the library side:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! Libraries need only include the `metrics` crate to emit metrics.  When an executable installs a recorder, all
> //! included crates which emitting metrics will now emit their metrics to that record, which allows library authors to
> //! seamless emit their own metrics without knowing or caring which exporter implementation is chosen, or even if one is
> //! installed.

*For the install rules (once, no replacement, leaked, error returns the recorder).* The leak and the ban on replacement both come from the need for a `'static` reference (`lib.rs`, quoted under What it does). Toby Lawrence, maintainer, PR #414:

Source: https://github.com/metrics-rs/metrics/pull/414
> Installation of the global recorder is meant to happen once during the life of a process.

Toby Lawrence, maintainer, issue #437, on why `set_global_recorder` takes ownership, and where the earlier `&'static` install came from:

Source: https://github.com/metrics-rs/metrics/issues/437#issuecomment-1890825415
> As part of fixing #409, we now take ownership of the recorder so that if another global recorder is already set, we can return the recorder we were given instead of leaking it.

Source: https://github.com/metrics-rs/metrics/issues/437#issuecomment-1890825415
> It was really just a holdover from the initial skeleton of `metrics` being based on the `log` crate, which did/does the same thing.

Toby Lawrence, maintainer, PR #414, on dropping the `&'static` form:

Source: https://github.com/metrics-rs/metrics/pull/414
> The functions have been changed to be slightly more ergonomic (handle boxing the value for callers) but to also remove the illusion that `metrics` is designed to work well in `no_std` environments, which is generally the only reason a user would ever install a recorder via a `&'static dyn Recorder` reference.

On the `Sync` bound added in 0.24.0. Dmitry Sviridkin (`Nekrolm`), a user, issue #511:

Source: https://github.com/metrics-rs/metrics/issues/511
> This is not an issue for any sane implementations, but currently the lack of Sync restrictions makes the `set_global_recorder` unsound: it's possible to create data race in safe code

Toby Lawrence, maintainer, agreeing:

Source: https://github.com/metrics-rs/metrics/issues/511#issuecomment-2322990650
> Not sure what my thinking was back then, but it does seem like we might want to require that `Recorder` is `Sync`.

On registering before install. Toby Lawrence, maintainer, issue #69 (2020), which introduced separate registration:

Source: https://github.com/metrics-rs/metrics/issues/69#issuecomment-612550013
> Given that this still requires a recorder to be installed, it means you would have to declare them after the program is running and a recorder is present, so it's not quite a seamless compile-time thing.

Source: https://github.com/metrics-rs/metrics/issues/69#issuecomment-693657933
> I'm satisfied that we have a simple enough approach to registering metrics even if it has the caveat of having to occur after a metrics record has been installed.

*For the local (scoped) override.* Toby Lawrence, maintainer, PR #414 and the release notes; the motivation was the global recorder and the earlier `clear_recorder` workaround:

Source: https://github.com/metrics-rs/metrics/pull/414
> - it's subject to race conditions since the default Cargo test runner will run unit tests in parallel

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/RELEASES.md
> - it's not thread-safe (the global recorder is, well, global)
> - it requires the recorder be _implemented_ in a thread-safe way

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/RELEASES.md
> Scoped recorders solve this problem by allowing the temporary overriding of what is considered the
> "global" recorder on the current thread.

Toby Lawrence, maintainer, PR #414, on the model and on why it is thread-local:

Source: https://github.com/metrics-rs/metrics/pull/414
> This is modeled after `tracing`, where a free function takes a reference to the dispatcher to temporarily set as the default, and a closure to run where only that overridden  default dispatcher applies.

Source: https://github.com/metrics-rs/metrics/pull/414
> It works on a thread-local basis so one instance of using a local recorder never conflicts with another.

The same PR names a second purpose besides tests: recorders that need not be thread-safe, using `RefCell` and avoiding locks and atomics. The crate docs name tests as one case among others:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs
> //! In many scenarios, such as in unit tests, you may wish to temporarily set a recorder to influence all calls to the
> //! emission macros within a specific section of code, without influencing other areas of the code, or being limited by
> //! the constraints of only one global recorder being allowed.

*Guard or closure.* The closure came first, modelled on `tracing`'s `with_default` (PR #414, above). The guard was added because the closure does not fit async tests (in issue #502 asmello, a user, adds that async closures are not stable, so the test would have to spawn a tokio runtime inside the closure). asmello, issue #502:

Source: https://github.com/metrics-rs/metrics/issues/502
> `with_local_recorder` requires the logic to be inside a closure, which isn't always feasible.

Toby Lawrence, maintainer, replying:

Source: https://github.com/metrics-rs/metrics/issues/502#issuecomment-2271669326
> Yeah, using the local recorder with async code is indeed painful.

Source: https://github.com/metrics-rs/metrics/issues/502#issuecomment-2271669326
> I'd definitely be willing to accept a PR implementing something like `tracing::set_default`.

Matei David, the contributor who wrote the guard (not a maintainer), gave the same reason in PR #523: the closure does not support async execution, notably on single-threaded runtimes, unless the closure itself spawns a runtime.

Toby Lawrence, maintainer, reviewing #523, on why the guard saves and restores the previous recorder:

Source: https://github.com/metrics-rs/metrics/pull/523#issuecomment-2386952189
> What needs to happen is that we need to store the _current_ local recorder in the guard, so that when it drops, it can be reset.

Matei David, the guard's contributor (not a maintainer), presented it as additive and rejected an `Arc`-based alternative because it would break `with_local_recorder`:

Source: https://github.com/metrics-rs/metrics/pull/523
> The change does not introduce any breaking changes to the existing API.

Source: https://github.com/metrics-rs/metrics/pull/523#issuecomment-2389078754
> 2. Use Arc / RefCell, but this unfortunately would break backwards compatibility since `with_local_recorder` takes a trait object.

No maintainer states why both forms are kept (see No stated rationale found).

**Inferred**

- Inferred: the guard is `!Send` because it holds a `NonNull<dyn Recorder>` (the previous recorder) and a `PhantomData<&'a dyn Recorder>`, and its `Drop` writes that pointer back into the *current* thread's `LOCAL_RECORDER`; dropped on another thread, it would restore the wrong thread's slot. No author states this, and the `!Send` comes from the fields, not an explicit `impl !Send`.
- Inferred from source: a handle registered while a local recorder is active keeps the `Arc` it was given, and goes on updating that recorder's storage after the guard is dropped and on any thread it is moved to. The handle carries the binding, not the thread-local slot.
- Inferred from source: because every macro call registers afresh through `with_recorder`, the cost that a handle bound before install stays a no-op bites only code that stores a handle (in a struct or a `static`, for example). Code that calls `counter!(...)` inline each time records as soon as a recorder is installed.

**No stated rationale found**

- Why the guard is `!Send`: looked in the `LocalRecorderGuard` and `set_default_local_recorder` docs at the tag, and in the body and all issue comments of #523 and #502; none discusses `Send`.
- Why both the closure and the guard are kept, beyond the contributor's compatibility reason at introduction (above): looked in #523 and #502 (bodies and comments), the 0.24.0 CHANGELOG entry and `RELEASES.md` at the tag, which has no 0.24.0 narrative entry on local recorders.

A why was found for everything else asked.

**Constraints**

- Deployment model: a library crate linked into the process; libraries call the macros and one executable installs one recorder. The global is per crate version: two semver-incompatible `metrics` versions in one build each have their own global. Toby Lawrence, maintainer, issue #551:

Source: https://github.com/metrics-rs/metrics/issues/551#issuecomment-2610637888
> a mismatch in the minor version (i.e. using `metrics@0.24.x` while using, say, `metrics-exporter-prometheus@v0.15.x` which depends on `metrics@v0.23.x`) of the `metrics` crate can lead to installing exporters in a way where they aren't used when actually calling `counter!`, etc.

- Guarantees promised: the no-op fallback costs "an atomic load and comparison". Install is once per process. A failed install returns the recorder. The local override is thread-local and restores the previous one on drop, including on unwind, when guards drop in reverse order; out-of-order drops are not handled. Nothing is promised about the cost, fallibility, panics or blocking of a call into an installed recorder.
- Failure model: emission is infallible by signature. A recorder's panic propagates to the caller; nothing in the facade catches it. An example of a backend panicking at install is issue #122, "PrometheusBuilder::install panics without a thread-local runtime", reported by str4d, a user:

Source: https://github.com/metrics-rs/metrics/issues/122
> The problem with this is that `Server::try_bind` eventually calls `tokio::net::tcp::TcpListener::from_std`, which panics if thread-local runtime is not set:

- History:
  - 2019, issue #18 and PR #20: a `log`-style facade with a global recorder and an `install` that mirrors `env_logger`.
  - Up to 0.21.1: `set_recorder(&'static dyn Recorder)` and `set_boxed_recorder(Box<dyn Recorder>)` installed the recorder; an unsafe `clear_recorder` existed for tests (0.19.0, PR #302 by Noratrieb, a contributor, marked it unsafe and documented its unsoundness). The 0.21.1 source documents the leak `clear_recorder` caused:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.21.1/metrics/src/recorder.rs
> /// This will leak the currently installed recorder, as we cannot safely drop it due to it being
> /// provided via a reference with a `'static` lifetime.

  - 0.18.0 (PR #240) moved from operations on the global recorder to handles returned by registration, which is what lets a handle outlive the recorder lookup.
  - 0.22.0 (PR #414): added `with_local_recorder`; replaced both install functions with `set_global_recorder`, which takes ownership; removed `clear_recorder`; returned the recorder on a failed install (issue #409).
  - 0.24.0: added the `Sync` bound (issue #511, PR #513); added `set_default_local_recorder` (issue #502, PR #523); documented `with_local_recorder`'s thread limit (commit `a2707323dad3`).
  - 0.24.2 changed only the guard's internal lifetime cast (PR #564).
- Governance. Toby Lawrence, maintainer, issue #437:

Source: https://github.com/metrics-rs/metrics/issues/437#issuecomment-1890943379
> Both of these statements underline the reality of the crate: I'm essentially the only contributor when it comes to design and direction.

**Costs and dissent**

- Testing against a global was painful before 0.22. david-perez, a user, issue #389:

Source: https://github.com/metrics-rs/metrics/issues/389
> I'm testing a `Recorder` implementation and getting cross-test contamination because the recorder is shared across all threads and registered globally.

- A leaked recorder cannot flush at exit. jorendorff, a user, issue #308:

Source: https://github.com/metrics-rs/metrics/issues/308
> We have a panic hook that does `metrics::increment_counter!("panic");`. But we've found that this increment often doesn't make it to the server.

Toby Lawrence, maintainer, replying:

Source: https://github.com/metrics-rs/metrics/issues/308#issuecomment-1167741633
> At a high level, there is no way, currently, to drop the recorder as it's installed in such a way that callers can take a `'static` reference to it, which means that installing a recorder requires either a `&'static dyn Recorder` or an owned `R: Recorder` which we box and then leak, in order to fulfill the `'static` requirement.

The workaround lives outside the facade, in `metrics-util`'s `RecoverableRecorder` (PR #362), which installs a weak reference and keeps the strong one in a drop guard:

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/recoverable.rs
> /// `RecoverableRecorder` allows wrapping a recorder such that a weak reference to it is installed
> /// globally, while the recorder itself is held by `RecoveryHandle<R>`. This allows the recorder to
> /// be used globally so long as the recovery handle is active, keeping the original recorder alive.

- Taking ownership at install was a breaking change that drew complaint. `bmorin`, a user and exporter author (`metrics-cloudwatch-embedded`), issue #437:

Source: https://github.com/metrics-rs/metrics/issues/437
> Is there a reason `metrics` needs to take ownership of the `Recorder` object instead of receiving an interface that's threadsafe and `'static`?

- The closure override does not fit async code, the reason for the guard (issue #502, above). Even the guard covers only one thread: the docs limit it to a single-threaded runtime, and the closure is "not suitable" where multiple threads are involved.
- Handles bound before install. The maintainer acknowledged that registration must follow install (issue #69, above). No issue was found complaining specifically about a stored handle staying a no-op after a later install: tracker searches (`repo:metrics-rs/metrics` with each of "handle before recorder", "recorder installed after handle", "registered before installed", "static Counter noop", "noop counter", "install order", "before recorder installed") returned none. A planned search, "metrics not recorded", failed on the API rate limit and was not rerun.
- Multiple globals across versions (issue #551, above). Toby Lawrence, maintainer, issue #503, calls it a footgun to be removed at 1.0:

Source: https://github.com/metrics-rs/metrics/issues/503#issuecomment-2297045736
> At 1.0, this footgun goes away completely.

- A reversal inside the project. Before 0.18 the project had moved storage out of an object users held (`metrics-runtime`'s `Sink`) into the opaque facade; 0.18 went back to handles:

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/RELEASES.md
> With this update, we've switched back to a handle-based model that also works seamlessly with the
> macros.

- Comparables that chose otherwise (`log`, `tracing`, OpenTelemetry) are surveyed in their own sections and not repeated here.
- Chose otherwise on one of two unset paths: `metrique` 0.1.34 (awslabs), a Rust metrics library whose `ServiceMetrics` global sink panics if `sink` is called before a destination is attached:

Source: https://docs.rs/metrique/0.1.34/metrique/
> by using the sink method (you must attach a destination before calling sink, otherwise you will encounter
> a panic!).

The same release also offers `sink_or_discard()`, which never panics. It discards an entry appended while no sink is attached, and forwards entries once one is attached. Its docs give a reason, and the test `sink_or_discard_discards_then_forwards` checks that one handle does both:

Source: https://github.com/awslabs/metrique/blob/metrique-v0.1.34/metrique-writer-core/src/global.rs
>                 /// checks whether a sink is attached at *that* point. If a sink is
>                 /// available, the entry is forwarded to it; otherwise the entry is
>                 /// silently discarded.

Source: https://github.com/awslabs/metrique/blob/metrique-v0.1.34/metrique-writer-core/src/global.rs
>                 /// This is particularly useful for **libraries** that want to emit metrics
>                 /// when available but don't control when (or whether) the host application
>                 /// attaches a sink.

No stated rationale found for the panic: the crate root docs at 0.1.34 mention "panic" only in this sentence, and the `_guide::sinks` page at 0.1.34 not at all; the issue tracker was not searched.

The same workspace has an opt-in route for startup that leaves this rule in place: `metrique-util`'s `pending_sink` (feature `pending-sink`, not on by default), released with 0.1.25 on 2026-04-20 (PR #275; CHANGELOG at `metrique-v0.1.34`). The application attaches the pending sink as the destination at once and resolves it with the real sink later. Meanwhile entries are buffered up to a bound, the oldest dropped when full, and if the resolver is dropped unresolved the sink becomes a no-op and the buffer is discarded. Its author, jlizen (`CONTRIBUTOR`), PR #275:

Source: https://github.com/awslabs/metrique/pull/275
> This lets applications start emitting metrics immediately during startup, even when the underlying sink requires async initialization (credential exchange, network handshakes, etc.).

Source: https://github.com/awslabs/metrique/blob/metrique-v0.1.34/metrique-util/src/pending_sink.rs
> /// Call [`resolve`](PendingSinkResolver::resolve) to drain buffered entries into the
> /// real sink and switch to direct forwarding. If this handle is dropped without
> /// calling `resolve`, the pending sink becomes a no-op and buffered entries are
> /// discarded.

Only this sentence, the `sink_or_discard` docs in `metrique-writer-core/src/global.rs` and the pending sink were read; the crate is not otherwise surveyed.

**Unverified**

- How any particular exporter (for example `metrics-exporter-prometheus`) behaves on panic or blocking; exporters were not surveyed. The only exporter evidence is issue #122, which concerns install, not emission.
- Whether a `LocalRecorderGuard` held across `.await` on a multi-threaded runtime could be dropped on another thread. The type is `!Send`, so a future holding it is `!Send` and the compiler rejects a spawn that needs `Send`; no test was compiled and no source states the outcome.
- The review comments on PR #414 (`pulls/414/comments`, `pulls/414/reviews`); only the body and issue-thread comments were read.
- Exhaustiveness of the dissent search, cut short by the GitHub search API rate limit (see Costs and dissent).
- Whether the out-of-order drop in PR #523's `it_will_segfault` example crashes at 0.24.6. The destructor it relies on is unchanged at the tag (read from source); the example was not compiled or run.

#### Leads that did not hold (`metrics`)

- `set_recorder` and `set_boxed_recorder` exist only up to 0.21.1. PR #414 replaced both with `set_global_recorder` in 0.22.0; they are absent from `https://docs.rs/metrics/0.24.6/metrics/all.html` and from a grep of `metrics/src` at `metrics-v0.22.0` and `metrics-v0.24.6`.
- `set_default_local_recorder` was not released with the local recorder support of 0.22.0. It arrived in 0.24.0 (PR #523), and the 0.24.0 CHANGELOG does not list it.
- "Scoped override for tests" understates the authors' purpose. PR #414 and the 0.22.0 release notes also present the local recorder as a way to run recorders that are not thread-safe; the crate docs give unit tests as one example ("In many scenarios, such as in unit tests").
- `with_local_recorder`'s own summary line says it sets the recorder "as the global recorder for the duration", but it is thread-local, as its next paragraph and the source show. The wording is the crate's, not a behaviour difference.
- PR #20 (2019) described the global recorder as one that "can be overridden at runtime". That no longer holds at 0.24.6: the global can be set once and never replaced; only the thread-local override exists.

### A4. OpenTelemetry Rust (`opentelemetry::global` and the `opentelemetry_sdk` providers) (`opentelemetry` 0.33.1, `opentelemetry_sdk` 0.33.1)

The OpenTelemetry API and SDK crates for Rust, tested against the claim that Transect's shape is "the facade pattern of the log, tracing and metrics crates: a global entry point, a backend installed at the top level, and a scoped override for tests". Pinned: `opentelemetry` 0.33.1 and `opentelemetry_sdk` 0.33.1 (current releases, both published 2026-10-09; tags `opentelemetry-0.33.1` and `opentelemetry_sdk-0.33.1` both peel to commit `372ebbc74d4dba71bb9820732f57f7316b4e7a1e`, to which every link is pinned unless it names another ref; `opentelemetry-otlp` there is also 0.33.1). Specification v1.63.0. Read 2026-11-24.

**The claim, part by part**

1. *A global entry point: holds, but optional.* `global` holds a process-wide tracer and meter provider, yet the SDK provider is an ordinary value the application builds and owns; the SDK's own getting-started example never uses the global, and logs have no global at all (removed in 0.23; a re-add refused in 2026, #3346).
2. *A backend installed at the top level: holds, by convention.* `set_tracer_provider` and `set_meter_provider` say "Libraries should NOT call this function. It is intended for applications/executables." Separately, they can be called any number of times (last call wins, unless the slot's lock is poisoned; `set_tracer_provider` has returned nothing since 0.31, and `set_meter_provider` already returned nothing at 0.30.0), and installing does not hand over the lifecycle: the application keeps the provider to shut it down, and the clone in the global is never dropped while it is the current one; replacing it drops the old clone inside `set_*`, under the write lock, which shuts that provider down if it was the last clone.
3. *A scoped override for tests: does not hold at 0.33.1.* No public item scopes a provider. A guard that restored the previous provider existed up to v0.12 and was removed in 0.13 (#444). Tests build their own providers with in-memory exporters.

**What it does**

*1. Global entry point: yes, but optional; the provider is an object the application builds.* The `global` module holds a process-wide tracer provider and meter provider (and a text-map propagator), each a lazily initialised static holding a no-op provider until replaced:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
> /// The global `Tracer` provider singleton.
> static GLOBAL_TRACER_PROVIDER: OnceLock<RwLock<GlobalTracerProvider>> = OnceLock::new();

The metrics one is the same shape, a `RwLock` around `Arc<dyn MeterProvider + Send + Sync>` initialised to `NoopMeterProvider` (`static GLOBAL_METER_PROVIDER: OnceLock<RwLock<GlobalMeterProvider>>` in `global/metrics.rs`). The entry points are `global::tracer`, `tracer_with_scope`, `tracer_provider`, `meter`, `meter_with_scope` and `meter_provider`. The module states its purpose:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/mod.rs
> //! The global trace API **provides applications access to their configured
> //! [`TracerProvider`] instance from anywhere in the codebase**. This allows
> //! applications to be less coupled to the specific Open Telemetry SDK while not
> //! manually passing references to each part of the code that needs to create
> //! [`Span`]s.

The SDK provider is an ordinary value built with `SdkTracerProvider::builder()` or `SdkMeterProvider::builder()`, whose `build` is infallible; the global is a place to put a clone:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
> /// The `TracerProvider` is designed to be clonable. Cloning a `TracerProvider`  creates a
> /// new reference to the same provider, not a new instance.

The SDK's crate-level "Getting Started" example builds a provider, takes a tracer from it directly and shuts it down, never touching the global:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/lib.rs
> //!     let tracer = provider.tracer("readme_example");

The metrics guidance tells applications to keep the provider and set a clone globally, and to obtain meters from the global:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/metrics.md
> * **Set as Global Provider**: Use `opentelemetry::global::set_meter_provider` to
>   set a clone of the `MeterProvider` as the global provider. This ensures
>   consistent usage across the application, allowing applications and libraries
>   to obtain `Meter` from the global instance.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/metrics.md
> For most applications, a `Meter` should be obtained
> from `global` and saved for re-use.

So the docs recommend both: hold the provider explicitly (for shutdown) and publish a clone globally (for discovery by libraries). There is no global for logs: removed in 0.23 (see Constraints).

*2. Backend installed at the top level: yes; replaceable any number of times; not endable through the global.* `set_tracer_provider` and `set_meter_provider` take the provider by value, overwrite the slot under the write lock (`**provider = GlobalTracerProvider::new(new_provider);`) and return `()`; the last call wins:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
> /// Libraries should NOT call this function. It is intended for applications/executables.

The exception is a poisoned lock: the setter then logs an error and leaves the slot as it was (read from source, not run; the meter setter has the same branch):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
>     } else {
>         otel_error!(name: "TracerProvider.GlobalSetFailed", message = "Setting global tracer provider failed. Traces created using global::tracer() or global::tracer_with_scope() will not function. Report this issue in OpenTelemetry repo.");

Until 0.31 `set_tracer_provider` returned the replaced provider:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/CHANGELOG.md
> - *Breaking* Change return type of `opentelemetry::global::set_tracer_provider` to Unit to align with metrics counterpart

At 0.30.0 the two setters already differed: the tracer setter returned the replaced `GlobalTracerProvider`, the meter setter nothing:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry-0.30.0/opentelemetry/src/global/trace.rs
> pub fn set_tracer_provider<P, T, S>(new_provider: P) -> GlobalTracerProvider

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry-0.30.0/opentelemetry/src/global/metrics.rs
> pub fn set_meter_provider<P>(new_provider: P)

The global cannot be shut down: `global::shutdown_tracer_provider()` was removed in 0.28 and `global::shutdown_meter_provider` in 0.22 (changelog: "Remove `global::shutdown_meter_provider`, use `SdkMeterProvider::shutdown` directly instead").

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/migration_0.28.md
> `opentelemetry::global::shutdown_tracer_provider()` is removed. Now, you should
> explicitly call shutdown() on the created tracer provider.

Shutdown is a method on the SDK provider (`shutdown` and `shutdown_with_timeout` on `SdkTracerProvider` and `SdkMeterProvider`). After it the provider hands out no-op tracers:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
> /// Once shut down, the `TracerProvider` transitions into a disabled state. In this state, further
> /// operations on its associated `Tracer` instances will result in no-ops, ensuring that no spans
> /// are processed or exported after shutdown.

A second `shutdown` returns `Err(OTelSdkError::AlreadyShutdown)` for both providers (`provider.rs`, `meter_provider.rs`).

*Tracers and meters obtained before a provider is set stay no-op.* `global::tracer` clones the provider currently in the slot and asks it for a tracer, which is boxed; nothing refers back to the slot afterwards:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
>     fn tracer_with_scope(&self, scope: InstrumentationScope) -> Self::Tracer {
>         BoxedTracer(self.provider.boxed_tracer(scope))
>     }

So a `BoxedTracer` taken while the slot holds `NoopTracerProvider` wraps a `NoopTracer` for its whole life. For meters the documentation says so outright:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/metrics.rs
> /// **NOTE:** This function should be called before getting [`Meter`] instances via [`meter()`] or [`meter_with_scope()`]. Otherwise, you could get no-op [`Meter`] instances.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/metrics.rs
> /// If the global [`MeterProvider`] is changed after getting [`Meter`] instances from these calls, the [`Meter`] instances returned will not reflect the change.

The SDK's own design note hits this for its self-diagnostics and lists it as open work:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/design/observability.md
> The `BatchLogProcessor` obtains a `Meter` from the global `MeterProvider`
> during construction. Rust's `global::meter()` returns a snapshot — it does
> **not** retroactively upgrade if the global provider changes later.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/design/observability.md
> - Long-term: `global::meter()` currently returns a snapshot that does not
>   reflect later calls to `set_meter_provider()`. Investigate whether the
>   global meter can be made to pick up provider changes after the fact.

The same applies on replacement: a tracer or meter taken from provider A keeps using A after `set_*_provider(B)`, and since an `SdkTracer` holds a clone of its provider (`SdkTracer::new(scope, self.clone())` in `provider.rs`), A stays alive while such tracers exist.

*3. Scoped override for tests: none at 0.33.1.* The full docs.rs item index of each crate (both built with `all-features = true`; `https://docs.rs/opentelemetry/0.33.1/opentelemetry/all.html` and `https://docs.rs/opentelemetry_sdk/0.33.1/opentelemetry_sdk/all.html`, saved as `otel-all-0.33.1.html` and `sdk-all-0.33.1.html`) lists the `global` items as exactly `get_text_map_propagator`, `meter`, `meter_provider`, `meter_with_scope`, `set_meter_provider`, `set_text_map_propagator`, `set_tracer_provider`, `tracer`, `tracer_provider`, `tracer_with_scope`, `BoxedSpan`, `BoxedTracer`, `GlobalTracerProvider`, `ObjectSafeSpan`, `ObjectSafeTracer`, `ObjectSafeTracerProvider`. Neither index has a `with_default`, `set_default`, guard type or thread-local provider. The only guard in the API crate is `context::ContextGuard`, which scopes the current `Context` (active span, baggage) to a thread, not the provider; a grep of `opentelemetry/src` for `thread_local` finds it only in `context.rs`.

Tests instead get explicit providers with in-memory exporters (`trace::InMemorySpanExporter`, `metrics::InMemoryMetricExporter`, `logs::InMemoryLogExporter`) and a `testing` module: a test builds its own provider and uses it directly, never the global.

A scoped override existed once: up to v0.12, `set_tracer_provider` returned a `TracerProviderGuard` that restored the previous provider on drop. It was removed in 0.13 by #444 (see Costs and dissent).

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/v0.12.0/opentelemetry/src/global/trace.rs
> /// Restores the previous tracer provider on drop.
> ///
> /// This is commonly used to uninstall pipelines. As you can only have one active tracer provider,
> /// the previous provider is usually the default no-op provider.

*4. Errors and blocking.* The global functions return no `Result`. A poisoned lock is logged through the crate's internal-log macros and the call degrades to a no-op provider:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
>     // Try to get the global tracer provider. If the RwLock is poisoned, we'll log an error and return a NoopTracerProvider.

At v0.12 the trace global panicked on a poisoned lock (`.expect("GLOBAL_TRACER_PROVIDER RwLock poisoned")`); #3078, released in 0.31, removed the remaining crash path:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3078
> In addition failure to set global tracer does not crash program anymore - it will return noop and log error - like with global metrics

The project's error-handling decision record (ADR 001, 27 Feb 2025):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/adr/001_error_handling.md
> Failures during regular operation should not panic, instead returning errors to the caller where appropriate, _or_ logging an error if not appropriate.

A span start runs application-supplied code on the calling thread: the sampler the application configured, then each processor's `on_start`. A grep of `opentelemetry/src` and `opentelemetry-sdk/src` at the pin finds `catch_unwind` only in two tests, so a panic in that code unwinds into the caller (read from source, not run):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/tracer.rs
>         let samplings_result = config.sampler.should_sample(

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
>     pub fn with_sampler(mut self, sampler: impl Into<Box<dyn crate::trace::ShouldSample>>) -> Self {

Set-up and teardown return errors; recording does not. Exporter construction is fallible (e.g. `opentelemetry-otlp`'s `pub fn build(self) -> Result<MetricExporter, ExporterBuildError>` in `src/metric.rs`); provider `build` is not; `shutdown` and `force_flush` return `OTelSdkResult`. Span-processor hooks run on the caller's thread and must not block:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/span_processor.rs
>     /// `on_end` is called after a `Span` is ended (i.e., the end timestamp is
>     /// already set). This method is called synchronously within the `Span::end`
>     /// API, therefore it should not block or throw an exception.

The batch processor drops a span when its queue is full and warns once:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/span_processor.rs
>                         message = "BatchSpanProcessor dropped a Span due to queue full. No further log will be emitted for further drops until Shutdown. During Shutdown time, a log will be emitted with exact count of total spans dropped.");

The simple processor exports on the calling thread, so `Span::end` blocks on the exporter:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/span_processor.rs
> /// Spans are exported synchronously
> /// in the same thread that emits the log record.

Obtaining a tracer or meter through the global takes the slot's `RwLock` for reading, so it waits while `set_tracer_provider` or `set_meter_provider` holds the write lock. Inferred from source, not run: the write lock is held while the replaced provider is dropped, which can run that provider's shutdown.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
>     let global_provider = global_tracer_provider().read();

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/sync/poison/rwlock.rs
>     /// Locks this `RwLock` with shared read access, blocking the current thread
>     /// until it can be acquired.

`force_flush` and `shutdown` block the caller:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
> /// This will block the user thread till all the spans are passed to exporters.

*5. Drop and shutdown.* Dropping the last clone of an SDK provider runs shutdown, which flushes:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
> /// new reference to the same provider, not a new instance. Dropping the last reference
> /// to the `TracerProvider` will automatically trigger its shutdown. During shutdown, the provider
> /// will flush all remaining spans, ensuring they are passed to the configured processors.

The drop path calls `shutdown()`, which is `shutdown_with_timeout(Duration::from_secs(5))`, a fixed five seconds passed to each processor in turn, and discards the result:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
>             let _ = self.shutdown(); // errors are handled within shutdown

The batch span processor waits for its worker's acknowledgement with `recv_timeout(timeout)` and returns `OTelSdkError::Timeout` on expiry. Once the acknowledgement arrives it joins the worker thread with no deadline, so the join also waits for whatever the worker does after acknowledging, including dropping the exporter its closure owns (read from source, not run):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/span_processor.rs
>                 receiver
>                     .recv_timeout(timeout)
>                     .map(|_| {
>                         // join the background thread after receiving back the
>                         // shutdown signal
>                         if let Some(handle) = self.handle.lock().unwrap().take() {
>                             handle.join().unwrap();
>                         }

The meter provider's `shutdown_with_timeout` ignores its argument (`_timeout: Duration`), and the periodic reader's shutdown waits a hard-coded five seconds:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/metrics/periodic_reader.rs
>         // TODO: Make this timeout configurable.
>         match response_rx.recv_timeout(Duration::from_secs(5)) {

A provider set globally is never dropped through the global while it is the current one, because the slot is a `static` (a later `set_*` does drop it, see below), and

Source: https://github.com/rust-lang/reference/blob/b122dbbf524f95f75fd2cc2966fe26bd37aa8b04/src/items/static-items.md
> Static items do not call [`drop`] at the end of the program.

Replacing it does drop it. Each setter assigns into the slot while it holds the write guard, and assignment runs the destructor of the old value, an `Arc` around the old provider. If the global held the last clone of an `SdkTracerProvider`, its inner destructor runs `shutdown` (the drop path quoted above), inside `set_*` and under the write lock. So only the value in the slot when the process exits is never dropped. Before 0.31 `set_tracer_provider` returned the replaced provider; since then it is dropped in place. `set_meter_provider` already assigned in place at 0.30.0. Whether it is the last clone depends on what else holds one: the application, or tracers obtained from it (read from source, not run):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/trace.rs
>     let mut global_provider = global_tracer_provider().write();
>     if let Ok(ref mut provider) = global_provider {
>         **provider = GlobalTracerProvider::new(new_provider);

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/metrics.rs
>         **provider = Arc::new(new_provider);

Source: https://doc.rust-lang.org/1.100.0/reference/destructors.html
> Assignment also runs the destructor of its left-hand operand, if it’s initialized.

The metrics guide states the consequence the other way round:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/metrics.md
> > [!NOTE] If you did not use `opentelemetry::global::set_meter_provider` to set
> > a clone of the `MeterProvider` as the global provider, then you should be
> > aware that dropping the last instance of `MeterProvider` implicitly calls
> > shutdown on the provider.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/metrics.md
> :heavy_check_mark: Always call `shutdown` on the `MeterProvider` at the end of
> your application to ensure proper cleanup.

**The stated why**

*Why a global exists.* The OpenTelemetry specification (v1.63.0, current) asks for one, and in the same section for explicit instances:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/api.md
> Normally, the `TracerProvider` is expected to be accessed from a central place.
> Thus, the API SHOULD provide a way to set/register and access
> a global default `TracerProvider`.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/api.md
> Thus, implementations of `TracerProvider` SHOULD allow creating an arbitrary
> number of `TracerProvider` instances.

The crate's own reason is decoupling ("less coupled to the specific Open Telemetry SDK while not manually passing references", module docs above) and library use:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/src/global/mod.rs
> //! [`Span`]s. Additionally, **3rd party middleware** or **library code** can be
> //! written against this generic API and not constrain users to a specific
> //! implementation choice.

Zhongyang Wu (TommyCpp), maintainer (README at 0.33.1), in #1623, on what the global buys in Rust:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/1623#issuecomment-2002646678
> Yes. App owner should be the one creating providers but the benifit of a global signal provider is app owner doesn't need to manage the lifetime of signal provider until shutdown. Otherwise it can be painful to pass the signal provider along the app due to the ownership model

Zhongyang Wu, then a contributor, in #444, on why one global provider is the common case:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/444
> Also currently we allow the users to use multiple tracer providers throughout the application, which I believe is not a common situation. Most people should have one global tracer provider.

*Why the global has no shutdown, and the application must keep the handle.* Lalit Kumar Bhasin, maintainer (README at 0.33.1), in #1623 and #1961:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/1623#issuecomment-2002767929
> Since these methods are intended exclusively for use by the application owner, they do not have a place in the API. While instrumented libraries can achieve a similar shutdown or reset effect by executing `set_meter_provider(NoopMeterProvider::new());`, the presence of a dedicated method might misleadingly imply that it is designed for use by libraries.

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1961#issuecomment-2248395986
> There shouldn't be any flush/shutdown mechanism exposed at API/global level as per the specs. The application needs to keep hold of the sdk::TracerProvider handle, and use it to invoke shutdown/flush.

Cijo Thomas, maintainer (README at 0.33.1), in #1961, on the model all signals now share:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1961#issuecomment-2494004249
> Once user creates a provider, they hold on to it, so shutdown can be called at the end. -- **this is the key part.**

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1961#issuecomment-2494004249
> If there is a need to set the provider globally (so that other parts of the app or libraries can retrieve it), clone and set it.

The 0.28 migration guide gives the consistency reason for removing `shutdown_tracer_provider`:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/migration_0.28.md
> This now makes shutdown consistent across signals.

*Why exporters no longer install the global.* Cijo Thomas, in #1592:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1592
> 1. It sets global providers, which may not be what user has intended.

*Why there is no global for logs.* The 0.23 changelog (#1691), and Cijo Thomas in #3346 (2026):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry/CHANGELOG.md
>     LoggerProviders are not meant for end users to get loggers from. It is only required for the log bridges.

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3346#issuecomment-3873396074
> Adding a global logger would encourage non-idiomatic usage and expand the API surface we maintain.

*Why the scoped guard was removed.* Julian Tescher, then maintainer (emeritus in the README at 0.33.1), in #427, on what the guard was for:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/427#issuecomment-760478803
> It is currently used as the mechanism to shut down the batch span processor so the current batch is sent before the process exists. This is currently done when the tracer provider is dropped and as it is often registered as a global, the uninstall guard deregisters the global.

The reason for removal is in the issue body (Dan Burkert, contributor, reporting); #444 also names hangs on Tokio's current-thread runtime (G3):

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/427
> When `Uninstall` drops it disables trace collection, which forces callers to use `mem::forget` in instances where global trace collection is enabled in a function other than `main`.

and #444 (Zhongyang Wu) replaced the guard with returning the old provider:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/444
> the function instead of returning the guard, we return the replaced tracer provider. If users need to use multiple tracer providers. They can manage those tracer providers on their own.

*Why API calls do not fail.* Specification v1.63.0:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> 1. API methods MUST NOT throw unhandled exceptions when used incorrectly by end users.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> 2. The API or SDK MAY _fail fast_ and cause the application to fail on initialization, e.g. because of a bad user config or environment, but MUST NOT cause the application to fail later at runtime, e.g. due to dynamic config settings received from the Collector.

*Why shutdown blocks.* Zhongyang Wu, in #868, and the specification's bound:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/868#issuecomment-1250387989
> The reason why it's blocking is by spec when tracer providers shut down it should call[ `shutdown`](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md#shutdown-1) function on all span processors, which will invoke `forceFlush` method to export any remaining spans.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> `Shutdown` SHOULD complete or abort within some timeout. `Shutdown` can be
> implemented as a blocking API or an asynchronous API which notifies the caller
> via a callback or an event.

**Inferred**

- Inferred: tracers and meters taken early stay no-op because the global stores the provider behind a lock and hands out snapshots, not a delegating proxy that re-reads the slot on each call. No author states this as the reason; the observability design note calls it a limitation to investigate, and the source shows the mechanism.
- Inferred: keeping the provider and calling `shutdown` on it is mandatory for a provider set globally, because the current global's clone lives in a `static` that Rust never drops, so the drop-triggers-shutdown path cannot fire for it; it can fire for a provider that a later `set_*` replaces, if the global held its last clone. The metrics guide's note implies this; no author states the `static` reason in those words.
- Inferred: the absence of a scoped override follows from the removal of the guard in #444 and of the returned provider in #3078; nobody proposed a test-scoped replacement in the threads read.

**No stated rationale found**

- Why 0.31 dropped the returned old provider from `set_tracer_provider`, beyond "to align with metrics counterpart" (changelog) and the pull request body ("mem::replace was replaced with mutable assignment and old tracer is no longer returned"): looked in #3078, its comments (only bots and the CLA check besides the author) and the 0.31 changelog.
- Why there is no test-scoped override: looked in the `global` module docs, `docs/` (ADR 001, `docs/design/*.md`, `docs/metrics.md`, `docs/traces.md`) and the issue search `repo:open-telemetry/opentelemetry-rust global in:title` (saved as `gh/search-global-title.json`); none discusses a scoped override for tests.

**Constraints**

- *Deployment model:* an in-process library. The API crate (`opentelemetry`) is a dependency of instrumented libraries and holds the globals; the SDK crate is chosen and configured by the application. Since 0.28 exporters run on SDK-owned background threads (batch span processor, periodic reader), with no async-runtime requirement:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/docs/migration_0.28.md
> These components have been re-written to no longer require an async runtime.
> Instead they operate by spawning dedicated background thread, and making
> blocking calls from the same.

- *Guarantees:* recording calls on the global path do not return errors; ADR 001 says regular operation should not panic, and a poisoned global lock degrades to a no-op since 0.31, but a span start runs the application's sampler and each processor's `on_start` on the calling thread with no `catch_unwind` around them (read from source, not run; see What it does, part 4); data loss is allowed and logged once (batch queue full); shutdown is best-effort; the batch span processor bounds its wait for the worker's acknowledgement by a timeout, configurable for traces, and then joins the worker with no deadline, and the metrics periodic reader waits a fixed five seconds; the simple span processor first takes the exporter mutex, which an export in flight holds, so that wait is outside its timeout.
- *Failure model:* set-up can fail (exporter build returns `Result`); shutdown and flush return `OTelSdkResult`; a span ended after its provider has shut down is skipped silently in `span.rs`, before any processor sees it, and tracers obtained after shutdown are no-ops; a processor that is itself shut down while the provider is not warns ("Spans are being emitted even after Shutdown. This indicates incorrect lifecycle management of TracerProvider in application. Spans will not be exported." in `span_processor.rs`), for example when a processor is shut down directly, or in a race with provider shutdown.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/span.rs
>         // skip if provider has been shut down
>         if provider.is_shutdown() {
>             return;
>         }

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/372ebbc74d4dba71bb9820732f57f7316b4e7a1e/opentelemetry-sdk/src/trace/provider.rs
> /// Once shut down, the `TracerProvider` transitions into a disabled state. In this state, further
> /// operations on its associated `Tracer` instances will result in no-ops, ensuring that no spans
> /// are processed or exported after shutdown.

- *Stability:* pre-1.0, breaking the global API between minor releases (0.13, 0.22, 0.23, 0.28 and 0.31 all changed it).
- *History:* a global with an uninstall guard that restored the previous provider (from #229, merged 2020-09-27, to v0.12); guard replaced by returning the old provider plus `global::shutdown_tracer_provider` (0.13, #444); exporter pipelines that installed the global themselves, removed in 2024 (#1787 metrics, #1812 traces, under #1592); global logs removed (0.23, #1691); `global::shutdown_meter_provider` removed (0.22, #1412) and `global::shutdown_tracer_provider` removed (0.28, #2369); `set_tracer_provider` stops returning the old provider and stops panicking (0.31, #3078). The direction throughout is from a global that owns the lifecycle to an application-held provider with an optional global for discovery.

**Costs and dissent**

- *The guard was a footgun.* Julian Tescher, then maintainer, in #427:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/427#issuecomment-760386919
> @open-telemetry/rust-approvers this does seem to be a common footgun for people coming to otel.

- *Losing the handle once it is set globally.* Zhongyang Wu, maintainer, in #1623 (since 0.31 neither setter returns the replaced provider, `set_meter_provider` having already returned unit at 0.30.0, so even that route is closed; the application must keep a clone):

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/1623#issuecomment-2002771562
> However, for end users, if they set the global signal prvoider using `set_<signal>_provider` method, they will lose the handle of the provider. For them to shutdown the provider, they need to call `let _ = set_<singal>_provider(NoopProvider::new())` method to regain the handle of the provider, which seem to be unintuitive

- *Shutdown through the global did not flush.* #1961 (user `stepantubanov`) reported that `global::shutdown_tracer_provider()` only dropped a reference while a `tracing` layer held a tracer; Lalit Kumar Bhasin, maintainer:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1961#issuecomment-2248813859
> Agree, doc is misleading. We can use this issue to track the improvement.

- *Shutdown hung.* #536 and #868 report `global::shutdown_tracer_provider()` hanging on async runtimes; closed after the rewrite to dedicated threads. Cijo Thomas:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/868#issuecomment-2612873048
> BatchProcessors, PeriodicReader are modified to use own thread and do blocking calls from that one only.

- *Drop-triggered shutdown broke the global.* #1661 (a user) reported that a `Drop` added by #1623 shut down the provider shared with the global; Lalit Kumar Bhasin replied as below. The fix moved `Drop` to the shared inner value, so only the last clone shuts down.

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1661#issuecomment-2054252711
> @bwalk-at-ibm Your analysis is correct. We shouldn't have `Drop` implemented for `SdkMeterProvider`.

- *A provider dropped too early.* #1625 (a user) reported a provider dropped while its tracer was still in use. Zhongyang Wu:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1625#issuecomment-1999989238
> Yeah it's a known behavior. Users need to manually hold reference to provider or pass the provider to global tracer provider.

- *Globals and tests.* Zhongyang Wu, in #444; and Cijo Thomas, in #3324 (2026), on the `log` crate's global in the appender tests. At 0.33.1, `global/trace.rs` and `global/metrics.rs` contain no `#[test]` (grep of the pinned tree).

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/444#issuecomment-780325598
> But if two tests try to modify the global tracer provider at the same time, the result will likely be non-deterministic. Thus, I run tests in `global/trace.rs` sequentially.

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3324
> Only `log` integration within `tracing` appender is ignored, as `log` has no other way to be initialized except globally which is not test friendly.

- *Dissent on the missing logs global.* `Kile-Asmussen`, a user, in #3346 (rejected; the matching #3347 closed unmerged):

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3346#issuecomment-3871139953
> It would not be appropriate for a first-party Rootcause library to implement a Notification/Facade pattern with global state.

- *Contention on the global lock.* #3870 (open at the read date, contributor `paullegranddc`) proposes `ArcSwap` in place of the `RwLock`, with a benchmark showing the read path at 2.39 µs per access with 18 threads against 359 ns. Utkarsh Umesan Pillai, maintainer, pushed back:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/3870#issuecomment-6986728101
> A synthetic loop that repeatedly acquires and drops a handle is not an optimization target for us.

- *An SDK panic path despite ADR 001.* The batch span processor's shutdown joins its worker with `handle.join().unwrap()` after `self.handle.lock().unwrap()` (`span_processor.rs`), so a poisoned lock or a panicked worker panics the caller of `shutdown`.
- *Comparables that chose otherwise* (`log`, `tracing`, `metrics`) are covered in A1 to A3. Within OpenTelemetry Rust, the spec allows a delegating global; this crate does not delegate (see Inferred).

**Unverified**

- Whether other OpenTelemetry language SDKs return a delegating (proxy) tracer from the global before an SDK is installed, which this crate does not: not checked here; C2 and C3 cover the Python and Java APIs.
- Which release first shipped the uninstall guard: #229 was merged 2020-09-27, but the first release carrying it was not checked against the tags. Its presence at v0.12.0 is shown from source.

#### Leads that did not hold (OpenTelemetry Rust)

- **"A backend installed at the top level"** holds by convention, as the setters' docs assign them to applications, but differs from `log`, `tracing` and `metrics` in two respects the claim does not cover: `set_tracer_provider` and `set_meter_provider` are replaceable any number of times (last call wins unless the lock is poisoned; `set_tracer_provider` returns nothing since 0.31, and `set_meter_provider` already did not at 0.30.0), and installing does not hand over the lifecycle: the application builds and keeps the SDK provider, and the global holds a clone that is never dropped until another `set_*` replaces it.
- **"A global entry point"** holds with a qualification the claim omits: the global is optional. The SDK's getting-started example uses `provider.tracer(...)` without it, and logs have no global (removed in 0.23, a re-add refused in 2026, #3346).
- **"A scoped override for tests"** does not hold at 0.33.1: no item in either crate's full index scopes a provider. One existed up to v0.12 (`TracerProviderGuard`) and was removed in 0.13.
- **Lead `shutdown_tracer_provider`**: confirmed removed in 0.28 (#2369), not merely deprecated. While present it released the global's reference rather than shutting the provider down if other references existed (#1961).
- **Lead "a tracer obtained before a provider is set starts working once one is"**: it stays no-op (source of `GlobalTracerProvider::tracer_with_scope`; documented for meters).
- **Lead `SdkTracerProvider::builder()` / `SdkMeterProvider`**: both exist; `build()` returns the provider directly, not a `Result`. The fallible step is the exporter build.
- **`SdkMeterProvider::shutdown_with_timeout`** takes a timeout and ignores it (`_timeout: Duration`), so the meter provider's shutdown wait is the periodic reader's fixed five seconds per reader, not the caller's value.

## B. Python's standard logging

The Python standard library's logging, along the same three parts.

### B1. CPython `logging` (3.15.2)

The Python standard library's logging package: one implicit registry of named loggers per interpreter (so one per process in the usual single-interpreter process), configured by the application and shared by every library. Source pinned at CPython tag `v3.15.2` (the highest `v3.x.y` tag on the date read), docs at `docs.python.org/3.15` (titled "Python 3.15.2 documentation"), PEP 282 and PEP 391 at python/peps `af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58`, the commit D4 uses (both "Status: Final"), migrated bugs.python.org issues cited by GitHub number. Read 2026-11-24.

**What it does**

Source: https://docs.python.org/3.15/c-api/subinterpreters.html
> the new interpreter has
> separate, independent versions of all imported modules

*1. Global entry point: an implicit registry, one per interpreter.* A module-level static created at import, never by the application (a subinterpreter imports its own copy of every module, so it has its own registry): import runs `root = RootLogger(WARNING)` and `Logger.manager = Manager(Logger.root)`, a single, undocumented `Manager` ("[under normal circumstances] just one Manager instance"). Loggers "are singletons that are never freed during a script execution" (the cookbook).

Source: https://docs.python.org/3.15/library/logging.html
> Multiple calls to getLogger() with the same
> name will always return a reference to the same Logger object.

A library may call `getLogger` at import time, before configuration: `Logger.callHandlers` walks `c.handlers` then `c = c.parent` on every call, so handlers added to root later are found. That holds until `fileConfig` or `dictConfig` runs. Both take `disable_existing_loggers`, default `True` in both forms: every existing non-root logger not named in the configuration, nor with a named ancestor, is marked `disabled`, and `Logger.handle` then returns early. `basicConfig` never touches `disabled`.

Source: https://docs.python.org/3.15/library/logging.config.html
> disable_existing_loggers – If specified as False, loggers which
> exist when this call is made are left
> enabled. The default is True because this
> enables old behaviour in a
> backward-compatible way.

*2. Top-level configuration: three entry points, all repeatable, with different failure behaviour.* **`basicConfig`** does nothing, with no signal, when root already has handlers, unless `force` is passed:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py#L2020-L2024
>     This function does nothing if the root logger already has handlers
>     configured, unless the keyword argument *force* is set to ``True``.
>     It is a convenience method intended for use by simple scripts
>     to do one-shot configuration of the logging package.

Its whole body sits under `if len(root.handlers) == 0:` (line 2107), including setting `level` and the `ValueError('Unrecognised argument(s): ...')` check (lines 2150–2153). So with handlers present and no `force`, `basicConfig(level=...)` changes nothing and a misspelt keyword raises nothing (read from the indentation, not executed). `force=True` (3.8) first removes and closes root's handlers. The module-level `logging.debug()`, `info()`, `warning()`, `error()`, `critical()` and `log()` call `basicConfig` whenever root has no handlers; `Logger` methods do not (lines 2170–2178).

**`fileConfig`** "can be called several times" and is loud for a missing, empty or unparseable file:

Source: https://docs.python.org/3.15/library/logging.config.html
> It will raise FileNotFoundError if the file
> doesn’t exist and RuntimeError if the file is invalid or
> empty.

**`dictConfig`** is loud too. Most per-object failures are re-raised as `ValueError('Unable to configure ...') from e`; a missing or wrong `version` raises `ValueError` before anything changes (config.py 538–541).

Source: https://docs.python.org/3.15/library/logging.config.html
> If an error is encountered during configuration, this function will
> raise a ValueError, TypeError, AttributeError
> or ImportError with a suitably descriptive message.

A non-incremental `dictConfig` is not atomic: `_clearExistingHandlers` empties `logging._handlers` and flushes and closes every handler before anything new is built (config.py 576–580; see Inferred).

`incremental: True` changes only the levels of named handlers and the levels and `propagate` of named loggers, and ignores everything else.

*3. Scoped override for tests: none in `logging`.* No name in `__all__` (lines 33–42) is a context manager or scope; a grep for `contextmanager`, `__enter__`, `__exit__` and `temporar` over the three modules finds only `QueueListener.__enter__`/`__exit__`, which start and stop its thread; `logging.disable(level)` is process-wide with no restore (lines 2253–2254); `Manager` is not public. The cookbook offers a recipe, not an API (`assertLogs` and `caplog` are covered in T4 and T5):

Source: https://docs.python.org/3.15/howto/logging-cookbook.html
> There are times when it would be useful to temporarily change the logging
> configuration and revert it back after doing something. For this, a context
> manager is the most obvious way of saving and restoring the logging context.

*4. Without configuration: `lastResort`, `NullHandler` and the advice to libraries.* A record that finds no handler in its chain goes to a module-level `lastResort = _StderrHandler(WARNING)`, which writes to whatever `sys.stderr` is at call time:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py#L1755-L1764
>         if (found == 0):
>             if lastResort:
>                 if record.levelno >= lastResort.level:
>                     lastResort.handle(record)
>             elif raiseExceptions and not self.manager.emittedNoHandlerWarning:
>                 sys.stderr.write("No handlers could be found for logger"
>                                  " \"%s\"\n" % self.name)
>                 self.manager.emittedNoHandlerWarning = True

So unconfigured, `WARNING` and above print the bare message to stderr and lower levels are dropped silently (by root's default level and by `lastResort`'s own). `logging.lastResort = None` restores the pre-3.2 behaviour: nothing, except a one-off "No handlers could be found" line when `raiseExceptions` is true. A library attaches the do-nothing `NullHandler`, whose docstring still says it is "intended to be used to avoid the "No handlers could be found for logger XXX" one-off warning"; in 3.15.2 its real effect is to keep the library's WARNING-and-above records from `lastResort`. The HOWTO, "Configuring Logging for a Library":

Source: https://docs.python.org/3.15/howto/logging.html
> If the using application does not use logging, and library code makes logging
> calls, then (as described in the previous section) events of severity
> WARNING and greater will be printed to sys.stderr. This is regarded as
> the best default behaviour.

Source: https://docs.python.org/3.15/howto/logging.html
> It is strongly advised that you do not add any handlers other
> than NullHandler to your library’s loggers. This is
> because the configuration of handlers is the prerogative of the application
> developer who uses your library.

*5. The serving path: what can raise or block on a logging call.* The swallow is a per-handler convention, not enforced by the framework. `Handler.handle` calls `emit` under the handler's lock with no `try`; each standard `emit` that does I/O or formatting wraps its own work (`BufferingHandler` and `MemoryHandler` do not: their `emit` appends and may call `flush`, which hands records to the target's `handle` without a `try`, so an exception from the target's filters or from a non-standard target reaches the caller; both quoted below), including formatting (so a mismatched `%`-format goes to `handleError`), and does not catch non-`Exception` throwables (`with self.lock: self.emit(record)`, lines 1029–1030). Only `StreamHandler.emit` re-raises `RecursionError` (quoted next). `FileHandler.emit` calls it outside any `try` (lines 1272–1273), and `WatchedFileHandler.emit` calls `FileHandler.emit` outside its own `try` (handlers.py 544–549), so the re-raise reaches their callers. No `emit` in `logging.handlers` has a `RecursionError` clause: `BaseRotatingHandler.emit` (the rotating file handlers; handlers.py 78–83) and the `emit` of `SocketHandler`, `SysLogHandler`, `SMTPHandler`, `NTEventLogHandler`, `HTTPHandler` and `QueueHandler` catch `Exception`, which includes `RecursionError`, and pass it to `handleError` (the rotating and HTTP handlers are quoted after `StreamHandler`, `SocketHandler` below). Read from source, not run:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py#L1153-L1162
>         try:
>             msg = self.format(record)
>             stream = self.stream
>             # issue 35046: merged two stream.writes into one.
>             stream.write(msg + self.terminator)
>             self.flush()
>         except RecursionError:  # See issue 36272
>             raise
>         except Exception:
>             self.handleError(record)

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>         try:
>             if self.shouldRollover(record):
>                 self.doRollover()
>             logging.FileHandler.emit(self, record)
>         except Exception:
>             self.handleError(record)

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>             h.getresponse()    #can't do anything with the result
>         except Exception:
>             self.handleError(record)

`BufferingHandler.emit`, which `MemoryHandler` inherits, and `MemoryHandler.flush` have no `try`:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>         self.buffer.append(record)
>         if self.shouldFlush(record):
>             self.flush()

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>         with self.lock:
>             if self.target:
>                 for record in self.buffer:
>                     self.target.handle(record)
>                 self.buffer.clear()

`SocketHandler.emit` passes every `Exception` to `handleError`, a `RecursionError` included. Its own socket errors never get that far. `createSocket` and `send` catch `OSError`, so a failed connection or send drops the record without calling `handleError`, and nothing is printed whatever `raiseExceptions` says. The docstring: "If there is an error with the socket, silently drop the packet." (handlers.py 622–633, 647–652, 695; read from source, not run). With `closeOnError` set (default `False`), its `handleError` closes the socket instead of printing (676–688).

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py#L699-L703
>         try:
>             s = self.makePickle(record)
>             self.send(s)
>         except Exception:
>             self.handleError(record)

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py#L647-L652
>         if self.sock:
>             try:
>                 self.sock.sendall(s)
>             except OSError: #pragma: no cover
>                 self.sock.close()
>                 self.sock = None  # so we can call createSocket next time

With `raiseExceptions` true (the default), `handleError` prints a traceback to stderr and returns, never re-raising the original exception (while printing, a `RecursionError` is re-raised and only `OSError` from the writes is suppressed, lines 1097–1105). With it false, nothing:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py#L1066-L1075
>         This method should be called from handlers when an exception is
>         encountered during an emit() call. If raiseExceptions is false,
>         exceptions get silently ignored. This is what is mostly wanted
>         for a logging system - most users will not care about errors in
>         the logging system, they are more interested in application errors.
>         You could, however, replace this with a custom handler if you wish.
>         The record which was being processed is passed in to this method.
>         """
>         if raiseExceptions and sys.stderr:  # see issue 13807

The module's comment on the flag says "propagated", which the code does not do (see Leads that did not hold):

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py#L58-L62
> #raiseExceptions is used to see if exceptions during handling should be
> #propagated
> #
> raiseExceptions = True

Still reaching the caller: a non-integer level to `Logger.log` raises `TypeError` when `raiseExceptions` is true and returns silently otherwise (lines 1592–1596); an `extra` key colliding with a `LogRecord` attribute raises `KeyError` from `makeRecord` whatever the flag (lines 1643–1645); filters run outside any `try` (lines 868–872); a `RecursionError` in `StreamHandler.emit`, also through `FileHandler` and `WatchedFileHandler`, or any non-`Exception`; and any `emit` that does not wrap its own work, a freedom the maintainer defends for third-party handlers (issue 70892). Standard handlers had such gaps, since fixed: `SysLogHandler.emit` formatting outside its `try` (issue 66965, bpo-22776) and `WatchedFileHandler` raising `FileNotFoundError` with `raiseExceptions = False` (issue 135683; wrapped at the tag, handlers.py 543–546).

What can block: the write is synchronous on the calling thread, under the handler lock (`StreamHandler.emit` writes then flushes). An `isEnabledFor` cache miss takes the module `_lock`, as do `getLogger`, `addHandler` and every configuration call. The docs promise thread-safety through one module lock and one lock per handler, and warn:

Source: https://docs.python.org/3.15/library/logging.html
> If you are implementing asynchronous signal handlers using the signal
> module, you may not be able to use logging from within such handlers.

Source: https://docs.python.org/3.15/library/logging.html
> This method is called after a handler-level lock is acquired, which
> is released after this method returns. When you override this method, note
> that you should be careful when calling anything that invokes other parts of
> the logging API which might do locking, because that might result in a
> deadlock.

After `fork` the module re-initialises its locks in the child (line 251).

`QueueHandler`/`QueueListener` is the cookbook's answer, because "almost any network-based handler can block": enqueue on the calling thread (after `prepare` formats the record there), write on a listener thread. The enqueue never waits for queue space: `put_nowait` is `put(item, block=False)`, and on a full bounded queue it raises `Full`, which sends the record to `handleError`, so it is lost and, with the flag true, a traceback is printed. With a `queue.Queue` it still takes the queue's lock, held for the size check and the append (`with self.not_full:`, queue.py 150–175). The queue may be "any queue-like object", and the docs warn that a `multiprocessing.Queue` whose own `DEBUG` records reach a `QueueHandler` on the same queue "will cause a deadlock or infinite recursion" (logging.handlers.rst 1060–1067). Read from source and docs, not run. Records still queued at exit are processed only if `QueueListener.stop()` is called. (`self.queue.put_nowait(record)`, handlers.py 1496.)

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/queue.py#L150-L156
>         with self.not_full:
>             if self.is_shutdown:
>                 raise ShutDown
>             if self.maxsize > 0:
>                 if not block:
>                     if self._qsize() >= self.maxsize:
>                         raise Full

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.handlers.rst#L1062-L1067
>       The :mod:`multiprocessing` module uses an internal logger created and
>       accessed via :meth:`~multiprocessing.get_logger`.
>       :class:`multiprocessing.Queue` will log ``DEBUG`` level messages upon
>       items being queued. If those log messages are processed by a
>       :class:`QueueHandler` using the same :class:`multiprocessing.Queue` instance,
>       it will cause a deadlock or infinite recursion.

At exit, `shutdown` (via `atexit`) flushes and closes every handler, ignoring `OSError` and `ValueError` and swallowing anything else unless `raiseExceptions` is set (lines 2256–2288).

**The stated why**

Speakers: the module's copyright, `__author__` and CODEOWNERS (`Lib/logging/` and `Doc/**/logging*` to `@vsajip`) make Vinay Sajip the maintainer; PEP 282's authors are Vinay Sajip and Trent Mick, PEP 391's Vinay Sajip alone. The reference, HOWTO and cookbook are cited below as the CPython logging docs, which CODEOWNERS assigns to the maintainer. Other core developers are dissent or context; What's New pages are release notes.

*The registry: named singletons so references need not be passed around.* Vinay Sajip and Trent Mick, authors, PEP 282 (the sentence continues: so that "one does not have to pass logger object references around"; the PEP adds that the Manager "is a singleton and is not directly exposed to users"):

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0282.rst
> A registry of named singleton logger objects is maintained so that

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0282.rst
> If a single logging mechanism is enshrined in the standard
> library, 1) logging is more likely to be done 'well', and 2)
> multiple libraries will be able to be integrated into larger
> applications which can be logged reasonably coherently.

*Configuration from outside the code, changeable at run time.* PEP 282; then Vinay Sajip, author, PEP 391; then the CPython logging docs on why incremental configuration is limited to levels:

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0282.rst
> The main benefit of a logging system like this is that one can
> control how much and what logging output one gets from an
> application without changing that application's source code.

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0391.rst
> Another drawback of the current ConfigParser-based configuration
> system is that it does not support incremental configuration: a new
> configuration completely replaces the existing configuration.

Source: https://docs.python.org/3.15/library/logging.config.html
> Changing the object graph arbitrarily in
> a safe way is problematic in a multi-threaded environment; while not
> impossible, the benefits are not worth the complexity it adds to the
> implementation.

*`disable_existing_loggers` defaults to `True`: backward compatibility* (quoted under What it does, 1). Loggers are disabled rather than deleted because "other threads may continue to hold references to them" (the `_handle_existing_loggers` docstring). Vinay Sajip, maintainer, issue 127567 (2025):

Source: https://github.com/python/cpython/issues/127567#issuecomment-2651855870
> If `incremental` _isn't_ set (the default, if omitted), then a wholesale cleanup of the configuration happens - but loggers are singletons, and the `disable_existing_loggers=False` is needed to prevent the loggers from being marked as disabled.

*The module-level helpers call `basicConfig`: so short scripts are easy* (PEP 282: "A further convenience provided by these functions is that if no configuration has been done, basicConfig() is automatically called"). Vinay Sajip, maintainer, issue 79711 (bpo-35530), then issue 78531 (bpo-34350):

Source: https://github.com/python/cpython/issues/79711#issuecomment-1093807350
> For that use case, logging.debug() and friends call basicConfig() under the hood so that simple usage is as easy as possible.

Source: https://github.com/python/cpython/issues/79711#issuecomment-1093807350
> Libraries are not supposed to configure logging except using a NullHandler, and this is also documented, but there are numerous authors of libraries that ignore that advice.

Source: https://github.com/python/cpython/issues/78531#issuecomment-1093796123
> Obviously, this behaviour can't be changed because of the need to maintain backward compatibility (and IMO there is no reason to change this behaviour, as it is like this by design).

*`basicConfig` is a no-op once root has handlers: one-shot configuration for simple scripts* (its docstring). Why silent rather than an error: No stated rationale found. The 3.8 What's New on why `force` was added; then Vinay Sajip, maintainer, issue 78078 (bpo-33897):

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/whatsnew/3.8.rst
> This solves a long-standing problem.  Once a logger or *basicConfig()* had
> been called, subsequent calls to *basicConfig()* were silently ignored.

Source: https://github.com/python/cpython/issues/78078#issuecomment-1093790100
> Except that it doesn't \*just* clear the handlers - the act of clearing also lets e.g. the level to be set and the formatting to be set by the call.

*Swallowing handler errors: logging must not change how the application behaves.* Vinay Sajip, maintainer, issue 34244 (an early item on bare `except:`, adding that logging "swallows exceptions, except SystemExit and KeyboardInterrupt in certain situations"); then on his blog, December 2010. The HOWTO gives the same reason.

Source: https://github.com/python/cpython/issues/34244#issuecomment-1093957746
> The reason for the fair number of bare excepts in logging is this: in many cases (e.g. long-running processes like Zope servers) users don't want their application to change behaviour just because of some exception thrown in logging.

Source: https://plumberjack.blogspot.com/2010/12/proposed-changes-to-logging-defaults.html
> When the logging package was introduced, this was done with a philosophy that logging is an adjunct to normal application activity — meaning that a script should work in exactly the same way with or without the presence of logging.

*`raiseExceptions` defaults to `True`: development is noisy, production should turn it off.* the CPython logging docs, the HOWTO; the reference agrees:

Source: https://docs.python.org/3.15/howto/logging.html
> The default value of raiseExceptions is True. This is
> because during development, you typically want to be notified of any
> exceptions that occur. It’s advised that you set raiseExceptions to
> False for production usage.

*The swallow stays per handler: backward compatibility for third-party handlers.* Vinay Sajip, maintainer, issue 70892 (bpo-26705), declining a user's proposal to move `try`/`handleError` into `Handler.handle`:

Source: https://github.com/python/cpython/issues/70892#issuecomment-1093711465
> And if there are existing handler implementations out there (i.e. not in the stdlib) which don't call handleError in their emit() (i.e. allow exceptions to propagate upwards), their behaviour would change, wouldn't it? That's not backwards-compatible.

*The handler lock around `emit` is a contract.* Vinay Sajip, maintainer, issue 68833 (bpo-24645), declining to drop it for `QueueHandler`:

Source: https://github.com/python/cpython/issues/68833#issuecomment-1093688002
> Currently, people overriding emit() [or code called from there] know that any state they manipulate there is protected by the handler lock - and this would not be the case if I implemented your suggestion.

*Deadlocks from logging inside `emit` were answered with documentation.* Vinay Sajip, maintainer, issue 96727 (where he also says `emit()` calls "don't have complete freedom as to what they can do"):

Source: https://github.com/python/cpython/issues/96727#issuecomment-1251372370
> I prefer to just add documentation - you need an unusual set of circumstances to hit this (very specialised handler and repeated configuration during program execution), and in this case the very few people who need to do this and hit a deadlock will need to find a workaround.

*`lastResort` (3.2): warnings and errors should not pass silently, and a library that cannot raise needs a configurable place to report.* From a python-dev thread of December 2010, begun when `concurrent.futures` needed to report errors it could not raise. Vinay Sajip, maintainer, python-dev:

Source: https://mail.python.org/pipermail/python-dev/2010-December/106556.html
> There is a way in which this can be done without
> affecting a logging configuration, viz. logging can define a "handler of last
> resort" (not attached to any logger) which is invoked when there are no
> user-specified handlers.

Source: https://mail.python.org/pipermail/python-dev/2010-December/106556.html
> This is of course a backwards-incompatible change to logging semantics: instead
> of saying that logging will be silent unless explicitly asked to produce output,
> we're saying that logging will always produce output for warnings and errors (or
> perhaps just errors), unless explicitly silenced.

Nick Coghlan, CPython core developer (not the logging maintainer), who raised the request:

Source: https://mail.python.org/pipermail/python-dev/2010-December/106561.html
> Libraries that write directly to stderr affect program behaviour as
> well - at least with logging, the application developer will have an
> easier time of silencing (or redirecting) them.

Source: https://mail.python.org/pipermail/python-dev/2010-December/106580.html
> As a starting point, I'd say warnings and above, no formatting (i.e.
> just the message).

Vinay Sajip, maintainer, on his blog (adding that logging gives "more flexibility in dealing with it than would a bare write to sys.stderr"), then on python-list answering a user who asked "why not simply drop the log event":

Source: https://plumberjack.blogspot.com/2010/12/proposed-changes-to-logging-defaults.html
> In some cases exceptions can’t be usefully raised, and writing out a message is the only way to provide information about an error condition which has been detected.

Source: https://mail.python.org/pipermail/python-list/2010-December/744466.html
> However, the consensus on Python-dev is that the logging package
> should do useful work, and not just act as an adjunct, i.e. notify the
> user on warning and error conditions by default if no logging
> configuration is set up.

Source: https://mail.python.org/pipermail/python-list/2010-December/744415.html
> There's only one handler of last resort (else
> it wouldn't be a last resort).

*`NullHandler`: the application owns handler configuration* (the HOWTO, quoted under What it does, 4; the cookbook's "Patterns to avoid" agrees). The blog on the original purpose of the message `NullHandler` silences:

Source: https://plumberjack.blogspot.com/2010/12/proposed-changes-to-logging-defaults.html
> The message was provided as a means of warning developers, who would have been new to logging, about a possible misconfiguration.

**Inferred**

- Inferred: a non-incremental `dictConfig` that raises part-way leaves logging part-configured: `_clearExistingHandlers()` (config.py 578) has already closed every existing handler and nothing restores them. The claim's "fail loudly" (E) holds for the exception, but the old configuration does not survive. Read from statement order; not executed.
- Inferred: a blocking stream (full pipe, slow disk, stalled socket) blocks the calling thread inside `emit`, and every other thread logging to that handler waits on its lock. No docs sentence says this for streams in general; the cookbook says it for network handlers.
- Inferred: the rule that libraries attach only `NullHandler` follows from the single registry: any handler a library adds lands on a logger the application shares.
- Inferred: a library calling `getLogger` at import is silenced by a later `fileConfig`/`dictConfig` that omits its name and keeps the default; one calling it lazily is not. Survival depends on import order relative to configuration.

**No stated rationale found**

- Why `handleError` prints rather than re-raises when `raiseExceptions` is true. Checked the docstring, reference docs, the HOWTO's "Exceptions raised during logging", PEP 282 and issues 43949, 78267 and 70892. In 2006–2007 the maintainer described the flag as raising ("exceptions are generally raised", issue 43949, 2007-01-15; `handleError()` "raises everything if raiseExceptions is set (the default)", issue 34244, 2006-12-22). The code does not show a change. At tags `v2.3.1`, `v2.4`, `v2.5` and `v2.6`, `handleError` prints the traceback under `if raiseExceptions:` and does not re-raise, as at `v3.15.2` (read from source, not run). Python 2.3.1 was released on September 23, 2003, per https://www.python.org/downloads/release/python-231/ (unpinned; read as of 2026-11-24). Trunk on the statement dates was not read. Why the statements and the code differ was not found.

Source: https://github.com/python/cpython/blob/v2.3.1/Lib/logging/__init__.py#L633-L636
>         if raiseExceptions:
>             import traceback
>             ei = sys.exc_info()
>             traceback.print_exception(ei[0], ei[1], ei[2], None, sys.stderr)

- PEP 282 on handler exceptions, `raiseExceptions`, `NullHandler` or `lastResort`: a grep for those terms, `swallow` and `last resort` returns 0. Its only related statement is the thread-safety requirement.
- Why no scoped or test override exists. Checked PEP 282, PEP 391, the HOWTO, the cookbook (its `LoggingContext` recipe gives no reason it is not an API), and tracker searches `logging "context manager" in:title` (132106, 109461, 83770, 65782, none on this) and `logging in:title temporarily` (0).
- Why `basicConfig` is silent rather than raising. In issue 46092 (2008) the reporter proposed "giving a ValueError in such cases"; Guido van Rossum (CPython's creator, not the maintainer) replied "I think the behavior is intentional, but I suppose it could be documented better"; the maintainer added a doc sentence (comment 1093405360) without a reason. Also checked issues 78078 and 79711, the docs and PEP 282.

**Constraints**

- Deployment model: one registry per interpreter process, shared by many libraries and one application, serving both long-running programs (PEP 282 names Zope) and "short scripts and small applications" (plus the interactive prompt and Jupyter, per the 3.8 What's New). The maintainer weighs "the newbie who writes a one-off script" (issue 79711).
- Guarantees and failure model: as under What it does (same name, same logger; thread-safe with no caller work; loggers never freed; per-handler swallow with one global switch; caller-side errors can still raise; unconfigured is not silent; blocking is synchronous unless a queue is put in front).
- History: PEP 282 (2002), shipped in 2.3, built on `java.util.logging`, log4j, Protomatter's Syslog and mx.Log. `fileConfig` first; `NullHandler` 3.1; `dictConfig` with incremental configuration (PEP 391) and `lastResort` 3.2; `force` 3.8 (bpo-33897); the `formatter` parameter 3.15.

**Costs and dissent**

- Implicit `basicConfig` in the helpers. Mark Dickinson, CPython core developer (`author_association: MEMBER`), speaking as a user at Enthought, issue 79711; the maintainer replied it is by design and cannot change (quoted above); issue 92859 (2022) raised it again as a documentation problem:

Source: https://github.com/python/cpython/issues/79711#issuecomment-1093807343
> In my mind, this is a design flaw in logging, and it's one that's caused my colleagues and me real-world pain on multiple occasions.

Source: https://github.com/python/cpython/issues/79711#issuecomment-1093807346
> And that results in logging being accidentally configured as a side-effect halfway through a long test run, when one of those libraries happens to be imported.

- `basicConfig` silently doing nothing: reported in 2008 (issue 46092); Raymond Hettinger, CPython core developer, in issue 78078 (2018), whose request led to `force` in 3.8. `force` is opt-in; a call without it is still silent.
- `disable_existing_loggers` defaulting to `True`: the HOWTO warns it "may or may not be what you want". Issue 90195 (bpo-46037): an already-disabled logger is not re-enabled by a later `dictConfig` naming it. Issue 127567: `disable_existing_loggers: False` still closes every existing handler; the maintainer pointed to `incremental` and it closed as not planned.
- One switch for every handler error. Serhiy Storchaka, CPython core developer, issue 134568 (open), on `BrokenPipeError` from `StreamHandler`; then a user in issue 70892 proposing "print", "propagate" and "ignore" modes (closed as not planned):

Source: https://github.com/python/cpython/issues/134568#issuecomment-5058456849
> We lack a mechanism to silence or re-raise exceptions by choice -- it is print-all or silence-all.

Source: https://github.com/python/cpython/issues/70892#issuecomment-1093711466
> For example when raiseException is True the handleError method don't propagate the excpetion as will be expected.

- The swallow is not uniform: issues 66965 (2014) and 135683 (2025), above.
- Blocking and deadlocks. Issue 91305 (bpo-47149): `DatagramHandler` did a DNS lookup per record; its reporter, a user, said it is "important for a logging system not to block the service doing the logging". Issue 96727: a deadlock between `dictConfig` and a logging `emit`, seen "in production", answered with documentation. Issue 84551 (bpo-40371, open): a deadlock between `logging._lock` and the import lock in `dictConfig`. Issue 68833's request to drop the redundant `QueueHandler` lock was declined. Fork issues 80714, 80768, 81921 and 86263 (titles only) record hangs.
- The `lastResort` change. John Nagle, a user, python-list, December 2010; in the same thread Jean-Michel Pichavant, a user, asked "why not simply drop the log event, doing nothing ? It sounds pretty reasonable and less intrusive."

Source: https://mail.python.org/pipermail/python-list/2010-December/744694.html
> "sys.stderr" might be connected
> to a dead pipe, and writing to it would then kill the program.

- The `NullHandler` burden: a 2012 user called the old message "very annoying" (issue 60743, bpo-16539); the maintainer called it "not a valid issue"; amaury.forgeotdarc, a core developer, closed it "works for me".
- Comparables that chose otherwise: out of scope for this section (A1 to A4 cover the Rust crates, T1 to T10 the test fakes).

**Unverified**

- Why the maintainer's 2006–2007 statements describe `handleError` as raising when it prints at `v2.3.1`, `v2.4`, `v2.5` and `v2.6`: trunk on the statement dates, and the pre-3 hg and Subversion history, were not fetched.
- The `lastResort` commit: its message, "logging: added handler of last resort.", was confirmed through the GitHub API as cpython commit `5a27d4018692a9cb9f30b5ed81ac7061c8fe3c82` (2010-12-10); its body and the svn revision number (r87157) were not checked. `Misc/HISTORY` at the tag confirms the entry under 3.2 beta 1.
- Fork issues 80714, 80768, 81921 and 86263: titles only.
- Searches covered only `python/cpython` issues (one malformed and some rate-limited queries discarded); Discourse was not searched. Of the python-dev and python-list threads, only the cited messages were read.

#### Leads that did not hold (Python `logging`)

The first three are CPython's own comments, docstrings or docs contradicted by the code; the leads all held, with the `dictConfig` nuance below.

- "raiseExceptions is used to see if exceptions during handling should be propagated" (module comment, lines 58–62, and the reference docs). `handleError` never propagates: with the flag true it prints and returns. The flag makes the caller see an exception only outside `handleError`: `Logger.log` with a non-int level, and `shutdown`.
- What's New in 3.2 says the old no-handler behaviour "would either raise an exception or silently drop the event depending on the value of logging.raiseExceptions". The HOWTO and the 2010 blog post describe a one-off "No handlers could be found for logger X.Y.Z" message instead, and the `elif` branch in `callHandlers` (quoted above) writes it and does not raise.
- The `NullHandler` docstring is out of date: the warning it names appears since 3.2 only if `lastResort` is `None`; its effect now is to keep a library's records from `lastResort`.
- "`dictConfig` raises `ValueError`" holds in part: the docs list `ValueError`, `TypeError`, `AttributeError` or `ImportError`; the source wraps most as `ValueError`; and a failure after handlers are cleared leaves the old configuration closed.
- Held, as described above: `getLogger` and the manager, `disable_existing_loggers`, `force`, `lastResort`, `NullHandler`, the HOWTO library section, `handleError`, `QueueHandler`/`QueueListener`.

## C. OpenTelemetry's API and SDK

Why OpenTelemetry separates an API from an SDK, what the API does with no SDK installed, what its specification says about errors, and how two language SDKs implement its global registration.

### C1. The OpenTelemetry specification (v1.63.0)

The cross-language specification that splits each signal into an API libraries import and an SDK the application owner installs. Pinned at `open-telemetry/opentelemetry-specification` tag `v1.63.0` (published 2026-11-23); read 2026-11-24. Roles in C1–C3 are GitHub's `author_association` ("org member" `MEMBER`, "contributor" `CONTRIBUTOR`, "user" `NONE`); whether someone is a maintainer or approver was not checked.

**What it does**

*The split.* Each signal has API, SDK, Semantic Conventions and Contrib packages. The API is whatever is imported into third-party libraries and application code; the SDK is installed and managed by the application owner; the two "MUST be provided as independent artifacts".

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/overview.md
> [Instrumentation authors](glossary.md#instrumentation-author) MUST NOT directly reference any SDK package of any kind, only the API.

*No SDK installed.* The API carries a minimal implementation whose calls "should be no-ops which generate minimal overhead"; no figure is given for that cost.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/library-guidelines.md
> The API package is a self-sufficient dependency, in the sense that if the end user application or a third-party library depends only on it and does not plug a full SDK implementation then the application will still build and run without failing, although no telemetry data will be actually delivered to a telemetry backend.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/library-guidelines.md
> It is important that values returned from this minimal implementation of API are valid and do not require the caller to perform extra checks (e.g. createSpan() method should not fail and should return a valid non-null Span object).

The trace no-op is a section of `trace/api.md` (no side effects, except that a parent `SpanContext` still propagates). `metrics/noop.md` requires a No-Op of every language and forbids its `MeterProvider` to "return a non-empty error or log any message".

*Error handling.* Run time is forbidden to throw; initialisation may fail fast. The SDK also must not throw for its own errors, and where a non-null value is expected must return a "no-op" or default object, ideally pre-allocated. Users MUST be able to change the default error handling, and a custom handler "is the only exception" to these principles.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> OpenTelemetry implementations MUST NOT throw unhandled exceptions at runtime.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> 1. API methods MUST NOT throw unhandled exceptions when used incorrectly by end users.
>    The API and SDK SHOULD provide safe defaults for missing or invalid arguments.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> 2. The API or SDK MAY _fail fast_ and cause the application to fail on initialization, e.g. because of a bad user config or environment, but MUST NOT cause the application to fail later at runtime, e.g. due to dynamic config settings received from the Collector.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> Whenever the library suppresses an error that would otherwise have been exposed to the user, the library SHOULD log the error using language-specific conventions.

*Performance and blocking.* `performance.md` uses lower-case "should" and has no RFC 2119 "MUST NOT block"; under load it prefers dropping data with a warning log ("Prevent blocking"). It allows shutdown to block:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/performance.md
> - **Library should not block end user application by default.**
> - **Library should not consume unbounded memory resource.**

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/performance.md
> The OpenTelemetry client could block the end user application when it shut down. On shutdown, it has to flush data to prevent information loss. The OpenTelemetry client should support user-configurable timeout if it blocks on shut down.

The normative no-blocking rules are narrower. On the serving path, `Span.End` "MUST NOT perform blocking I/O on the calling thread" (`trace/api.md`), and the log record processor's `OnEmit` "SHOULD NOT block or throw exceptions" (`logs/sdk.md`); the span processor's `OnStart`, `OnEnding` and `OnEnd` say the same in lower case (`trace/sdk.md`). `Export` "MUST NOT block indefinitely", except for synchronous output through an API without deadlines or cancellation (trace, metrics and logs SDK pages), and `Shutdown` "SHOULD NOT block indefinitely" (metrics and logs SDK pages; lower case in `trace/sdk.md`). The specification's simple processor passes each span to the exporter "as soon as they are finished" (`trace/sdk.md`, which does not say on which thread; `logs/sdk.md` says the same of log records). OpenTelemetry Rust's simple processor runs the export on the thread that ends the span (A4; read from source, not run).

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/logs/sdk.md
> `OnEmit` is called when a `LogRecord` is [emitted](api.md#emit-a-logrecord). This
> method is called synchronously on the thread that emitted the `LogRecord`,
> therefore it SHOULD NOT block or throw exceptions.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> This is an implementation of `SpanProcessor` which passes finished spans
> and passes the export-friendly span data representation to the configured
> `SpanExporter`, as soon as they are finished.

*Global registration.* A SHOULD, in the same words for `TracerProvider`, `MeterProvider` and `LoggerProvider`; implementations SHOULD also allow "an arbitrary number" of provider instances.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/api.md
> Normally, the `TracerProvider` is expected to be accessed from a central place.
> Thus, the API SHOULD provide a way to set/register and access
> a global default `TracerProvider`.

Silent on a get before any set and on a second set. The only related rule: implementations "MUST NOT require users to repeatedly obtain a `Tracer` again with the same identity to pick up configuration changes". Global propagators MUST default to no-op, and since 1.63.0 their getter and setter are a SHOULD.

*Shutdown and ForceFlush.* The TracerProvider text; `MeterProvider` and `LoggerProvider` repeat it, with "MAY" where trace says "can". `Shutdown` "SHOULD provide a way to let the caller know whether it succeeded, failed or timed out". `ForceFlush` carries the same timeout text as `Shutdown` below, with "flush timeout"; the exporter's `ForceFlush` SHOULD be called only when "absolutely necessary", such as on FaaS providers that may suspend the process before export.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> `Shutdown` MUST be called only once for each `TracerProvider` instance. After
> the call to `Shutdown`, subsequent attempts to get a `Tracer` are not allowed. SDKs
> SHOULD return a valid no-op Tracer for these calls, if possible.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> `Shutdown` SHOULD complete or abort within some timeout. `Shutdown` can be
> implemented as a blocking API or an asynchronous API which notifies the caller
> via a callback or an event. OpenTelemetry client authors can decide if they want to
> make the shutdown timeout configurable.

**The stated why**

The speaker is the specification, published by the OpenTelemetry Specification SIG, naming no individual author.

*The split.* Instrumentation is cross-cutting; library authors "do not care (and cannot know) what specific implementation of OpenTelemetry is used in the final application"; and instrumented libraries must work with no SDK, which the application chooses to install or not (the SDK's plugin interfaces are for plugin authors):

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/overview.md
> Cross-cutting concerns, by their very nature, violate a core design principle – separation of concerns. As a result, OpenTelemetry client design requires extra care and attention to avoid creating issues for the codebases which depend upon these cross-cutting APIs.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/library-guidelines.md
> The rationale is that third-party libraries and frameworks which are instrumented with OpenTelemetry must still be fully usable in the applications which do not want to use OpenTelemetry (so this removes the need for framework developers to have "instrumented" and "non-instrumented" versions of their framework).

*Valid, cheap no-op values:* so the caller need not "know and worry about the fact that minimal implementation is in effect", minimising boilerplate and error handling, and:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/library-guidelines.md
> It is also important that minimal implementation incurs as little performance penalty as possible, so that third-party frameworks and libraries that are instrumented with OpenTelemetry impose negligible overheads to users of such libraries that do not want to use OpenTelemetry too.

*Errors are swallowed* because telemetry is not essential to business logic and the library may be loaded "outside of the application developer's control":

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md
> We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

*A configurable handler*, so developers can run strict "in a staging environment to catch invalid uses of the API, or malformed config". *The exporter's synchronous-write exception*, from its NOTE:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> > a blocked write. Bounding the caller's wait through background execution can
> > leave that write blocked and retaining resources after `Export` returns, or
> > allow output to complete after a timeout. These costs motivate this exception.

*A global at all:* only "Normally, the `TracerProvider` is expected to be accessed from a central place".

**Inferred**

- Inferred: failing at initialisation (allowed) versus run time (forbidden) is what lets Java's `GlobalOpenTelemetry.set` throw (C3), setting the global being an initialisation act. No author says so in the specification; in Java PR #5010 jack-berg (org member) calls Java's choice "fail fast".
- Inferred: the specification's silence on a second set and a get before set is why implementations differ, as issue #3068 records.

**No stated rationale found**

- Why the global is a SHOULD not a MUST, and a global rather than dependency injection, beyond "a central place": checked the provider sections of `trace/api.md`, `metrics/api.md` and `logs/api.md`, and `grep -rn -i global specification/` over the `v1.63.0` tarball. The only reason found anywhere is issue #5299 (Costs and dissent).
- Why `Shutdown` "MUST be called only once": checked the `Shutdown` sections of `trace/sdk.md`, `metrics/sdk.md` and `logs/sdk.md`.

**Constraints**

- Deployment model: the API is a dependency of other libraries; the SDK is installed once by the application owner; a platform or agent may load OpenTelemetry dynamically.
- Promised: no failure without an SDK, valid non-null values, no run-time throws, silent stateless metrics and logs no-ops, no re-fetch of a `Tracer` to see configuration changes. Not promised: a no-op cost figure, a hard non-blocking API, any behaviour for get-before-set or a second set.
- Failure model: telemetry is lost rather than the application disturbed; suppressed errors are logged; a user error handler is the one sanctioned way to surface errors.
- History: issue #3068 (2023) found global get/set "under-defined" and closed as stale; issue #3302 (a global "reset") was closed wontfix by the Technical Committee; issue #5299 and PR #5294 (merged 2026-09-09) made global propagators a SHOULD, to match the providers.

**Costs and dissent**

Issue #3068, by MrAlias (contributor). In the thread jmacd (org member) said accepted dependency injection makes "the delegating no-op mechanism unnecessary" because "the DI mechanism _is a manner of delegation_".

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3068
> This does not specify the API behavior when an "access" is made prior to a global being set. Nor does it specify the behavior of multiple set operations. This seems like a source of user confusion if implementations deviate in behavior.

Issue #5299 by carlosalberto (contributor); his PR #5294 adds "race conditions when setting the global instance". Then jsuereth (contributor), for the Technical Committee, refusing issue #3302's reset:

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/5299
> Exposing global instances of `TracerProvider`, `MeterProvider`, `LoggerProvider` and `Propagators`, although useful, has been a source of problems in a few SIGs (e.g. Java), due to the problems related to initialization, with its functionality being _mostly_ specially useful for auto instrumentation agents (as the injected SDK needs to be exposed for end user usage).

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3302#issuecomment-2343985637
> We will not be adding a reset to global tracer provider as a general specification.  There's a lot of issues that this would cause globally across all languages.

The silent no-op's cost as hidden misconfiguration is in C2 and C3.

**Unverified**

- Issue #3068's language table is a contributor's 2023 survey; its Java cell ("Log error" on a second set) conflicts with Java's source, which throws (C3). Go, JS, Ruby and .NET were not checked.
- Whether the "API and Minimal Implementation" text dates from the founding: `library-guidelines.md` history not traced.

### C2. OpenTelemetry Python `opentelemetry-api` (1.45.2)

The Python API package: a proxy that late-binds and a set-once global. Pinned at `open-telemetry/opentelemetry-python` tag `v1.45.2` (published 2026-10-29; `__version__ = "1.45.2"`); read 2026-11-24 from `trace/__init__.py`, `metrics/_internal/__init__.py`, `_logs/_internal/__init__.py`, `util/_once.py` and `util/_providers.py`.

**What it does**

*Before a set*, `get_tracer_provider()` returns a module-level `ProxyTracerProvider`, unless `OTEL_PYTHON_TRACER_PROVIDER` is set. Then the first call loads the named entry point and installs it as the global. If it cannot load it (no such entry point, or one that fails), it logs the error and re-raises it to the caller, who may be `trace.get_tracer()`:

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/trace/__init__.py
>         tracer_provider: TracerProvider = _load_provider(OTEL_PYTHON_TRACER_PROVIDER, "tracer_provider")

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/util/_providers.py
>     except Exception:  # pylint: disable=broad-exception-caught
>         logger.exception("Failed to load configured provider %s", provider)
>         raise

A `ProxyTracer` resolves on each use: a `NoOpTracer` until a global exists, then the real tracer, cached. Spans started before the set are no-op and never recorded. Metrics push instead: `_ProxyMeterProvider` records each proxy meter and, on a set, gives every meter and instrument a real backing object.

*Setting twice.* The first set wins; later calls are ignored with a warning and do not raise, under a `Once` guard with a lock (the docstring: "a warning will be logged if any further attempt is made"). Metrics is the same ("Overriding of current MeterProvider is not allowed"). So is `_logs`, read from source, not run. Before a set, `get_logger_provider()` returns a module-level `ProxyLoggerProvider`, unless `OTEL_PYTHON_LOGGER_PROVIDER` names an entry point. Its `ProxyLogger` uses a `NoOpLogger` until a global exists, then the real logger, cached. A second set is ignored under a `Once` guard, with a warning ("Overriding of current LoggerProvider is not allowed").

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/trace/__init__.py
>     did_set = _TRACER_PROVIDER_SET_ONCE.do_once(set_tp)
> 
>     if log and not did_set:
>         logger.warning("Overriding of current TracerProvider is not allowed")

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/_logs/_internal/__init__.py
>     if _LOGGER_PROVIDER is None:
>         if _OTEL_PYTHON_LOGGER_PROVIDER not in environ:
>             return _PROXY_LOGGER_PROVIDER

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/_logs/_internal/__init__.py
>     did_set = _LOGGER_PROVIDER_SET_ONCE.do_once(set_lp)
> 
>     if log and not did_set:
>         _logger.warning("Overriding of current LoggerProvider is not allowed")

*No-op.* `NoOpTracer.start_span` returns the parent's non-recording span, or a new `NonRecordingSpan` with the parent's `SpanContext`.

**The stated why**

*Set once, with a warning.* aabmass (org member), issue #781; ocelotl (contributor), issue #958, adding that an auto-instrumentation provider "may be easily overridden in application code causing unexpected side effects like span processors being lost":

Source: https://github.com/open-telemetry/opentelemetry-python/issues/781
> Then, `a.py` runs and overwrites the current global provider. Now modules `a` and `b` have tracers from different providers with different configs! `b`'s tracer never had a span processor set up and never gets exported!

*The no-op fallback and the warning.* aabmass (org member), issue #1159:

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1159#issuecomment-738133247
> If a user of that library does not set the global tracer provider, then the `DefaultTracerProvider` will provide no-op spans that don't do anything, since the user isn't collecting telemetry.

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1159#issuecomment-738133247
> That is the intention behind logging a warning (https://github.com/open-telemetry/opentelemetry-python/issues/781), so that it doesn't fail to collect telemetry silently.

*The proxy.* Before PR #1726 an early `get_tracer()` fixed the default no-op provider for good. owais (contributor), issue #1276; in #1159 he adds that import order "is not necessarily in users' control". aabmass (org member) records the decision; PR #1726 (owais) shipped proxies returning no-ops "until a global tracer provider is set by the user".

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1276
> Calling `trace.get_tracer()` before setting a global tracer provider effectively disables all tracing for the process.

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1159#issuecomment-760345226
> We discussed in the 2021-01-14 SIG meeting and agreed to go with the proxy approach in #1445.

**Inferred**

- Inferred: an early `get_tracer()` and a second set are separate hazards with separate cures: the proxy for the first, the `Once` guard and warning for the second. From the code and issues together; no single author states it.
- Inferred: before the proxy, `get_tracer_provider()` stored the default provider as the global on first read, so a late set failed (issue #1159: "it calls get_tracer_provider, which SETS global _TRACER_PROVIDER=DefaultTraceProvider"); the pre-#1726 source was not read.

**No stated rationale found**

Not applicable for set-once, the warning, the no-op and the proxy. One gap: why warn rather than raise. aabmass lists raising as an option in #1159 (comment 742040616) and the thread ends with the proxy. Read: issues #781, #840, #958, #1159, #1276; PRs #856, #959, #1726, #2182.

**Constraints**

- Deployment model: auto-instrumentation (`opentelemetry-instrument`) and frameworks such as Django may import instrumented modules before set-up (#1159, comment 812943009).
- Guarantees: a set takes effect once (thread-safe since PR #2182); early tracers and meters bind once a provider is set; earlier telemetry is dropped. Failure model: a second set is a no-op plus a `logging` warning; a provider named by `OTEL_PYTHON_TRACER_PROVIDER` that cannot be loaded is logged and re-raised from the first `get_tracer_provider()`.
- History: global set/get 2019 (PR #29); override warning 2020-06 (PR #856, issue #840); override blocked 2020-08 (PR #959, issue #958); proxy 2021-04 (PR #1726); race fix 2021-10 (PR #2182). From the file's commit list at `v1.45.2`.

**Costs and dissent**

The proxy drops whatever is emitted before set-up. aabmass (org member) preferred an explicit early set, and named throwing the only option that loses no data:

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1159#issuecomment-742724245
> I would rather folks explicitly set what they want than lose traces/metrics because things ran in an unexpected order or an import took longer than expected. I'm worried the proxy approach might encourage this.

Source: https://github.com/open-telemetry/opentelemetry-python/issues/1159#issuecomment-742040616
> 1\. is the only way to prevent spans/metrics from being dropped, because it forces the user to be explicit.

anton-ryzhov (contributor) was surprised by "`set` that may be called only once and `get` that internally calls that one-shot `set`". garry-cairns (user), specification issue #3302: set-once blocks resetting the global after a `fork` ("Once will prevent that"). Re-running hosts trip the warning: Streamlit re-runs scripts in-process (issue #3743, open), and pmcollins (org member) replied that operations "designed to happen only once per Python process" need care. Comparable that chose otherwise: Java (C3) throws on a second set and has no proxy.

**Unverified**

- The SDK's `TracerProvider.shutdown` is covered in G6; `force_flush` was not read.

### C3. OpenTelemetry Java `GlobalOpenTelemetry` (1.68.0)

The Java API's global entry point, which throws on a second set and binds no proxy. Pinned at `open-telemetry/opentelemetry-java` tag `v1.68.0` (published 2026-11-06); read 2026-11-24 from `api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java`.

**What it does**

*Setting twice throws* `IllegalStateException`, with the first caller's stack as cause:

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java
>       if (globalOpenTelemetry != null) {
>         throw new IllegalStateException(
>             "GlobalOpenTelemetry.set has already been called. GlobalOpenTelemetry.set must be "
>                 + "called only once before any calls to GlobalOpenTelemetry.get. If you are using "
>                 + "the OpenTelemetrySdk, use OpenTelemetrySdkBuilder.buildAndRegisterGlobal "
>                 + "instead. Previous invocation set to cause of this exception.",
>             setGlobalCaller);

*`get()` before `set()` fixes the global*: it installs and returns an autoconfigured SDK if opted in, otherwise `OpenTelemetry.noop()`, so any later `set` throws and a `Tracer` got this way is a no-op for good (nothing proxies it). On the autoconfigured path the first `get()` returns a separate wrapper from the one stored as the global (quoted before **The stated why**). `getTracer`, `getMeter`, `getTracerProvider`, `getMeterProvider` and `getPropagators` all call `get()`.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java
>           set(OpenTelemetry.noop());
>           openTelemetry = Objects.requireNonNull(globalOpenTelemetry);

Since 1.57.0, `getOrNoop()` and `isSet()` read without that side effect. Autoconfiguration runs only with `otel.java.global-autoconfigure.enabled=true`; if it throws, `get()` logs SEVERE ("OpenTelemetry will not be enabled") and falls back to no-op; if the autoconfigure class is present but its `initialize` or `getOpenTelemetrySdk` method cannot be found or accessed, `get()` throws `IllegalStateException` ("This is a bug in OpenTelemetry."). A null instrumentation-scope name or version passed to `getTracer`, `tracerBuilder`, `getMeter` or `meterBuilder` is logged and given a no-op. A null passed to `set` is not: `set` begins with `Objects.requireNonNull(openTelemetry, "openTelemetry");` (read from source, not run). `resetForTest()` clears the global, tests only.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java
>     } catch (NoSuchMethodException | IllegalAccessException e) {
>       throw new IllegalStateException(
>           "AutoConfiguredOpenTelemetrySdk detected on classpath "
>               + "but could not invoke initialize method. This is a bug in OpenTelemetry.",

With autoconfiguration enabled, the first `get()` returns a different object from later calls, though both wrap the same SDK (read from source, not run). `initialize()` registers the SDK through `set`, which stores an obfuscating wrapper. `get()` then returns another wrapper, which it built around the same SDK. Later calls return the stored one, and `obfuscatedOpenTelemetry` builds a new wrapper each time it is called.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk-extensions/autoconfigure/src/main/java/io/opentelemetry/sdk/autoconfigure/AutoConfiguredOpenTelemetrySdk.java#L36-L38
>   public static AutoConfiguredOpenTelemetrySdk initialize() {
>     return builder().setResultAsGlobal().build();
>   }

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk-extensions/autoconfigure/src/main/java/io/opentelemetry/sdk/autoconfigure/AutoConfiguredOpenTelemetrySdkBuilder.java#L434-L439
>     GlobalOpenTelemetry.set(
>         () -> {
>           AutoConfiguredOpenTelemetrySdk sdk = buildImpl();
>           autoConfiguredRef.set(sdk);
>           return sdk.getOpenTelemetrySdk();
>         });

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L183
>       globalOpenTelemetry = obfuscatedOpenTelemetry(openTelemetry);

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L148-L151
>           OpenTelemetry autoConfigured = maybeAutoConfigureAndSetGlobal();
>           if (autoConfigured != null) {
>             return autoConfigured;
>           }

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L357
>       return obfuscatedOpenTelemetry((OpenTelemetry) getOpenTelemetrySdk.invoke(autoConfiguredSdk));

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L372-L378
>   private static OpenTelemetry obfuscatedOpenTelemetry(OpenTelemetry openTelemetry) {
>     OpenTelemetry incubating = IncubatingUtil.obfuscatedOpenTelemetryIfIncubating(openTelemetry);
>     if (incubating != null) {
>       return incubating;
>     }
>     return new ObfuscatedOpenTelemetry(openTelemetry);
>   }

**The stated why**

*The global is discouraged but exists for the agent.* The class Javadoc (scare text added in PR #4223 by jkwatson, John Watson per commit b4218426ee's co-author line; reworded in PR #7819 by jack-berg):

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java
>  * <p>WARNING: To avoid inherent complications around initialization ordering, it's best-practice to
>  * pass around instances of {@link OpenTelemetry} rather than using {@link GlobalOpenTelemetry}.
>  * However, the OpenTelemetry javagent makes the {@link OpenTelemetry} instance it installs
>  * available via {@link GlobalOpenTelemetry}.

*`get()` sets a no-op so a late `set` throws.* bogdandrutu (org member), proposing it in PR #2548's review; jack-berg (org member) in PR #5010 and in specification issue #3068 (in issue #4180 he adds that otherwise libraries could hold "a mix of noop and properly configured `OpenTelemetry` instances, depending on the order"):

Source: https://github.com/open-telemetry/opentelemetry-java/pull/2548#issuecomment-763247698
> But do we need #2396 if we simply call `set(NOOP)` on the get? Then if user tries to set will get an error that was already registered when reading first time?

Source: https://github.com/open-telemetry/opentelemetry-java/pull/5010#discussion_r1039022638
> I'm prefer to the fail fast because I think the absence of all telemetry provides a really strong signal to go and fix the issue.

Source: https://github.com/open-telemetry/opentelemetry-specification/issues/3068#issuecomment-1371352082
> The invariant that all calls to `GlobalOpenTelemetry.get` receive the same result simplifies initialization issues which might otherwise be head scratchers since either everything is going to work or nothing is going to work.

*Autoconfiguration became opt-in*: PR #5010 (jack-berg) quotes mateuszrzeszutek asking why the discouraged global should "auto-load the SDK". *Obfuscation* prevents users "from casting them to their SDK-specific implementation" (Javadoc). *`getOrNoop()`*, jack-berg (org member), PR #7819:

Source: https://github.com/open-telemetry/opentelemetry-java/pull/7819
> This will be our recommended default for native instrumentation, as it allows them to use the instance installed by the OpenTelemetry java agent (if installed) or noop (if not installed).

**Inferred**

- Inferred: Java's throw on a second set agrees with the specification's ban on run-time throws if setting the global counts as initialisation; jack-berg's "fail fast" is the closest an author comes, and no one cites the clause.
- Inferred: `getOrNoop()` reopens the mixed state `get()`'s side effect prevents (A gets a no-op, a later `set` succeeds, B gets the real instance); jkwatson raises exactly this in PR #7819.

**No stated rationale found**

Not applicable for throwing, set-on-get, the opt-in, the obfuscation and `getOrNoop`. PR #2548's description is empty; its reason is only in review comments (read: body, comments, review comments, reviews, and commit `b4218426ee280e2c970637df3accb3cbe6daba63`, which lists only squashed titles).

**Constraints**

- Deployment model: the Java agent installs an SDK in premain and calls `set` before application code; instrumentation finds it through the global. Without the agent, the application typically calls `OpenTelemetrySdkBuilder.buildAndRegisterGlobal()`.
- Guarantees: once the global holds an instance, every later `get()` returns that stored instance, except that on the opt-in autoconfiguration path the first `get()` returns its own wrapper, separate from the one the autoconfigured `set` stored, both around the same SDK (read from source, not run); a second `set` throws with the first caller's stack; the instance cannot be cast to the SDK. Failure model: a `get` before `set` gives no-op application-wide, then `IllegalStateException` at the late `set`; autoconfiguration that throws logs SEVERE and degrades to no-op, and one whose methods cannot be reached by reflection throws `IllegalStateException` from `get()`.
- History: own class 2020-12 (PR #2233); set-twice prevented 2021-01 (PR #2548); obfuscation 2021-02 (PR #2829); scare text 2022-03 (PR #4223); opt-in autoconfiguration 2022-12 (PR #5010); `getOrNoop`/`isSet` 2025-11 (PR #7819, 1.57.0). From the file's commit list at `v1.68.0`.

**Costs and dissent**

Libraries touching the global during class initialisation trigger the exception. Issue #4180 (gfelbing, a user of the OpenCensus shim): anuraaga (contributor) replied; yzhaoa (user) found `resetForTest` fails once a library has cached a no-op:

Source: https://github.com/open-telemetry/opentelemetry-java/issues/4180#issuecomment-1043680740
> Unfortunately opencensus automatically initializes on first call and has no way of controlling initialization order - this sort of issue is why in OTel we discourage the global.

Source: https://github.com/open-telemetry/opentelemetry-java/issues/4180#issuecomment-1528988725
> By the time you call resetForTest the opencensus-shim has already captured in a static variable a tracer derived from OpenTelemetry.noop(), so any subsequent attempts to change GlobalOpenTelemetry will not be used by the opencensus shim and thus not produce any traces.

jkwatson (contributor), PR #5010, on the trade-off; then in PR #7819, after jack-berg (org member) called `get()`'s behaviours "real foot guns" and trask (org member) welcomed "an offramp from it", on the gap `getOrNoop` reopens:

Source: https://github.com/open-telemetry/opentelemetry-java/pull/5010#discussion_r1039020746
> I guess it boils down to: in the case of incorrect initialization ordering, do you want a) nothing to be emitted from the SDK at all or b) at least some things emitted, from the instruments/tracers/etc that are initialized after the SDK initialization has taken place.

Source: https://github.com/open-telemetry/opentelemetry-java/pull/7819#issuecomment-3543763125
> Won't we need to advise people to not keep a reference to a potential no-op instance, then, in case they ask for their first instance before the global gets initialized?

*The no-op hides misconfiguration.* PR #2396 by anuraaga (contributor) proposed a warning when the SDK is on the classpath but unregistered; closed stale, unmerged (2022). He kept the no-SDK case silent because a library may be instrumented while "a user doesn't actually want to enable OpenTelemetry in their app":

Source: https://github.com/open-telemetry/opentelemetry-java/pull/2396#issuecomment-791241765
> Yeah this message is only thrown when the SDK is on the classpath, where it's almost always the case that it's an error to have forgotten to register it.

Comparable that chose otherwise: Python (C2) warns and late-binds. Issue #3068 records Go and JS returning a delegating no-op (contributor survey, unverified).

**Unverified**

- The SDK's `SdkTracerProvider.shutdown()`/`forceFlush()` (returning `CompletableResultCode`) were not read; only the specification's were in scope.
- Whether `buildAndRegisterGlobal()` checks anything beyond calling `set`.
- mateuszrzeszutek's role: he is quoted only inside jack-berg's PR #5010 body.

#### Leads that did not hold (OpenTelemetry API and SDK)

- "MUST NOT block" in `performance.md`: absent; it says "should" and allows shutdown and flush to block. Upper-case no-blocking text covers `Span.End` (MUST NOT), the log record processor's `OnEmit` (SHOULD NOT), `Export` (MUST NOT block indefinitely; trace, metrics and logs SDK pages) and `Shutdown` (SHOULD NOT block indefinitely; metrics and logs SDK pages). Shown by `grep -rn 'MUST NOT block\|SHOULD NOT block\|MUST NOT perform blocking'` over `specification/` at `v1.63.0`.
- That the specification defines a tracer or meter obtained before registration: it does not (`grep -rn -i global specification/` at `v1.63.0`); #3068 called it under-defined and closed stale.
- Java's `set` throws if called twice or after `get`: holds after `set`, `get()` or any helper calling it; not after `getOrNoop()` or `isSet()` (since 1.57.0). With autoconfiguration enabled, `get()` sets an SDK, not a no-op.
- Python warns on a second set: holds, and the second provider is ignored, not installed.
- A trace no-op page: no `trace/noop.md` at `v1.63.0` (tree listing); only metrics and logs have `noop.md`.
- #3068's Java "Log error" on a second set: contradicted by Java's source at `v1.68.0` and at PR #2548 (2021), which throw.

## D. Guard values and closure scopes

What each mechanism guarantees at the end of a scope, in Rust and in Python, for the scoping claim.

### D1. Rust's `thread::scoped` guard and RFC 1066 (Rust 1.0.0-beta to 1.2.0; rust-lang/rfcs `f43d578`)

Pre-1.0 `std::thread::scoped` returned a `JoinGuard` whose destructor joined a thread that borrowed the parent's stack; RFC 1066 then made `mem::forget` safe. The guard half of the claim "A Python `with` block maps to a Rust guard value or a closure scope". Read 2026-11-24.

**What it does**

Source: https://github.com/rust-lang/rust/blob/1.0.0/src/libstd/thread/mod.rs
> /// The join guard can be used to explicitly join the child thread (via
> /// `join`), returning `Result<T>`, or it will implicitly join the child
> /// upon being dropped.

Ariel Ben-Yehuda (arielb1, contributor) opened the soundness issue on 2015-04-10:

Source: https://github.com/rust-lang/rust/issues/24292
> You can use a reference cycle to leak a `JoinGuard` and then the scoped thread can access freed memory:

At tag `1.0.0-beta`, `scoped` was stable:

Source: https://github.com/rust-lang/rust/blob/1.0.0-beta/src/libstd/thread/mod.rs
> #[stable(feature = "rust1", since = "1.0.0")]
> pub fn scoped<'a, T, F>(f: F) -> JoinGuard<'a, T> where

Aaron Turon's PR 24385 reverted it to unstable. The PR record shows `merged_at: null` (closed 2015-04-15, last comment alexcrichton's `@bors: r+` on `a94040f`); the landing is shown by tag `1.0.0`, which shipped it unstable:

Source: https://github.com/rust-lang/rust/blob/1.0.0/src/libstd/thread/mod.rs
> #[unstable(feature = "scoped",
>            reason = "memory unsafe if destructor is avoided, see #24292")]

Tag `1.2.0` deprecated it as an unsafe API unlikely ever to be stabilised in that form; PR 27684 (Alex Crichton, merged 2015-08-14) removed it with every other unstable deprecated item. RFC 1066 (Alex Crichton, merged 2015-05-07) made `mem::forget` safe:

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/1066-safe-mem-forget.md
> The standard library and the primitives it
> provides will always attempt to run destructors, but will not provide a
> guarantee that destructors will be run.

**The stated why**

Alex Crichton (alexcrichton, RFC 1066 author; MEMBER on rust-lang/rust), on why the guard was unsound, and why leaks were admitted rather than destructors guaranteed (he announced the RFC in the issue as admitting `scoped` was the source of unsafety):

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/1066-safe-mem-forget.md
> It has never been a guarantee of Rust that destructors for a type will run, and
> this aspect was overlooked with the `thread::scoped` API which requires that its
> destructor be run!

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/1066-safe-mem-forget.md
> Overall the changes necessary for this strategy are more invasive than admitting
> destructors may not run, so this alternative is not proposed in this RFC.

Aaron Turon (aturon, PR 24385 author), on what the bug showed:

Source: https://github.com/rust-lang/rust/pull/24385
> (There are several possible ways to address this issue; it's not a
> fundamental problem with the `scoped` idea, but rather an indication
> that Rust doesn't currently provide a good way to ensure that
> destructors are run within a particular stack frame.)

Brian Anderson (brson, contributor), on why it stopped blocking 1.0:

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-95735628
> Retriaging as P-medium. The immediate threat to 1.0 has subsided since this API is unstable.

The Rustonomicon at 1.100.0 says the API "had to be scrapped in favor of a completely different design"; Crichton closed the issue on deprecation.

**Inferred**

None.

**No stated rationale found**

Not applicable: each point above has a stated why.

**Constraints**

- Deployment: std API for OS threads, sound only if the parent frame outlives the child.
- Guarantee: join on guard drop; RFC 1066 made explicit that destructors are not guaranteed to run.
- Failure: a leaked guard (`Rc` cycle, or the panic-in-destructor bugs rust-lang/rust#14875 and #16135 that RFC 1066 cites) lets the child read a popped frame: use-after-free in safe code.
- History: reported after `1.0.0-beta` marked it stable; fixed by withdrawal, not repair. RFC 1066's "Alternatives" rejected a `Leak` marker trait as too invasive.

**Costs and dissent**

Alex Crichton, RFC 1066, "Drawbacks":

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/1066-safe-mem-forget.md
> It is clearly a very nice feature of Rust to be able to rely on the fact that a
> destructor for a type is always run (e.g. the `thread::scoped` API).

arielb1, an alternative not adopted:

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-91646130
> I think the best way to fix this would be to add a `Leak` OIBIT and make `Rc`/`Arc` require it.

Josh Triplett (joshtriplett, MEMBER), dissenting from admitting leaks:

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-93525984
> I'm suggesting the same thing @Gankro is, that we _should_ prevent writing mem::forget in safe code, using Rc or otherwise.

SirVer (association NONE), objecting to the removal, and bluss (contributor) replying:

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-131095402
> I argue `thread::scoped` should not have been removed until an alternative design was in place.

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-131107912
> Rust cannot keep around features that break memory safety. It will come back when someone figures out (and bugfixes the compiler) a memory safe API for it.

Third-party blog: Gankra (login `Gankra`, contributor in the thread; profile name Aria Desires), "Pre-Pooping Your Pants With Rust" (faultlore.com, unpinnable), calls assuming destructors run in safe code "completely wrong". rust-lang/rfcs#1085 "Leak and Destructor Guarantees" (reem) and #1094 "Guaranteed non-static destructors" (rkjnsn) proposed guaranteed destructors and closed unmerged (found by searching rust-lang/rfcs PRs on "scoped", April to July 2015); not read. Third-party blog: withoutboats ("The Scoped Task trilemma", 2023-04-08, unpinnable), on reopening the question:

Source: https://without.boats/blog/the-scoped-task-trilemma/
> I won’t get into the details in this post, but I’ll say that think the backward
> compatibility problems with changing this decision now would be enormous and disruptive and I’m not
> personally optimistic about this changing.

**Unverified**

- Crichton's and Turon's 2015 library-team roles; only GitHub associations were checked. Real names in D1 and D2 (Ariel Ben-Yehuda, Brian Anderson, Josh Triplett, Alex Crichton, Aaron Turon, Mara Bos for m-ou-se) are GitHub profile names (`gh api users/<login>`, 2026-11-24), not otherwise confirmed.
- "Leakpocalypse": RFC 3151 links `http://cglab.ca/~abeinges/blah/everyone-poops/`, which returns HTTP 404 (2026-11-24); the post was read at faultlore.com, unpinnable.

### D2. Closure scopes: RFC 1084, crossbeam `scope`, `std::thread::scope` and RFC 3151 (Rust 1.100.0; crossbeam-utils 0.8.23)

The closure half of the claim: a function takes a closure and joins every thread spawned in it before returning. `std::thread::scope` is stable since 1.63.0. Read 2026-11-24 at Rust 1.100.0, crossbeam-utils 0.8.23 (published 2026-09-05) and rust-lang/rfcs `f43d578`.

**What it does**

Source: https://doc.rust-lang.org/1.100.0/std/thread/fn.scope.html
> Unlike non-scoped threads, scoped threads can borrow non-'static data,
> as the scope guarantees all threads will be joined at the end of the scope.

The join also runs when the closure panics: the implementation catches the panic, joins, then resumes it.

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
>     // Run `f`, but catch panics so we can make sure to wait for all the threads to join.
>     let result = catch_unwind(AssertUnwindSafe(|| f(&scope)));

A spawned thread's panic becomes a panic of `scope`; to handle it, join the handle inside the scope:

Source: https://doc.rust-lang.org/1.100.0/std/thread/fn.scope.html
> If any of the automatically joined threads panicked, this function will panic.

Source: https://doc.rust-lang.org/1.100.0/std/thread/fn.scope.html
> If you want to handle panics from spawned threads,
> join them before the end of the scope.

Its stated limit:

Source: https://doc.rust-lang.org/1.100.0/std/thread/fn.scope.html
> However, note that joining will only wait for the main function of these threads to finish; even
> when this function returns, destructors of thread-local variables in these threads might still
> be running.

That limit applies to the threads `scope` joins automatically. `ScopedJoinHandle::join` documents a full wait:

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
>     /// Otherwise, it fully waits for the thread to finish, including all destructors
>     /// for thread-local variables that might be running after the main function of the thread.

crossbeam-utils has the same shape (its module docs: a scope "promises to join the thread before the scope ends"), but returns a `Result`:

Source: https://docs.rs/crossbeam-utils/0.8.23/crossbeam_utils/thread/fn.scope.html
> If any of the joined threads has panicked, an Err is
> returned containing errors from panicked threads.

Source: https://docs.rs/crossbeam-utils/0.8.23/crossbeam_utils/thread/fn.scope.html
> Note: Since Rust 1.63, this function is soft-deprecated in favor of the more efficient std::thread::scope.

History: RFC 1084 "Scoped threads, take 2" (Aaron Turon; opened 2015-04-23, Start Date 2015-04-16, closed unmerged 2015-07-01; read at PR head `75db90d` in `aturon/rfcs`) first proposed the closure API. Turon committed crossbeam's first scoped threads on 2015-05-13 (`ad3f87b`). RFC 3151 (merged 2022-01-22, tracking issue rust-lang/rust#93203) moved it into std.

**The stated why**

Aaron Turon (aturon, RFC 1084 author), on avoiding RAII, why callbacks cannot leak, a second benefit, and the limit of the lesson:

Source: https://github.com/aturon/rfcs/blob/75db90de40849d7cd28e334388ffa74b9e7a9bcf/text/0000-scoped-take-2.md
> This RFC proposes an alternative to the `thread::scoped` API that does not rely
> on RAII, and is therefore memory safe even if destructors can be leaked.

Source: https://github.com/aturon/rfcs/blob/75db90de40849d7cd28e334388ffa74b9e7a9bcf/text/0000-scoped-take-2.md
> The closure can use the `defer` method to register callbacks to invoke upon
> *any* exit from the callback, including unwinding. Unlike RAII guards, there is
> no way to leak these callbacks,

Source: https://github.com/aturon/rfcs/blob/75db90de40849d7cd28e334388ffa74b9e7a9bcf/text/0000-scoped-take-2.md
> While the API proposed here is slightly less ergonomic than the RAII-style
> `scoped` API, **it has the benefit of much more clearly marking the point at
> which children threads will be joined, which was left more implicit in the old
> API.**

Source: https://github.com/aturon/rfcs/blob/75db90de40849d7cd28e334388ffa74b9e7a9bcf/text/0000-scoped-take-2.md
> Note that this does *not* mean that RAII should be avoided in general. **RAII is
> still a safe, idiomatic, and ergonomic style of programming for Rust.**

RFC 1084 credits nikomatsakis (whose IRC proposal theemathas relayed in issue 24292: a new `scoped()` "tolerent to memory leaks") and arielb1 (contributor):

Source: https://github.com/rust-lang/rust/issues/24292#issuecomment-93489826
> I think we do want to introduce `Leak` someday, but that would be a breaking change. We may have to settle for an ST-like `with_scope` API.

The RFC 3151 text (not attributed to a person: see **Unverified**) gives the same reason, closures rather than guards; on why the fix stayed outside std until 2022, why a scope beats `spawn`, and why `scope` does not return a `Result` of panics as crossbeam does:

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/3151-scoped-threads.md
> But we weren't
> feeling completely comfortable with including scoped threads in Rust 1.0 so it
> was decided they should live in external crates,

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/3151-scoped-threads.md
>     they make sure spawned threads are joined and don't get accidentally "leaked".

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/3151-scoped-threads.md
>   * This quickly gets complicated, as multiple threads might have panicked.

m-ou-se (MEMBER, proposed stabilisation), on panics in the scope's own closure:

Source: https://github.com/rust-lang/rust/issues/93203#issuecomment-1075344006
> Yes, panics on the main thread simply continue unwinding past the scope, and do not start a new panic.

**Inferred**

Inferred: the join is guaranteed because it runs in `scope`'s own body after the closure returns or unwinds, in no destructor of a caller-held value, so the caller has nothing to `mem::forget`. Backed by the `catch_unwind` comment and RFC 1084's "no way to leak these callbacks", but stated in these words by no source. No source covers process exit or the abort strategy; D3 quotes the reference that no destructors run then, and that the join is also skipped is inferred.

**No stated rationale found**

Not applicable, except crossbeam's first `scope` commit (`ad3f87b`): its message is only "Basic scoped threads", and its source comments speak only to panic-safety (running outside any destructor to avoid #14875).

**Constraints**

- Deployment: synchronous code on OS threads; the parent blocks at scope end.
- Guarantee: every spawned thread is joined before `scope` returns, panic included. In `std`, the automatic join at the end of the scope waits for each thread's main function, not its thread-local destructors, while a thread joined by hand through its `ScopedJoinHandle` is waited for in full, destructors included (from the documentation, not run; quoted under What it does). crossbeam joins the remaining threads with `std::thread::JoinHandle::join`, whose docs say it waits for them in full too; crossbeam's own docs say nothing about thread-local destructors (read from source, not run).

Source: https://github.com/crossbeam-rs/crossbeam/blob/crossbeam-utils-0.8.23/crossbeam-utils/src/thread.rs
>         .filter_map(|handle| handle.join().err())

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/join_handle.rs
>     /// Otherwise, it fully waits for the thread to finish, including all destructors
>     /// for thread-local variables that might be running after the main function of the thread.

- Failure: std re-raises the closure's panic or panics with "a scoped thread panicked"; crossbeam returns `Err` with the panics.
- History: proposed 2015 (RFC 1084), seven years in crossbeam, into std by RFC 3151; the signature changed before stabilisation (next field).

**Costs and dissent**

RFC 1084's "Drawbacks" names the ergonomics cost quoted under **The stated why**. Aaron Turon, closing it:

Source: https://github.com/rust-lang/rfcs/pull/1084#issuecomment-117734482
> I'm going to close this RFC for the time being. We need to solve the soundness issue pointed out by @kballard at the language level first, and I'd also like to prototype this in an external crate before landing in std.

RFC 3151, "Drawbacks" and an open question:

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/3151-scoped-threads.md
> The main drawback is that scoped threads make the standard library a little bit bigger.

Source: https://github.com/rust-lang/rfcs/blob/f43d5789b838fb0d80962e3d4b45fb9ddfcc9a07/text/3151-scoped-threads.md
> Can this concept be extended to async? Would there be any behavioral or API differences?

std has no async counterpart at 1.100.0: the full item index (https://doc.rust-lang.org/1.100.0/std/all.html, unstable items included) lists for "scope" only `thread::scope`, `thread::Scope`, `thread::ScopedJoinHandle` and the unrelated `net::Ipv6MulticastScope`.

Third-party blog: withoutboats ("The Scoped Task trilemma", 2023-04-08, unpinnable), on the cost that the parent must block (the post also says the guard version failed because every Rust object can be leaked without its destructor):

Source: https://without.boats/blog/the-scoped-task-trilemma/
> These APIs mandate that you join the child task(s) before they return control to the caller, that’s
> how they guarantee that the cross-thread borrowing conforms to the lifetime signature.

RFC 3151 differs from what shipped: the RFC's `s.spawn(|_| ...)` with `Scope<'env>` became `s.spawn(|| ...)` with `Scope<'scope, 'env>` in 1.63. m-ou-se (MEMBER):

Source: https://github.com/rust-lang/rust/issues/93203#issuecomment-1075284785
> There was just one open question of whether it was possible to remove the (unnecessary) scope argument to the thread closures.

Comparable that chose otherwise: crossbeam returns a `Result` of panics; RFC 3151's reason for not following it is under **The stated why**.

**Unverified**

- Who wrote the RFC 3151 text: bstrie opened PR 3151 as "take 2" of PR 2647, whose author now shows as `ghost`; the text's Start Date is 2019-02-26.
- Whether the "@kballard" soundness issue that closed RFC 1084 is the borrowck bug a later commenter (`#issuecomment-131596637`) says rust-lang/rust#27641 fixed; the bug was not read.

### D3. What a Rust guard can and cannot do at scope end (Rust 1.100.0; Clippy `rust-1.100.0`; tokio 1.54.1)

`Drop` at scope end: leaks, unwinding, exit and abort, failing destructors, async drop and guards across `.await`. Read 2026-11-24, also rust-lang/api-guidelines `97a0969` and rust-lang/async-fundamentals-initiative `7015ac3`.

**What it does**

A guard can be leaked in safe code (`mem::forget`'s docs give this as why it is not `unsafe`):

Source: https://doc.rust-lang.org/1.100.0/reference/destructors.html
> Preventing a destructor from being run via core::mem::forget or other means is safe even if it has a type that isn’t 'static. Besides the places where destructors are guaranteed to run as defined by this document, types may not safely rely on a destructor being run for soundness.

The reference lists "Leaks of memory and other resources" and "Exiting without calling destructors" as behaviour not considered unsafe. `Drop` gets no error and returns unit:

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/core/src/ops/drop.rs
>     fn drop(&mut self) {

A consequence in std:

Source: https://doc.rust-lang.org/1.100.0/std/fs/struct.File.html
> Errors detected
> on closing are ignored by the implementation of Drop.  Use the method
> sync_all if these errors must be manually handled.

Destructors run during unwinding, but not on process exit, abort or the abort strategy (unwind is the default on most targets, per the reference):

Source: https://doc.rust-lang.org/1.100.0/reference/panic.html
> This means that as the panic traverses Rust frames, live objects in those frames that implement Drop will have their drop methods called.

Source: https://doc.rust-lang.org/1.100.0/reference/destructors.html
> There are some ways to terminate the process without unwinding, in which case destructors will not be run.

Source: https://doc.rust-lang.org/1.100.0/reference/destructors.html
> Additionally, if the panic handler is set to abort, panicking will always terminate the process without destructors being run.

Source: https://doc.rust-lang.org/1.100.0/std/ops/trait.Drop.html
> Implementations should generally avoid panic!ing, because drop() may itself be called
> during unwinding due to a panic, and if the drop() panics in that situation (a “double
> panic”), this will likely abort the program.

Async drop: none on stable. `AsyncDrop` is in `core` behind an unstable feature (nightly only); tracking issue rust-lang/rust#126482 (async drop codegen, from compiler-team MCP 727) was open on 2026-11-24:

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/core/src/future/async_drop.rs
> #![unstable(feature = "async_drop", issue = "126482")]

Guards across `.await`: std's `MutexGuard` is not `Send`.

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/sync/poison/mutex.rs
> impl<T: ?Sized> !Send for MutexGuard<'_, T> {}

Tokio 1.54.1's `Mutex` docs (which add that holding a lock across `.await` is what the async mutex offers over the blocking one):

Source: https://docs.rs/tokio/1.54.1/tokio/sync/struct.Mutex.html
> Note that, although the compiler will not prevent the std Mutex from holding
> its guard across .await points in situations where the task is not movable
> between threads, this virtually never leads to correct concurrent code in
> practice as it can easily lead to deadlocks.

Clippy's `await_holding_lock` (category `suspicious`, since 1.45.0) checks for this; its fix is to unlock before `await`:

Source: https://github.com/rust-lang/rust-clippy/blob/rust-1.100.0/clippy_lints/src/await_holding_invalid.rs
>     /// The other solution is to ensure the mutex is unlocked before calling
>     /// `await`, either by introducing a scope or an explicit call to

**The stated why**

Leaking: RFC 1066 (D1); the Rustonomicon at 1.100.0 restates it (safe code may assume no leaks; unsafe code cannot rely on destructors). Failing and blocking destructors: the Rust API Guidelines (rust-lang/api-guidelines, the library team's published guidance):

Source: https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/dependability.md
> Destructors are executed while panicking, and in that context a failing
> destructor causes the program to abort.

Source: https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/dependability.md
> Instead of failing in a destructor, provide a separate method for checking for
> clean teardown, e.g. a `close` method, that returns a `Result` to signal
> problems.

Source: https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/dependability.md
> Similarly, destructors should not invoke blocking operations, which can make
> debugging much more difficult.

Async drop: the async fundamentals initiative (document last changed 2021-12-14, repository 2023-09-18, so possibly stale; its roadmap adds that sync drop cannot be prevented "even from within an async setting"):

Source: https://github.com/rust-lang/async-fundamentals-initiative/blob/7015ac366d0fda9522916b1099fc221c832dd924/evaluation/challenges/guaranteeing_async_drop.md
> One challenge with `AsyncDrop` is that we have no guarantee that it will be used. For any type `MyStruct` that implements `AsyncDrop`, it is always possible in Rust today to drop an instance of `MyStruct` in synchronous code.

Guards across `.await`, Clippy's lint text:

Source: https://github.com/rust-lang/rust-clippy/blob/rust-1.100.0/clippy_lints/src/await_holding_invalid.rs
>     /// not designed to operate in an async context across await points.

**Inferred**

Inferred: a `Drop` body learns of an in-progress panic only via `std::thread::panicking()`, which the `Drop` docs mention; it is never passed the panic or an error (the signature takes only `&mut self`).

**No stated rationale found**

Not applicable: each point above has a stated why.

**Constraints**

- Deployment: any Rust code; destructors run at scope end and during unwinding.
- Guarantee: the reference names "the places where destructors are guaranteed to run", but no type may rely on its destructor for soundness; nothing runs on `process::exit`, `process::abort` or `panic = "abort"`.
- Failure: `drop` returns unit; a panic in `drop` while unwinding will likely abort; the guidelines send fallible teardown to `close() -> Result`.
- History: settled by RFC 1066 (2015); async drop unstable, tracked since 2024-06-14.

**Costs and dissent**

Source: https://doc.rust-lang.org/1.100.0/nomicon/unwinding.html
> Don’t build your programs to unwind under normal circumstances.

Clippy's known false positive, pushing users from explicit `drop` to a block scope:

Source: https://github.com/rust-lang/rust-clippy/blob/rust-1.100.0/clippy_lints/src/await_holding_invalid.rs
>     /// Will report false positive for explicitly dropped guards

The initiative, on an async-drop type dropped synchronously:

Source: https://github.com/rust-lang/async-fundamentals-initiative/blob/7015ac366d0fda9522916b1099fc221c832dd924/roadmap/async_drop.md
> The question remains: what should code that implements `AsyncDrop` *do* if synchronous `Drop` is invoked? One option is panic, but that is suboptimal, as panic from within a destructor is considered bad practice.

**Unverified**

- Async drop's design status beyond the open tracking issue and the unstable attribute; no design document newer than 2021 to 2023 was read.
- Whether the library team formally adopted the API Guidelines; the repository is under rust-lang, no adoption statement was read.

### D4. Python's `with` (PEP 343), `contextlib` and `async with` (PEP 492) (Python 3.15; python/peps `af21ad1`)

The Python side of the claim. Read 2026-11-24 in the Python 3.15 docs (v3.15.2) and python/peps `af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58`.

**What it does**

Source: https://docs.python.org/3.15/reference/compound_stmts.html
> The with statement guarantees that if the __enter__()
> method returns without an error, then __exit__() will always be
> called.

`__exit__` receives the exception; a false return re-raises it, a true one suppresses it:

Source: https://docs.python.org/3.15/reference/compound_stmts.html
> If the return
> value was true, the exception is suppressed, and execution continues with the
> statement following the with statement.

It can raise its own exception but should not re-raise the one passed in:

Source: https://docs.python.org/3.15/reference/datamodel.html
> Note that __exit__() methods should not reraise the passed-in exception;
> this is the caller’s responsibility.

PEP 343 (Guido van Rossum and Alyssa Coghlan, Final, Python 2.5): an exception from `__exit__` propagates like any other.

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> Similarly, if any of the calls raises an exception, the effect is
> exactly as it would be in the above code.

`contextlib.contextmanager` re-raises the block's exception in the generator; `ExitStack` callbacks do not run on garbage collection:

Source: https://docs.python.org/3.15/library/contextlib.html
> If an unhandled exception occurs in the block, it is reraised inside the
> generator at the point where the yield occurred.

Source: https://docs.python.org/3.15/library/contextlib.html
> Note that callbacks are not
> invoked implicitly when the context stack instance is garbage collected.

`async with` (PEP 492, Yury Selivanov, Final, Python 3.5) lets enter and exit suspend; the data model says `__aexit__` differs from `__exit__` only in returning an awaitable:

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0492.rst
> An *asynchronous context manager* is a context manager that is able to
> suspend execution in its *enter* and *exit* methods.

**The stated why**

PEP 343's Author's Note makes first-person text Guido van Rossum's. Guido van Rossum, PEP author, on its purpose, why a statement rather than PEP 340's block templates, why `__exit__` may swallow exceptions but not by default, and why it receives the exception:

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> This PEP adds a new statement "with" to the Python language to make
> it possible to factor out standard uses of ``try/finally`` statements.

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> However, the with-statement of :pep:`310` does **not** hide control
> flow, in my view: while a finally-suite temporarily suspends the
> control flow, in the end, the control flow resumes as if the
> finally-suite wasn't there at all.

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> The motivation for this
> detail is to make it possible for ``mgr.__exit__()`` to swallow
> exceptions, without making it too easy (since the default return
> value, ``None``, is false and this causes the exception to be
> re-raised).

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> The template in
> that example must commit or roll back the transaction depending on
> whether an exception occurred or not.

Guido van Rossum, PEP 340 (Rejected, before PEP 343), on why the block should not be a closure ("thunk"):

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0340.rst
> I think I'd be slightly uncomfortable seeing
> a block and not knowing whether it will be executed in the normal
> control flow or later.

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0340.rst
> The other problem with thunks is that once we think of them as the
> anonymous functions they are, we're pretty much forced to say that
> a return statement in a thunk returns from the thunk rather than
> from the containing function.

Yury Selivanov, PEP 492 author, on why `async with` is a separate statement:

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0492.rst
> Making existing "for" and "with" statements to recognize asynchronous
> iterators and context managers will inevitably create implicit suspend
> points, making it harder to reason about the code.

**Inferred**

None.

**No stated rationale found**

Not applicable: each point above has a stated why.

**Constraints**

- Deployment: any Python code; `with` is syntax and runs `__exit__` on normal exit, on exceptions, and (PEP 343) on `break`/`continue`/`return`, with three `None` arguments as if the block completed normally.
- Guarantee: `__exit__` always runs once `__enter__` returned without error; it gets the exception, may suppress it or raise its own; `__aexit__` may await.
- Failure: an exception from `__exit__` replaces normal flow; limits under **Costs and dissent**.
- History: PEP 310 (argument-less `__exit__`) and PEP 340 (generator-based anonymous blocks) combined into PEP 343 for Python 2.5; `async with` from PEP 492 in 3.5.

**Costs and dissent**

Guido van Rossum, PEP 343, on a failing `__exit__`, asynchronous interruption, and finalisation (the last said of generator `finally` clauses):

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> (You may ask, what if a bug in the ``__exit__()`` method causes an
> exception?  Then all is lost -- but this is no worse than with
> other exceptions;

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> Even if you
> write bug-free code, a KeyboardInterrupt exception can still cause
> it to exit between any two virtual machine opcodes.)

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0343.rst
> The usual cautions about finalization
> apply -- the process may be terminated abruptly without finalizing
> any objects, and objects may be kept alive forever by cycles or
> memory leaks in the application

PEP 419 (Paul Colomiets, Deferred, "Protecting cleanup statements from interruptions"):

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0419.rst
> However, neither is protected from interruption
> by ``KeyboardInterrupt`` or ``GeneratorExit`` caused by
> ``generator.throw()``.

PEP 789 (Zac Hatfield-Dodds and others, Draft), on `yield` inside a scoping context manager:

Source: https://github.com/python/peps/blob/af21ad1e51fe60aaa3fa2f48392ab4cecfd5fd58/peps/pep-0789.rst
> However, using ``yield`` to suspend a frame inside such a
> context leads to situations where the wrong task is canceled, timeouts are
> ignored, and exceptions are mishandled.

The contextlib docs, on `contextlib.suppress`:

Source: https://docs.python.org/3.15/library/contextlib.html
> As with any other mechanism that completely suppresses exceptions, this
> context manager should be used only to cover very specific errors where
> silently continuing with program execution is known to be the right
> thing to do.

Rejected alternative: Greg Ewing argued for thunk (closure) blocks; PEP 340 quotes and rejects him (quoted under **The stated why**).

**Unverified**

- Whether `docs.python.org/3.15/` changes between 3.15 patch releases. It names the minor series, not a patch release: the pages read identified themselves as "Python 3.15.2 documentation", and `docs.python.org/3.15.2/` returns 404, so no patch-pinned path exists. Read 2026-11-24.

#### The guarantees side by side

Facts only, each drawn from a quotation above. No verdict on the claim is offered. §1 to §4 are D1 to D4.

| Property | Rust guard (`Drop`) | Rust closure scope (`std::thread::scope`, crossbeam) | Python `with` |
| --- | --- | --- | --- |
| Cleanup can be skipped by safe code | Yes: `mem::forget`, `Rc` cycles (§1, §3) | Callers hold no value whose leak skips the join; the join runs inside `scope` (§2; mechanism Inferred) | `__exit__` "will always be called" once `__enter__` returned (§4) |
| Runs on panic or exception | Yes under unwind; not under `panic = "abort"`, `exit` or `abort` (§3) | Yes: `catch_unwind` then join, then resume (§2) | Yes; `__exit__` receives the exception (§4) |
| Sees the error | No error argument; `drop(&mut self)` (§3) | std: an explicit `join()` inside the scope returns the thread's panic as a `Result`; unjoined panics end as a panic of `scope`; crossbeam: `Result` (§2) | Receives type, value, traceback (§4) |
| Can suppress the error | No error to suppress (§3) | std: yes for an explicitly joined thread, by handling its `join()` result inside the scope; unjoined panics are not suppressible; crossbeam returns `Err` (§2) | Yes, by returning true (§4) |
| Can report its own failure | Only by panicking, which aborts if already unwinding; guidelines say use `close() -> Result` (§3) | The scope's return value is the closure's own result (§2) | Yes, by raising (§4) |
| Can suspend (async) | No on stable; `AsyncDrop` unstable at 1.100.0 (§3) | No async scope in std at 1.100.0 (item index, §2); RFC 3151 left async open (§2) | Yes, via `async with` / `__aexit__` (§4) |
| Process exit / abort | Not run (§3) | Not run (Inferred from §3) | Not run: "the process may be terminated abruptly" (§4, said of generator finalisation) |

#### Leads that did not hold (guard and closure)

- **"The original `std::thread::scoped` guard API (`JoinGuard`) and its removal in 2015."** Holds, but longer: stable at `1.0.0-beta`, destabilised by PR 24385 so 1.0.0 shipped it unstable, deprecated in 1.2.0, removed by PR 27684 on 2015-08-14. RFC 3151's "Before Rust 1.0 was released ... it got removed" is looser than the tags: before 1.0 it was destabilised, not removed.
- **"The 'leakpocalypse' issue on the rust-lang/rust tracker."** The issue is rust-lang/rust#24292, titled "std::thread::JoinGuard (and scoped) are unsound because of reference cycles"; the term is from Gankra's post, whose RFC 3151 link 404s; read at faultlore.com, unpinnable.
- **"Crossbeam's closure-based `scope`."** Holds, but the design first appeared in RFC 1084 (closed unmerged 2015-07-01); crossbeam returns `Result` rather than panicking and is soft-deprecated since 1.63.
- **"RFC 3151 which added `std::thread::scope` (Rust 1.63)."** Holds (merged 2022-01-22; stable since 1.63.0), but the shipped API dropped the spawn closure's `&Scope` argument and added a `'scope` lifetime (rust-lang/rust#94559, per the tracking issue); the text began as PR 2647 (2019), PR 3151 being bstrie's "take 2".
- **"No async `Drop`."** Holds for stable only: `core::future::AsyncDrop` exists at 1.100.0 behind `#![unstable(feature = "async_drop", issue = "126482")]`, issue open.
- **"An async-drop initiative."** Exists (rust-lang/async-fundamentals-initiative), but its roadmap page dates from 2021-12-14 and the repository from 2023-09-18; current work is in rust-lang/rust#126482.
- **"Tokio's docs on holding a `std::sync::MutexGuard` across `.await`."** Holds (D3), but the docs do not say the compiler always rejects it: it does not prevent it "in situations where the task is not movable between threads".
- **"Clippy's `await_holding_lock`."** Holds: `AWAIT_HOLDING_LOCK`, `suspicious`, `#[clippy::version = "1.45.0"]`, at `rust-1.100.0`.
- No lead was found not to exist.

## E. The failure posture across fourteen libraries

Both halves of the posture claim.

The claim under test, made from memory and unverified: "Observability libraries usually let set-up fail loudly and never let a call on the serving path fail or block." Set-up is creating or configuring the client, exporter, registry or appender; the serving path is the per-event call. The sentence admits two readings: (a) "usually" qualifies set-up only, and "never" holds for every library on the serving path; (b) "usually" qualifies both halves, so most libraries never let a serving call fail or block. The table can show counterexamples under (a) and cannot measure frequency under (b). Obtaining a handle (a tracer, meter, logger or labelled child) is not a per-event call under this definition; where the sample shows such a lookup it is named (E5's lookup-or-register, E7's `WithLabelValues`, and the read lock OpenTelemetry Rust takes to obtain a tracer through the global, A4). All sources read 2026-11-24 (GitHub API responses were stamped 2026-11-25 01:19 UTC; 2026-11-24 is used throughout). The sample is purposive, not random: it started from the leads, every named API, setting and default of which exists at the pinned version, and was widened on purpose to include libraries expected to go *against* the claim, so that both halves could fail. It covers Java, Python, Go and Rust, and logging (E1 to E3, E12, E13), metrics (E5 to E9) and event or trace shipping (E10, E11, E14); the Kafka producer (E4) is a messaging client, included because the leads named it. **The proportions in the table are an artefact of that choice and say nothing about how common any posture is.**

"Loud" means the failure reaches the caller as an exception, an error value or a panic. Blocking cells name the kind: backpressure on a full buffer, synchronous I/O in the caller's thread, or a lock.

| ID | Library | Lang. | Version | Set-up fails loudly? | Serving call can fail? (on what) | Serving call can block? (default) | Primary source |
|---|---|---|---|---|---|---|---|
| E1 | Log4j 2 Core (`AsyncAppender`, async loggers) | Java | 2.26.1 | **Mostly no**: most errors go to the status logger, and a missing configuration falls back to `DefaultConfiguration`; an `AsyncAppender` left with no usable appender throws `ConfigurationException`, which `Configurator.initialize` status-logs, returning `null` to its caller, but which, read from the code, reaches the first `LogManager.getLogger` caller under automatic configuration. | **Configurable**, default no: `ignoreExceptions=true` swallows appender exceptions. | **Yes, by default, without a bound**: backpressure until the queue has space. | log4j2 `rel/2.26.1` |
| E2 | Logback (`AsyncAppender`) | Java | 1.6.8 | **Depends on the path**: automatic configuration prints `JoranException`; explicit `doConfigure` throws it. | **No**: `doAppend` catches `Exception` into a status error. | **Yes, by default**, mixed: `WARN`/`ERROR` block without a bound and lower levels drop near full. | logback `v_1.6.8`, logback-site `c83ed2a` |
| E3 | Python stdlib `logging` | Python | CPython 3.15.2 | **Yes**: `dictConfig` and `fileConfig` raise; `SysLogHandler` constructs quietly when its Unix socket is not listening or its host does not resolve. | Errors inside a standard handler's `emit` **no** (a traceback to stderr by default; nothing when `raiseExceptions` is false or `sys.stderr` is unset; `SocketHandler` drops its socket errors without one), except a `RecursionError` in `StreamHandler`, `FileHandler` and `WatchedFileHandler`, which is re-raised, and except through `MemoryHandler`'s unguarded flush to its target; a non-integer level **raises `TypeError`**, an `extra` key colliding with a record attribute **raises `KeyError`**, and filter exceptions **propagate** (B1). | **Yes**: handlers run synchronously in the caller's thread under the handler's lock. | cpython `v3.15.2` |
| E4 | Kafka Java producer | Java | 4.4.0 | **Yes**: the constructor throws `KafkaException`. | **Yes**: `send` throws several exceptions directly; API errors come back in the `Future`. | **Yes**: waits for metadata and buffer space up to `max.block.ms` = 60000 ms by default, configurable; blocking in user-supplied serializers or the partitioner is not counted against it. | kafka `4.4.0`, KIP-19, KAFKA-3539 |
| E5 | Micrometer | Java | 1.18.0 | **Mixed**: a type clash throws, while the Prometheus registry logs other registration failures. | Increment no; lookup-or-register (often per event) can throw. | Cumulative counter increment no; a first registration holds the registry's lock while it creates the meter and runs meter-added listeners (read from source, not run). | micrometer `v1.18.0`, issues #2068, #5228 |
| E6 | `prometheus_client` | Python | 0.26.0 | **Yes**: duplicate registration and bad names raise. | **Yes**: wrong labels, negative increments and missing labels raise. | Default (in-process) mode: short lock only, no I/O. Multiprocess mode (`PROMETHEUS_MULTIPROC_DIR` set): one process-wide lock for every metric, every update writes to a memory-mapped file, a new child can open or grow that file, and after a fork every file is reopened. | client_python `v0.26.0`, prometheus/docs guideline |
| E7 | `client_golang` | Go | 1.25.0 | **Yes, panics** with `MustRegister`; `Register` returns an `error`. | **Yes, panics** on a wrong label count or negative add; error-returning variants exist. | **Yes, through a lock**: `WithLabelValues` can block behind a stuck scrape at v1.25.0 (#2147). | client_golang `v1.25.0`, issues #715, #2147 |
| E8 | `pystatsd` | Python | 4.0.1 | **Yes**: the constructor resolves the host and raises on failure. | UDP **no** (swallowed); TCP and Unix **yes**; timer misuse raises. | UDP: a blocking socket write in the caller's thread (how long it can take is Unverified, see E8); TCP and Unix socket: **yes**, no timeout by default. | pystatsd `v4.0.1` |
| E9 | `cadence` (StatsD) | Rust | 1.8.0 | **Yes**: the UDP sink constructor returns a `Result`. | **Yes, as a `Result`**; `.send()` routes errors to a no-op handler by default. | Socket mode is the caller's choice; the queuing sink is unbounded by default and fails rather than blocks when bounded. | cadence `1.8.0`, issue #65 |
| E10 | `sentry-sdk` | Python | 3.0.0 | **Yes**: a malformed DSN raises `BadDsn`; an empty DSN makes the SDK a no-op. | **No**: SDK-internal exceptions are logged. | **No wait for queue space**: `put_nowait` on a 100-item queue, dropping and recording when full. Event processing and any user `before_send` run synchronously on the caller's thread, and when the worker is not alive a submit first takes the worker lock (which `flush` holds while it waits) and starts a thread. | sentry-python `3.0.0`, sentry-docs develop guidelines |
| E11 | `sentry` | Rust | 0.49.6 | **Yes, panics** on an invalid DSN; an empty DSN disables the client; a failed transport-thread spawn is silent (`.ok()`), and envelopes are then recorded lost (G2). | **No error value**: `capture_event` returns a `Uuid`; it is nil if the event is discarded before sending, but a drop at the transport's full channel happens after the ID is set, so a non-nil ID does not mean the event was queued. An application `before_send` runs inline and can panic. | **No wait for channel space**: `try_send` on a 30-slot channel, dropping when full. Event preparation, including any application `before_send`, runs synchronously on the caller's thread under the transport slot's read lock, and in application session mode it takes a session mutex. | sentry-rust `0.49.6` |
| E12 | `tracing-appender` (with `tracing-subscriber`) | Rust | 0.2.5 (subscriber 0.3.23) | **Mixed**: loud for `new`, the worker spawn and `init` (panic) and for the builder and `try_init` (`Result`); quiet for `with_ansi(true)` without the `ansi` feature in a release build, which only prints to stderr. | **No** in lossy mode; the worker ignores I/O errors. | Default **no** (lossy, 128,000 lines); `lossy(false)` blocks with backpressure. | tracing `tracing-appender-0.2.5`, PR #673, issue #2865 |
| E13 | `slog-async` (with `slog`) | Rust | 2.8.0 (slog 2.8.2) | Spawning the worker panics on failure. | `Fatal` on poisoning or disconnection, which the documented `.fuse()` turns into a **panic**. | Default **no** (`DropAndReport`, 128 slots); `Block` blocks. | slog-rs/async `v2.8.0`, slog `v2.8.2` |
| E14 | Datadog `ddtrace` (trace writer only) | Python | 4.17.2 | Not examined. | Not on buffer full: drops, warns and counts. | A lock around encoding; `sync_mode`, on by default in some serverless and job runtimes, flushes in the caller's thread. | dd-trace-py `v4.17.2` |

What the sample shows, half by half, without a verdict. Under reading (a) the serving half says "never", and the sample has counterexamples to it: Kafka, Log4j 2 and Logback block by default, Python `logging` does synchronous I/O, and `prometheus_client`, `client_golang` and `cadence` raise, panic or return errors on misuse. Under reading (b) the same rows show only that some libraries fail or block on the serving path, and the sample cannot say how many, so under that reading the serving half is Unverified too. The set-up half says "usually". A purposive sample cannot test how common a posture is (see the note above the table), so that half is Unverified here. What the sample shows is that set-up postures vary. Set-up is loud in E4, E6 to E10 and E13, and in E3 apart from `SysLogHandler`, which constructs quietly when its Unix socket is not listening or its host does not resolve. It is loud in E11 apart from a silent transport-thread spawn failure, and loud in E12 apart from a release-build `with_ansi` misuse. Log4j 2 status-logs a missing configuration and most component errors, but an `AsyncAppender` with no usable appender throws, and read from the code that reaches the caller on the automatic path (E1). Logback is quiet on its automatic path and loud on an explicit `doConfigure` (E2). Micrometer's Prometheus registry is quiet since 1.6, apart from a type clash (E5). Set-up was not examined for `ddtrace` (E14). The event shippers (E10, E11, and E14 on the one path examined) and the lossy Rust writers (E12, E13) do not block on a full queue; E10 and E11 can still wait elsewhere on the serving call (see their sections).

### E1. Log4j 2 Core (2.26.1)

Java logging framework, here for `AsyncAppender` and the async loggers. Tag `rel/2.26.1` (latest 2.x); manual versioned in the repository under `src/site/antora/`. Read 2026-11-24.

**What it does**

*Set-up.* Problems go to the internal status logger and Log4j keeps running:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/pages/manual/configuration.adoc
> If no configuration file is found, Log4j Core uses the link:../javadoc/log4j-core/org/apache/logging/log4j/core/config/DefaultConfiguration.html[`DefaultConfiguration`] and the xref:manual/status-logger.adoc[status logger] prints a warning.

In `AsyncAppender.start()` a dangling appender reference is only status-logged (`LOGGER.error`), and plugin construction failures in `AbstractConfiguration` are caught and logged, but having no usable appender throws:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/appender/AsyncAppender.java
> throw new ConfigurationException("No appenders are available for AsyncAppender " + getName());

`ConfigurationException` extends `RuntimeException`. It is not caught on the way out of `LoggerContext.setConfiguration` (a `try` with only a `finally`), which `reconfigure` also calls, nor in `AbstractConfiguration.start()`, which calls `appender.start();` in a loop, nor in `Log4jContextFactory.getContext`, which calls `ctx.start()` (read from source, not run):

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/LoggerContext.java
>             config.start();

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/config/AbstractConfiguration.java
>             appender.start();

Whether it reaches the application depends on the entry point. Automatic configuration goes through `LogManager.getLogger` and then `getContext`, which catches only `IllegalStateException`, so by this reading the exception reaches the first caller of `LogManager.getLogger`:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-api/src/main/java/org/apache/logging/log4j/LogManager.java
>         } catch (final IllegalStateException ex) {
>             LOGGER.warn("{} Using SimpleLogger", ex.getMessage());

`Configurator.initialize`, the programmatic entry point, catches it, logs it to the status logger and returns `null` to its caller in place of the `LoggerContext`:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/config/Configurator.java
>         } catch (final Exception ex) {
>             LOGGER.error(
>                     "There was a problem initializing the LoggerContext using configuration {}",
>                     configuration.getName(),
>                     ex);
>         }
>         return null;

The overloads that take a configuration location document the `null`:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/config/Configurator.java
>      * @return The LoggerContext or null if an error occurred (check the status logger).

*Serving path, failure.* `AppenderControl` catches every `RuntimeException` from `append` and rethrows only when `ignoreExceptions` is `false` (default `true`); that includes the `IllegalStateException` a stopped `AsyncAppender` throws:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/pages/manual/appenders.adoc
> If `false` logging exceptions will be forwarded to the caller.
> Otherwise, they will be logged using xref:manual/status-logger.adoc[].

*Serving path, blocking.* `AsyncAppender` blocks by default (`blocking=true`), and its wait (`queue.put`) has no timeout. With `blocking=false`, a full queue goes to the optional `errorRef` appender and is otherwise ignored.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/pages/manual/appenders/delegating.adoc
> If `true`, the Appender will wait until there are free slots in the queue.

The queue-full policy (`log4j2.asyncQueueFullPolicy`), shared with the async loggers, also blocks by default; `Discard` drops events at or below a threshold level (`INFO`). The default policy itself logs on the caller's thread instead only when the caller is Log4j's own thread, to avoid deadlock (comment citing LOG4J2-471). Before it consults the policy, a blocking `AsyncAppender` whose queue is full checks the calling thread's depth of nested logging calls (`AbstractLogger.getRecursionDepth`, "the depth of nested logging calls in the current Thread"). The async loggers' path was not read for this. Read from source, not run, a nested call is logged on the caller's thread, whichever thread that is:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/log4j-core/src/main/java/org/apache/logging/log4j/core/appender/AsyncAppender.java
>         if (!transfer(memento)) {
>             if (blocking) {
>                 if (AbstractLogger.getRecursionDepth() > 1) { // LOG4J2-1518, LOG4J2-2031
>                     // If queue is full AND we are in a recursive call, call appender directly to prevent deadlock
>                     AsyncQueueFullMessageUtil.logWarningToStatusLogger();
>                     logMessageInCurrentThread(logEvent);

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/partials/manual/systemproperties/properties-async.adoc
> Default:: blocks the calling thread until the event can be added to the queue.

The default queue size is 1024 in the source (`DEFAULT_QUEUE_SIZE`), while the deprecated factory's javadoc still says 128: source and javadoc disagree.

**The stated why**

The project manual (async trade-offs page; no individual author named), on why async errors stay off the caller, recommending synchronous logging where the caller must know, and stating the consequence of the blocking default without defending it:

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/partials/manual/async-trade-offs.adoc
> If a problem happens during the logging process and an exception is thrown, it is less easy for an asynchronous setting to signal this problem to the application.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/partials/manual/async-trade-offs.adoc
> If logging is part of your business logic, e.g. you are using Log4j as an audit logging framework, we would recommend to synchronously log those audit messages.

Source: https://github.com/apache/logging-log4j2/blob/rel/2.26.1/src/site/antora/modules/ROOT/partials/manual/async-trade-offs.adoc
> If the _sustained rate_ at which your application is logging messages is faster than the maximum sustained throughput of the underlying appender, the queue will fill up and the application will end up logging at the speed of the slowest appender.

**Inferred**

Inferred: by blocking and swallowing appender exceptions by default, Log4j puts not losing events ahead of caller latency, and caller isolation ahead of signalling faults. The project does not state this as one principle.

**No stated rationale found**

For default `blocking=true`, the `Default` queue-full policy and default `ignoreExceptions=true`: none in the pinned `appenders.adoc`, `appenders/delegating.adoc`, `async.adoc`, the partials `async-trade-offs.adoc`, `properties-async.adoc`, `properties-async-logger.adoc`, or the javadoc of `AsyncQueueFullPolicyFactory` and `DefaultAsyncQueueFullPolicy`.

**Constraints**

In the application's JVM; async loggers use an LMAX Disruptor ring buffer, `AsyncAppender` a `BlockingQueue`; the status logger lets it report its own failures without throwing.

**Costs and dissent**

The deadlock fixes named in the source (LOG4J2-471, LOG4J2-1518, LOG4J2-2031) show the blocking default has had to be special-cased. `properties-async-logger.adoc` records excessive CPU use with Disruptor v3.4.2 when the ring buffer was full. Logback (E2) drops low-level events instead.

**Unverified**

Whether the `ConfigurationException` from `AsyncAppender.start()` reaches the application was traced from the code, not run: `AbstractConfiguration.start()`, `LoggerContext.setConfiguration` (a `try` with only a `finally`), `LoggerContext.reconfigure` and `Log4jContextFactory.getContext` have no `catch`; `LogManager.getContext` catches only `IllegalStateException`; `Configurator.initialize` catches `Exception` and status-logs it. The LOG4J2-471, -1518 and -2031 Jira threads were not read.

### E2. Logback (1.6.8)

Java logging framework, here for `AsyncAppender`. Tag `v_1.6.8` (latest 1.x); the manual, in untagged `qos-ch/logback-site`, pinned to commit `c83ed2a6d41801394f42f4bbd485374598c36486` (2026-11-13), not to `v_1.6.8`. Read 2026-11-24.

**What it does**

*Set-up.* Depends on the path. Automatic configuration from the class path catches `JoranException` and prints it:

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-classic/src/main/java/ch/qos/logback/classic/util/DefaultJoranConfigurator.java
>             } catch (JoranException e) {
>                 e.printStackTrace();
>             }
>             // You tried and that counts Mary.

An explicit `doConfigure` throws, for example when the URL cannot be opened:

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/joran/GenericXMLConfigurator.java
>             addError(errMsg, ioe);
>             throw new JoranException(errMsg, ioe);

A `SAXException` thrown by the XML parser also becomes a `JoranException`. The recorder's own SAX error handlers only record errors and do not throw, so which malformed documents reach this branch depends on the parser (read from source, not run):

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/joran/event/SaxEventRecorder.java
>         } catch (SAXException se) {
>             // Exception added into StatusManager via Sax error handling. No need to add it again
>             throw new JoranException("Problem parsing XML document. See previously reported errors.", se);

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/joran/event/SaxEventRecorder.java
>     public void fatalError(SAXParseException spe) throws SAXException {
>         addError(XML_PARSING + " - Parsing fatal error on line " + spe.getLineNumber() + " and column " + spe.getColumnNumber());
>         addError(spe.toString());
>     }

Warnings and errors while the file is processed are printed as status data (`configuration.html`). An `AsyncAppender` with no attached appender or a bad queue size records an error and returns without starting.

*Serving path, failure.* `doAppend` catches every `Exception` into a status; appending to a non-started appender is a `WarnStatus`, not an exception:

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/UnsynchronizedAppenderBase.java
>         } catch (Exception e) {
>             if (exceptionGuard.allow()) {
>                 addError("Appender [" + name + "] failed to append.", e);

*Serving path, blocking.* Lossy and blocking by default. With less than 20% of the queue free (`discardingThreshold = queueSize / 5`; default queue 256), events at `INFO` or below are dropped silently:

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-classic/src/main/java/ch/qos/logback/classic/AsyncAppender.java
>      * Events of level TRACE, DEBUG and INFO are deemed to be discardable.

Other events block on a full queue without a bound, unless `neverBlock` (default `false`) makes `offer` drop them, uncounted:

Source: https://github.com/qos-ch/logback/blob/v_1.6.8/logback-core/src/main/java/ch/qos/logback/core/AsyncAppenderBase.java
>         if (neverBlock) {
>             blockingQueue.offer(eventObject);
>         } else {
>             putUninterruptibly(eventObject);

**The stated why**

The Logback manual (no individual author named), on the lossy default and in defence of blocking what is not dropped. (Both matched with whitespace collapsed: they span lines of the HTML source.)

Source: https://github.com/qos-ch/logback-site/blob/c83ed2a6d41801394f42f4bbd485374598c36486/src/site/pages2/manual/appenders-async-sift.html
> and INFO if its queue is 80% full. This strategy has an amazingly
> favorable effect on performance at the cost of event loss.

Source: https://github.com/qos-ch/logback-site/blob/c83ed2a6d41801394f42f4bbd485374598c36486/src/site/pages2/manual/appenders-async-sift.html
> therefore becomes pseudo-synchronous when the appender is
> operating at or near the capacity of its event buffer. This is not
> necessarily a bad thing. The appender is designed to allow the
> application to keep on running, albeit taking slightly more time
> to log events until the pressure on the appenders buffer eases.

(Line breaks collapsed: the page's HTML wraps the sentence differently.)

GitHub user `ceki` (association `MEMBER`), on why `neverBlock` exists beside the threshold:

Source: https://github.com/qos-ch/logback/issues/290#issuecomment-826383485
> However, you may have a situation where the rate of arrival of non-discardable events (e.g. of level ERROR) is higher than the rate of service such that the buffer is full. In such a case, setting neverBlock to true can make sense.

Jira user `jeff.wartes` (Jeff Wartes, the reporter of LOGBACK-898, whose comment on it attached the original patch; his role beyond that not checked), opening the issue on 2013-08-30, on why `neverBlock` was wanted. The issue is resolved "Fixed" for 1.1.5 by applying PR 290. Jira pages are unpinnable: this was read as of 2026-11-24 through Jira's REST API.

Source: https://jira.qos.ch/rest/api/2/issue/LOGBACK-898
> Sometimes the application being responsive is categorically more important than writing logs. The discardingThreshold is a great nod to that, but it would be nice to offer an assurance that log statements will never block, even if you are throwing errors left and right and your disk has gone read-only.

**Inferred**

None.

**No stated rationale found**

Not applicable for the drop-or-block defaults. For catching `JoranException` in automatic configuration, only the behaviour and the comment "You tried and that counts Mary." (`DefaultJoranConfigurator.java`, pinned `configuration.html`).

**Constraints**

In the application's JVM; reports its own failures to an internal status manager. `neverBlock` arrived as a patch carried from the LOGBACK-898 Jira in a pull request (#290) by a user (`tempredirect`, `NONE`).

**Costs and dissent**

Dropped events are not counted; an open pull request (#905) by a user (`tommyulfsparre`, `NONE`) proposes counters. Log4j 2 chose the opposite default (E1).

**Unverified**

Whether status messages print for errors after configuration was not checked. Nor was which malformed documents make the parser throw `SAXException` (and so make `doConfigure` throw), rather than only report through the recorder's error handlers. Nor was whether errors in a well-formed configuration's content (for example an unknown element) make `doConfigure` throw. LOGBACK-898 was read as of 2026-11-24 through `https://jira.qos.ch/rest/api/2/issue/LOGBACK-898`; its `browse` page also opened.

### E3. Python standard library `logging` (CPython 3.15.2)

Posture facts only; the package is covered in full in B1, at the same tag, `v3.15.2`. Read 2026-11-24.

**What it does**

*Set-up.* `dictConfig` raises; `fileConfig` raises `FileNotFoundError` for a missing file and `RuntimeError` for an invalid or empty one. A handler's own constructor can be quiet. `SysLogHandler.__init__` ignores `socket.gaierror` from `createSocket`, and `createSocket` ignores `OSError` when it connects to a Unix-socket address. So a syslog daemon that is not listening on a Unix socket, or a host name that does not resolve, raises nothing at set-up, while a TCP connection failure to a resolved host still raises (handlers.py 886–890, 927–960; read from source, not run).

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py#L886-L890
>         # The address is resolved again when emitting an event.
>         try:
>             self.createSocket()
>         except socket.gaierror:
>             pass

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.config.rst
>    If an error is encountered during configuration, this function will
>    raise a :exc:`ValueError`, :exc:`TypeError`, :exc:`AttributeError`
>    or :exc:`ImportError` with a suitably descriptive message.

*Serving path, failure.* Errors inside a standard handler's `emit` go to `handleError` (B1 gives three exceptions: `MemoryHandler`, whose `emit` and `flush` hand records to the target's `handle` without a `try`; a `RecursionError` from `StreamHandler.emit`, which re-raises it, also through `FileHandler` and `WatchedFileHandler`; and `SocketHandler`, which drops its own socket errors without calling `handleError`), which by default (`raiseExceptions = True`) prints a traceback to stderr and returns, without re-raising; with `raiseExceptions=False` it is silent. Not every error goes there: an `extra` key that collides with a `LogRecord` attribute raises `KeyError`, and an exception in a filter propagates (B1). At the earlier tag `v3.14.0`, `FileHandler` opening a delayed file and `WatchedFileHandler` reopening one ran outside `emit`'s `try`, so an `OSError` reached the caller; `v3.15.2` routes both to `handleError`. The module comment says such exceptions "should be propagated", but the code only prints: comment and code disagree. `Logger.log` with a non-integer level does raise by default:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py
>         if not isinstance(level, int):
>             if raiseExceptions:
>                 raise TypeError("level must be an integer")

*Serving path, blocking.* Handlers run in the caller's thread under the handler's lock:

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/__init__.py
>         Wrap the actual emission of the record with acquisition/release of
>         the I/O thread lock.

The documentation offers `QueueHandler` to move slow work off-thread. It never waits for queue space: a full bounded queue raises `queue.Full` into `handleError`, and the queue `dictConfig` builds is unbounded (`queue.Queue()`). The enqueue still takes the queue's lock for the size check and the append, and the docs warn of a deadlock when a `multiprocessing.Queue` logs through a `QueueHandler` on that same queue (B1).

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>         The base implementation uses put_nowait. You may want to override
>         this method if you want to use blocking, timeouts or custom queue
>         implementations.

**The stated why**

The Logging HOWTO, whose named author is Vinay Sajip (`:Author:` line; maintainer role not verified):

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging.rst
> The logging package is designed to swallow exceptions which occur while logging
> in production. This is so that errors which occur while handling logging events
> - such as logging misconfiguration, network or other similar errors - do not
> cause the application using logging to terminate prematurely.

The HOWTO also explains the `True` default of `raiseExceptions` as serving development, and advises `False` in production; the `handleError` docstring (no named author) says most users care about application errors, not errors in logging. Both are quoted in B1.

Why `SysLogHandler` is quiet at set-up: its `createSocket` docstring, and the comment above its Unix-socket branch (author not traced):

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py#L918-L922
>         Try to create a socket and, if it's not a datagram socket, connect it
>         to the other end. This method is called during handler initialization,
>         but it's not regarded as an error if the other end isn't listening yet
>         --- the method will be called again when emitting an event,
>         if there is no socket at that point.

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py#L929-L932
>             # Syslog server may be unavailable during handler initialisation.
>             # C's openlog() function also ignores connection errors.
>             # Moreover, we ignore these errors while logging, so it's not worse
>             # to ignore it also here.

**Inferred**

None.

**No stated rationale found**

For running handlers synchronously by default: none in the pinned `Doc/howto/logging.rst`, `Doc/library/logging.handlers.rst` or the `Handler.handle` docstring; the `QueueHandler` text explains moving off-thread, not the on-thread default. Also read, as of 2026-11-24, the Discourse thread "Dealing with unbounded recursion in logging handlers" (2025, https://discuss.python.org/t/dealing-with-unbounded-recursion-in-logging-handlers/86365, all 18 posts). Its opener, Duane Griffin (no core-developer title shown), calls the module "synchronous by design" and gives no reason for that choice. The maintainer's one post there (#18) is on another point.

**Constraints**

In-process and synchronous unless the user wires a `QueueHandler` and `QueueListener`; `raiseExceptions` is a module global, shared by the whole interpreter.

**Costs and dissent**

The comment-versus-behaviour mismatch is a documentation cost. Most other libraries here emit off the caller's thread by default (E9 to E14).

**Unverified**

CPython issue 13807, cited by the source, not read.

### E4. Kafka Java producer (4.4.0)

A messaging client, not an observability library, included because the leads named it. Tag `4.4.0` (highest release tag in `git ls-remote`). Read 2026-11-24.

**What it does**

*Set-up.* Any constructor failure is rethrown:

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/KafkaProducer.java
>             throw new KafkaException("Failed to construct kafka producer", t);

*Serving path, failure.* `send` throws directly: `IllegalStateException` (closed producer, or a `transactional.id` with no transaction), `SerializationException`, `InterruptException` and other `KafkaException`s. API errors come back through the `Future` and callback:

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/KafkaProducer.java
>             // for API exceptions return them in the future,
>             // for other exceptions throw directly

*Serving path, blocking.* `send` is documented as asynchronous but blocks, on an exhausted buffer or missing metadata, for up to `max.block.ms` (default `60 * 1000`; configurable, 0 allowed):

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerConfig.java
> "For <code>send()</code> this timeout bounds the total time waiting for both metadata fetch and buffer allocation "

Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/ProducerConfig.java
>                                                     + "(blocking in the user-supplied serializers or partitioner is not counted against this timeout). "

**The stated why**

KIP-19, status Accepted (Confluence page version 36, not pinnable further; history names Jiangjie Qin as creator and Mayuresh Gharat as last editor, roles not verified). Bounded, not zero, blocking was a goal:

Source: https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=55154824
> Have bounded blocking time for send() - user should be able to have a bounded blocking time when they call send()

**Inferred**

Inferred: without the partition layout the producer cannot batch a record, so without metadata it must block, fail or queue elsewhere. A KAFKA-3539 commenter (Radai Rosenblatt, role not verified) describes this; not quoted, and not a maintainer's statement.

**No stated rationale found**

For keeping any blocking in `send` rather than failing fast or queueing: no maintainer's statement in KIP-19 (version 36) or the description and all 21 comments of KAFKA-3539.

**Constraints**

In-process with a background I/O thread, buffering per partition up to `buffer.memory` (32 MiB default). Its guarantees concern delivery (`acks`, retries, idempotence), so dropping on overflow is not one of its modes.

**Costs and dissent**

KAFKA-3539, opened by Oleg Zhurakousky (reporter; role not verified), is still In Progress, unresolved:

Source: https://issues.apache.org/jira/browse/KAFKA-3539
> The bottom line is that method that returns Future must never block, since it essentially violates the Future contract as it was specifically designed to return immediately passing control back to the user to check for completion, cancel etc.

Other users there (roles not verified) say the API misleads readers into expecting no blocking, and prefer a more intuitive API to better documentation. Spyridon Ninos (role not verified) argued against treating it as critical:

Source: https://issues.apache.org/jira/browse/KAFKA-3539
> indeed the producer does not comply with the Future contract, however I'm not sure that this should be considered critical because it violates the contract only when the system has issues (i.e. the producer cannot communicate with the cluster).

The thread links KIP-739 as an attempted fix (not read).

**Unverified**

The roles of everyone named in KIP-19 and KAFKA-3539; whether KIP-739 was adopted.

### E5. Micrometer (1.18.0)

Java metrics facade over many backends. Tag `v1.18.0`. Read 2026-11-24.

**What it does**

*Set-up and registration.* Meters are usually registered lazily, often per event (`registry.counter(name, tags)` returns "A new or existing counter"), so registration posture applies to the serving path too. A meter whose ID is already registered as another meter type throws `IllegalArgumentException`. The ID is the name and the tags, as any meter filter maps them, so in the core registry the same name with different tags is a separate meter (read from source, not run):

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java
>                     format("There is already a registered meter of a different type (%s vs. %s) with the same name: %s",

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/Meter.java
>             return name.equals(meterId.name) && tags.equals(meterId.tags);

The Prometheus registry turns its own registration failures into a log line (warn once, then debug) and a listener callback, without throwing; throwing is opt-in (`throwExceptionOnRegistrationFailure()`). So since 1.6:

Source: https://github.com/micrometer-metrics/micrometer/issues/2068
> Previously, `PrometheusMeterRegistry` threw an `IllegalArgumentException`. Now, we'll _not_ throw an exception but instead silently continue, but inform any callbacks registered that this `Meter.Id` could not be registered.

In 1.18.0 two conflicts that used to pass registration and then fail every later scrape are caught at registration instead. The first is a duplicate Prometheus family name. The second is meters of the same name whose histogram configuration gives them different Prometheus family types: `SUMMARY` without histogram buckets, `HISTOGRAM` with them. By default the conflict is logged, and the conflicting meter is not exposed through any registered Prometheus collector, so scrapes omit it. The guide's words are "discarded" and "ignored". Read from source, not run, the registry still creates the meter, returns it to the caller and keeps it in its meter map. The migration guide is a wiki page, pinned to its revision `8f46ab2`; it is checked as HTML, so its inline code appears without backticks. The earlier behaviour:

Source: https://github.com/micrometer-metrics/micrometer/wiki/1.18-Migration-Guide/8f46ab2ad0e7040ce0ba82d43fa89fe8751a9fae
> Previously, if different meters mapped to the same Prometheus metric family name (for example, registering a Timer("test") which generates test_seconds_max along with a separate Gauge("test_seconds_max")), both meters were accepted at registration time, but subsequent calls to scrape() would fail with a DuplicateLabelsException.

The 1.18 behaviour, in the guide's words: first for a duplicate family name, then the rule the histogram check enforces:

Source: https://github.com/micrometer-metrics/micrometer/wiki/1.18-Migration-Guide/8f46ab2ad0e7040ce0ba82d43fa89fe8751a9fae
> By default, the duplicate meter registration fails gracefully: a warning is logged and the duplicate meter is discarded. Subsequent scrapes succeed and export only the originally registered meter's metrics.

Source: https://github.com/micrometer-metrics/micrometer/wiki/1.18-Migration-Guide/8f46ab2ad0e7040ce0ba82d43fa89fe8751a9fae
> In Prometheus, all time series sharing the same metric name must produce the same metric family type.

The check compares family types, not configurations (read from source, not run):

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/implementations/micrometer-registry-prometheus/src/main/java/io/micrometer/prometheusmetrics/MicrometerCollector.java
>      * Fails instead of failing later on scrape if the family was already registered with
>      * a different type, e.g. when only some meters with the same name publish histogram
>      * buckets.

The Prometheus registry's factories still return the meter (the timer factory shown), and the core registry stores it after creating it:

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/implementations/micrometer-registry-prometheus/src/main/java/io/micrometer/prometheusmetrics/PrometheusMeterRegistry.java
>         applyToCollector(id, (collector, context) -> collector.addTimer(context, timer));
>         return timer;

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java
>                     meterMap.put(mappedId, m);

*Serving path.* `CumulativeCounter.increment` is a `DoubleAdder.add` (`value.add(amount)`). A lookup that finds an existing meter returns without entering the registry's `synchronized (meterMapLock)` block. A first registration takes the registry's single `meterMapLock` and holds it while it creates the meter and runs every meter-added listener. For the Prometheus registry, creating the meter includes adding it to its collector. A first use can therefore wait for that lock, or run application listener code while holding it. How long either takes was not measured (read from source, not run):

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java
>             synchronized (meterMapLock) {

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java
>                     m = meterSupplier.create(this, mappedId, config, specificPauseDetector);

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java
>                     for (Consumer<Meter> onAdd : meterAddedListeners) {
>                         onAdd.accept(m);
>                     }
>                     meterMap.put(mappedId, m);

**The stated why**

GitHub user `jkschneider` (association `CONTRIBUTOR` as fetched), in #2068, which introduced the listener:

Source: https://github.com/micrometer-metrics/micrometer/issues/2068
> This is mainly driven by the significant burden Prometheus' requirement places on everyone for the same metric name to have the same set of tags.

Source: https://github.com/micrometer-metrics/micrometer/issues/2068
> In this way, the user can do whatever they'd like with these problems, including logging or propagating a hard failure if they choose.

The 1.18 migration guide, last revised by Tommy Ludwig (`shakuzen`, the `MEMBER` quoted next), on the 1.18 default for a conflicting meter:

Source: https://github.com/micrometer-metrics/micrometer/wiki/1.18-Migration-Guide/8f46ab2ad0e7040ce0ba82d43fa89fe8751a9fae
> Default behavior: A warning log explains that meters with the same name must produce the same family type (e.g. SUMMARY vs HISTOGRAM). The conflicting meter is ignored, preventing the scrape endpoint from failing.

GitHub user `shakuzen` (association `MEMBER`), on why the failure is not even logged by default:

Source: https://github.com/micrometer-metrics/micrometer/issues/5228#issuecomment-2212811290
> it's important to balance this with the principle that observability impact to your application should be minimal - I think this includes avoiding logging too much. It's better to lose some observability info than cause issues for the application.

The compromise shipped is the warn-then-debug logger, in the Prometheus registry only.

**Inferred**

None.

**No stated rationale found**

For keeping the type-clash `IllegalArgumentException` while softening the Prometheus registry: none in #2068, #5228, #877 and their comments, or the `MeterRegistry` javadoc.

**Constraints**

Some backends (such as the Prometheus Java client) have hard validation rules. The stated reason for silencing failures is the third-party-library case: instrumentation the application's developers do not control.

**Costs and dissent**

A reversal: the Prometheus registry threw before 1.6. A contributor (`izeye`, `CONTRIBUTOR`):

Source: https://github.com/micrometer-metrics/micrometer/issues/5228
> A meter registration failure seems to be an important event for users, but it's not easy for the users to be aware of the failure unless they register a callback for it.

A maintainer says (#877) the same-tag-keys restriction that drove all this was removed from `PrometheusMeterRegistry` in 1.17.

**Unverified**

How long a first registration waits for or holds the registry lock (scope read from source, timing not measured); push registries' publish errors; the roles of `jkschneider` and `shakuzen` beyond GitHub's associations.

### E6. Prometheus `prometheus_client` for Python (0.26.0)

The official Prometheus client for Python (pull model). Tag `v0.26.0`. Read 2026-11-24.

**What it does**

*Set-up.* A collector whose time series duplicate an existing one raises `DuplicateTimeseries`; a bad name raises `ValueError`.

*Serving path, failure.* `labels()` raises on a wrong label count or names, `inc()` on a negative amount, and a labelled metric used without labels raises `ValueError`:

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/metrics.py
>                 raise ValueError('Incorrect label count')

*Serving path, blocking.* In the default in-process mode, child lookup takes a lock (`with self._lock:`) and there is no I/O, since exposition happens at scrape time. In multiprocess mode, chosen by `PROMETHEUS_MULTIPROC_DIR` (`if 'prometheus_multiproc_dir' in os.environ or 'PROMETHEUS_MULTIPROC_DIR' in os.environ:`, `values.py`), every value shares one process-wide lock and every update, not only the first use, writes to a memory-mapped file. Creating a value (on a label combination's first use) can open a per-process file, which growing the map truncates to a larger size, and after a fork `__check_for_pid_change` closes every file and resets every value, so all the files are reopened (read from source, not run):

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/values.py
>                 files[file_prefix] = MmapedDict(filename)

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/mmap_dict.py
>         self._f = open(filename, 'rb' if read_mode else 'a+b')

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/values.py
>         def inc(self, amount):
>             with lock:
>                 self.__check_for_pid_change()
>                 self._value += amount
>                 self._timestamp = 0.0
>                 self._file.write_value(self._key, self._value, self._timestamp)

**The stated why**

The Prometheus "Writing client libraries" guidelines (prometheus/docs commit `31957d4`; no individual author) require the negative-increment check:

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md
> * `inc(double v)`: Increment the counter by the given amount. MUST check that v >= 0.

and recommend avoiding blocking:

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md
> Metrics SHOULD avoid blocking when they are being incremented/decremented/set
> etc. as it’s undesirable for the whole application to be held up while a scrape
> is ongoing.

**Inferred**

None.

**No stated rationale found**

For raising, rather than ignoring, on a wrong label count: none in the guidelines ("Labels" and "Counter" say what to validate, not how to report it), the `labels()` source, or the 23 titles from the issue search `repo:prometheus/client_python labels ValueError raise` (bodies not read).

**Constraints**

Pull model: a scrape collects the values, so the serving path sends nothing. In the default in-process mode the serving path only updates in-memory values; in multiprocess mode every update also writes to a memory-mapped file, and a value's first use can open or grow one (see What it does, where the update's write is quoted). Growing the map truncates the file to a larger size:

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/mmap_dict.py
>             self._f.truncate(self._capacity)

**Costs and dissent**

`client_golang` panics where this raises (E7); Micrometer softened the equivalent failure (E5).

**Unverified**

Whether its `Lock` is a plain or a re-entrant lock at this version.

### E7. Prometheus `client_golang` (1.25.0)

The official Prometheus client for Go. Tag `v1.25.0`. Read 2026-11-24.

**What it does**

*Set-up.* `MustRegister` panics; `Register` returns an `error`:

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/registry.go
> // MustRegister registers the provided Collectors with the DefaultRegisterer and
> // panics if any error occurs.

*Serving path, failure.* `WithLabelValues` panics where `GetMetricWithLabelValues` returns an error, and `Counter.Add` panics on a negative value:

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go
> // WithLabelValues works as GetMetricWithLabelValues, but panics where
> // GetMetricWithLabelValues would have returned an error. Not returning an
> // error allows shortcuts like

*Serving path, blocking.* Lookup takes the vector's read-write lock, and at v1.25.0 `metricMap.Collect` holds the read lock while sending every child on the gather channel. A contributor (`lif0`, `CONTRIBUTOR`) reported, in a closed issue, every request blocking behind a stuck scrape:

Source: https://github.com/prometheus/client_golang/issues/2147
> 2. sync.RWMutex does not let new readers in while a writer waits and so every WithLabelValues on this vec blocks from now on

The fix, PR #2157, merged 2026-10-14, after the v1.25.0 tag's commit (2026-10-08), so it is not in v1.25.0.

**The stated why**

The package documentation (no named author), on surfacing errors at registration:

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/doc.go
> // Inconsistencies are ideally detected at registration time, not at collect
> // time. The former will usually be detected at start-up time of a program,
> // while the latter will only happen at scrape time, possibly not even on the
> // first scrape if the inconsistency only becomes relevant later.

GitHub user `beorn7` (association `CONTRIBUTOR`; writes "I used to be the maintainer of this repo" in the same thread):

Source: https://github.com/prometheus/client_golang/issues/715
> Whoever doesn't care about panicking, can and should use `promauto` constructors, no matter if they want the local or the global registry.

The `WithLabelValues` comment gives the reason for panicking: "Not returning an error allows shortcuts like" chained calls.

**Inferred**

None.

**No stated rationale found**

Not applicable.

**Constraints**

Pull model, as E6. Panicking and error-returning variants exist for both registration and label lookup.

**Costs and dissent**

Issue #715 (eliminate `MustRegister`) was closed by the stale bot without action. #2147 shows the serving call can block. `prometheus_client` raises instead (E6).

**Unverified**

Whether PR #2157 has since been released; whether a slow, not stuck, `Write` causes noticeable latency (the reporter's figures not checked).

### E8. `pystatsd` (4.0.1)

A StatsD client for Python. Tag `v4.0.1`. Read 2026-11-24.

**What it does**

*Set-up.* The UDP client resolves the host in its constructor, so resolution failure raises there:

Source: https://github.com/jsocol/pystatsd/blob/v4.0.1/statsd/client/udp.py
>         family, _, _, _, addr = socket.getaddrinfo(

*Serving path, UDP.* Socket errors are swallowed silently; the socket is a default blocking one, written in the caller's thread:

Source: https://github.com/jsocol/pystatsd/blob/v4.0.1/statsd/client/udp.py
>             self._sock.sendto(data.encode('ascii'), self._addr)
>         except (socket.error, RuntimeError):
>             # No time for love, Dr. Jones!
>             pass

On any transport, the timer helpers raise `RuntimeError` on misuse (`stop()` before `start()`).

*Serving path, TCP and Unix socket.* These raise, and default to `timeout=None`, so can block without a bound:

Source: https://github.com/jsocol/pystatsd/blob/v4.0.1/docs/tcp.rst
> * :py:meth:`connect() <TCPStatsClient.connect()>` and all methods that send
>   data can potentially raise socket exceptions.

**The stated why**

None found; see below.

**Inferred**

Inferred: StatsD over UDP is fire-and-forget, so dropping on error matches the transport, while TCP failures are ones a caller may want to handle. No author states this.

**No stated rationale found**

All ten files under `docs/` at `v4.0.1` were grepped for error, exception, fail, block, drop and lost; the hits describe behaviour or unrelated things (`tags.rst` "To avoid silently failing" is about an API break for tagged metrics). The only text near the UDP `except` is the joke comment.

**Constraints**

No background thread or queue: every call is a direct socket write.

**Costs and dissent**

One library ships opposite serving postures (swallow on UDP, raise on TCP and Unix). `cadence` returns a `Result` instead (E9).

**Unverified**

Whether UDP `sendto` ever blocks noticeably in practice.

### E9. `cadence` (1.8.0)

A StatsD client for Rust. Tag `1.8.0`. Read 2026-11-24.

**What it does**

*Set-up.* `UdpMetricSink::from` returns a `Result`:

Source: https://github.com/56quarters/cadence/blob/1.8.0/cadence/src/sinks/udp.rs
> /// An error is returned if the initial resolution of `addr` fails.

*Serving path, failure.* Plain metric calls return a `Result`; the builder's `.send()` routes errors to a handler that by default discards them:

Source: https://github.com/56quarters/cadence/blob/1.8.0/cadence/src/client.rs
>     fn count(&self, key: &str, count: T) -> MetricResult<Counter> {

Source: https://github.com/56quarters/cadence/blob/1.8.0/cadence/src/builder.rs
>     /// By default, if no handler is given, a "no-op" handler is used that
>     /// simply discards all errors.

*Serving path, blocking.* Socket blocking mode is the caller's choice (the documented examples call `set_nonblocking(true)`). `QueuingMetricSink` sends from a thread; its default queue is unbounded, and a bounded one makes writes fail, not block, until drained.

**The stated why**

The crate documentation (repository owner `56quarters`; lines not blamed), which adds that the trade-off is one users must decide for themselves:

Source: https://github.com/56quarters/cadence/blob/1.8.0/cadence/src/lib.rs
> //! Using a `QueuingMetricSink` with a capacity set means that when the queue
> //! is full, attempts to emit metrics via the `StatsdClient` will fail. While
> //! this is bad, the alternative (if you instead used an unbounded queue) is
> //! for unsent metrics to slowly use up more and more memory until your
> //! application exhausts all memory.

The `send`/`try_send` split came from issue #65, where the owner (`56quarters`, `OWNER`) agreed to an error handler:

Source: https://github.com/56quarters/cadence/issues/65#issuecomment-376358475
> I like the idea of some sort of error handler such that errors aren't completely ignored.

**Inferred**

None.

**No stated rationale found**

For the no-op default handler, when #65 proposed "defaulting to logging an error": none in #65's comments, `CHANGES.md` (entry v0.14.0), or the issue search `repo:56quarters/cadence error handler default` (#65, #66).

**Constraints**

Its only runtime dependency is `crossbeam-channel`; no logging crate. A v0.6.0 changelog entry records an earlier default change from blocking to non-blocking sockets (in the since-removed `from_udp_host`): callers that would have blocked get a `MetricError` with `WouldBlock`.

**Costs and dissent**

A contributor (`pjenvey`, `CONTRIBUTOR`) questioned returning a `Result` at all and suggested a logging default; the shipped default discards:

Source: https://github.com/56quarters/cadence/issues/65#issuecomment-376331042
> I'm wondering if it's the wrong default in the first place w/ the nature of metrics, do most users ignore send results?

Inferred (from `Result` being `#[must_use]`, not checked by compiling): ignoring `client.count(...)` draws the compiler's unused-`Result` warning.

**Unverified**

Whether `56quarters` wrote the trade-off text.

### E10. Sentry for Python (`sentry-sdk` 3.0.0)

An error and event shipper. Tag `3.0.0`; Sentry's SDK development guidelines at getsentry/sentry-docs `develop-docs`, commit `feaece2`. Read 2026-11-24.

**What it does**

*Set-up.* A malformed DSN raises `BadDsn` (a `ValueError`). It is parsed while `_init_impl` builds the transport, in a `try` with only a `finally`, so it reaches the caller of `init` (read from code, not run). Unknown options raise `TypeError`; an empty DSN is valid and makes the SDK a no-op.

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/utils.py
>             raise BadDsn("Missing public key")

*Serving path, failure.* `capture_event` returns an id or `None`; SDK-internal exceptions are logged:

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/utils.py
>     These exceptions do not end up in Sentry and are just logged instead.

*Serving path, blocking.* `put_nowait` onto a queue of `DEFAULT_QUEUE_SIZE = 100`; when full, the event is dropped and recorded lost:

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/transport.py
>         if not self._worker.submit(send_envelope_wrapper):
>             self.on_dropped_event("full_queue")
>             for item in envelope.items:
>                 self.record_lost_event("queue_overflow", item=item)

That covers a full queue only. Event processing runs first on the caller's thread, including any user `before_send` (`client.py` line 562):

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/client.py
>                     new_event = before_send(event, hint or {})

Before enqueueing, `submit` restarts a worker that is not alive (on the first submit, after `kill()`, in a forked child, or after the thread has died), under the lock `flush` holds while it waits, and spawns a thread; when the worker is alive, `submit` takes no lock. Python's `put` holds `self.not_full` only for a size check and the append, since `block=False` (read from source, not run):

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/worker.py
>     def submit(self, callback: "Callable[[], Any]") -> bool:
>         self._ensure_thread()

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/worker.py
>     def flush(self, timeout: float, callback: "Optional[Any]" = None) -> None:
>         logger.debug("background worker got flush request")
>         with self._lock:
>             if self.is_alive and timeout > 0.0:
>                 self._wait_flush(timeout, callback)

**The stated why**

Sentry's SDK development guidelines (project documentation; no individual author), which also permit the transport to discard on a missing DSN, a full queue or rate limiting:

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/getting-started/philosophy/index.mdx
> We never want our SDKs to be the cause of customer breakage.

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/getting-started/philosophy/index.mdx
> If this cannot be achieved we need to make sure that we inform the user ahead of time by alerting about such situations at installation time.

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/transport/index.mdx
> Envelopes **SHOULD** be transmitted in a background thread or equivalent asynchronous mechanism so that sending does not block the application.

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/client/index.mdx
> SDKs **MUST** accept an empty DSN as valid configuration.

**Inferred**

Inferred: the "inform the user ahead of time … at installation time" line is the closest stated support for failing loudly at set-up, but it is about platform support, not a malformed DSN.

**No stated rationale found**

For raising, rather than disabling, on a non-empty malformed DSN: none in the pinned `foundations/client/index.mdx` and `client/configuration/index.mdx` (empty DSN only), or the philosophy and principles pages.

**Constraints**

Push model with a background worker; events are best-effort, and loss is sent to the server as "client reports".

**Costs and dissent**

Rust's SDK panics for the same input (E11).

**Unverified**

None beyond the inference above.

### E11. Sentry for Rust (`sentry` 0.49.6)

Sentry's Rust SDK. Tag `0.49.6`. Read 2026-11-24.

**What it does**

*Set-up.* `init` panics on an invalid DSN (an `expect` in `clientoptions.rs`); an empty string converts to no DSN (`Ok(None)` in `intodsn.rs`) and disables the client:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/init.rs
> /// This will panic when the provided DSN is invalid.

*Serving path, failure.* `capture_event` has no error path:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/api.rs
> /// The return value is the event ID. If the event was discarded for any reason,
> /// return value will be the nil UUID (`Uuid::nil`).

The docs' "for any reason" is wider than the code: the transport's queue-overflow drop is recorded as a client report and does not change the returned ID. `capture_event` sets the ID inside the envelope builder, before the transport is called, and returns it whatever the transport does; the nil ID comes back only for discards before the envelope is built, such as `before_send` returning `None` or a client with no transport:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/mod.rs
>                 event_id = event.event_id;

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/transports/tokio_thread.rs
>                 TrySendError::Full(task) => (task, ClientReportReason::QueueOverflow),

*Serving path, blocking.* The transport uses `try_send` on a channel of `DEFAULT_CHANNEL_CAPACITY` 30, dropping and recording the loss when full. That covers a full queue only: `capture_event` first prepares the event on the caller's thread, inside the closure that `send_envelope_with` runs while it holds the transport slot's read lock. That runs the application's `before_send` callback, and in application session mode it takes a session mutex (`.lock().unwrap()`). A grep of `client/mod.rs` finds no `catch_unwind`; other files were not searched. `shutdown` takes the write lock only for `.take()`, and the guard is released before `transport.shutdown(timeout)` (read from source, not run):

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/mod.rs
>         if let Some(ref func) = self.options.before_send {
>             sentry_debug!("invoking before_send callback");
>             let id = event.event_id;
>             if let Some(processed_event) = func(event) {

**The stated why**

A transport source comment (author not blamed); the cross-SDK guidelines in E10 apply too:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/transports/tokio_thread.rs
>         // Using send here would mean that when the channel fills up for whatever
>         // reason, trying to send an envelope would block everything. We'd rather
>         // drop the envelope in that case.

**Inferred**

None.

**No stated rationale found**

For panicking rather than returning a `Result` on an invalid DSN: none in the `init` docs or the `From` impls in `clientoptions.rs`, which point to `parse` for callers who want the error without saying why `init` panics.

**Constraints**

As E10. The DSN usually arrives through `IntoDsn` conversions, which have no error channel in `From`.

**Costs and dissent**

Python's SDK raises a catchable exception for the same input (E10).

**Unverified**

None. The transport thread is settled: the default transport (`ReqwestHttpTransport`, G2) uses `tokio_thread.rs`, quoted above, whose `try_send` and drop path match `thread.rs`.

### E12. `tracing-appender` with `tracing-subscriber` (0.2.5; subscriber 0.3.23)

Rust's non-blocking log writer for `tracing`. Tags `tracing-appender-0.2.5` and `tracing-subscriber-0.3.23`. Read 2026-11-24.

**What it does**

*Set-up.* Loud, except for one misuse in release builds. `RollingFileAppender::new` panics and the builder returns a `Result`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/rolling.rs
>     /// Unlike [`RollingFileAppender::new`], the [`Builder::build`] method
>     /// returns a `Result` rather than panicking when the appender cannot be
>     /// initialized.

Spawning the worker panics on failure (`.expect`); the subscriber's `init` panics (for example when a global subscriber is already installed) while `try_init` returns an error. `with_ansi(true)` without the `ansi` feature panics only in debug builds (`eprintln!` otherwise, lines 331 to 340).

*Serving path, failure.* In lossy mode a write always reports success, and a dropped line only increments a counter:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs
>             if self.channel.try_send(Msg::Line(buf.to_vec())).is_err() {
>                 self.error_counter.incr_saturating();

The worker ignores I/O errors (a TODO comment proposes a metric or stderr). The fmt layer prints a failed event write to stderr rather than returning it, when `log_internal_errors` is on, its documented default.

*Serving path, blocking.* Lossy by default (`DEFAULT_BUFFERED_LINES_LIMIT` 128,000); non-lossy mode blocks the caller:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs
>     /// By default, the built `NonBlocking` will be lossy.

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs
> /// If [`NonBlocking`] is _not_ lossy, backpressure will be exerted on
> /// senders, causing them to block their respective threads until there
> /// is available capacity.

**The stated why**

In the review of PR #673, which introduced the writer, a reviewer (`Matthias247`, association `NONE`; not a maintainer) asked for the blocking option:

Source: https://github.com/tokio-rs/tracing/pull/673#discussion_r406398194
> maybe make the lossy property an option. Many programs can not afford to loose logs, and would rather slow down the producer (by blocking on the channel).

GitHub user `hawkw` (association `MEMBER`) agreed and accepted the name "non-blocking" for the blocking mode:

Source: https://github.com/tokio-rs/tracing/pull/673#discussion_r406847214
> That makes me wonder if "non-blocking" is really the right name for this type. But, we are still not blocking senders on _IO_, so maybe it's okay (and, if backpressure is enabled, the _happy_ path is still non-blocking)...

**Inferred**

None.

**No stated rationale found**

For lossy as the *default*: none in PR #673 and all its review comments, issue #2865 and its comments, `CHANGELOG.md`, or the 11 titles of the search `repo:tokio-rs/tracing lossy non_blocking`. The contributed implementation was lossy and the option was added in review; nobody argued for the default.

**Constraints**

In-process, one worker thread fed by a crossbeam channel; dropping the `WorkerGuard` asks the worker to drain and flush, waiting at most about 1.1 s without joining (G1).

**Costs and dissent**

A user (`f1recracker`, `NONE`) in #2865; a maintainer replied that the behaviour should be documented more clearly, not changed:

Source: https://github.com/tokio-rs/tracing/issues/2865
> Silently, losing logs in a production environment is hard to diagnose, and should not be a default.

**Unverified**

None. A2 names `hawkw` as Eliza Weisman, the first listed author of `tracing`.

### E13. `slog-async` with `slog` (2.8.0; slog 2.8.2)

Rust's asynchronous drain for `slog`. Tags `v2.8.0` (slog-rs/async) and `v2.8.2` (slog). Read 2026-11-24.

**What it does**

*Set-up.* The builder `unwrap`s the worker spawn, so failure panics (`lib.rs` line 319). The channel holds 128 records by default (`chan_size`).

*Serving path, failure.* `Async` absorbs `Full` but returns `Fatal` on mutex or channel poisoning:

Source: https://github.com/slog-rs/async/blob/v2.8.0/lib.rs
> /// `Async` never returns `AsyncError::Full`.

`slog` requires the root drain never to return errors, and its documented way, `fuse()`, panics:

Source: https://github.com/slog-rs/slog/blob/v2.8.2/src/lib.rs
> //! Root drain (passed to `Logger::root`) must be one that does not ever return
> //! errors. This forces user to pick error handing strategy.

Source: https://github.com/slog-rs/slog/blob/v2.8.2/src/lib.rs
> /// `Fuse` will wrap a `Drain` and panic if it returns any errors.

*Serving path, blocking.* The default drops and later reports the count; `Block` (opt-in) blocks the caller until there is space, and `Drop` also exists:

Source: https://github.com/slog-rs/async/blob/v2.8.0/lib.rs
>     /// The message gets dropped and a message with number of dropped is produced once there's
>     /// space.
>     ///
>     /// This is the default.

**The stated why**

The crate documentation (author not blamed), on moving logging off-thread; and `slog`'s "This forces user to pick error handing strategy" (above):

Source: https://github.com/slog-rs/async/blob/v2.8.0/lib.rs
> //! thread.  Typically, serialization and IO operations are slow enough that
> //! they make logging hinder the performance of the main code. Sending log
> //! records to another thread is much faster (ballpark of 100ns).

**Inferred**

None.

**No stated rationale found**

For `DropAndReport` over `Block` as default: none in PR #7 ("Overflow mode", `vorner`, `COLLABORATOR`) and its comments, `CHANGELOG.md` (2.3.0: "Configurable overflow strategy (can now block or drop the messages silently)"), or the 4 titles of the search `repo:slog-rs/async overflow strategy`. Drop-and-report predates the configurable strategy.

**Constraints**

In-process, one worker thread. Dropping `Async` waits for the worker to finish all earlier records, so the drop itself can block; the docs suggest dropping it in another thread if the delay is intolerable.

**Costs and dissent**

The documented `.fuse()` turns a poisoned mutex or dead worker into a panic at the logging call site. The worker catches inner-drain panics and prints them (`eprintln!("slog-async failed with panic: {panic_cause:?}")`), after which the channel is disconnected; inferred from the code, not a test.

**Unverified**

Whether a disconnected channel after a worker panic surfaces as `Fatal` on the next `log` (inferred from the `From<SendError>` impl).

### E14. Datadog `ddtrace`, trace writer only (4.17.2)

Datadog's Python tracer. Tag `v4.17.2`. Timeboxed: only the writer's buffer-full path, its buffer-size default and its `sync_mode` default were read. Read 2026-11-24.

**What it does**

*Set-up.* Not examined.

*Serving path, failure.* A trace that does not fit the encoder buffer is dropped with a warning and counted (`buffer.dropped.traces`, `reason:full`); no exception reaches the caller:

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
>                 "trace buffer (%s traces %db/%db) cannot fit trace of size %db, dropping (writer status: %s)",

*Serving path, blocking.* Writes take a lock around encoding; in `sync_mode` the write flushes in the caller's thread:

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
>         if self._sync_mode:
>             self.flush_queue()

The quotation above is from the `HTTPWriter` class. `create_trace_writer` returns a `NativeWriter` (or, in AWS Lambda without the Agent extension, a `LogWriter`), whose `write` does the same (`if self._write_without_flush(spans) and self._sync_mode:`). It passes `sync_mode=_use_sync_mode()`, which is on in the runtimes named under **The stated why**. The trace buffer defaults to 20 MB (`DD_TRACE_WRITER_BUFFER_SIZE_BYTES`), capped at 10 MB when an API key is given (read from source, not run):

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/constants.py
> DEFAULT_BUFFER_SIZE = 20 << 20  # 20 MB

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/settings/_config.py
>         self._trace_writer_buffer_size = _get_config("DD_TRACE_WRITER_BUFFER_SIZE_BYTES", DEFAULT_BUFFER_SIZE, int)

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
>         buffer_size = buffer_size or config._trace_writer_buffer_size
>         max_payload_size = max_payload_size or config._trace_writer_payload_size
>         if api_key is not None:
>             buffer_size = min(buffer_size, AGENTLESS_MAX_BUFFER_SIZE)

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
> AGENTLESS_MAX_BUFFER_SIZE = 10 << 20  # 10 MB

**The stated why**

The writer's source, in the docstring of `_use_sync_mode` (no individual author named), on why delivery is synchronous by default in some runtimes. The docstring introduces the list with "There are only three cases in which this is desirable:".

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
>     - AWS Lambdas can have the Datadog agent installed via an extension.
>       When it's available traces must be sent synchronously to ensure all
>       are received before the Lambda terminates.
>     - Google Cloud Functions and Azure Functions have a mini-agent spun up by the tracer.
>       Similarly to AWS Lambdas, sync mode should be used to avoid data loss.
>     - Ray Job run different processes that can be killed at any time. Traces must be sent
>       synchronously to ensure all are received before an actor/a worker is killed

**Inferred**

None.

**No stated rationale found**

For the buffer-full drop and the lock around encoding: only `writer.py`, `constants.py` and `settings/_config.py` were read, and no design documents or issues were searched, so this is no proof of absence.

**Constraints**

Push model to a local agent, with a periodic background flush, except where `sync_mode` is on (by default in the runtimes the `_use_sync_mode` docstring names): there each write flushes in the caller's thread.

**Costs and dissent**

Not examined.

**Unverified**

Set-up failure behaviour, and any stated rationale for the buffer-full drop.

#### Leads that did not hold (posture)

- **Log4j 2 never blocking the serving path:** `AsyncAppender` (`blocking=true`) and the queue-full policy (`Default`) both block by default; dropping is opt-in (`Discard`). E1.
- **Logback `neverBlock`:** it exists but defaults to `false`, so the appender blocks; the default is lossy for `TRACE`/`DEBUG`/`INFO` through `discardingThreshold`, not `neverBlock`. E2.
- **Kafka `send` not blocking:** documented as asynchronous, it blocks on metadata and buffer space for up to `max.block.ms` (60000 ms default), and without that bound in user-supplied serializers or the partitioner, and throws several exceptions directly. E4.
- **The serving half, for metrics clients:** `prometheus_client` raises and `client_golang` panics on a wrong label count or negative increment; `cadence` returns a `Result` from every plain call; at v1.25.0 `client_golang`'s `WithLabelValues` can block behind a stuck scrape. E6, E7, E9.
- **"Set-up fails loudly" for Java logging:** Log4j 2 status-logs most configuration errors and falls back to a default configuration, except that an `AsyncAppender` with no usable appender throws `ConfigurationException`, which reaches the caller on the automatic path (read from the code); Logback's automatic configuration catches and prints `JoranException`, while an explicit `doConfigure` throws it. E1, E2.
- **"Set-up fails loudly" for Micrometer:** since 1.6 the Prometheus registry swallows registration failures (warn-then-debug), while a `MeterRegistry` type clash still throws. E5.
- **`tracing-appender` set-up failing loudly:** holds except for one case: `new` and the worker spawn panic and the builder returns a `Result`, all loud, but `with_ansi(true)` without the `ansi` feature only prints to stderr in a release build. Runtime I/O errors are ignored, which is the serving path, not set-up. E12.
- **"A StatsD client" as one posture:** `pystatsd` swallows over UDP but raises, and can block without a bound, over TCP; `cadence` returns a `Result`. E8, E9.
- **The serving half for `slog-async`:** with the documented `.fuse()`, a fatal drain error becomes a panic at the call site. E13.

#### Leads not examined (posture)

- **Datadog `ddtrace`:** only the trace writer's buffer-full path and its buffer and `sync_mode` defaults were read (E14); set-up, the DogStatsD client and any rationale beyond the `sync_mode` docstring were not examined. This is not a finding about `ddtrace` as a whole.

## G. Values and blocks that own a background worker

Comparables for a top-level block that owns a background writer.

Libraries in which a value or block held at the top level owns a background worker, and ending it ends or flushes the worker. Sources read 2026-11-24; pins were that day's current releases; Sentry docs and SDK spec at `getsentry/sentry-docs` commit `feaece23fe2aa5da596937b948b8fca6f70ff2e0`. Two shapes appear. **Scope-owned**: ending a value or block asks the worker to finish and waits for it (G1, G2, the last clone in G3, G4 as a `with` block). Whether the request is always delivered, whether everything queued is written, and whether the thread has exited when the wait ends differ by library; each section says which. **Exit-hook-owned**: a global object owns the worker and an `atexit` hook (in G7 also signal handlers) ends it; the application holds no value whose end ends the worker (G5, G6, G7). Two libraries removed a scope-owned shape: opentelemetry-rust its provider guard (#444), sentry-python `init` as a context manager (#3729, #3730).

### G1. tracing-appender `non_blocking` and `WorkerGuard` (crate 0.2.5, tag `tracing-appender-0.2.5`)

Rust, scope-owned. `non_blocking(writer)` returns `(NonBlocking, WorkerGuard)`; the guard's `Drop` asks the worker thread to drain and flush. Read 2026-11-24.

**What it does**

The guard is `#[must_use]` and holds the thread's `JoinHandle`.

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs
> //! Note that the `WorkerGuard` returned by `non_blocking` _must_ be assigned to a binding that
> //! is not `_`, as `_` will result in the `WorkerGuard` being dropped immediately.
> //! Unintentional drops of `WorkerGuard` remove the guarantee that logs will be flushed
> //! during a program's termination, in a panic or otherwise.

- *Ending it.* `Drop` makes two bounded sends and does **not** join: `Msg::Shutdown` on the data channel (at most 100 ms), then a rendezvous on a zero-capacity channel (at most 1000 ms). The worker handles `Shutdown` in queue order, so it reaches `Shutdown` only after attempting every line queued before it, if it gets there before the guard's bound runs out; a line whose write fails is lost and the loop carries on (`write_all(msg)?`, errors ignored; quoted below). If `Shutdown` cannot be enqueued within 100 ms, `Drop` prints an error and returns without waiting. If the 1000 ms rendezvous expires, `Drop` returns while earlier lines may still be unwritten. On reaching `Shutdown`, the worker flushes; if that flush succeeds it blocks on the rendezvous, breaks and flushes again. If that first flush fails, `work` returns the error after `Shutdown` has been taken off the channel, the outer loop's empty `Err(_)` arm (quoted below) loops back to a blocking `recv`, and the worker is not at the rendezvous, so the guard's 1000 ms send runs out and the worker keeps running (read from source, not run). Bound about 1.1 s; neither timeout is configurable in 0.2.5 (a `// TODO: Make timeout configurable.` sits on the 1000 ms send).

Source: https://github.com/tokio-rs/tracing/issues/1135
> Currently there is a default timeout of 1000 ms. This default wasn't chosen for a specific reason and it would be better to let the end user decide what is the correct value for their application.

  #1135 is open; PR #3231 (configurable `shutdown_timeout`) is open and unmerged (checked 2026-11-24). On unreleased master (`74fc079d2308a959d3a17907b3ba592ffd0a98f7`) `Drop` also joins after a successful rendezvous and reports a timeout or worker panic on stderr; that join is from PR #1713 (merged to master 2021-11-13) and is **not** in 0.2.5 (no #1713 commit in the tag's history of `non_blocking.rs`).

  The worker's branch for a failed write or flush, in 0.2.5:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/worker.rs
>                         Err(_) => {
>                             // TODO: Expose a metric for IO Errors, or print to stderr
>                         }

  The flush that ends each pass of `work`, which returns its error even when the pass has just received `Shutdown`:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/worker.rs
>         self.writer.flush()?;
>         Ok(worker_state)

  The arm that holds the rendezvous, which a failed flush does not reach:

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/worker.rs
>                         Ok(WorkerState::Shutdown) | Ok(WorkerState::Disconnected) => {
>                             let _ = self.shutdown.recv();
>                             break;
>                         }

- *Early drop, leak.* An early drop shuts the worker down at once; later lines go nowhere. A leaked or never-dropped guard sends no `Shutdown`, and the worker runs until the process ends. Nothing in 0.2.5 mentions `mem::forget` (grep of `non_blocking.rs`, `worker.rs`, `lib.rs`). After an early drop, `write` in lossy mode (the default) counts the failure and returns `Ok`; in blocking mode it returns an `io::Error`.
- *Exit without ending it.* No `atexit` or exit hook; the guard must drop by unwinding or by `main` returning.

Source: https://github.com/tokio-rs/tracing/blob/tracing-appender-0.2.5/tracing-appender/src/non_blocking.rs
> /// a periodic basis rather than every time a span or event is written. This means that if the program
> /// terminates abruptly (such as through an uncaught `panic` or a `std::process::exit`), some spans
> /// or events may not be written.

- *Can it fail?* `Drop` returns nothing: a first-send timeout prints to stdout (`println!`), a rendezvous timeout is discarded (`let _ =`), the final flush error goes to stderr. Nothing reaches the caller.
- *Worker dies first.* A write error does not end the worker; the loop ignores it under a TODO ("Expose a metric for IO Errors, or print to stderr"). If the writer panics, the thread ends, and `Drop`'s first send gets `Disconnected`, which is ignored. Lossy writes only increment the drop counter.

**The stated why**

Eliza Weisman (`hawkw`, tokio-rs/tracing MEMBER), reviewing the PR that introduced the appender; the released docs keep the reasoning:

Source: https://github.com/tokio-rs/tracing/pull/673#discussion_r405760597
> I think we need to make sure there's a way of ensuring that logs are always flushed when the program shuts down, even if it panics. Since logs emitted immediately before a crash will be helpful for diagnosing the problem, we want to ensure they are all written before the program terminates. We probably want constructing a `FileAppender` to return a drop guard that is held in `main`, and forces the writer to be flushed when it's dropped.

Zeki (`thekeys93`, CONTRIBUTOR, author of #673 and #1125), on bounding rather than joining, and on the handshake the merged fix uses:

Source: https://github.com/tokio-rs/tracing/pull/1125#issuecomment-742781678
> It may be unlikely to happen but if the worker thread fails to actually stop then the call to join will never complete. It seems to me using join within drop is not good practice (but I may be wrong about this).

Source: https://github.com/tokio-rs/tracing/pull/1125
> This guarantees that the `Worker` has flushed all it's messages before the `WorkerGuard` can continue with its drop.

**Inferred**

- From the source: if the writer panics, queued lines are lost and nobody is told.
- With no join in 0.2.5, the final `flush` after the rendezvous may still run when `main` returns and the process exits; #1713 was opened against this race.

**No stated rationale found**

Not applicable.

**Constraints**

- One OS thread per `non_blocking` call, fed by a bounded crossbeam channel; lossy by default, `DEFAULT_BUFFERED_LINES_LIMIT` = 128,000 lines.
- The flush guarantee holds only if the guard drops by unwinding or `main` returning; nothing is surfaced to the caller.
- History: #673 (April 2020) added the guard; #701 moved the shutdown signal into the channel; #1120 reported the flush guarantee broken, fixed by #1125 (merged 2020-12-11) with the rendezvous; #1713 added the join on master only.

**Costs and dissent**

- Early drop is a recurring user error: the maintainer told a user whose log file stayed empty that the guard must be held in `main` (#1493).
- Code that cannot keep the guard in `main` struggles. A JNI user asked for a guard that does not shut the worker down (#708, open since 2020-05-06):

Source: https://github.com/tokio-rs/tracing/issues/708
> The guard is dropped once it exits this JNI method and the shutdown signal is sent preventing us from logging.

- The 1 s bound is arbitrary and fixed. `salewski` (CONTRIBUTOR, author of #1120):

Source: https://github.com/tokio-rs/tracing/pull/1125#issuecomment-742873844
> Really, I'd be willing to wait (a lot) longer in general, on the theory that it will be fast when things are working correctly, but when things are going sideways the remaining bits of unflushed data might be the most important to have written.

- Flushing is only through drop; #3267 (open, `jlizen`, MEMBER) asks for `WorkerGuard::flush`. #1713 records that the writer was sometimes not destroyed on exit.

**Unverified**

- Whether a release with #1713's join is planned; only the 0.2.5 history of `non_blocking.rs` was checked.

### G2. sentry (Rust) `init` and `ClientInitGuard` (crate 0.49.6, tag `0.49.6`)

Rust, scope-owned. `sentry::init` binds a client to the process hub and returns a `#[must_use]` `ClientInitGuard`; dropping it closes the client, which drains and then shuts down the transport thread. Its docs say events are "drained with the configured `shutdown_timeout`". Read 2026-11-24.

**What it does**

- *Ending it.* `Drop` ends any open session and calls `close(None)`, which drops the session, logs and metrics batchers, then calls `shutdown(timeout)` on the transport; `close` returns `true` if the queue drained in time and defaults to `shutdown_timeout` (2 s). The default transport (feature `transport` turns on `reqwest`, so `ReqwestHttpTransport` is `DefaultTransport`) implements `shutdown` as `flush`: send a marker on the worker's channel, wait for the acknowledgement with `recv_timeout`. When the transport's last reference then drops, `TransportThread::drop` sets a shutdown flag, sends `Shutdown`, and joins with no timeout:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/transports/tokio_thread.rs
>         self.shutdown.store(true, Ordering::SeqCst);
>         let _ = self.sender.send(Task::Shutdown);
>         if let Some(handle) = self.handle.take() {
>             handle.join().unwrap();

  Read from the source: the 2 s bound covers only the acknowledgement wait. The blocking `send` of the marker can first wait on the full 30-slot channel (`DEFAULT_CHANNEL_CAPACITY`), and the `join` after is unbounded. The worker checks the flag before each task, so envelopes still queued after a timed-out flush are discarded, while an in-flight HTTP send is waited for. The Sentry SDK specification states a hard bound:

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/client/index.mdx
> Both methods **MUST** block for at most `timeout` seconds.

  Read from source, not run: the default transport builds its client from `reqwest::Client::builder()` and sets no `timeout` on it, and the worker awaits the send with no timeout around it; an application can pass its own client instead. At 0.13.5, the reqwest version Sentry's own lockfile pins, the builder starts with no total request timeout, so the in-flight send the `join` waits for has no request deadline from the client:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/transports/reqwest.rs
>             let mut builder = reqwest::Client::builder();

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/Cargo.lock
> name = "reqwest"
> version = "0.13.5"

Source: https://github.com/seanmonstar/reqwest/blob/v0.13.5/src/async_impl/client.rs
>     /// Enables a total request timeout.
>     ///
>     /// The timeout is applied from when the request starts connecting until the
>     /// response body has finished. Also considered a total deadline.
>     ///
>     /// Default is no timeout.

- *Early drop, leak.* An early drop closes the client; later captures do nothing, unreported. The docs permit `mem::forget` and warn of the cost:

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/init.rs
> /// If you don't want (or can not) keep the guard around, it's permissible to
> /// call `mem::forget` on it.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry/src/init.rs
> /// This is not recommended, as events or session updates that have been queued
> /// might be lost.

  Lorenzo Cian (`lcian`, MEMBER):

Source: https://github.com/getsentry/sentry-rust/issues/698#issuecomment-2700478303
> However, this should not cause a panic. If the client is closed, the Sentry APIs should simply no-op.

- *Exit without ending it.* No exit hook (grep for `atexit` in `init.rs` and `lib.rs` at 0.49.6; code search `repo:getsentry/sentry-rust atexit`, default branch, 0 results). The panic integration flushes on its own (`client.flush(None)` after capturing), independently of the guard. On `exec` and other non-returning exits, Arpad Borsos (`Swatinem`, CONTRIBUTOR):

Source: https://github.com/getsentry/sentry-rust/issues/647#issuecomment-2014998823
> AFAIK, `execvp` just replaces the current process with another one. So the original process does not exist anymore as such, and there is no way to flush anything afterwards.
- *Can it fail?* `close` returns `bool`; `ClientInitGuard::drop` discards it, so a timeout shows only in the `sentry_debug!` log.
- *Worker dies first.* The thread is spawned with `.ok()`, so a spawn failure leaves `handle` as `None`. If the worker exits, `send` fails and captures are recorded as lost in the client report with reason `InternalError`.

**The stated why**

Armin Ronacher (`mitsuhiko`, author; association shown CONTRIBUTOR), adding `#[must_use]`:

Source: https://github.com/getsentry/sentry-rust/pull/81
> This solves an issue that mozilla ran into where the guard was dropped too early and the transport closed. That means events are quietly discarded.

Sentry's Rust documentation gives the cost:

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/docs/platforms/rust/index.mdx
> The `sentry::init` function returns a guard that when dropped, will flush Events that weren't yet sent to Sentry. It has a two-second deadline, so application shutdown may be slightly delayed as a result. Be sure to keep the guard or you won't be able to send events.

Arpad Borsos (`Swatinem`, CONTRIBUTOR), rejecting a reference-counted guard in PR #646:

Source: https://github.com/getsentry/sentry-rust/pull/646#issuecomment-2012879841
> To be quite frank, this is a very niche usecase. Usually you `sentry::init` in the main thread, before calling into the rest of the application.

**Inferred**

- From `handle.join().unwrap()`: if the transport thread had panicked, `unwrap` panics inside `Drop`.
- After the worker exits, `flush` returns `false` at once, because the acknowledgement sender is dropped.

**No stated rationale found**

Not applicable for the guard. For the unbounded `join`: none in the comments of `thread.rs` and `tokio_thread.rs` at 0.49.6, nor in the search `repo:getsentry/sentry-rust shutdown hang` (only #1040, unrelated).

**Constraints**

- One thread `sentry-transport` running a current-thread tokio runtime for reqwest, fed by a bounded `sync_channel` (30); envelopes dropped when full (`try_send`).
- Best-effort drain within `shutdown_timeout` on drop; the panic hook flushes separately. Every failure is silent to the caller.
- History: PR #81 (2018-09-07) added `#[must_use]` after Mozilla lost events. PR #646 (2024), a reference-counted guard, closed unmerged; shared ownership is left to the user (`Arc<ClientInitGuard>`).

**Costs and dissent**

- Early drop silently discards events (#81); #698 is a production report of an unexpected `dropping client guard -> disposing client`.
- Code that cannot hold the guard in `main` (#646, a user):

Source: https://github.com/getsentry/sentry-rust/pull/646
> The only way to get it to work today is to call `std::mem::forget` on it, which is not ideal, as it will never be dropped.

- An error returned from `main` comes after the guard has dropped (#51, a user):

Source: https://github.com/getsentry/sentry-rust/issues/51#issuecomment-503550260
> The code from my last comment doesn't work. If the ClientInitGuard is in main() it gets dropped before it can report the error.

**Unverified**

- Whether anything below the request bounds a stalled send at the default: on Linux, Android and Fuchsia reqwest 0.13.5's builder sets `tcp_user_timeout: Some(Duration::from_secs(30))`, whose effect on a stalled send was not checked. Which reqwest an application resolves: Sentry's manifest asks for `version = "0.13.2"`, so an application's lockfile may pick another 0.13.x, whose defaults were not read.

### G3. opentelemetry_sdk (Rust) `SdkTracerProvider` and `BatchSpanProcessor` (crate 0.33.1, tag `opentelemetry_sdk-0.33.1`)

Rust, scope-owned through reference counting: the provider is an `Arc`, dropping the **last** clone runs `shutdown` on every span processor, and `BatchSpanProcessor` owns a dedicated thread. Trace signal only. Read 2026-11-24.

**What it does**

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/provider.rs
> /// The `TracerProvider` is designed to be clonable. Cloning a `TracerProvider`  creates a
> /// new reference to the same provider, not a new instance. Dropping the last reference
> /// to the `TracerProvider` will automatically trigger its shutdown. During shutdown, the provider
> /// will flush all remaining spans, ensuring they are passed to the configured processors.

- *Ending it.* The inner `Drop` calls `shutdown()` unless already shut down; default 5 s (`Duration::from_secs(5)`), given to each processor in turn. The processor sends a `Shutdown` control message with `try_send`, and a full control channel returns an error without signalling the worker. The worker makes one export pass over what is buffered, shuts the exporter down, ignoring that result, and sends back the export's result. The caller waits with `recv_timeout`, discards that result (`.map(|_| {`), and **only then** joins (`handle.join().unwrap()`, which has no timeout of its own), so shutdown returns `Ok` even if the final export failed. On timeout the thread is not joined.
- *Early drop, leak.* Dropping one clone does nothing. Dropping the last early stops processing. A span ended after its provider has shut down is skipped silently in `span.rs`, before any processor sees it (as in A4); the batch processor's warning below is reached when its span channel is disconnected, which happens once the worker thread has ended: after the processor is shut down while its provider is not, or after the worker has died, for example by a panic (read from source, not run):

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>                     message = "Spans are being emitted even after Shutdown. This indicates incorrect lifecycle management of TracerProvider in application. Spans will not be exported."

  The warning sits in the `Disconnected` arm of `BatchSpanProcessor::on_end`, under this comment:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>                 // Given background thread is the only receiver, and it's
>                 // disconnected, it indicates the thread is shutdown

  The documented pattern gives a clone to the global and keeps one to shut down explicitly:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/CHANGELOG.md
>   tracer_provider must be kept around to call shutdown on it at the end of
>   application (ex: `tracer_provider.shutdown()`)

- *Exit without ending it.* No exit hook (grep for `atexit` in `provider.rs`, `span_processor.rs`; code search `repo:open-telemetry/opentelemetry-rust atexit path:opentelemetry-sdk`, default branch, 0 results). The processor docs recommend calling `shutdown` before exit.
- *Can it fail?* The batch processor's `shutdown_with_timeout` returns `Err(Timeout)`, `Err(InternalFailure)` or `Err(AlreadyShutdown)`. The provider's explicit `shutdown` returns `Err(AlreadyShutdown)` if it was already shut down, and otherwise gathers every processor's error, a timeout included, into one `Err(InternalFailure)` (quoted below; read from source, not run). On drop the result is discarded and logged at debug level, for a stated reason:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/provider.rs
>                 //  - Or the error occurs during `TracerProviderInner::Drop` as part of telemetry shutdown,
>                 //    which is non-actionable by the user

  The provider's aggregation, in `shutdown_with_timeout`:

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/provider.rs
>                 Err(OTelSdkError::InternalFailure(format!(
>                     "Shutdown errors: {:?}",

- *Worker dies first.* A disconnected control channel makes `shutdown` return `AlreadyShutdown`; spans meanwhile get the after-shutdown warning. The docs warn that `shutdown()`, blocking, can deadlock if called from the main thread on tokio's current-thread runtime.

**The stated why**

opentelemetry-rust once returned a guard from `set_tracer_provider` (its drop shut the provider down) and **removed it**. Zhongyang Wu (`TommyCpp`, CONTRIBUTOR, author), PR #444, merged 2021-02-27:

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/444
> The current approach works for multiple thread tokio runtime, but not really working for the current thread tokio runtime.

Source: https://github.com/open-telemetry/opentelemetry-rust/pull/444
> Also currently we allow the users to use multiple tracer providers throughout the application, which I believe is not a common situation. Most people should have one global tracer provider.

#2369 (merged 2024-12-04) also removed `global::shutdown_tracer_provider()`, leaving explicit `provider.shutdown()` plus shutdown on the last drop.

**Inferred**

- The global holder is a `static OnceLock<RwLock<GlobalTracerProvider>>` (`opentelemetry/src/global/trace.rs`, same tag) and Rust never drops statics, so a clone held only by the global is never shut down by `Drop` while it stays current; a later `set_tracer_provider` drops it under the global's write lock, and if it was the last clone its `Drop` runs `shutdown`. Hence the explicit call.
- If the worker panicked after acknowledging, `join().unwrap()` panics in the caller.
- Acknowledge-then-join reaches the join only after the worker acknowledges: a worker that never acknowledges is timed out and not joined. The objection raised on tracing-appender #1125, that a join in `drop` "will never complete" if the worker fails to stop, then applies only to a worker that stalls after acknowledging, for example while its exporter is dropped, because the join has no deadline (read from source, not run). Neither project cites the other.

**No stated rationale found**

For the 5 s default: none in the comments of `provider.rs` and `span_processor.rs`, the CHANGELOG entry adding `shutdown_with_timeout`, or the search `repo:open-telemetry/opentelemetry-rust shutdown hang in:title` (only #536).

**Constraints**

- One thread per processor, `OpenTelemetry.Traces.BatchProcessor`; queue bounded (2,048 default), drops when full.
- Shutdown makes one export pass over the spans buffered when the worker takes the message, in batches of up to `max_export_batch_size`, each exported once; the timeout bounds only how long the caller waits (`recv_timeout`), not the worker's export; tracers then do nothing. Explicit `shutdown` returns an error for a timeout or a full control channel, but not for a failed final export, whose result is discarded; drop-time errors are logged at debug.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>         while target > 0 && total_exported_spans < target {

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>                 receiver
>                     .recv_timeout(timeout)

- History: guard removed in #444 (2021). `SdkMeterProvider` gained a `Drop` in #1623 and broke the global pattern (#1661); a maintainer proposed moving `Drop` to the shared inner value (it landed: `impl Drop for SdkMeterProviderInner` at 0.33.1, as A4 says). #2369 (2024) removed `global::shutdown_tracer_provider`.

**Costs and dissent**

- Dropping the last clone early stops export silently (#1625, a user):

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1625
> There is no compiler warning or any documentation note regarding this behaviour or that it must be kept alive manually.

- `Drop` on a shared clone shut down the global provider (#1661). Lalit Kumar Bhasin (`lalitb`, MEMBER):

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1661#issuecomment-2054252711
> @bwalk-at-ibm Your analysis is correct. We shouldn't have `Drop` implemented for `SdkMeterProvider`.

- Current-thread-runtime hangs, and #427's forced `mem::forget` outside `main` (A4), were why the guard went (#444); #536 and #868 report `shutdown_tracer_provider()` hanging.

**Unverified**

- Logs and metrics providers: `logger_provider.rs` fetched but not read; metrics files not read.

### G4. CPython `logging.handlers.QueueListener` (tag `v3.15.2`)

Standard library. Scope-owned as a `with` block since 3.14 (the docs' `versionchanged:: 3.14`: entering starts the listener, exiting stops it); otherwise explicit `start()` and `stop()`. A daemon thread with no exit hook of its own. Read 2026-11-24.

**What it does**

- *Ending it.* `__exit__` calls `stop()`, which enqueues a sentinel and `join()`s **with no timeout**; records queued before the sentinel are handled first. `stop()` does not flush or close downstream handlers; `logging.shutdown` does at exit.
- *Early end, never ended.* Leaving the block early stops the listener; later records stay on the queue.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/logging.handlers.rst
>       This asks the thread to terminate, and then waits for it to do so.
>       Note that if you don't call this before your application exits, there
>       may be some records still left on the queue, which won't be processed.

  The thread is a daemon, shown only in the source; the reference page does not say so (grep for `daemon` matches only syslog text):

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/logging/handlers.py
>         self._thread = t = threading.Thread(target=self._monitor)
>         t.daemon = True

- *Exit without ending it.* `logging`'s `atexit.register(shutdown)` flushes and closes handlers but does not stop listeners (grep for `listener` in `Lib/logging/__init__.py`: nothing). `dictConfig` attaches a listener as `handler.listener` but calls no `.start()` or `.stop()` (grep of `config.py`), leaving both to the application.
- *Can it fail?* Read from the source: `enqueue_sentinel` uses `put_nowait`, so on a full bounded queue `stop()` raises `queue.Full` and does not join; the docs name `enqueue_sentinel` as the method to override "if you want to use timeouts". The unbounded `join` can wait forever if a downstream handler blocks.
- *Worker dies first.* `_monitor` catches only `queue.Empty`. Exceptions inside `emit` normally go to `handleError`, which prints only when `raiseExceptions` is set. If the thread has died, `stop()` still enqueues the sentinel, `join` returns at once, and queued records are not processed.

**The stated why**

Vinay Sajip (`vsajip`, MEMBER, copyright holder of `handlers.py`), refusing a context manager in 2020:

Source: https://github.com/python/cpython/pull/18563#pullrequestreview-361331527
> The intention is for `QueueListener` to be used in a separate thread or process whose only job is to listen to messages from the `QueueHandler` and dispatch them to appropriate destinations.

Source: https://github.com/python/cpython/pull/18563#pullrequestreview-361331527
> I don't want to bake in context management for any particular handler at the moment - the use cases are too varied for a definitively useful basis for design/implementation.

The cookbook, on a separate listener:

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/howto/logging-cookbook.rst
> The advantage of having a separate :class:`QueueListener` class is that you
> can use the same instance to service multiple ``QueueHandlers``.

Vinay Sajip on the daemon thread, 2019:

Source: https://github.com/python/cpython/issues/73076#issuecomment-1093733964
> Why does that particularly need documenting? If it were a non-daemon thread, that might need documenting as the program would have to join() it or else seem to hang, but what does it matter if it's a daemon thread?

The context manager was accepted in 2025 (gh-132106, PR gh-132107, merged 2025-04-12), proposed by `csm10495` (CONTRIBUTOR):

Source: https://github.com/python/cpython/issues/132106
> It's a welcomed alternative to needing to call start/stop manually.

**Inferred**

- From the source: an exception from `prepare` or `handle` ends the thread.

**No stated rationale found**

For `stop()` having no timeout: none in the `stop` and `enqueue_sentinel` docstrings, the reference page, gh-114706 and PR gh-114748, or the search `repo:python/cpython QueueListener stop in:title` (only #114748).

**Constraints**

- One daemon thread per listener serving any number of `QueueHandler`s; the queue is the user's (`dictConfig` defaults to an unbounded `queue.Queue()`).
- No guarantee at exit unless `stop()` is called, which waits without bound; `queue.Full` on a bounded queue; handler errors via `handleError`.
- History: added in 3.2; context manager refused 2020 (bpo-39589); `stop()` made idempotent 2024 (gh-114706), to allow calling it from app shutdown and `atexit`; context manager added 2025 (3.14).

**Costs and dissent**

- The 2019 report behind #73076 (`Julien Castiaux`, user), records lost to the daemon thread:

Source: https://github.com/python/cpython/issues/73076#issuecomment-1093733965
> As it was not, the process was exiting logging a few messages or not depending on the threads schedule.

- The gh-114706 reporter (`Booplicate`, CONTRIBUTOR):

Source: https://github.com/python/cpython/issues/114706
> For example, having it in multiple places: on app shutdown (normal behaviour) and atexit callbacks (backup in case shutdown wasn't planned and its callbacks didn't run).

- The 2020 refusal was reversed in 2025.

**Unverified**

- The Discourse thread linked from gh-132106 (`discuss.python.org/t/.../87124`) was not fetched.

### G5. sentry-sdk (Python) `init`, `AtexitIntegration` and `BackgroundWorker` (3.0.0, tag `3.0.0`)

Exit-hook-owned. `init()` returns `None`; a global client owns a daemon `BackgroundWorker`, and the default `AtexitIntegration` ends the session and calls `client.close(callback=...)` at exit. A `Client` is still a context manager (`__exit__` calls `close()`), but `init` no longer returns one. Read 2026-11-24.

**What it does**

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/MIGRATION_GUIDE.md
> - `sentry_sdk.init()` can no longer be used as a context manager.

- *Ending it.* `close()` flushes, closes the batchers, then calls `transport.kill()`. `flush` waits on the queue's unfinished-task count to a deadline (0.1 s, then the callback, which prints "Sentry is attempting to send %i pending events" on stderr, then the rest), and does not join. `kill()`'s docstring says it "Returns immediately"; read from source, not run, it first takes the worker's lock, the one `flush` holds while it waits, so it waits if another thread is in `flush`, and its `put_nowait` of the terminator can fail on a full queue, which it logs at debug level before dropping its reference to the thread without stopping it, so the worker is left running with no terminator queued (quoted below). In `close()` the flush and the kill run one after the other on the same thread. Default `shutdown_timeout: float = 2` (`consts.py`). The option's documentation:

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/consts.py
>             Setting this value too low may cause problems for sending events from command line applications.

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/consts.py
>             Setting the value too high will cause the application to block for a long time for users experiencing
>             network connectivity problems.

  `kill()` at the same tag:

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/worker.py
>         with self._lock:
>             if self._thread:
>                 try:
>                     self._queue.put_nowait(_TERMINATOR)
>                 except FullError:
>                     logger.debug("background worker queue full, kill failed")
>
>                 self._thread = None

- *Never ended.* No value to drop. Removing the hook disables draining:

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/docs/platforms/python/configuration/draining.mdx
> The Python SDK automatically drains on shutdown unless the `AtexitIntegration` is removed or the `shutdown_timeout`
> config key is set to 0.

- *Exit.* `atexit` is the mechanism. The thread is a daemon and does not keep the process alive. It is created lazily, and a source comment says that once the interpreter is shutting down it can no longer start, so events can no longer be sent.
- *Can it fail?* `close` and `flush` return `None`; a timeout logs `"flush timed out, dropped %s events"` at error level. Before the 1.33.0 fix the `atexit` callback could raise `RuntimeError` on Python 3.12 (#2299, "Exception ignored in atexit callback").
- *Worker dies first.* `submit` calls `_ensure_thread()`, which restarts a dead thread (the `is_alive` check also catches a fork, via `_thread_for_pid`). A failing job is logged and the loop continues.

**The stated why**

Neel Shah (`sl0thentr0py`, MEMBER), on removing the `init` context manager:

Source: https://github.com/getsentry/sentry-python/pull/3276#discussion_r1675776684
> `init` is generally one per process anyway. In case people want DSN isolation, multiple clients is the way to go now. So I really don't see the use case for this.

Daniel Szoke (`szokeasaurusrex`, MEMBER), deprecation PR:

Source: https://github.com/getsentry/sentry-python/pull/3729
> It is possible to use the return value of `sentry_sdk.init` as a context manager; however, this functionality has not been maintained for a long time, and it does not seem to be documented anywhere.

Ivana Kellyer (`sentrivana`, COLLABORATOR), on the lazy start:

Source: https://github.com/getsentry/sentry-python/issues/2983#issuecomment-2059150339
> We _could_ probably start it right away instead of on demand, but that could lead to issues on setups that fork the process the SDK is running in.

The Sentry SDK specification's bound for `close`:

Source: https://github.com/getsentry/sentry-docs/blob/feaece23fe2aa5da596937b948b8fca6f70ff2e0/develop-docs/sdk/foundations/client/index.mdx
> | `close(timeout)` | Flush the transport queue for up to `timeout` seconds. The Client **SHOULD** be disabled or disposed after close returns. |

**Inferred**

None.

**No stated rationale found**

For `atexit` rather than a returned value, nothing beyond the removal rationale: `integrations/atexit.py` has no class docstring, and the search `repo:getsentry/sentry-python AtexitIntegration` added nothing.

**Constraints**

- One lazily created daemon thread per transport; queue bounded (`DEFAULT_QUEUE_SIZE`), submissions fail when full.
- Best-effort drain within `shutdown_timeout` (2 s) at `atexit`; failures logged only.
- History: 2.x `init` returned an undocumented context manager; deprecated by #3729 (merged 2024-11-12), removed by #3730 (merged 2024-11-05 to `potel-base`), shipped in 3.0.0.

**Costs and dissent**

- Starting a thread during finalization fails on 3.12, losing events at exit (#2983, #2299). Daniel Szoke (`szokeasaurusrex`, MEMBER):

Source: https://github.com/getsentry/sentry-python/issues/2983#issuecomment-2061231972
> This behavior is quite confusing from a user perspective, however, so I think we should invest in creating a solution that allows us to ensure the transport is flushed at program exit in Python 3.12.

- Daemon threads at shutdown can crash the interpreter (#877; users said `shutdown_timeout=0` avoided it); closed without a reproduction.
- The context-manager removal reverses the scope-owned shape.

**Unverified**

- `AsyncWorker` (`close_async`) at exit; only the threaded worker was read.

### G6. opentelemetry-sdk (Python) `TracerProvider(shutdown_on_exit=True)` and `BatchSpanProcessor` (1.45.2, tag `v1.45.2`)

Exit-hook-owned. `TracerProvider` runs `atexit.register(self.shutdown)` when `shutdown_on_exit` (the default); `BatchSpanProcessor` owns a daemon thread and has no hook of its own. `TracerProvider` has no `__enter__` or `__exit__` (the only `__exit__` in `sdk/trace/__init__.py`, line 1002, is `Span`'s). Read 2026-11-24.

**What it does**

- *Ending it.* `TracerProvider.shutdown()` shuts down each processor and unregisters the hook. `BatchSpanProcessor.shutdown()` takes no timeout; it uses `BatchProcessor.shutdown()`'s default 30,000 ms: set the flag, wake the worker, join with a timeout, then shut the exporter down with the time left. On the way out the worker exports what is buffered, batch by batch (`EXPORT_ALL`), until the queue is empty or the join times out. `shutdown` then sets `_shutdown_timeout_exceeded`, and the worker starts no further batch, so batches still queued are not exported (read from source, not run; quoted after this list). A source comment says that if one export is still running the call returns instead of waiting for the thread.

  Read from source, not run: the provider's default multi-processor shuts processors down one after another, passing no timeout, and each batch processor's join uses its own 30 s default (the join is quoted after this list); an application may pass `ConcurrentMultiSpanProcessor` instead, which shuts them down in parallel.

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/__init__.py
>         self._active_span_processor = active_span_processor or SynchronousMultiSpanProcessor()

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/__init__.py
>     def shutdown(self) -> None:
>         """Sequentially shuts down all underlying span processors."""
>         for sp in self._span_processors:
>             sp.shutdown()

- *Never ended.* No value whose drop ends the worker. `shutdown_on_exit=False` removes the hook, leaving `shutdown()` to the application. After shutdown, `emit` refuses data (`"Shutdown called, ignoring %s."`).
- *Exit.* `atexit` is the mechanism; the thread is a daemon, so a process that skips the hook loses the buffer. Forks: `os.register_at_fork`; the child clears the queue and starts a new thread.
- *Can it fail?* `shutdown` returns `None`; a worker that misses the timeout is abandoned, not reported; export exceptions are logged.
- *Worker dies first.* `_export` catches every exception, so exporter failures do not end the worker. No restart was found for a thread dying otherwise, except after a fork.

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py
>         if not self._queue or self._shutdown_timeout_exceeded:
>             return False

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/_shared_internal/__init__.py
>         self._worker_thread.join(timeout_millis / 1000)
>         # Stops worker thread from calling export again if queue is still not empty.
>         self._shutdown_timeout_exceeded = True

**The stated why**

Mauricio Vásquez (`mauriciovasquezbernal`, MEMBER), author of PR #280, merged 2019-11-27:

Source: https://github.com/open-telemetry/opentelemetry-python/pull/280
> Before this commit applications
> had to shut down the span processor explicitely to guarantee that all the spans
> were summited to the exporters, this was not very intuitive for the users.

(Line breaks collapsed: the source uses CRLF.)

The same author, proposing `shutdown_on_exit` and rejecting `__del__`:

Source: https://github.com/open-telemetry/opentelemetry-python/pull/280#issuecomment-552882701
> 3. Don't use `__del__`, two reasons: (a) I don't think people would create multiple tracer instances in an application and destroy them before the application ends, (b) it is not guarantee that it'll be called in all cases.

Chris Kleinknecht (`c24t`, MEMBER), reviewer:

Source: https://github.com/open-telemetry/opentelemetry-python/pull/280#discussion_r344863763
> I agree about making this configurable, but I think this is much better than the current default: call `shutdown` or lose unexported spans.

**Inferred**

None.

**No stated rationale found**

For the 30 s default: no comment on `shutdown(self, timeout_millis: int = 30000)` at the tag; a later maintainer comment (#2284) cites the bound without a reason.

**Constraints**

- One daemon thread per batch processor; queue bounded, oldest entries dropped when full, with a warning (`Queue full, dropping %s.`) and a dropped-items count.
- Best-effort export at `atexit`, bounded per batch processor by 30 s plus the exporter's shutdown; by default processors are shut down one after another with no shared deadline (read from source); failures logged, `shutdown` returns nothing.
- History: PR #280 (2019) added `shutdown_on_exit` and `atexit`. The shutdown path was bounded later; the earlier version joined without a timeout (#2284 traceback: `self.worker_thread.join()`).

**Costs and dissent**

- Exit hangs with an unreachable collector (#2284, 2021-11-18 to 2025-12-05). Reporter `flashgorman-chorus` (user), then `DylanRussell` (CONTRIBUTOR), closing it:

Source: https://github.com/open-telemetry/opentelemetry-python/issues/2284
> We have a process that sometimes fails to exit until we hit `ctrl-c`.

Source: https://github.com/open-telemetry/opentelemetry-python/issues/2284#issuecomment-3618449236
> In the BatchSpan/LogProcessor we now will wait at most 30 seconds to try and finish flushing telemetry.

- Carlos Alberto Cortez (`carlosalberto`, CONTRIBUTOR) dissented from automatic shutdown:

Source: https://github.com/open-telemetry/opentelemetry-python/pull/280#discussion_r344322863
> My personal preference would be to **not** do this by default, but have it as something the user can plug himself, or at least make this optional.

- Christian Neumüller (`Oberon00`, MEMBER) objected to the strong reference from the `atexit` list:

Source: https://github.com/open-telemetry/opentelemetry-python/pull/280#issuecomment-552919175
> However, even the `shutdown_on_exit` bit is a bit problematic because when this is set to true, we have a (strong) reference from the global atexit handler list to the tracer (you could `atexit.unregister` in `Tracer.shutdown`, but still).

**Unverified**

- Whether the OTLP exporter's `shutdown(timeout_millis=...)` honours the time left; exporter packages not read.

### G7. ddtrace (Python) global `tracer` (4.17.2, tag `v4.17.2`)

Exit-hook-owned. The global `ddtrace.tracer` owns a writer (`HTTPWriter` or `NativeWriter`) on a native `PeriodicThread`. `Tracer.__init__` calls `atexit.register(self._atexit)` and `atexit.register_on_exit_signal(self._atexit)` (SIGTERM, SIGINT); `Tracer` has no `__enter__` (grep of `_trace/tracer.py` for `__enter__|__exit__`). Read 2026-11-24.

**What it does**

- *Ending it.* `_atexit` calls `shutdown(timeout=5)` (`SHUTDOWN_TIMEOUT`). The span aggregator clears unfinished traces with a warning, then `writer.stop(timeout)` stops the periodic thread (running `on_shutdown`, a final `periodic()` flush) and joins with the timeout:

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/writer/writer.py
>         # FIXME: don't join() on stop(), let the caller handle this
>         super()._stop_service()
>         self.join(timeout=timeout)

  A direct `tracer.shutdown()` defaults to `timeout=None`, documented as "block until flushing has successfully completed".
- *Never ended.* Spans unfinished at shutdown are dropped with a log ("These spans will not be sent to Datadog").
- *Exit.* The `atexit` wrapper swallows exceptions (re-raised only when `DD_TESTING_RAISE` is set) and skips registration under uWSGI `--skip-atexit` to avoid crashes. Signal handlers are installed only from the main thread; SIGINT is skipped when `default_int_handler` is installed, so `asyncio.Runner` can install its own, with `atexit` covering `KeyboardInterrupt`. The native thread module's own `atexit` handler stops and joins every running periodic thread.

  Read from source, not run: `shutdown` passes its timeout to each processor in turn; before that, outside an AWS Lambda microVM it waits without a bound for `_post_fork_lock`; and the native handler joins each periodic thread it has registered with no timeout, which `PeriodicThread_join` treats as an unbounded wait:

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/_trace/tracer.py
>             wait = max(timeout, 0) if timeout is not None and in_aws_lambda_microvm() else -1
>             locked = self._post_fork_lock.acquire(timeout=wait)

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/_trace/tracer.py
>             for processor in chain(self._span_processors, SpanProcessor.__processors__, [self._span_aggregator]):
>                 if processor:
>                     processor.shutdown(timeout)

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/_threads.cpp
>                 PyObject* result = PeriodicThread_join((PeriodicThread*)thread, NULL, NULL);

Source: https://github.com/DataDog/dd-trace-py/blob/v4.17.2/ddtrace/internal/_threads.cpp
>     if (timeout == Py_None) {
>         AllowThreads _(self->_state);
>
>         self->_stopped->wait();

- *Can it fail?* Exceptions are silently swallowed in production.
- *Worker dies first.* Per the native thread's stub, raising an exception prints the traceback and stops the loop. The writer's `periodic` calls `flush_queue(raise_exc=False)`. `PeriodicService` resumes after a fork.

**The stated why**

Brett Langdon (`brettlangdon`, MEMBER), PR #16342, merged 2026-02-06, adding the signal handlers:

Source: https://github.com/DataDog/dd-trace-py/pull/16342
> The impact on traces is up to 1 seconds worth of traces could be lost. For stats it is up to 10 seconds of stats which could be lost.

**Inferred**

None.

**No stated rationale found**

For the 5 s timeout, or a global tracer with hooks rather than a returned handle: none in `tracer.py`, `docs/advanced_usage.rst`, `docs/troubleshooting.rst` (grep for `shutdown|atexit|flush`: only the uWSGI note and an example `tracer.shutdown()`), or the searches `repo:DataDog/dd-trace-py atexit hang shutdown` and `shutdown timeout atexit`.

**Constraints**

- A native periodic thread, about a 1 s trace flush interval (per #16342); processes often forked (gunicorn, uWSGI).
- Best-effort flush at `atexit`, SIGTERM or SIGINT, with `timeout=5` passed to each processor's `shutdown`; outside an AWS Lambda microVM the lock wait before it is unbounded, and the native `atexit` handler's join has no timeout (read from source); explicit `shutdown()` unbounded by default; exceptions swallowed and logged.
- History: #8252 (2024) reported spans lost on SIGTERM; #16342 (2026-02-06) added the exit-signal handlers, not linking #8252. #17195, proposing `DD_TRACER_ATEXIT_ENABLED` to opt out, closed **unmerged** (`merged_at: null`); no `ATEXIT_ENABLED` in the 4.17.2 sources.

**Costs and dissent**

- Exit-time cost: #19915 (open) reports about 2.2 s added to every interpreter shutdown in 4.14.0. Reporter `ruidc` (user):

Source: https://github.com/DataDog/dd-trace-py/issues/19915
> The invariant is *three sequential blocking round-trips at process exit*; the cost is 3× the RTT to your intake

- Exit hangs: #21184 (merged 2026-10-28), `P403n1x87` (COLLABORATOR):

Source: https://github.com/DataDog/dd-trace-py/pull/21184
> ddtrace only stops its threads in atexit handlers, which run after that, so the process hangs instead of exiting.

- Owning the shutdown order: #17195 (unmerged), `ZStriker19` (COLLABORATOR):

Source: https://github.com/DataDog/dd-trace-py/pull/17195
> - Enables users to manage their own shutdown sequence (e.g., waiting for in-flight LLM sessions to complete before teardown)

**Unverified**

- Whether `PeriodicThread` is a daemon: grep of `_threads.cpp` for `daemon` found nothing; thread creation not read.
- Why #17195 was closed; its comments hold only `/merge`.

#### Leads that did not hold (worker guards)

- **OpenTelemetry Python `BatchSpanProcessor` and `atexit`.** The registration is `TracerProvider`'s; grep for `atexit` in `sdk/trace/export/__init__.py` and `sdk/_shared_internal/__init__.py` at v1.45.2 finds nothing.
- **ddtrace as a guard comparable.** No value or block the application holds; the global tracer's worker ends through Python and native `atexit` hooks plus SIGTERM and SIGINT handlers (since #16342). The #17195 opt-out was never merged.
- **sentry-python's `atexit` flush as an `init` guard.** In 3.0.0 `init()` returns `None` and is not a context manager (MIGRATION_GUIDE, #3730); the hook's `close()` flushes but does not join, and `kill()` does not join either, though it takes the lock `flush` holds and its enqueue can fail on a full queue (G5).
- **opentelemetry_sdk providers "on drop".** Only the **last** clone's drop shuts down, a clone in the global `static OnceLock` is never dropped unless a later `set_*` replaces it, and the changelog directs an explicit `shutdown()`. The earlier guard was removed in #444.
- Holds, with a divergence: **tracing-appender `WorkerGuard`**: in 0.2.5 `Drop` does not join, waiting at most 100 ms then 1000 ms for a rendezvous; the join exists only on unreleased master (#1713).
- Holds, with a divergence: **sentry-rust `ClientInitGuard`**: the docs say events drain "with the configured `shutdown_timeout`", but only the flush acknowledgement is bounded (2 s); the `TransportThread` drop joins unbounded, and the marker `send` can wait on a full channel first (read from source).
- Holds, with a divergence: **CPython `QueueListener`**: since 3.14 also a context manager; `stop()` joins without a timeout, the thread is a daemon (in source, not the reference page), and `logging`'s `atexit` does not stop listeners.

## H. Comparables that chose otherwise

Libraries that pass their client explicitly and have no global, or only a discouraged one, with contrasts that keep a global.

Seven systems. Four pass the logger or registry as an explicit value and offer no global, or only a discouraged one: slog-rs, zap, Rust `prometheus-client` and go-kit `log`. Three keep a first-class global and are contrasts the leads named: Go `log/slog`, the Rust `prometheus` crate and Python `prometheus_client`; for them "chose otherwise" does not hold. Read 2026-11-24 (a GitHub API error was stamped 2026-11-25 01:18 UTC, so some reads may fall just after midnight).

### H1. slog-rs with `slog-scope` (Rust), explicit (slog 2.8.2 at `e694b83`; slog-scope 4.4.1 at `178058a`; slog-term 2.9.2; wiki `FAQ.md` at `4bff5c8`, 2020-03-11)

A Rust structured logger whose `Logger` is a passed value; the global lives in a separate, discouraged crate. Read 2026-11-24.

**What it does**

The core holds no global logger: https://docs.rs/slog/2.8.2/slog/all.html lists only two statics (`LOG_LEVEL_NAMES`, `LOG_LEVEL_SHORT_NAMES`) and no functions, and a grep of `src/` at `v2.8.2` for global, `OnceLock`, `lazy_static`, `set_global` and static `Logger` patterns finds only the "one globally registered backend" line quoted below. A root logger is built from a drain and passed on; the docs call cloning and creating loggers cheap, and loggers free to pass between threads.

The global is `slog-scope`, which the core docs name a "convenience" crate for "logging-scopes for implicit `Logger` passing". It holds a process-wide `GLOBAL_LOGGER` and a thread-local scope stack; `slog_scope::logger()` returns the innermost scope or the global. Its own docs discourage it in libraries:

Source: https://github.com/slog-rs/scope/blob/v4.4.1/lib.rs
> //! It is generally advised **NOT** to use `slog_scope` in libraries. Read more in

Its unset behaviour contradicts its docs, which say it panics:

Source: https://github.com/slog-rs/scope/blob/v4.4.1/lib.rs
> //! **Warning**: Since `slog-scope` version 4.0.0, `slog-scope` defaults to
> //! panicking on logging if no scope or global logger was set. Because of it, it
> //! is advised to always set a global logger upfront with `set_global_logger`.

The source at the same tag initialises the global to `slog::Discard` and installs the panicking `NoGlobalLoggerSet` drain only when a `GlobalLoggerGuard` drops:

Source: https://github.com/slog-rs/scope/blob/v4.4.1/lib.rs
> /// On drop it will reset global logger to an `slog::Drain` that panics upon receiving a log record,
> /// so use outside of main is discouraged.

So a record before `set_global_logger` is silently discarded and one after the guard drops panics; slog-rs/slog#169 reports the same asymmetry.

Tests: each builds its own root `Logger` and drain; nothing global needs resetting. The core has `Discard` and the public `Drain` trait but no in-memory capturing drain (structs: `Discard`, `Duplicate`, `Filter`, `Fuse`, `IgnoreResult`, `LevelFilter`, `MapError`). The FAQ points tests at `slog-term`'s `TestStdoutWriter`, which routes output through the harness's captured stdout and records no structured entries.

**The stated why**

Dawid Ciężarkiewicz, named in the README as original author and current maintainer, in the FAQ wiki (his lines per `git blame`, commits `4cf6261` 2017-01-15 and `5c66dc1` 2017-04-11; rendered page, so inline code lacks backticks):

Source: https://github.com/slog-rs/slog/wiki/FAQ/4bff5c82127095e4cba2ff577b6a07337d2e9947
> Note however that slog author advises not using slog_scope at all, and definitely not in libraries.

Source: https://github.com/slog-rs/slog/wiki/FAQ/4bff5c82127095e4cba2ff577b6a07337d2e9947
> The reason is: manually passing Logger gives maximum flexibility. Using slog_scope ties the logging data structure to the stacktrace, which is not the same a logical structure of your software. Especially libraries should expose full flexibility to their users, and not use implicit logging behaviour.

Source: https://github.com/slog-rs/slog/wiki/FAQ/4bff5c82127095e4cba2ff577b6a07337d2e9947
> Usually Logger instances fit pretty neatly into data structures in your code representing resources, so it's not that hard to pass them in constructors, and use info(self.log, ...) everywhere.

The same reason in `slog-scope`'s crate docs:

Source: https://github.com/slog-rs/scope/blob/v4.4.1/lib.rs
> //! Part of a `slog` logging philosophy is ability to freely express logging contexts
> //! according to logical structure, rather than callstack structure. By using
> //! logging scopes the logging context is tied to code flow again, which is less
> //! expressive.

On `log`'s global, the core docs list as an advantage over `log`:

Source: https://github.com/slog-rs/slog/blob/v2.8.2/src/lib.rs
> //! * **flexible** - `slog` does not constrain logging to just one globally
> //!   registered backend. Parts of your application can handle logging
> //!   in a customized way, or completely independently.

Dawid Ciężarkiewicz (`dpc`, collaborator), to a user asking for `log`-style global setup (#157), then on the slog-scope panic default (#169), where he also recalls, hedged with "IIRC", why the guard exists:

Source: https://github.com/slog-rs/slog/issues/157#issuecomment-354695001
> `log` has one global logger, and that's where everything lands.

Source: https://github.com/slog-rs/slog/issues/169#issuecomment-384061697
> Problems with global state just won't go away...

Source: https://github.com/slog-rs/slog/issues/169#issuecomment-384061697
> IIRC, the guard was added so that ther's something reliabily dropping `slog-async::Async` so that logging messages are flushed, to avoid a pitfall.

(The typos are the source's.)

**Inferred**

Inferred: the core's "tree-structured loggers" and per-`Logger` key-value context follow the program's logical structure only when child loggers are values handed to sub-components. `slog-scope` shows a global can coexist with child loggers, but it ties them to the call stack instead, which is the cost the author states above. No author states the link to tree-structured loggers.

**No stated rationale found**

Not applicable: reasons are stated above.

**Constraints**

- Deployment: a library crate; the application composes drains (`slog-term`, `slog-async`, `slog-json`).
- Guarantee: the root drain passed to `Logger::root` must never return errors, forcing the application to pick an error strategy (crate docs).
- Failure: no global, so no unset state in the core; `slog-scope` discards before setup and panics after its guard drops.
- History: `slog-stdlog` bridges `log`'s global into `slog-scope`, so programs migrate without rewriting call sites (FAQ, "Can I try slog without modifying my code").

**Costs and dissent**

- Threading a logger everywhere. User `quodlibetor` (contributor), #157:

Source: https://github.com/slog-rs/slog/issues/157
> So I've looked at #37 and [the example library](https://github.com/slog-rs/example-lib/blob/master/lib.rs) and it seems like there is no good way for a library to set itself up for logging in the way that the application wants, without requiring that apps thread Loggers through everything.

  The maintainer closed it as "nothing actionable", pointing at `slog-scope` and suggesting a registry could live outside the core (comments `354695001`, `364855296`, `364855499`). #311 ("Is there a way to not pass Logger to every function", 2022) got only a link to `slog-scope`.
- The global's failure default. User `pjenvey`, #169 (open):

Source: https://github.com/slog-rs/slog/issues/169
> I think this is a bad default, especially for test suites. It's not uncommon to startup/teardown logging during tests.

- Test capture is stdout-only and fails across threads: `TestStdoutWriter`'s `# Note` says it has no effect once the logger goes to a thread the harness does not control.
- Later position: the README now points to `tracing` (Dawid Ciężarkiewicz, commit `76ab559`, 2021-10-06, per `git blame`), for async support and community size, not explicit passing:

Source: https://github.com/slog-rs/slog/blob/v2.8.2/README.md
> Please check [tracing](https://github.com/tokio-rs/tracing) and see
> if it is more suitable for your use-case. It seems that it is already
> a go-to logging/tracing solution for Rust.

- The wiki page "Things to make different next time around (slog v3?)" (Dawid Ciężarkiewicz, 2018; wiki HEAD `2a3af71`) lists eight changes; none concerns explicit passing or a global.

**Unverified**

- Whether the panic claim was true at 4.0.0 and changed later; only v4.4.1 was read.
- Who wrote the "**flexible**" line; `git blame` failed on the partial clone.

### H2. zap (Go), explicit (1.28.0)

Uber's Go logger: a `*zap.Logger` built in `main` and passed; globals `L()` and `S()` kept for migration and discouraged. Tag `v1.28.0`, read 2026-11-24.

**What it does**

`ReplaceGlobals` replaces `L()` and `S()` and returns a restore function. The global starts as a no-op (`_globalL  = NewNop()` in `global.go`).

Tests build a logger per test: `zaptest` writes to `testing.TB` (printed only on failure or `-v`); `zaptest/observer` keeps an in-memory, encoding-agnostic record of entries for unit-testing log output.

**The stated why**

The FAQ, added by Akshay Shah in PR #469 (merged 2017-07-06); Akshay Shah also wrote `L()` and `S()` (commit `c555037`, `git blame` at `v1.28.0`) and is the top committer per the GitHub contributors API:

Source: https://github.com/uber-go/zap/blob/v1.28.0/FAQ.md
> Since so many other logging packages include a global logger, many
> applications aren't designed to accept loggers as explicit parameters.
> Changing function signatures is often a breaking change, so zap includes
> global loggers to simplify migration.

Source: https://github.com/uber-go/zap/blob/v1.28.0/FAQ.md
> Avoid them where possible.

Akshay Shah, reviewing PR #266 (a proposed `zapglobal` package, 2017-02-02):

Source: https://github.com/uber-go/zap/pull/266#issuecomment-277098242
> While I acknowledge that people want this, I think it's a pretty terrible antipattern; loggers should be injected into functions and structs that need them. If that's painful, it should be solved with dependency injection, not globals.

Abhinav Gupta (`abhinav`, collaborator), #717 (2019), on why `L()` prints nothing by default:

Source: https://github.com/uber-go/zap/issues/717#issuecomment-496612544
> Zap prefers not to provide implicit default global behavior, favoring explicit
> configuration in your `main()`.

(Line breaks collapsed: the source uses CRLF.)

Source: https://github.com/uber-go/zap/issues/717#issuecomment-496640441
> Hello. No, we believe that it's cleaner software design to not rely on any
> global state in our applications. We believe that the verbosity trade-off is
> worth it. The trade-off of Zap may not be worth it for simple systems.

(Line breaks collapsed: the source uses CRLF.)

Prashant V (`prashantv`, collaborator), #924 (2021):

Source: https://github.com/uber-go/zap/issues/924#issuecomment-789461851
> We recommend using dependency injection, and passing `*zap.Logger` explicitly as part of constructors.

On why there is no global `SetLevel`, #870:

Source: https://github.com/uber-go/zap/issues/870#issuecomment-715566103
> zap doesn't have a `SetLogger` method, because a child logger passed to some library should not have the ability to change the log level for all other loggers.

**Inferred**

- Inferred: the global defaults to no-op so it does nothing until `main` configures it, matching "favoring explicit configuration in your `main()`"; the maintainers state the preference, not this link.
- Inferred (from `global.go`; no document says so): a test can swap the globals with `ReplaceGlobals` and restore them, but the swap is process-wide and shared by parallel tests.

**No stated rationale found**

Not applicable: reasons are stated above.

**Constraints**

- Deployment: an in-process library; the application owns construction.
- Guarantee: `L()`, `S()` and `ReplaceGlobals` are documented safe for concurrent use (`global.go`).
- Failure: an unconfigured global silently drops every record.
- History: Peter Edge (`bufdev`, contributor) proposed `zapglobal` in PR #266 (closed unmerged); Akshay Shah counter-proposed plain `zap.L`/`zap.S` while calling globals an antipattern, and merged PR #271 implementing it. The FAQ later gave migration as the reason.

**Costs and dissent**

- The silent no-op surprises users: #717 (`dfang`, 2019) asks why `zap.S()` "outputs nothing"; a later commenter:

Source: https://github.com/uber-go/zap/issues/717#issuecomment-986323404
> can we make this more clear in the documentation? I spent 10-30min wondering why the global logger produces no output.

- A library on the global is reachable only by replacing the global: in #870 (`celesteking`) a third-party library logged through `zap.L()` and the user could not set its level; the answer was a new logger plus `ReplaceGlobals` (comment `715566103`). The thread was locked.
- Threading cost: `dfang` (#717) found "it's a little tricky for to use "pass it down" pattern" and asked about "import then log" (comment `496783195`); the maintainer said they were "free to use that pattern if it works for you" (`497019548`).
- The requester agreed globals are an antipattern. `bufdev` (no name on profile; the quoted reply email is addressed to Akshay Shah), PR #266:

Source: https://github.com/uber-go/zap/pull/266#issuecomment-277198252
> Also I completely agree in general it's a terrible antipattern, but it's one I have a hard time fighting against.

- No reversal: globals and FAQ unchanged at v1.28.0.

**Unverified**

- Akshay Shah's formal role; the API labels the account `CONTRIBUTOR` on the 2017 threads, so the role rests only on blame, the contributors API and the PRs.

### H3. `prometheus-client` (Rust, the official OpenMetrics client), explicit (0.26.0 at `5801bff`)

The Prometheus organisation's Rust client: an explicit `Registry`, no default. Read 2026-11-24.

**What it does**

A caller creates a `Registry`, registers metrics with it, and passes it to an encoder. No default or global registry: https://docs.rs/prometheus-client/0.26.0/prometheus_client/all.html has no statics (functions are encoders and bucket helpers only), and a grep of `src/` at `v0.26.0` for `global`, `default_registry`, `lazy_static`, `OnceLock`, `OnceCell` and `static X:` finds nothing. Tests create a `Registry`, encode it to a `String` and assert on the text, as the `Registry` doctest does.

**The stated why**

Max Inden (`mxinden`, `MEMBER` of the prometheus GitHub organisation; crates.io co-owner with `krisztianfekete`), #25 "Global registry pattern" (2021-11-13), when the crate was `open-metrics-client`:

Source: https://github.com/prometheus/client_rust/issues/25#issuecomment-968138848
> I am undecided on the topic of global registries. Not offering it within `open-metrics-client` thus far has been by design.

Source: https://github.com/prometheus/client_rust/issues/25#issuecomment-968138848
> - I consider global variables in general and a global metric registry in specific error prone. The implicit side effect of registering metrics with a global registry might catch folks by surprise, e.g. when importing an external library for the sake of a single helper function.

Source: https://github.com/prometheus/client_rust/issues/25#issuecomment-968138848
> My proposition moving forward: Instead of adding a global registry to `open-metrics-client`, add an example showcasing how users can define it themselves, including a disclaimer on how they might be shooting themselves in the foot.

Earlier, while "helping to maintain" the older `prometheus` crate (his words in #392), tikv/rust-prometheus#336, 2020-07-07:

Source: https://github.com/tikv/rust-prometheus/issues/336#issuecomment-654723275
> Lastly I would like to advocate using a custom registry in the first place, as it prevents all issues connected to the general problem of global state.

His own word is "undecided": the absence is a choice "thus far", not final.

**Inferred**

None.

**No stated rationale found**

Not applicable: the reason is stated above.

**Constraints**

- Deployment: a library; the application owns the registry and HTTP endpoint.
- README guarantees: no `unsafe`, type safety, speed.
- Departs from the Prometheus client-library guideline requiring a default registry (H7); the README's list of where the crate "lags behind" OpenMetrics omits this.
- History: written from scratch by Max Inden as `rust-open-metrics-client`, proposed as the `prometheus` crate's successor in tikv/rust-prometheus#392 (2021-02-21); `roidelapluie` ("Julien from the Prometheus team") wrote there that it was likely to be adopted as an official implementation under the Prometheus organisation (comment `968072946`).

**Costs and dissent**

- #25 (`thedodd`, open since 2021-11-12) asks for a built-in global; the older crate's default "definitely makes getting started quite easy". `adamchalmers` (contributor) was "a bit reluctant to sit down and do the work of figuring out a global registry myself" (comment `1062202939`), then argued:

Source: https://github.com/prometheus/client_rust/issues/25#issuecomment-1251182822
> I actually think this is a non-issue. You don't need a global registry, you need global _metrics_.

- `huntc` (#25, comment `1221122163`) cites the guideline as requiring a default registry.
- Users build their own: PR #291 (`BentEngbers`, open, 2025-12-30) adds an example with "a global registry and global metrics" for migrating from `prometheus`; a reviewer noted a lazily initialised counter is absent from output until first touched (comment `3821646765`).
- No reversal: no default at v0.26.0; #25 still open.

**Unverified**

- When `open-metrics-client` was renamed; the v0.26.0 CHANGELOG records no rename (old name from Max Inden's comment).
- Max Inden's formal role beyond the `MEMBER` label and crates.io ownership.
- Whether the OpenMetrics specification requires or forbids a default registry; not read.

### H4. go-kit `log` (Go), explicit (go-kit/log 0.2.1 at `0b69c70`; go-kit/kit 0.13.0 at `dfe43fa`)

Go kit's logger: explicit `Logger` values; the package default was removed in 2015. Read 2026-11-24.

**What it does**

`Logger` is a one-method interface built in `main` and passed, usually as a per-component child (`log.With(logger, "component", "worker")`). No package-level logger: a grep of every non-test `.go` file at `v0.2.1` (including `level/`, `term/`, `syslog/`) for package-level `var`s finds errors, an encoder pool, a regex, the `DefaultTimestamp`/`DefaultCaller` valuers, level values and colour tables, none a `Logger`. For a library wanting a package-scoped logger, `SwapLogger` "serves well as a package global logger that can be changed by importers"; its zero value discards. The package began as `github.com/go-kit/kit/log` (deprecation notice in go-kit/kit `v0.13.0`); the old path aliases the new. Tests log into a `bytes.Buffer` (`log.NewLogfmtLogger(buf)`) and read it.

**The stated why**

Chris Hines (`ChrisHines`, go-kit organisation member), go-kit/kit#42 "Proposal: Remove log.DefaultLogger" (2015-05-22):

Source: https://github.com/go-kit/kit/issues/42
> Logging is an application concern and should be controlled by applications. Each application should decide how log events are filtered and routed.

Source: https://github.com/go-kit/kit/issues/42
> Each source of log events should provide a mechanism for accepting a `Logger` implementation from the main application.

Source: https://github.com/go-kit/kit/issues/42
> Packages that do not create log events do not need any of these. Thus, **`log.DefaultLogger` is not needed as package log is not a source of log events**.

Peter Bourgon (`peterbourgon`, organisation member) agreed with the first two sentences and closed it "This is done!" (comment `105806372`). Commit `ec30ded` "Remove DefaultLogger" (PR #46, 2015-05-25) deleted `log/default_logger.go` and gave the one internal user, the Zipkin collector, its own swappable package logger. Chris Hines restated the position in the `log/slog` review (H5), citing this issue.

**Inferred**

None.

**No stated rationale found**

Not applicable: reasons are stated above.

**Constraints**

- Deployment: a toolkit for services; the application wires every component.
- Failure: `Log` returns an `error`; a zero `SwapLogger` discards without error.
- History: removed May 2015; go-kit/kit's first tag `v0.1.0` points at a 2016-06-07 commit, so the default never shipped in a tagged release.

**Costs and dissent**

- Peter Bourgon, same thread:

Source: https://github.com/go-kit/kit/issues/42#issuecomment-104995733
> There are situations where this isn't practical. Consider a library that maintains a persistent connection to some backing service. Intermittent failures should be reported, so operators can correlate problems, but parameterizing a logger or reporting channel in the API likely violates principles of encapsulation.

  Chris Hines (comment `105344724`): exceptions "should be rare", and such libraries "are coupling themselves to a particular logging API". The shipped compromise is the package-scoped `SwapLogger`, not a shared default.
- No reversal: v0.2.1 has no default logger.

**Unverified**

- Later dissent in the go-kit tracker was not searched (the GitHub search rate limit was shared across the whole survey).

### H5. Go `log/slog`, contrast (Go 1.27.4; design doc at proposal commit `f990ad7`)

Go's standard structured logger: a default logger beside explicit `Logger` values. Read 2026-11-24.

**What it does**

Both. `slog.New(h)` returns an explicit `*Logger`; a package default, set with `SetDefault`, backs `slog.Info` and the other top-level functions, and before `SetDefault` writes through the `log` package. The design doc: "There is a single, global default `Logger`." A grep of non-test `src/log/slog/*.go` at `go1.27.4` finds no `NewContext`, `FromContext` or context key.

The package docs, on avoiding duplicate keys, say to pass each subsystem a different `Logger`; the example derives it from the default. Tests build a `Logger` over a buffer-writing handler or `DiscardHandler`; `testing/slogtest` tests `Handler` implementations and does not capture an application's records.

**The stated why**

Jonathan Amsterdam (`jba`), author of the proposal and design doc, golang/go#56345, answering a reviewer who opposed any default:

Source: https://github.com/golang/go/issues/56345#issuecomment-1404157567
> @ChrisHines, we know there is controversy about providing a default logger, but it comes down to these two points: making it  easy to get started, and making it possible to add debug logging anywhere in a program without disrupting the code any more than necessary and risk adding more bugs. Removing the context functions only makes that more important. I agree that good code should plumb loggers through somehow, but it's not always easy or feasible.

Source: https://github.com/golang/go/issues/56345#issuecomment-1404157567
> It should be easy to find these calls statically, and you can install a default Handler that alerts if it's called.

Same author, on why built-in handlers never refer to the default, why the context logger was dropped (2023-01-13), and who may set the default:

Source: https://github.com/golang/go/issues/56345#issuecomment-1320879084
> Think of it from the perspective of someone who is trying to avoid all global state. They can do so by avoiding the default logger and its global functions, always creating their own loggers and handlers.

Source: https://github.com/golang/go/issues/56345#issuecomment-1381910606
> There is clearly a lot of controversy around the idea of adding a logger to a context. That feature is independent of the rest of the proposal, and easy for anyone to implement outside of the standard library. So we've decided to remove the `NewContext`, `FromContext` and `Ctx` functions.

Source: https://github.com/golang/go/issues/56345#issuecomment-1404265057
> A non-main package calling `slog.SetDefault` is a design flaw.

**Inferred**

None.

**No stated rationale found**

Not applicable: reasons are stated above.

**Constraints**

- Deployment: standard library under the Go 1 compatibility promise; must interoperate with the global `log` package.
- Failure: an unconfigured default writes text through `log`'s output and never panics; below Info it drops records unless `SetLogLoggerLevel` lowers the threshold (`logger.go`).
- History: the proposal (2022-10-19) had `NewContext`/`FromContext`, removed January 2023 after review; the default logger was kept.

**Costs and dissent**

Reviewers, not authors. Chris Hines (`ChrisHines`, contributor on this issue; proposer of go-kit's removal, H4):

Source: https://github.com/golang/go/issues/56345#issuecomment-1401382937
> I don't think a structured logging package should provide a default logger or top level functions that log to it. I first argued this case [while developing the Go kit log package](https://github.com/go-kit/kit/issues/42) many years ago, and I haven't seen anything to change my opinion since.

Source: https://github.com/golang/go/issues/56345#issuecomment-1401382937
> We have completed that refactor now and during the process we found essentially zero cases where a local logger wasn't available.

Sean Liao (`seankhliao`, `MEMBER` on golang/go):

Source: https://github.com/golang/go/issues/56345#issuecomment-1302726325
> imo this points to the global logger being an unnecessary distraction.
> We really want to ensure nothing goes through a global logger, tracking down errant callers is not a fun task.

(Line breaks collapsed: the source uses CRLF.)

**Unverified**

- The preceding discussion golang/go#54763 was not read (GitHub Discussions are not reachable through the REST endpoints the quotation check uses).

### H6. Rust `prometheus` crate (tikv), contrast (0.14.0 at `e07efb4`)

The older Rust Prometheus client: a default registry beside explicit ones. Read 2026-11-24.

**What it does**

Both. A `lazy_static` global registry backs `register`, `gather` and the `register_*!` macros, which register with it by default; `Registry::new()` and `register_*_with_registry!` give explicit registries. `registry.rs` documents `default_registry()` as "Default registry (global static)".

Tests create a `Registry` and use the `_with_registry` variants (what #386 below asked for); the plain macros register globally, so a second registration of a name fails.

**The stated why**

No author rationale found. The README says the API follows the Go client (`client_golang`). The global came in PR #15 "Add a global registry" (2016-08-25, `overvenus`), resolving #13 (`siddontang`), a bare usage sketch; neither thread gives a why beyond "LGTM".

**Inferred**

Inferred: the default mirrors the Go client and the Prometheus guideline (H7). A later maintainer confirms the Go-mirroring in general terms:

Source: https://github.com/tikv/rust-prometheus/issues/392#issuecomment-783070641
> 1. I think a whole code refactoring is necessarily, considering that previously the interfaces are designed to be as much close with Golang's library as possible, which brings some performance pitfalls and not respecting some Rust best practices or utilizing some Rust nice features.

**No stated rationale found**

Looked at #13 and PR #15 with all comments, and the README and crate docs at `v0.14.0`: no author says why the default exists.

**Constraints**

- Deployment: a library crate; the application exposes `gather()` output.
- Failure: registration returns a `Result`; a duplicate name on the default fails with `AlreadyReg` (#386), and the `register_*!` macros return that `Result`.
- A process collector registers on the default at first use only with the `process` feature, which is not a default feature, and only on Linux; otherwise nothing is registered (`registry.rs`):

Source: https://github.com/tikv/rust-prometheus/blob/v0.14.0/src/registry.rs
>     if #[cfg(all(feature = "process", target_os="linux"))] {

Source: https://github.com/tikv/rust-prometheus/blob/v0.14.0/Cargo.toml
> default = ["protobuf"]

- History: default added in PR #15 (2016-08-25).

**Costs and dissent**

- Tests. User `sazzer`, #386 (open):

Source: https://github.com/tikv/rust-prometheus/issues/386
> However, because it always registers with the default registry, this means that I can only call it once per thread. Running multiple tests thus hits problems because it's trying to register the same metric in different tests, and all but the first then fails with `AlreadyReg`.

- Max Inden's objection to a `clear` on the global (#336, H3).
- The successor, `prometheus-client`, dropped the default (H3).

**Unverified**

None beyond the absence above.

### H7. Python `prometheus_client`, contrast (0.26.0; guideline at prometheus/docs commit `31957d4`)

The Python Prometheus client: a default `REGISTRY`. Read 2026-11-24.

**What it does**

Both, global by default. `REGISTRY = CollectorRegistry(auto_describe=True)`; every metric constructor takes `registry=REGISTRY` and the docs say all constructors register with it "automatically unless told otherwise"; `registry=None` skips registration and `CollectorRegistry()` gives an isolated one. Tests use a private `CollectorRegistry` (the docs mark skipping global registration as "useful in tests") and `get_sample_value`, "intended only for use in unittests".

**The stated why**

The client's docs state none. The Prometheus guideline for every client library requires the default and gives a reason; it was added to prometheus/docs in commit `7397876` (2016-04-05, committed by Johannes Ziemke), and the history does not show the drafter.

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md
> Users shouldn’t have to worry about plumbing their metrics throughout
> their code, the client library should do that for them (and if it doesn’t,
> users will write a wrapper around the library to make it "easier" - which
> rarely tends to go well).

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md
> There MUST be a default CollectorRegistry, the standard metrics MUST by default
> implicitly register into it with no special work required by the user. There
> MUST be a way to have metrics not register to the default CollectorRegistry,
> for use in batch jobs and unittests.

**Inferred**

Inferred: the client's default follows this guideline; its source and docs at `v0.26.0` never cite it (grep for `writing_clientlibs`, `clientlib_guidelines`, "client library guidelines" finds nothing).

**No stated rationale found**

For the client itself: none in `docs/content/` or `prometheus_client/` at `v0.26.0` (grep for "global" returns only descriptive lines).

**Constraints**

- Deployment: a library; the application exposes metrics (`start_http_server`, `generate_latest`, or a WSGI/ASGI app).
- Failure: registering a name already present raises `ValueError` ("Duplicated timeseries in CollectorRegistry"), at import time for module-level metrics; `auto_describe=True` makes the default check duplicates at registration.
- History: the guideline dates from 2016; whether the client's default predates it was not checked.
- Multiprocess mode needs a fresh registry, not the default (maintainer `csmarchbanks`, #626, comment `777799689`).

**Costs and dissent**

- Reloading and repeated imports. User `arrdem`, #993 (open):

Source: https://github.com/prometheus/client_python/issues/993
> The real solution is that we should be explicitly managing and lifecycling registries, but the library default behavior of using a shared global registry creates this pitfall.

  Maintainer Chris Marchbanks (`csmarchbanks`, member) preferred an error on duplicates and floated making it "easier to clear an entire registry (including the default registry)" (comment `1911094553`).
- #1042 (open): a module-level metric breaks IPython autoreload.
- Recurrent "Duplicated timeseries" reports: #626 (Gunicorn multiprocess on the default) was fixed with a fresh `CollectorRegistry()`; #745 asks how to avoid re-creating an existing metric.

**Unverified**

- The guideline text's author; blame ends at the 2016 commit that added the file.

#### Leads that did not hold (chose otherwise)

None failed on the facts; each held with a qualification:

- **slog-rs and `slog-scope`.** Explicit values and a discouraged optional global hold. `slog-scope`'s docs say it panics when unset; the v4.4.1 source discards until set and panics only after the guard drops (H1; slog-rs/slog#169). No reversal of explicit passing; the README's pointer to `tracing` cites async support and community.
- **zap's globals and FAQ.** Hold. The stated reason for the globals is migration, and they default to no-op, so an unconfigured `zap.L()` drops everything.
- **Rust `prometheus-client`, no default.** Holds (item index and grep, H3). The author calls the position "undecided", "by design" "thus far"; #25 is open; the crate departs from the guideline's "There MUST be a default CollectorRegistry".
- **Rust `prometheus` default registry.** Holds: `default_registry()`, a `lazy_static` global (H6); no author-stated reason found.
- **Go `log/slog`, default plus explicit.** Holds, but belongs with the contrasts. What review dropped was the `context.Context` logger (`NewContext`, `FromContext`, `Ctx`, removed 2023-01-13); none exists at `go1.27.4`.
- **Python `prometheus_client`, `REGISTRY` default.** Holds: default for every constructor, explicit registries the opt-out; the client states no reason, the guideline does.

## S. Structured concurrency

Where the idea was stated by those who introduced it, and by the languages that built on it.

Seven sources, read 2026-11-24, to test a claim made from memory: "Structured concurrency says every background activity lives inside a scope that someone visibly opens and closes." No verdict on fit. **[ticket 13]** marks a finding on a background writer that dies or on how long a scope's end waits (ticket 13 and two open questions); it is not weighed.

### S1. Martin Sústrik and libdill (libdill `2.14` at `d958f29`; posts via Wayback)

Sústrik coined the term in "Structured Concurrency" (February 7th, 2016) and wrote libdill, a C coroutine library. The original post URLs return 404 and `libdill.org` returns 403, so the posts are quoted from 2018 and 2019 Wayback snapshots and libdill from its repository at tag `2.14` (released Feb 28th, 2019).

**What it does**

*Promise.* A green thread may not outlive its launcher. libdill's scope is a handle, not a block: closing it cancels the child, and once `hclose` returns the child has finished. It is done by hand, as idiomatic C, visible only as the `go`/`hclose` pair the programmer writes and not enforced by the language.

Source: https://github.com/sustrik/libdill/blob/d958f29e0e4b2e09da44cd9bd284c65795d6c472/website/src/structured-concurrency.md
> Structured concurrency means that lifetimes of concurrent functions are cleanly nested. If coroutine `foo` launches coroutine `bar`, then `bar` must finish before `foo` finishes.

*Way out for long-lived work.* The 2016 post allows it by analogy with a heap variable freed by hand; libdill's documentation gives the same pattern, an object that opens and closes its background coroutines.

Source: https://web.archive.org/web/20190211184210/http://250bpm.com/blog:71
> That's it. The lifetime of the green thread is now managed manually by the owner(s) of the connection object.

Source: https://web.archive.org/web/20190211184210/http://250bpm.com/blog:71
> Some goroutines may be left running in a infinite loop just to get canceled when the process exits. These are equivalent to green threads launched in global scope. It's really hard to think of a fitting use case.

*When a child fails.* See **Inferred**. **[ticket 13]**

*When a child will not finish.* The 2016 post answers with a grace period. In libdill `hclose` cancels and still waits; `bundle_wait` with a deadline, then `hclose`, gives a wait followed by a cancel. **[ticket 13]**

Source: https://web.archive.org/web/20190211184210/http://250bpm.com/blog:71
> In real-world case we want a mixture of both, but the trivial case is the latter: Imagine that bar() is some kind of generator running in an infinite loop. If foo() waited for it to finish, it would be stuck forever.

Source: https://web.archive.org/web/20190211184210/http://250bpm.com/blog:71
> Let's also add timeout parameter to our gocancel() function. The cancellation of the child thread will begin after the timeout expires.

Source: https://github.com/sustrik/libdill/blob/d958f29e0e4b2e09da44cd9bd284c65795d6c472/website/src/structured-concurrency.md
> From point 3. on, all the blocking calls in the child coroutine start to return `ECANCELED` error. The call to `hclose()` won't finish until the worker coroutine exits.

Source: https://github.com/sustrik/libdill/blob/d958f29e0e4b2e09da44cd9bd284c65795d6c472/website/src/structured-concurrency.md
> In the second scenario, there are still some children running when deadline is reached. `bundle_wait()` exits with `ETIMEDOUT` at point 4. The remaining coroutines are canceled at point 5.

**The stated why**

Martin Sústrik, author of the term and of libdill, in the libdill documentation, then in the 2016 post:

Source: https://github.com/sustrik/libdill/blob/d958f29e0e4b2e09da44cd9bd284c65795d6c472/website/src/structured-concurrency.md
> The goal of structured concurrency is to guarantee encapsulation.

Source: https://web.archive.org/web/20190211184210/http://250bpm.com/blog:71
> The rest of the article will explore the question of cancellation and will propose a model of "structured concurrency" to deal with it.

**Inferred**

- A libdill coroutine is declared `coroutine void foo(...)` in the documentation's examples, so it has no return channel for an error. The documentation describes no mechanism that propagates a child's failure to its parent or cancels its siblings; results and errors travel through channels the programmer creates. **[ticket 13]**

**No stated rationale found**

Not applicable.

**Constraints**

- **Deployment model.** Single-threaded, cooperatively scheduled C coroutines. Sústrik's 2018 update says every implementation he knew is single-core, and that he implemented and deleted an OS-process variant:

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> What that means is they can't use structured concurrency on more than one CPU core.

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> The reason was that implementation of threads in the C standard library (pthreads) is complex and fragile.

- **History.** libdill 2.1 (Feb 1st, 2018) added coroutine bundles; 2.5 (Mar 3rd, 2018) added `bundle_wait`; the 2016 post proposed `gocancel(handle, deadline)`.

**Costs and dissent**

In "Update on Structured Concurrency" (October 19th, 2018, snapshot of 2018-11-30), Sústrik warns against equating a scope with a bundle cancelled in parallel at scope exit, with a logging thread as the example; describes `bundle_wait()`'s deadline (wait, then cancel what still runs); and doubts Trio can express this. **[ticket 13]**

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> It may happen that the logging thread would exit first. In that case all the logs produced by the connections while they are shutting down would be lost.

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> What we really want is shutting down the connections first, then shutting down the logging thread.

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> To be frank, I am not sure whether this scenario can be implemented in Trio.

In "Structured Concurrency in High-level Languages" (April 28th, 2018, snapshot of 2018-12-05):

Source: https://web.archive.org/web/20181205063621/http://250bpm.com/blog:124
> Implementing structured concurrency in higher-level languages is not entirely trivial and poses some hard design questions.

**Unverified**

- The original post URLs `https://250bpm.com/blog:71`, `blog:124` and `blog:137` return 404 (curl, 2026-11-24); `http://libdill.org/structured-concurrency.html` returns 403. As of 2026-11-24 the author's site has a post of the same title, `https://www.250bpm.com/p/structured-concurrency`, dated Jun 29, 2024 (no version). Its body does not say it republishes the 2016 post. Each of the five `blog:71` quotations above was found verbatim in its text. Its links to parts 1 and 2 were not checked. The site's sitemap lists no counterpart for `blog:124` or `blog:137`, so those snapshots were not compared with a live copy.

### S2. Nathaniel J. Smith's essay and Trio (essay of 25 April 2018; Trio `v0.35.0` at `3b280b0`)

Smith's essay "Notes on structured concurrency, or: Go statement considered harmful" (dated URL, no version) popularised the term. Trio, his Python async library, was read at tag `v0.35.0` (released 2026-10-31), quoting the repository source, not the rendered `https://trio.readthedocs.io/en/v0.35.0/reference-core.html`.

**What it does**

*Promise.* A child can be started only inside a nursery, the `async with trio.open_nursery()` block, which waits for every child:

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> Crucially, the nursery block doesn't exit until all the tasks inside it have exited – if the parent task reaches the end of the block before all the children are finished, then it pauses there and waits for them.

(Line breaks collapsed: the source HTML is hard-wrapped.)

*Way out for long-lived work.* Pass a nursery in, which the essay calls "an escape"; tasks spawned into it are still bound by that nursery's lifetime. Trio's documentation covers the same pattern. Trio's "system" tasks need no explicit nursery.

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> What if you really do need to write a function that spawns a background task, where the background task outlives the function itself? Easy: pass the function a nursery object.

(Line breaks collapsed: the source HTML is hard-wrapped.)

Source: https://github.com/python-trio/trio/blob/v0.35.0/src/trio/_core/_run.py
>         * They don't need an explicit nursery; instead they go into the
>           internal "system nursery".

Source: https://github.com/python-trio/trio/blob/v0.35.0/src/trio/_core/_run.py
>         * System tasks are automatically cancelled when the main task exits.

On async-sig, a user (Dima Tisnek, not a Trio author) asked for daemon tasks, one being a logging tail; Smith, Trio's author, replied, and gave a pattern: an object owning background tasks takes a nursery that an async context manager opens. **[ticket 13]**

Source: https://mail.python.org/pipermail/async-sig/2018-April/000479.html
> Finally, slob programmers like me occasionally want fire-and-forget
> tasks, aka daemonic threads.

Source: https://mail.python.org/pipermail/async-sig/2018-April/000480.html
> Well, what semantics do you want? If the battery status poller
> crashes, what should happen? If the "tail part of low-latency logging"
> command is still running when you go to shut down, do you want to wait
> a bit for it to finish, or cancel it, or ...?

*When a child fails.* Siblings are cancelled, then the error is re-raised. Since Trio 0.25 errors are grouped by default, for a reason from production. A deprecated `strict_exception_groups=False` argument to `trio.run` and `trio.open_nursery` still restores the old single-exception behaviour at `v0.35.0`, with a deprecation warning (read from source, not run). A failing system task takes down the whole run. **[ticket 13]**

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> The answer is that when an unhandled exception occurs in a child, Trio immediately cancels all the other tasks in the same nursery, and then waits for them to finish before re-raising the exception.

(Line breaks collapsed: the source HTML is hard-wrapped.)

Source: https://github.com/python-trio/trio/blob/v0.35.0/docs/source/reference-core.rst
> Unfortunately, the results were not good: calling code often didn't realize that
> some function *could* raise a ``MultiError``, and therefore handle only the common
> case - with the result that things would work well in testing, and then crash under
> heavier load (typically in production).

Source: https://github.com/python-trio/trio/blob/v0.35.0/docs/source/reference-core.rst
> We currently support a compatibility argument ``strict_exception_groups=False`` to
> `trio.run` and `trio.open_nursery`, which restores the old behavior (although
> ``MultiError`` itself has been fully removed).  We strongly advise against it for
> new code, and encourage existing uses to migrate - we consider the option deprecated
> and plan to remove it after a period of documented and then runtime warnings.

Source: https://github.com/python-trio/trio/blob/v0.35.0/src/trio/_core/_run.py
>         * If a system task raises an exception, then it's converted into a
>           :exc:`~trio.TrioInternalError` and *all* tasks are cancelled. If you
>           write a system task, you should be careful to make sure it doesn't
>           crash.

*When a child will not finish.* The nursery waits as long as it takes. Cancellation is a separate cancel scope placed outside it (e.g. `trio.move_on_after`). **[ticket 13]**

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> When this happens, the nursery always waits for the full cleanup to happen.

(Line breaks collapsed: the source HTML is hard-wrapped.)

Source: https://github.com/python-trio/trio/blob/v0.35.0/docs/source/reference-core.rst
> In Trio, child tasks inherit the parent nursery's cancel scopes. So in
> this example, both the child tasks will be cancelled when the timeout
> expires:

**The stated why**

Nathaniel J. Smith, Trio's author, in the essay (Trio's documentation says the same: no supervisor may leave orphans, and unhandled exceptions propagate):

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> With nurseries, you don't have to worry about this: any function can open a nursery and run multiple concurrent tasks, but the function can't return until they've all finished.

(Line breaks collapsed: the source HTML is hard-wrapped.)

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> If an error occurs in a background task, and you don't handle it manually, then the runtime just... drops it on the floor and crosses its fingers that it wasn't too important.

(Line breaks collapsed: the source HTML is hard-wrapped.)

**Inferred**

None.

**No stated rationale found**

Not applicable.

**Constraints**

- **Deployment model.** A Python async library; the scope is lexical, and cancellation arrives as an exception at checkpoints.
- **History.** The essay credits Sústrik in footnote [3]. Errors became grouped by default in Trio 0.25, and `strict_exception_groups=False`, which restores the old behaviour, is deprecated.

**Costs and dissent**

Smith, in the async-sig thread, then in the essay:

Source: https://mail.python.org/pipermail/async-sig/2018-April/000482.html
> You might expect to be able to use it that way, but you can't! The
> 'async with' part of 'async with open_nursery()' is mandatory.

Source: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/
> Unfortunately, to fully capture these benefits, we do need to remove the old primitives entirely, and this probably requires building new concurrency frameworks from scratch – just like eliminating goto required designing new languages.

(Line breaks collapsed: the source HTML is hard-wrapped.)

Two Trio issues on background services and shutdown are open as of 2026-11-24: #1521, "Idea: service nurseries" (2020-05-14, by Smith, `author_association` MEMBER), proposing that a nursery's background tasks be cancelled automatically when the nursery block exits, and shielded from cancellation before then; and #147, "More ergonomic support for graceful shutdown" (2017-05-02), where Smith weighs a grace period and notes a cost for code that runs forever. **[ticket 13]**

Source: https://github.com/python-trio/trio/issues/1521
> - background tasks are automatically cancelled when the nursery block exits

Source: https://github.com/python-trio/trio/issues/147#issuecomment-321420110
> Code that's cancellation-oblivious gets the full time to complete.

The documentation records a further cost, citing draft PEP 789: a nursery or cancel scope must not be held open across a `yield` in an async generator.

Source: https://github.com/python-trio/trio/blob/v0.35.0/docs/source/reference-core.rst
> use a cancel scope internally, so they have all the problems of cancel
> scopes plus a number of problems of their own: for example, when
> the generator is suspended, what should the background tasks do?

**Unverified**

- Whether the essay has changed since 2018: the page has no revision marker and was compared only with itself.

### S3. Python `asyncio.TaskGroup` (CPython `v3.15.2`)

The standard library's construct, added in 3.11; `TaskGroup.cancel()` is new in 3.15. Read at `Doc/library/asyncio-task.rst`, tag `v3.15.2`.

**What it does**

*Promise.* The scope is the `async with asyncio.TaskGroup() as tg:` block. It is not the only way to run a task: `asyncio.create_task` remains, documented for "fire-and-forget" work outside any group.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
>    All tasks are awaited when the context manager exits.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
>       For reliable "fire-and-forget" background tasks, gather them in
>       a collection::

*Way out for long-lived work.* Pass `tg` into a coroutine (the Trio pattern), or use unstructured `create_task`, documented with a warning. **[ticket 13]**

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> (for example, by passing ``tg`` into one of the coroutines
> and calling ``tg.create_task()`` in that coroutine).

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
>       Note that this approach never awaits the tasks, so if a task
>       fails, its exception is never retrieved and asyncio logs a
>       "Task exception was never retrieved" message when the task is
>       garbage collected.

*When a child fails.* Siblings and the body are cancelled; errors are raised as a group. **[ticket 13]**

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> The first time any of the tasks belonging to the group fails
> with an exception other than :exc:`asyncio.CancelledError`,
> the remaining tasks in the group are cancelled.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> Once all tasks have finished, if any tasks have failed
> with an exception other than :exc:`asyncio.CancelledError`,
> those exceptions are combined in an
> :exc:`ExceptionGroup` or :exc:`BaseExceptionGroup`

*When a child will not finish.* The block waits for every child, accepting new tasks meanwhile until the group starts shutting down. Children are cancelled when a child fails, when the body raises, or on `cancel()`. From then on `create_task` closes the coroutine and raises `RuntimeError`: the documentation says so for a failed child and for a group "in the process of shutting down"; for the body raising and for `cancel()` it was read from source, not run. **[ticket 13]**

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> If the body of the ``async with`` statement exits with an exception
> (so :meth:`~object.__aexit__` is called with an exception set),
> this is treated the same as if one of the tasks failed:

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
>       Cancel the task group.  This is a non-exceptional, early exit of the
>       task group's lifetime -- useful once the group's goal has been met or
>       its services no longer needed.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
>       If the task group is inactive (e.g. not yet entered,
>       already finished, or in the process of shutting down),
>       we will close the given ``coro`` and raise :exc:`RuntimeError`.

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> No further tasks can then be added to the group.

Source: https://github.com/python/cpython/blob/v3.15.2/Lib/asyncio/taskgroups.py
>         if self._aborting:
>             coro.close()
>             raise RuntimeError(f"TaskGroup {self!r} is shutting down")

**The stated why**

Guido van Rossum (`author_association` MEMBER; author of the merged PR #31270 that added the class), opening gh-90908 (bpo-46752) on 2022-02-14 and starting from EdgeDB's `TaskGroup`. In the same message he gives the reason for accepting new tasks while `__aexit__` waits. Then the documentation:

Source: https://github.com/python/cpython/issues/90908#issuecomment-1093944756
> After some conversations with Yury, and encouraged by the SC's approval of PEP-654, I am proposing to add a new class, asyncio.TaskGroup, which introduces structured concurrency similar to nurseries in Trio.

Source: https://github.com/python/cpython/issues/90908#issuecomment-1093944756
> The key change I made to EdgeDb's TaskGroup is that subtasks can keep spawning more subtasks while \_\_aexit__ is running; \_\_aexit__ exits once the last subtask is done. I made this change after consulting some Trio folks, who knew of real-world use cases for this behavior, and did not know of real-world code in need of prohibiting task creation as soon as \_\_aexit__ starts running.

(Markdown escapes as in the comment's source.)

Source: https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-task.rst
> Task groups combine a task creation API with a convenient
> and reliable way to wait for all tasks in the group to finish.

**Inferred**

- The class signature `.. class:: TaskGroup()` takes no arguments, so the group has no deadline parameter of its own. **[ticket 13]**

**No stated rationale found**

Not applicable.

**Constraints**

- **Deployment model.** An asyncio event loop.
- **What it guarantees.** `KeyboardInterrupt` and `SystemExit` are re-raised unwrapped. The loop holds only weak references to tasks, so a `create_task` task kept nowhere else can be garbage-collected.
- **History.** Merged in GH-31270 for 3.11; documented in June 2022; `cancel()` added under gh-108951 (PR #127214, merged 2026-04-24).

**Costs and dissent**

In gh-108951 van Rossum objected to the name "cancel", describing the wanted feature as stopping all tasks and exiting the block "peacefully" (not raising):

Source: https://github.com/python/cpython/issues/108951#issuecomment-1708830643
> It feels, at least to me, that "cancel" elicits all the wrong connotations, in an asyncio context, because it sounds like it would cause a CancelledError exception to propagate out.

`create_task` remains beside `TaskGroup`, so structure is not enforced. Trio's documentation says asyncio took the always-group rule from Trio's experience (S2).

**Unverified**

- EdgeDB's `taskgroup.py` was not read (the issue links it on `master`); the merged name and semantics of `cancel()` were not established beyond the 3.15.2 documentation.

### S4. Java `StructuredTaskScope`, JEPs 428 to 543 (JEP 543, "Updated" 2026/10/17)

The JDK's API, by Alan Bateman, Viktor Klang and Ron Pressler. JEP URLs carry no version, so each JEP is cited with its page's "Updated" stamp. From the index `https://openjdk.org/jeps/0`: incubators 428 (JDK 19, 2023/06/08) and 437 (20, 2023/06/08); previews 453 (21, 2025/02/27), 462 (22, 2025/02/27), 480 (23, 2025/02/25), 499 (24, 2025/02/11), 505 (25, 2025/10/09), 525 (26, 2026/04/02) and 533 (27, 2026/08/19), all Closed / Delivered; final 543, status **Integrated**, release 28 (2026/10/17). Quotations are from JEP 543 unless another is named.

**What it does**

*Promise.* Subtask lifetimes are confined to the try-with-resources body. From JEP 505 onward only the scope's owner may fork; up to JEP 499 any thread in the scope's tree could. A phrase count over the saved JEP pages dates the change: "not in the tree hierarchy" appears once in each of 428 to 499 and never in 505 to 543, and "not the scope's owner" the reverse.

Source: https://openjdk.org/jeps/543
> Under all conditions, their lifetimes are confined to a lexical scope, namely the body of the try-with-resources statement.

Source: https://openjdk.org/jeps/543
> For example, attempts to call a fork method from a thread that is not the scope's owner will fail with an exception.

Source: https://openjdk.org/jeps/499
> attempts to call fork(Callable) from a thread that is not in the tree hierarchy of the scope — i.e., the owner, the subtasks, and subtasks in nested scopes (sub-subtasks) — will fail with an exception.

*Way out for long-lived work.* Replacing `ExecutorService` or `Future` is a non-goal. JEPs 428 to 499 had a "Fan-in scenarios" section, a server whose owner runs without bound; `grep -c -i 'fan-in'` gives 2 for each of 428 to 499 and 0 for each of 505 to 543.

Source: https://openjdk.org/jeps/543
> It is not a goal to replace any of the concurrency constructs in the java.util.concurrent package, such as ExecutorService or Future.

Source: https://openjdk.org/jeps/499
> Here, unlike the previous examples, the scope's owner is unbounded in its duration — it will stop only when it is interrupted.

*When a child fails.* By default a failing subtask interrupts its siblings and `join()` throws; other `Joiner` policies, e.g. `allUntil` and custom joiners, may ignore failures. **[ticket 13]**

Source: https://openjdk.org/jeps/543
> Error handling with short-circuiting — If one of the findUser() or fetchOrder() subtasks fails, by throwing an exception, then the other is cancelled, i.e., interrupted, if it has not yet completed.

*When a child will not finish.* `close()` cancels, then waits with no bound; a timeout can be set when the scope opens. **[ticket 13]**

Source: https://openjdk.org/jeps/543
> Close the scope, usually implicitly via try-with-resources. This cancels the scope, if it is not already cancelled, thereby cancelling all of its remaining subtasks and waiting for them to terminate.

Source: https://openjdk.org/jeps/543
> Subtasks that do not respond to interrupts because, e.g., they block on methods that are not interruptible, may delay the closing of a scope indefinitely. The close method always waits for threads executing subtasks to finish, even if the scope is cancelled.

Source: https://openjdk.org/jeps/543
> In this example, if the timeout expires before or while waiting in join() then the scope is cancelled, which cancels all incomplete subtasks, and join() throws an ExecutionException with a CancelledByTimeoutException as the cause.

**The stated why**

The JEP's authors, named in its header; the JEP credits Sústrik with the term and Smith with popularising it.

Source: https://openjdk.org/jeps/543
> Promote a style of concurrent programming that can eliminate common risks arising from cancellation and shutdown, such as thread leaks and cancellation delays.

**Inferred**

None.

**No stated rationale found**

- Why JEP 505 narrowed `fork` to the owner and dropped the fan-in section. Its "History" paragraph mentions only the move to static factory methods and `Joiner`; the History sections of 505, 525, 533 and 543, read in full, give no reason. JEP 505's Alternatives section, read in full in triage on 2026-11-24, has only "Enhance the ExecutorService interface" and "Have the fork methods return a Future", and gives no reason either. The Alternatives sections of 525, 533 and 543 were not each read in full. The JBS issue JDK-8340343 refused an automated fetch (HTTP 403), and loom-dev was not searched.

**Constraints**

- **Deployment model.** JDK threads, virtual by default. Cancellation is interruption; replacing it is a non-goal.
- **What it guarantees.** Misuse fails at run time. A `fork` from a thread other than the owner throws `WrongThreadException` (JDK 25 API, and the JDK 28 early-access API, build 25, as of 2026-11-24). Leaving a scope without `close()`, or closing scopes out of nesting order, may throw `StructureViolationException`. Thread dumps show the scope tree.

Source: https://openjdk.org/jeps/543
> At run time, StructuredTaskScope enforces structure and order upon concurrent operations. For example, attempts to call a fork method from a thread that is not the scope's owner will fail with an exception. Using a scope outside of a try-with-resources block and returning without calling close(), or without maintaining the proper nesting of close() calls, may cause the scope's methods to throw a StructureViolationException.

Source: https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/StructuredTaskScope.html
> WrongThreadException - if the current thread is not the scope owner

(Text extracted from the HTML; the JEP page has no version, read 2026-11-24.)

- **History.** JEP 453 made `fork` return a `Subtask`, not a `Future`; 505 replaced the constructors with `open` factories and added `Joiner`; 533 typed the exception `join()` throws.

**Costs and dissent**

"Alternatives", on why this is not a structured `ExecutorService`:

Source: https://openjdk.org/jeps/543
> However, we found it to be problematic because most uses of ExecutorService, and its parent interface Executor, in the JDK and in the ecosystem are not structured.

The API took two incubators and seven previews (JDK 19 to 27) before JEP 543.

**Unverified**

- The loom-dev feedback threads were not read. JDK 28 has not shipped as of 2026-11-24. The JDK 28 project page (no version; "Last update: 2026/11/24 15:17 UTC", read 2026-11-24) lists General Availability for 2027/03/09 and JEP 543 among "JEPs targeted to JDK 28, so far".

Source: https://openjdk.org/projects/jdk/28/
> The main line is
> open for bug fixes, small enhancements, and JEPs as proposed and
> tracked via the JEP Process.

### S5. Kotlin coroutines (kotlinx.coroutines `1.11.0`) and Roman Elizarov

The library made structured concurrency its default before 1.0. Read at tag `1.11.0` (released 2026-05-08); Medium returns 403, so Elizarov's posts are quoted from Wayback snapshots.

**What it does**

*Promise.* A parent waits for its children, and coroutines launch only in a `CoroutineScope`, which may be lexical (`coroutineScope { }`) or a value in a field, not necessarily a visible block.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/docs/topics/coroutines-basics.md
> To maintain structured concurrency, new coroutines can only be launched in a [`CoroutineScope`](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-scope/) that defines and manages their lifecycle.

*Way out for long-lived work.* First, a scope owned by an object, the key part being to cancel it at the end of the object's lifecycle. Second, `GlobalScope` behind an opt-in, `DelicateCoroutinesApi`, declared with `RequiresOptIn.Level.WARNING`; the KDoc's example is an application-long statistics logger. A coroutine can also leave the tree by naming another scope or passing another `Job`. **[ticket 13]**

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * When the lifecycle of the scope is not limited lexically
>  * (for example, when coroutines should outlive the function that creates them)
>  * but is tied to the lifecycle of some entity, the [CoroutineScope] constructor function can be used
>  * to define a personal scope for the entity. This scope should be stored as a field in the entity.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * There are limited circumstances under which `GlobalScope` can be legitimately and safely used,
>  * such as top-level background processes that must stay active for the whole duration of the application's lifetime.
>  * Because of that, any use of `GlobalScope` requires an explicit opt-in with `@OptIn(DelicateCoroutinesApi::class)`,

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/Annotations.kt
> @RequiresOptIn(
>     level = RequiresOptIn.Level.WARNING,
>     message = "This is a delicate API and its use requires care." +
>         " Make sure you fully read and understand documentation of the declaration that is marked as a delicate API."
> )
> public annotation class DelicateCoroutinesApi

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * The global scope is used to launch top-level coroutines whose lifecycles are not limited by structured concurrency.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/docs/topics/coroutine-context-and-dispatchers.md
> In both cases, the launched coroutine is not tied to the scope it was launched from and operates independently.

*When a child fails.* Under a regular `Job` a failing child cancels its parent and so its siblings, which cannot be overridden; supervisors cancel only downward; in `GlobalScope`, which installs no `CoroutineExceptionHandler`, a failure in a `launch` goes to the platform's last-resort propagation unless a handler is passed in `launch`'s arguments; a root `async` or `produce` leaves the exception to whoever awaits or receives the result. **[ticket 13]**

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/docs/topics/exception-handling.md
> If a coroutine encounters an exception other than `CancellationException`, it cancels its parent with that exception. 

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/Supervisor.kt
>  * A failure or cancellation of a child does not cause the supervisor job to fail and does not affect its other children,

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * This means that exceptions thrown in coroutines created using [launch] will lead to platform-specific
>  * last-resort error propagation behavior, such as crashing the application (on Android, Kotlin/Native, and JS)
>  * or populating the logs with potentially unnecessary information (on non-Android JVM).

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * One way to solve this would be to provide a [CoroutineExceptionHandler] in the [launch] arguments.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/docs/topics/exception-handling.md
> Coroutine builders come in two flavors: propagating exceptions automatically ([launch]) or
> exposing them to users ([async] and [produce]).
> When these builders are used to create a _root_ coroutine, that is not a _child_ of another coroutine,
> the former builders treat exceptions as **uncaught** exceptions, similar to Java's `Thread.uncaughtExceptionHandler`,
> while the latter are relying on the user to consume the final
> exception, for example via [await][Deferred.await] or [receive][ReceiveChannel.receive] 
> ([produce] and [receive][ReceiveChannel.receive] are covered in [Channels](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/channels.md) section).

*When a child will not finish.* `coroutineScope { }` waits. Cancellation is cooperative and does not finish the computation at once; timeouts come from `withTimeout` and `withTimeoutOrNull`; `scope.cancel()` is documented as shorthand for cancelling the scope's `Job`.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * [coroutineScope] and [supervisorScope] functions can be called in any `suspend` function to define a scope
>  * lexically, ensuring that all coroutines launched in this scope complete by the time the scope-limiting
>  * function exits.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * Since [GlobalScope] does not have a [Job], it is impossible to cancel all coroutines launched in it.
>  * Likewise, there is no way to wait for all coroutines launched in it to finish.

**The stated why**

Roman Elizarov, then Team Lead for Kotlin libraries at JetBrains (per the Medium byline), in "Structured concurrency" (Sep 12, 2018, snapshot of 2020-11-12), which keeps `GlobalScope` for the rare application-long coroutine ("The reason to avoid GlobalScope", Jan 27, 2019, snapshot of 2020-11-09, says the same); then commenting on Sústrik's 2018 update (21 Oct 2018):

Source: https://web.archive.org/web/20201112034122/https://medium.com/@elizarov/structured-concurrency-722d765aa952
> On a more philosophical level, you rarely launch coroutines “globally”, like you do with threads.

Source: https://web.archive.org/web/20181130014202/http://250bpm.com/blog:137
> We've used the term "structured concurrency" to label this syntactic change of default, even though nothing had really changed inside.

**Inferred**

- `CoroutineScope.cancel` is declared `public fun`, not `suspend fun`, and its KDoc mentions no waiting, so it does not wait for the children. The documentation does not say so directly. **[ticket 13]**

**No stated rationale found**

Not applicable.

**Constraints**

- **Deployment model.** Multiplatform (JVM, Android, JS, Native), dispatchers on thread pools.
- **History.** The default changed before 1.0 (September 2018). The KDoc says any `GlobalScope` use now needs an opt-in to `DelicateCoroutinesApi`.

**Costs and dissent**

The KDoc lists the pitfalls of unscoped coroutines (leaks, crashes) and warns against an ad-hoc `CoroutineScope()` in place of `GlobalScope`; the supervision documentation says two-way cancellation does not suit some cases.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/CoroutineScope.kt
>  * Do not replace `GlobalScope.launch { ... }` with a `CoroutineScope().launch { ... }` constructor function call.

**Unverified**

- The live Medium posts (403, 2026-11-24) could not be compared with the snapshots; the release that added the `@DelicateCoroutinesApi` opt-in was not identified.

### S6. Swift SE-0304 with SE-0381 (swift-evolution at `58a97fa`)

SE-0304 "Structured concurrency", by John McCall, Joe Groff, Doug Gregor and Konrad Malawski, "Implemented (Swift 5.5)"; SE-0381 (DiscardingTaskGroup, Swift 5.9, by Cory Benfield and Konrad Malawski) adds a group for servers. Read at commit `58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060`.

**What it does**

*Promise.* The scope is the closure passed to `withTaskGroup`; SE-0317 `async let` also creates child tasks.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> A *task group* defines a scope in which one can create new child tasks programmatically. As with all child tasks, the child tasks within the task group scope must complete when the scope exits, and will be implicitly cancelled first if the scope exits with a thrown error.

*Way out for long-lived work.* `Task { }` and `Task.detached { }`; SE-0381 for never-ending groups.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> Sometimes however, these rigid rules end up being too restrictive. We might need to create new tasks whose lifetime is not bound to the creating task, for example in order to fire-and-forget some operation or to initiate asynchronous work from synchronous code.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> Tasks run to completion even if there are no remaining uses of their task handle, so it is not necessary to retain the task handle or observe its value for the task to complete.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0381-task-group-discard-results.md
> It is specialized for potentially never-ending task groups, such as top-level loops of http or other kinds of rpc servers.

*When a child fails.* A child's error does not by itself cancel its siblings; cancellation follows only if the body throws, typically rethrowing an error read with `next()`. If the body returns normally, child errors are ignored: the accepted text promised otherwise, and the proposal was revised to match the implementation. SE-0381's discarding groups rethrow the first error and cancel. **[ticket 13]**

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> /// complete. The tasks are only cancelled if `cancelAll()` was invoked before
> /// returning, the groups' task was cancelled, or the group body has thrown.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> This behavior was never implemented; throws from tasks are ignored in this state.

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0381-task-group-discard-results.md
> the discarding task group types must handle this behavior implicitly by re-throwing the _first_ encountered error and cancelling the group.

*When a child will not finish.* The group waits; cancellation is cooperative. **[ticket 13]**

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> Because cancellation is cooperative, and because structured concurrency does not allow child tasks to outlast their parent context, control does not actually return until the onion-chopping task actually completes; any value it returns or throws will be discarded.

**The stated why**

The SE-0304 authors, who ask programmers to organise concurrency into tasks and child tasks:

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0304-structured-concurrency.md
> If child tasks did not have bounded duration and so could arbitrarily outlast their parents, the behavior of tasks under these features would not be easily comprehensible. 

**Inferred**

None.

**No stated rationale found**

- Why the originally accepted behaviour, cancelling a throwing group's remaining tasks when a task throws after the body returns normally, was never implemented: no design reason was found. The proposal history says only that the Language Steering Group required a new proposal to restore it. On PR #2537 (merged 2024-08-21), which removed the sentence, SE-0304 co-author Konrad Malawski (`ktoso`) wrote that "Seems some old wording stuck around in the proposal", and gave the reason discarding groups cancel on a throw. John McCall, an SE-0304 author, signing for the Language Steering Group in the post the proposal header links as "revision", gave the reason for revising the document rather than the implementation. Of the forum threads only that post was read.

Source: https://github.com/swiftlang/swift-evolution/pull/2537#issuecomment-2290094437
> That's right thanks for the fix. Seems some old wording stuck around in the proposal. This isn't what was fleshed out behavior wise and implemented.

Source: https://github.com/swiftlang/swift-evolution/pull/2537#issuecomment-2290094437
> That behavior is true of _discarding_ task groups however -- as they cannot observe the error via a `try await next()` call, it is a "all for one" strategy (if one dies/throws, all cancel) in discarding task groups, while it is a "one for all" (each throws/dies on its own). But that was a subsequent different proposal.

Source: https://forums.swift.org/raw/51850/9
> A member of the community recently [pointed this out](https://github.com/swiftlang/swift-evolution/pull/2537), and the Language Steering Group discussed it.  The LSG believes that the appropriate response for now is to bring the proposal document in line with the current implementation.  This is less a judgment about what the behavior *should* be and more a decision that too much time has passed to reasonably consider any change to be a mere bug fix.  Adopting the originally-proposed semantics would now need to be separately proposed and reviewed.  In the meantime, the proposal document should reflect reality.

(Post 9 of the acceptance thread, https://forums.swift.org/t/accepted-with-modifications-se-0304-structured-concurrency/51850/9, quoted from its raw Markdown; no version, read 2026-11-24.)

**Constraints**

- **Deployment model.** The Swift language and runtime.
- **What it guarantees.** Priority escalation, task-locals and cancellation flow down the task tree.
- **History.** Three pitches, four reviews and a revision after acceptance (per the header); SE-0381 followed for servers.

**Costs and dissent**

SE-0381 on `TaskGroup` and long-running servers (the child-error gap is under **What it does**):

Source: https://github.com/swiftlang/swift-evolution/blob/58a97fabc7233f58af6b8a1e8d3d5a25fb4f7060/proposals/0381-task-group-discard-results.md
> The result of this is that Task Groups are ill-suited to running for a potentially unbounded amount of time.

**Unverified**

- The Swift Forums pitch and review threads were not read; of the acceptance thread only post 9 (the revision, 2024-08-21) was read.

### S7. Rust `std::thread::scope` (`1.100.0`)

Scoped OS threads, here briefly; D1 and D2 cover their history. Read at `library/std/src/thread/scoped.rs`, tag `1.100.0` (released 2026-11-12).

**What it does**

*Promise.* The lexical closure is the scope. The promise is about the threads' main functions; their thread-local destructors may still be running when `scope` returns (as in D2):

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
> /// All threads spawned within the scope that haven't been manually joined
> /// will be automatically joined before this function returns.
> /// However, note that joining will only wait for the main function of these threads to finish; even
> /// when this function returns, destructors of thread-local variables in these threads might still
> /// be running.

*Way out for long-lived work.* `std::thread::spawn` remains.

*When a child fails.* If a thread joined automatically at the end of the scope panicked, `scope` panics with its own message, "a scoped thread panicked", not the child's payload; a panic in a thread joined by hand comes back as the `Err` of `join` and does not make `scope` panic. If the closure itself panicked, its panic is resumed instead. **[ticket 13]**

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
> /// If any of the automatically joined threads panicked, this function will panic.

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
>         Ok(_) if scope.data.a_thread_panicked.load(Ordering::Relaxed) => {
>             panic!("a scoped thread panicked")
>         }

*When a child will not finish.* `scope` waits for the main function of every thread; thread-local destructors in those threads may still be running when it returns. It has no timeout: `pub fn scope<'env, F, T>(f: F) -> T` takes only the closure, and `grep -c timeout` on the file returns 0. **[ticket 13]**

**The stated why**

The documentation, on borrowing:

Source: https://github.com/rust-lang/rust/blob/1.100.0/library/std/src/thread/scoped.rs
> /// as the scope guarantees all threads will be joined at the end of the scope.

**Inferred**

- The documentation describes no cancellation of sibling threads; only the `scope` documentation was read, not the whole `Scope` API. **[ticket 13]**

**No stated rationale found**

Not applicable: deliberately brief; D1 and D2 cover the history.

**Constraints**

- OS threads; the lexical closure is the scope.

**Costs and dissent**

The Rust async book (`840327a`, committed 2026-10-20), a Rust project document, not the originators' work:

Source: https://github.com/rust-lang/async-book/blob/840327a2e8ea30644b2a6c8940d467183a17c43d/src/part-reference/structured.md
> Generally these patterns are ones where not being tied to a specific task is a feature, e.g., worker pools or background threads. Even using these patterns, the tasks usually shouldn't outlive the whole program and so there is always one task which can be the parent.

**Unverified**

- The history is not covered here.

#### The claim, source by source

What each source says of the claim, without a verdict:

- **"Lives inside a scope".** Every source states that a child does not outlive its parent scope. Rust's `scope` qualifies this: it waits only for each thread's main function, and thread-local destructors may still be running when it returns (S7, D2).
- **"Every".** Each adopter keeps a way out for long-lived work: Sústrik's heap-allocated green thread, "managed manually by the owner(s)"; asyncio's `create_task` for "fire-and-forget" tasks; Java's non-goal of replacing `ExecutorService`; Kotlin's `GlobalScope`, "not limited by structured concurrency", behind an opt-in at warning level; Swift's `Task { }` and `Task.detached`; Rust's `thread::spawn`. Smith's essay says the full benefit needs the old primitives removed.
- **"Visibly".** Trio, asyncio, Java and Swift scopes are syntactic blocks (Java's is a try-with-resources block, closed "usually implicitly", S4; `close()` may also be called directly), and Java enforces structure at run time. Trio and the essay let a nursery be passed elsewhere, "explicitly" per the essay, so the call site shows it. Trio's system tasks go into an internal "system nursery" user code never opens. In libdill and Kotlin's `CoroutineScope()` entity pattern, the scope is a value in an object, ended by an explicit call, not a block: libdill's `hclose` cancels and waits, while Kotlin's `scope.cancel()` only starts cancellation, and a caller that needs the scope's work complete waits on the scope's `Job`, for example with `cancelAndJoin()`.
- **"Closes".** libdill's `hclose` cancels, then waits. Trio's nursery waits, cancelling when a child or the body raises or an enclosing cancel scope is cancelled. asyncio's `TaskGroup` waits, cancelling when a child or the body raises or on `cancel()`. Swift's group waits, cancelling on `cancelAll()`, cancellation of the group's task, or a throwing body. Java's `close()` cancels, then waits with no bound. Kotlin's `coroutineScope` waits; `scope.cancel()` cancels and, inferred from its non-suspending signature, does not wait.

Source: https://github.com/Kotlin/kotlinx.coroutines/blob/1.11.0/kotlinx-coroutines-core/common/src/Job.kt
>  * Cancels the job and suspends the invoking coroutine until the cancelled job is complete.

**[ticket 13]**

#### Leads that did not hold (structured concurrency)

- **"Java JEPs 428, 453, 462, 480, 499, 505".** All six exist, but the list omits 437 (JDK 20), 525 (26), 533 (27) and 543 (final, Integrated, 28). Evidence: the index `https://openjdk.org/jeps/0` (2026-11-24) and each page's status block.
- **"Martin Sústrik's posts" at 250bpm.com.** The live `blog:71`, `blog:124` and `blog:137` return 404, and the domain redirects to a Substack; Wayback snapshots 20190211184210, 20181205063621 and 20181130014202 were used.
- **libdill documentation at libdill.org.** `http://libdill.org/structured-concurrency.html` returns 403 to curl; `website/src/structured-concurrency.md` at tag `2.14` was used.
- **"Roman Elizarov's post" on Medium.** The live URLs return 403 to curl; snapshots 20201112034122 and 20201109065434 were used.

## T. Fakes for tests

What comparable libraries give a test to capture what was recorded.

All sources read 2026-11-24. Each fake answers: how a test installs it, what it records, whether its docs promise, deny or say nothing about the real backend's rules, whether it shows what was dropped, and its stated why and costs. Each "say nothing" verdict rests on a full read of the files named in the section, backed by a case-insensitive grep for `production|same (as|rules)|faithful|identical|real (backend|exporter)|drop` (hits naming only span drops, guard drops or eviction are not fidelity statements). The grep alone proves nothing: it gave 0 for structlog's testing docs, which denies fidelity in other words (T9).

### T1. metrics-util `DebuggingRecorder` and `Snapshotter` (metrics-util 0.20.4, metrics 0.24.6)

Rust in-memory metrics recorder for tests; `metrics-util` 0.20.4 is crates.io max stable. Read 2026-11-24: module and item docs of `debugging.rs` and `metrics/src/recorder/mod.rs`, both CHANGELOGs.

**What it does**

- **Install.** Global, a closure (`metrics::with_local_recorder`) or a guard (`metrics::set_default_local_recorder`); the latter two are thread-local, so parallel tests work only through them, and a metric looked up on another thread is not captured (the `counter!` family looks up the recorder on each call). A handle registered while capture is set is different: it is built on the recorder's own storage and is `Send + Sync`, so it keeps recording into the capture from any thread it is moved or cloned to (read from source, not run). The guard does not intercept handles registered earlier.

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/debugging.rs
>     /// Installs this recorder as the global recorder.

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// This only applies as long as the closure is running, and on the thread where `with_local_recorder` is called. This

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/recorder/mod.rs
> /// runtime. Any metrics registered prior to the returned guard will remain attached to the recorder that was present at

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/macros.rs
>         $crate::with_recorder(|recorder| recorder.$register(&metric_key, metadata))

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/debugging.rs
>         self.inner.registry.get_or_create_counter(&key, |c| Counter::from_arc(c.clone()))

Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/handles.rs
>     inner: Option<Arc<dyn CounterFn + Send + Sync>>,

- **Records** the raw values passed to the `Recorder` trait; no exporter processing (rendering, bucketing, naming rules, limits). A snapshot drains: counters and gauges swap to zero, histograms clear.

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/debugging.rs
> /// A simplistic recorder that can be installed and used for debugging or testing.

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/debugging.rs
>                     counters.get(ck.key()).map(|c| DebugValue::Counter(c.swap(0, Ordering::SeqCst)))

- **Real backend's rules?** Docs say nothing; no sentence in `debugging.rs` compares it with any exporter. The module doc frames it as an aid for testing exporters:

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/src/debugging.rs
> //! While these utilities are primarily designed to help aid with testing and debugging of exporters

- **Shows drops?** No. The trait has no notion of refusal; the snapshot holds only `(CompositeKey, Option<Unit>, Option<SharedString>, DebugValue)` and skips a key described but never registered.

**The stated why**

Thread-local recorders: tobz, metrics-rs member (`MEMBER`), author of PR 414:

Source: https://github.com/metrics-rs/metrics/pull/414
> - it's subject to race conditions since the default Cargo test runner will run unit tests in parallel

Source: https://github.com/metrics-rs/metrics/pull/414
> It works on a thread-local basis so one instance of using a local recorder never conflicts with another.

Source: https://github.com/metrics-rs/metrics/pull/414
> This is modeled after `tracing`, where a free function takes a reference to the dispatcher to temporarily set as the default

Maintainers' changelog: the per-thread mode inside `DebuggingRecorder`, removed in 0.16.0, and why it existed in 0.12.1:

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/CHANGELOG.md
> - Support for per-thread mode in `DebuggingRecorder`. Users should now use

Source: https://github.com/metrics-rs/metrics/blob/metrics-util-v0.20.4/metrics-util/CHANGELOG.md
> - A new per-thread mode for `DebuggingRecorder` that allows recording metrics on a per-thread basis to better supporting

Why a snapshot consumes: villainb-dg, contributor (`CONTRIBUTOR`), PR 588, merged and released by the maintainer:

Source: https://github.com/metrics-rs/metrics/pull/588
> The motivation is to make them behave in a similar way to histograms whose values are cleared from the backing storage during snapshot.

**Inferred**

None.

**No stated rationale found**

Why it applies none of an exporter's rules: no author says, beyond "simplistic" (above).

**Constraints**

One process-global recorder, set once, optional per-thread override. A snapshot reports what the facade passed in since the last one. No failure model: every call is recorded. Per-thread mode added 0.12.1, removed 0.16.0 for `with_local_recorder`; consume semantics arrived in 0.19.2, yanked and re-released as 0.20.0.

**Costs and dissent**

- A user (`NONE`), issue 697, still open. The reporter says counters are not reset "in a similar way", but the 0.20.4 source swaps them to zero (above); the user's observation was not checked.

Source: https://github.com/metrics-rs/metrics/issues/697
> This behavior is undocumented, and definitely surprising.

- A user (`NONE`) on PR 588:

Source: https://github.com/metrics-rs/metrics/pull/588#issuecomment-2985569837
> This is quite the breaking change for a point release...

- A user (`NONE`) on the closure form for async tests, and the maintainer agreeing:

Source: https://github.com/metrics-rs/metrics/issues/502
> It isn't possible to use a closure unless you combine all your tests into a single one.

Source: https://github.com/metrics-rs/metrics/issues/502#issuecomment-2271669326
> Yeah, using the local recorder with async code is indeed painful.

- Chose otherwise: tracing-test (T3) installs one global capture to see other threads.

**Unverified**

None. The guard's motive is settled: PR #523, which added it, closes #502 and cites it as the motivation (A3).

### T2. tracing-mock (tracing-mock 0.1.0-beta.3, tracing-core 0.1.36)

The tracing project's mock subscriber; crates.io has only betas, no `max_stable_version`. Read 2026-11-24: README, `subscriber.rs` and `layer.rs` module docs and CHANGELOG at the tag; `tracing-core` dispatcher docs.

**What it does**

- **Install.** Through `tracing` dispatch: closure (`with_default`), guard (`set_default`) or global; the docs use the closure. Scoped forms are thread-local and miss spawned threads.

Source: https://github.com/tokio-rs/tracing/blob/tracing-mock-0.1.0-beta.3/tracing-mock/src/subscriber.rs
> //! // Use `with_default` to apply the `MockSubscriber` for the duration

Source: https://github.com/tokio-rs/tracing/blob/tracing-core-0.1.36/tracing-core/src/dispatcher.rs
> //! It's important to note that `with_default` will not propagate the current

- **Records** nothing to read back: it asserts an ordered list of expectations against the raw `Subscriber` callbacks (`new_span`, `enter`, `event`, `record`, `exit`, `drop_span`) as they happen. Its only filter is the test's own, run before validation. `MockLayer` can sit in a real `tracing_subscriber::registry()` beside real per-layer filters and sees what they pass (`layer.rs` example).

Source: https://github.com/tokio-rs/tracing/blob/tracing-mock-0.1.0-beta.3/tracing-mock/src/subscriber.rs
> //! `MockSubscriber` has expectations set on it which are later

Source: https://github.com/tokio-rs/tracing/blob/tracing-mock-0.1.0-beta.3/tracing-mock/src/subscriber.rs
>     /// is not important. The filter does not perform any validation

- **Real backend's rules?** Docs say nothing; there is no backend to match, and only the test decides what is enabled.
- **Shows drops?** Not as data. `.only()` fails on any unexpected callback and a test can expect `drop_span`; a callsite the dispatcher never delivers is invisible.

**The stated why**

Published because third parties kept reproducing the internal test support. yaahc, collaborator (`COLLABORATOR`), filed the request; hawkw, maintainer (`MEMBER`), replied:

Source: https://github.com/tokio-rs/tracing/issues/539
> Publish the contents of `tracing/tracing/tests/support` and any other necessary machinery so that they can be added as a dev dependency to `spandoc` and tests can be created that verify span entry and exit ordering.

Source: https://github.com/tokio-rs/tracing/issues/539#issuecomment-574893933
> so, perhaps that's more evidence in support of making it publicly available...

Source: https://github.com/tokio-rs/tracing/issues/539#issuecomment-574411576
> Hmm, if we're going to do this, I think the test framework needs a lot of cleanup.

hds (`CONTRIBUTOR`) announced the crates.io beta in the same issue (comment 2508209025).

**Inferred**

None.

**No stated rationale found**

Why it validates expectations rather than returning captured data: not found in issue 539, the README, the module docs or the CHANGELOG.

**Constraints**

A dev-dependency in beta; the README asks for an exact pin. Ordered expectation checking: panics on mismatch, `assert_finished` checks all were met. Issue 539 opened 2020-01-14; first beta on crates.io November 2024 (0.1.0-beta.1 entry dated November 29, 2024).

Source: https://github.com/tokio-rs/tracing/blob/tracing-mock-0.1.0-beta.3/tracing-mock/README.md
> While `tracing-mock` is in beta, it is recommended that an exact version is

**Costs and dissent**

Thread-scoped capture in `tracing-core` 0.1.x can silently miss events under parallel tests, for every `with_default` fake. Two users (`NONE`) in issue 3611; a third (`NONE`) in issue 2874 believes it makes their tests flaky. Both issues open.

Source: https://github.com/tokio-rs/tracing/issues/3611
> A later event emitted **on the capture thread** is then discarded *before* reaching the subscriber; the instance-local capture buffer stays empty even though the event macro executed under the scoped default.

Source: https://github.com/tokio-rs/tracing/issues/3611#issuecomment-6299997622
> We encountered empty thread-local log captures under parallel `cargo test`, while nextest’s process-per-test execution passes.

**Unverified**

Whether tracing-mock itself has been reported as hit by issue 3611; not searched.

### T3. tracing-test (tracing-test 0.2.6)

Rust attribute macro capturing `tracing` output. Read 2026-11-24 at `v0.2.6`: `lib.rs`, `internal.rs`, `subscriber.rs`, the macro's `lib.rs`, CHANGELOG, issue list.

**What it does**

- **Install.** `#[traced_test]` installs a process-global subscriber once (`set_global_default`). Each test enters a span named after its function, and assertions keep only buffer lines whose text contains a space, that name and a colon: that is how parallel tests stay apart. The test is on the text of the formatted line alone, not on span membership, so a line that contains that text anywhere passes (read from source, not run).

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! The macro provided in this crate registers a global default subscriber instead.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test-macro/src/lib.rs
>             let span = tracing::info_span!(#scope);

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/internal.rs
>         .filter(|line| line.contains(&format!(" {}:", scope)))

- **Records** formatted text after a real `tracing_subscriber::fmt` and an env filter, the crate's own, which by default keeps only the test crate's logs.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! This subscriber contains a writer which logs into a global static in-memory buffer.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! By default, `tracing-test` sets an env filter that filters out all logs

- **Real backend's rules?** Explicitly denied on one point (the application's runtime filter config is ignored); the writer also notes it differs from production.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! library ensures that the logs do not depend on external state. For example, the

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/subscriber.rs
>         // Note: The `lock` will block. This would be a problem in production code,

- **Shows drops?** No. Only formatted lines reach the buffer; a failed write becomes an `io::Error` the fmt layer does not report.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/subscriber.rs
>             .map_err(|_| io::Error::from(io::ErrorKind::Other))

**The stated why**

dbrgn, owner (`OWNER`), crate docs and PR 12:

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! This works fine, as long as no threads are involved. As soon as you use a

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! The focus is on testing the logging, not on debugging the tests. That's why the

Source: https://github.com/dbrgn/tracing-test/pull/12#issuecomment-978499211
> To avoid this, and to capture logs in all threads, I register a global subscriber.

Source: https://github.com/dbrgn/tracing-test/pull/12#issuecomment-978499211
> This way the logs are all captured, but the filters cannot be changed per-test, unless we add a requirement that tests may not run in parallel.

Source: https://github.com/dbrgn/tracing-test/pull/12#issuecomment-977197646
> I don't think that `RUST_LOG` should have an effect on test outcome.

**Inferred**

None.

**No stated rationale found**

Not applicable: the owner states the why.

**Constraints**

A dev-dependency proc macro; one global subscriber and buffer per test binary. Substring and closure assertions over lines whose text contains the test's span name followed by a colon. Lock poisoning or a write error drops lines silently (PR 61, below). 0.2.3 added `no-env-filter`, which integration tests need; 0.2.4 fixed `logs_assert` reading other tests' logs.

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/CHANGELOG.md
> - [bug] `logs_assert` should not get logs from other tests (#19)

Source: https://github.com/dbrgn/tracing-test/blob/v0.2.6/tracing-test/src/lib.rs
> //! integration tests must use `no-env-filter` to capture and observe logs.

**Costs and dissent**

- Logs from `std::thread::spawn` and `spawn_blocking` lack the test's span and are dropped by the scoping. A user (`NONE`), issue 23, open; another user (`NONE`) there adds there is no good way to associate events across threads or tasks.

Source: https://github.com/dbrgn/tracing-test/issues/23
> I'm having difficulties asserting traces from inside an std thread.

- Missing logs under parallel tests (the `tracing-core` interest race, T2). PR 61, from a user (`NONE`), closed unmerged; its measurements are that author's claim.

Source: https://github.com/dbrgn/tracing-test/pull/61
> A callsite that another test thread reaches for the first time in that window sees no global subscriber yet, caches `Interest::never`, and drops its events for the rest of the run, so `logs_assert`/`logs_contain` see only part of the logs.

Source: https://github.com/dbrgn/tracing-test/pull/61
> `MockWriter` turns the poison into an `io::Error`, so every later log line is silently dropped.

- A user (`NONE`), issue 59, open:

Source: https://github.com/dbrgn/tracing-test/issues/59
> That buffer is **never cleared** for the lifetime of the test binary, so it accumulates the log output of every traced test in the process.

- Chose otherwise: tracing-mock (T2) and `metrics` (T1) scope capture to a thread.

**Unverified**

None.

### T4. Python `unittest`: `assertLogs` and `assertNoLogs` (CPython v3.14.10)

Standard-library log assertions. Read 2026-11-24 at `v3.14.10`: `Doc/library/unittest.rst` lines 1134–1193 and `Lib/unittest/_log.py`.

**What it does**

- **Install.** A `TestCase` context manager: on entry it replaces the target logger's handlers with one capturing handler, turns propagation off and sets the level; on exit it restores all three. Loggers are process-global, so every thread sees the change; `_log.py` has no thread handling (grep for `thread`: nothing).

Source: https://github.com/python/cpython/blob/v3.14.10/Lib/unittest/_log.py
>         logger.handlers = [handler]

Source: https://github.com/python/cpython/blob/v3.14.10/Lib/unittest/_log.py
>         logger.propagate = False

- **Records** `LogRecord`s passing the logger's level and filters and the handler's level, with text in a fixed format; production handlers' filters and formatters never run.

Source: https://github.com/python/cpython/blob/v3.14.10/Lib/unittest/_log.py
>     A logging handler capturing all (raw and formatted) logging output.

- **Real backend's rules?** Docs say nothing, and never mention the handler swap or propagation (grep of rst lines 1120–1200 for `handler|propagat` matches only "non-propagating descendent logger"). The source removes the production handlers.
- **Shows drops?** No; `assertNoLogs` fails if anything at or above the level was logged, showing only what got through.

**The stated why**

Antoine Pitrou, who proposed and committed it (per the bpo-18937 changeset), then replying to a suggestion to mock the logger; bitdancer, a participant, agreeing:

Source: https://github.com/python/cpython/issues/63137#issuecomment-1093626912
> It is sometimes useful to check for the log messages emitted by some piece of code (especially a library).

Source: https://github.com/python/cpython/issues/63137#issuecomment-1093626918
> Only works if you test the exact logger that will be triggered, rather

Source: https://github.com/python/cpython/issues/63137#issuecomment-1093626922
> It is the difference between black box testing and white box testing.

`assertNoLogs`: its requester, Kit Yan Choi, a user:

Source: https://github.com/python/cpython/issues/83566#issuecomment-1093851989
> assertLogs is really useful (bpo-18937). Unfortunately it does not cover the use cases where one wants to ensure no logs are emitted.

**Inferred**

None.

**No stated rationale found**

Why production handlers are replaced rather than kept: not in the 15 messages of bpo-18937 (cpython issue 63137) or the doc entry.

**Constraints**

Standard library, one in-process logging tree; pass or fail on whether a matching record was seen in the `with` block. `assertLogs` 3.4, `assertNoLogs` 3.10 (`versionadded`). The bpo-41943 fix (commit `6fdfcec`, `master`, 2020-11-02) addressed `assertLogs` passing unexpectedly; at `v3.14.10` the handler sets its own level (`handler.setLevel(self.level)`). First release carrying it not checked.

**Costs and dissent**

- A user (`MANNEQUIN`, migrated bpo account), issue 89900, open:

Source: https://github.com/python/cpython/issues/89900#issuecomment-1093936765
> However, if the code being tested is relying on a handler to do something, then the test fails because the handler is being removed.

- A user, on the bug bpo-41943 fixed:

Source: https://github.com/python/cpython/issues/86109#issuecomment-1093885890
> This means that this test should fail (nothing has been logged at warning level or above), but it passes.

- voidspace, a participant, preferring mocks:

Source: https://github.com/python/cpython/issues/63137#issuecomment-1093626920
> Do you have a lot of circumstances where you want to test logging but you don't know the specific logger and method called? That's not a situation I've been in.

- Chose otherwise: pytest `caplog` (T5) adds a handler and keeps the existing ones.

**Unverified**

Core-developer status of bitdancer and voidspace; migrated bpo comments carry no author association.

### T5. pytest `caplog` (pytest 9.2.0)

pytest's log-capture fixture. Read 2026-11-24 at `9.2.0`: `how-to/logging.rst`; `catching_logs`, `LogCaptureHandler`, `LogCaptureFixture` in `_pytest/logging.py`; entries in `changelog.rst`.

**What it does**

- **Install.** Function-scoped fixture; its handler goes on the root logger and, since 9.1.0 (changelog, issue 3697), on every logger that is non-propagating when capture starts; a logger that becomes non-propagating afterwards is missed. The other way round, a logger that is non-propagating when capture starts and propagates afterwards has the handler on itself and on the root, so each of its records is captured twice (read from source at `9.2.0`, not run; issue 15064's reporter, a user (`NONE`), reproduced it on `main` at `9.2.0.dev0`, in the report sections too). Existing handlers stay.

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>         # Attach to all non-propagating loggers (won't reach root).

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>         # Note that will miss loggers that *become* non-propagating
>         # after the `__enter__`. Not worth the trouble for now.

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>         root_logger.addHandler(self.handler)

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>                 logger.addHandler(self.handler)

Source: https://github.com/pytest-dev/pytest/issues/15064
> I ran into a case where one logging call is captured twice if a logger is non-propagating when pytest starts capture and
> enables propagation during the test.

Source: https://github.com/pytest-dev/pytest/issues/15064
> I can also reproduce the duplicate in captured failure-report sections, `--log-cli-level` output, and `--log-file`

- **Records** `LogRecord`s reaching its handler after real logger levels, logger filters and propagation, plus formatted text; production handlers' filters do not gate it.
- **Real backend's rules?** Denied on purpose in one respect: a record that fails to format raises in the test while `logging.raiseExceptions` is true (its default), where production prints to stderr and carries on (the next comment says pytest wants such mistakes visible). The docs warn capture depends on the root logger's config.

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>             # Fail the test if the log message is bad (emit failed).

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/src/_pytest/logging.py
>     def handleError(self, record: logging.LogRecord) -> None:
>         if logging.raiseExceptions:

Source: https://github.com/pytest-dev/pytest/blob/9.2.0/doc/en/how-to/logging.rst
>     The ``caplog`` fixture adds a handler to the root logger to capture logs. If the root logger is

- **Shows drops?** Not as data; only one refusal is surfaced, a format failure turned into a test failure while `logging.raiseExceptions` is true.

**The stated why**

bluetech, maintainer (`MEMBER`), PR 7231 on raising for bad records (Line breaks collapsed: the source uses CRLF.), then PR 14375 on non-propagating loggers:

Source: https://github.com/pytest-dev/pytest/pull/7231
> For regular programs this behavior makes sense, a bad log message
> shouldn't take down the program. But during tests, it is better not to
> skip over such mistakes, but propagate them to the user.

Source: https://github.com/pytest-dev/pytest/pull/14375
> As far as I can see, for the pytest use case, we do always want to capture these logs, for both test reporting (i.e. the "Captured log calls" section) and `caplog` testing.

**Inferred**

Inferred, not read in any pytest source: the logging tree is process-global, so tests run in parallel only in separate processes (as pytest-xdist does).

**No stated rationale found**

Why the handler goes on the root rather than the logger under test: not in PR 7231, PR 14375 or issue 3697 (all in full), or the how-to's 3.4 section, which points to issue 3013 (not read).

**Constraints**

Test-runner plugin, one process per worker. Records per phase (`setup`, `call`, `teardown`); levels restored after each test. A format failure fails the test while `logging.raiseExceptions` is true (its default). From `pytest-catchlog` in 3.3, changed in 3.4; format errors fail tests since 6.0.0rc1 (issue 6433); non-propagating loggers captured since 9.1.0.

**Costs and dissent**

- The 9.1.0 change broke a user's (`vallsv`, `NONE`, the reporter) test of a handler's resilience to bad records. The reporter's own explanation:

Source: https://github.com/pytest-dev/pytest/issues/14603#issuecomment-4707909507
> But it was done in purpose to check incorrect calls. To make sure that a custom handler is resilient to any problems.

Maintainers (`RonnyPfannschmidt` and `bluetech`, `MEMBER`) replied:

Source: https://github.com/pytest-dev/pytest/issues/14603#issuecomment-4707726446
> so pytest just uncovered a bug in your code - because those logger calls are absolutely incorrect - seems like lack of handler and propagation just hid the fact that there is a bug

Source: https://github.com/pytest-dev/pytest/issues/14603#issuecomment-4718245861
> This is not a regression but an intentional change, see #3697 (was one of the most highly voted issues in pytest).

- Before 9.1.0, turning propagation on as a workaround changed behaviour under test. A user (`NONE`):

Source: https://github.com/pytest-dev/pytest/issues/3697#issuecomment-2718915873
> And enabling propagation can further complicate the testing. Your filters will be rendered useless on your loggers.

- bluetech's cost, PR 14375:

Source: https://github.com/pytest-dev/pytest/pull/14375
> A downside is that the (somewhat performance-sensitive) per-test logging setup becomes a bit slower (depending on the logging setup).

- bluetech, maintainer (`MEMBER`), on PR 15138, which would stop the double capture (open and unmerged as of 2026-11-24):

Source: https://github.com/pytest-dev/pytest/pull/15138#issuecomment-6400114300
> I agree with this, the solution seems too much for this problem. If it cannot be done in a simpler manner I'd be tempted to treat it as a WONTFIX.

- Chose otherwise: `unittest.assertLogs` (T4) replaces the handlers.

**Unverified**

Issue 3013 (the 3.4 discussion) not read. Issue 15064 and PR 15138 (duplicate capture when propagation changes mid-test) were read in full on 2026-11-24 (above). As of that date, the issue is open, PR 15138 (RonnyPfannschmidt, `MEMBER`) is open and unmerged, and PR 15075, from a user (`NONE`), was closed unmerged; neither PR was read beyond its body and comments.

### T6. OpenTelemetry Python: `InMemorySpanExporter` and `InMemoryMetricReader` (opentelemetry-sdk 1.45.2, spec v1.63.0)

The Python SDK's in-memory exporter and reader. Read 2026-11-24: `in_memory_span_exporter.py`, the `InMemoryMetricReader` class (its docstring: useful for unit tests), `SimpleSpanProcessor.on_end`, `ReadableSpan`'s `dropped_*` properties, the spec's in-memory metrics exporter page.

**What it does**

- **Install.** Into an SDK provider the test builds (span exporter behind a processor, or a metric reader). No global switch needed; a per-test provider lets tests run in parallel.
- **Records** SDK output after the real pipeline: sampling, span limits and the chosen processor; views, aggregation, temporality and cardinality limits. `SimpleSpanProcessor` exports only sampled spans. The store can be bounded (commit `08322fd`, 2026-07-10, PR 5296; at `v1.45.2`, first release not checked).

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/export/in_memory_span_exporter.py
>     This class can be used for testing purposes. It stores the exported spans

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/export/__init__.py
>         if not (span.context and span.context.trace_flags.sampled):

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/export/in_memory_span_exporter.py
>             is reached, the oldest spans are dropped automatically. If ``None``

- **Real backend's rules?** Docs say nothing. The nearest rule, the spec's in-memory exporter page, fixes the fake's own defaults (cumulative, default aggregation) rather than another exporter's. SDK rules apply because it sits behind the SDK; nothing says exporter behaviour (OTLP encoding, payload limits, retry, network failure) is reproduced: it returns `SUCCESS` until shut down.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk_exporters/in-memory.md
> temporality to Cumulative for all instrument kinds by default.

- **Shows drops?** Partly. Span-limit drops are counts on each span (`dropped_attributes`, `dropped_events`, `dropped_links`), as the spec requires; cardinality overflow appears as an overflow series. Unsampled spans never reach the exporter under either processor (`BatchSpanProcessor.on_end` checks the same sampled flag at v1.45.2); a full queue drops the oldest span with a warning and a count (G6).

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
>   Counts for attributes, events and links dropped due to collection limits MUST be

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md
> `otel.metric.overflow` having (boolean) value `true`, which is used to report a

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/trace/sdk.md
> * `maxQueueSize` - the maximum queue size. After the size is reached, spans are

**The stated why**

The spec calls the in-memory metrics exporter a test aid:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk_exporters/in-memory.md
> local memory and allows to inspect it (useful for e.g. unit tests).

The span exporter's docstring (above) was worded by Oberon00, member (`MEMBER`), in PR 119 review (`discussion_r319952840`). On pairing with the simple processor, carlosalberto, contributor (`CONTRIBUTOR`):

Source: https://github.com/open-telemetry/opentelemetry-python/pull/119#discussion_r320243178
> That's correct, `SimpleExportSpanProcessor` is offered as a very simple option for testing and similar scenarios.

**Inferred**

Inferred: a fake at the exporter seam means a test exercises the real SDK's sampling, limits and aggregation. No author states this.

**No stated rationale found**

Why the exporter seam rather than replacing the SDK: not in PR 119 (all comments, reviews, review comments) or PR 5296. PR 119's "testing and demo purposes" reply (`discussion_r320010733`) is anchored to the `SimpleSpanProcessor` hunk, so it is not cited as the exporter's why.

**Constraints**

In-process SDK, pipeline built by the test. Holds what was exported, in order, when unbounded (the default); with `max_spans` set, the oldest spans are evicted silently, with no count. `export` fails only after `shutdown`.

Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-sdk/src/opentelemetry/sdk/trace/export/in_memory_span_exporter.py
>         max_spans: Maximum number of spans to store in memory. When the limit
>             is reached, the oldest spans are dropped automatically. If ``None``
>             (default), there is no limit.

**Costs and dissent**

- The bound was added because the unbounded list could exhaust memory. PR 5296, a contributor (`CONTRIBUTOR`):

Source: https://github.com/open-telemetry/opentelemetry-python/pull/5296
> `InMemorySpanExporter` currently stores all spans in an unbounded list,

- What it sees depends on the processor chosen (T7: simple and batch disagreed).
- Chose otherwise: structlog `capture_logs` (T9) disables the pipeline instead of sitting after it; `unittest.assertLogs` (T4) replaces production handlers.

**Unverified**

None. Sampling is settled: `BatchSpanProcessor.on_end` returns early for an unsampled span, as `SimpleSpanProcessor` does (`opentelemetry-sdk/src/opentelemetry/sdk/trace/export/__init__.py` at `v1.45.2`).

### T7. OpenTelemetry Rust: `InMemorySpanExporter` and `InMemoryMetricExporter` (opentelemetry_sdk 0.33.1)

The Rust SDK's in-memory exporters. Read 2026-11-24 at `opentelemetry_sdk-0.33.1`: `trace/in_memory_exporter.rs`, `metrics/in_memory_exporter.rs` docs, `testing/mod.rs`, the `testing` feature, `SpanData` in `trace/export.rs`, both `on_end` in `trace/span_processor.rs`.

**What it does**

- **Install.** As in Python, a test-built provider. Compiled only with the `testing` feature or in the SDK's tests. The doc example also sets the global provider (optional). The `testing` module also holds `TestMetricReader` (`collect` returns `Ok(())` and fills nothing, so it captures nothing), `TestSpanExporter` and `NoopSpanExporter`, read only that far.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/mod.rs
> #[cfg(any(feature = "testing", test))]

- **Records** `SpanData` after the real SDK; by default shutdown clears it.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/in_memory_exporter.rs
> /// This exporter is useful for testing and debugging purposes. It stores

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/in_memory_exporter.rs
>             reset_on_shutdown: true,

- **Real backend's rules?** Docs say nothing.
- **Shows drops?** Partly. Attribute drops are counted on `SpanData`. Spans dropped from a full batch queue never reach the exporter; the SDK reports them in its internal log and a counter, `processed_queue_full`, compiled only with `experimental_metrics_bound_instruments` (saved file line 503).

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/export.rs
>     /// The number of attributes that were above the configured limit, and thus

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>                         message = "BatchSpanProcessor dropped a Span due to queue full. No further log will be emitted for further drops until Shutdown. During Shutdown time, a log will be emitted with exact count of total spans dropped.");

**The stated why**

cijothomas, member (`MEMBER`), tracking issue:

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/1195
> Opening an issue to track adding InMemory SpanExporter, similar to whats done for

**Inferred**

Inferred: as in Python, the exporter seam means the real SDK rules run first.

**No stated rationale found**

Nothing beyond parity with metrics, in issue 1195 and PR 1216 with comments.

**Constraints**

In-process SDK; guarantees what was exported. A poisoned lock becomes `OTelSdkError::InternalFailure`; the metrics exporter may panic (its docs).

**Costs and dissent**

At this version the simple and batch processors disagree on unsampled spans, so a `SimpleSpanProcessor` test does not show what `BatchSpanProcessor` exports. A contributor (`CONTRIBUTOR`) reported it; at the tag the simple processor checks the flag and the batch `on_end` (saved file line 812) enqueues without it; a maintainer (`MEMBER`) accepted the bug. The fix (PR 3858) merged 2026-11-09, after the 0.33.1 tagged commit of 2026-10-08 (published 2026-10-09).

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3812
> `BatchSpanProcessor` sends spans with `IsRecording` = `true` and `Sampled` = `false` to the exporter. `SimpleSpanProcessor` drops these spans.

Source: https://github.com/open-telemetry/opentelemetry-rust/blob/opentelemetry_sdk-0.33.1/opentelemetry-sdk/src/trace/span_processor.rs
>         if !span.span_context.is_sampled() {

Source: https://github.com/open-telemetry/opentelemetry-rust/issues/3812#issuecomment-6408050127
> This is actionable as-is, so I’m marking it as an accepted trace SDK bug.

Chose otherwise: structlog `capture_logs` (T9) disables the pipeline; `unittest.assertLogs` (T4) replaces production handlers.

**Unverified**

None.

### T8. OpenTelemetry Java: `InMemorySpanExporter`, `InMemoryMetricReader` and `OpenTelemetryExtension` (opentelemetry-java v1.68.0)

The Java SDK's `sdk/testing` module. Read 2026-11-24: `InMemorySpanExporter.java`, `InMemoryMetricReader.java` class docs, `junit5/OpenTelemetryExtension.java`; for loss, `SpanData.java`, `LogRecordData.java`, and `SimpleSpanProcessor.java` and `BatchSpanProcessor.java` with their builders.

**What it does**

- **Install.** A test-built provider, or the JUnit 5 extension, which installs one SDK as the global for the test class and clears captures before each test.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/testing/src/main/java/io/opentelemetry/sdk/testing/junit5/OpenTelemetryExtension.java
>     GlobalOpenTelemetry.set(openTelemetry);

- **Records** exported `SpanData`, `MetricData` and `LogRecordData` after the real SDK; the extension wires a simple processor, not a batch one.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/testing/src/main/java/io/opentelemetry/sdk/testing/junit5/OpenTelemetryExtension.java
>             .addSpanProcessor(SimpleSpanProcessor.create(spanExporter))

- **Real backend's rules?** Docs say nothing; each class is described only as a test aid (`InMemoryMetricReader` in the same words).

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/testing/src/main/java/io/opentelemetry/sdk/testing/exporter/InMemorySpanExporter.java
>  * A {@link SpanExporter} implementation that can be used to test OpenTelemetry integration.

- **Shows drops?** Within a captured span or log record only: `SpanData` gives total counts of recorded events, links and attributes, which exceed the attached ones when a span limit dropped some, and `LogRecordData`, which the extension also returns, gives the same total for a log record's attributes. No count of whole spans that never reached the exporter. Among those are unsampled spans: the simple processor the extension wires, like the batch processor, passes on only sampled spans unless `setExportUnsampledSpans(true)` is set (read from source, not run).

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/data/SpanData.java
>    * The total number of {@link EventData} events that were recorded on this span. This number may
>    * be larger than the number of events that are attached to this span, if the total number
>    * recorded was greater than the configured maximum value. See: {@link

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/testing/src/main/java/io/opentelemetry/sdk/testing/junit5/OpenTelemetryExtension.java
>   public List<LogRecordData> getLogRecords() {

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/logs/src/main/java/io/opentelemetry/sdk/logs/data/LogRecordData.java
>    * <p>This number may be larger than the number of attributes that are attached to this log, if
>    * the total number recorded was greater than the configured maximum value. See {@link

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/SimpleSpanProcessor.java
>     if (span != null && (exportUnsampledSpans || span.getSpanContext().isSampled())) {

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/SimpleSpanProcessorBuilder.java
>    * Sets whether unsampled spans should be exported. If unset, defaults to exporting only sampled
>    * spans.

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessor.java
>     if (span != null && (exportUnsampledSpans || span.getSpanContext().isSampled())) {

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/trace/src/main/java/io/opentelemetry/sdk/trace/export/BatchSpanProcessorBuilder.java
>   private boolean exportUnsampledSpans = false;

**The stated why**

anuraaga, contributor (`CONTRIBUTOR`), author of PR 1880; jkwatson, contributor (`CONTRIBUTOR`), in review:

Source: https://github.com/open-telemetry/opentelemetry-java/pull/1880
> It's good if we can provide some test helpers for OpenTelemetry adopters.

Source: https://github.com/open-telemetry/opentelemetry-java/pull/1880#discussion_r512187538
> We've had enough people try to use the SDK for writing instrumentation that anything we can do to get them to not do that would be good.

**Inferred**

Inferred from source, not documented: the extension sets a process global and resets it in `beforeAll`/`afterAll`, so test classes running concurrently in one JVM would share or clobber it. Nothing in the file addresses this.

**No stated rationale found**

Why a simple processor and a global install: not in PR 1880 (all comments) or PR 1991 (body: "Depends on" another PR).

**Constraints**

The JVM, one `GlobalOpenTelemetry`; captures cleared before each test. Extension added October 2020; exporter artifact folded into `sdk-testing` November 2020; metric reader moved there May 2022.

**Costs and dissent**

The extension itself steers users away from leaning on it:

Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/testing/src/main/java/io/opentelemetry/sdk/testing/junit5/OpenTelemetryExtension.java
>    * Clears the collected exported {@link SpanData}. Consider making your test smaller instead of

No issue found where a Java fake passed and production differed; one search (`repo:open-telemetry/opentelemetry-java OpenTelemetryExtension parallel`) returned only issue 7999, on nested-class cleanup, not read. Chose otherwise: structlog `capture_logs` (T9) disables the pipeline; `unittest.assertLogs` (T4) replaces production handlers.

**Unverified**

None. The batch processor's sampling filter, and the simple processor's, are under **Shows drops?** (read from source).

### T9. structlog: `capture_logs`, `LogCapture`, `CapturingLogger` and `ReturnLogger` (structlog 26.1.0)

structlog's Python testing helpers. Read 2026-11-24 at `26.1.0`: `docs/testing.md`, `src/structlog/testing.py`.

**What it does**

- **Install.** `capture_logs()`, a context manager, rewrites the process-global configuration and is not thread-safe; `LogCapture` can be configured as a pytest fixture instead.

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/testing.py
>     Attention: this is **not** thread-safe!

- **Records** the event dict without the configured processors (no renderer, timestamper or context merge); a test can opt chosen processors back in. `LogCapture` then raises `DropEvent`, so nothing is output. `ReturnLogger` returns whatever it is passed.

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/testing.py
>         raise DropEvent

- **Real backend's rules?** Explicitly denied:

Source: https://github.com/hynek/structlog/blob/26.1.0/docs/testing.md
> Note that inside the context manager all configured processors are disabled.

Source: https://github.com/hynek/structlog/blob/26.1.0/docs/testing.md
> If you want to capture logs after certain processors have been applied, they can be passed to the context manager.

- **Shows drops?** No; a processor raising `DropEvent` before `LogCapture` leaves no entry.

**The stated why**

hynek, owner (`OWNER`), in 2013, then on a contributor's proposed shape:

Source: https://github.com/hynek/structlog/issues/14
> Basically a processor that records all calls and allows assertions against it.

Source: https://github.com/hynek/structlog/issues/14#issuecomment-564013049
> wow I love that approach! Simple yet powerful!

**Inferred**

- Inferred: with processors disabled, assertions are on the event as the application built it, independent of output format. No author states this.
- Inferred from source: `capture_logs` changes only `processors`, so a level filter set via `wrapper_class` is not removed. The docs do not say this.

**No stated rationale found**

Why processors are disabled rather than kept: not in issue 14 or PR 234 (in full), PR 259 (documented the behaviour, no reason), PR 728 or the CHANGELOG entries.

**Constraints**

Process-global configuration; no failure model. Added 20.1.0; covers already-initialised bound loggers since PR 412 (changelog, under 22.1.0); *processors* parameter in 25.5.0. The docs say loggers cached under `cache_logger_on_first_use` are not affected. The source is narrower (read from source, not run): `capture_logs` empties and refills the configured processor list object in place, and a bound logger runs, at each call, the list object it was built with. So a logger built from the configured default sees capture, cached or not, while that object is still the configured one; a logger built before a later `configure(processors=...)` or `reset_defaults()` replaced the object keeps the old list and is not captured; a logger given its own `processors` is never captured. Caching decides only how long a proxy keeps the logger it built at first use. No test at `26.1.0` covers a cached logger, and PR 412 changed `testing.py`, the changelog and a test, not the docs.

Source: https://github.com/hynek/structlog/blob/26.1.0/docs/testing.md
> `capture_logs()` relies on changing the configuration.

Source: https://github.com/hynek/structlog/blob/26.1.0/docs/testing.md
> If you have *cache_logger_on_first_use* enabled for {doc}`performance <performance>`, any cached loggers will not be affected, so it’s recommended you do not enable it during tests.

Source: https://github.com/hynek/structlog/blob/26.1.0/CHANGELOG.md
> - `structlog.testing.capture_logs` now works for already initialized bound loggers.

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/testing.py
>     # Modify `_Configuration.default_processors` set via `configure` but always
>     # keep the list instance intact to not break references held by bound
>     # loggers.
>     configured_processors = get_config()["processors"]

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/testing.py
>         configured_processors.clear()
>         configured_processors.extend(processors)
>         configured_processors.append(cap)

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/_config.py
>         if self._processors is None:
>             procs = _CONFIG.default_processors
>         else:
>             procs = self._processors

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/_config.py
>     _CONFIG.default_processors = _BUILTIN_DEFAULT_PROCESSORS[:]

Source: https://github.com/hynek/structlog/blob/26.1.0/src/structlog/_base.py
>         for proc in self._processors:

**Costs and dissent**

- Contributors (`CONTRIBUTOR`), confused by the disabled processors, then the PR 728 escape hatch from a contributor (`CONTRIBUTOR`):

Source: https://github.com/hynek/structlog/pull/259
> We got confused at work when `structlog.testing.capture_logs` did not seem to capture `contextvars` bindings.

Source: https://github.com/hynek/structlog/pull/728
> I'm using a pytest fixture to capture logs in an application test suite. In some test cases it's convenient to be able to inspect context variables.

- hynek, on capture across processes:

Source: https://github.com/hynek/structlog/issues/436#issuecomment-1211699221
> Processes are isolated from each other, so you have to communicate with the task somehow explicitly.

- Chose otherwise: the OpenTelemetry fakes (T6–T8) sit after the real pipeline.

**Unverified**

None.

### T10. Sentry: `sentry::test` in Rust, and the Python SDK (sentry 0.49.6, sentry-sdk 3.0.0)

Sentry's test support. Read 2026-11-24. Rust: `test.rs`, `Hub` docs in `hub.rs` and `hub_impl.rs`, `prepare_event` and `build_envelope_sender` in `client/mod.rs`, `client_reports/mod.rs` docs, `tests/client_reports.rs`. Python: the class list of `transport.py`, a file listing of `sentry_sdk/`, `tests/conftest.py`.

**What it does**

- **Rust install.** Behind a default-off feature. `with_captured_events` binds a new hub to the current thread for a closure (as `hub_impl.rs` also says); hubs are thread-local, so parallel tests each get their own.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/test.rs
> //! **Feature:** `test` (*disabled by default*)

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/test.rs
> /// and `TestTransport`, and bind it to a newly created hub for the duration of

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/hub.rs
> /// Each thread has its own thread-local ( see [`Hub::current`]) hub, which is

- **Records.** `TestTransport` replaces only the transport; envelopes reach it after the real client's processing (scope and integration processors, `before_send`, sampling), each recording a loss reason (`BeforeSend`, `SampleRate`) when it drops an event. `with_captured_events` uses `ClientOptions::default()` unless given options, so the app's own `before_send` and sample rate apply only if the test supplies them.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/test.rs
> /// Collects events instead of sending them.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/mod.rs
>                 self.record_lost_event(ClientReportReason::BeforeSend);

- **Real backend's rules?** Docs say nothing; `test.rs` doc comments describe only collecting instead of sending.
- **Shows drops?** Yes, through envelopes, once one is sent: pending client reports with loss reasons are attached only to an outgoing envelope, returned by `TestTransport::fetch_and_clear_envelopes`, so a test that only causes drops sees no report until something sends an envelope; `with_captured_events` keeps only event items and hides them. The SDK's own tests assert drops this way, with `ClientOptions::default()` plus a DSN and a `TestTransport`, sending an empty envelope first. No option turns the counting on or off: the envelope sender always builds the aggregator, and `clientoptions.rs` has no field for client reports. The sender is a no-op unless both a DSN and a transport are set, and the aggregator is a no-op on targets without 64-bit and 8-bit atomics (read from source, not run).

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/tests/client_reports.rs
> fn assert_drop_records_client_report<F>(options: ClientOptions, capture: F, reason: Reason)

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/tests/client_reports.rs
>     client.send_envelope(Envelope::new());

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/envelope_sender.rs
>     /// If there are any pending client reports, and we are sending an envelope, we attach and
>     /// send them, too.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/client_reports/mod.rs
> /// Aggregates counts for lost data that should be reported in client reports.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/envelope_sender.rs
>         let client_report_aggregator = ClientReportAggregator::new();

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/tests/client_reports.rs
>     assert_drop_records_client_report(
>         ClientOptions::default(),

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/mod.rs
> /// If either the `dsn` or the `transport` are `None`, a no-op [`EnvelopeSender`] is returned.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/sentry-core/src/client/client_reports/mod.rs
> //! This module is a no-op on platforms lacking support for the atomics needed to collect client
> //! reports.

- **Python.** `sentry_sdk` ships no test transport and no module named for testing (the only `sentry_sdk/` file with "test" in its name is `integrations/litestar.py`); `transport.py` defines `Transport`, `HttpTransportCore`, `BaseHttpTransport`, `HttpTransport`, `AsyncHttpTransport`, `_EnvelopePrinterTransport`. The SDK's `capture_events` fixture lives in the repo's `tests/conftest.py`, outside the package, wrapping the client's transport by monkeypatching; that file also defines a no-op `TestTransport`. The base `Transport` has a loss hook a custom test transport could observe.

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/tests/conftest.py
>         """No-op capture_envelope for tests"""

Source: https://github.com/getsentry/sentry-python/blob/3.0.0/sentry_sdk/transport.py
>         """This increments a counter for event loss by reason and

**The stated why**

Not found for `TestTransport`; see **No stated rationale found**.

**Inferred**

Inferred: a fake at the transport seam exercises the client's processing and sampling, as with OpenTelemetry. Rate limiting and channel capacity live in the transport `TestTransport` replaces, so they do not apply; inferred from `build_envelope_sender` passing `transport_channel_capacity` to the transport factory (HTTP transport not read).

**No stated rationale found**

Read, for the Rust `test` module: its docs, all of `test.rs`, and a grep of the 0.49.6 CHANGELOG for `TestTransport|with_captured|test feature|client report`, which found only client-report entries silent on the test module's design. Issue tracker not searched (search quota).

**Constraints**

In-process client, background transport. Losses are counted by reason and sent later in a client report; protocol types and `Recorder` are under the 0.48.3 changelog heading.

Source: https://github.com/getsentry/sentry-rust/blob/0.49.6/CHANGELOG.md
> Transports can use this recorder to record discarded Sentry data; the SDK aggregates these reported losses and automatically sends them in a future envelope

**Costs and dissent**

No regret or complaint found; nothing searched beyond the reads above. Chose otherwise: structlog `capture_logs` (T9) disables the pipeline; `unittest.assertLogs` (T4) replaces production handlers.

**Unverified**

- Whether docs.sentry.io documents a Python test transport; not read.

#### Leads that did not hold (fakes)

- **tracing-mock captures what was recorded.** It returns no data; it validates a pre-declared ordered list of expectations and panics on mismatch (`subscriber.rs` module docs). No stable release: crates.io lists only `0.1.0-beta.1` to `0.1.0-beta.3`, `max_stable_version` null.
- **"Sentry's test transport", documented across SDKs.** Rust has one behind a default-off feature (`sentry::test::TestTransport`); Python `sentry_sdk` 3.0.0 ships none, and its `capture_events` helpers are internal to the repo's `tests/conftest.py`.
- **Any fake that promises the real backend's rules.** None of the ten. Three deny it in part: structlog disables processors, tracing-test ignores `RUST_LOG`, pytest raises on a bad record (while `logging.raiseExceptions` is true) where production prints and carries on. `assertLogs` departs from production in source but not in its docs.

## N. What the three names already mean elsewhere

Facts for the maintainer on open question 18, which asks whether confluence, establish and core are the final names. These names are not comparables, so this section records no stated why, constraints or costs. It recommends no name, ranks none, and says of none that it is good or bad.

Pinning. Docs, specifications and source files are pinned to a version, tag or commit.
Some pages cannot be pinned: atlassian.com, confluent.io, newsroom.ibm.com, the
crates.io API and sparse index, and the PyPI JSON API and simple index. For those, the
date read is the only anchor. Download counts are crates.io's totals as of 2026-11-24.
PyPI's JSON API gives no download counts: its `info.downloads` fields read `-1`.

Quotations from registry API responses are not given as blockquotes, because the
quotation check fetches those endpoints as HTML. Descriptions in the tables below are copied
from the saved JSON. Repository files are quoted in code blocks, marked "repository
file", and checked by hand rather than by the quotation check.

### N1. Confluence

| What | Where | Link | Date read |
|---|---|---|---|
| Atlassian Confluence, the product. The page title is "Confluence \| AI Workspace for Knowledge & Collaboration". | atlassian.com product page (unpinnable) | https://www.atlassian.com/software/confluence | 2026-11-24 |
| "Confluence" is listed in the Word Mark chart of Atlassian's trademark guidelines. Atlassian treats it as its trademark and says it has registered or applied to register "some of these". | Atlassian trademark guidelines (unpinnable) | https://www.atlassian.com/legal/trademark | 2026-11-24 |
| Confluent, Inc. (a near name), the data streaming company built on Apache Kafka. IBM completed its acquisition of Confluent on 2026-03-17, and confluent.io now calls it "Confluent, an IBM company". | IBM press release; confluent.io about page (both unpinnable) | https://newsroom.ibm.com/2026-03-17-ibm-completes-acquisition-of-confluent,-making-real-time-data-the-engine-of-enterprise-ai-and-agents ; https://www.confluent.io/about/ | 2026-11-24 |
| "Confluence" as a property of programs in distributed systems: an operation is confluent if its outputs do not depend on the ordering and batching of its inputs. It is the consistency notion used by the CALM Theorem. | Hellerstein and Alvaro, "Keeping CALM: When Distributed Consistency is Easy", arXiv:1901.01930v2 (26 Jan 2019), section 2.1 "Program Consistency: Confluence" | https://arxiv.org/html/1901.01930v2 | 2026-11-24 |
| Crate `confluence` 0.4.1, "Access and modify Atlassian Confluence pages from Rust". 11,061 downloads; created 2015-11-26, last updated 2019-06-13; repository https://github.com/Nercury/confluence-rs | crates.io API | https://crates.io/api/v1/crates/confluence | 2026-11-24 |
| 14 crates have "confluence" in their name (table below). Each describes itself in terms of Atlassian Confluence. | crates.io search API, `q=confluence`, 142 results, all 3 pages fetched | https://crates.io/api/v1/crates?q=confluence&per_page=100&sort=downloads | 2026-11-24 |
| Crates named with "confluent" (near name), all tied to Confluent the company: `azure_mgmt_confluent` (26,206 downloads, "generated REST API bindings"), `proto-src-confluent` (16,684), `confluent-kafka` (2,280, "Confluent Rust implementation of the Kafka client, translated from the Apache Ka…" as truncated in the extract), `azure_resourcemanager_confluent` (758). | crates.io search API, `q=confluent` | https://crates.io/api/v1/crates?q=confluent&per_page=100&sort=downloads | 2026-11-24 |
| PyPI project `confluence` 0.1, "A Python API to Confluence". One release, uploaded 2013-06-13; homepage https://bitbucket.org/phoebian/confluence | PyPI JSON API | https://pypi.org/pypi/confluence/json | 2026-11-24 |
| 134 PyPI project names contain "confluence", out of 948,905 projects in the simple index (`_last-serial` 44134606). Examples: `sphinxcontrib-confluencebuilder` 3.3.0, "Sphinx extension to build Atlassian Confluence Storage Markup", first upload 2016-07-12, latest 2026-11-20; `markdown-to-confluence` 0.6.5, "Publish Markdown files to Confluence wiki"; `llama-index-readers-confluence` 0.9.0, "llama-index readers confluence integration". | PyPI simple index (PEP 691 JSON) and JSON API | https://pypi.org/simple/ ; https://pypi.org/pypi/sphinxcontrib-confluencebuilder/json | 2026-11-24 |
| PyPI project `confluent` 0.3.2 (near name), "confluent keeps your language specific configs in sync". It is unrelated to Confluent, Inc.; uploads run 2023-08-11 to 2024-10-31. Separately, `confluent-kafka` 2.16.2 is "Confluent's Python client for Apache Kafka". In all, 57 PyPI names contain "confluent" without "confluence". | PyPI JSON API | https://pypi.org/pypi/confluent/json ; https://pypi.org/pypi/confluent-kafka/json | 2026-11-24 |

The crates with "confluence" in their name, from the crates.io search API sorted by
downloads, read 2026-11-24:

| Crate | Version | Downloads | Last updated | Description (from the API) |
|---|---|---|---|---|
| devboy-confluence | 0.35.0 | 38,010 | 2026-09-01 | Confluence self-hosted provider for devboy-tools … |
| confluence | 0.4.1 | 11,061 | 2019-06-13 | Access and modify Atlassian Confluence pages from Rust |
| atlas-confluence | 0.2.0 | 3,842 | 2023-11-12 | Simple library to interact with the Confluence REST API |
| reposix-confluence | 0.14.0 | 973 | 2026-07-14 | Confluence Cloud BackendConnector implementation for reposix. |
| confluence-dc-mcp | 0.7.9 | 821 | 2026-08-01 | Confluence Data Center MCP server, generated by mcpify. |
| typub-adapter-confluence | 0.1.7 | 820 | 2026-07-10 | Confluence adapter for typub publishing |
| confluence-cli | 0.1.44 | 796 | 2026-11-24 | A CLI for reading, searching, syncing, and automating Confluence |
| infigraph-confluence | 2.0.0 | 427 | 2026-07-02 | Confluence ingestion for Infigraph … |
| synaptic-confluence | 0.4.0 | 237 | 2026-02-25 | Confluence document loader for Synaptic |
| mcp-atlassian-confluence | 0.3.3 | 167 | 2026-10-13 | Confluence REST API client (Cloud and Server/Data Center) |
| confluence-archiver | 0.2.1 | 146 | 2026-01-27 | A Confluence archiving tool to export Pages or Spaces as Markdown/HTML with local assets. |
| mcp-confluence | 1.1.0 | 64 | 2026-04-24 | MCP server for Confluence integration - create, update, search, and manage Confluence pages |
| confluence-workflow | 0.2.0 | 34 | 2026-04-21 | Merge Markdown files into Confluence pages while preserving inline comments |
| lib-client-confluence | 0.1.0 | 29 | 2025-12-29 | Confluence API client library for ADI |

Quotations:

Source: https://www.atlassian.com/legal/trademark
> Atlassian uses a number of terms and logos as active trademarks in branding its products and services including, but not limited to, those displayed in the chart below.

The chart's cells run together once the tags are stripped. The word marks include
"Confluence":

Source: https://www.atlassian.com/legal/trademark
> Jira Service ManagementJira CoreJira OpsStatuspageOpsgenieConfluenceTrello

Source: https://www.atlassian.com/software/confluence
> Bring your people, knowledge, and work together in one connected workspace.

Source: https://newsroom.ibm.com/2026-03-17-ibm-completes-acquisition-of-confluent,-making-real-time-data-the-engine-of-enterprise-ai-and-agents
> IBM (NYSE: IBM) today completed its acquisition of Confluent, Inc., the data streaming platform that more than 6,500 enterprises, including 40% of the Fortune 500, rely on to power real-time operations.

Source: https://newsroom.ibm.com/2026-03-17-ibm-completes-acquisition-of-confluent,-making-real-time-data-the-engine-of-enterprise-ai-and-agents
> Built on Apache Kafka®, the standard for data streaming, Confluent is already embedded in the operational fabric of the world's largest enterprises

Source: https://www.confluent.io/about/
> Confluent, an IBM company

Source: https://arxiv.org/html/1901.01930v2
> an operation on a single machine is confluent if it produces the same set of outputs for any non-deterministic ordering and batching of a set of inputs.

Source: https://arxiv.org/html/1901.01930v2
> Confluent operations compose: if the outputs of one confluent operation are consumed by another, the resulting composite operation is confluent.

### N2. Establish

| What | Where | Link | Date read |
|---|---|---|---|
| TCP's `ESTABLISHED` connection state: "an open connection", the normal state for data transfer. It sits in the state list with SYN-SENT, SYN-RECEIVED, FIN-WAIT-1 and the others. Section 3.5 is titled "Establishing a Connection" (the three-way handshake). | RFC 9293, STD 7, IETF Standards Track, August 2022, W. Eddy (Ed.). It obsoletes RFC 793 and others. | https://www.rfc-editor.org/rfc/rfc9293.html | 2026-11-24 |
| Linux kernel enum constant `TCP_ESTABLISHED = 1`, the first value of the TCP `sk_state` enum, with the flag `TCPF_ESTABLISHED`. | `include/net/tcp_states.h` at tag `v7.3` | https://github.com/torvalds/linux/blob/v7.3/include/net/tcp_states.h | 2026-11-24 |
| Diesel's `Connection::establish(database_url: &str) -> ConnectionResult<Self>`, a required method of the `Connection` trait, which "Establishes a new connection to the database". Diesel 2.4.0 has 47,654,108 downloads on crates.io. | docs.rs, diesel 2.4.0 | https://docs.rs/diesel/2.4.0/diesel/connection/trait.Connection.html | 2026-11-24 |
| No crate named `establish`: the crates.io API returns 404 for `/crates/establish`, and the sparse index returns 404 for `es/ta/establish`. | crates.io API and sparse index | https://crates.io/api/v1/crates/establish ; https://index.crates.io/es/ta/establish | 2026-11-24 |
| No crate name containing "establish" appeared among the 300 most relevant and the 200 most downloaded results for `q=establish`, which returns 5,889 fuzzy matches. This does not cover the other matches. | crates.io search API | https://crates.io/api/v1/crates?q=establish&per_page=100 | 2026-11-24 |
| No PyPI project named `establish` (the JSON API returns 404). None of the 948,905 names in the PyPI simple index contains "establish". | PyPI JSON API and simple index | https://pypi.org/pypi/establish/json ; https://pypi.org/simple/ | 2026-11-24 |

Quotations:

Source: https://www.rfc-editor.org/rfc/rfc9293.html
> represents an open connection, data received can be
> delivered to the user.

(Line breaks collapsed: the RFC wraps the line with an indent.)

Source: https://www.rfc-editor.org/rfc/rfc9293.html
> The "three-way handshake" is the procedure used to establish a

Source: https://github.com/torvalds/linux/blob/v7.3/include/net/tcp_states.h
> TCP_ESTABLISHED = 1,

Source: https://docs.rs/diesel/2.4.0/diesel/connection/trait.Connection.html
> Establishes a new connection to the database

### N3. Core

| What | Where | Link | Date read |
|---|---|---|---|
| Rust's built-in `core` crate, "The Rust Core Library". It is the dependency-free foundation of `std`, with no allocation, concurrency or I/O, and it is stable since Rust 1.6.0 according to the page. | Rust standard library docs, 1.100.0 (`0ef1bc386`, 2026-11-09). Rust 1.100.0 is the latest GitHub release, published 2026-11-12. | https://doc.rust-lang.org/1.100.0/core/index.html | 2026-11-24 |
| `core` is always in the extern prelude, so a `core::` path resolves to it unless a declaration in the module shadows the name, or the module or an ancestor carries `no_implicit_prelude`, which keeps the extern prelude out of scope. | The Rust Reference, 1.100.0, "Preludes" | https://doc.rust-lang.org/1.100.0/reference/names/preludes.html | 2026-11-24 |
| `core` is a reserved crate name on crates.io: publishing it fails with "cannot upload a crate with a reserved name". The API returns 404 for `/crates/core`, and the sparse index returns 404 for `co/re/core`. | crates.io source at `7866a45`: the reserved-names migration and `publish.rs` | https://github.com/rust-lang/crates.io/blob/7866a4599199c2034bc631eb067d764486bf7a3a/migrations/20170305095748_create_reserved_crate_names/up.sql | 2026-11-24 |
| `tracing-core` 0.1.36: "Core primitives for application-level tracing." 1,105,015,107 downloads. | crates.io API; docs.rs | https://docs.rs/tracing-core/0.1.36/tracing_core/ | 2026-11-24 |
| `futures-core` 0.3.34: "The core traits and types in for the `futures` library." 1,201,112,691 downloads. | crates.io API; docs.rs | https://docs.rs/futures-core/0.3.34/futures_core/ | 2026-11-24 |
| `rand_core` 0.10.1: "Core random number generator traits and tools for implementation." 2,304,374,799 downloads. | crates.io API; docs.rs | https://docs.rs/rand_core/0.10.1/rand_core/ | 2026-11-24 |
| `serde_core` 1.0.229, created 2025-09-13: "Serde traits only, with no support for derive -- use the `serde` crate instead". 923,958,146 downloads. | crates.io API; docs.rs | https://docs.rs/serde_core/1.0.229/serde_core/ | 2026-11-24 |
| Other `*core` crates among the top results for `q=core` by downloads, with crates.io descriptions: `parking_lot_core` (1,356,731,273), "An advanced API for creating custom synchronization primitives."; `time-core` (849,893,498), "This crate is an implementation detail and should not be relied upon directly."; `rayon-core` (681,818,375), "Core APIs for Rayon". The older `tokio-core` 0.1.18 (8,578,396; last updated 2020-12-05) is described as "Core I/O and event loop primitives for asynchronous I/O in Rust. Foundation for the rest of the tokio crates." | crates.io API | https://crates.io/api/v1/crates?q=core&per_page=100&sort=downloads ; https://crates.io/api/v1/crates/tokio-core | 2026-11-24 |
| PyPI project `core` 1.0.1. The summary and description are empty, the only classifier is "Development Status :: 1 - Planning", the license field reads "GNU GPL" and the author is "Alex" (owner `konteck`). Its one release has no files, so there is no upload date. `last_serial` is 238755. | PyPI JSON API | https://pypi.org/pypi/core/json | 2026-11-24 |
| In this repository, `libtransect` is called the core (quoted below). | `crates/libtransect/Cargo.toml`, `crates/libtransect/src/lib.rs`, `AGENTS.md` (repository files) | repository files, cited by path | 2026-11-24 |

Quotations:

Source: https://doc.rust-lang.org/1.100.0/core/index.html
> It links to no
> upstream libraries, no system libraries, and no libc.

Source: https://doc.rust-lang.org/1.100.0/core/index.html
> The core library is minimal: it isn’t even aware of heap allocation,
> nor does it provide concurrency or I/O.

Source: https://doc.rust-lang.org/1.100.0/reference/names/preludes.html
> The core crate is always added to the extern prelude.

Source: https://doc.rust-lang.org/1.100.0/reference/names/scopes.html
> The prelude names may be shadowed by declarations in a module.

Source: https://doc.rust-lang.org/1.100.0/reference/names/preludes.html
> The no_implicit_prelude attribute prevents the standard library prelude, extern prelude, macro_use prelude, and the tool prelude from being brought into scope for the module and its descendants.

Source: https://github.com/rust-lang/crates.io/blob/7866a4599199c2034bc631eb067d764486bf7a3a/migrations/20170305095748_create_reserved_crate_names/up.sql
> ('compiletest'), ('core'), ('coretest'),

Source: https://github.com/rust-lang/crates.io/blob/7866a4599199c2034bc631eb067d764486bf7a3a/src/controllers/krate/publish.rs
> return Err(bad_request("cannot upload a crate with a reserved name"));

Source: https://docs.rs/tracing-core/0.1.36/tracing_core/
> This crate defines the core
> primitives of tracing.

Source: https://docs.rs/futures-core/0.3.34/futures_core/
> Core traits and types for asynchronous operations in Rust.

Source: https://docs.rs/rand_core/0.10.1/rand_core/
> Note that the traits focus solely on the core RNG functionality.

Source: https://docs.rs/serde_core/1.0.229/serde_core/
> The serde_core crate contains Serde’s trait definitions with no support
> for #[derive()].

The repository's own descriptions of `libtransect` follow. These are repository files,
quoted exactly and not fetched; they were checked with `grep -F` against the worktree on
2026-11-24.

Repository file `crates/libtransect/Cargo.toml`, line 5:

```text
description = "The core of Transect's in-application client."
```

Repository file `crates/libtransect/src/lib.rs`, lines 1 to 3:

```text
//! The core of Transect's in-application client.
//!
//! The client is not implemented yet, so this crate holds one item: its version.
```

Repository file `AGENTS.md`, lines 8 and 15 to 17:

```text
This repository holds Transect's in-application client: a Rust core, a Rust client API
```

```text
- `crates/libtransect/` is the core, where every behaviour of the client will live. Unit
  tests sit beside the code under `#[cfg(test)]`; public items carry asserting doctests.
- `crates/transect/` is the Rust client API, built on the core.
```

Repository file `AGENTS.md`, lines 96 and 97 (the `rust-change` block):

```text
Use the `rust-change` skill, and `review-change` to review the result. Behaviour belongs
in the core; the Rust client and the binding translate it. Run `just fmt-check`,
```

#### Unverified (names)

- Confluence's trademark registration: the Atlassian page says only that "some of these"
  marks are registered or applied for. No trademark register was searched (USPTO TSDR,
  IP Australia or others), so whether "Confluence" itself is registered, and where, is
  unconfirmed.
- "Confluence" in term rewriting (the Church–Rosser property) is a well-known meaning
  from memory. No primary source was fetched for it, so it is not tabled.
- crates.io names containing "establish": only the top 300 by relevance and the top 200 by
  downloads, out of 5,889 fuzzy matches, were checked. A crate whose name contains
  "establish" further down that list is not ruled out. The exact name `establish` is
  ruled out by the 404s.
- PyPI download counts: the PyPI JSON API does not provide them (`-1`), and no
  third-party statistics service was used.
- The confluent.io about page and the IBM newsroom page are unpinnable and may change.
  The text quoted is from the copies saved on 2026-11-24.

#### Leads that did not hold (names)

- "crates or packages named `establish`": none exists. The crates.io API returns 404 for
  `/api/v1/crates/establish`, the sparse index returns 404 for `es/ta/establish`, the
  PyPI JSON API returns 404 for `/pypi/establish/json`, and no name in the PyPI simple
  index (948,905 projects) contains "establish".
- "`core` on PyPI": the project exists, but as an empty placeholder: version 1.0.1 with
  an empty summary, a "Planning" classifier and no uploaded files.
- `core` on crates.io (implied by the `*-core` lead): there is no crate `core`. The name
  is reserved in crates.io's `reserved_crate_names` table (migration
  `20170305095748_create_reserved_crate_names`), and the API and sparse index return 404.
