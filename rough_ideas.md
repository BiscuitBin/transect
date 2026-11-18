# Table-based observability client: design brief

Nov 10, 2026 · @Steven

A Rust-core client lets Python applications declare state and time series tables up front and write rows through a local ingest queue into local databases on each application instance. A cluster-level collector gathers those databases, compacts them and publishes to object storage every 5 to 15 minutes for SQL consumers.

## Goals

The client replaces metrics with tables: each one is declared up front as **state** (latest value per key) or **time series** (append-only rows), with typed columns. It should close five gaps in a Prometheus/OTel plus structured-logs setup:

- **High-cardinality dimensions** that would overwhelm a metrics backend.
- **Relational application state**, captured as joinable tables grouped into namespaces.
- **Cheap, highly compressed logs** and other high-volume rows.
- **SQL over everything**: one query model across state, metrics and logs.
- **Per-tenant segmentation** of runtime data on a platform, where sending data to the wrong consumer is costly.

Two constraints, stated for schema changes and treated here as general: the client never raises runtime errors in the host application, and nothing a client does may block new data from being published. Python is the first target; other languages follow.

## Data path

&#91;embedded content: data path · application instance, collector, object storage\]

Each application instance (a VM or container) holds its own ingest queue, data writer and local databases; the queue and the writer thread sit outside the web worker processes. The collector runs once or a few times per cluster, like a Prometheus scraper or OTel collector: it gathers the instances' local databases, compacts them and publishes. A second compactor and the optional projection service are separate cluster services that work on the files already in object storage.

## Decisions so far

Fifteen points are settled enough to build against; anything marked "proposed" was suggested in the interview and not yet confirmed.

| Area | Decision | Note |
| --- | --- | --- |
| Table model | Tables are declared up front as state or time series, with columns | State tables group into namespaces |
| Implementation | Rust core, Python client first | Rust is the likely choice; other languages later |
| Client-side state | Latest only | History may be kept in object storage |
| Atomicity | Atomic publish per namespace for the MVP | An app-facing atomic write concept is a post-MVP option |
| Ingest queue | One per application instance, outside the worker processes; it keeps slow columnar writes off the hot path | The client in each worker process writes to it |
| Queue-full behavior | Configurable per table | Proposed default: drop and count |
| Multi-process sharing | Worker processes share the local ingest queue; one data writer drains it | Mechanism is open; see below |
| Data writer | A thread in each application instance, outside the worker processes, that writes the local databases | Local databases live on disk, not in memory; which process hosts the thread is open |
| Collector | One or a few per cluster, like a Prometheus scraper or OTel collector; it gathers each instance's local databases, compacts them and publishes | Not a per-host service; it keeps its own local databases, with a compactor and a publisher inside |
| Object-storage compaction | A separate compactor, one or a few per cluster, compacts the published files | The projection service is likewise a separate service working on object storage |
| Tenant isolation | Shared files with a tenant column | An optional projection service writes tenant-specific files after compaction |
| Tenant stamping | Explicit on every write, and/or structlog-style binding | Proposed: a write with no tenant is dropped and counted, never raised |
| Freshness | 5 to 15 minutes from write to queryable | Favors large, well-compressed files |
| Producers | Long-lived services, forked worker pools, many hosts or containers | Short-lived jobs are not part of the first deployment |
| Consumers | Internal dashboards, ad hoc SQL, platform tenants, automated jobs | Tenant-specific files come from the projection service |

## Open questions

Ten questions are undecided; the first three shape the architecture most and each has a prototype below.

| Question | Options on the table | What settles it |
| --- | --- | --- |
| How do worker processes share the local ingest queue? | One append-only file of framed batches; per-worker segment files in a shared directory; a local daemon that owns the store | Prototype 1. RocksDB allows one writing process, so workers cannot each open it |
| Which process hosts the data writer thread? | The pool's parent process; one elected worker; a separate process in the instance | Prototype 1. A thread started before fork does not carry into the child processes |
| What is published to object storage? | Parquet with a table format (Iceberg, Delta, DuckLake); Parquet with a small manifest you own | Prototype 3. Whether atomic publish, history and schema tracking justify the dependency |
| How do table definitions change during a rolling deploy? | Additive only; versioned schemas; a Prometheus-like experience where the client simply registers what it has | Prototype 4. Must hold both constraints: no client errors, no blocked publishing |
| What does a state capture write? | Full snapshot per capture; keyed upserts and deletes | Size and churn of real state tables in the first application |
| Is state history kept after publish? | Latest only; prior versions retained for time travel | Whether any report needs past state; storage cost |
| Do state writes coalesce by key in the queue? | Proposed: yes, so a slow drain loses intermediate versions but never overflows | Confirm no consumer needs every intermediate version |
| How do local databases reach the collector? | The collector scrapes each instance; each instance pushes on a timer | Prototype 3. The collector is a cluster service, so this is a network transfer with discovery and retries |
| What is lost when an instance dies before its local databases are collected? | Accept the loss; flush on shutdown; keep local databases on a volume that outlives the instance | How long an instance can hold uncollected data, and whether any table is audit-grade |
| How is a wrong or missing tenant caught? | Required at bind time; validated against an allow-list; quarantined at projection | The projection service cannot repair a bad stamp, so this must be decided before tenants read data |

Not yet discussed: how other languages share the Rust core (bindings versus thin clients that write the log format), retention and per-tenant deletion, the local table format (DuckDB files or another columnar format), and how the client reports its own drops and lag.

## Prototypes

Five experiments, in dependency order; the first decides the local architecture and should run before any client API work.

1. **Local ingest queue bake-off.** Build the three queue designs and drive each from forked gunicorn workers, with the data writer thread hosted each candidate way. Measure hot-path write latency (p99), throughput, behavior when a worker is killed mid-write, and recovery after a crash.
2. **Drain to columnar.** Have the data writer drain the winning queue into local databases. Measure drain lag under load and compression ratio on real log rows.
3. **Publish and read.** Have one collector gather local databases from several application instances, compact them and publish to object storage in both candidate formats, then run the storage compactor over the result. Confirm a reader never sees a partial namespace, then query from DuckDB and a dashboard.
4. **Schema drift.** Run two client versions with different definitions of the same table at once. Pass means no client error and no stalled publish.
5. **Tenant projection.** Project per-tenant files from compacted shared files. Test that no row reaches the wrong tenant and decide what happens to rows with a missing tenant.
