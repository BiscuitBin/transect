# Research: table definitions over time

- **Ticket:** `issues/15-research-the-why-table-definitions-over-time.md`. It bears on open questions 13 and 20 of `docs/specs/transect-client.allium`.
- **Sources read:** every source on 2026-11-25 (UTC), which was 2026-11-24 in the researcher's local time.
- **Web research:** authorised by the maintainer on 2026-11-24 for this ticket, for the agent working it and for its reviewers.
- **State of this file:** complete. The findings, up to "Candidates not examined, or dropped", passed the first adversarial review in two rounds. Fit, the fairness of the comparison, the two verdicts, the proposed wording and what the findings bear on were written after it, and the second review covers them.

## How the sources were checked

Six survey agents found the candidates, one per group of systems, and saved raw text. The author then fetched every cited source again, independently:

- source and documentation files at a pinned tag or commit, through `raw.githubusercontent.com`;
- issue, pull request, comment, review-comment, commit and release text through the GitHub REST API, and a quotation cited to one comment from that comment alone;
- a Google Docs design document through its plain-text export;
- vendor pages, blog posts and mailing-list archives as HTML, with the tags stripped;
- the Thrift paper, a PDF, as text extracted with macOS PDFKit.

Each quotation below was then checked by machine as a substring of that text. A source line names the quotations under it, such as `(quoted as otel-25)`, and the text uses those labels to refer back to them. A quotation that matches only once line breaks, indentation, comment markers or the PDF's ligatures are collapsed is still verbatim in its wording.

Versions were resolved from each project's releases or tags on the read date, not from memory. Where a project publishes no tags, the commit is named. A quotation from source code keeps the comment markers and escapes it has in the file.

Who is quoted is labelled: an author of the system (a maintainer, a member of the project, or the person who wrote the proposal or the page), a contributor, or a third party such as a user. For GitHub, the label follows the author association GitHub records, and "member" means a member of the project's GitHub organisation.

## What the specification proposes

The two behaviours this ticket checks, as the specification states them:

- **Nothing enforced across runs.** "The client enforces nothing about a definition that changed between runs. Each run's local databases carry the definitions they were written with." (`@guarantee NothingAcrossRuns`)
- **Declare at any time.** "A table may be declared at any time, with or without a run in force." (`rule DeclareTable`) and "A table declared while a run is in force is usable at once." (`rule OpenCountersForLateTable`)

Three neighbouring statements in the specification matter for the comparison, and are quoted here, not judged:

- **Within one confluence, a definition is checked.** A declaration that "repeats a namespace and name with any difference" fails loudly and changes nothing (`rule DeclareTable`, `@guarantee RedeclarationReturnsTheSameTable`).
- **Why declaring may fail loudly.** "Declaring fails loudly because it runs at start-up, where the developer can see it." (`@guidance` in the same surface)
- **What a row must fit.** A column is required or optional, and "A missing required column, an unknown column or a value of the wrong type: the row is refused whole and nothing is converted." (the comment above the rule that counts `rejected_invalid`)

The vocabulary below follows the specification. A **run** is "one establish". A deployment or restart of the application starts a new one. A **process** is one operating-system process. A run's definitions live in that run's local databases.

---
## Checking nothing across processes

### C1. Prometheus client libraries: client_golang and client_python

**What it does.** Read at client_golang `v1.25.0`, client_python `v0.26.0`, and the client library guidelines in `prometheus/docs` at commit `31957d4`.

- **client_golang checks one registry, in one process.** At registration it compares, for one name, the help string, the unit and the label names. A mismatch makes `Register` return an error, and `MustRegister` panic.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/desc.go#L34-L38 (quoted as prometheus-3)

  > Descriptors registered with the same registry have to fulfill certain
  > // consistency and uniqueness criteria if they share the same fully-qualified
  > // name: They must have the same help string and the same label names (aka label
  > // dimensions) in each, constLabels and variableLabels, but they must differ in
  > // the values of the constLabels.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/registry.go#L329 (quoted as prometheus-2)

  > a previously registered descriptor with the same fully-qualified name as %s has different label names or a different help string

- **Type is checked only when the registry is gathered, at each scrape**, because a descriptor carries no type. By default one inconsistent metric fails the whole scrape of that process with HTTP 500.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/registry.go#L689 (quoted as prometheus-5)

  > // TODO(beorn7): Simplify switch once Desc has type.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/promhttp/http.go#L484-L485 (quoted as prometheus-10)

  > // Serve an HTTP status code 500 upon the first error
  > 	// encountered.

- **A definition is remembered for the registry's lifetime, even after `Unregister`.**

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/registry.go#L127-L132 (quoted as prometheus-1)

  > Note that even after unregistering, it will not be possible to
  > 	// register a new Collector that is inconsistent with the unregistered
  > 	// Collector, e.g. a Collector collecting metrics with the same name but
  > 	// a different help string. The rationale here is that the same registry
  > 	// instance must only collect consistent metrics throughout its
  > 	// lifetime.

- **Registration may happen at any time.** `Register` takes the registry's mutex, and nothing found in `registry.go` restricts it to before the handler serves. The package documentation expects inconsistencies to show up at start-up "usually":

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/doc.go#L165-L170 (quoted as prometheus-8)

  > Inconsistencies are ideally detected at registration time, not at collect
  > // time. The former will usually be detected at start-up time of a program,
  > // while the latter will only happen at scrape time, possibly not even on the
  > // first scrape if the inconsistency only becomes relevant later. That is the
  > // main reason why a Collector and a Metric have to describe themselves to the
  > // registry.

- **client_python checks names only.** The registry compares only the names a collector produces, not help, type or labels. A second registration of the same name raises `DuplicateTimeseries`, a `ValueError`, even when the definition is identical (Inferred from the code). The check covers only names the registry can obtain: a custom collector with no `describe` method, in a registry built without `auto_describe`, yields no names and is not checked. `auto_describe` is off by the constructor's default and on for the global `REGISTRY` (Inferred from `registry.py`). A metric registers when its object is constructed, under a lock, so at any point in the program.

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/registry.py#L49-L51 (quoted as prometheus-32)

  > duplicates = set(self._names_to_collectors).intersection(names)
  >             if duplicates:
  >                 raise DuplicateTimeseries(duplicates)

- **client_python's multiprocess mode merges per-process files with no check across processes.** It is the one place in this survey where Prometheus code merges data that separate processes wrote to local files. The first file that names a metric sets its help and type, and samples from every other file are added to it. That a worker with a different definition is merged under the first one seen is Inferred from the code, and so is the absence of an error, with one exception found in the same code. When the first file read for a name is a histogram's, every sample with an `le` label is parsed as a bucket bound. A gauge does not reserve `le`, so another worker's gauge may carry one that is not a number, and collection then raises `ValueError`. That path was read, not run. Files from earlier runs are not reconciled: the directory must be wiped.

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/multiprocess.py#L74-L77 (quoted as prometheus-35)

  > metric = metrics.get(metric_name)
  >                 if metric is None:
  >                     metric = Metric(metric_name, help_text, typ)
  >                     metrics[metric_name] = metric

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/docs/content/multiprocess/_index.md#L32-L33 (quoted as prometheus-37)

  > This directory must be wiped
  > between process/Gunicorn runs (before startup is recommended).

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/multiprocess.py#L132-L133 (quoted as author-75)

  > if l[0] == 'le':
  >                             bucket_value = float(l[1])

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/metrics.py#L613 (quoted as author-76)

  > _reserved_labelnames = ['le']

- **The guidelines that bind every official client** intend metrics as file-static globals that register implicitly, while requiring registries to allow `register()` and `unregister()`.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L95-L96 (quoted as prometheus-25)

  > These should be primarily used as file-static variables, that is, global
  > variables defined in the same file as the code they’re instrumenting.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L104-L105 (quoted as prometheus-27)

  > There MUST be a default CollectorRegistry, the standard metrics MUST by default
  > implicitly register into it with no special work required by the user.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L66-L67 (quoted as prometheus-29)

  > CollectorRegistry SHOULD offer `register()`/`unregister()` functions, and a
  > Collector SHOULD be allowed to be registered to multiple CollectorRegistrys.

**Stated why.**

- **Why check at registration:** to catch an inconsistency at start-up rather than at a later scrape. That is the package documentation's reason, quoted above as prometheus-8.
- **Why only within one binary.** beorn7, then the sole maintainer named in client_golang's `MAINTAINERS.md`, refusing a request to re-register a metric with more labels (2021):

  Source: https://github.com/prometheus/client_golang/issues/203#issuecomment-827144006 (quoted as prometheus-16)

  > That's not possible by design. The idea is that one and the same binary, during its lifetime, never exposes metrics that are inconsistent with each other.

  Source: https://github.com/prometheus/client_golang/issues/203#issuecomment-829148470 (quoted as prometheus-17)

  > When dealing with non-trivial PromQL, it's very confusing if labels on a metric suddenly appear or disappear. We cannot prevent that from happening globally, but at least instrumentation libraries can guarantee it for the pre-defined collectors over the lifetime of a binary.

- **Why custom collectors are not checked for consistent labels**, from the guidelines:

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L251-L253 (quoted as prometheus-31)

  > Metrics from custom collectors should almost always have consistent label
  > names. As there are still rare but valid use cases where this is not the case,
  > client libraries should not verify this.

- **Why metrics are globals**, from the guidelines:

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L99-L102 (quoted as prometheus-26)

  > Users shouldn’t have to worry about plumbing their metrics throughout
  > their code, the client library should do that for them (and if it doesn’t,
  > users will write a wrapper around the library to make it "easier" - which
  > rarely tends to go well).

- **Why registration may happen at any time: no stated rationale found.** Looked in client_golang's `registry.go` and `doc.go` at `v1.25.0`, `writing_clientlibs.md`, client_golang issues #47 and #203, and GitHub searches for registering at run time. Two further searches of beorn7's comments hit GitHub's rate limit.
- **client_python's name-only check, and wiping rather than reconciling the multiprocess directory: no stated rationale found.** Looked in `registry.py`, `metrics.py`, `multiprocess.py` and the multiprocess documentation at `v0.26.0`, and in issues #626, #671, #732, #815 and #1042. A maintainer's replies there are usage advice, such as csmarchbanks (member):

  Source: https://github.com/prometheus/client_python/issues/671#issuecomment-868543914 (quoted as prometheus-40)

  > You should not be creating a new `Counter` each time `REQUEST_COUNT` is called.

**Inferred why.** Inferred: the guidelines require every collector to be called on each scrape, so a collector registered late simply appears in the next scrape, and nothing about the pull model needs registration to end before serving.

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md#L53-L54 (quoted as prometheus-28)

> Every time the CollectorRegistry is scraped it must
> callback to each of the Collectors’ collect method.

**Constraints.**

- The pull model: each process serves its own `/metrics`. The client can check only its own registry, which is the limit beorn7 names ("We cannot prevent that from happening globally").
- The registry's memory lasts for the life of the process (prometheus-1). Inferred: a restart clears it, so a new version of the binary can register a different definition under the same name and nothing in the client notices.
- The text exposition format allows one `HELP` line and one `TYPE` line per name. That this format rule is why help must match is Inferred.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/exposition_formats.md (quoted as prometheus-41, prometheus-42)

  > Only one `HELP`
  > line may exist for any given metric name.

  > Only one
  > `TYPE` line may exist for a given metric name.

**Costs and dissent.**

- **Two versions of client_golang in one binary break the scrape** when a help string changed between them. The issue is open.

  johnharris85 (third party):

  Source: https://github.com/prometheus/client_golang/issues/1820 (quoted as prometheus-19)

  > makes interoperability between different golang applications utilizing different versions of the client problematic (as the validation fails).

  kakkoyun (maintainer):

  Source: https://github.com/prometheus/client_golang/issues/1820#issuecomment-3069326395 (quoted as prometheus-20)

  > Rather than disabling the strict check, we can add a special case to handle version discrepancies maybe.

  An open pull request proposes a lenient mode. spor3006 (contributor), its author:

  Source: https://github.com/prometheus/client_golang/pull/2006 (quoted as prometheus-22)

  > A trivial difference like a help string gaining or losing a trailing period across a `client_golang` upgrade turns a metadata mismatch into a hard `/metrics` outage for the whole binary (see #1820).

  The same author keeps the strict default:

  Source: https://github.com/prometheus/client_golang/pull/2006 (quoted as prometheus-23)

  > The strict default has value: it surfaces accidental help-text changes during development and testing.

- **A user asked to redefine a metric at run time**, and beorn7 refused (prometheus-17). xaionaro (third party):

  Source: https://github.com/prometheus/client_golang/issues/203#issuecomment-828752584 (quoted as prometheus-18)

  > The positive impact is clear: for example it will be possible to re-register a metric with another set of labels.

- **client_python's duplicate check catches reloads.** The issue search above returns more than ten reports titled "Duplicated timeseries in CollectorRegistry", from multiprocess mode, re-creating a metric in a loop, and module reloads. kerrick-js (third party), on Jupyter `autoreload`:

  Source: https://github.com/prometheus/client_python/issues/1042 (quoted as prometheus-39)

  > I think instantiating a metric should be idempotent.

**Fit.** In the table under "Fit".

### C2. Prometheus server: scrape, storage, metadata, federation and remote write

**What it does.** Read at `prometheus/prometheus` `v3.16.0`, `prometheus/docs` at `31957d4` and `prometheus/proposals` at `738d590`.

- **A series is identified by name and labels.** Type, help and unit are not part of the identity.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/concepts/data_model.md#L14 (quoted as prometheus-43)

  > Every time series is uniquely identified by its metric name and optional key-value pairs called labels.

- **By default, two targets do not share a series**, because the server attaches `job` and `instance` labels to what it scrapes. Inferred: under that default, two targets that expose one name with different types, help or label names produce separate series, kept side by side, and nothing at ingestion compares them.

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/concepts/jobs_instances.md#L19-L20 (quoted as prometheus-44)

  > When Prometheus scrapes a target, it attaches some labels automatically to the
  > scraped time series which serve to identify the scraped target:

  A scrape configuration can give this up. With `honor_labels` set to true, which federation and scraping the Pushgateway use, the labels a target exposes win over the ones the server attaches. Inferred: two targets then write one series when their final label sets match. A server-side label is attached only where the target does not expose one of that name (author-97). So two targets can collide when both expose the same values, and also when one exposes the very value the server attaches to the other, such as the other's `instance`. Relabelling can change the result. What the server does with such a series was examined only as far as one path in the scrape loop: a sample with a different value but the same timestamp as one already stored is dropped, counted and logged as a warning. Inferred: two writers reach that path only when they write the same timestamp. Whatever else happens to such a series was not examined.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/configuration/configuration.md#L381-L382 (quoted as author-2)

  > # If honor_labels is set to "true", label conflicts are resolved by keeping label
  > # values from the scraped data and ignoring the conflicting server-side labels.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/configuration/configuration.md#L389-L391 (quoted as author-3)

  > # Setting honor_labels to "true" is useful for use cases such as federation and
  > # scraping the Pushgateway, where all labels specified in the target should be
  > # preserved.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/scrape.go#L2073-L2075 (quoted as author-77)

  > sl.l.Warn("Error on ingesting samples with different value but same timestamp", "num_dropped", appErrs.numDuplicates)

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/scrape.go#L653-L657 (quoted as author-97)

  > if !lset.Has(l.Name) {

- **Metadata is held per target in a scrape cache, keyed by name, and is overwritten when a target changes it.** It is not stored in the time-series database by default; storing it is an open proposal, issue #12608.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/scrape.go#L1026 (quoted as prometheus-45)

  > metadata map[string]*metaEntry // metadata by metric family name.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/scrape/scrape.go#L1193-L1194 (quoted as prometheus-47)

  > if e.Type != t {
  > 		e.Type = t

- **The metadata API returns every distinct version among the targets currently scraped.** It is marked experimental, and it does not cover targets no longer scraped.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/querying/api.md (quoted as prometheus-48, prometheus-49)

  > each value is a list of unique metadata objects, as exposed for that metric name across all targets.

  > At least one target has a value for `HELP` that do not match with the rest.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/querying/api.md#L1515-L1516 (quoted as author-4)

  > It returns metadata about metrics currently scraped from targets. However, it does not provide any target information.

- **Federation drops type and help for ordinary float series.**

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/federation.md#L15-L17 (quoted as prometheus-53)

  > for technical reasons, float samples are always federated
  > as `untyped`, while histogram samples are federated with their full type
  > information)

- **Before remote write 2.0, one target's metadata overwrote another's** downstream. The authors of the remote write 2.0 proposal (alexgreenbank, bwplotka, cstyan and npazosmendez):

  Source: https://github.com/prometheus/proposals/blob/3d85921828eeee033fd71f8730a1638bc5307f4a/proposals/2024-04-09_remote-write-20.md#L204 (quoted as prometheus-62)

  > Prometheus didn't have metadata persistence or series differentiation. Metadata was actually cached in memory on a per-metric name basis. That meant that if two targets exported the same metric name with different metadata, whichever was scraped most recently would have its metadata cached.

  Remote write 2.0 carries metadata per series. A sender SHOULD provide it, and MUST give the type only in the stateless modes. A receiver may reject a series without a type. Prometheus itself sends it only with the `metadata-wal-records` feature flag on:

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/specs/prw/remote_write_spec_2_0.md#L383 (quoted as prometheus-64)

  > * `metadata` sub-fields SHOULD be provided (in [`stateless` and `stateless-st` modes](#modes), `Metadata.type` MUST be specified). Receivers MAY reject series with unspecified `Metadata.type`.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/feature_flags.md#L173 (quoted as author-5)

  > This must be used if you would like to send metadata using the new remote write 2.0.

- **An accepted proposal adds type and unit to a series' labels** (PROM-39, owners dashpole and bwplotka). `v3.16.0` implements it behind the feature flag `type-and-unit-labels`, which is off by default. As the proposal designs it, a query over one name with differing types or units then returns both, with an annotation. That `v3.16.0` emits the annotation was not checked.

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/feature_flags.md#L264-L267 (quoted as author-6)

  > When enabled, Prometheus will start injecting additional, reserved `__type__`
  > and `__unit__` labels as designed in the [PROM-39 proposal](https://github.com/prometheus/proposals/pull/39).

  Source: https://github.com/prometheus/prometheus/blob/v3.16.0/docs/feature_flags.md#L6 (quoted as author-7)

  > Here is a list of features that are disabled by default since they are breaking changes or are considered experimental.

  Source: https://github.com/prometheus/proposals/blob/738d59014c53658753d21f8dc6253292654302b7/proposals/0039-metadata-labels.md#L7 (quoted as prometheus-73)

  > **Implementation Status:** `Accepted`

  Source: https://github.com/prometheus/proposals/blob/738d59014c53658753d21f8dc6253292654302b7/proposals/0039-metadata-labels.md#L72 (quoted as prometheus-71)

  > When a query for a metric returns multiple metrics with a different `__type__` or `__unit__` label, but the same `__name__`, the query returns an info annotation, which is surfaced to the user in the UI.

**Stated why.**

- **Metadata may change without changing a series' identity.** beorn7 (Prometheus team member), arguing against storing metadata in the block index:

  Source: https://github.com/prometheus/prometheus/issues/12608#issuecomment-1821181884 (quoted as prometheus-55)

  > However, metadata can change over time, which (currently) doesn't change the series identity.

- **Two targets may disagree, and both cases should work.** bboreham (member), answering cstyan (member), 2025:

  Source: https://github.com/prometheus/prometheus/issues/15911#issuecomment-2636463804 (quoted as prometheus-59)

  > * Because multiple replicas of the same target are mid-way through a software update which changed the metric, e.g. improved the help message.
  > * Because two unrelated programs picked the same metric name.
  >
  > IMO we should make both of these work.

  cstyan, just before:

  Source: https://github.com/prometheus/prometheus/issues/15911#issuecomment-2634809030 (quoted as prometheus-58)

  > The reason we switched from metadata per metric family to metadata per series ref is because it's possible for the same metric name but with different metadata to be scraped from two different targets.

- **Why identity grows to include type and unit**, from PROM-39's authors:

  Source: https://github.com/prometheus/proposals/blob/738d59014c53658753d21f8dc6253292654302b7/proposals/0039-metadata-labels.md (quoted as prometheus-68, prometheus-69, prometheus-70)

  > Significant increase of the cases for series with the same metric name but different unit and type.

  > Simply removing suffixes might result in "collisions" between distinct OpenTelemetry metrics which have the same name, but different types (less commonly) or units.

  > **This essentially extends metric family identity from just metric name to also unit and type**.

- **Why there is no central schema of metric definitions: no stated rationale found.** Looked in `data_model.md`, `writing_clientlibs.md`, `exposition_formats.md`, the OpenMetrics 1.0 and 2.0 specifications, the proposals listing, and issues #12608, #15911 and #17619. The nearest statements are beorn7's "We cannot prevent that from happening globally" (C1) and bboreham's "we should make both of these work" (above). bwplotka (maintainer) has floated a schema label as an idea, not a proposal:

  Source: https://github.com/prometheus/prometheus/issues/15911#issuecomment-2633125006 (quoted as prometheus-57)

  > The idea is to have another label `__schema__` which points to link on some git registry with exact version of metric with not only help, but also exact structured definition, and name/fields in the previous and future versions.

**Constraints.** A pull model in which the server labels each target. A time-series database whose identity is name and labels. Metadata treated as a hint that may change over a series' life.

**Costs and dissent.**

- **Keeping metadata per series costs memory.** bwplotka (maintainer):

  Source: https://github.com/prometheus/prometheus/issues/15911 (quoted as prometheus-56)

  > Some increase is expected as this literally adds a metadata record with 3 strings into WAL for every time series Prometheus ingests

- **The project now moves type and unit into identity**, because names alone collide, particularly for metrics arriving from OpenTelemetry (PROM-39, above). Its non-goal keeps one process to one definition per name:

  Source: https://github.com/prometheus/proposals/blob/738d59014c53658753d21f8dc6253292654302b7/proposals/0039-metadata-labels.md#L58 (quoted as prometheus-72)

  > * Allow mixing metrics with the same name, but different type or unit in the exposition format.

- OpenMetrics 2.0, at status "Experimental", names the risk of names alone:

  Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/specs/om/open_metrics_spec_2_0.md#L1238 (quoted as prometheus-67)

  > OpenMetrics allows these metrics to be exposed, but without the conventions and suffixes recommended here there is an increased risk of collisions and incompatibilities along the chain of services in a metrics system.

**Fit.** In the table under "Fit".

### C3. Prometheus Pushgateway: the member of the family that refuses

**What it does.** Read at `prometheus/pushgateway` `v1.11.4`. By default the Pushgateway refuses, at push time, a push whose metric conflicts with what another group pushed: the same name must have the same type across groups, and no series may repeat. It keeps conflicting help strings and picks one. The flag `--push.disable-consistency-check` turns the check at push time off. An inconsistent push is then accepted with status 202, and the same check at each scrape fails every scrape until the inconsistent metrics are deleted (author-8, below).

Source: https://github.com/prometheus/pushgateway/blob/v1.11.4/README.md (quoted as prometheus-75, prometheus-76)

> Pushes that would lead to inconsistencies are rejected with status
> code 400.

> Inconsistent help strings are tolerated, though. The Pushgateway will pick a
> winning help string and log about it at info level.

One bad push already stored can block later pushes:

Source: https://github.com/prometheus/pushgateway/blob/v1.11.4/README.md#L391-L393 (quoted as prometheus-80)

> In rare cases, it is possible that the Pushgateway ends up with an inconsistent
> set of metrics already pushed. In that case, new pushes are also rejected as
> inconsistent even if the culprit is metrics that were pushed earlier.

**Stated why.** Everything pushed is exposed on one `/metrics` endpoint, so the rules of one exposition apply across pushers:

Source: https://github.com/prometheus/pushgateway/blob/v1.11.4/README.md (quoted as prometheus-81, prometheus-74)

> The Pushgateway exposes all pushed metrics together with its own metrics via
> the same `/metrics` endpoint.

> Therefore, all the metrics have to be
> consistent with each other: Metrics of the same name must have
> the same type, even if they are pushed to different groups

Why the check runs at push time by default: it costs little, and without it a single inconsistent push fails every scrape.

Source: https://github.com/prometheus/pushgateway/blob/v1.11.4/README.md#L211-L221 (quoted as author-8)

> The consistency check performed during a push is the same as it happens anyway
> during a scrape. In common use cases, scrapes happen more often than
> pushes. Therefore, the performance cost of the push-time check isn't
> relevant. However, if a large amount of metrics on the Pushgateway is combined
> with frequent pushes, the push duration might become prohibitively long. In
> this case, you might consider using the command line flag
> `--push.disable-consistency-check`, which saves the cost of the consistency
> check during a push but allows pushing inconsistent metrics. The check will
> still happen during a scrape, thereby failing all scrapes for as long as
> inconsistent metrics are stored on the Pushgateway. Setting the flag therefore
> puts you at risk to disable the Pushgateway by a single inconsistent push.

**Constraints.** A single service that re-exposes data from many short-lived pushers on one endpoint, which the server then scrapes as one target.

**Costs and dissent.** Version drift is the README's own example of a help conflict:

Source: https://github.com/prometheus/pushgateway/blob/v1.11.4/README.md#L204-L205 (quoted as prometheus-77)

> The help string of Pushgateway's own `push_time_seconds` metric
> has changed in v0.10.0.

The check costs time on large gateways, as the passage quoted above (author-8) says.

**Fit.** In the table under "Fit".

### C4. OpenTelemetry metrics: identity, the single writer and duplicate registration

**What it does.** Read at `opentelemetry-specification` `v1.63.0`, and the SDKs at Go `v1.47.0`, Python `v1.45.2` and Java `v1.68.0`.

- **A metric is identified by its Resource, its instrumentation Scope and its name.** Type, unit and the other intrinsic properties also identify it; the description does not. Inferred from that definition: two processes with different Resource attributes produce different identities, so a different definition from another process is not a conflict in OTLP at all.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md (quoted as otel-1)

  > Metric streams are grouped into individual `Metric` objects,
  > identified by:
  >
  > - The originating `Resource` attributes
  > - The instrumentation `Scope` (e.g., instrumentation library name, version)
  > - The metric stream's `name`

- **Two definitions for one name, in one Resource and Scope, are a "semantic error".** A producer may remediate some conflicts: it should choose the longer description, and it may convert disagreeing units or temporality. Otherwise it should inform the user and pass the conflicting data through. A consumer may reject such data. The specification does not say how a rejection reaches the user.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md (quoted as otel-2, otel-3, otel-4, otel-5)

  > Producers SHOULD prevent the presence of multiple `Metric` identities
  > for a given `name` with the same `Resource` and `Scope` attributes.
  > Producers are expected to aggregate data for identical `Metric`
  > objects as a basic feature, so the appearance of multiple `Metric`,
  > considered a "semantic error", generally requires duplicate
  > conflicting instrument registration to have occurred somewhere.

  > 4. Generally, for potential conflicts involving an identifying
  >    property (i.e., all properties except `description`), the producer
  >    SHOULD inform the user of a semantic error and pass through
  >    conflicting data.

  > Consumers MAY reject OpenTelemetry Metrics data containing semantic
  > errors (i.e., more than one `Metric` identity for a given `name`,
  > `Resource`, and `Scope`).

  > OpenTelemetry does not specify any means for conveying such an outcome
  > to the end user, although this subject deserves attention.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md#L325-L330 (quoted as author-9)

  > 1. If the potential conflict involves a non-identifying property (i.e.,
  >    `description`), the producer SHOULD choose the longer string.
  > 2. If the potential conflict involves similar but disagreeing units
  >    (e.g., "ms" and "s"), an implementation MAY convert units to avoid
  >    semantic errors; otherwise an implementation SHOULD inform the user
  >    of a semantic error and pass through conflicting data.

- **Two processes writing one stream break the single-writer principle**, which the specification treats as misconfiguration, not a semantic error. Receivers should deduplicate.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md (quoted as otel-6, otel-7, otel-9)

  > All metric data streams within OTLP MUST have one logical writer.  This means,
  > conceptually, that any Timeseries created from the Protocol MUST have one
  > originating source of truth.

  > Multiple writers for a metric stream is considered an error state, or
  > misbehaving system. Receivers SHOULD presume a single writer was intended and
  > eliminate overlap / deduplicate.

  > Note that violations of the Single-Writer principle are not semantic
  > errors, generally they result from misconfiguration.

- **A duplicate registration returns a working instrument**, which must export data even if that causes a semantic error. The rest is recommended, not required: the SDK SHOULD warn unless a View corrects the conflict, and what the warning SHOULD say depends on the conflict. A description set through a View SHOULD avoid the warning. A conflict that a View selector can tell apart SHOULD get a renaming View recipe in the warning. Otherwise, as with differing units, the SDK SHOULD report both `Metric` objects with a generic warning. SDKs differ in how far they follow it (below).

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md (quoted as otel-16, otel-17)

  > Whenever this occurs, users still need to be able to make measurements with the
  > duplicate instrument. This means that the Meter MUST return a functional
  > instrument that can be expected to export data even if this will cause
  > [semantic error in the data
  > model]

  > Additionally, users need to be informed about this error. Therefore, when a
  > duplicate instrument registration occurs, and it is not corrected with a View,
  > a warning SHOULD be emitted. The emitted warning SHOULD include information for
  > the user on how to resolve the conflict, if possible.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md#L1021-L1026 (quoted as author-10)

  > 1. If the potential conflict involves multiple `description`
  >    properties, setting the `description` through a configured View
  >    SHOULD avoid the warning.
  > 2. If the potential conflict involves instruments that can be distinguished by
  >    a supported View selector (e.g. name, instrument kind) a renaming View
  >    recipe SHOULD be included in the warning.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md (quoted as otel-18)

  > 3. Otherwise (e.g., use of multiple units), the SDK SHOULD pass through the
  >    data by reporting both `Metric` objects and emit a generic warning
  >    describing the duplicate instrument registration.

- **The rule was reversed in 2022.** Before pull request #2317 the API specification required an error. From `api.md` at the parent commit of that change:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/9a0a3300c6269c2837a1d7c9c5232ec816f63222/specification/metrics/api.md (quoted as otel-21)

  > * Meter implementations MUST return an error when multiple Instruments are
  >   registered under the same Meter instance using the same name.

- **Implementations differ in detail.** The Go SDK logs "duplicate metric stream definitions" and exports both. Java keeps both and warns:

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk/metrics/src/main/java/io/opentelemetry/sdk/metrics/internal/state/MetricStorageRegistry.java (quoted as otel-74, otel-111)

  > If a metric with the same
  >    * name (case-insensitive) but incompatible {@link MetricDescriptor} was previously registered,
  >    * logs a diagnostic warning and returns the {@code newStorage}.

  > Each descriptor in the registry results in an exported metric stream.

  In January 2022, jack-berg (member) described Java as dropping the conflicting values; v1.68.0 exports both:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1012321692 (quoted as otel-33)

  > If you register an instrument that is in conflict with a previously registered instrument, we log a warning, and values recorded to the instrument are dropped.

  The Python SDK keys instruments on name, type, unit and description, so distinct definitions become separate instruments. Its View-aware warning is still marked `FIXME` in the code.

**Stated why.** From issue #2226, "Meter and instrument identity", which pull request #2317 resolved, and from the error-handling principle.

- **Instruments are created throughout a program's life, so an error would be a crash at run time.** jack-berg (member):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1023846383 (quoted as otel-22)

  > It's common to ask for the same meter multiple times, and for the same instrument from that meter multiple times. Requiring that the API return an error in this situation reduces API usability, forcing users to think carefully about instrument initialization ordering details and requiring clunky code for correctness.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1025974112 (quoted as otel-25)

  > Truly erroring when these situations occur would be an especially bad experience for apps which create new instruments throughout the app's lifecycle. E.g. the app is running fine for days but at some point the conditions are met for the creation of a new instrument and the app crashes - yikes.

  The remedy jack-berg proposed in that comment was a no-op instrument and a logged error; pull request #2317 instead required a functional instrument (otel-16).

- **Shared instrumentation cannot guarantee one registration per name, and in one contributor's experience a strict check was switched off almost everywhere.** anuraaga (contributor), from one internal framework:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1023854851 (quoted as otel-23, otel-24)

  > But it's mostly impossible to ensure that the same convention has an instrument instantiated only once, unless the instrumentation itself keeps some state to make sure to return the same instrument - this just pushes the spec non-compliance from the SDK into instrumentation.

  > Anecdotally, I've worked with an internal metrics framework that did prevent duplicate registration and had a flag to suppress the exception - almost every app enabled the flag.

- **Why a warning, not silence and not a failure.** jsuereth (contributor, author of the single-writer text):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1027009619 (quoted as otel-26)

  > This is the primary reason why we want this error message.   It's a sharp edge in our design.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1028226694 (quoted as otel-27)

  > By DEFAULT the API should *not fail* in this scenario.  The end user may belong to neither of the teams in conflict and jus wants to get their job done.

  jmacd (member, author of pull request #2317):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1027490180 (quoted as otel-29, otel-28)

  > Does this still deserve a warning? Yes, because it will generate errors for certain metric-type-aware vendors.

  > This is a compromise to make the SDK simpler and "pass along" the ambiguity

- **Why one participant preferred first seen for a description.** This is jack-berg's position in the discussion, not the rule the specification adopted: the data model at `v1.63.0` tells a producer to choose the longer description (author-9), and the SDK specification points to a View (author-10). jack-berg (member):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1029186579 (quoted as otel-34)

  > First one wins makes most sense to me because any other approach implies that a metric's description / unit is subject to being updated from one export to another, which feels wrong.

- **The pull request's own summary**, by jmacd:

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/2317 (quoted as otel-35, otel-36)

  > Permits duplicate instrument registration as a first-class feature

  > Specifies that consumers are permitted to reject such data.

- **Why a single writer.** jmacd (member), reviewing pull request #1574, which added the text:

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/1574#discussion_r609307846 (quoted as otel-37, otel-38)

  > We are trying to define a "single-writer" property so that we know when it is safe to re-aggregate data.

  > For these rules to work, we have to be sure that multiple processes cannot somehow write to the same stream, because that would mean they can overwrite each other.

- **Why OpenTelemetry does not decide which conflicting stream is right.** jsuereth (contributor), the author of pull request #1574, names a back end with a registered schema as the place that could:

  Source: https://github.com/open-telemetry/opentelemetry-specification/pull/1574#discussion_r612770263 (quoted as otel-39)

  > It's likely impossible for 'open telemetry' to know which is erroneous.  a backend that supports schema'd metrics could use the currently registered metric schema to determine which one is 'stale' and ingest the correct one, but the key here is this is an "error' scenario.

- **The project-wide principle**, from `error-handling.md`:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md (quoted as otel-40, otel-42, otel-43)

  > We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

  > 1. API methods MUST NOT throw unhandled exceptions when used incorrectly by end users.

  > 2. The API or SDK MAY _fail fast_ and cause the application to fail on initialization, e.g. because of a bad user config or environment, but MUST NOT cause the application to fail later at runtime, e.g. due to dynamic config settings received from the Collector.

  Inferred: once instruments may be created at any point, a registration error becomes a run-time failure, which this principle forbids. No single sentence in the specification ties the two together.

**Constraints.**

- OTLP is pushed, and Resource attributes are what tell writers apart.
- Instrumentation libraries register without coordinating with each other (otel-23).
- OpenTelemetry may be loaded by an agent the developer does not control:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md (quoted as otel-41)

  > OpenTelemetry may be enabled via platform extensibility mechanisms, or dynamically loaded at runtime.
  > This makes the use of the library non-obvious for end users, and may even be outside of the application developer's control.

- Back ends differ in whether they are type-aware (otel-29).

**Costs and dissent.**

- **A vendor back end keeps the first type and tells the sender.** jmacd (member), speaking for his employer Lightstep:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1027490180 (quoted as otel-30)

  > Speaking for my employer, for example, Lightstep will experience an error (*) if the sender writes a different type of metric stream than its type on the first arrival.

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1027491260 (quoted as otel-31)

  > So, we return gRPC or HTTP response trailers to tell the user about this sort of conflict and only the original-type metric stream will continue writing.

- **Users report the warning as noise.** On Java issue #4381, about the Micrometer shim, jack-berg (member):

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4381#issuecomment-1125463909 (quoted as otel-77)

  > Looks like its not too bad after all! Just noisy logs.

- **Users want every conflicting definition sent.** tylerlance (third party), Java issue #4510, and jack-berg's reply (June 2022):

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4510 (quoted as otel-75)

  > Ideally we would want all these metrics sent to the collector, not just potentially the first one that was instrumented.

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4510#issuecomment-1147716017 (quoted as otel-76)

  > Currently, all are sent to the collector. The warning you see is just a warning but both of the duplicate definitions are exported.

- **The Prometheus Go client chose otherwise**, as jmacd noted in the same thread:

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1028149506 (quoted as otel-32)

  > First, a Prometheus library (Golang) returns error if you try to register the same instrument name, regardless of identical instrument kind or not.

**Fit.** In the table under "Fit".

### C5. OpenTelemetry Collector: the Prometheus exporter

**What it does.** Read at `opentelemetry-collector-contrib` `v0.166.0`. The exporter merges metrics from many sources under one name for a Prometheus scrape. The specification requires it to drop a whole metric whose `TYPE` conflicts, and to keep the points when only `HELP` or `UNIT` conflicts:

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/compatibility/prometheus_and_openmetrics.md (quoted as otel-93)

> Exporters MUST drop entire metrics to prevent
> conflicting TYPE comments, but SHOULD NOT drop metric points as a result of
> conflicting UNIT or HELP comments.

The exporter keeps the first `TYPE` and `HELP` it sees for a name, for as long as that name stays in its cache. It drops a later metric of another type and logs an error. It logs a different description at Info and keeps the first. A name that no metric of the cached type updates for `metric_expiration`, by default five minutes, is deleted, and the next definition seen becomes the first (Inferred from `validateMetrics` and `cleanupMetricFamilies` in `collector.go`):

Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/exporter/prometheusexporter/README.md#L29 (quoted as author-11)

> `metric_expiration` (default = `5m`): defines how long metrics are exposed without updates

Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/exporter/prometheusexporter/collector.go (quoted as otel-95)

> "instrument type conflict, using existing type definition. instrument: %s, existing: %s, dropped: %s"

Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/exporter/prometheusexporter/collector.go (quoted as otel-96)

> "Instrument description conflict, using existing",

It serves the scrape with `ContinueOnError`:

Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/exporter/prometheusexporter/prometheus.go (quoted as otel-97)

> ErrorHandling:     promhttp.ContinueOnError,

**Stated why.** dashpole (contributor), author of specification pull request #2890 (2022):

Source: https://github.com/open-telemetry/opentelemetry-specification/pull/2890 (quoted as otel-94)

> For TYPE conflicts, some metric has to be dropped, as the data sent might not be valid (e.g. you can't send counter information with a histogram TYPE).

For a conflicting description, the exporter's fix in 2024 chose to keep the first and stop failing. kristinapathak (contributor), its author:

Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/pull/36356 (quoted as otel-102)

> Fixes bug where exporting fails due to different help messages for the same metric.  With this solution, the exporter will always export metrics of the same name with the first description it receives. This also rejects metrics whose types have changed.

**Constraints.** The OpenMetrics format allows one `HELP`, `TYPE` and `UNIT` per name in a scrape, as pull request #2890's description states. The exporter folds many sources, and so many processes, under one name.

**Costs and dissent.**

- **Before the 2024 fix, two sources with different help failed the whole scrape.** dashpole (contributor), relaying an Istio user's report:

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/28617 (quoted as otel-99, otel-100, otel-101)

  > The prometheus exporter fails to gather metrics if the description differs between two metrics with the same name.

  > With a prometheus receiver, scrape two endpoints with the same metric name, but different HELP (description).

  > The prometheus exporter fails incoming scrapes.

- **After the fix, a user cannot tell which sources clash.** pilhuhn (third party), issue #53060 (open):

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/53060 (quoted as otel-103)

  > Unfortunately a) this is not actionable as I don't see which 2 resources clash.

  dashpole (contributor), a code owner of the exporter, in reply:

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/53060#issuecomment-6839345286 (quoted as otel-104)

  > since `validateMetrics` runs on every scrape for each accumulated series and minor description differences across SDK versions are common.

- **A different failure, often confused with this one:** "was collected before with the same name and label values" is two sources producing the same series, not two definitions. Aneurysm9 (member, a code owner) explains where the `instance` label comes from:

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/24054#issuecomment-1631360762 (quoted as otel-105)

  > This is an important attribute used to uniquely identify timeseries in Prometheus.

**Fit.** In the table under "Fit".

---
## A declared version, validated downstream

### C6. Snowplow: self-describing events, SchemaVer and failed events

**What it does.** Documentation read live; Enrich source at `6.15.0`.

- **A self-describing event names its schema and version**, as an Iglu URI such as `iglu:com.acme/checkout/jsonschema/1-0-0`. Baked-in events, which are page views, page pings and structured events, carry no schema of their own. The entities attached to an event are schema-defined by default, and each names its own schema.

  Source: https://docs.snowplow.io/docs/fundamentals/events/ (quoted as author-12, author-13)

  > The baked-in event types are page views, page pings, and structured events

  > All Snowplow events are by default tracked with schema-defined entities attached to them.
- **Validation happens downstream**, in the Enrich application, not in the tracker. That trackers do not validate by default is Inferred: no tracker page fetched says so outright, the documentation places validation in Enrich, and the only client-side validation documented is opt-in generated code for the browser tracker. By default it logs a warning. A custom handler can throw, and the default handler throws when `NODE_ENV` is `test`. Inferred from the generated example, which validates before it calls the tracker: a throw stops the event before it reaches the tracker.

  Source: https://docs.snowplow.io/docs/fundamentals/ (quoted as author-1)

  > When an event fails to validate, it will feed into a bad data stream which contains all of your failed events. This way, the Snowplow pipeline is non-lossy as failed events can be reprocessed.

  Source: https://docs.snowplow.io/docs/event-studio/implement-tracking/client-side-validation/ (quoted as registries-25)

  > By default, violations are logged to the browser console using console.warn.

  Source: https://docs.snowplow.io/docs/event-studio/implement-tracking/client-side-validation/ (quoted as author-14)

  > When NODE_ENV is set to test, as many testing libraries do automatically, the default handler throws an Error instead of logging a warning.

- **An event that fails is kept apart, not loaded and not dropped.**

  Source: https://docs.snowplow.io/llms.txt (quoted as registries-15)

  > Events that fail validation become failed events; they are not dropped silently.

  Source: https://docs.snowplow.io/docs/fundamentals/failed-events/ (quoted as registries-19, registries-17)

  > Failed events are not written to your atomic events table, which only contains high quality data.

  > Validation failures. These errors occur when an event or an entity does not match its schema. The reason usually is incorrect tracking code.

- **A schema missing from the registry also yields a failed event**, not a refusal:

  Source: https://docs.snowplow.io/docs/fundamentals/failed-events/ (quoted as registries-18)

  > Validation can also fail if the schema is not available, such as when you forgot to add it to the production schema registry before putting the tracking code live.

- **An unreachable schema registry now crashes Enrich instead.** The trigger is a resolution "system error", which the code names RepoFailure or ClientFailure (server unavailability, connection issues). A schema that does not exist still yields a failed event, unless the lookup also failed outright: the resolver counts a system error when any custom repository returned only failures, or every Iglu Central mirror did, even if another repository answered that the schema was not found. That was read in iglu-scala-client `4.3.1`, the version Enrich `6.15.0` pins, from its Maven Central sources jar, because it has no public tag (author-88, author-89, below). The failed-events page still lists the outage as a cause of failed events; the current code and its commit say otherwise. The change was committed in December 2025 and released in Enrich 6.5.0 on 2026-01-09. Its stated reason is the code comment it adds (registries-29, below). The issue number it names, #157, resolves in the public repository to an unrelated issue of 2020.

  Source: https://docs.snowplow.io/docs/fundamentals/failed-events/ (quoted as registries-20)

  > Temporary infrastructure issue. This is again rare. One example would be Iglu Server (schema registry) not being available.

  Source: https://github.com/snowplow/enrich/blob/6.15.0/modules/common/src/main/scala/com.snowplowanalytics.snowplow.enrich/common/utils/IgluUtils.scala (quoted as registries-28, registries-29)

  > Error raised when Iglu Server is unreachable, causing the application to crash.

  > This prevents bad rows from being created due to infrastructure issues.

  Source: https://github.com/snowplow/enrich/commit/6c9f43eb691b5f5b71fb527f92e5dc251a1d9d29 (quoted as registries-30)

  > Crash on Iglu Server unavailability instead of creating bad rows (#157)

  Source: https://github.com/snowplow/enrich/blob/6.15.0/modules/common/src/main/scala/com.snowplowanalytics.snowplow.enrich/common/utils/IgluUtils.scala#L52-L54 (quoted as author-15)

  > Thrown when `Resolver.isSystemError` returns true, which happens when schema resolution
  >  * fails with RepoFailure or ClientFailure errors (server unavailability, connection issues)
  >  * rather than NotFound errors (schema genuinely doesn't exist).

  Source: https://github.com/snowplow/enrich/blob/6.15.0/CHANGELOG#L162-L169 (quoted as author-16)

  > 6.5.0 (2026-01-09)

  Source: https://repo1.maven.org/maven2/com/snowplowanalytics/iglu-scala-client_2.13/4.3.1/iglu-scala-client_2.13-4.3.1-sources.jar!/com.snowplowanalytics.iglu/client/resolver/Resolver.scala (quoted as author-88, author-89)

  > val customUnavailable = custom.values.exists(hasOnlyFatalErrors)

  > igluCentral.nonEmpty && igluCentral.values.forall(hasOnlyFatalErrors)

**Stated why.**

- **Why a declared version.** Alex Dean, Snowplow's co-founder, introducing SchemaVer (2014):

  Source: https://snowplow.io/blog/introducing-schemaver-for-semantic-versioning-of-schemas (quoted as registries-1, registries-2, registries-4)

  > As we start to re-structure Snowplow away from implicit data models and wiki-based tracker protocols towards formal schemas (initially Thrift and JSON Schema, later Apache Avro), we have started to think about schema versioning.

  > When versioning a data schema, we are concerned with the backwards-compatibility between the new schema and existing data represented in earlier versions of the schema.

  > On balance, this seemed a bad idea for SchemaVer: because inevitably some MODEL version 0s will go into production, and then we lose our all-important guarantees about the relationship between schema versions and the historical data.

- **Why the version travels with each payload.** Alex Dean, introducing self-describing JSON (2014):

  Source: https://snowplow.io/blog/introducing-self-describing-jsons (quoted as registries-5, registries-6, registries-7)

  > Combined, these knowledge gaps leave us in a tight spot: when we come back to a folder full of our JSONs, how will we know how to validate them?

  > We want the individual JSONs to record which JSON Schema they are associated with

  > This should make schema evolution and working with historical data much simpler.

- **Why bad data is kept rather than dropped.** Yali Sassoon, Snowplow's co-founder (2016):

  Source: https://snowplow.io/blog/what-is-bad-data (quoted as registries-8, registries-9, registries-10)

  > Every other analytics platform and data pipeline that we are aware of simply ‘drops’ the problematic data, resulting in missing data.

  > This is deeply problematic, because it becomes very hard to spot missing data: If you are relying on your analytics system to tell you what has happened and it fails to tell you about something, you have to be very fortunate to separately know that that thing occurred to identify that it is missing.

  > So with Snowplow, rather than drop events that fail to process, we load them into a separate “bad rows” folder in S3.

- **Why validate early in the pipeline.** Yali Sassoon, same post:

  Source: https://snowplow.io/blog/what-is-bad-data (quoted as registries-11)

  > More importantly when we think about bad data, it also means that Snowplow can validate that the data conforms to the schema right at the beginning of the pipeline, upstream of any data processing steps that would otherwise fail because the data has been malformed.

- **Why crash on a registry outage rather than write failed events.** The code comment the 2025 commit adds, quoted above: "This prevents bad rows from being created due to infrastructure issues." (registries-29). The commit gives no further reason.

- **Scope of these reasons.** Sassoon's reason is stated against dropping failed events, not against refusing them at the source. No source found states why the tracker does not refuse. The one stated reason against validating on the client in production is about bundle size:

  Source: https://docs.snowplow.io/docs/event-studio/implement-tracking/client-side-validation/ (quoted as registries-23, registries-24)

  > Because of the additional libraries required for client-side validation, using validation will increase your application bundle size.

  > For this reason, we recommend using validation only in development and test environments.

**Inferred why.** Inferred: trackers run in browsers, apps and servers Snowplow does not control. Validating in Enrich keeps every schema decision in one component with access to the registry; validating in the tracker would ship schemas and a validator to every client.

**Constraints.** Trackers send to a collector; Enrich validates and enriches; loaders write to warehouses. Loading depends on correct versions, and the documentation asks for each version to be treated as immutable:

Source: https://docs.snowplow.io/docs/fundamentals/schemas/versioning/ (quoted as registries-26)

> Aim to treat each schema version as immutable.

**Costs and dissent.**

- Snowplow's own documentation calls recovery hard:

  Source: https://docs.snowplow.io/docs/fundamentals/failed-events/ (quoted as registries-21)

  > This is a complicated process mainly reserved for internal failures and outages.

- A user's recovery job took about nine hours, and was then abandoned. Andre_Sionek (third party), on Snowplow's retired forum, read through the Wayback Machine:

  Source: https://web.archive.org/web/20240305034136/https://discourse.snowplow.io/t/unable-to-recover-bad-events-due-to-a-missing-schema/3968 (quoted as registries-31, registries-32)

  > We tried to recover events using the Hadoop Event Recovery, it took approximately 9 hours to run this job in EMR and move 10 days worth of bad records (~200Gb) to s3/recovered.

  > We canceled the execution and are kind of out of other alternatives.

**Fit.** In the table under "Fit".

### C7. OpenTelemetry schema URL

**What it does.** Read at `opentelemetry-specification` `v1.63.0`, collector-contrib `v0.166.0` and weaver `v0.28.0`.

- **A Resource or a Scope may carry a `schema_url`** naming a version of the semantic conventions. The schema file lists the transformations between versions, such as renames. A consumer may translate data to the version it expects.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0152-telemetry-schemas.md (quoted as otel-110)

  > - Telemetry schemas are identified by Schema URLs, that are unique for each
  >   schema version.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0152-telemetry-schemas.md (quoted as otel-81)

  > If necessary, telemetry consumers may transform the telemetry data
  >   from the received schema version to the target schema version

- **The schema does not describe the full shape of the data**, so there is nothing to validate against:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0152-telemetry-schemas.md (quoted as otel-82)

  > The schema for example does not define all
  >   possible valid values for attributes or expected data types for metrics, etc.
  >   It is not a goal.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/schemas/README.md (quoted as otel-84)

  > goal is narrowly defined to solve the following problem only: to allow
  >   OpenTelemetry Semantic Conventions to evolve over time.

- **Validation is named only as a future possibility**, in OTEP 0152, and as an aim in OTEP 4815, which no status line marks as adopted:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0152-telemetry-schemas.md (quoted as otel-83)

  > - Automatic validation that emitted telemetry confirms to the declared schema.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/4815-semantic-conventions-schema-v2.md (quoted as otel-85, otel-86)

  > Consumers of telemetry should be able to access the full schema to validate, upgrade,
  > or sanitize the telemetry.

  > has built the foundation for these scenarios, but does not fully support them.

- **The Collector's schema processor translates and does not validate.** It is alpha, in the contrib distribution only. Unmapped names pass through. A failure at the Scope level is logged and counted, and the data continues untranslated. A failure to fetch or apply the translation for a Resource is logged, counted and returned as an error, and the processor helper then passes none of that batch on. What the component upstream does with the error was not examined.

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/processor/schemaprocessor/README.md (quoted as otel-88, otel-89)

  > The _Schema Processor_ is used to convert existing telemetry data or signals to a version of the semantic convention defined as part of the configuration.

  > Unmapped names pass through unchanged.

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/processor/schemaprocessor/processor.go (quoted as otel-90)

  > t.log.Error("failed to apply scope metric changes", zap.Error(err))
  > 				failed++

  Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.166.0/processor/schemaprocessor/processor.go#L155-L159 (quoted as author-17)

  > t.log.Error("failed to apply resource changes", zap.Error(err))

  Source: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.166.0/processor/processorhelper/metrics.go#L62-L67 (quoted as author-18)

  > if errFunc != nil {

- **Weaver's live check validates sample telemetry against a registry it is given**, as a developer and CI tool, not as a stage of the ingest pipeline. No statement was found that it follows a sample's `schema_url`.

  Source: https://github.com/open-telemetry/weaver/blob/v0.28.0/crates/weaver_live_check/README.md (quoted as otel-91, otel-92)

  > Live check is a developer tool for assessing sample telemetry and providing findings for improvement.

  > OTLP live-check is particularly useful in CI/CD pipelines to evaluate the quality of instrumentation observed from all unit tests, integration tests and so on.

- **No OpenTelemetry component was found that quarantines data that fails a schema.** Looked in the specification's `schemas/` pages, OTEP 0152, OTEP 4815, the schema processor's README, design notes and `processor.go`, and the weaver live-check README.

**Stated why.** OTEP 0152, "Telemetry Schemas":

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0152-telemetry-schemas.md (quoted as otel-79, otel-80)

> This makes it difficult or impossible to change the composition of the emitted
> telemetry data without breaking the consumers.

> We believe that the 3 parties described above should be able to evolve
> independently over time, while continuously retaining the ability to correctly
> work together.

**Constraints.** Semantic conventions, the sources of telemetry and its consumers are owned by different parties and change independently (otel-79, otel-80). The schema records changes between versions, not a full definition (otel-82).

**Costs and dissent.** OTEP 4815 says the existing schemas do not yet support validation (otel-86). No user reports were looked for.

**Fit.** In the table under "Fit".

---

## Blocking the producer

### C8. Confluent Schema Registry

**What it does.** Read at `confluentinc/schema-registry` `v8.4.1` and Apache Kafka `4.4.0`; Confluent documentation read live. There are three points of enforcement.

- **The serializer registers a schema on first use, by default.**

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/schema-serializer/src/main/java/io/confluent/kafka/serializers/AbstractKafkaSchemaSerDeConfig.java (quoted as registries-34)

  > public static final boolean AUTO_REGISTER_SCHEMAS_DEFAULT = true;

- **The registry checks compatibility on registration, and answers an incompatible schema with 409.**

  Source: https://docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html (quoted as registries-46)

  > When a schema is updated, Schema Registry checks compatibility before accepting the new version.

  Source: https://docs.confluent.io/platform/current/schema-registry/develop/api.html (quoted as registries-44)

  > 409 Conflict – Incompatible schema

- **The producer's `send` then throws.** The serializer turns a 409 into a `SerializationException`, which `KafkaProducer.send` declares. That is read from the code; no end-to-end run was made.

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/schema-serializer/src/main/java/io/confluent/kafka/serializers/AbstractKafkaSchemaSerDe.java (quoted as registries-41)

  >       return new SerializationException(errorMessage, e);

  Source: https://github.com/apache/kafka/blob/4.4.0/clients/src/main/java/org/apache/kafka/clients/producer/KafkaProducer.java (quoted as registries-43)

  > @throws SerializationException If the key or value are not valid objects given the configured serializers

- **The client caches in memory, so the registry is needed on a cache miss, not on every message.** A miss is a schema's first use under a subject by a registry client, or a use after the bounded cache has evicted it. Each serializer builds its own client unless one is passed in, and the cache holds by default 1000 schemas per subject.

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/CachedSchemaRegistryClient.java (quoted as registries-42)

  > RegisterSchemaResponse cachedResponse = schemaResponseMap.getIfPresent(cacheKey);

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/CachedSchemaRegistryClient.java#L585-L588 (quoted as author-19)

  > schemaToResponseCache.get(subject, () -> CacheBuilder.newBuilder()

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/schema-serializer/src/main/java/io/confluent/kafka/serializers/AbstractKafkaSchemaSerDeConfig.java#L84-L87 (quoted as author-20)

  > "Maximum number of schemas to create or cache locally.";

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/schema-serializer/src/main/java/io/confluent/kafka/serializers/AbstractKafkaSchemaSerDe.java#L206-L210 (quoted as author-21)

  > if (schemaRegistry == null) {

  junrao (Jun Rao, contributor, with pull requests merged in the registry in 2015), in issue #250:

  Source: https://github.com/confluentinc/schema-registry/issues/250 (quoted as registries-53)

  > Note that schema registry server is used rarely since the schema registry client does caching.

- **The registry has a single primary.** Reads, and schemas already registered, are served by other instances when the primary is down.

  Source: https://docs.confluent.io/platform/current/schema-registry/fundamentals/index.html (quoted as registries-48)

  > Schema Registry is designed to be distributed, with a single-primary architecture.

  Source: https://docs.confluent.io/platform/current/schema-registry/multidc.html (quoted as registries-50)

  > If the primary node goes down in a single datacenter Schema Registry deployment, the
  > remaining Schema Registry instances can continue to serve requests.

  Source: https://docs.confluent.io/platform/current/schema-registry/multidc.html (quoted as registries-51)

  > This includes GET requests on
  > existing IDs and POST requests on schemas already in the registry. These
  > instances can’t register new schemas.

- **Confluent Server can also validate at the broker, per topic and opt-in.** It checks only that a record carries a valid schema ID, not the data, and rejects a batch with an invalid record.

  Source: https://docs.confluent.io/platform/current/schema-registry/schema-validation.html (quoted as registries-75)

  > Schema ID Validation doesn’t inspect the data.

  Source: https://docs.confluent.io/platform/current/schema-registry/schema-validation.html (quoted as registries-76, registries-77, registries-78)

  > the broker rejects any message sent to my-topic-sv
  > without a valid value schema. The broker returns an error to the producer and
  > discards the message.

  > If a producer sends a batch and at least one message is invalid, the broker
  > discards the entire batch.

  > Value schema validation and key schema validation are independent. You can
  > enable either or both. Both default to false.

**Stated why.**

- **Why enforce schemas between producer and consumer.** Jay Kreps, Confluent's co-founder (2015):

  Source: https://www.confluent.io/blog/avro-kafka-data/ (quoted as registries-67, registries-68, registries-69)

  > However data streams are different; they are a broadcast channel. Unlike an application’s database, the writer of the data is, almost by definition, not the reader.

  > These compatibility breakages are often particularly painful when used with a system like Kafka because producers of events may not even know of all the consumers, so manually testing compatibility can quickly become impossible.

  > We’ve found most people who have implemented a large scale streaming platform without schemas controlling the correctness of data have lead to serious instability at scale.

- **Why a registry with serializers that register automatically.** Gwen Shapira, Confluent engineering manager (2015):

  Source: https://www.confluent.io/blog/schema-registry-kafka-stream-processing-yes-virginia-you-really-need-one/ (quoted as registries-64, registries-65)

  > Resilient data pipelines: Applications and stream processing pipelines that subscribe to a data stream should be confident that a producer upstream won’t send them data they can’t handle.

  > Schemas are automatically registered, so the whole process of pushing new schemas to production is seamless.

- **Why one primary.** junrao, in issue #250:

  Source: https://github.com/confluentinc/schema-registry/issues/250 (quoted as registries-52)

  > The easiest way to enforce this is to have a single master design---the master decides the ordering of the schemas registered in a subject and the ordering in which the registered schemas are written to the Kafka log. If we allow new schemas to be registered on more than one schema registry instance, non-compatible schemas can leak into the system.

- **Why gate the client at produce time, accepting the dependency.** ewencp (Ewen Cheslack-Postava, contributor, committing under a confluent.io address), in issue #250 (2016):

  Source: https://github.com/confluentinc/schema-registry/issues/250 (quoted as registries-54, registries-55, registries-56)

  > I get that requiring all clients to validate against the schema registry introduces a runtime requirement and potential source of failure, but is there a reason you're really motivated to remove that dependency?

  > In general, schema registry is not a highly-loaded system, has a good HA story, and isn't operationally complex.

  > The existing format was proven to work well in a large organization with gating on clients based on successfully registering/validating schemas.

- **Why add broker-side validation.** Guozhang Wang, Confluent engineer (2019):

  Source: https://www.confluent.io/blog/data-governance-with-schema-validation/ (quoted as registries-71, registries-72, registries-73)

  > However, these schemas are only enforced as “agreement” between the clients and are totally agnostic to brokers, which still see all messages as entirely untyped byte arrays.

  > It is important to enforce data governance policies in a single place. The best place is inside the event streaming platform itself, so that we don’t have to audit each client to make sure their application code has respected all the rules.

  > We need to watch out for potentially significant overhead, as we are required to validate schema on a message-by-message basis.

**Inferred why.** Inferred: the broker checks only the schema ID because, as Wang says, validating every message is costly (registries-73). The documentation does not give that as the reason.

**Constraints.** Kafka brokers treat records as bytes (registries-71). Many producers and consumers that cannot upgrade together share one stream, and a producer may not know its consumers (registries-67, registries-68). The history is LinkedIn's Avro practice, which ewencp calls "proven to work well in a large organization" (registries-56).

**Costs and dissent.**

- **A single primary across data centres.** bcotton (third party), opening issue #250, which is still open:

  Source: https://github.com/confluentinc/schema-registry/issues/250 (quoted as registries-57)

  > Reviewing the architecture of the schema-registry, specifically in a multi datacenter deployment where there can only be a single master node, leads to overly complex deployment architectures.

- **An application can go down with the registry.** mjsax (member), issue #928 (2018):

  Source: https://github.com/confluentinc/schema-registry/issues/928 (quoted as registries-59)

  > a Kafka Streams application using `AvroSerde` can go down if Schema Registry is not available.

  yzia2000 (third party), same issue (2022):

  Source: https://github.com/confluentinc/schema-registry/issues/928 (quoted as registries-60)

  > I see a lot of operation timeouts or network glitches in our cluster (atleast once in 2 weeks) with the schema-registry which could be resolved much easier with a retry solution and will not require our intervention.

  rayokota (member) closed the issue in 2024 with a pull request that adds retries to the client's REST calls:

  Source: https://github.com/confluentinc/schema-registry/issues/928 (quoted as registries-61)

  > Fixed by https://github.com/confluentinc/schema-registry/pull/3424

  Source: https://github.com/confluentinc/schema-registry/pull/3424 (quoted as author-72)

  > We implement exponential backoff with full jitter

  At `v8.4.1` the client retries a failed connection and the responses 408, 429, 500, 502, 503 and 504, three times by default. Before each retry it waits a random time drawn with full jitter, from one millisecond up to a ceiling that doubles with each attempt, from 1 second up to at most 20 seconds by default, so a later wait can be shorter than an earlier one. The retries run against one URL at a time, inside a loop that fails over to the next configured URL. Inferred: a short outage need no longer fail a send that misses the cache. Because the waits are random, no outage length is sure to pass, and an outage that outlasts the retries against every URL still fails the send.

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/SchemaRegistryClientConfig.java#L44-L48 (quoted as author-73)

  > public static final int MAX_RETRIES_DEFAULT = 3;

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/rest/RestService.java#L745-L748 (quoted as author-74)

  > boolean isClientErrorToIgnore =
  >         status == 408 || status == 429;
  >     boolean isServerErrorToIgnore =
  >         status == 500 || status == 502 || status == 503 || status == 504;

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/rest/RetryExecutor.java#L123-L131 (quoted as author-98, author-99)

  > return ceil == 0 ? Duration.ofMillis(0L) : Duration.ofMillis(random.nextInt(ceil) + 1L);

  > initialWaitMs.multipliedBy(1L << cappedRetries).toMillis(), maxWaitMs.toMillis());

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/SchemaRegistryClientConfig.java#L46-L48 (quoted as author-100, author-101)

  > public static final int RETRIES_WAIT_MS_DEFAULT = 1000;

  > public static final int RETRIES_MAX_WAIT_MS_DEFAULT = 20000;

  Source: https://github.com/confluentinc/schema-registry/blob/v8.4.1/client/src/main/java/io/confluent/kafka/schemaregistry/client/rest/RestService.java#L705-L709 (quoted as author-102, author-103)

  > for (int i = 0, n = baseUrls.size(); i < n; i++) {

  > return retryExecutor.retry(() -> sendHttpRequest(requestUrl,

**Fit.** In the table under "Fit".

### C9. Apache Pulsar: a schema registry inside the broker

**What it does.** Read at `apache/pulsar` `v5.0.1` and the documentation repository at commit `4b4a781`.

- **The broker checks a producer's schema when the producer is created**, and refuses the producer if the schema is incompatible, or new while automatic update is off. A message sent with a schema the producer has not used before is checked at send time (PIP-43, adopted in 2.5.0), and other messages are not. The client asks the broker to get or create the schema. If it is incompatible, that message's send fails with `IncompatibleSchemaException` and the message is dropped, while later messages continue. A replication producer instead pauses publishing, to keep order.

  Source: https://github.com/apache/pulsar/blob/v5.0.1/pip/pip-43.md (quoted as author-22)

  > To guarantee scenarios that send a message with a brand new schema, we also propose a new Command to get schema version, or create one if NOT present.

  Source: https://github.com/apache/pulsar/blob/v5.0.1/pulsar-client/src/main/java/org/apache/pulsar/client/impl/ProducerImpl.java (quoted as author-23, author-24)

  > op.sendComplete(new IncompatibleSchemaException(failedMsg));

  > this.pauseSendingToPreservePublishOrderOnSchemaRegFailure = conf.isReplProducer();

  Source: https://github.com/apache/pulsar-site/blob/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/schema-overview.md (quoted as registries-86)

  > If it's not allowed to be auto-updated, then the schema cannot be registered, and the broker rejects the producer.

  Source: https://github.com/apache/pulsar-site/blob/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/schema-overview.md (quoted as registries-84)

  > enforces the data type safety when a topic has a schema defined. As a result, producers/consumers are only allowed to connect if they are using a "compatible" schema.

  Source: https://github.com/apache/pulsar/blob/v5.0.1/pulsar-broker/src/main/java/org/apache/pulsar/broker/service/ServerCnx.java (quoted as registries-92)

  > protected void handleProducer(final CommandProducer cmdProducer) {

- **The schema is applied when data is read**; the broker checks schemas, not payloads:

  Source: https://github.com/apache/pulsar-site/blob/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/schema-overview.md (quoted as registries-83)

  > Pulsar messages are stored as unstructured byte arrays and the data structure (as known as schema) is applied to this data only when it's read.

- **There is no separate service**:

  Source: https://github.com/apache/pulsar-site/blob/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/schema-overview.md (quoted as registries-85)

  > stored in the existing storage layer BookKeeper, without additional system required.

- **A producer with no schema is accepted on a topic with one, by default.** `schemaValidationEnforced` refuses it, and is off:

  Source: https://github.com/apache/pulsar-site/blob/4b4a7815eb9bd2e9027e506828a437e4e870a691/docs/schema-understand.md (quoted as registries-89, registries-90)

  > By default, schema validation enforcement is only **disabled** (`isSchemaValidationEnforced`=`false`) for producers, which means:

  > A producer without a schema can produce any messages to a topic with schemas, which may result in producing trash data to the topic.

**Stated why.**

- **Why check in the server.** The Pulsar 2.4.0 documentation:

  Source: https://github.com/apache/pulsar/blob/v2.4.0/site2/docs/concepts-schema-registry.md (quoted as registries-80, registries-81, registries-82)

  > Type safety is extremely important in any application built around a message bus like Pulsar.

  > A "server-side" approach in which producers and consumers inform the system which data types can be transmitted via the topic. With this approach, the messaging system enforces type safety and ensures that producers and consumers remain synced.

  > Both approaches are available in Pulsar, and you're free to adopt one or the other or to mix and match on a per-topic basis.

- **Why enforcement against schema-less producers defaults to off.** sijie (Sijie Guo, member), author of pull request #2730 (2018):

  Source: https://github.com/apache/pulsar/pull/2730 (quoted as registries-94, registries-95)

  > We need an upgrade/backward compatibility story for schema enforcement.

  > otherwise, it will break all non-java producers on topics with schema immediately when upgrade to the new version

**Constraints.** The broker owns the topic and stores schemas in BookKeeper. A producer holds a long-lived connection, and its schema is negotiated when it is created. Clients that predate schemas had to keep working (registries-95).

**Costs and dissent.**

- rdhabalia (contributor), reviewing pull request #2730:

  Source: https://github.com/apache/pulsar/pull/2730 (quoted as registries-96)

  > but with this option, isn't a chance that producer without schema can inject incompatible data.

  sijie, in reply, planned to remove the flag. The current documentation still has it off (registries-89).

  Source: https://github.com/apache/pulsar/pull/2730 (quoted as registries-98)

  > yes, we should remove this flag after 2.3 or 2.4. before getting there, we also need to get a upgrade guide ready :)

- PIP-420 proposes decoupling schema validation from the broker:

  Source: https://github.com/apache/pulsar/blob/v5.0.1/pip/pip-420.md (quoted as registries-102, registries-103)

  > Apache Pulsar currently provides a built-in schema management system tightly coupled with the broker.

  > Pulsar brokers can be decoupled from schema storage and validation responsibilities.

**Fit.** In the table under "Fit".

### C10. AWS Glue Schema Registry and Apicurio Registry (brief)

**What it does.** Both refuse at the moment a schema is registered. With auto-registration on, which Glue's README says is off by default, registration happens in the producer's serializer, so a refusal can reach the producer while it serializes a record. AWS's guide says Glue's serializer throws for a record whose schema does not match a registered one, and the record is not sent. Apicurio's guide says that with auto-registration the registry applies its compatibility rules, and that "the SerDes" throws on incompatible versions, without saying which side; that a producer's send fails is Inferred. Neither path was traced in either system's code. Read at `aws-glue-schema-registry` `v3.0.1` and Apicurio Registry `3.3.5`, and AWS's developer guide read live.

Source: https://github.com/awslabs/aws-glue-schema-registry/blob/v3.0.1/README.md (quoted as registries-105, registries-106)

> For Schemas, Evolution check is performed while registering.

> Auto-Registration is disabled by default.

Source: https://github.com/awslabs/aws-glue-schema-registry/blob/v3.0.1/common/src/main/java/com/amazonaws/services/schemaregistry/common/AWSSchemaRegistryClient.java (quoted as registries-108)

> throw new AWSSchemaRegistryException(String.format("Schema evolution check failed. "

Source: https://github.com/Apicurio/apicurio-registry/blob/3.3.5/docs/modules/ROOT/pages/getting-started/assembly-intro-to-registry-rules.adoc (quoted as registries-109, registries-110)

> All configured global rules, group-specific rules, or artifact-specific rules must pass before a new artifact version can be added to {registry}.

> If not, {registry} reports the reason why in an HTTP error response.

Source: https://docs.aws.amazon.com/glue/latest/dg/schema-registry-works.html (quoted as author-52, author-53, author-51)

> When auto-registration is turned on in the serializer settings, automatic registration of the schema will be performed.

> If the schema exists but the serializer is using a new version that doesn’t exist, the Schema Registry will check the schema reference a compatibility rule to ensure the new version is compatible before registering it as a new version.

> If the schema of the record does not match a registered schema, the serializer will return an exception and the application will fail to deliver the record to the destination.

Source: https://github.com/Apicurio/apicurio-registry/blob/3.3.5/docs/modules/ROOT/pages/getting-started/assembly-schema-lifecycle-best-practices.adoc#L606 (quoted as author-54)

> when enabled, the serializer registers new schemas automatically, and {registry} applies the configured compatibility rules.

Source: https://github.com/Apicurio/apicurio-registry/blob/3.3.5/docs/modules/ROOT/pages/getting-started/assembly-schema-lifecycle-best-practices.adoc#L539 (quoted as author-55)

> If the schema versions are incompatible, the SerDes throws an exception.

The sentence before it, in the same paragraph, gives each side its part:

Source: https://github.com/Apicurio/apicurio-registry/blob/3.3.5/docs/modules/ROOT/pages/getting-started/assembly-schema-lifecycle-best-practices.adoc#L539 (quoted as author-104)

> The serializer resolves the schema from {registry}, and the deserializer verifies that the data matches the reader schema.

**Stated why.** For Glue, AWS's launch post, by Brian Likosar (a solutions architect at AWS) and Larry Heathcote (a product marketing manager at AWS), 2021-01-13:

Source: https://aws.amazon.com/blogs/big-data/validate-evolve-and-control-schemas-in-amazon-msk-and-amazon-kinesis-data-streams-with-aws-glue-schema-registry/ (quoted as author-56)

> If it isn’t, the data producer receives an exception from the serializer. This ensures that potentially breaking changes are found earlier in development cycles, and can also help prevent unintentional schema changes due to human error.

For Apicurio, no stated rationale was found for refusing at produce time. Its lifecycle guide gives a reason for checking before deployment instead:

Source: https://github.com/Apicurio/apicurio-registry/blob/3.3.5/docs/modules/ROOT/pages/getting-started/assembly-schema-lifecycle-best-practices.adoc#L540 (quoted as author-57)

> Pre-registration catches breaking changes during the build rather than at runtime.

Looked in the Glue README, client and developer guide, AWS's launch post, and Apicurio's documentation on rules, serializers and the schema lifecycle.

**Constraints, costs and dissent.** Not looked for beyond the files cited. Glue's client keeps a local cache, with a 24-hour default:

Source: https://github.com/awslabs/aws-glue-schema-registry/blob/v3.0.1/README.md (quoted as registries-104, registries-107)

> An inbuilt local in-memory cache to save calls to AWS Glue Schema Registry.

> // If not passed, defaults to 24 Hours

**Fit.** In the table under "Fit".

---
## Column ids

### C11. Apache Iceberg: field ids

**What it does.** Read at `apache-iceberg-1.12.0`. Every field has an integer id, unique in the table's schema, and readers select a data file's columns by id, not by name or position. Table metadata keeps `last-column-id`, so a new column always gets an unused id. A dropped column's values stay in old data files and become unreachable. A column added again under the same name gets a new id, so a data file written with field ids does not supply the old values for it: in such a file it reads as null or, from format v3, as the new field's initial default.

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md (quoted as ids-2, ids-3, ids-5, ids-6)

> Each field in the tuple is named and has an integer id that is unique in the table schema.

> Adding a new field assigns a new ID for that field and for any nested fields. Renaming an existing field must change the name, but not the field ID.

> Columns in Iceberg data files are selected by field id. The table schema's column names and order may change after a data file is written, and projection must be done using field ids.

> An integer; the highest assigned column ID for the table. This is used to ensure columns are always assigned an unused ID when evolving schemas.

Reading and writing differ. On read, the value for an id a data file lacks is taken, in order: from partition metadata, for an identity partition; through the table's name mapping, for a file written without field ids; from the field's initial default, from format v3; and otherwise it is null.

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md#L402-L407 (quoted as author-64)

> * Return the value from partition metadata if an [Identity Transform](#partition-transforms) exists for the field and the partition value is present in the `partition` struct on `data_file` object in the manifest. This allows for metadata only migrations of Hive tables.
> * Use `schema.name-mapping.default` metadata to map field id to columns without field id as described below and use the column if it is present.
> * Return the default value if it has a defined `initial-default` (See [Default values](#default-values) section for more details).
> * Return `null` in all other cases.

On write, format v3 forbids omitting a known field: the writer fills in the field's write default, and if a required field has none, the writer must fail. What earlier format versions require of a writer was not checked.

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md#L333 (quoted as author-25)

> Omitting a known field when writing a data file is never allowed. The write default for a field must be written if a field is not supplied to a write. If the write default for a required field is not set, the writer must fail.

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md#L1920 (quoted as author-26)

> Default values are added to struct fields in v3.

**The rule is stated, though not in the words "never reused".** The specification at `apache-iceberg-1.12.0` was searched for `reuse`, `re-use`, `never`, `unique`, `last-column-id` and `field id`. The phrase "never reused" does not appear. The rule does: `last-column-id` exists "to ensure columns are always assigned an unused ID when evolving schemas" (ids-6), and "Adding a new field assigns a new ID" (ids-3). The documentation page on evolution gives the purpose (ids-12, below). The sentence of ids-6 is already in the specification of the `0.7.0-incubating` release, tagged on 2019-10-25, and in `apache/iceberg` from the commit of 2019-06-23 that moved the specification to the project's site (`601de88`), so it was written no later than that:

Source: https://github.com/apache/iceberg/blob/apache-iceberg-0.7.0-incubating/site/docs/spec.md#L354 (quoted as author-61)

> An integer; the highest assigned column ID for the table. This is used to ensure columns are always assigned an unused ID when evolving schemas.

**Which changes the ids were written to survive.** The specification's goals name add, drop, reorder and rename:

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md (quoted as ids-1)

> Evolution** -- Tables will support full schema and partition spec evolution. Schema evolution supports safe column add, drop, reorder and rename, including in nested structures.

The earliest dated source, the README of the first public release in Netflix's repository, by rdblue (Ryan Blue), 2017-12-13:

Source: https://github.com/Netflix/iceberg/blob/a5eb3f6ba171ecfc517a4f09ae9654e7d8ae0291/README.md (quoted as ids-16)

> **Schema evolution**: Columns are tracked by ID to support add/drop/rename.

The code at the same commit gives a new column the id after the table's last assigned one, and commits that counter with the new schema:

Source: https://github.com/Netflix/iceberg/blob/a5eb3f6ba171ecfc517a4f09ae9654e7d8ae0291/core/src/main/java/com/netflix/iceberg/SchemaUpdate.java#L175-L184 (quoted as author-59, author-60)

> TableMetadata update = base.updateSchema(apply(), lastColumnId);

> int next = lastColumnId + 1;
>     this.lastColumnId = next;

Type widening is supported. An author ties it to the ids in 2021, four years after the first release, which makes this a later explanation and not a statement of the original design's goals. rdblue (Ryan Blue), on Iceberg's development list, 2021-05-18:

Source: https://www.mail-archive.com/dev@iceberg.apache.org/msg02227.html (quoted as author-62, author-63)

> From the IDs, you can see that field 1 was
> renamed and promoted to long, field 2 was deleted, and field 3 was added
> with field 2's original name.

> Casting or promoting data is done by strict rules in Iceberg. This is
> affected by ID because we know that a field is the same across files, like
> in my example above.

**Stated why.** The documentation page on evolution, first committed by rdblue on 2019-06-26 and unchanged in substance at `1.12.0`:

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/docs/docs/evolution.md (quoted as ids-10, ids-11, ids-12, ids-13)

> Iceberg guarantees that **schema evolution changes are independent and free of side-effects**, without rewriting files:

> 1. Added columns never read existing values from another column.
> 2. Dropping a column or field does not change the values in any other column.

> Iceberg uses unique IDs to track each column in a table. When you add a column, it is assigned a new ID so existing data is never used by mistake.

> * Formats that track columns by name can inadvertently un-delete a column if a name is reused, which violates #1.
> * Formats that track columns by position cannot delete columns without changing the names that are used for each column, which violates #2.

And on Hive, which tracks columns by name or position:

Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/docs/docs/evolution.md (quoted as ids-14)

> In some cases, even changes as simple as renaming a column are either not supported, or can cause [data correctness](#correctness) problems.

So the stated reason ties ids to adding a column (tracking by name can bring a deleted column back if its name is reused) and to dropping one (tracking by position shifts the others). Rename and reorder follow from projecting by id.

**Inferred why.** The purpose of a new id is stated (ids-12: "so existing data is never used by mistake"). Inferred: a reused id would let a new column read an old column's values, the same failure the documentation describes for reused names.

**Constraints.** Data files are immutable and written by many engines. A schema change must be a change to metadata, with no rewrite. Readers plan scans with no central service.

**Costs and dissent.**

- **A dropped column cannot be re-added under its original id** through the public interface; adding it again assigns a new id, so its old values are not read under it. The specification limits rolling a deletion back:

  Source: https://github.com/apache/iceberg/blob/apache-iceberg-1.12.0/format/spec.md (quoted as ids-4)

  > Field deletion cannot be rolled back unless the field was nullable or if the current snapshot has not changed.

  zhongyujiang (contributor), issue #14426:

  Source: https://github.com/apache/iceberg/issues/14426 (quoted as ids-19)

  > Users might accidentally delete a column, after which the column data cannot be recovered, except by reading from an old snapshot via time travel. However, the column cannot be re-added to the table's current schema since iceberg uses unique IDs to track columns.

  Fokko (contributor), in reply:

  Source: https://github.com/apache/iceberg/issues/14426 (quoted as ids-20)

  > Just reverting the current-schema-id to the previous value should restore the data.

- **A sink matched input against a historical schema and silently wrote nulls**, after a column was dropped and added again. The report does not say whether the sink matched by name or which ids were written. aboueleyes (third party), issue #17773 (open):

  Source: https://github.com/apache/iceberg/issues/17773 (quoted as ids-22)

  > at least one real corruption case where the Flink dynamic sink matched input against a historical schema and silently wrote nulls after a delete-plus-re-add cycle.

**Fit.** In the table under "Fit".

### C12. Protocol Buffers: field numbers and `reserved`

**What it does.** Documentation read at commit `7712b0c` of `protocolbuffers.github.io`. The wire format identifies a field only by its number. The `reserved` statement makes the compiler reject reuse of a deleted field's number or name. Nothing checks at run time that writer and reader agree: a number reused with another meaning is decoded under the reader's definition, and the guide lists the outcomes as a parse or merge error at best, leaked personal data, or corrupted data (ids-28).

Source: https://github.com/protocolbuffers/protocolbuffers.github.io/blob/7712b0c36f911534ef07b755900aa142efc39b9f/content/programming-guides/proto3.md (quoted as ids-24, ids-25)

> This number **cannot be changed once your message type is in use** because it
> identifies the field in the
> [message wire format](/programming-guides/encoding).

> Field numbers **should never be reused**. Never take a field number out of the
> [reserved](#fieldreserved) list for reuse with a new field definition.

Source: https://github.com/protocolbuffers/protocolbuffers.github.io/blob/7712b0c36f911534ef07b755900aa142efc39b9f/content/programming-guides/proto3.md (quoted as ids-29)

> However, you
> **must** [reserve the deleted field number](#fieldreserved). If you do not
> reserve the field number, it is possible for a developer to reuse that number in
> the future.

Source: https://github.com/protocolbuffers/protocolbuffers.github.io/blob/7712b0c36f911534ef07b755900aa142efc39b9f/content/programming-guides/proto3.md#L303-L307 (quoted as author-27)

> Reserved names affect only the protoc compiler behavior and not runtime
> behavior, with one exception: TextProto implementations may discard unknown
> fields (without raising an error like with other unknown fields) with reserved
> names at parse time (only the C++ and Go implementations do so today). Runtime
> JSON parsing is not affected by reserved names.

**The literal rule is here.** "should never be reused" is the earliest literal never-reuse rule this survey found. Meta's fork of Thrift, fbthrift, states one too, publicly since 2022 (C13).

**Stated why.**

Source: https://github.com/protocolbuffers/protocolbuffers.github.io/blob/7712b0c36f911534ef07b755900aa142efc39b9f/content/programming-guides/proto3.md (quoted as ids-26, ids-27, ids-28)

> Reusing a field number makes decoding wire-format messages ambiguous.

> The Protobuf wire format is lean and doesn't provide a way to detect fields
> encoded using one definition and decoded using another.

> -   A parse/merge error (best case scenario)
> -   Leaked PII/SPII
> -   Data corruption

From the "Dos and Don'ts" page:

Source: https://github.com/protocolbuffers/protocolbuffers.github.io/blob/7712b0c36f911534ef07b755900aa142efc39b9f/content/best-practices/dos-donts.md (quoted as ids-31)

> Never re-use a tag number. It messes up deserialization. Even if you think no
> one is using the field, don’t re-use a tag number. If the change was live ever,
> there could be serialized versions of your proto in a log
> somewhere.

**History.** The earliest capture of the language guide found, in the Wayback Machine on 2008-07-11, shortly after the public release, already has the rule in another form. The capture date is not the publication date.

Source: http://web.archive.org/web/20080711025823/http://code.google.com:80/apis/protocolbuffers/docs/proto.html (quoted as ids-33)

> Non-required fields can be removed, as long as the tag number is not used again in your updated message type (it may be better to rename the field instead, perhaps adding the prefix "OBSOLETE_", so that future users of your .proto can't accidentally reuse the number).

The `reserved` keyword arrived in 3.0.0-alpha-3, on 2015-05-25:

Source: https://github.com/protocolbuffers/protobuf/blob/v3.0.0/CHANGES.txt (quoted as ids-34)

> Added a "reserved" keyword in both proto2 and proto3 syntax. User can use
>     this keyword to declare reserved field numbers and names to prevent them
>     from being reused by other fields in the same message.

**Constraints.** A compact wire format that carries no schema, and messages written under old definitions that persist in logs and old servers (ids-31).

**Costs and dissent.** Protection is advisory and works at compile time: protoc rejects a reserved number or name. At run time, reserved names have one effect, only in TextProto parsing in C++ and Go, which may discard a field with a reserved name (author-27). No run-time effect of reserved numbers is stated. Before 2015 the only guard was a naming convention, prefixing a retired field with `OBSOLETE_` (ids-33). User reports were not looked for.

**Fit.** In the table under "Fit".

### C13. Apache Thrift field ids and Parquet `field_id` (brief)

**Thrift.** Each struct field carries an id, and readers skip an unknown id by its type. There is no `reserved` keyword in the IDL at `v0.25.0`, and no rule against reusing a removed field's id was found in the 2007 paper or the IDL specification. The paper, by Slee, Agarwal and Kwiatkowski of Facebook, gives the reason for ids:

Source: https://thrift.apache.org/static/files/thrift-20070401.pdf (quoted as ids-35, ids-36, ids-37, ids-38)

> Thrift is robust in the face of versioning and data deﬁnition
> changes. This is critical to enable staged rollouts of changes to
> deployed services.

> The system must be able to support reading of
> old data from log ﬁles, as well as requests from out-of-date clients
> to new servers, and vice versa.

> Versioning in Thrift is implemented via ﬁeld identiﬁers.

> If a ﬁeld identiﬁer is not
> recognized, the generated code can use the type speciﬁer to skip
> the unknown ﬁeld without any error.

**fbthrift.** Meta's fork of Thrift states the rule its upstream does not. It has done so in its public documentation since 2022-12-07, when it first appeared with a link to an internal Meta wiki, so any earlier internal date cannot be checked. Read at `meta/fbthrift` commit `0767943`, and at `1b5eec9` for the first public version:

Source: https://github.com/meta/fbthrift/blob/076794349265d2a13820388d7d7715ba64285e4d/thrift/doc/idl/index.md#L525 (quoted as author-28)

> Do not reuse ids. If a field is removed, it's a good practice to comment it out as a reminder not to reuse it.

Source: https://github.com/meta/fbthrift/blob/1b5eec929fdb623f713356524cbd52e34f8acfd1/thrift/doc/spec/idl/index.md#L158 (quoted as author-29)

> **WARNING:** Do not reuse ids. If a field is removed from a struct, it's a good practice to comment it out as a reminder to not to reuse it

**Parquet.** `SchemaElement` has an optional `field_id`, added on 2014-03-04, and Parquet itself resolves nothing by it; table formats do. No stated rationale found beyond the field's own comment, and the format states no rule against reuse. Read at `apache-parquet-format-2.14.0`.

Source: https://github.com/apache/parquet-format/blob/apache-parquet-format-2.14.0/src/main/thrift/parquet.thrift (quoted as ids-41)

> /** When the original schema supports field ids, this will save the
>    * original field id in the parquet schema

**Fit.** In the table under "Fit".

### C14. Delta Lake column mapping

**What it does.** Read at `delta-io/delta` `v4.4.1`. Each column gets a physical name and an id separate from its display name. A table property tracks the largest id assigned, and must only increase. In `id` mode readers resolve columns by Parquet `field_id`, and a missing id reads as null.

Source: https://github.com/delta-io/delta/blob/v4.4.1/PROTOCOL.md (quoted as ids-48, ids-49, ids-50, ids-51)

> Delta can use column mapping to avoid any column naming restrictions, and to support the renaming and dropping of columns without having to rewrite all the data.

> In these modes, a physical field path must be unique across all versions of the table. This supports cheap column deletions in `name` mode.

> The maximum id that is assigned to a column is tracked as the table property `delta.columnMapping.maxColumnId`. This is an internal table property that cannot be configured by users. This value must increase monotonically as new columns are introduced and committed to the table alongside the introduction of the new columns to the schema.

> If a data file does not contain field ids, readers must refuse to read that file or return nulls for each column. For ids that cannot be found in a file, readers must return `null` values for those columns.

**No literal "never reused" rule.** The protocol states mechanisms: physical paths "unique across all versions of the table" and a maximum id that "must increase monotonically". They have the same effect, and no sentence forbids reuse.

**Stated why.** brkyvz (Burak Yavuz), in the commit that added column mapping (2021-09-29):

Source: https://github.com/delta-io/delta/commit/282fc689467a31938114e4e1e0d452e0bd6b0aaf (quoted as ids-52)

> Assign a globally unique identifier as the physical name for each new column that is added to the schema. This is especially important for supporting cheap column deletions in `name` mode.

liwensun (contributor), in tracking issue #958:

Source: https://github.com/delta-io/delta/issues/958 (quoted as ids-53)

> Delta currently doesn't support such an operation because Delta's column names are tied to the underlying column names in Parquet, so to rename a column, Delta would need to rewrite the underlying Parquet files to change the column names.

The design document, by Jackie Zhang, created 2022-02-04, after the first column-mapping commit of 2021-09-29, names Iceberg once, as a competitor that has these operations. It is the only statement by an author that the survey found connecting two of these systems, and it speaks of competition, not of deriving the design:

Source: https://docs.google.com/document/d/1NeqRyjdPwFWXDwoYgaMs69QRGyeW-2qdZ5Da7ywoRUo/edit (quoted as ids-54)

> Second, users can't perform certain schema evolution operations efficiently in Delta, such as RENAME COLUMN and DROP COLUMN, because there is no easy way to mark a column with the same name "deleted" in Parquet. These limitations give similar products like Apache Iceberg a major competitive advantage over Delta Lake.

**Constraints.** Delta's columns were tied to the column names in Parquet files, so a rename or drop meant rewriting them (ids-53).

**Costs and dissent.** Column mapping is opt-in. The column-mapping page calls turning it on irreversible:

Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-column-mapping.mdx (quoted as ids-56)

> This protocol upgrade is
>   irreversible.

The feature-removal page at the same tag lists column mapping as a feature that can be dropped from Delta Lake 3.3.0, rewriting data files where needed. The two pages disagree. The code at the same tag agrees with the feature-removal page: column mapping is declared a removable feature, with a command to run before the downgrade (author-105 to author-107, below).

Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-drop-feature.mdx#L31 (quoted as author-30)

> Drop support for column mapping is available in Delta Lake 3.3.0 and above.

Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-drop-feature.mdx#L44-L46 (quoted as author-31)

> Rewrite data files as necessary to remove all traces of the table feature from the data files backing the table in the current version.

Source: https://github.com/delta-io/delta/blob/v4.4.1/spark/src/main/scala/org/apache/spark/sql/delta/TableFeature.scala#L619-L654 (quoted as author-105, author-106, author-107)

> object ColumnMappingTableFeature

> with RemovableFeature

> ColumnMappingPreDowngradeCommand(table)

The physical name, not the id, is what makes a deletion cheap in `name` mode, where ids do not resolve columns:

Source: https://github.com/delta-io/delta/blob/v4.4.1/PROTOCOL.md#L1023 (quoted as author-108)

> Column ids are not used in this mode for resolution purposes.

**Fit.** In the table under "Fit".

### Where "column ids that are never reused" came from

The ticket asks which system the idea came from. The elicitation's record is not tracked in this repository, so where its sentence came from cannot be checked. What the sources show:

- **For message field numbers**, the earliest primary source found that states a non-reuse rule is the Protocol Buffers language guide, captured on 2008-07-11 (ids-33). Its current wording is "should never be reused" (ids-25), and `reserved` has enforced it at compile time since 2015 (ids-34). It is about message fields, not table columns.
- **Ids used for versioning without a reuse rule** came earlier or alongside: the Thrift paper of 2007 (ids-37) and Parquet's `field_id` in 2014. Meta's fork of Thrift states a never-reuse rule in public documentation from 2022 (C13).
- **Column ids in a table format**: Iceberg's first public release, 2017 (ids-16), and Delta's column mapping, 2021 (ids-52). Neither uses the words "never reused". Iceberg's specification states the rule as the purpose of its counter: columns are "always assigned an unused ID" (ids-6). The sentence was written no later than 2019-06-23 (author-61); when it was first written was not established. The code of the 2017 release already gives each new column the id after the table's last one (author-59, author-60). Delta's protocol states a counter that only increases (ids-50).
- **A connection stated by an author:** only Delta's design document, which names Iceberg as a competitor, not as a source (ids-54). No Iceberg source read names Protocol Buffers or Thrift. That Iceberg's ids descend from either is Inferred, from a shared mechanism.
- The sentence "The cheapest upgrade: a declared version or definition hash, and column ids that are never reused" was not found in any source. "Cheapest" is a claim no source makes. Its wording, "never reused", matches the Protocol Buffers documentation and not Iceberg's.

---

## Data that carries its own definition

The specification says each run's local databases "carry the definitions they were written with". These comparables store data with the definition it was written under.

### C15. Apache Avro: object container files

**What it does.** Read at Avro `release-1.12.2`. A container file's header must carry the writer's schema. A reader resolves the writer's schema against its own by field name: a field only the writer has is ignored, a field only the reader has takes its default, and a reader-only field with no default is an error.

Source: https://github.com/apache/avro/blob/release-1.12.2/doc/content/en/docs/%2B%2Bversion%2B%2B/Specification/_index.md (quoted as ids-59, ids-60, ids-61, ids-62)

> **avro.schema** contains the schema of objects stored in the file, as JSON data (required).

> A reader of Avro data, whether from an RPC or a file, can always parse that data because the original schema must be provided along with the data. However, the reader may be programmed to read data into a different schema.

> the ordering of fields may be different: fields are matched by name.

> if the reader's record schema has a field with no default value, and writer's schema does not have a field with the same name, an error is signalled.

Avro also specifies a single-object encoding, for one object stored on its own, which carries a fingerprint of the writer's schema instead of the schema. Its stated reason is a store that holds records written under several schemas. A reader must resolve the fingerprint to a schema, so a store of schemas is needed.

Source: https://github.com/apache/avro/blob/release-1.12.2/doc/content/en/docs/%2B%2Bversion%2B%2B/Specification/_index.md (quoted as author-35, author-36, author-37)

> In the period after a schema change this persistence system will contain records that have been written with different schemas. So the need arises to know which schema was used to write a record to support schema evolution correctly. In most cases the schema itself is too large to include in the message, so this binary wrapper format supports the use case more effectively.

> The 8-byte little-endian CRC-64-AVRO

> This check helps avoid expensive lookups that resolve the schema from a fingerprint, when the message is not an encoded Avro payload.

**Stated why.** The specification:

Source: https://github.com/apache/avro/blob/release-1.12.2/doc/content/en/docs/%2B%2Bversion%2B%2B/Specification/_index.md (quoted as ids-57, ids-58)

> Binary encoded Avro data does not include type information or field names. The benefit is that the serialized data is small, but as a result a schema must always be used in order to read Avro data correctly.

> Therefore, files or systems that store Avro data should always include the writer's schema for that data.

The documentation's overview:

Source: https://github.com/apache/avro/blob/release-1.12.2/doc/content/en/docs/%2B%2Bversion%2B%2B/_index.md (quoted as ids-64, ids-65)

> When Avro data is stored in a file, its schema is stored with it, so that files may be processed later by any program. If the program reading the data expects a different schema this can be easily resolved, since both schemas are present.

> No manually-assigned field IDs: When a schema changes, both the old and new schema are always present when processing data, so differences may be resolved symbolically, using field names.

Doug Cutting, Avro's author, proposing it on the Hadoop mailing list (2009):

Source: https://www.mail-archive.com/general@hadoop.apache.org/msg00152.html (quoted as ids-70, ids-71)

> With the schema in hand, you don't need to tag data with field numbers
> or types, since that's all there in the schema.

> Also, with the schema, resolving version differences is simplified.
> Developers don't need to assign field numbers, but can just use names.

Source: https://www.mail-archive.com/general@hadoop.apache.org/msg00160.html (quoted as ids-74)

> This is equivalent to
> Thrift and Protocol Buffer's support for schema evolution, but does not
> require manually assigning numeric field ids.

And on the Avro users' list (2009), including the case of many versions in one store:

Source: https://www.mail-archive.com/avro-user@hadoop.apache.org/msg00063.html (quoted as ids-77, ids-78)

> The best practice with Avro is to store the schema with serialized data,
> so that later, even if the schema in your application has changed, you
> can still read that data. Avro's data file stores the schema once per
> file.

> If you're, e.g.,
> potentially storing different versions of a record in a database, then
> you might consider annotating each entry with the hash of its schema

A sentence about Protocol Buffers and Thrift encoding names as numbers is sometimes credited to Cutting. It is Owen O'Malley's, in the same thread (msg00149).

**Constraints.** Hadoop data files are long-lived and read by dynamic languages and scripts, such as Pig, Hive and Python, without generated code:

Source: https://www.mail-archive.com/general@hadoop.apache.org/msg00146.html (quoted as ids-67)

> My ambition is for Avro to replace both Hadoop's RPC and to be
> used for most Hadoop data files, e.g., by Pig, Hive, etc.

**Costs and dissent.** Data cannot be read without its writer's schema (ids-57). A rename needs an alias, because matching is by name. Chad Walters argued for Thrift's field ids on the same thread; his role was not verified, so he is labelled a third party:

Source: https://www.mail-archive.com/general@hadoop.apache.org/msg00170.html (quoted as ids-75, ids-76)

> Anyone doing more than just that is doing something advanced
> that wouldn't be possible without the field IDs (like renaming a field).

> I also don't see why matching names is considered easier than matching
> numbers, which is essentially what the versioning semantics come down to in
> the end.

**Fit.** In the table under "Fit".

### C16. Parquet footers and SQLite's schema table (brief)

**Parquet.** Every file's footer carries that file's schema. No stated rationale found for embedding it, in the README or the Thrift definition at `apache-parquet-format-2.14.0`; only the footer's position has a stated reason (single-pass writing).

Source: https://github.com/apache/parquet-format/blob/apache-parquet-format-2.14.0/src/main/thrift/parquet.thrift (quoted as ids-42)

> /** Parquet schema for this file.  This schema contains metadata for all the columns.

Spark can merge the schemas of files that differ, and does not by default. Read at Spark `v4.3.0`:

Source: https://github.com/apache/spark/blob/v4.3.0/docs/sql-data-sources-parquet.md (quoted as ids-46, ids-47)

> In this way, users may end
> up with multiple Parquet files with different but mutually compatible schemas. The Parquet data
> source is now able to automatically detect this case and merge schemas of all these files.

> Since schema merging is a relatively expensive operation, and is not a necessity in most cases, we
> turned it off by default starting from 1.5.0.

**SQLite.** The database file holds its own schema in `sqlite_schema`. No stated rationale found for storing it in the file; the pages read argue for SQLite as an application file format, not for this.

Source: https://www.sqlite.org/schematab.html (quoted as ids-79)

> The sqlite_schema table contains one row for each table, index, view,
> and trigger (collectively "objects") in the schema

**Fit.** In the table under "Fit".

---
## Declaring late

Prometheus's clients are covered under C1: both register a metric whenever its code runs, and both refuse a second registration that conflicts.

### C17. OpenTelemetry: instruments created before the provider is set

**What it does.**

- **The specification asks only for a settable global provider**, and requires the no-op default to be usable as it is. At `v1.63.0` no normative text was found about instruments created before the provider is set; `metrics/api.md`, `metrics/sdk.md`, `library-guidelines.md` and `trace/api.md` were searched.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/api.md (quoted as otel-15)

  > Normally, the `MeterProvider` is expected to be accessed from a central place.
  > Thus, the API SHOULD provide a way to set/register and access a global default
  > `MeterProvider`.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/library-guidelines.md (quoted as otel-44)

  > It is important that values returned from this minimal implementation of API are valid and do not require the caller to perform extra checks (e.g. createSpan() method should not fail and should return a valid non-null Span object). The caller should not need to know and worry about the fact that minimal implementation is in effect.

- **Go and Python rewire early instruments.** Instruments created before the provider is set are recreated against it when it is set. Measurements made in between are lost: in Go, read in `internal/global/instruments.go`, where a measurement is forwarded only once a delegate is set.

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/metric.go (quoted as otel-50)

  > If this is called before a global MeterProvider is registered the returned
  > // Meter will be a No-op implementation of a Meter. When a global MeterProvider
  > // is registered for the first time, the returned Meter, and all the
  > // instruments it has created or will create, are recreated automatically from
  > // the new MeterProvider.

  Source: https://github.com/open-telemetry/opentelemetry-python/blob/v1.45.2/opentelemetry-api/src/opentelemetry/metrics/_internal/__init__.py (quoted as otel-58)

  > # gives all proxies real instruments off the newly set meter provider

- **Java's global chose otherwise.** Calling `GlobalOpenTelemetry.get()` before `set()` installs a global for good, and a later `set()` throws. The global is a no-op, or the autoconfigured SDK when the autoconfigure module is present and its property is on. Instruments taken from the no-op stay no-op. Since 1.57.0, `getOrNoop()` returns a no-op without installing it, so a later `set()` succeeds; instruments taken from that no-op still stay no-op.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java (quoted as otel-65, otel-67, otel-66)

  > Returns the registered global {@link OpenTelemetry} if set, else calls {@link
  >    * GlobalOpenTelemetry#set(OpenTelemetry)} with a no-op {@link OpenTelemetry} instance and returns
  >    * that.

  > "GlobalOpenTelemetry.set has already been called. GlobalOpenTelemetry.set must be "

  > <p>If the global instance has not been set, and {@code
  >    * io.opentelemetry:opentelemetry-sdk-extension-autoconfigure} is present, and {@value
  >    * GLOBAL_AUTOCONFIGURE_ENABLED_PROPERTY} is {@code true}, the global instance will be set to an
  >    * autoconfigured instance instead of {@link OpenTelemetry#noop()}.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L92-L93 (quoted as author-38)

  > <p>NOTE: This does not result in the {@link #set(OpenTelemetry)} side effects of {@link
  >    * #get()}.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java#L38-L39 (quoted as author-58)

  > <p>Native instrumentation should use {@link #getOrNoop()} as the default {@link OpenTelemetry}
  >  * instance, and expose APIs for setting a custom instance.

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/sdk-extensions/autoconfigure/src/main/java/io/opentelemetry/sdk/autoconfigure/AutoConfiguredOpenTelemetrySdk.java#L34 (quoted as author-39)

  > <p>This will automatically set the resulting SDK as the {@link GlobalOpenTelemetry} instance.

**Stated why.**

- **Why early use must work.** OTEP 0005, "Global SDK initialization", in the specification repository with its status still "proposed":

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/0005-global-init.md (quoted as otel-46, otel-47, otel-48, otel-49)

  > This
  > presents a set of opposing requirements: (1) the API supports a
  > configurable SDK; (2) third party libraries may use OpenTelemetry
  > without configuration.

  > We expect third
  > party libraries to use the global SDK before it is installed, which is
  > addressed in a requirement stated below.

  > There may be loss of metrics at startup.

  > Metric SubMeasure objects (i.e., metrics w/ predefined labels)
  > initialized before the SDK is installed will redirect to the global
  > SDK after it is installed.

- **Go.** jmacd (member), issue #388 and pull request #392:

  Source: https://github.com/open-telemetry/opentelemetry-go/issues/388 (quoted as otel-53)

  > Otherwise, metrics allocated on the global Meter implementation are no-op instruments that will remain no-op instruments for the process lifetime.

  Source: https://github.com/open-telemetry/opentelemetry-go/pull/392 (quoted as otel-54)

  > Implements deferred initialization for metric instruments registered before the first Meter SDK is installed.

  And on why globals at all, in the OTEP's discussion:

  Source: https://github.com/open-telemetry/oteps/pull/45#issuecomment-545083389 (quoted as otel-113)

  > If I depend on a body of code, and that body of code begins using OpenTelemetry instrumentation, I should not have to change my code at all.

- **Python.** aabmass (member), issue #2144:

  Source: https://github.com/open-telemetry/opentelemetry-python/issues/2144 (quoted as otel-59)

  > However, this needs to go all the way down to the instrument level, or users will end up with no-op instruments even after configuring an SDK.

  Source: https://github.com/open-telemetry/opentelemetry-python/issues/2144#issuecomment-932679695 (quoted as otel-60)

  > With this approach, the user will still lose measurements made before the SDK is configured, just how they would lose spans. I think it's OK to lose a little bit of telemetry in this edge case where a user creates tracers/instruments before setting up the SDK.

- **Java: a late registration should fail loudly, not silently.** bogdandrutu (member) and anuraaga (contributor, the pull request's author), pull request #2548 (2021):

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/2548#issuecomment-763247698 (quoted as otel-68)

  > But do we need #2396 if we simply call `set(NOOP)` on the get? Then if user tries to set will get an error that was already registered when reading first time?

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/2548#issuecomment-763238743 (quoted as otel-69)

  > If registering the SDK late becomes impossible, I definitely want to warn the user.

**Constraints.** The API and the SDK are separate packages, bound at run time. Third-party libraries use the API without configuring it (otel-46). OpenTelemetry may be loaded by an agent (otel-41).

**Costs and dissent.**

- **Against globals.** yurishkuro (member), in the OTEP's discussion:

  Source: https://github.com/open-telemetry/oteps/pull/45#issuecomment-542960342 (quoted as otel-114)

  > the best way to avoid confusion about how to initialize globals is to avoid damned globals.

- **Java's maintainers advise against its global.**

  Source: https://github.com/open-telemetry/opentelemetry-java/blob/v1.68.0/api/all/src/main/java/io/opentelemetry/api/GlobalOpenTelemetry.java (quoted as otel-64)

  > <p>WARNING: To avoid inherent complications around initialization ordering, it's best-practice to
  >  * pass around instances of {@link OpenTelemetry} rather than using {@link GlobalOpenTelemetry}.

- **A user was caught by Java's rule.** yangtaoran (third party), issue #4110:

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4110 (quoted as otel-70)

  > If I using above `get` to judge, but it will set default OpenTelemetry to global. And then it will throw exception when I set my OpenTelemetry.

  In 2022 the maintainers declined to add a way to ask whether the global was set. jack-berg (member):

  Source: https://github.com/open-telemetry/opentelemetry-java/issues/4110#issuecomment-1075521790 (quoted as otel-72)

  > we don't plan on providing tooling to know if `GlobalOpenTelemetry#set` has been called.

  In 2025 they added one, in pull request #7819:

  Source: https://github.com/open-telemetry/opentelemetry-java/pull/7819 (quoted as otel-73)

  > Adds new `GlobalOpenTelemetry#isSet()` method.

**Fit.** In the table under "Fit".

### C18. Micrometer

**What it does.** Read at `micrometer-metrics/micrometer` `v1.18.0`.

- **Meters are created on demand, at any point**, through the registry. The documentation endorses creating them inside a method when tags come from local context.
- **The same name and tags with a different type is refused with an exception.** A second registration of the same gauge is ignored with a warning.

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java (quoted as late-1)

  > There is already a registered meter of a different type (%s vs. %s) with the same name: %s

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java (quoted as late-2)

  > This %s has been already registered (%s), the registration will be ignored.

- **The Prometheus registry refuses a meter whose type differs from an earlier one under the same name, keeps the first and logs**, since pull request #6470 (2025). Before that, the conflict failed the whole scrape.

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/implementations/micrometer-registry-prometheus/src/main/java/io/micrometer/prometheusmetrics/PrometheusMeterRegistry.java (quoted as late-16)

  > Prometheus requires that all meters with the same name have the same

- **Configuration is meant to come before the first meter.** A `MeterFilter` added after meters exist applies only to later ones, and since 1.13 the registry warns:

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/micrometer-core/src/main/java/io/micrometer/core/instrument/MeterRegistry.java (quoted as late-3)

  > A MeterFilter is being configured after a Meter has been registered to this registry. All MeterFilters should be configured before any Meters are registered.

**Stated why.**

- **Why late creation.** The documentation:

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/docs/modules/ROOT/pages/concepts/registry.adoc (quoted as late-4)

  > When tags need to be determined from local context, you have no choice but to construct or look up the Meter inside your method body.

  And on recording:

  Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/docs/modules/ROOT/pages/concepts/meters.adoc (quoted as late-7)

  > Recording a measurement for a `Meter` is expected to be a relatively cheap operation and should not throw any exception.

- **Why warn about late filters rather than forbid them.** shakuzen (maintainer), pull request #4917 and issue #4920:

  Source: https://github.com/micrometer-metrics/micrometer/pull/4917 (quoted as late-9)

  > The problem with configuring MeterFilters after a Meter has been registered is that such filters will not be applied to previously registered meters. This can result in a mix of metrics with all filters applied and only some filters applied, which is potentially hard to notice.

  Source: https://github.com/micrometer-metrics/micrometer/issues/4920 (quoted as late-10)

  > Historically, we have allowed configuring MeterFilters after meters have been registered. Depending on how meters are used, the negative effects of doing this can be minimal.

  Source: https://github.com/micrometer-metrics/micrometer/issues/4920#issuecomment-2896480235 (quoted as late-12)

  > The behavior hasn't changed, but I suspect many users were unaware of the subtle behavior that this situation causes, which is why we're warning them about it so they can correct the usage.

- **Why refuse a conflicting meter at registration rather than fail the scrape.** shakuzen (maintainer):

  Source: https://github.com/micrometer-metrics/micrometer/issues/6434#issuecomment-3007532125 (quoted as late-18)

  > We can avoid the scrape failure by failing to register the second meter with the same name but a different type. See #6470 which does that. Of course that means that the second meter won't be registered, which isn't ideal, but it's better than failing the whole scrape with all other registered metrics.

- **Why the first registration wins.** jonatan-ivanov (maintainer):

  Source: https://github.com/micrometer-metrics/micrometer/issues/8141#issuecomment-6676892353 (quoted as late-21)

  > Micrometer cannot predict the future and have zero control over the order Meters are registered. If a meter registration comes in, the type will be decided, if two hours later 200 other registrations come in that all demand a different type, Micrometer cannot really fix that but the instrumentation should (Micrometer tells you about the issue in the warning log).

**Inferred why.** Inferred: libraries and application code register meters from anywhere, with no central declaration step, so the library cannot know the full set at start-up. The maintainers point to framework lifecycles, such as Spring Boot's, as where ordering is enforced. shakuzen (maintainer):

Source: https://github.com/micrometer-metrics/micrometer/issues/4920#issuecomment-2241899105 (quoted as late-13)

> What the framework should be doing is ensuring that the `MeterRegistry` given to your components already has all configuration related things done, e.g. `MeterFilter`s configured.

**Constraints.** A library in someone else's process; recording must not throw (late-7); the registry is shared by frameworks the application does not control; each exporter imposes its own rules.

**Costs and dissent.**

- **Frameworks configure filters late anyway.** brunobat (third party), for Quarkus, issue #4920 (open):

  Source: https://github.com/micrometer-metrics/micrometer/issues/4920#issuecomment-2298348202 (quoted as late-14)

  > However there are MeterFilters that will need runtime data, therefore then cannot be setup at that point.

- **Before #6470 a type conflict emptied the scrape.** KaminskiDaniel0 (third party), issue #8141:

  Source: https://github.com/micrometer-metrics/micrometer/issues/8141 (quoted as late-22)

  > The scrape endpoint answers HTTP 500 and returns **no families at all**, not even the healthy ones.

**Fit.** In the table under "Fit".

### C19. The Rust `metrics` crate

**What it does.** Read at `metrics-v0.24.6` and `metrics-exporter-prometheus-v0.18.3`.

- **Metrics are emitted through macros at any time.** Before a recorder is installed, a no-op answers and what is emitted is lost.

  Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs (quoted as late-24)

  > Initialization of the global recorder isn't required for macros to function, but any metrics emitted before a global
  > //! recorder is installed will not be recorded

- **The recorder is installed once for the life of the process.**

  Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs (quoted as late-26)

  > Only one global recorder can be installed in the lifetime of the process. If a global recorder has already been
  > //! installed, it cannot be replaced: this is due to the fact that once installed, the recorder is "leaked" so that a
  > //! static reference can be obtained to it

- **Two metrics may share a name if their kinds differ**, kept side by side:

  Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs (quoted as late-27)

  > You could conceivably have multiple metrics with the same name, so long as they are of
  > //! different types.

- **In the Prometheus exporter, the first description wins and later ones are dropped silently:**

  Source: https://github.com/metrics-rs/metrics/blob/metrics-exporter-prometheus-v0.18.3/metrics-exporter-prometheus/src/recorder.rs (quoted as late-29)

  > let already_present = descriptions.contains_key(&sanitized);
  >
  >         if already_present {
  >             return;
  >         }

  That a counter and a gauge of one name would each get a `TYPE` line in the exposition is Inferred from the rendering code, and was not run.

**Stated why.**

- **Why a no-op before installation.**

  Source: https://github.com/metrics-rs/metrics/blob/metrics-v0.24.6/metrics/src/lib.rs (quoted as late-25)

  > In cases where no global recorder is installed, a "noop" recorder lives in its place, which has an incredibly
  > //! low overhead: an atomic load and comparison.  Libraries can safely instrument their code without fear of ruining
  > //! baseline performance.

- **Why the recorder is fixed.** The documentation gives a mechanical reason, quoted above (late-26).
- **Registration is optional, and late by construction.** tobz (maintainer), issue #69:

  Source: https://github.com/metrics-rs/metrics/issues/69 (quoted as late-30)

  > Allow ahead-of-time definitions of metrics for both self-documentation and performance.

  Source: https://github.com/metrics-rs/metrics/issues/69#issuecomment-612550013 (quoted as late-31)

  > Given that this still requires a recorder to be installed, it means you would have to declare them after the program is running and a recorder is present, so it's not quite a seamless compile-time thing.

  Source: https://github.com/metrics-rs/metrics/issues/69#issuecomment-693657933 (quoted as late-32)

  > I'm satisfied that we have a simple enough approach to registering metrics even if it has the caveat of having to occur after a metrics record has been installed.

- **What happens on a conflicting second definition: no stated rationale found.** Looked in the crate documentation and the exporter's recorder; a GitHub search hit the rate limit.

**Constraints.** A facade crate: libraries depend on `metrics`, and only the executable chooses an exporter. A `'static` global, and a performance target of one atomic load when nothing is installed.

**Costs and dissent.** Metrics emitted before installation are lost (late-24). No user report was found in the time available.

**Fit.** In the table under "Fit".

### C20. .NET `System.Diagnostics.Metrics` (brief)

**What it does.** Read at `dotnet/runtime` `v10.0.15`. An instrument may be created at any time. For a counter, gauge, histogram or up-down counter, a second request returns the cached instrument only when type, unit, description and tags all match; otherwise a second instrument of the same name is created beside the first, with no error and no warning. An observable instrument is not cached: each request constructs a new one.

Source: https://github.com/dotnet/runtime/blob/v10.0.15/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/Metrics/Meter.cs (quoted as late-33)

> if (instrument.GetType() == instrumentType && instrument.Unit == unit &&
>                     instrument.Description == description && DiagnosticsHelper.CompareTags(instrument.Tags as List<KeyValuePair<string, object?>>, tags))

Source: https://github.com/dotnet/runtime/blob/v10.0.15/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/Metrics/Meter.cs (quoted as late-34)

> instrumentList.Add(newInstrument);

Source: https://github.com/dotnet/runtime/blob/v10.0.15/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/Metrics/Meter.cs#L20 (quoted as author-78)

> private Dictionary<string, List<Instrument>> _nonObservableInstrumentsCache = new();

Source: https://github.com/dotnet/runtime/blob/v10.0.15/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/Metrics/Meter.cs#L348-L349 (quoted as author-79)

> new ObservableCounter<T>(this, name, observeValue, unit, description, tags: null);

**Stated why.** For caching an identical instrument, the API proposal that introduced the cache, issue #77514 (opened by dpk83 in 2022; its body says it was edited by tarekgh), gives the purpose:

Source: https://github.com/dotnet/runtime/issues/77514 (quoted as author-80)

> The Meter will now cache non-Observable instruments internally to prevent re-creation when attempting to recreate the same instrument with identical parameters such as name, unit, tags, and generic type.

No stated rationale found for keeping differing instruments side by side, or for leaving observable instruments uncached. Looked in `Meter.cs`, the instrumentation documentation and the body of issue #77514; its comments were not read.

**Constraints, costs and dissent.** Not looked for.

**Fit.** In the table under "Fit".

---

## Frameworks that fix definitions at start-up, and those that do not

### C21. Hibernate ORM

**What it does.** Read at `hibernate-orm` `7.4.17`. The mapping is collected into metadata at bootstrap, and building the `SessionFactory` fixes it. There is no interface for adding an entity to a live factory; the way to change the mapping is to build a new factory.

Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/hibernate-core/src/main/java/org/hibernate/SessionFactory.java (quoted as late-36)

> the runtime metamodel representing the entities and their O/R mappings is
>  * fixed as soon as the {@code SessionFactory} is created. Of course, any
>  * {@code SessionFactory} is threadsafe.

**Stated why.** No stated rationale found for fixing the mapping when the factory is built. Looked in the `SessionFactory` Javadoc, the `SessionFactoryImpl` implementation note (quoted under "Constraints"), the user guide's architecture chapter, the introduction, and Hibernate team answers on the project's forum. The passages below are the nearest the authors come, and none gives a reason for the fixing itself.

- **Why one factory per database, not why its mapping is fixed.** The user guide:

  Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/documentation/src/main/asciidoc/userguide/chapters/architecture/Architecture.adoc (quoted as late-38)

  > A `SessionFactory` is very expensive to create, so, for any given database, the application should have only one associated `SessionFactory`.

- **A benefit of fixing at start-up, given for named queries, not a reason for fixing the mapping.** The introduction, on declaring a query by annotation:

  Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/documentation/src/main/asciidoc/introduction/Introduction.adoc (quoted as late-39)

  > so that Hibernate can validate the query at startup time, that is, when the `SessionFactory` is created, instead of when the query is first executed.

- **Immutability stated, not explained, in Hibernate team answers on the project's forum.** The 2016 answer's "For this reason" points to how bootstrap hands the metadata to the factory, a mechanism rather than a motive. vlad (Vlad Mihalcea, 2016) and emmanuel (2004), each ranked "Hibernate Team" on the forum:

  Source: https://forum.hibernate.org/viewtopic.php?p=2490014 (quoted as late-40)

  > No. The bootstrap process creates the Metadata and passes it to the SessionFactory upon instantiation. For this reason, you can not add entities dynamically to a SessionFactory, meaning that you need to recreate it from scratch.

  Source: https://forum.hibernate.org/viewtopic.php?p=2206248 (quoted as late-43)

  > Session factory is "immutable" considering the mapping configuration, you have to build a new one.

**Inferred why.** Inferred: an immutable model shared by every session needs no locks on the hot path, and a session can assume the mapping does not change under it.

**Constraints.** One factory per database for the application's life, shared by many sessions and threads. The implementation's own note states a concurrency constraint, though not as the reason the mapping is fixed:

Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/hibernate-core/src/main/java/org/hibernate/internal/SessionFactoryImpl.java#L148-L151 (quoted as author-87)

> @implNote This class must appear immutable to clients, even if it does
>  *           all kinds of caching and pooling under the covers. It is crucial
>  *           that the class is not only thread-safe, but also highly concurrent.
>  *           Synchronization must be used extremely sparingly.

**Costs and dissent.** A forum user said rebuilding the factory was not an option for a large mapping (saved, not quoted). What Hibernate does with two entities of the same name was not examined.

**Fit.** In the table under "Fit".

### C22. Entity Framework Core (brief)

**What it does, and why.** The model is built once per cache key and cached; by default the key is the context type, and a custom key lets one context type have several models. It is built on the first operation that needs it, not at application start-up. The stated reason, performance, explains building it once, not building it early. The EF Core documentation, read at `dotnet/EntityFramework.Docs` commit `ea9278e`:

Source: https://github.com/dotnet/EntityFramework.Docs/blob/ea9278e26d837ce9ceb7efc3c48fedf83aa0b4d3/entity-framework/core/modeling/dynamic-model.md (quoted as late-76, late-77)

> EF builds the model and runs `OnModelCreating` only once, caching the result for performance reasons.

> by default, EF assumes that for any given context type the model will be the same, so the default implementation of this service returns a key that just contains the context type.

Source: https://github.com/dotnet/EntityFramework.Docs/blob/ea9278e26d837ce9ceb7efc3c48fedf83aa0b4d3/entity-framework/core/modeling/dynamic-model.md#L18 (quoted as author-41)

> To produce different models from the same context type, you need to replace the `IModelCacheKeyFactory` service with the correct implementation

And the performance documentation, read live:

Source: https://learn.microsoft.com/en-us/ef/core/performance/advanced-performance-topics (quoted as author-40)

> Note that just creating a DbContext instance does not cause the EF model to be initialized.

The cache is a memory cache with a size limit, and the model is an entry in it at high priority, rebuilt on a miss:

Source: https://github.com/dotnet/EntityFramework.Docs/blob/ea9278e26d837ce9ceb7efc3c48fedf83aa0b4d3/entity-framework/core/performance/advanced-performance-topics.md#L329 (quoted as author-81)

> By default, EF Core configures its own `IMemoryCache` with a size limit of 10240. For reference, a compiled query has a cache size of 10, while the built model has a cache size of 100.

Source: https://github.com/dotnet/efcore/blob/v10.0.0/src/EFCore/Infrastructure/ModelSource.cs#L61-L77 (quoted as author-82)

> cache.Set(runtimeKey, runtimeModel, new MemoryCacheEntryOptions { Size = 100, Priority = CacheItemPriority.High });

**Constraints, costs and dissent.** Not looked for.

**Fit.** In the table under "Fit".

### C23. gRPC servers

**What it does.** grpc-go `v1.85.0`: services are fixed once `Serve` is called. A registration after `Serve`, and a duplicate registration, both end the process.

Source: https://github.com/grpc/grpc-go/blob/v1.85.0/server.go (quoted as late-65)

> This must be called before
> // invoking Serve.

Source: https://github.com/grpc/grpc-go/blob/v1.85.0/server.go (quoted as late-66, late-67)

> logger.Fatalf("grpc: Server.RegisterService after Server.Serve for %q", sd.ServiceName)

> logger.Fatalf("grpc: Server.RegisterService found duplicate service registration for %q", sd.ServiceName)

grpc Python `v1.85.4` documents both ways of adding handlers as safe only before start, and enforces that on one of them. `add_registered_method_handlers` logs a warning and returns without registering once the server has started. `add_generic_rpc_handlers` has no such check: it appends to the handler list the server consults when a call arrives (read in the code, not run). The C core says method registration must come before start.

Source: https://github.com/grpc/grpc/blob/v1.85.4/src/python/grpcio/grpc/_server.py (quoted as late-74)

> "Cannot register method handlers once server has started"

Source: https://github.com/grpc/grpc/blob/v1.85.4/src/python/grpcio/grpc/__init__.py (quoted as late-73)

> This method is only safe to call before the server is started.

**Stated why.** menghanl (contributor, a member of the grpc-go team), pull request #1370 (2017):

Source: https://github.com/grpc/grpc-go/pull/1370#issuecomment-315416357 (quoted as late-68, late-69)

> The purpose of not support registering after `serve()` is to avoid the overhead of mutex when reading from the service handler map. We didn't see the need to register new service handlers after the server has been started.

> If you have a use case where the service handler has to be installed after `serve()` is called, please file an issue, and we will consider supporting `register` after `serve()`.

On pull request #828 (2016), which made the late case fatal:

Source: https://github.com/grpc/grpc-go/pull/828#issuecomment-239002139 (quoted as late-70)

> By design, `s.m` should be read only after `server.start`, so this lock is not necessary here.

**Constraints.** A server's handler map is read on every request.

**Costs and dissent.** containerd needed a health service up before its real service was ready. moypray (third party):

Source: https://github.com/grpc/grpc-go/pull/1370 (quoted as late-72)

> In containerd project, We start health check grpc server first (to make sure the health check should be first served), And then load data from disk, after all the data done, we register the grpc real service of containerd.

**Fit.** In the table under "Fit".

### C24. Django

**What it does.** Read at Django `6.1.3`.

- **The set of applications is fixed at start-up.** Setup imports every application's configuration, then each one's models, then runs `ready()`. Using the registry before then raises.

  Source: https://github.com/django/django/blob/6.1.3/django/apps/registry.py (quoted as late-48)

  > raise AppRegistryNotReady("Models aren't loaded yet.")

- **The models are not strictly fixed.** Defining a model class registers it, at any time, and registration does not check whether setup has finished. The documentation still requires every model to be in its module by the end of loading.

  Source: https://github.com/django/django/blob/6.1.3/django/apps/registry.py (quoted as late-44)

  > Every time a
  >         # model is imported, ModelBase.__new__ calls apps.register_model which
  >         # creates an entry in all_models. All imported models are registered,
  >         # regardless of whether they're defined in an installed application
  >         # and whether the registry has been populated.

- **The same name twice:** the same class reloaded gives a warning and replaces the old one; a different class under the same name raises.

  Source: https://github.com/django/django/blob/6.1.3/django/apps/registry.py (quoted as late-46)

  > "Model '%s.%s' was already registered. Reloading models is not "
  >                     "advised as it can lead to inconsistencies, most notably with "
  >                     "related models."

  Source: https://github.com/django/django/blob/6.1.3/django/apps/registry.py (quoted as late-47)

  > "Conflicting '%s' models in application '%s': %s and %s."

**Stated why.**

- **Load everything at start-up.** The release notes for 1.7, which introduced application loading:

  Source: https://github.com/django/django/blob/6.1.3/docs/releases/1.7.txt (quoted as late-51)

  > Django imports all application configurations and models as soon as it
  >   starts, through a deterministic and straightforward process. This should
  >   make it easier to diagnose import issues such as import loops.

- **The ORM needs every model.** The applications reference:

  Source: https://github.com/django/django/blob/6.1.3/docs/ref/applications.txt (quoted as late-50)

  > The ORM cannot function properly until all
  >   models are available.

- **Why a reload warns and a conflict raises.** Trac ticket #23621 (2014), among Django's core developers. Aymeric Augustin, author of the application-loading change:

  Source: https://code.djangoproject.com/ticket/23621#comment:9 (quoted as late-53)

  > Going from "fails silently with subtle and inconsistent effects" to "fails loudly with an exception" doesn't count as a regression in my book :-)

  Carl Meyer:

  Source: https://code.djangoproject.com/ticket/23621#comment:5 (quoted as late-54)

  > if there are FK references to or from the reloaded model, there will be related-objects and _meta modules still holding references to the old version of the model, and that could cause all kinds of strange behavior.

  The commit that made a reload a warning, by Loic Bistuer:

  Source: https://github.com/django/django/commit/8c4ca16c65174db63471f12b005f5423b61de073 (quoted as late-57)

  > Previously a RuntimeError was raised every time two models clashed
  > in the app registry. This prevented reloading a module in a REPL;
  > while it's not recommended to do so, we decided not to forbid this
  > use-case by turning the error into a warning.

**Constraints.** Models refer to one another through foreign keys and reverse relations. A Python module cannot be safely imported twice:

Source: https://github.com/django/django/blob/6.1.3/django/apps/registry.py (quoted as late-45)

> Since it isn't possible
>         # to reimport a module safely (it could reexecute initialization code)
>         # all_models is never overridden or reset.

**Costs and dissent.** Ticket #23621 was itself a regression report from users of IPython's autoreload. The 1.7 release notes admit regressions "cannot be ruled out" (saved, not quoted).

**Fit.** In the table under "Fit".

### C25. SQLAlchemy

**What it does.** Read at `rel_2_1_9`.

- **A table may be defined at any time.** Constructing a `Table` adds it to its `MetaData`. ORM mappers may be added late too, and are configured on next use:

  Source: https://github.com/sqlalchemy/sqlalchemy/blob/rel_2_1_9/lib/sqlalchemy/orm/mapper.py (quoted as late-62)

  > Mapper configuration is normally invoked automatically, the first time
  >     mappings from a particular :class:`_orm.registry` are used, as well as
  >     whenever mappings are used and additional not-yet-configured mappers have
  >     been constructed.

- **Defining the same table twice with arguments raises, unless told otherwise**, whether or not the definition differs: the test is only whether arguments were given.

  Source: https://github.com/sqlalchemy/sqlalchemy/blob/rel_2_1_9/lib/sqlalchemy/sql/schema.py (quoted as late-58)

  > if not keep_existing and not extend_existing and bool(other_args):

  Source: https://github.com/sqlalchemy/sqlalchemy/blob/rel_2_1_9/lib/sqlalchemy/sql/schema.py (quoted as late-59)

  > f"Table '{key}' is already defined for this MetaData "
  >                     "instance.  Specify 'extend_existing=True' "

  `extend_existing=True` merges the new arguments in; `keep_existing=True` ignores them and returns the original.

**Stated why.**

- **Why the two flags exist.** zzzeek (Michael Bayer, SQLAlchemy's author), issue #2109 (2011):

  Source: https://github.com/sqlalchemy/sqlalchemy/issues/2109 (quoted as late-64)

  > uses the existing table "foo" and *ignores* all arguments.  This prevents redundant constraints, sequences, etc.

- **Why redefinition raises by default: no stated rationale found.** Looked at the docstrings of the two flags, the 0.5, 0.6 and 0.7 changelogs, and the issues that quote the error.
- **Why late definition is allowed: no stated rationale found.** Inferred: `MetaData` is a plain collection, also filled at run time by reflection, and its tables feed SQL generation rather than a fixed run-time model.

**Constraints.** Building tables in one `MetaData` is not fully thread-safe:

Source: https://github.com/sqlalchemy/sqlalchemy/blob/rel_2_1_9/lib/sqlalchemy/sql/schema.py (quoted as late-61)

> Construction of new tables within a single :class:`_schema.MetaData`
>     object,
>     either explicitly or via reflection, may not be completely thread-safe.

**Costs and dissent.** Not looked for.

**Fit.** In the table under "Fit".

---
## Stores with typed columns

The ticket asks whether reasons given by libraries for metrics carry over to tables with typed and required columns. These stores keep typed columns or fields, so they show how such systems treat a definition that differs between writers or over time.

### C26. Delta Lake: schema enforcement

**What it does.** Read at `delta-io/delta` `v4.4.1`, and the authors' blog post of 2019.

- **One schema per table, in the transaction log.**

  Source: https://www.databricks.com/blog/2019/09/24/diving-into-delta-lake-schema-enforcement-evolution.html (quoted as typed-1)

  > With Delta Lake, the table's schema is saved in JSON format inside the transaction log.

- **A DataFrame batch write with a column the table lacks, or a column type that does not match, is refused whole.** A write that omits a nullable column is accepted, and the column is null. The rules quoted below are stated for DataFrame writes, and other paths cast first. Delta's analysis rule up-casts a SQL `INSERT` by name to the table's types, and not a DataFrame append by name (author-65). Its streaming sink merges the schemas with implicit conversions allowed and casts the data before writing (author-68, author-69). Databricks documents safe casts for SQL `INSERT` and `MERGE` in its product (author-70, author-71). Inferred: on those paths a type is refused whole only when the path cannot cast it. A column declared not nullable becomes a `NOT NULL` constraint that every write checks, and a missing one throws (author-66, author-67); that omitting such a column always fails the write is Inferred from the code, as the paths were not traced one by one.

  Source: https://www.databricks.com/blog/2019/09/24/diving-into-delta-lake-schema-enforcement-evolution.html (quoted as typed-2)

  > If the schema is not compatible, Delta Lake cancels the transaction altogether (no data is written), and raises an exception to let the user know about the mismatch.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-batch.mdx (quoted as typed-9, typed-10)

  > DataFrame column data types must match the column data types in the target table. If they don't match, an exception is raised.

  > Columns present in the table but not in the DataFrame are set to null.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/spark/src/main/scala/org/apache/spark/sql/delta/DeltaAnalysis.scala#L111-L112 (quoted as author-65)

  > // AppendData.byName is also used for DataFrame append so we check for the SQL origin text
  >     // since we only want to up-cast for SQL insert into by name

  Source: https://github.com/delta-io/delta/blob/v4.4.1/spark/src/main/scala/org/apache/spark/sql/delta/sources/DeltaSink.scala#L196-L201 (quoted as author-68, author-69)

  > allowImplicitConversions = true,

  > /** Casts columns in the given dataframe to match the target schema. */

  Source: https://github.com/delta-io/delta/blob/v4.4.1/spark/src/main/scala/org/apache/spark/sql/delta/constraints/Invariants.scala#L78-L79 (quoted as author-66)

  > case (parents, field) if !field.nullable =>
  >         Constraints.NotNull(parents :+ field.name)

  Source: https://github.com/delta-io/delta/blob/v4.4.1/spark/src/main/scala/org/apache/spark/sql/delta/constraints/DeltaInvariantCheckerExec.scala#L175-L177 (quoted as author-67)

  > case n @ NotNull(column) =>
  >           buildExtractor(output, column).getOrElse {
  >             throw DeltaErrors.notNullColumnMissingException(n)

  For Databricks, not the open-source release:

  Source: https://docs.databricks.com/aws/en/tables/schema-enforcement (quoted as author-70, author-71)

  > Databricks attempts to safely cast column data types to match the target table.

  > If the data type in the source statement does not match the target column, MERGE tries to safely cast column data types to match the target table.

- **A constraint violation aborts the whole transaction.** That the same holds for a column declared not nullable was not found in the protocol; the constraints documentation lists `NOT NULL` among the constraints whose violation throws.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/PROTOCOL.md (quoted as typed-14, typed-15)

  > Writers MUST abort any transaction that adds a row to the table, where an invariant evaluates to `false` or `null`.

  > When writing to a table that contains CHECK constraints, every new row being written to the table must satisfy CHECK constraints in the table. Otherwise, the write operation must fail and the table must stay unchanged.

- **A concurrent schema change makes the other writer fail.**

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/concurrency-control.mdx (quoted as typed-17)

  > This exception occurs when a concurrent transaction updates the metadata of a Delta table. Common causes are `ALTER TABLE` operations or writes to your Delta table that update the schema of the table.

- **The schema changes in place only by an explicit choice.** Columns are added by `mergeSchema`. With column mapping on (C14), a rename or a drop changes only metadata. With type widening on, a supported type change needs no rewrite of the files. Otherwise a type change, rename or drop rewrites the table.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-batch.mdx#L1671 (quoted as author-32)

  > To rename columns without rewriting any of the columns' existing data, you must enable column mapping for the table.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-batch.mdx#L1732 (quoted as author-33)

  > To drop columns as a metadata-only operation without rewriting any data files, you must enable column mapping for the table.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-type-widening.mdx#L98 (quoted as author-34)

  > The table schema is updated without rewriting the underlying Parquet files.

  Source: https://github.com/delta-io/delta/blob/v4.4.1/docs/src/content/docs/delta-batch.mdx (quoted as typed-11)

  > You can change a column's type or name or drop a column by rewriting the table.

**Stated why.** The blog post by Burak Yavuz, Brenner Heintz and Denny Lee, of Databricks, which created Delta Lake (2019):

Source: https://www.databricks.com/blog/2019/09/24/diving-into-delta-lake-schema-enforcement-evolution.html (quoted as typed-4, typed-5, typed-6, typed-8)

> A much better approach is to stop these enemies at the gates - using schema enforcement - and deal with them in the daylight rather than later on, when they'll be lurking in the shadowy recesses of your production code.

> Schema enforcement provides peace of mind that your table's schema will not change unless you make the affirmative choice to change it.

> To avoid potential mistakes, data corruption or loss issues (which we've personally experienced at Databricks), we decided to add this restriction.

> Because it's such a stringent check, schema enforcement is an excellent tool to use as a gatekeeper of a clean, fully transformed data set that is ready for production or consumption.

Source: https://www.databricks.com/blog/2019/09/24/diving-into-delta-lake-schema-enforcement-evolution.html (quoted as typed-7)

> Schema evolution can be used anytime you intend to change the schema of your table (as opposed to where you accidentally added columns to your DataFrame that shouldn't be there).

**Inferred why.** Inferred: a write is one atomic commit to the log, so the unit accepted or refused is the transaction, not the row.

**Constraints.** Batch and streaming jobs writing through engines such as Spark to a shared table with optimistic concurrency. Readers expect one schema per table version. Writers are jobs, not long-lived libraries inside an application.

**Costs and dissent.** Not looked for beyond the post's own admission that an unexpected mismatch error "can trip you up" (saved, not quoted).

**Fit.** In the table under "Fit".

### C27. Elasticsearch: mappings and the failure store

**What it does.** Read at Elasticsearch `v9.5.7` and `v7.17.29`, and `elastic/docs-content` at commit `96870a9`.

- **A value that cannot be converted to the field's type refuses the whole document, by default.** For numeric fields, coercion is on by default: a string is converted to a number, and a fraction is truncated for an integer. Per field or index, `ignore_malformed` keeps the document and leaves the field unindexed.

  Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/mapping-reference/ignore-malformed.md (quoted as typed-20, typed-21)

  > Trying to index the wrong data type into a field throws an exception by default, and rejects the whole document.

  > The `ignore_malformed` parameter, if set to `true`, allows the exception to be ignored. The malformed field is not indexed, but other fields in the document are processed normally.

  Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/mapping-reference/coerce.md#L15-L16 (quoted as author-42)

  > * Strings will be coerced to numbers.
  > * Floating points will be truncated for integer values.

  Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/mapping-reference/number.md#L108 (quoted as author-43)

  > Accepts `true` (default) and `false`.

- **With a data stream's failure store on, a document refused for its mapping or by an ingest pipeline is kept apart, and the client is told it succeeded, with a flag.** Failures from backpressure, security or version conflicts are still returned to the client, and so is the original error when the refused document cannot be stored. From 9.2 the failure store is on by default for new data streams that match `logs-*-*`, through the built-in `logs` index template.

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/failure-store.md (quoted as typed-23, typed-24)

  > In the absence of the failure store, a failed document would cause the indexing operation to fail, with an error message returned in the operation response.

  > When a data stream's failure store is enabled, these failures are instead captured in a separate index and persisted to be analysed later. Clients receive a successful response with a flag indicating the failure was redirected.

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/failure-store.md#L45 (quoted as author-44)

  > New logs data streams that match the `logs-*-*` pattern already have the failure store enabled through the built-in `logs` index template.

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/failure-store.md#L23 (quoted as author-83)

  > Failure stores do not capture failures caused by backpressure, security issues, or document version conflicts. These failures are always returned as-is since they warrant specific action by the client.

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/data-streams/failure-store.md#L272 (quoted as author-84)

  > If the document was redirected to a data stream's failure store but that failed document could not be stored (for example, due to shard unavailability or a similar problem), then the `failure_store` field on the response will be `failed`, and the response will display the error for the original failure, as well as a suppressed error detailing why the failure could not be stored

- **Two indices with different types for one field are kept side by side**, and queries across them see a conflict:

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/troubleshoot/security/detection-rules.md (quoted as typed-33)

  > Type conflicts occur when a field is mapped to different types across multiple indices.

- **A field's type is never changed in place.**

  Source: https://github.com/elastic/docs-content/blob/96870a908ce76d263fa01d5f4c4e687be43e1c99/manage-data/data-store/mapping/explicit-mapping.md (quoted as typed-18, typed-19)

  > you can’t change the mapping or field type of an existing field. Changing an existing field could invalidate data that’s already indexed.

  > Renaming a field would invalidate data already indexed under the old field name.

**Stated why.**

- **No change in place**: invalidating data already indexed (typed-18, above). That is the documentation's reason; no design note was found.
- **One definition per field per index**, from the 7.x page on removing mapping types:

  Source: https://github.com/elastic/elasticsearch/blob/v7.17.29/docs/reference/mapping/removal_of_types.asciidoc (quoted as typed-29, typed-30)

  > In an Elasticsearch index, fields that have the same name in different mapping
  > types are backed by the same Lucene field internally.

  > This can lead to frustration when, for example, you want `deleted` to be a
  > `date` field in one type and a `boolean` field in another type in the same
  > index.

- **Accepting logs rather than refusing them.** eyalkoren (contributor), issue #95222 (2023):

  Source: https://github.com/elastic/elasticsearch/issues/95222 (quoted as typed-27)

  > As part of our effort to accept all logs by default, one of the first issues we want to address is the rejection of log events due to field type not matching the corresponding mapping.

- **The failure store on by default.** flash1293 (contributor), issue #131105 (2025):

  Source: https://github.com/elastic/elasticsearch/issues/131105 (quoted as typed-25, typed-26)

  > To avoid dropping data silently, the failure store should be enabled by default for logs data

  > While this might lead to increased disk usage for wrongly configured systems in which lots of malformed data is dropped by Elasticsearch, the benefits for regular system outweigh the downsides.

**Inferred why.** Inferred: a field's type decides its on-disk structures, so a type change cannot be applied to existing segments without rewriting them. Per-index mappings let a new index start with a new type, which is why conflicts appear across indices and never within one.

**Constraints.** A server fed by many independent shippers. The document is the unit written. Indices roll over by time, so a template change takes effect at the next rollover.

**Costs and dissent.** A refused document was lost unless the client handled the error, which is the reason the failure store gives (typed-25). Type conflicts across indices degrade queries (typed-33). The failure store trades that for disk (typed-26).

**Fit.** In the table under "Fit".

### C28. InfluxDB

**What it does.** Documentation in `influxdata/docs-v2` at commit `5690235`; source at `v1.13.2`.

- **In 1.x and 2.x a field's type is fixed per shard by the first write.** A point of another type in the same shard is refused; in a later shard it is accepted, and both types are kept.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb/v1/write_protocols/line_protocol_reference.md (quoted as typed-34)

  > In a measurement, a field's type cannot differ in a [shard](/influxdb/v1/concepts/glossary/#shard), but can differ across
  > shards.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb/v1/troubleshooting/frequently-asked-questions.md (quoted as typed-38, typed-39)

  > InfluxDB will accept writes with a different data type to an existing field if the point has a timestamp
  > that occurs after that `end_time`.

  > Note that this will not change the field's data type on prior shards.

- **Since 2017 a refused point does not fail the rest of its batch.** sparrc (contributor), issue #7814, gave the reason:

  Source: https://github.com/influxdata/influxdb/issues/7814 (quoted as typed-46, typed-47)

  > The reason for this is that telegraf (and any system writing batches to InfluxDB) currently can get into a situation where a mismatched type can cause the entire batch to be dropped.

  > If the entire batch is not dropped, then it will be in a state where all batches continually fail forever, as the mismatched point will always fail the entire retried batch.

- **A query across shards returns the values of one type only.** After any casts, it returns the values whose type comes first in float, integer, string, Boolean, and leaves the others out; in the FAQ's example, `SELECT *` returns only the float and the integer values. Naming each type with `<field_key>::<type>` returns all of them.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb/v1/troubleshooting/frequently-asked-questions.md (quoted as typed-36)

  > returns all values with the type that occurs first in the
  > following list: float, integer, string, Boolean.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb/v1/troubleshooting/frequently-asked-questions.md#L319 (quoted as author-45)

  > `SELECT *` returns only the float and integer field values.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb/v1/troubleshooting/frequently-asked-questions.md#L310-L311 (quoted as author-46)

  > If your data have field value type discrepancies, use the syntax
  > `<field_key>::<type>` to query the different data types.

- **InfluxDB 3 Enterprise has an explicit mode**: tables and columns must be declared before writing, anything undeclared is refused, and the schema may only grow.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb3/enterprise/admin/databases/enforce-schema.md (quoted as typed-57)

  > _Explicit_ schema mode inverts that: tables and columns must be declared
  > through the configuration API before you can write to them, and a write
  > that references anything undeclared is rejected.

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb3/enterprise/admin/databases/enforce-schema.md (quoted as typed-59)

  > Schema evolution is **add-only**: you can declare new columns, but you can't
  > remove, rename, or retype an existing one.

**Stated why.**

- **Why a type is fixed per shard: no stated rationale found.** Looked in the line protocol reference and FAQ, issues #3460, #8412, #17251 and #26937, and `tsdb/shard.go`; a further search hit GitHub's rate limit. A maintainer statement describes the rule without giving a reason. philjb (contributor):

  Source: https://github.com/influxdata/influxdb/issues/26937 (quoted as typed-56)

  > First datatype write wins in a new shard.

- **Why the explicit mode only adds.** The Enterprise documentation ties it to how catalog changes reach other nodes:

  Source: https://github.com/influxdata/docs-v2/blob/56902356161c4cfd346f03af5d3de113c90ee0f2/content/influxdb3/enterprise/admin/databases/enforce-schema.md (quoted as typed-60, typed-61)

  > Add-only evolution is what keeps this safe.

  > As a result, the lag can reject a write that should have been accepted.
  > It can never accept a write that should have been rejected.

**Inferred why.** Inferred: each shard's files and index are independent and created as time advances, so a per-shard set of fields needs no coordination across shards.

**Constraints.** A server receiving batches of points from many agents, with no declared schema in 1.x and 2.x. Shards partitioned by time, and dropped whole by retention.

**Costs and dissent.**

- **Whole-batch refusal blocked unrelated data**, before 2017 and again in the 2.0 betas. timburke (third party), issue #17953:

  Source: https://github.com/influxdata/influxdb/issues/17953 (quoted as typed-49)

  > However, as we investigated moving to influxdb v2, we see a huge issue because a single field type error from any sensor could block data from all sensors from reaching influxdb since the entire 5k data point batch would be rejected.

- **Types that differ across shards cut a query short silently.** jbuchermn (third party) and philjb (contributor), issue #26937:

  Source: https://github.com/influxdata/influxdb/issues/26937 (quoted as typed-54, typed-55)

  > When querying data before August 18th 2025, I only get data until August 18th.

  > Oh; I think i know what this is; the field heating_operation_mode must be changing data type at the shard boundary.

**Fit.** In the table under "Fit".

### C29. Google BigQuery (brief)

**What it does.** Documentation read live. A streaming insert through `tabledata.insertAll` with any invalid row fails the whole request by default; keeping the valid rows is opt-in. Google's streaming page now calls that method the Storage Write API (REST) (author-85); BigQuery's other ingestion interfaces were not read. A field the table lacks is an error by default. A required column cannot be added to an existing table, except nested inside a new `RECORD` field, and a column's mode may only be relaxed from required to nullable. The schema is not add-only: DDL can drop or rename a column and make certain changes to its type.

Source: https://cloud.google.com/bigquery/docs/reference/rest/v2/tabledata/insertAll (quoted as typed-62)

> Optional. Insert all valid rows of a request, even if invalid rows exist. The default value is false, which causes the entire request to fail if any invalid rows exist.

Source: https://cloud.google.com/bigquery/docs/reference/rest/v2/tabledata/insertAll (quoted as typed-63)

> Optional. Accept rows that contain values that do not match the schema. The unknown values are ignored. Default is false, which treats unknown values as errors.

Source: https://cloud.google.com/bigquery/docs/managing-table-schemas (quoted as typed-64, typed-65)

> You cannot add a REQUIRED column to an existing
> table schema.

> The only supported modification you can make to a column's mode is
> changing it from REQUIRED to NULLABLE.

Source: https://docs.cloud.google.com/bigquery/docs/managing-table-schemas (quoted as author-47, author-48, author-49, author-86)

> You can delete a column from an existing table by using the ALTER TABLE DROP COLUMN DDL statement

> To rename a column on a table, use the ALTER TABLE RENAME COLUMN DDL statement

> You can use GoogleSQL to make certain changes to the data type of a column.

> However, you can create a nested REQUIRED column as part of a new RECORD field.

Source: https://docs.cloud.google.com/bigquery/docs/streaming-data-into-bigquery (quoted as author-85)

> The BigQuery Storage Write API (REST), previously known as the legacy tabledata.insertAll method, lets you stream rows into BigQuery tables without running a load job.

**Stated why.** For refusing to add a required column, Google's troubleshooting page gives the reason:

Source: https://docs.cloud.google.com/bigquery/docs/troubleshoot-schemas (quoted as author-50)

> Because existing rows in the table would receive NULL values for the newly added column, BigQuery rejects adding REQUIRED columns directly through schema updates.

For failing the whole request and for refusing unknown fields, no stated rationale found on the pages read.

**Constraints, costs and dissent.** Not looked for.

**Fit.** In the table under "Fit".

### C30. Grafana Mimir (brief)

**What it does, and why.** Conflicting metadata for one metric name in a tenant is kept as a set, within limits. Read at `mimir-3.2.6`; the file says it derives from Cortex. That samples are not refused over a metadata disagreement is Inferred from this file only.

Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/pkg/ingester/user_metrics_metadata.go (quoted as typed-67)

> // Metadata is kept as a set as it can come from multiple targets that Prometheus scrapes
> // with the same metric name.

**Fit.** In the table under "Fit".

---
## The claims from the elicitation

Each claim was recorded in `CONTEXT.md` with no link. Each is checked here against the sections above.

| Claim | Result | Where |
| --- | --- | --- |
| OpenTelemetry and Prometheus check nothing across processes | **Confirmed for their client libraries and SDKs**, which check only within one process: client_golang within one registry, the OpenTelemetry SDK within one Meter. **Wrong for Prometheus's Pushgateway**, which by default refuses a push whose type conflicts with another pusher's; with `--push.disable-consistency-check` it accepts the push, and its scrapes fail instead. | C1, C3, C4 |
| ...and keep conflicting versions side by side downstream | **Partly wrong.** By default the Prometheus server keeps the series apart by `job` and `instance`, which `honor_labels` gives up where a target exposes conflicting values for those labels itself, and its experimental metadata API lists the distinct versions among the targets currently scraped. But metadata was overwritten per name before remote write 2.0, federation drops type and help, the OpenTelemetry Collector's Prometheus exporter drops a metric whose type conflicts and keeps the first help while the name stays cached, OpenTelemetry lets a consumer reject a semantic error, and receivers should deduplicate two writers of one stream. Mimir keeps conflicting metadata as a set. In the client rather than downstream, client_python's multiprocess mode keeps one metric per name when it collects files that separate processes wrote: the first file to name a metric sets its help and type, and every other process's samples are added to it (Inferred from the code). | C1, C2, C4, C5, C30 |
| Snowplow adds a declared version, validated downstream, with bad data quarantined | **Confirmed for self-describing events and entities, with two caveats.** Baked-in events, such as page views, carry no event schema. The stated reason is against dropping bad data, not against refusing it at the source. Since Enrich 6.5.0, released on 2026-01-09, Enrich crashes when schema resolution fails with a system error, such as an unreachable registry, instead of writing failed events; its stated reason is to keep infrastructure issues from creating bad rows. | C6 |
| OpenTelemetry's schema URL adds a declared version, validated downstream, with bad data quarantined | **Declared version: confirmed. Validated downstream and quarantined: wrong.** The schema URL drives translation, and OTEP 0152 puts validation out of scope. The schema processor passes unmapped names through, logs and counts a failure for a Scope and carries on, and for a failure on a Resource returns an error and passes on none of the batch. No component that quarantines was found. Weaver's live check validates as a developer and CI tool. | C7 |
| Only Confluent Schema Registry blocks a producer at write time | **Wrong.** Pulsar refuses a producer with an incompatible schema when it is created, and fails the send of a message whose new schema is incompatible (PIP-43). AWS Glue and Apicurio refuse at registration, which happens in the producer's serializer when auto-registration is on. AWS also documents a separate step, in which Glue's serializer checks each record against a registered schema, throws when it does not match, and the record is not sent (author-51); for Apicurio, that the producer's send fails is Inferred from its documentation. Neither path was traced in code. Prometheus's Pushgateway refuses a conflicting push by default. Stores with typed columns refuse a write that does not fit at the store, which is blocking a producer only if a store's caller counts as one; the claim does not say. | C3, C8 to C10, C26 to C29 |
| ...and it needs an always-available service | **Partly confirmed.** The serializer needs the registry on a cache miss, not on every write: a schema's first use under a subject by each registry client, or a use after the bounded cache has evicted it. Instances other than the primary serve reads and schemas already registered. Its authors call the dependency "a runtime requirement and potential source of failure", and users reported outages. Since 2024 the client retries a failed connection and some error responses with randomised backoff, three times by default; Inferred from the code, a short outage need no longer fail a send that misses the cache, though no outage length is sure to pass. | C8 |
| "The cheapest upgrade: a declared version or definition hash, and column ids that are never reused" | **Unverified as a sentence: no source found.** "Cheapest" is a claim no source makes. Its parts exist: a declared version (Snowplow, OpenTelemetry's schema URL); a schema hash per stored entry, suggested by Avro's author in 2009 and specified in Avro's single-object encoding, which needs a store to resolve it; and a literal never-reuse rule for ids in Protocol Buffers, and later in Meta's fbthrift. Neither Iceberg nor Delta uses the words "never reused": Iceberg's specification states the rule as the purpose of its counter, "always assigned an unused ID", and Delta states a counter that only increases. | C6, C7, C11 to C15 |
| Iceberg was named; find which system the idea of column ids came from | **Not established.** For table columns, Iceberg's specification states the unused-id rule, in a sentence written no later than 2019-06-23; when it was first written was not established. The mechanism is older: Iceberg's first public release, 2017, already tracks columns by id and gives each new column the id after a stored counter. For message field numbers, the earliest source found is Protocol Buffers, 2008, which says nothing about table columns. The only author's statement connecting two of these systems is Delta's design document, which names Iceberg as a competitor. Where the elicitation's sentence came from cannot be checked: its record is not tracked. | C11 to C14, "Where 'column ids that are never reused' came from" |
| Prometheus clients register metrics whenever the code runs | **Confirmed.** Both clients register at any time, under a lock, and refuse a conflicting second registration. The client guidelines intend metrics as globals registered when the code loads. No stated rationale was found for allowing late registration. | C1 |
| OpenTelemetry instruments can be created before or after the provider is set | **Confirmed that Go, Python and Java each let an instrument be created before or after the provider is set. Wrong for Java if the claim means that an early instrument starts working once the provider is set.** In Go and Python early instruments are rewired when the provider is set, and measurements in between are lost. Java does not rewire: an instrument taken from a no-op stays no-op. In Java, `get()` before `set()` also installs a global for good, a no-op or the autoconfigured SDK when autoconfigure is on, and a later `set()` throws either way. Since 1.57.0, `getOrNoop()`, which the class documentation tells native instrumentation to use, lets code take an early no-op without blocking a later `set()`; later calls get the instance that was set, but instruments taken before it stay no-op. | C17 |
| Declaring at any time is the norm for telemetry libraries | **Confirmed for every library read**: Prometheus's two clients, OpenTelemetry's SDKs, Micrometer, the Rust `metrics` crate and .NET. Each fixes something early: Micrometer its filters, `metrics` its recorder, Java OpenTelemetry its global. | C1, C17 to C20 |
| Frameworks that own a schema, such as object-relational mappers, fix everything at start-up | **Partly wrong.** Hibernate and grpc-go fix their definitions at start-up; grpc-go's team states why (a read path with no lock), and no stated reason was found for Hibernate's. Entity Framework Core builds a model once per cache key, on first use rather than at start-up, and reuses it while it stays in its size-limited memory cache; whether a cached model is ever evicted and rebuilt was not established. Django fixes its set of applications, but its registry accepts a model defined later. SQLAlchemy lets a table be defined at any time. Unless told to keep or extend the first, it refuses a second definition of the same table that is given any arguments, identical or not. | C21 to C25 |

## Comparables that chose otherwise

**Refusing a conflicting definition across writers.**

- **Prometheus's Pushgateway refuses**, by default, a push whose type conflicts with another group's, because every push is exposed on one endpoint. A flag moves the check to scrape time, where one bad push fails every scrape (C3). Prometheus's server, in the same family, does not refuse.
- **Confluent Schema Registry and Pulsar refuse a producer** whose schema is incompatible: Confluent in the client serializer, on a schema's first use under a subject, and Pulsar in the broker when the producer is created or a message brings a new schema. Confluent's authors give a stream with many independent readers as the reason, and Pulsar's documentation gives type safety on a message bus (C8, C9). AWS Glue's serializer also throws, and AWS's launch post gives the reason that breaking changes are "found earlier in development cycles"; that concerns a producer with a registry too (C10).
- **Within one process, client_golang refuses**, and its maintainer limits the guarantee to "the lifetime of a binary" (C1). OpenTelemetry once required an error too, and reversed it in 2022, because a duplicate cannot be avoided across libraries and an error raised while the program runs would be a crash (C4).

**Fixing definitions at start-up.**

- **Hibernate** fixes its mapping when the factory is built. No stated rationale for the fixing was found; its documentation gives cost as the reason for one factory per database, and start-up validation as a benefit for named queries (C21). **Entity Framework Core** caches its model "for performance reasons", once per cache key, and builds it on first use rather than at start-up (C22).
- **grpc-go** ends the process on a late registration, to avoid a lock on the read path; its team offered to reconsider for a real use case (C23).
- **Django** loads every application at start-up so that loading is deterministic and the ORM sees every model, but still accepts a model defined later (C24).
- **OpenTelemetry's Java global** makes a late SDK registration fail loudly after an early `get()`, rather than leave instruments silently no-op (C17). Since 1.57.0, `getOrNoop()`, which the class documentation tells native instrumentation to use, lets the late registration succeed, and instruments taken before it stay no-op without an error.

**Typed columns refused at the store.**

- **Delta Lake** refuses a whole write that does not fit, to "stop these enemies at the gates", and changes a schema only by an explicit choice (C26).
- **Iceberg**, from format v3, makes a writer fail when a required field is missing and has no write default (C11).
- **Elasticsearch** refuses, by default, a document with a value it cannot coerce to the field's type, and now keeps refused documents of new logs data streams in a failure store "to avoid dropping data silently" (C27).
- **InfluxDB 3 Enterprise's explicit mode** refuses anything undeclared and lets the schema only grow, because catalog changes reach nodes late (C28).

## Candidates not examined, or dropped

- **Not examined:** StatsD and DogStatsD clients; Prometheus's Java and Rust clients; OpenTelemetry's SDKs other than Go, Python and Java; ClickHouse; Thanos and VictoriaMetrics; DuckDB; ORC; Hive's own documentation; Rails' schema cache.
- **Read only in part:** KIP-467 was not fetched, and of Confluent pull request 3424 only its description is quoted (author-72). Ryan Blue's talks, the Iceberg mailing list and Thrift's issue tracker were not searched. What Hibernate does with two entities of one name, and the reason behind .NET's instrument cache (issue #77514), were not examined. Kibana's page on conflicting field types was not found.
- **Limited by GitHub's search rate limit,** shared by the survey agents: further searches for beorn7's comments on client_golang, for issues on the Rust `metrics` crate, and for a reason behind InfluxDB's per-shard types.
- **Set aside as a different failure:** "was collected before with the same name and label values" in the OpenTelemetry Collector, which is two sources producing one series, not two definitions (C5).

## Fit

This section and the ones after it were written after the first adversarial review. They cite the sections above by number and by quotation label rather than quote them again, except where a new quotation is given.

### The constraints of this client

Taken from the specification (`docs/specs/transect-client.allium`) and from `CONTEXT.md`. A leaning is marked as one.

- **K1. A library inside the host's process.** Opening a client handle and writing "never fail and never block" (`NeverFailsNeverBlocks`). Declaring a table and establish may fail loudly (`LoudFailure`). The failure posture was chosen by the agent, not the maintainer, and ticket 16 researches it (`CONTEXT.md`, "Where a choice was delegated").
- **K2. A table is a typed definition.** A namespace, a name, a kind (time series or keyed state), a tenant scope, typed columns each required or optional, and a key for a keyed table. A row that does not fit is refused whole, and nothing is converted (`fits`).
- **K3. Within one confluence a definition is checked.** An identical redeclaration returns the table; any difference fails loudly (`RedeclarationReturnsTheSameTable`).
- **K4. A run is one establish, with its own local databases.** One live process holds a location (`OneWriterProcessPerInstance`). The on-disk form is private (`PrivateOnDiskForm`).
- **K5. The hand-over carries each run's definitions with its rows.** It exposes the run id and, for each table, its namespace, name, kind, tenant scope, columns and key (`surface HandOver`). The collector's internals are outside the specification, and whether collection is a push or a pull is open question 15; the maintainer leans towards a pull.
- **K6. A run may follow another at the same location.** What establish does with the local databases an earlier run left there is open question 6.
- **K7. The usual host is an ephemeral pod** (a leaning, not a decision). Inferred from the leaning: several instances of one application run at once, each with its own run, and during a rolling deployment two of them can run different definitions of one table at the same time.
- **K8. The standing guidance**: prefer coordination-free or low-coordination solutions; keep the MVP simple without closing off options; follow practice where it exists.
- **K9. One behaviour for Rust and Python.**
- **K10. A table may be declared at any time, and one declared during a run is usable at once.** The specification's guidance gives the reason declaring may fail loudly as "it runs at start-up, where the developer can see it".

### Fit of each comparable

"Holds" lists the constraints behind the comparable's choice that this client shares. "Does not hold" lists those it does not. "Use" says what the comparable may do for the specification: **justifies** needs a stated why and an argument that it fits, under `CONTEXT.md`; everything else **informs**. Where a cell argues beyond what a source states, the argument is the researcher's.

| § | What it does | Stated why | Holds here | Does not hold | Use |
| --- | --- | --- | --- | --- | --- |
| C1 Prometheus clients | Check one registry in one process; no check across processes; register at any time; client_python's multiprocess mode merges per-process files under the first definition seen, and its files must be wiped between runs | Within one binary: "We cannot prevent that from happening globally" (prometheus-17). Late registration and wiping: none found | A library inside each process, whose run cannot reach another instance's run (K1; K7, a leaning). The check within one binary has the same shape as K3 | beorn7 states a limit, not its cause: Prometheus "cannot prevent" a metric's labels changing "globally", and a library guarantees them "over the lifetime of a binary" (prometheus-17), said in refusing a request to re-register a metric with other labels (prometheus-18). That the limit is what a library can reach is Inferred, and client_python's multiprocess mode does read files other processes wrote to its directory. Successive runs of one confluence, which the specification allows (Derived), share its declarations (`rule AttachRun`), so a definition changed between them fails as a redeclaration (K3). For a run in a new process that follows another at the same location, the earlier run's databases can be seen (K6), so an inability to reach does not hold there. The multiprocess mode is the comparable closest to local files written by separate processes, but its files are merged at collection inside the client, and earlier runs' files are deleted, not kept with their definitions | **Justifies**, through its stated limit, checking nothing against runs on other instances, so that for them the check stops at the confluence (K3); the fit is the researcher's argument. Informs the rest |
| C2 Prometheus server | Keeps series from different targets apart by default; metadata API lists versions; metadata overwritten per name before remote write 2.0; type and unit moving into identity | Metadata "can change over time" (prometheus-55); rollouts and unrelated programs, of which bboreham wrote "IMO we should make both of these work" (prometheus-59); names alone collide (prometheus-68 to -70) | Two runs disagreeing during a rollout (K7) | It is the receiving side, the collector's analogue, outside the specification (K5). Its series carry advisory metadata; a table's columns are not advisory (K2) | Informs. Its move of type and unit into identity informs what a collector may face |
| C3 Pushgateway | Refuses a push whose type conflicts with another pusher's, by default; a flag moves the check to scrape time, where one bad push fails every scrape | One endpoint exposes every push (prometheus-81, prometheus-74); a check only at read lets one bad write fail every read (author-8) | None at the client: there is no endpoint here where runs' data meet | It is the place where writers' data meet, which here is the collector (K5). Its authors weigh one check at write and at read, and give the reason for checking at write | Informs, for the collector |
| C4 OpenTelemetry identity and duplicates | Identity includes Resource and Scope; conflicts in one Resource and Scope passed through with a warning; a consumer may reject; duplicates return a working instrument, reversed from an error in 2022 | A crash at run time is unacceptable (otel-25, otel-40, otel-43); libraries cannot coordinate (otel-23); "pass along" the ambiguity to keep the SDK simple, at the cost of errors at type-aware back ends (otel-28, otel-29); OpenTelemetry cannot know which stream is erroneous, a back end with a schema could (otel-39) | A library inside the process that must not change the host's behaviour (K1). Pass-through matches K5, which carries each run's definitions to the collector | The reasons concern one process or one stream. That a different Resource is no conflict is Inferred (C4), not stated. Within one confluence the specification fails a conflicting redeclaration loudly (K3), which OpenTelemetry's 2022 reversal argues against at run time | Informs. Its reasons against a loud failure at run time bear on K3 for a late declaration; that posture is ticket 16's |
| C5 Collector Prometheus exporter | Keeps the first type and help per name while cached; drops a metric whose type conflicts; once failed the whole scrape | TYPE conflicts must drop a metric, "as the data sent might not be valid" (otel-94) | None at the client | A downstream aggregation point (K5) | Informs, for the collector |
| C6 Snowplow | A version on each self-describing payload; validated downstream; failures kept, not dropped; a registry outage now crashes Enrich | Versions tied to historical data (registries-2, -4); each payload records its schema (registries-5 to -7); dropped data is hard to spot (registries-8, -9) | Rows read later than they are written, under definitions that may have changed (K5). A dropped row is counted here, not silent | The pipeline validates against a registry; this client has none, and its collector's internals are outside the specification. Trackers do not validate by default (Inferred, C6); the one client-side check documented, opt-in generated code for the browser tracker, logs a warning by default (registries-25); this client refuses a row that does not fit (K2) | Informs. The reason for each payload to name its schema bears on open question 13 |
| C7 OpenTelemetry schema URL | A version per Resource or Scope, used to translate; no validation, no quarantine | Producers and consumers evolve independently (otel-79, otel-80); validation is not a goal (otel-82) | Producers and consumers that change independently (K5, K7) | It versions semantic conventions shared across many producers, not one application's tables | Informs |
| C8 Confluent Schema Registry | The producer's serializer refuses an incompatible schema on a cache miss; a single primary | Readers that cannot be tested against every producer (registries-67, -68); a single primary keeps incompatible schemas out (registries-52); the dependency accepted (registries-54) | None | A service every producer must reach on a cache miss: against K8, and against K1 wherever a refusal or an outage would reach a write | Informs: its stated costs are the reason it does not fit |
| C9 Pulsar | The broker refuses an incompatible producer, and a send with an incompatible new schema | Type safety on a message bus (registries-80, -81) | None | A broker that owns the topic and its schemas; this client has no broker | Informs |
| C10 AWS Glue, Apicurio | Refuse at registration; Glue's serializer throws for a record that does not match | Glue: breaking changes "found earlier in development cycles" (author-56). Apicurio: checking before deployment (author-57) | Finding a breaking change early, where the developer looks (K1's loud declaration). Glue's serializer also checks each record before it is sent (author-51), as this client checks each row (K2), though Glue throws where this client counts | A registry the producer must reach (K8) | Informs |
| C11 Iceberg | Field ids, never handed out twice; read by id; a v3 writer fails a required field with no default | Changes "independent and free of side-effects" without rewriting files (ids-10 to -13) | Data that outlives the definition it was written under (K5) | Iceberg is the final table, where columns are renamed, dropped and re-added. This client writes one run's rows under one definition, and the specification does not rename a column within a run | Informs open question 13 |
| C12 Protocol Buffers | Field numbers; "should never be reused"; `reserved` | The wire format cannot tell definitions apart (ids-26, -27) | None stated by the specification: the on-disk form is private (K4), and the hand-over names columns (K5) | A wire format without names | Informs open question 13 |
| C13 Thrift, Parquet `field_id` | Ids for versioning; fbthrift states a never-reuse rule | Staged rollouts and old data (ids-35, -36) | Staged rollouts (K7) | As C12 | Informs |
| C14 Delta column mapping | Ids and physical names, so rename and drop need no rewrite | Rename and drop without rewriting (ids-48, ids-53); cheap deletion in `name` mode from unique physical names, where ids do not resolve columns (ids-52, author-108) | None at the client | A final table with many writers over time | Informs open question 13 |
| C15 Avro container files | The writer's schema in each file; the reader resolves it against its own | Data stays readable after the application's schema changes (ids-77, ids-64); a hash per entry where many versions share a store (ids-78, author-35) | Each run's data is read later, possibly after the application's definitions have changed, and the hand-over carries each run's definitions (K5) | The reasons tied to Avro's binary encoding (ids-57) depend on an on-disk form, which is private here (K4) | **Justifies** carrying each run's definitions with its rows to whoever reads them, which the hand-over does (K5). For the local databases themselves it fits only where they are read after the process that wrote them has gone or its definitions have changed. The specification does not say whether a run's hand-over can be served then, and what establish does with an earlier run's databases is open question 6 |
| C16 Parquet footers, SQLite | Each file carries its schema | None found | As C15 | No stated reason | Informs |
| C17 OpenTelemetry global provider | Instruments created before the provider: rewired in Go and Python, measurements in between lost; never rewired in Java | Third-party libraries use the API before the SDK (otel-46, otel-47); globals spare a large code base from passing providers around (otel-113); Java: a late registration should be loud (otel-69) | A library used before it is configured, if tables are declared before establish (K10) | Third-party libraries instrumenting with no configuration at all. The specification has a developer declare against a confluence created at global scope; it does not say whether libraries declare their own tables | Informs |
| C18 Micrometer | Meters created on demand; a conflicting type refused; filters meant to come first | "you have no choice" when tags come from local context (late-4); a late filter is "potentially hard to notice" (late-9) | Configuration that should come before the first use (K10's start-up) | A meter's identity includes its tags, which are known only at the call. A table's identity is its namespace and name, and the tenant is a write parameter, so nothing about a table is known only at the call | Informs |
| C19 Rust `metrics` | Emit at any time; a no-op before the recorder; registration optional and late by construction | Libraries instrument freely at low cost (late-25); registration must follow the recorder (late-31, late-32) | A facade used by libraries (K9's Rust side) | As C17: whether libraries declare tables is not stated | Informs |
| C20 .NET | Instruments at any time; differing ones kept side by side | Caching identical instruments prevents re-creation (author-80); none for keeping differing ones | None | No stated reason for the side-by-side rule | Informs |
| C21 Hibernate | Mapping fixed when the factory is built | None found for the fixing | A definition shared by many threads (K1's write path) | No stated reason. Its model is a graph of related entities; tables here have no relations | Informs |
| C22 Entity Framework Core | Model built on first use, cached per key | "for performance reasons" (late-76) | None | Caching explains building once, not building early | Informs |
| C23 grpc-go | Fatal on a late registration | No lock on the handler map's read path (late-68) | Only conditionally. A write must never block (K1). Whether a write reaches its table through a shared structure is not stated: the write is given its table (`ApplicationWrites(app, handle, table, values, tenant?)`), and how the client reaches a table declared while writes run (`OpenCountersForLateTable`) is left unspecified | grpc-go offered to reconsider for a real use case (late-69); its read path serves a network server, not a bounded in-process queue | Informs. It names a cost a late declaration could put on a write path that reads shared state on every write |
| C24 Django | Applications fixed at start-up; models accepted later | A deterministic load (late-51); the ORM needs every model (late-50) | None | Its reason is relations between models; tables here have none | Informs |
| C25 SQLAlchemy | Tables defined at any time; a second definition with arguments refused unless told otherwise | Why the two flags exist (late-64); none for the default | Declaring at any time (K10) | It does not compare definitions at all; the specification compares them (K3). The difference is described, not judged | Informs |
| C26 Delta schema enforcement | A batch write that does not fit refused whole; other paths cast; schema changed only by choice | "stop these enemies at the gates" (typed-4); change only by "affirmative choice" (typed-5) | Refusing what does not fit (K2) | It is the final table, refusing per transaction; this client refuses per row and converts nothing | Informs the fairness question |
| C27 Elasticsearch | Refuses a value it cannot coerce; per-index mappings; a failure store for logs | No change in place (typed-18); "To avoid dropping data silently" (typed-25) | Typed fields refused when they do not fit (K2) | It coerces by default; the specification converts nothing. Conflicts across indices are met at query time, downstream | Informs the fairness question |
| C28 InfluxDB | A field's type fixed per shard; conflicts across shards kept and coerced or left out at query | Partial writes, so a retried batch does not "continually fail forever" (typed-47); add-only in explicit mode (typed-60) | Definitions per partition, as a run's here (K4) | Its shards are one database's; the conflict is met at query time, downstream | Informs the fairness question |
| C29 BigQuery | Whole request refused by default; no new required column | Existing rows would be NULL (author-50) | Required columns (K2) | A service-side table | Informs |
| C30 Mimir | Conflicting metadata kept as a set | Metadata "can come from multiple targets" (typed-67) | None at the client | Downstream | Informs, for the collector |

## Whether the comparison is fair

The ticket asks whether the reasons a metrics library gives carry over to a table with typed columns, some required, where a row that does not fit is refused whole. The answer below is the researcher's, built from the sections above.

**What a metric is to these libraries.** A Prometheus series is identified by its name and labels; type, help and unit are not part of that identity (prometheus-43), and its authors call metadata something that "can change over time" without changing the series (prometheus-55). An OpenTelemetry metric's identity takes in its Resource, Scope, name, type and unit (otel-1), and a conflict within one Resource and Scope is passed through (otel-3). In both, a sample is a number with labels, and the definition that may disagree between writers is mostly metadata around it.

**What a table is here.** A definition fixes which columns a row has, their types and which are required, and a row that does not fit is refused whole, with nothing converted (K2). A change between runs can change what a row is: a column added, dropped, made required or given another type.

**The reasons that carry over.** Two kinds of reason given by the metric libraries are about the deployment, not the data, and carry over to tables unchanged:

- **Where a check can be made.** beorn7 says Prometheus "cannot prevent" a metric's labels from changing "globally", and that a library can guarantee them "over the lifetime of a binary" (prometheus-17). He gives no reason for "cannot". Inferred: the limit is what a library can reach. client_python's multiprocess mode reads files that other processes wrote to a shared directory and still checks nothing across them (C1), so the limit is not one process as such. This client's runs on other instances are out of reach (K7, a leaning). Successive runs of one confluence, where the specification allows them (Derived), share one set of declarations and are already checked (K3). A run in a new process that follows another at the same location is not out of reach, and can see what the earlier run left (K6).
- **Disagreement during a rollout is normal.** bboreham's "multiple replicas of the same target are mid-way through a software update" (prometheus-59) describes what K7 implies for an ephemeral pod, which is a leaning.

**The reasons that stop short.** Three do not carry over to typed tables:

- **Metadata is advisory.** Prometheus can let help and type differ because a series is still its name and labels (prometheus-55). A table's columns are not advisory: they decide whether a row is kept (K2).
- **Passing the ambiguity downstream moves its cost.** OpenTelemetry passes a conflict along as "a compromise to make the SDK simpler" and lets a consumer reject it (otel-28, otel-4). Its authors do not call that cheap. jmacd kept the warning because it "will generate errors for certain metric-type-aware vendors" (otel-29), and the back end he speaks for keeps the first type it saw and reports an error for the rest (otel-30, otel-31):

  Source: https://github.com/open-telemetry/opentelemetry-specification/issues/2226#issuecomment-1027490180 (quoted as author-123)

  > Errors will result when the SDK "passes along" the ambiguity described above to Lightstep.

  The data model also lets a producer convert units (author-9) or temporality:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/data-model.md#L331-L335 (quoted as author-124)

  > an implementation MAY convert temporality using a
  >    Cumulative-to-Delta or a Delta-to-Cumulative transformation;

  So even for a stream of numbers, a consumer may have to reconcile or reject a stream whose identifying properties disagree. For a table, what conflicts is which columns a row has, their types and which are required, and whatever reads several runs' rows must decide how to read rows whose columns differ. That falls to a collector this specification excludes (K5). That it is a harder problem than a metric back end's is the researcher's reading.
- **A sample has little that can fail to fit.** The metric libraries do check a measurement against its definition, and refuse it alone. client_python's `labels()` raises `ValueError` for label names or a label count that differ from the metric's, and converts each label value to a string (author-92, author-93); client_golang returns an error for a wrong number of label values (author-121), and its `WithLabelValues` panics where that form would fail (author-96). Both clients refuse a negative increment to a counter (author-94, author-95, author-120), and OpenTelemetry Go's exponential histogram ignores NaN and infinity (author-122). A label-count check resembles the specification's refusal of a missing or unknown column, for label values that are all strings. No metric library read refuses a sample for a missing required field or a value of the wrong type, and a sample has neither. This client refuses rows against their own run's definition, so within a run nothing disagrees, and the disagreement exists only between runs.

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/metrics.py#L174-L180 (quoted as author-92, author-93)

  > if sorted(labelkwargs) != sorted(self._labelnames):
  >                 raise ValueError('Incorrect label names')

  > if len(labelvalues) != len(self._labelnames):
  >                 raise ValueError('Incorrect label count')
  >             str_labelvalues = tuple(str(l) for l in labelvalues)

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/metrics.py#L340-L341 (quoted as author-94)

  > raise ValueError('Counters can only be incremented by non-negative amounts.')

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go#L241-L242 (quoted as author-121)

  > An error is returned if the number of label values is not the same as the
  > 	// number of variable labels in Desc (minus any curried labels).

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go#L42-L43 (quoted as author-120)

  > Add adds the given value to the counter. It panics if the value is <
  > 	// 0.

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go#L127-L129 (quoted as author-95)

  > panic(errors.New("counter cannot decrease in value"))

  Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go#L278-L279 (quoted as author-96)

  > // WithLabelValues works as GetMetricWithLabelValues, but panics where
  > // GetMetricWithLabelValues would have returned an error.

  Source: https://github.com/open-telemetry/opentelemetry-go/blob/v1.47.0/sdk/metric/internal/aggregate/exponential_histogram.go#L336 (quoted as author-122)

  > // Ignore NaN and infinity.

**What the typed stores show.** The comparables with typed columns refuse at the store a write that does not fit the store's one current definition: Delta (C26), Elasticsearch within an index (C27), InfluxDB within a shard (C28), BigQuery (C29), and an Iceberg v3 writer (C11). Where they keep definitions per partition, they meet the disagreement when data is read: Elasticsearch across indices (typed-33), InfluxDB across shards, where a default query leaves out values of other types and a user's query was cut short at a shard boundary (author-45, typed-54, typed-55), and Avro across files, where a reader-only field with no default is an error (ids-62). A run's local databases here are such a partition, each with its own definitions (K4, K5). Within a run, the client refuses a row that does not fit its run's definition before storing it (K2), as these stores refuse a write that does not fit their current definition, so they inform that admission check too. Across runs the client reconciles nothing: rows written under different definitions meet wherever several runs' rows are read, downstream of the collector, which the specification excludes (K5). Three differences limit even this comparison:

- Elasticsearch coerces by default (author-42, author-43), and Delta casts on some write paths (author-65, author-68); this client converts nothing (K2).
- Delta refuses a transaction; this client refuses a row.
- SQLAlchemy refuses a second definition without comparing it (C25); this client compares (K3).

**Conclusion of the fairness argument.** Metric libraries are a fair comparable for where a check can be made and for disagreement during a rollout. They stop short of what a disagreement costs. Their authors move that cost downstream, where a type-aware consumer may raise errors or reject the data (otel-29, author-123, otel-4), and what disagrees is a stream's type, unit or help, not the shape of a row. For that cost, the typed stores and Avro are the closer comparables, and they place it at the reader.

## Verdicts on the two behaviours

### Nothing enforced across runs

**Verdict: it rests on a stated why that does not transfer, for part of what it covers.**

The guarantee has two sentences, and they rest on different reasons.

- **"The client enforces nothing about a definition that changed between runs."**
  - The stated why is Prometheus's. beorn7, on client_golang's pre-defined collectors, says labels that "suddenly appear or disappear" confuse PromQL users, that "We cannot prevent that from happening globally", and that a library can guarantee it "over the lifetime of a binary" (prometheus-17). He gives no reason for "cannot". That the limit is what a library can reach is Inferred, and client_python's multiprocess mode reaches other processes' files in a shared directory (C1).
  - Its limit transfers to runs the client cannot reach: other instances, and two runs live at once during a rollout (K7, a leaning). There it fits, by the researcher's argument, and it **justifies** checking nothing against those runs, so that for them the check stops at the confluence (K3).
  - It does not reach successive runs of one confluence, which the specification allows as Derived (the comment above `EstablishProductionCore`). They share the confluence's declarations (`rule AttachRun`), so a definition changed between them fails loudly as a redeclaration (K3). The guarantee's "enforces nothing" does not mention that case.
  - It does not transfer to a run in a new process that follows another at the same location. That run can see the databases the earlier one left (K6), so "cannot" does not hold.
  - No comparable states a reason for not checking what an earlier run left. client_python's multiprocess directory is the nearest case, and its documentation says only that the directory must be wiped between runs (prometheus-37), with no stated rationale (C1).
  - OpenTelemetry's reasons concern one process or one stream (C4). They inform this sentence and do not justify it.
- **"Each run's local databases carry the definitions they were written with."**
  - This rests on a stated why that fits: Avro stores the writer's schema with the data so that "later, even if the schema in your application has changed, you can still read that data" (ids-77).
  - Snowplow gives the same reason for each payload naming its schema (registries-5 to -7).
  - The hand-over carries each run's definitions with its rows (K5), so the reason applies through what is transmitted, whatever the on-disk form is.
  - For the local databases themselves, the reason fits where they are read after the process that wrote them has gone, or after its definitions have changed. The specification does not say whether a run's hand-over can be served then, and what establish does with an earlier run's databases is open question 6. This file judges neither.

**Question for the maintainer.** `NothingAcrossRuns` says the client enforces nothing about a definition that changed between runs. Where one confluence holds successive runs (Derived), `rule DeclareTable` refuses a changed redeclaration in a later run. Should the guarantee name only runs in other processes, or is that check meant to sit outside it as worded?

**Proposed wording for the maintainer.** It keeps the behaviour. It states what each comparable is cited for, and points the case it does not cover at open question 6, without answering it. It leaves the case of successive runs of one confluence to the question above. Its `@guidance` and the one proposed under "Declare at any time, usable at once" are two parts of the one `@guidance` of `surface Declaring`; they share the sentence on open question 13, which would appear once.

```text
    @guarantee NothingAcrossRuns
        -- The client enforces nothing about a definition that changed
        -- between runs. Each run's local databases carry the definitions
        -- they were written with, and the hand-over carries them with the
        -- rows.

    @guidance
        -- Checking only within the confluence follows Prometheus's
        -- client libraries, whose maintainer says a metric's labels can be
        -- kept consistent over the lifetime of a binary and cannot be kept
        -- so globally; a run cannot see another instance's run. Carrying each run's definitions follows Avro's
        -- reason for storing the writer's schema with the data: rows are
        -- read after the application's definitions may have changed. A
        -- run that follows another at the same location could see the
        -- definitions the earlier run left; what establish does with them
        -- is open question 6, and no comparable states a reason for
        -- leaving them unchecked. Whether a declaration should carry a
        -- version or a definition hash is open question 13.
```

### Declare at any time, usable at once

**Verdict: it rests on a stated why that does not transfer.** The behaviour is the norm for the telemetry libraries read: Prometheus's clients, OpenTelemetry's SDKs, Micrometer, the Rust `metrics` crate and .NET all create a metric at any time (C1, C17 to C20). So the claim that it is common is confirmed. The reasons found are of three kinds. Each bears on a different behaviour, and none is shown to hold for this client:

- **A metric's identity is known only at the call.** Micrometer: "you have no choice" when tags come from local context (late-4). A table's identity is its namespace and name, fixed in its declaration, and the tenant is a parameter of the write (K2), so this reason does not transfer.
- **Libraries instrument code they do not configure.** OTEP 0005 expects third-party libraries to use the API before the SDK is installed (otel-46, otel-47), and the Rust `metrics` crate lets libraries instrument at low cost while no recorder is installed (late-25). Both concern use before configuration, which here would be a declaration before establish, not one during a run. This transfers only if libraries declare tables of their own. The specification has a developer declare against a confluence and does not say whether a library may.
- **Instruments are created throughout a program's life.** jack-berg gives this as the reason a duplicate must not raise an error (otel-25). It is a reason about the failure posture of a late conflict, not about allowing a late declaration, and the posture is ticket 16's.

**Usable at once has no stated why of its own.** The reasons above concern when a metric may be created. None of the sources read gives a reason for a metric created after its provider or registry is in place being usable at once. Micrometer's (late-4) entails it, since a meter built inside a method body records there; that reading is the researcher's. What the sources state is the earlier case, the loss before configuration: "There may be loss of metrics at startup" (otel-48), and in Micrometer's documentation:

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/docs/modules/ROOT/pages/concepts/registry.adoc#L37 (quoted as author-125)

> Recordings have no effect until there is a non-composite registry in the composite.

That case is the specification's write with no run in force, which is discarded and counted (`DiscardWriteWithoutRun`). It is not a table declared during a run.

Prometheus states no reason for allowing late registration (C1). The comparables that fix definitions at start-up do not bear on this either way. Only grpc-go states a reason, a read path with no lock (late-68), and Hibernate's fixing has none found (C21). grpc-go's reason names a cost that would apply here only if writes reached their table through a shared structure that a late declaration changes. That structure would have to tolerate a table added while writes run, and writes must still never block (K1). The specification gives each write its table (`ApplicationWrites(app, handle, table, values, tenant?)`), and a table declared during a run adds its counters while writes run (`OpenCountersForLateTable`); it does not say how the client reaches either. That is the researcher's reading, not a finding about this client's design.

**A tension in the specification's own guidance.** It gives the reason declaring may fail loudly as "it runs at start-up, where the developer can see it". A table declared during a run is not declared at start-up. A late declaration that conflicts with an earlier one still fails loudly (K3). That reason does not cover it. OpenTelemetry's reversal in 2022 was made for a similar case: an error at instrument creation, which jack-berg described as a crash at run time, "days" after start (otel-25). Here a refused declaration is "an exception in Python, an error result in Rust, never a panic" (`LoudFailure`), so whether it ends the host depends on how the host handles it (Inferred). Whether a late conflict should fail loudly is the failure posture, which ticket 16 researches. This file puts it as a question and does not answer it.

**Question for the maintainer.** Should the reason given for a loud failure at declaration cover a table declared during a run, or should ticket 16 take up that case with the rest of the failure posture?

**Proposed wording for the maintainer.** It keeps the behaviour and marks what the comparables do as informing it, not justifying it. The first comment replaces only the first sentence of the comment above `rule DeclareTable`; that comment's other sentences stay as they are, its "Derived" marker among them. The comment above `rule OpenCountersForLateTable`, "A table declared while a run is in force is usable at once.", is unchanged. The `@guidance` here is the second part of the one proposed under "Nothing enforced across runs".

```text
-- A table may be declared at any time, with or without a run in force.
-- Telemetry libraries do the same: Prometheus's clients, OpenTelemetry's
-- SDKs, Micrometer, the Rust metrics crate and .NET create a metric at any
-- time. That informs this rule and does not justify it: their reasons are
-- metric identities known only at the call, and libraries that instrument
-- code they do not configure, and neither is shown to hold for a table.

    @guidance
        -- Declaring is expected at start-up, where a loud failure is
        -- seen. A declaration during a run that conflicts with an earlier
        -- one also fails loudly, while the host is running; whether it
        -- should is part of the failure posture, which is still being
        -- researched. Whether a
        -- declaration should carry a version or a definition hash is open
        -- question 13.
```

## What the findings bear on in the specification

This section reports. It decides nothing, and recommends no answer to either question.

### Open question 13: a version or a definition hash, and stable column ids

The evidence touches each part of the question, and each mechanism comes with the reason its authors gave and a cost:

- **A declared version.**
  - Snowplow ties a version to each payload so that data stays readable "when we come back to a folder full of our JSONs" (registries-5). It asks each version to be treated as immutable (registries-26).
  - OpenTelemetry's schema URL versions conventions shared by many producers, for translation, not validation (C7).
  - The cost Snowplow documents is that validation and recovery happen downstream (registries-21, registries-31).
- **A definition hash.**
  - Avro's author suggested a hash of the schema per stored entry where many versions share one store (ids-78).
  - Avro's single-object encoding specifies a fingerprint for that case. Its stated cost is that a reader must resolve the fingerprint through some store of schemas (author-35, author-37).
- **Stable column ids.**
  - Iceberg gives each column an id that is never handed out again, so that adding a column never reads another column's values and dropping one changes no other, without rewriting files (ids-11 to -13, ids-6).
  - Protocol Buffers forbids reusing a number because its wire format cannot tell two definitions apart (ids-26, ids-27). fbthrift states the same rule (author-28).
  - Delta added column mapping, a physical name and an id for each column, so that rename and drop need no rewrite (ids-48, ids-53). The commit that added it ties cheap deletion in `name` mode to unique physical names (ids-52), and in that mode ids do not resolve columns (author-108); readers resolve by id in `id` mode (C14).
  - Each is a format where the same data is read under several definitions over time, or a wire format without names.
  - Their stated costs: an Iceberg field deletion "cannot be rolled back unless the field was nullable or if the current snapshot has not changed" (ids-4). A contributor reports that a dropped column's data cannot be recovered except from an old snapshot, because a column added again gets a new id (ids-19), and another replied that reverting the current schema id should restore it (ids-20). A third party reports a sink that "matched input against a historical schema and silently wrote nulls" after a column was dropped and added again, without saying how it chose that schema (ids-22). Protocol Buffers' protection is advisory, covers only what a developer lists as `reserved`, and works at compile time, except that the C++ and Go TextProto parsers may discard a field with a reserved name (author-27). Delta's column-mapping page calls enabling it irreversible, while its feature-removal page and its code at the same release let it be dropped, rewriting data files where needed (C14).
- **What the specification already has.** The hand-over carries each run's full definition, with column names and types, beside the rows (K5). Whether a collector or a final store would need a version, a hash or ids beyond that depends on what happens downstream, which the specification excludes. This file does not judge it.

### Open question 20: what makes a declaration valid

The research was not aimed at this question, and found only incidental evidence:

- **An identical redeclaration**, which the specification returns as the existing table (K3), is handled in several ways:
  - client_golang returns `AlreadyRegisteredError` with the existing collector, so the caller can use it:

    Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/registry.go#L202-L204 (quoted as prometheus-12)

    > This can be used to
    > // find out if an equal Collector has been registered before and switch over to
    > // using the old one, as demonstrated in the example.

  - client_python raises even for an identical definition (C1);
  - OpenTelemetry returns a working instrument (C4);
  - SQLAlchemy returns the existing table when no arguments are given and refuses one given with arguments (C25);
  - grpc-go ends the process on any duplicate (C23).
- **Names that differ only in case.** OpenTelemetry's instrument names are case-insensitive. Where an SDK represents a name in a case-sensitive encoding, two casings make a duplicate registration, and the instrument returned uses the first name seen:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/api.md (quoted as otel-14)

  > * They are case-insensitive, ASCII strings.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md (quoted as otel-19)

  > When this happens, the Meter MUST return
  > an instrument using the first-seen instrument name and log an appropriate error
  > as described above.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md#L1046-L1049 (quoted as author-109)

  > If an SDK uses a case-sensitive encoding to represent this
  > `name`, a duplicate instrument registration will occur when a user passes
  > multiple casings of the same `name`.
- **A name that collides with one the library adds itself**, which bears on "a column name that collides with a field the client adds". client_python's registry checks the names a metric "produces and clashes with", including the suffixes it derives from the type, such as `_total`:

  Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/registry.py#L67-L85 (quoted as author-90, author-91)

  > """Get names of timeseries the collector produces and clashes with."""

  > 'counter': ['_total', '_created'],

- **Reserved names.** Protocol Buffers lets a developer list retired names and numbers as `reserved`, and the compiler then refuses their reuse. For numbers that check is at compile time only. For names there is one exception: the C++ and Go TextProto parsers may discard an unknown field with a reserved name at parse time (author-27, C12).

None of this was surveyed for its why on validity rules. It informs, and nothing in it bears on which columns may form a key.
