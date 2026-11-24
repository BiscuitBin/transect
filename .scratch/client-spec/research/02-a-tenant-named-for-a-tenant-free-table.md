# Research: a tenant named for a tenant-free table

- **Ticket:** `issues/02-research-a-tenant-named-for-a-tenant-free-table.md`, open question 19 of `docs/specs/transect-client.allium`.
- **Sources read:** every source on 2026-11-24 (UTC), which was 2026-11-23 in the researcher's local time.
- **Web research:** authorised by the maintainer on 2026-11-23 for this ticket, for the agent working it and for its reviewers.
- **State of this file:** findings only. Fit, which behaviour surprises least, the options, the recommendation and the proposed wording are not written yet: they follow the first adversarial review, as `REVIEW.md` requires.

## How the sources were checked

Two survey agents found the candidates and saved raw text. The author then fetched every cited source again, independently: source and documentation files at a pinned tag or commit through `raw.githubusercontent.com`, issue, pull request and commit text through the GitHub REST API, Jira through its REST API, and the two vendor documentation pages as HTML with the tags stripped. Each quotation below was then checked by machine as a substring of that text. Every quotation matched character for character, except three that match only once line breaks and indentation are collapsed. Those three are marked "(line breaks collapsed)", and their wording is verbatim.

A quotation from source code keeps the comment markers and indentation it has in the file.

## The shape being looked for

The question is about one write that **names** a tenant itself, for a table **declared** tenant-free. Each comparable is classified on two axes.

- **Named or ambient.** Named: the write call itself carries the scope, as a parameter, a header, a clause or a field. Ambient: the scope comes from the surrounding context, such as a session, a connection or a deployment setting. The ticket settles the ambient case: a handle's bound tenant is simply not applied to a tenant-free table.
- **Scope-like or unknown-field-like.** Scope-like: the thing named is a tenant, namespace, partition or routing key. Unknown-field-like: an undeclared column, label, attribute or field. The specification already settles that a row with an unknown column is refused whole, so an unknown-field comparable bears on the question only if a named tenant is treated as row content.

Some comparables are a different shape again: a named tenant that **conflicts** with the ambient tenant on a tenant-**scoped** target. They are labelled that way.

---

## System level

### S1. Kubernetes API server: a namespace on a cluster-scoped object

**Shape.** Named and scope-like, the closest match found. A cluster-scoped kind, such as `ClusterRole` or `Node`, is declared without a namespace. A write can name one in three places, and each is handled differently.

**What it does.** Read at tag `v1.37.2`.

- **In the request body** (`metadata.namespace`): the namespace is **cleared and the object stored**, with no error and no warning.
  - `BeforeCreate` calls `EnsureObjectNamespaceMatchesRequestNamespace` with the namespace expected for the scope. For a cluster-scoped kind that is empty, and the function clears the field.
  - The same function **rejects** a namespaced object whose body namespace differs from the request's. So the server rejects a namespace that conflicts with the target's scope, and drops one the target has no use for.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apiserver/pkg/registry/rest/meta.go

  > // cluster-scoped, clear namespace

  > return errors.NewBadRequest("the namespace of the provided object does not match the namespace sent on the request")

- **Validation would reject it, but runs too late.** Object-meta validation has a rule against a namespace on a cluster-scoped kind. `BeforeCreate` calls validation (`ValidateCreate`, `create.go` line 130) only after the clear (line 124), so on the API path the rule cannot fire. That conclusion comes from the call order and was not executed.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apimachinery/pkg/api/validation/objectmeta.go

  > allErrs = append(allErrs, field.Forbidden(fldPath.Child("namespace"), "not allowed on this type"))

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apiserver/pkg/registry/rest/create.go

  > // ensure namespace on the object is correct, or error if a conflicting namespace was set in the object

- **In the URL path** (`/api/v1/namespaces/x/nodes`): **not routed.** The route installer registers cluster-scoped kinds only at the non-namespaced path, so the request gets a not-found response. That is inferred from the installer, and a user report agrees.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/apiserver/pkg/endpoints/installer.go

  > // Handle non-namespace scoped resources like nodes.

  Source: https://github.com/kubernetes/kubernetes/issues/111248

  > the server could not find the requested resource

- **Through `kubectl -n`**: the namespace is **dropped in the client**, before any request is sent.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/cli-runtime/pkg/resource/visitor.go

  > // FilterNamespace omits the namespace if the object is not namespace scoped

**Visible?** Nothing for the body and the flag; an error for the URL path. Kubernetes has a warning mechanism for creates (`WarningsOnCreate`), and this case does not use it.

**Stated why.** No stated rationale found for clearing the field.

- The clear dates to commit `e485dc93`, 2015-02-02. Its message gives no reason, and the pull request it belongs to (#3789, "Generate names automatically when requested") does not discuss namespaces on cluster-scoped objects.

  Source: https://github.com/kubernetes/kubernetes/commit/e485dc93cab272b242f869420c88c342a424e322

  > Minions should have common logic with create

- Pull request #94637 (merged 2022-02-23) kept the clear and moved it before admission. Its stated reason concerns the order of the check, not the clear.

  Source: https://github.com/kubernetes/kubernetes/pull/94637

  > Ensures the namespace population/check that occurs before an object is persisted is done before it is sent to admission. This ensures the namespace in the object matches the request namespace attribute.

- Also searched, with nothing found: GitHub issue searches on `kubernetes/kubernetes` and `kubernetes/kubectl` for a namespace set, ignored or warned about on a cluster-scoped resource, and issue #88282, which the pull request cross-references.

For the URL path there is a maintainer's answer, given when the 404 was reported: the client should decide.

Source: https://github.com/kubernetes/kubernetes/issues/111248#issuecomment-2977588089

> You can use the discovery client to determine if the desired group/version/kind is namespaced or not. That's what kubectl does to decide whether to include the specified namespace in the lookup request.

**Inferred why.** Inferred: `kubectl` sets a namespace on every object it sends, so rejecting one on a cluster-scoped kind would have broken mixed manifests applied with `-n`. The client filters the namespace out itself, though, so this is at most a historical reason. No source states it.

**Constraints.**

- Every kind's scope can be discovered (`APIResource.Namespaced`), so the client and the server both know the target is scope-free.
- The API is shared by many clients and controllers.
- A conflicting namespace on a namespaced kind is a security concern (a write landing in the wrong namespace), and that is the case Kubernetes rejects.

  Source: https://github.com/kubernetes/kubernetes/blob/v1.37.2/staging/src/k8s.io/cli-runtime/pkg/resource/visitor.go

  > // value, returns an error. This is intended to guard against administrators

  > // accidentally operating on resources outside their namespace.

**Costs and dissent.**

- A reviewer on pull request #94637 was surprised the clear existed.

  Source: https://github.com/kubernetes/kubernetes/pull/94637#discussion_r813330248

  > interesting.  We used to clear this?

  Source: https://github.com/kubernetes/kubernetes/pull/94637#discussion_r813332393

  > so we did.  weird.

- A downstream tool's maintainers called the silent acceptance a flaw, and said it should be an error. This is a Pulumi maintainer's view, not a Kubernetes author's.

  Source: https://github.com/pulumi/pulumi-kubernetes/issues/515

  > Overly broad transformations can erroneously set the namespace for non-namespaceable resource Kinds. While this doesn't prevent the resource from being created, it can force an unnecessary replacement if this ignored field is changed later.

  Source: https://github.com/pulumi/pulumi-kubernetes/issues/515#issuecomment-511088289

  > I think we should _not_ do this for Q3, since this is a flaw the underlying k8s API has as well (_i.e._, k8s will happily accept resources with `.metadata.namespace` set, but which are not namespaced).

  Source: https://github.com/pulumi/pulumi-kubernetes/issues/415#issuecomment-478166619

  > When we solve this problem, we should make consider erroring out when people try to set the namespace of a resource that is not namespaced. This leads to all sorts of annoying problems if it is silently accepted.

- controller-runtime made its cache ignore a namespace on a cluster-scoped read, for consistency with the direct client. This is a read path, so the analogy is looser.

  Source: https://github.com/kubernetes-sigs/controller-runtime/pull/1326

  > When fetching a cluster-scoped resource via the cache, the namespace key is ignored, just like with a direct client. The APIReader and Cache behavior should be consistent.

### S2. Grafana Mimir and Loki (and Cortex) with multi-tenancy off

**Shape.** Named (the push carries an `X-Scope-OrgID` header) and scope-like (a tenant). The scope-free declaration is deployment-wide (`-auth.multitenancy-enabled=false` in Mimir, `auth_enabled: false` in Loki), not per target, so this is looser than S1: the whole cluster is the "table".

**What it does.** The push is **stored under a substitute tenant, and the header is never read**: `anonymous` in Mimir, `fake` in Loki. No error, log line or metric for the ignored header was found in the source read.

Mimir, at `mimir-3.2.6`:

Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/pkg/mimir/mimir.go

> When set to true, incoming HTTP requests must specify tenant ID in HTTP X-Scope-OrgId header. When set to false, tenant ID from -auth.no-auth-tenant is used instead.

Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/pkg/util/noauth/no_auth.go

> ctx := user.InjectOrgID(r.Context(), noMultitenancyTenant)

Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/docs/sources/mimir/manage/secure/authentication-and-authorization.md

> After you disable multi-tenancy, Grafana Mimir components internally set the tenant ID to the string `anonymous` for every request.

Loki, at `v3.7.10`. The docs say only that the header is "not required". The code shows it is not read: the outer handler branches on the setting before any header is read, and reads the header only in the other branch.

Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/operations/multi-tenancy.md

> The `X-Scope-OrgID` header is not required in Loki API requests.

> The single tenant ID will be the string `fake`.

Source: https://github.com/grafana/loki/blob/v3.7.10/pkg/loki/modules.go

> if !t.Cfg.AuthEnabled {

> next.ServeHTTP(w, r.WithContext(user.InjectOrgID(r.Context(), "fake")))

- **Unverified at the tag:** that no other part of Mimir's push path reads the header. A code search on the default branch found direct reads only off the push path.
- **Unverified:** Cortex `v1.22.0` has the same middleware, but only the middleware was read. Tempo has the same switch, but none of its source was read.

**Stated why.** The code comment, identical in Cortex and Loki, gives the reason for the substitute tenant: single-tenant mode is a shim, and the internals always run multi-tenant.

Source: https://github.com/cortexproject/cortex/blob/v1.22.0/pkg/util/fakeauth/fake_auth.go

> // Package fakeauth provides middlewares that injects a fake userID, so the rest of the code
> // can continue to be multitenant.

Loki's current default branch says the same in other words.

Source: https://github.com/grafana/loki/blob/c1ab23aede2bbb78f92fde4effc01eb0288a6691/pkg/util/fakeauth/fake_auth.go

> // request so downstream code can assume a tenant is always present.

No stated rationale was found for ignoring a header that is *present* in this mode, rather than rejecting or honouring it. Searched: Mimir pull requests #1063 and #1130, Mimir issue #276, Tempo issue #495, and Loki and Mimir issue searches for "X-Scope-OrgID" and "multitenancy_enabled false".

**Constraints.**

- The tenant travels in a header, not in the payload. An authenticating reverse proxy is expected to set it.
- Single-tenant mode exists so that a small install needs no proxy.
- The authors themselves describe the setting as a tenancy switch, not an authentication switch.

  Source: https://github.com/grafana/mimir/issues/276

  > The `auth_enabled` setting is confusing because it does not actually enable authentication, it more accurately enables multi-tenancy. It's only purpose (from what I can tell) is to inject a "fake" org ID when set to `false`.

**Costs and dissent.**

- Mimir renamed the substitute tenant and made it configurable.

  Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/CHANGELOG.md

  > * [CHANGE] Default tenant ID used with disabled auth (`-auth.multitenancy-enabled=false`) has changed from `fake` to `anonymous`. This tenant ID can now be changed with `-auth.no-auth-tenant` option. #1063

- The same issue proposed removing the switch altogether, with a proxy always supplying the header. The switch was renamed (pull request #1130) and kept.

  Source: https://github.com/grafana/mimir/issues/276

  > * Idea one: remove the setting entirely. Mimir always requires the org ID header to be set. Users that want to run without tenants or authentication can have a proxy inject the header before sending a request to Mimir.

- No complaint about a present header being ignored in this mode was found.

### S3. Elasticsearch time-series data streams: an explicit routing value

**Shape.** Named (a request parameter) and scope-like: `routing` chooses the shard, a per-write partition key. A time-series (TSDS) index declares that it derives routing from the document's dimensions and takes no custom routing.

**What it does.** **Rejects the write** with an `IllegalArgumentException` naming the operation, the index and its mode. Read at tag `v9.5.7`. The check `checkNoRouting(indexRequest.routing())` runs when a document is indexed, and also on delete and get.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/server/src/main/java/org/elasticsearch/cluster/routing/IndexRouting.java

> throw new IllegalArgumentException(error("specifying routing"));

> return operation + " is not supported because the destination index [" + indexName + "] is in " + indexMode.getName() + " mode";

The documentation, at tag `v8.19.0`, states the rule:

Source: https://github.com/elastic/elasticsearch/blob/v8.19.0/docs/reference/data-streams/tsds.asciidoc

> TSDS documents don't support a custom `_routing` value. Similarly, you can't

**Stated why.** No stated rationale found beyond the documentation's statement of the rule. Searched: GitHub pull request searches for "routing_path", "TSDB routing_path" and "specifying routing is not supported", and one web search.

**Inferred why.** Inferred: in a TSDS, routing is a function of the dimensions (`index.routing_path`). A caller-supplied routing value would put one time series on two shards, so the named scope would *conflict* with a declared derivation, not merely go unused.

**Constraints.** Routing is derived from the data. A wrong routing value would silently split a series across shards.

**Costs and dissent.** None found in the sources read.

### S4. Spark SQL: `INSERT ... PARTITION (...)` into a non-partitioned table

**Shape.** Named (a clause of the statement) and scope-like (a partition). The target is declared without partitions.

**What it does.** **Rejected at analysis.** This was traced through the source at tag `v4.3.0` and not executed.

- `PreprocessTableInsertion` normalises the statement's partition spec against the table's own partition columns, which are none for a non-partitioned table.
- Each key in the spec is then not found, and an error is thrown.
- Only the v1 `InsertIntoStatement` path was traced. DataSource V2 tables were not.

Source: https://github.com/apache/spark/blob/v4.3.0/sql/catalyst/src/main/scala/org/apache/spark/sql/util/PartitioningUtils.scala

> throw QueryCompilationErrors.invalidPartitionColumnKeyInTableError(key, tblName)

Source: https://github.com/apache/spark/blob/v4.3.0/common/utils/src/main/resources/error/error-conditions.json

> The partition(s) <partitionList> cannot be found in table <tableName>.

> The target relation <relationId> is not partitioned.

> LOAD DATA target table <tableIdentWithDB> is not partitioned, but a partition spec was provided.

The second message is for data sources that are not file-based. The third is the same rule for `LOAD DATA`.

**Stated why.** No stated rationale found. Searched: the error conditions and the source comments. No pull request or JIRA issue was looked up.

**Constraints.** Analysis runs before any data is written, and a SQL statement is expected to fail whole on a schema mismatch.

**Costs and dissent.** None looked for.

### S5. Azure Cosmos DB: a partition key on the call that differs from the document's

**Shape.** Named (the SDK call takes a partition key value) and scope-like. This is a looser analogy, because a container always has a partition key, so no target is truly scope-free.

**What it does.**

- A named key that conflicts with the document's key property is **rejected** with 400, substatus 1001.

  Source: https://learn.microsoft.com/en-us/azure/cosmos-db/troubleshoot-bad-request

  > PartitionKey extracted from document doesn’t match the one specified in the header

- "No partition key" is modelled as a distinguished value, not as an absence. Legacy non-partitioned containers get a system key, and their documents are addressed with `PartitionKey.None`.

  Source: https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/migrate-containers-partitioned-to-nonpartitioned

  > Azure Cosmos DB provides a system defined partition key named /_partitionkey on all the containers that don’t have a partition key.

  > Applications can access the existing documents that don’t have a partition key by using the special system property called "PartitionKey.None", this is the value of the non-migrated documents.

- **Unverified:** what happens when a value other than `None` is named against a container that was never migrated.

**Stated why.** No stated rationale found on either page.

**Constraints.** The partition key is derived from the document. The call's key and the document's key must agree.

**Costs and dissent.** None looked for.

### S6. ClickHouse `input_format_skip_unknown_fields` (unknown-field-like)

**Shape.** Named (the row carries a column) and unknown-field-like (the table does not declare it). It is included because it holds the fullest record found of a silent drop being reconsidered.

**What it does.** At tag `v26.9.37.5-stable` the default is on: the extra column is **dropped silently**, and the row is stored. Nothing is logged.

Source: https://github.com/ClickHouse/ClickHouse/blob/v26.9.37.5-stable/src/Core/FormatFactorySettings.h

> When writing data, ClickHouse throws an exception if input data contain columns that do not exist in the target table. If skipping is enabled, ClickHouse does not insert extra data and does not throw an exception.

**Stated why.** The default changed from off to on in 22.6. The stated reason concerns reading, not writing, so the silent drop on insert was a side effect.

Source: https://github.com/ClickHouse/ClickHouse/blob/v26.9.37.5-stable/src/Core/SettingsChangesHistory.cpp

> {"input_format_skip_unknown_fields", false, true, "Optimize reading subset of columns for some input formats"}

Source: https://github.com/ClickHouse/ClickHouse/pull/37192

> This PR enables setting `input_format_skip_unknown_fields` by default, because otherwise in case of select of subset of columns exception will be thrown.

**Constraints.** One setting governs both reading a subset of columns and writing unknown ones. Formats differ in where their data comes from.

**Costs and dissent.** A reversal is under discussion. On 2026-11-11 a ClickHouse maintainer (alexey-milovidov) opened issue #130754, calling the silent drop data loss.

Source: https://github.com/ClickHouse/ClickHouse/issues/130754

> If a column in the data has no matching column in the table (a typo, a renamed column, the wrong table), it is dropped without any message. The table column that was meant to get the data is filled with its default value. Nothing tells the user that data was lost.

> For text formats such as `JSONEachRow`, skipping unknown keys is a reasonable default. `Native` is different: the data almost always comes from another ClickHouse server or a client library, and the column names are explicit. A name that doesn't match is nearly always a mistake.

> That breaks backward compatibility, so it would need a compatibility setting entry.

The maintainer chose to start with a warning rather than an error:

Source: https://github.com/ClickHouse/ClickHouse/issues/130754#issuecomment-6794051640

> @groeneai, let's start with a server warning - for all formats that skip unknown fields. Send a PR.

Pull request #131160, still open on 2026-11-24, adds a server-log warning for each skipped field (at most 10 per query) and a separate setting to turn the warning off.

### S7. Elasticsearch `dynamic` mapping, and the field-count limit (unknown-field-like)

**Shape.** Named and unknown-field-like. The operator declares, per object, what happens to an undeclared field.

**What it does.** At tag `v9.5.7`:

- `true` (the default) adds the field to the mapping.
- `false` **keeps** the value in `_source` but does not index it. This is a third behaviour, between dropping and storing as declared.
- `strict` **rejects** the document.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/mapping-reference/dynamic.md

> :   New fields are ignored. These fields will not be indexed or searchable, but will still appear in the `_source` field of returned hits. These fields will not be added to the mapping, and new fields must be added explicitly.

> :   If new fields are detected, an exception is thrown and the document is rejected. New fields must be explicitly added to the mapping.

**Stated why.** The page gives no reason for the `false` and `strict` choices.

**Adjacent: the field-count limit.** A document that would take an index over `index.mapping.total_fields.limit` is rejected by default. A later setting, `ignore_dynamic_beyond_limit`, keeps the document and records the surplus fields in `_ignored`, and the logs and metrics templates turned it on. The stated reason is data loss in shared telemetry streams.

Source: https://github.com/elastic/elasticsearch/issues/89911#issuecomment-1301836032

> I think that the biggest pain with the field limit is that it causes data loss.

> As in APM, multiple services share the same data stream, a single misbehaving service can cause data loss for all services.

Source: https://github.com/elastic/elasticsearch/pull/96235

> Ignored fields are added to the `_ignored` metadata field.

Source: https://github.com/elastic/elasticsearch/pull/105180

> This reduces the risk of document loss if too many fields are added.

**Constraints.** Several services share one data stream, so a refused document is lost for its sender and the stream keeps working for the rest.

**Costs and dissent.** The field-limit change is itself a reversal: from rejecting the document to storing it without the surplus and recording what was left out.

### S8. BigQuery `tabledata.insertAll` (unknown-field-like)

**Shape.** Named and unknown-field-like.

**What it does.** By default the request treats an unknown value as an error. The caller can opt in, per request, to having it ignored.

Source: https://cloud.google.com/bigquery/docs/reference/rest/v2/tabledata/insertAll

> Accept rows that contain values that do not match the schema. The unknown values are ignored. Default is false, which treats unknown values as errors.

**Stated why.** No stated rationale found. Only the reference page was read.

**Constraints.** The caller, not the table, chooses for each request.

**Costs and dissent.** None looked for.

### S9. InfluxDB Cloud explicit bucket schemas (unknown-field-like)

**Shape.** Named and unknown-field-like.

**What it does.** A point that does not conform is **rejected, and the rejection is recorded** in a `rejected_points` measurement in the `_monitoring` bucket, so it can be counted. Two reasons are documented: a measurement the schema does not allow, and a field of the wrong type. **Unverified:** what happens to an undeclared tag or field under a measurement the schema allows.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/cloud/admin/buckets/bucket-schema.md

> Explicit bucket schemas ensure that measurements have specific columns and data types and prevent non-conforming write requests.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> the data must conform to the schema. Otherwise, InfluxDB rejects the data.

**Stated why.** No stated rationale found on these pages.

**Constraints.** The schema is opt-in per bucket. Without it, a bucket accepts anything.

**Costs and dissent.** None looked for.

### S10. PostgreSQL: an `INSERT` naming a column the table lacks (unknown-field-like)

**Shape.** Named and unknown-field-like. It is the plain relational baseline.

**What it does.** **Rejected** with an error, at tag `REL_19_0`.

Source: https://github.com/postgres/postgres/blob/REL_19_0/src/backend/parser/parse_target.c

> errmsg("column \"%s\" of relation \"%s\" does not exist",

Row-level security was ruled out as a comparable. It concerns a table that *has* tenancy enabled but no policy, which is default-deny, and that is not this shape.

**Stated why.** Not looked for. This is standard SQL behaviour.

**Constraints.** A statement fails whole, inside a transaction the caller controls.

**Costs and dissent.** None looked for.

---

## Framework and client level

### F1. Prometheus client_python: `.labels()` on a metric declared without labels

**Shape.** Named (the call passes the label) and, when the label is a tenant, scope-like. A metric declares its label names when it is constructed, and one constructed with none is label-free. Of the client libraries, this is the closest match to the exact shape.

**What it does.** At `v0.26.0`, `labels()` **raises `ValueError`** on a metric built without label names. It also raises when the names or the count differ from the declared set.

Source: https://github.com/prometheus/client_python/blob/v0.26.0/prometheus_client/metrics.py

> raise ValueError('No label names were set when constructing %s' % self)

> raise ValueError('Incorrect label names')

**Stated why.** Only in part. The Prometheus guideline for client libraries says label names are fixed when a metric is created. It does not say why a mismatch should raise. No reason specific to client_python was found: its issues were searched for "Incorrect label names", "No label names were set", "optional labels" and "missing labels".

Source: https://github.com/prometheus/docs/blob/31957d4da93dd215cad8c91be3e5205181dd11f1/docs/instrumenting/writing_clientlibs.md

> A client library MUST allow for optionally specifying a list of label names at
> Gauge/Counter/Summary/Histogram creation time.

**Constraints.** A metric's identity is its name plus its label set, and each set of label values is a child time series.

**Costs and dissent.** A 2020 user was surprised that a metric with an empty label list can be built and then fails on `.labels()`. The only maintainer reply pointed them to the mailing list.

Source: https://github.com/prometheus/client_python/issues/500

> Also lets say I do define labels, why do I always have to provide all of them? What if some parts of my code don't have all the data? Can I set default values for labels?

### F2. Prometheus client_golang: the `Counter` and `CounterVec` split, and `With` versus `GetMetricWith`

**Shape.** The same as F1. Go rules the label-free case out **at compile time**: a plain `Counter` has no `With` method, so a label cannot be named on it.

**What it does.** At `v1.25.0`, for a labelled metric, `GetMetricWith` **returns an error** when the label names or count are inconsistent with those declared, and `With` **panics** in the same cases.

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go

> // An error is returned if the number and names of the Labels are inconsistent
> // with those of the variable labels in Desc (minus any curried labels).

> // With works as GetMetricWith, but panics where GetMetricWithLabels would have
> // returned an error. Not returning an error allows shortcuts like

**Stated why.** Yes. beorn7, the maintainer, on issue #204:

Source: https://github.com/prometheus/client_golang/issues/204#issuecomment-223248317

> The current way was deliberately chosen (after literally weeks of intense discussion with very insightful Prometheans and Go developers) to allow the compiler to detect incorrect calls of label-less metrics with labels and vice versa. Ideally, the compiler would also detect the right number of labels, but that's not feasible with Go.

Source: https://github.com/prometheus/client_golang/issues/204#issuecomment-498373396

> In the Prometheus view of the world, a metric vector with three labels will only ever have metrics with values for each of the three labels. A zero value without labels would be against the data model.

**Inferred why.** Inferred: a `With` panic at a recording site takes down the calling goroutine, and the process unless something recovers it. `GetMetricWith` exists for callers who want an error instead.

**Constraints.** The label set is part of a series' identity. The type system can carry whether a metric has labels.

**Costs and dissent.** The issue asked for the opposite, one instrumentation API for metrics with and without labels.

Source: https://github.com/prometheus/client_golang/issues/204

> From our data model a metric with 0 dimensions is no different from one with N. The instrumentation API should reflect that by not distinguishing either.

The maintainer declined in 2021, finding no appetite for a change.

### F3. Micrometer `PrometheusMeterRegistry`: one meter name with a different set of tag keys

**Shape.** Named: Micrometer takes tags where the meter is built, often at the recording site. Unknown-field-like: a tag key outside the set the metric family was first registered with. It is scope-like when the tag is a tenant. It is a near case, not the exact shape: the target is a metric family, and its "declaration" is the first registration.

**What it does: four stages, each with a stated reason.**

1. **Threw**, at `v1.4.0`.

   Source: https://github.com/micrometer-metrics/micrometer/blob/v1.4.0/implementations/micrometer-registry-prometheus/src/main/java/io/micrometer/prometheus/PrometheusMeterRegistry.java

   > throw new IllegalArgumentException("Prometheus requires that all meters with the same name have the same" +

2. **Dropped silently**, with an opt-in callback and an opt-in throw (issues #2068 and #2400). The mismatched meter is left out of the scrape.

   Source: https://github.com/micrometer-metrics/micrometer/issues/2068

   > This is mainly driven by the significant burden Prometheus' requirement places on everyone for the same metric name to have the same set of tags.

   > Previously, `PrometheusMeterRegistry` threw an `IllegalArgumentException`. Now, we'll _not_ throw an exception but instead silently continue, but inform any callbacks registered that this `Meter.Id` could not be registered.

   > In this way, the user can do whatever they'd like with these problems, including logging or propagating a hard failure if they choose.

3. **Logged**, once at WARN and afterwards at DEBUG, by default (pull request #5228, merged 2024-10-08; the tag-key check is still present at `v1.16.9`).

   Source: https://github.com/micrometer-metrics/micrometer/pull/5228

   > A meter registration failure seems to be an important event for users, but it's not easy for the users to be aware of the failure unless they register a callback for it.

   Source: https://github.com/micrometer-metrics/micrometer/pull/5228#issuecomment-2212811290

   > It's better to lose some observability info than cause issues for the application. Logging this is far more reasonable if we're only talking about meter registration failures caused by instrumentation issues in code that users control in their application code, but it's a problem when we're talking about instrumentation issues in code that users don't control (third-party libraries).

4. **Accepted.** At `v1.18.0` only a mismatch of metric *type* is rejected, and there is no tag-key check. The maintainer dates the change to 1.17. That version's source was not read.

   Source: https://github.com/micrometer-metrics/micrometer/issues/877#issuecomment-3924463517

   > With the Prometheus Java client 1.5.0 that was recently released, it included https://github.com/prometheus/client_java/issues/696. That unblocked us from supporting the same, and so this restriction has been removed from the Micrometer `PrometheusMeterRegistry`.

**Constraints.**

- Micrometer is a facade over several back ends, and this restriction came from one of them.
- The application's owner often does not control the code that registers meters (third-party binders).
- The stated priority is to lose telemetry rather than disturb the application.

**Costs and dissent.**

- The silent drop cost users time.

  Source: https://github.com/micrometer-metrics/micrometer/pull/2400#issuecomment-859792366

  > I spent a few hours trying to figure out why some metrics don't appear after adding prometheus.

- A Prometheus contributor (brian-brazil) argued for failing loudly.

  Source: https://github.com/prometheus/client_java/issues/696#issuecomment-920353692

  > Think of it this way, if you suddenly pull in a library that has a clashing metric name rather than having an obvious failure at startup indicating that the name clash needs fixing instead your graphs/alerts will silently break.

- Prometheus later relaxed the rule itself from MUST NOT to SHOULD NOT, in prometheus/docs commit `3a44f48946` ("relax stance on metrics with same name but different labels (#2782)").

  Source: https://github.com/prometheus/docs/commit/3a44f48946fe459e4d2ef97c314d1a3f326d9324

  > Client libraries SHOULD NOT allow users to have different label names for the same metric for Gauge/Counter/Summary/Histogram or any other Collector offered by the library.

  (line breaks collapsed)

- The comment threads on Micrometer issue #877 and client_java issue #696 were read only in part, so the dissent recorded here is not complete.

### F4. OpenTelemetry metrics: a View's `attribute_keys` and the `Attributes` advisory parameter

**Shape.** Named (the measurement call carries attributes) and unknown-field-like: the instrument's advisory `Attributes`, or an operator's View, declares which keys a metric stream keeps. With `Attributes = []` the stream is declared attribute-free. It is scope-like when the dropped attribute is a tenant. The drop is **configured**, which sets it apart from F5, a size cap.

**What it does.** Read in the specification at `v1.63.0`.

- Attributes outside the allow-list are **dropped silently** when aggregating. No error is raised and nothing is counted.
- They may still be exported on exemplars, as "filtered attributes".
- The `Attributes` advisory parameter is marked Development, not Stable, in this version.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md

> * `attribute_keys`: This is, at a minimum, an allow-list of attribute keys for
>   measurements captured in the metric stream. The allow-list contains attribute
>   keys that identify the attributes that MUST be kept, and all other attributes
>   MUST be ignored.

> If the user has provided attribute keys via View(s), those keys take precedence.
> If no View is configured, or if a matching view does not specify attribute keys,
> the advisory parameter MUST be used (an empty list `[]` retains no attributes).
> If neither is provided, all attributes MUST be retained.

**Stated why.** In part.

- What Views are for: OTEP 0126 says they separate instrumentation from operation. The instrumentation author emits attributes, and the operator decides which to keep.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/metrics/0126-Configurable-Metric-Aggregations.md

  > OpenTelemetry's architecture separates the concerns of instrumentation and operation.

- The project's error-handling principles, which apply to every API:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

  > 1. API methods MUST NOT throw unhandled exceptions when used incorrectly by end users.

  > Whenever the library suppresses an error that would otherwise have been exposed to the user, the library SHOULD log the error using language-specific conventions.

  > Application developers may want to run with strict error handling in a staging environment to catch invalid uses of the API, or malformed config.

- No passage was found arguing for **not counting** attributes a View drops.

**Inferred why.** Inferred: under these principles a View's drop is not an error, because it is the outcome the operator configured, so there is nothing to log.

**Constraints.** Instrumentation authors and operators are different people. Operators reshape streams without touching instrumentation, and the library must never break the host application.

**Costs and dissent.** A 2026-10-27 comment on specification issue #3785 lists inconsistencies between SDKs. It describes itself as an AI-assisted audit, so its claims about SDK behaviour are **Unverified** here.

### F5. OpenTelemetry attribute limits (a loose analogy: a size cap)

**Shape.** Named, but nothing is undeclared: attributes beyond a count limit are dropped, and values beyond a length limit are truncated. It is included because it is the one place in the specification where dropped attributes are **counted**.

**What it does.** At `v1.63.0`, the SDK discards the surplus and counts it (`dropped_attributes_count`, exported as `otel.dropped_attributes_count` where the format has no field for it). It may log, at most once per record.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/common/README.md

> the SDK MUST discard that attribute, so that the total number of attributes in an attribute collection is at most equal to the limit;

(line breaks collapsed)

> There MAY be a log emitted to indicate to the user that an attribute was
> truncated, discarded, or replaced due to a limit. To prevent excessive logging,
> the log MUST NOT be emitted more than once per record on which an attribute is
> set.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/common/mapping-to-non-otlp.md

> OpenTelemetry dropped attributes count MUST be reported as a key-value
> pair associated with the corresponding data entity (e.g. Span, Span Link, Span Event,
> Metric data point, LogRecord, etc). The key name MUST be `otel.dropped_attributes_count`.

**Stated why.** Yes: memory safety.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/common/README.md

> Execution of erroneous code can result in unintended attributes. If there are no
> limits placed on attribute collections, they can quickly exhaust available memory,
> resulting in crashes that are difficult to recover from safely.

Metric attributes are exempt, because dropping one would change which series a point belongs to.

Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/metrics/sdk.md

> Attributes which belong to Metrics are exempt from the
> [common rules of attribute limits](../common/README.md#attribute-limits) at this
> time. Attribute truncation or deletion could affect identity of metric time
> series and the topic requires further analysis.

**Constraints.** Memory safety under automatic instrumentation. For metrics, attributes are part of a series' identity.

**Costs and dissent.** None collected.

### F6. Rust `tracing`: `Span::record` for a field the span did not declare

**Shape.** Named (the call names the field) and unknown-field-like: a span's field set is declared when it is created (`field::Empty` declares a field with no value yet). It is scope-like when the field is a tenant.

**What it does.** At `tracing-0.1.44` the record is **ignored silently**, and the docs say so. In the code, `field.as_field(meta)` returns `None` and nothing is recorded.

Source: https://github.com/tokio-rs/tracing/blob/tracing-0.1.44/tracing/src/span.rs

>     /// // Now, you try to record a value for a new field, `new_field`, which was not
>     /// // declared as `Empty` or populated when you created `span`.
>     /// // You won't get any error, but the assignment will have no effect!

**Stated why.** Only the mechanism is stated, not why the call is silent.

Same source.

>     ///     describing a particular span is constructed statically when the span
>     ///     is created and cannot be extended later to add new fields. Therefore,
>     ///     you cannot record a value for a field that was not specified when the
>     ///     span was created:

Source: https://github.com/tokio-rs/tracing/issues/845

> In an attempt to enable this, we currently represent `Field`s as an `&'static` reference to a `FieldSet` (a static array of strings generated by the macros for each callsite) and an integer index into that array.

No stated rationale was found for ignoring the call silently rather than reporting it. Searched: the `Span::record` docs, the `tracing-core` `field` module docs, and issues #845, #1343, #2252 and #2405, with all their comments.

**Constraints.** Field sets are `'static` per call site and generated by macros, and fields are compared by index for speed.

**Costs and dissent.** Two open issues ask for the mistake to be reported or the field kept. Neither has a maintainer reply explaining the silence.

Source: https://github.com/tokio-rs/tracing/issues/2405

> Can we have some "opt-in" mechanism to warn the developer of their (my) mistake.

Source: https://github.com/tokio-rs/tracing/issues/1343#issuecomment-812558157

> E.g. in [`Span::record`](https://github.com/tokio-rs/tracing/blob/1e09e50e8d15580b5929adbade9c782a6833e4a0/tracing/src/span.rs#L1095) instead of silently ignoring the new field, add it to some kind of `HashMap` (created only if needed).

### F7. Rails `acts_as_tenant`: an explicit tenant that conflicts with the current tenant (a different shape)

**Shape.** A different shape: a named tenant that conflicts with the ambient tenant on a tenant-**scoped** model. Scope-like. It is included because it has the clearest author-stated reasoning about a named tenant being silently ignored, and a reversal.

**What it does.** At `v2.2.2`:

- A new record without a tenant gets the current one.
- A record assigned to a different tenant **fails validation**: `save` returns false and the error is recorded against the tenant key. Nothing is raised.
- `insert_all` and `upsert_all` skip validation.

Source: https://github.com/ErwinM/acts_as_tenant/blob/v2.2.2/README.md

> New records are assigned the current tenant unless they already have one. A record assigned to a different tenant fails validation, so to create records for another tenant, wrap them in `ActsAsTenant.with_tenant(other_tenant) { ... }`.

For a model **without** `acts_as_tenant`, the exact shape here, the gem adds no scope, callback or validation. That is **Inferred** from the absence of any code path, not stated. If such a model has no tenant column, naming one raises in Rails itself (F12).

**Stated why.** Yes, for a reversal in 2.0.0. Before it, a conflicting explicit tenant was **silently overwritten** with the current one.

Source: https://github.com/ErwinM/acts_as_tenant/pull/378

> Normal tenants always had their tenant overwritten with the current tenant. That was confusing and hid bugs, such as factories in #317. Polymorphic tenants only filled in a blank tenant and never checked the value, so a request scoped to one tenant could create records in another by posting `commentable_type` and `commentable_id`.

> This is a breaking change, listed under "Upgrading" in the changelog. Code that creates records for another tenant while a tenant is set, including test factories with `test_tenant`, needs `with_tenant(other)`.

**Constraints.** Records are web-request models, validation failure is the framework's normal way to refuse a save, and a wrong tenant is a data-isolation risk.

**Costs and dissent.** The overwrite drew user reports before the change.

Source: https://github.com/ErwinM/acts_as_tenant/issues/329

> I'm not sure whether this is a target behavior but when saving new object, the tenant ID is simply overriden with the current tenant although I'd expect it to fail:

The change itself was breaking, as its own description says above.

### F8. Hibernate ORM `@TenantId`: an explicit tenant that conflicts with the session's (a different shape)

**Shape.** A different shape: a named tenant that conflicts with the ambient tenant on a tenant-scoped entity. Scope-like.

**What it does.** At `7.4.17`, at least on insert: if the `@TenantId` field already holds a value that differs from the session's tenant, `TenantIdGeneration` **throws** `PropertyValueException`. A "root" tenant may set the value explicitly. The validation method's other callers were not traced.

Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/hibernate-core/src/main/java/org/hibernate/generator/internal/TenantIdGeneration.java

> 				// the "root" tenant is allowed to set the tenant id explicitly

> 						"assigned tenant id differs from current tenant id ["

Source: https://github.com/hibernate/hibernate-orm/blob/7.4.17/hibernate-core/src/main/java/org/hibernate/annotations/TenantId.java

>  * when the entity is first made persistent. The {@code @TenantId} field may not be directly
>  * set by the application program.

An entity **without** `@TenantId` gets no tenant filter, because `TenantIdBinder` sets one up only for an attribute that carries the annotation. That such an entity is written without a tenant is **Inferred**.

**Stated why.** The rule is stated, but no reason for it was found. The originating commit says only "use this to throw exception from TenantIdGeneration".

Source: https://github.com/hibernate/hibernate-orm/commit/8af548b52d3cfbe438799f11665f035694f0e4dd

> use this to throw exception from TenantIdGeneration

Searched: the three commits for HHH-6054, all 65 comments on Jira HHH-6054 (three long comments read only in their first 400 characters), the user guide's chapter on multitenancy, and the `TenantId` and `CurrentTenantIdentifierResolver` javadocs. No GitHub pull request search was run.

**Constraints.** Discriminator multi-tenancy in one schema. The tenant comes from the session, and the root tenant is the way out for administrative writes.

**Costs and dissent.** None found in the sources read.

### F9. django-multitenant (Citus): the explicit tenant wins (a different shape)

**Shape.** A different shape: a named tenant that conflicts with the ambient tenant on a tenant-scoped model. Scope-like. It behaves the opposite way to F7 and F8.

**What it does.** At `v4.0.0`:

- `save()` sets the current tenant only if the object has none.
- If the object carries a different tenant, the current tenant is **switched to the object's** for the save and then restored.
- Changing the tenant column of an existing row raises `NotSupportedError`.

Source: https://github.com/citusdata/django-multitenant/blob/v4.0.0/django_multitenant/mixins.py

>         # Synchronizes object tenant with the tenant set in the application in case of a mismatch

>         if self.tenant_value and tenant_value != self.tenant_value:
>             self_tenant = get_object_tenant(self)
>             set_current_tenant(self_tenant)

Models that do not use `TenantModelMixin` are **Inferred** to be left alone.

**Stated why.** No stated rationale found. Commit `1a51595dcb` ("fix save when different tenant is set") and pull request #88, whose description is empty, give no reason. Issue #86 reports the bug they fixed: an integrity error when an instance was saved while another tenant was current. Also searched: issues for "tenant_id", "save" and "tenant mismatch".

**Inferred why.** Inferred, from a comment in `mixins.py` ("Citus requires tenant_id filters for update, hence doing this below change."): the switch keeps the distribution-column filter consistent with the row being written.

**Constraints.** Citus routes each statement by its tenant (distribution) column.

**Costs and dissent.** None found.

### F10. stancl/tenancy (Laravel) `BelongsToTenant`: the explicit tenant wins, unchecked (a different shape)

**Shape.** A different shape: a named tenant that conflicts with the ambient tenant on a tenant-scoped model. Scope-like.

**What it does.** At `v3.10.1`, when a model is created, the current tenant is set only if `tenant_id` is empty and the relation is not loaded. An explicit `tenant_id` is **kept**, and is never compared with the current tenant.

Source: https://github.com/archtechx/tenancy/blob/v3.10.1/src/Database/Concerns/BelongsToTenant.php

>             if (! $model->getAttribute(BelongsToTenant::$tenantIdColumn) && ! $model->relationLoaded('tenant')) {

The documentation calls tenant-free models "global models". A `tenant_id` named on one falls to Eloquent's mass-assignment rules (F11).

Source: https://github.com/stancl/tenancy-docs/blob/2be4b681d0cee05451a27a4415de8d4e6345785c/source/docs/v3/single-database-tenancy.blade.md

> - global models — models that are **not scoped** to any tenant whatsoever

**Stated why.** No stated rationale found. Its issues were searched for "BelongsToTenant" and "tenant_id", and no thread discussed an explicit tenant that conflicts with the current one.

**Constraints.** Single-database tenancy, with the tenant applied by model events.

**Costs and dissent.** None found.

### F11. Laravel Eloquent `fill()`: attributes the model does not accept are discarded silently

**Shape.** Named and unknown-field-like: a key that is not in `$fillable`. It is scope-like when the key is `tenant_id` on a global model (F10).

**What it does.** At `v13.43.0`, keys that are not fillable are **dropped silently** by default. An exception is raised only under the opt-in `preventSilentlyDiscardingAttributes()`, which can route the case to a callback instead, or when the model is totally guarded.

Source: https://github.com/laravel/framework/blob/v13.43.0/src/Illuminate/Database/Eloquent/Model.php

>             // The developers may choose to place some attributes in the "fillable" array
>             // which means only those attributes may be set through mass assignment to
>             // the model, and all others will just get ignored for security reasons.

**Stated why.** Yes, for both the silent default and the opt-in.

Source: https://github.com/laravel/docs/blob/91e8831934e4f40186acb06a6aebec1535a48b8a/eloquent.md

> By default, attributes that are not included in the `Fillable` attribute are silently discarded when performing mass-assignment operations. In production, this is expected behavior; however, during local development it can lead to confusion as to why model changes are not taking effect.

> Model::preventSilentlyDiscardingAttributes(! $this->app->isProduction());

Source: https://github.com/laravel/framework/pull/43893

> One very irritating thing for me is to forget adding a new property to the `$fillable` array (because it's not my default way of working) and later discover that fills have been silently discarded, thus causing bugs.

**Constraints.** Mass assignment takes untrusted request input, so the silent discard is a security default. The documented strictness depends on the environment: strict in development, silent in production.

**Costs and dissent.** A commenter on the pull request wanted strictness to be the default. It was not made so.

Source: https://github.com/laravel/framework/pull/43893#issuecomment-1238723630

> This should be the the Laravel default.

### F12. Rails and Django: an unknown attribute raises (unknown-field-like)

**Shape.** Named and unknown-field-like. This is what happens when a tenant attribute is named on a model that has no such attribute.

**What it does.** Rails raises `UnknownAttributeError`, and Django's model constructor raises `TypeError`.

Source: https://github.com/rails/rails/blob/v8.1.4.1/activemodel/lib/active_model/attribute_assignment.rb

> # By default, `#attribute_writer_missing` raises an UnknownAttributeError.

Source: https://github.com/django/django/blob/5.2.19/django/db/models/base.py

> f"{cls.__name__}() got unexpected keyword arguments: "

**Stated why.** Not looked for.

**Constraints.** A failed assignment is an exception in application code that the caller is expected to handle or fix.

**Costs and dissent.** Not looked for.

### F13. django-tenants and Apartment: shared models (ambient only)

**Shape.** Ambient (the connection's search path) and scope-like. In both libraries a write call has no way to name a tenant, so the named case cannot occur. It is included because it is how two widely used libraries model tenant-free tables.

**What it does.** While a tenant is active, a shared or excluded model resolves to the public schema, and the ambient tenant simply does not apply.

Source: https://github.com/django-tenants/django-tenants/blob/v4.0.7/docs/index.rst

> An application is considered to be shared when its tables are in the ``public`` schema. Some apps make sense being shared. Suppose you have some sort of public data set, for example, a table containing census data. You want every tenant to be able to query it. This application enables shared apps by always adding the ``public`` schema to the search path, making these apps also always available.

Source: https://github.com/rails-on-services/apartment/blob/v3.4.4/README.md

> Rails will always access the 'public' tenant when accessing these models, but note that tables will be created in all schemas. This may not be ideal, but its done this way because otherwise rails wouldn't be able to properly generate the schema.rb file.

**Stated why.** django-tenants gives the purpose of shared apps (above), not a reason for ignoring the ambient tenant. Apartment's passage explains where the tables are created, not why the tenant is ignored.

**Constraints.** Schema-per-tenant on PostgreSQL.

**Costs and dissent.** None looked for.

---

## Comparables that chose otherwise

There is no single majority to stand against, so this section records the split and the reason each side gave, where one was given.

**Among the scope-like comparables at the system level:**

- **Kubernetes (body field and `kubectl`) and the Grafana family drop the named scope silently.** No author gave a reason for dropping a scope that is present. Grafana's stated reason covers only the substitute tenant (S2), and a Kubernetes reviewer found the clear "weird" (S1).
- **Elasticsearch TSDS, Spark, the Kubernetes URL path and Cosmos DB reject it.** None states a reason. In Elasticsearch and Cosmos DB the target derives its scope from the data, so a named scope would conflict with it rather than merely go unused. That reading is Inferred.

**Among the telemetry clients:**

- **Prometheus client_golang (F2) refuses at compile time, and panics or returns an error at run time.** Its maintainer's stated reason is that the compiler should catch "incorrect calls of label-less metrics with labels". client_python (F1) raises, with no stated reason of its own.
- **OpenTelemetry Views (F4) and `tracing` (F6) drop silently.** OpenTelemetry states a project-wide reason, "users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application". `tracing` states only its mechanism.
- **Micrometer (F3) went from raising, to dropping silently, to logging, to accepting.** Each step has a stated reason. Against it, a Prometheus contributor argued that a silent failure means "your graphs/alerts will silently break".

**Among the tenancy libraries (the conflicting shape):**

- **acts_as_tenant reversed** from silently overwriting a named tenant to failing validation, because the overwrite "was confusing and hid bugs" (F7). Hibernate throws, and states no reason (F8).
- **django-multitenant (F9) and stancl/tenancy (F10) keep the named tenant.** Neither states a reason.

**Among the unknown-field comparables:**

- **Rejection is the default** for BigQuery (S8), InfluxDB explicit schemas (S9), PostgreSQL (S10), Elasticsearch `strict` (S7), Rails and Django (F12).
- **ClickHouse (S6) and Laravel (F11) drop silently by default.**
  - ClickHouse's default came about as a side effect of a read-side change, and in November 2026 a maintainer called it data loss and asked for a warning.
  - Laravel's reason is security, and its documentation calls the silence expected in production and confusing in development.
- **Elasticsearch's field limit (S7) moved from rejecting the document to storing it without the surplus and recording what was left out.** Its reason was that one misbehaving service could lose data for every service sharing the stream.

## Candidates not examined, or dropped

- **Not examined:** EF Core, the Rust `metrics` crate, structlog, Sentry scopes, Citus reference tables, VictoriaMetrics, Datadog and other hosted ingest (whose tenant comes from an API key, so it is ambient), and BigQuery partition decorators on a non-partitioned table.
- **Dropped:** Thanos Receive, because it has no tenancy-off mode. PostgreSQL row-level security, because it has a different shape (S10).
- **Read only in part:** the Hive rule for a partition spec on a non-partitioned table (an error is defined, but its use on the insert path was not traced), and the comment threads on Micrometer issue #877, client_java issue #696 and client_golang issue #1072.

## Fit, least surprise, options and recommendation

Not written yet. They follow the first adversarial review, as `REVIEW.md` requires.

## What the findings bear on in the specification

Not written yet, for the same reason.
