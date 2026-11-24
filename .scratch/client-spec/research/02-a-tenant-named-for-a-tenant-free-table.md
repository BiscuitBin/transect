# Research: a tenant named for a tenant-free table

- **Ticket:** `issues/02-research-a-tenant-named-for-a-tenant-free-table.md`, open question 19 of `docs/specs/transect-client.allium`.
- **Sources read:** every source on 2026-11-24 (UTC), which was 2026-11-23 in the researcher's local time.
- **Web research:** authorised by the maintainer on 2026-11-23 for this ticket, for the agent working it and for its reviewers.
- **State of this file:** findings only. Fit, which behaviour surprises least, the options, the recommendation and the proposed wording are not written yet: they follow the first adversarial review, as `REVIEW.md` requires.

## How the sources were checked

Two survey agents found the candidates and saved raw text. The first adversarial review added sources of its own. The author then fetched every cited source again, independently:

- source and documentation files at a pinned tag or commit, through `raw.githubusercontent.com`;
- issue, pull request, review-comment, commit, release and security-advisory text through the GitHub REST API, and a quotation cited to one comment from that comment alone;
- Jira through its REST API;
- vendor pages and blog posts as HTML, with the tags stripped.

Each quotation below was then checked by machine as a substring of that text. Every quotation matched character for character, except those marked "(line breaks collapsed)". Those match only once line breaks, indentation or diff markers are collapsed, and their wording is verbatim.

A quotation from source code keeps the comment markers and indentation it has in the file.

## The shape being looked for

The question is about one write that **names** a tenant itself, for a table **declared** tenant-free. Each comparable is classified on two axes.

- **Named or ambient.** Named: the write call itself carries the scope, as a parameter, a header, a clause or a field. Ambient: the scope comes from the surrounding context, such as a session, a connection or a deployment setting. The ticket settles the ambient case: a handle's bound tenant is simply not applied to a tenant-free table.
- **Scope-like or unknown-field-like.** Scope-like: the thing named is a tenant, namespace, partition or routing key. Unknown-field-like: an undeclared column, label, attribute or field. The specification already settles that a row with an unknown column is refused whole, so an unknown-field comparable bears on the question only if a named tenant is treated as row content.

Some comparables are a different shape again: a named tenant that **conflicts** with the ambient tenant on a tenant-**scoped** target. They are labelled that way.

---

## System level

### S1. Kubernetes API server: a namespace on a cluster-scoped object

**Shape.** Named and scope-like. A cluster-scoped kind, such as `ClusterRole` or `Node`, is declared without a namespace. A write can name one in three places, and each is handled differently.

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

- A downstream controller's security advisory turns on this clear. This is the advisory's account as Capsule published it, not a Kubernetes author's.
  - Capsule, a multi-tenancy controller built on Kubernetes, published advisory GHSA-qjjm-7j9w-pw72 (CVE-2026-22872). It affects versions up to v0.12.4 and is patched in 0.13.0. The repository's advisory rates it high, and GitHub's advisory database rates it medium.
  - Capsule's controller set a tenant's namespace on each object a tenant supplied in a `TenantResource`, then created the object with its own privileges. For a cluster-scoped kind the namespace did not confine the object, and it was created cluster-wide.
  - The advisory names the prerequisites: the controller runs with cluster-admin privileges, which it calls the default; a tenant owner may create a `TenantResource`; and the controller does not check whether a resource is cluster-scoped.
  - The vulnerability belongs to that controller. Kubernetes' own authorization still refused the tenant owner a direct create, and the advisory claims no bypass of it.

  Source: https://github.com/projectcapsule/capsule/security/advisories/GHSA-qjjm-7j9w-pw72

  > Although the TenantResource RawItems processing logic forcibly sets the namespace, this is ineffective for cluster-scoped resources.

  > Although the code calls `obj.SetNamespace(ns.Name)`, this is ineffective for cluster-scoped resources (ClusterRole, ValidatingWebhookConfiguration, etc.), as the Kubernetes API ignores this field

  > Tenant administrators can leverage the Controller's elevated privileges to create cluster-scoped resources (such as ClusterRole and ValidatingWebhookConfiguration) that they cannot create directly, achieving cross-tenant privilege escalation and cluster-level attacks.

  "Ignores" is the advisory's word. Traced, not executed:
  - At Capsule v0.12.4 the controller writes through controller-runtime v0.22.4, the version its `go.mod` pins.
  - That client leaves the namespace out of the request path for a kind that is not namespaced, and sends it in the body. So the write is routed, and the server's clear described above removes the namespace.
  - The advisory's proof of concept ran on Kubernetes 1.27 or later, not on v1.37.2.
  - How 0.13.0 closes the issue was not read. Its release note points to impersonation for `TenantResource` as the immediate mitigation.

  Source: https://github.com/projectcapsule/capsule/blob/v0.12.4/internal/controllers/resources/processor.go

  > 			obj.SetNamespace(ns.Name)

  Source: https://github.com/kubernetes-sigs/controller-runtime/blob/v0.22.4/pkg/client/unstructured_client.go

  > 		NamespaceIfScoped(o.namespace, o.isNamespaced()).

### S2. Grafana Mimir and Loki (and Cortex) with multi-tenancy off

**Shape.** Named (the push carries an `X-Scope-OrgID` header) and scope-like (a tenant). The scope-free declaration is deployment-wide (`-auth.multitenancy-enabled=false` in Mimir, `auth_enabled: false` in Loki), not per target, so this is looser than S1. The outcome differs too. Storage stays tenant-scoped, and every push is stored under one substitute tenant, so a named tenant is **replaced**, not removed. That is not "stored without a tenant".

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

> When configured with `auth_enabled: false`, Loki uses a single tenant.

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

Mimir's copy of the middleware keeps the same reason.

Source: https://github.com/grafana/mimir/blob/mimir-3.2.6/pkg/util/noauth/no_auth.go

> // Package noauth provides middlewares that injects a tenant ID so the rest of the code
> // can continue to be multitenant.

Loki's current default branch says the same in other words.

Source: https://github.com/grafana/loki/blob/c1ab23aede2bbb78f92fde4effc01eb0288a6691/pkg/util/fakeauth/fake_auth.go

> // request so downstream code can assume a tenant is always present.

No stated rationale was found for ignoring a header that is *present* in this mode, rather than rejecting or honouring it. Searched: Mimir pull requests #1063 and #1130, Mimir issue #276, Tempo issue #495, and Loki and Mimir issue searches for "X-Scope-OrgID" and "multitenancy_enabled false".

**Constraints.**

- The tenant travels in a header, not in the payload. An authenticating reverse proxy is expected to set it.
- Single-tenant mode removes the requirement for the header. A Cortex maintainer offered it to a user who did not care about the tenant value, as the alternative to a front door that sets the header. No author was found saying it exists for small installs. A proxy is not what multi-tenant mode requires either: in a trusted environment the client can set the header itself, and Loki requires an authenticating proxy in either mode.

  Source: https://github.com/cortexproject/cortex/blob/v1.22.0/docs/configuration/single-process-config-blocks.yaml

  > # Disable the requirement that every request to Cortex has a
  > # X-Scope-OrgID header. `fake` will be substituted in instead.

  Source: https://github.com/cortexproject/cortex/issues/1479#issuecomment-506516141

  > If you do not care about what the tenant value is you can also set a flag for `-auth.enabled=false` which will add "fake" as the tenant everywhere.

  Source: https://github.com/cortexproject/cortex/blob/v1.22.0/docs/guides/authentication-and-authorisation.md

  > In trusted environments, Prometheus can send the `X-Scope-OrgID` header itself

  Source: https://github.com/grafana/loki/blob/v3.7.10/docs/sources/operations/authentication.md

  > Grafana Loki does not come with any included authentication layer. You must run an authenticating reverse proxy in front of your services.
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

**Stated why.** In part, by the author of the change (nik9000), but no reason is given for refusing a value rather than ignoring it.

- The refusal was introduced in pull request #77731 (merged 2021-10-15). A follow-up, #79384 (merged 2021-10-19), says what routing is for in this mode.

  Source: https://github.com/elastic/elasticsearch/pull/79384

  > `routing_path`'s job is to put the same time series on the same node.

  > The third document could be routed to a different shard than the first two! Which would be a disaster because it'd cut the time series identified by `"dim":"a"` into pieces!

  (line breaks collapsed)

  That harm is stated for a `routing_path` that matches a non-dimension field, not for a caller's routing value.
- In the review of #77731 the author explained why this mode does not read routing at all. "Duplicate bytes" there refers to storing a *generated* routing value, not a caller's.

  Source: https://github.com/elastic/elasticsearch/pull/77731#discussion_r710111746

  > We didn't like the idea of writing this generated routing value to the translog because its just duplicate bytes. It felt much more natural not to have to look at `routing` at all for tsdb and make the change we needed here.

  Source: https://github.com/elastic/elasticsearch/pull/77731#discussion_r710268965

  > In another sense, when `index.routing_path` is set routing is *forbidden* on CRUD operations. And I think that sense aligns better with how we document it. And how the code works, thankfully.

- No passage says why a supplied value is refused rather than ignored. Searched: GitHub pull request searches for "routing_path", "TSDB routing_path" and "specifying routing is not supported", one web search, and every review comment, review and conversation comment on #77731 and #79384.

**Inferred why.** Inferred: in a TSDS, routing is a function of the dimensions (`index.routing_path`). A caller-supplied routing value would put one time series on two shards, so the named scope would *conflict* with a declared derivation, not merely go unused. #79384 states that harm, a series cut across shards, for a misconfigured `routing_path`. That it is the reason a caller's routing value is refused remains Inferred.

**Constraints.** Routing is derived from the data. A wrong routing value would silently split a series across shards.

**Costs and dissent.** An alternative was raised in review and set aside: accepting a routing value that is "right", so that updates and deletes could work. The author's answer is quoted under "Stated why", and the reviewer then accepted the approach.

Source: https://github.com/elastic/elasticsearch/pull/77731#discussion_r710081653

> But I wonder if we would then not also support an indexing request with the "right" routing value. That would allow updates and deletes too, meaning update-by-query and delete-by-query would work?

Source: https://github.com/elastic/elasticsearch/pull/77731#discussion_r710256606

> Which in turn means that the approach taken in this PR looks good to me.

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

**Stated why.** No stated rationale found for the SQL clause. Searched: the error conditions and the source comments. No pull request or JIRA issue was looked up for the SQL check itself.

- **An adjacent API, informing only.** The DataFrame API has the same shape: `partitionBy()` names partitioning on the write, and `insertInto()` targets a table that declares its own. Spark rejects the combination.
  - Its JIRA issue, SPARK-16033 (fixed in 2.0.0), and pull request #13747 state a reason, written for an existing partitioned table.
  - Traced at v4.3.0, not executed: the check runs before the table is looked up, so it fires for a non-partitioned table too.
  - The stated reason does not speak to that case, and it is not the reason for the SQL check above.

  Source: https://github.com/apache/spark/pull/13747

  > When inserting into an existing partitioned table, partitioning columns should always be determined by catalog metadata of the existing table to be inserted. Extra `partitionBy()` calls don't make sense, and mess up existing data because newly inserted data may have wrong partitioning directory layout.

  Source: https://github.com/apache/spark/blob/v4.3.0/sql/core/src/main/scala/org/apache/spark/sql/classic/DataFrameWriter.scala

  >       throw QueryCompilationErrors.partitionByDoesNotAllowedWhenUsingInsertIntoError(tableName)

  Source: https://github.com/apache/spark/blob/v4.3.0/common/utils/src/main/resources/error/error-conditions.json

  > partitionBy() cannot be used with insertInto(). Partition columns for table <tableName> are determined by the table definition.

**Constraints.** Analysis runs before any data is written, and a SQL statement is expected to fail whole on a schema mismatch.

**Costs and dissent.** For the SQL clause, none looked for. On the adjacent DataFrame API only: two days after the fix, a commenter on SPARK-16033 objected that `partitionBy()` had a valid use, and proposed allowing it when it matches the table's partition spec. The objection concerns a partitioned table, not a non-partitioned one, and the check still stands at v4.3.0.

Source: https://issues.apache.org/jira/browse/SPARK-16033

> I think users will be surprised when this support is removed in 2.0.

> but those columns are validated against the partition spec for the table.

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

As proposed, the warning does not reach the issue's own example. The pull request's description leaves out data the client parses itself, and the warning's author gave the reason on the issue.

Source: https://github.com/ClickHouse/ClickHouse/pull/131160

> Not covered: data `clickhouse-client` or `clickhouse-local` parse on the client side (stdin, `FROM INFILE` as in the issue's example, inline data with `async_insert = 0`), reads through table functions, and formats that do not use the setting (`Parquet`, `ORC`, `Arrow`, `Avro`, `Protobuf`, `CapnProto`).

Source: https://github.com/ClickHouse/ClickHouse/issues/130754#issuecomment-6839429936

> One limitation: the issue's `FROM INFILE` example is parsed by `clickhouse-client` itself, which drops `c` before it sends any block, so the server never sees that column and does not warn.

### S7. Elasticsearch `dynamic` mapping, and the field-count limit (unknown-field-like)

**Shape.** Named and unknown-field-like. The operator declares, per object, what happens to an undeclared field.

**What it does.** At tag `v9.5.7`:

- `true` (the default) adds the field to the mapping.
- `false` **keeps** the value in `_source` but does not index it. This is a third behaviour, between dropping and storing as declared.
- `strict` **rejects** the document.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/mapping-reference/dynamic.md

> :   New fields are ignored. These fields will not be indexed or searchable, but will still appear in the `_source` field of returned hits. These fields will not be added to the mapping, and new fields must be added explicitly.

> :   If new fields are detected, an exception is thrown and the document is rejected. New fields must be explicitly added to the mapping.

**Stated why.** The current reference page gives none. Elastic's older book, *Elasticsearch: The Definitive Guide* for 2.x, gives one for `strict`, especially where Elasticsearch is the primary data store, and only a bare preference for `false`. The page marks itself as no longer maintained, so this is historical guidance for a version past its end of life.

Source: https://www.elastic.co/guide/en/elasticsearch/guide/current/dynamic-mapping.html

> Perhaps you just want to ignore them.

> especially if you are using Elasticsearch as a primary data store

> perhaps you want unknown fields to throw an exception to alert you to the problem.

(line breaks collapsed)

**Adjacent: the field-count limit.** A document that would take an index over `index.mapping.total_fields.limit` is rejected by default. A later setting, `ignore_dynamic_beyond_limit`, indexes the document instead. It leaves the surplus fields out of the mapping, "similar to `dynamic: false`", and lists their names in `_ignored`. The logs and metrics templates turned it on.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/index-settings/mapping-limit.md

> When set to `true`, the index request will not fail. Instead, fields that would exceed the limit are not added to the mapping, similar to [`dynamic: false`](/reference/elasticsearch/mapping-reference/dynamic.md). The fields that were not added to the mapping will be added to the [`_ignored` field](/reference/elasticsearch/mapping-reference/mapping-ignored-field.md).

The stated reason is data loss in shared telemetry streams. The proposal also said the surplus fields would be kept, not removed.

Source: https://github.com/elastic/elasticsearch/issues/89911#issuecomment-1301836032

> I think that the biggest pain with the field limit is that it causes data loss.

> As in APM, multiple services share the same data stream, a single misbehaving service can cause data loss for all services.

> the additional fields would just be stored but not added to the mapping (similar to `dynamic: false`).

Source: https://github.com/elastic/elasticsearch/pull/96235

> Ignored fields are added to the `_ignored` metadata field.

Source: https://github.com/elastic/elasticsearch/pull/105180

> This reduces the risk of document loss if too many fields are added.

**Constraints.** Several services share one data stream, so a refused document is lost for its sender and the stream keeps working for the rest.

**Costs and dissent.** The field-limit change added an option and did not change the index default.

- With `ignore_dynamic_beyond_limit` on, the document is accepted, its surplus fields are unmapped and unindexed, and their names are listed in `_ignored`.
- With it off, which is still the default at `v9.5.7`, the document is rejected.
- What changed by default is the built-in `logs@settings` and `metrics@settings` component templates, which set the option to `true` (pull request #105180). A data stream built on them accepts the document.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/docs/reference/elasticsearch/index-settings/mapping-limit.md

> When set to `false` (the default), the index request of the document that tries to add a dynamic field to the mapping will fail with the message `Limit of total fields [X] has been exceeded`.

Source: https://github.com/elastic/elasticsearch/blob/v9.5.7/x-pack/plugin/core/template-resources/src/main/resources/logs@settings.json

>             "ignore_dynamic_beyond_limit": true

Source: https://github.com/elastic/elasticsearch/pull/105180

> As these component templates are imported by Fleet, this also affects integrations.

The values are not described as removed. The setting's documentation likens them to `dynamic: false`, whose fields "will still appear in the `_source` field of returned hits", but it does not state the retention directly.

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

**What it does.** A point that does not conform is **rejected, and the rejection is recorded** in a `rejected_points` measurement in the `_monitoring` bucket, so it can be counted. A point here is one field value, not a whole line (below). Two reasons are documented: a measurement the schema does not allow, and a field of the wrong type. **Unverified:** what happens to an undeclared tag or field under a measurement the schema allows.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/influxdb/cloud/admin/buckets/bucket-schema.md

> Explicit bucket schemas ensure that measurements have specific columns and data types and prevent non-conforming write requests.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> the data must conform to the schema. Otherwise, InfluxDB rejects the data.

**The unit rejected is one field value, not one line.**

- InfluxDB's "point" is a series key, one field value and a timestamp, and `rejected_points` logs one entry for each rejected field.
- In the documented field-type example, two lines of three fields each are written, and only the second line's `temperature` has the wrong type. The response reports five points accepted and one rejected, and one entry is logged. So the other two fields of that line are written. That is Inferred from the example's counts and the definition of a point: the page does not say it of the line.
- In the measurement example, one line of three fields is logged as three entries.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/reference/key-concepts/data-elements.md

> A **point** includes the series key, a field value, and a timestamp

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> InfluxDB logs an entry for each point (each unique field) that is rejected.

> partial write error (5 accepted): 1 out of 6 points rejected

> InfluxDB logs three `rejected_points` entries, one for each field.

> For example, a partial write may occur when InfluxDB writes all points that conform to the bucket schema, but rejects points that have the wrong data type in a field.

**When the caller learns of a rejection.** Both explicit-schema examples return an error with the write request itself, a `400` in the field-type example. InfluxDB Cloud also acknowledges a write with `204` once it is validated and queued, and the page says points may still be rejected after that. **Unverified:** whether an explicit-schema rejection in particular can arrive after a `204`. The page does not say which applies.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> InfluxDB returns a `400` error and a message that describes the result:

> InfluxDB may still reject points after you receive _success_ (HTTP `204` status code).

**Stated why.** Yes for explicit schemas as such, but not for rejecting a non-conforming point rather than dropping it. The two documentation pages above give no reason. InfluxData's blog post introducing the feature (Russ Savage, published 2021-08-26, updated 2025-12-14) gives the problem it solves.

Source: https://www.influxdata.com/blog/new-bucket-schema-option-protect-from-unwanted-schema-changes/

> As your application grows, and more users are adding their own data, it can become tricky to ensure that the schema doesn’t get muddled up with junk. Some customers actually end up developing some sort of protection service to ensure only the right points make it to their production databases.

> To help solve this problem for our users, we have introduced a new option to explicitly define the schema of the data that can be written to a bucket.

**Constraints.** The explicit schema is opt-in per bucket, and the default bucket schema type is `implicit`. The blog post describes an implicit bucket as allowing "any schema". Even so, it checks a new point against the series already written, and rejects a point whose field has a conflicting data type, logging it in `rejected_points`. What an implicit bucket does with a new field or tag was not read.

Source: https://www.influxdata.com/blog/new-bucket-schema-option-protect-from-unwanted-schema-changes/

> the default for new buckets is to allow any schema, aka implicit

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/write-data/troubleshoot.md

> If a point has a field with a different data type than the series, InfluxDB rejects the point and logs a `rejected_points` entry.

Source: https://github.com/influxdata/docs-v2/blob/df4a7d5fcf18fe4b13277a4bdd6bc54e3f8e77d2/content/shared/influxdb-v2/reference/cli/influx/bucket/create.md

> Bucket schema type (`explicit`, default `implicit`) _(Cloud only)_.

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

### S11. Weaviate: a tenant named on a write to a collection without multi-tenancy

**Shape.** Named (the object or request carries a tenant) and scope-like (a tenant, which in Weaviate is also the shard the data lives on). The target is a collection declared without multi-tenancy. That is the default, and the declaration is per collection, as a table's is here. This comparable was found by the first adversarial review.

**What it does.** Read at tag `v1.36.0`. The write is **rejected**.

- A single create gets HTTP 422 with the message "class … has multi-tenancy disabled, but request was with tenant", and nothing is stored. The acceptance tests at the tag assert this.
- In a batch, each object that names a tenant fails on its own with that message. The source records the error at that object's position and carries on, so the rest of the batch is written. The batch acceptance test gives every object a tenant, so it does not exercise a mixed batch.
- The check runs in shard resolution: the resolver for a collection without multi-tenancy reads the object's tenant and validates it before it picks a shard. Which call raises the error first for a single create was not traced, because `AddObject` calls `EnsureTenantActiveForWrite` and `Exists` before the write.
- The rule dates from `v1.20.0`, the first release with multi-tenancy. It mirrors the rule that rejects a missing tenant on a multi-tenant collection.
- A tenant that is **inherited**, not named, is cleared rather than rejected. When a reference crosses from a multi-tenant collection into one without multi-tenancy, Weaviate's own code drops the source's tenant.

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/repos/db/multitenancy/validator.go

> // The returned validator will reject any requests that include tenant parameters.

> 				fmt.Errorf("class %s has multi-tenancy disabled, but request was with tenant", v.className),

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/repos/db/sharding/resolver.go

> 	tenant := object.Object.Tenant
> 	if err := r.tenantValidator.ValidateTenants(ctx, tenant); err != nil {

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/repos/db/index.go

> 			out[pos] = err

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/test/acceptance_with_go_client/multi_tenancy_tests/data_test.go

> 	t.Run("fails creating objects of non-MT class when tenant given", func(t *testing.T) {

> 		assert.Equal(t, 422, clientErr.StatusCode)

Source: https://github.com/weaviate/weaviate/blob/v1.20.0/adapters/repos/db/index.go

> 	} else if !i.partitioningEnabled && tenant != "" {

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/repos/db/search.go

> 	// if this is reference search and tenant is given (as origin class is MT)
> 	// but searched class is non-MT, then skip tenant to pass validation

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/usecases/objects/batch_references_add.go

> 		if err := validateTenantRefObject(ctx, repo, targetClass, target.TargetID, ""); err != nil {

**Visible?** To the caller, as the 422, or as the object's failed status in a batch. To the operator, as a user error in the REST requests-total metric, in the same family of branches as invalid user input and an unrecognised property. The metric's exported name was not looked up.

Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/handlers/rest/handlers_objects.go

> 	case errors.As(err, &uco.ErrMultiTenancy{}):
> 		e.logUserError(className)

**Stated why.** In part. A code comment states an aim, but no reason was found for refusing a named tenant rather than ignoring it.

- The comment on the validator states the aim. It was added in 2025 by pull request #9251, a refactor that moved the existing check into its own package, so it was not there when the rule was introduced.

  Source: https://github.com/weaviate/weaviate/blob/v1.36.0/adapters/repos/db/multitenancy/validator.go

  > // singleTenantValidator validates requests for collections with multi-tenancy disabled.
  > // It ensures that no tenant parameters are provided in requests to single-tenant
  > // collections, maintaining strict separation between single and multi-tenant modes.

- The pull request gives a reason for validating the tenant together with shard resolution, not for refusing it.

  Source: https://github.com/weaviate/weaviate/pull/9251

  > These two things need to happen together because you can't assign a shard without knowing if the tenant is valid first, considering also that the tenant is required if the collection is multi-tenant.

- The commit that introduced the rule, `9ab7a764bc` (2023-06-29), has no pull request, and its message gives no reason.

  Source: https://github.com/weaviate/weaviate/commit/9ab7a764bce0fc8c22a7ea7787eec6162babab98

  > adds multitenancy support for listing objects

- Also searched, with nothing found:
  - the multi-tenancy how-to page and the data concepts page in `weaviate/docs` at commit `6fcdb058b4`;
  - the launch blog post;
  - issue and pull request searches for "multi-tenancy disabled";
  - a commit search for the error text.

**Inferred why.** Inferred: in Weaviate a tenant names both the shard to write to and the shard to authorise against (`authorization.ShardsData(className, object.Tenant)` in `AddObject`). A collection without multi-tenancy has no tenant shards, so the request names a target that does not exist. No source states this.

**Constraints.**

- Multi-tenancy is opt-in per collection, and the launch post promised no change to collections that do not use it.

  Source: https://weaviate.io/blog/multi-tenancy-vector-search

  > Weaviate’s new multi-tenancy mode is opt-in. If you don’t require it, there are no changes for you.

- A tenant is a physically separate shard, kept separate for isolation.

  Source: https://weaviate.io/blog/multi-tenancy-vector-search

  > To make sure we have isolation for both technical and compliance reasons, Weaviate must also store the data per tenant separately.

  Source: https://github.com/weaviate/docs/blob/6fcdb058b4adc81fbbbd8a1ee8a00a6bc0b571d5/docs/weaviate/manage-collections/multi-tenancy.mdx

  > Multi-tenancy provides data isolation. Each tenant is stored on a separate shard.

- It is a server API. The caller gets an error for each request, or a status for each object in a batch.

**Costs and dissent.**

- The strict rule tripped Weaviate's own cross-reference paths, where the tenant was inherited from the source collection rather than named by the caller.
  - Pull request #3679 (2023, by a member of the Weaviate organisation, merged) fixed it for reference search.

    Source: https://github.com/weaviate/weaviate/pull/3679

    > Now whenever reference search on non-MT class is performed tenant is unset.

  - Issue #7281 (2025, opened by a contributor) reports it for reading references, and was still open on 2026-11-24. An outside contributor's fix, pull request #13925, was also still open.

    Source: https://github.com/weaviate/weaviate/issues/7281

    > fetch_objects method with return_references fails when a multi-tenant collection references a single-tenant collection.

- No complaint was found about the refusal of a tenant the caller named.

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

**Shape.** The same as F1, but a metric can be label-free in two ways, and they are handled differently.

- A plain `Counter` has no `With` method, so **the compiler rejects** a label named on it.
- A `CounterVec` built with zero label names is also label-free, and the maintainer confirms it is allowed. Its `With` accepts a `Labels` map at compile time. A map that names a label then fails the label-count check **at run time**: `With` panics and `GetMetricWith` returns the error. This was traced in the source at `v1.25.0`, not executed.

Source: https://github.com/prometheus/client_golang/issues/204#issuecomment-223248317

> Nothing is keeping you from using XxxVec's with 0 labels.

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/vec.go

> 	if err := validateValuesInLabels(labels, len(m.desc.variableLabels.names)-len(m.curry)); err != nil {

**What it does.** At `v1.25.0`, for a labelled metric, `GetMetricWith` **returns an error** when the label names or count are inconsistent with those declared, and `With` **panics** in the same cases.

Source: https://github.com/prometheus/client_golang/blob/v1.25.0/prometheus/counter.go

> // An error is returned if the number and names of the Labels are inconsistent
> // with those of the variable labels in Desc (minus any curried labels).

> // With works as GetMetricWith, but panics where GetMetricWithLabels would have
> // returned an error. Not returning an error allows shortcuts like

**Stated why.** Yes. beorn7, the maintainer, on issue #204:

Source: https://github.com/prometheus/client_golang/issues/204#issuecomment-223248317

> The current way was deliberately chosen (after literally weeks of intense discussion with very insightful Prometheans and Go developers) to allow the compiler to detect incorrect calls of label-less metrics with labels and vice versa. Ideally, the compiler would also detect the right number of labels, but that's not feasible with Go.

That reason covers a plain `Counter`. It does not cover a zero-label `CounterVec`, where the mistake only shows at run time.

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

3. **Logged**, once at WARN and afterwards at DEBUG, by default (pull request #5228, merged 2024-10-08). The tag-key check is still present at `v1.16.9` in `io.micrometer.prometheusmetrics.PrometheusMeterRegistry`.

   Source: https://github.com/micrometer-metrics/micrometer/pull/5228

   > A meter registration failure seems to be an important event for users, but it's not easy for the users to be aware of the failure unless they register a callback for it.

   Source: https://github.com/micrometer-metrics/micrometer/pull/5228#issuecomment-2212811290

   > It's better to lose some observability info than cause issues for the application. Logging this is far more reasonable if we're only talking about meter registration failures caused by instrumentation issues in code that users control in their application code, but it's a problem when we're talking about instrumentation issues in code that users don't control (third-party libraries).

4. **Accepted, in the current registry.** At `v1.18.0`, `io.micrometer.prometheusmetrics.PrometheusMeterRegistry` (artifact `micrometer-registry-prometheus`, on the Prometheus Java client 1.x) rejects only a mismatch of metric *type*, and has no tag-key check. The maintainer dates the change to 1.17, and the 1.17 migration guide records it. That version's source was not read.

   Source: https://github.com/micrometer-metrics/micrometer/issues/877#issuecomment-3924463517

   > With the Prometheus Java client 1.5.0 that was recently released, it included https://github.com/prometheus/client_java/issues/696. That unblocked us from supporting the same, and so this restriction has been removed from the Micrometer `PrometheusMeterRegistry`.

   Source: https://github.com/micrometer-metrics/micrometer/wiki/1.17-Migration-Guide

   > Additionally, we have removed the restriction that meters having the same name must all have the same set of tag names - see https://github.com/micrometer-metrics/micrometer/issues/877.

**The legacy registry is still at stage 2.** Micrometer ships two Prometheus registries.

Source: https://docs.micrometer.io/micrometer/reference/implementations/prometheus.html

> Micrometer uses the Prometheus Java Client under the hood; there are two versions of it and Micrometer supports both.

The legacy one, `io.micrometer.prometheus.PrometheusMeterRegistry`, is in the artifact `micrometer-registry-prometheus-simpleclient` and runs on the Prometheus Java client 0.x. At `v1.18.0` it is deprecated and still has the tag-key check.

- A mismatch goes to `meterRegistrationFailed`. This class does not override it, so only registered callbacks hear of the mismatch. Pull request #5228 added its log line to the current registry alone.
- The mismatched meter is left out of the scrape, silently unless a callback is registered.
- This was traced in the source, not executed.

Source: https://github.com/micrometer-metrics/micrometer/blob/v1.18.0/implementations/micrometer-registry-prometheus-simpleclient/src/main/java/io/micrometer/prometheus/PrometheusMeterRegistry.java

>  * @deprecated since 1.13.0, use the class with the same name from

>             if (existingCollector.getTagKeys().equals(tagKeys)) {

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

- Why a View may drop attributes: the same OTEP names, as one of its three use cases, an operator constraining cardinality.

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/oteps/metrics/0126-Configurable-Metric-Aggregations.md

  > 3) The application developer/operator wishes to constrain the cardinality of labels for metrics being reported
  > to the metric vendor/backend of choice.

- The project's error-handling principles, which apply to every API:

  Source: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.63.0/specification/error-handling.md

  > We assume that users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application.

  > 1. API methods MUST NOT throw unhandled exceptions when used incorrectly by end users.

  > Whenever the library suppresses an error that would otherwise have been exposed to the user, the library SHOULD log the error using language-specific conventions.

  > Application developers may want to run with strict error handling in a staging environment to catch invalid uses of the API, or malformed config.

- No passage was found arguing for **not counting** attributes a View drops.

**Inferred why.** Inferred: under these principles a View's drop is not an error, because it is the outcome the operator configured, so there is nothing to log.

**Constraints.** Instrumentation authors and operators are different people, and an operator may choose which attributes to keep in order to limit the cardinality sent to a back end. Operators reshape streams without touching instrumentation, and the library must never break the host application.

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

**Stated why.** Yes, by the author (gavinking), in review. The check was written in pull request #3867, which was closed unmerged. The same change landed through #4428 (merged 2021-12-08) as commit `8af548b52d`.

Source: https://github.com/hibernate/hibernate-orm/pull/4428

> Supersedes #3867.

- The first version overwrote a tenant id the application had set with the session's, and the author found that acceptable.

  Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706585040

  > Looks like it gets overwritten, which is fine, IMO.

- Asked to keep a value the user supplies, the author gave the reason against honouring it, and then made the mismatch an error.

  Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706590727

  > Well the thing is that it would let the user set up cross-tenant associations which would break the semantics of this stuff. An error would be better, probably, but it doesn't look like that's supported by the APIs I'm working with.

  Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706594299

  > I now enforce that the tenant id be correct.

- The stated reason is against honouring a mismatched tenant. For an error rather than the earlier overwrite, the thread gives only the preference "An error would be better, probably".
- The "root" tenant is the stated way out.

  Source: https://github.com/hibernate/hibernate-orm/pull/3867#issuecomment-918107706

  > I've introduced the notion of a "root" tenant, a sort of superuser, in order to provide a reasonable way to turn this functionality off.

- The commit message adds no reason of its own.

  Source: https://github.com/hibernate/hibernate-orm/commit/8af548b52d3cfbe438799f11665f035694f0e4dd

  > use this to throw exception from TenantIdGeneration

Also read: the three commits for HHH-6054, all 65 comments on Jira HHH-6054 (three long comments only in their first 400 characters), the user guide's chapter on multitenancy, and the `TenantId` and `CurrentTenantIdentifierResolver` javadocs.

**Constraints.** Discriminator multi-tenancy in one schema. The tenant comes from the session, and the root tenant is the way out for administrative writes.

**Costs and dissent.** Another member of the Hibernate organisation (beikov) argued in the same thread for keeping the supplied value, and against the check.

Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706588885

> Hmm, not sure if that is such a good idea. IMO if the user gives us a value, we should stick to that.

Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706607181

> Anyway, preventing to accidently set a wrong value is IMO the task of a developer by controlling the write access to the property through proper encapsulation and we shouldn't mess with that.

The author answered by also making the field non-updatable, and restated the reason.

Source: https://github.com/hibernate/hibernate-orm/pull/3867#discussion_r706618183

> Well I was already planning on having `@TenantId` imply `optional=false` and `updateable=false`.

> As soon as you have associations between rows with different tenant ids, our filters just aren't going to do the right thing.

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

**Costs and dissent.** One historical cost, since repaired: the switched tenant stayed current when the save failed. A user reported it on the pull request that introduced the switch.

Source: https://github.com/citusdata/django-multitenant/pull/88#discussion_r476198054

> fails (e.g. because of uniqueness validation), this `set_current_tenant` would not be executed and the code would continue with a "wrong" tenant

The pull request's author accepted the repair the reporter proposed, and the reporter confirmed it in v2.3.2. That release was not checked, because no `v2.3.2` tag was found.

Source: https://github.com/citusdata/django-multitenant/pull/88#discussion_r476383575

> That's a brilliant idea, I'll do that now.

Source: https://github.com/citusdata/django-multitenant/pull/88#discussion_r476528856

> I just tested `v2.3.2` and it worked like a charm.

At `v4.0.0` the tenant is restored in a `finally` block.

Source: https://github.com/citusdata/django-multitenant/blob/v4.0.0/django_multitenant/mixins.py

>         try:
>             obj = super().save(*args, **kwargs)
>         finally:
>             set_current_tenant(current_tenant)

No other cost or dissent was found in the sources read.

### F10. stancl/tenancy (Laravel) `BelongsToTenant`: the explicit tenant wins, unchecked (a different shape)

**Shape.** A different shape: a named tenant that conflicts with the ambient tenant on a tenant-scoped model. Scope-like.

**What it does.** At `v3.10.1`, when a model is created, the current tenant is set only if `tenant_id` is empty and the relation is not loaded. An explicit `tenant_id` is **kept**, and is never compared with the current tenant.

Source: https://github.com/archtechx/tenancy/blob/v3.10.1/src/Database/Concerns/BelongsToTenant.php

>             if (! $model->getAttribute(BelongsToTenant::$tenantIdColumn) && ! $model->relationLoaded('tenant')) {

The documentation calls tenant-free models "global models". How a `tenant_id` named on one is treated depends on how it is named.

- Through `fill()`, it falls to Eloquent's mass-assignment rules (F11), and is dropped silently only if the key is not fillable.
- Assigned directly as a property, it bypasses those rules: `__set` passes it to `setAttribute`, which stores it with no fillable check. What a later save does with it was not traced.

Source: https://github.com/laravel/framework/blob/v13.43.0/src/Illuminate/Database/Eloquent/Model.php

>         $this->setAttribute($key, $value);

Source: https://github.com/laravel/framework/blob/v13.43.0/src/Illuminate/Database/Eloquent/Concerns/HasAttributes.php

>         $this->attributes[$key] = $value;

Source: https://github.com/stancl/tenancy-docs/blob/2be4b681d0cee05451a27a4415de8d4e6345785c/source/docs/v3/single-database-tenancy.blade.md

> - global models — models that are **not scoped** to any tenant whatsoever

**Stated why.** No stated rationale found. Its issues were searched for "BelongsToTenant" and "tenant_id", and no thread discussed an explicit tenant that conflicts with the current one.

**Constraints.** Single-database tenancy, with the tenant applied by model events.

**Costs and dissent.** None found.

### F11. Laravel Eloquent `fill()`: attributes the model does not accept are discarded silently

**Shape.** Named and unknown-field-like: a key that is not in `$fillable`. It is scope-like when the key is `tenant_id` on a global model, passed through `fill()` (F10).

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

**What it does.** While a tenant is active, both libraries leave the ambient tenant off a shared or excluded model, by different mechanisms.

- **django-tenants falls back through the search path, and does not route.**
  - It sets the path to the tenant's schema followed by `public`, and PostgreSQL takes the first schema that has the table.
  - A shared model therefore resolves to `public` only when the tenant's schema has no table of that name, which holds for an app listed in `SHARED_APPS` alone. An app listed in both `SHARED_APPS` and `TENANT_APPS` is migrated into both schemas, and the tenant's copy is found first.
  - A connection set with `include_public=False` leaves `public` off the path. The library does that only while migrating.
  - The precedence is read from source. No documentation page read states it.
- **Apartment routes an excluded model explicitly.** Its PostgreSQL schema adapter qualifies the model's table name with the default schema, so the search path plays no part. Its database-per-tenant adapters give the model its own connection to the default database.

Source: https://github.com/django-tenants/django-tenants/blob/v4.0.7/django_tenants/postgresql_backend/base.py

>         Issue `SET search_path` for the currently selected schema. Database will
>         search schemata from left to right when looking for the object
>         (table, index, sequence, etc.).

>         elif self.include_public_schema:
>             search_paths = [self.schema_name, public_schema_name]

Source: https://github.com/django-tenants/django-tenants/blob/v4.0.7/django_tenants/tests/test_tenants.py

>         Tests that both SHARED_APPS and TENANT_APPS can have apps in common.
>         In this case they should get synced to both tenant and public schemas.

Source: https://github.com/rails-on-services/apartment/blob/v3.4.4/lib/apartment/adapters/postgresql_adapter.rb

>           # Then explicitly set to default schema to prevent tenant-based queries

>           klass.table_name = "#{default_tenant}.#{table_name}"

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

- **Kubernetes (body field and `kubectl`) drops the named scope silently. The Grafana family silently replaces it with a substitute tenant, on storage that stays tenant-scoped.**
  - No author gave a reason for ignoring a scope that is present.
  - Grafana's stated reason covers only the substitute tenant (S2), and a Kubernetes reviewer found the clear "weird" (S1).
- **Weaviate (S11), Elasticsearch TSDS, Spark, the Kubernetes URL path and Cosmos DB reject it.**
  - None states why a named value is refused rather than ignored.
  - Weaviate's code states an aim, "maintaining strict separation between single and multi-tenant modes", added after the rule. Weaviate clears a tenant *inherited* across a reference instead of rejecting it, so it treats the named and the inherited case differently.
  - Elasticsearch's author states what routing is for, and that a series cut across shards "would be a disaster" (S3).
  - In Elasticsearch and Cosmos DB the target derives its scope from the data, so a named scope would conflict with it rather than merely go unused. That reading is Inferred.

**Among the telemetry clients:**

- **Prometheus client_golang (F2) refuses at compile time on a plain `Counter`. On a `CounterVec`, including one built with no labels, it refuses at run time: `With` panics and `GetMetricWith` returns an error.**
  - Its maintainer's stated reason is that the compiler should catch "incorrect calls of label-less metrics with labels", and that covers the plain `Counter` only.
  - client_python (F1) raises, with no stated reason of its own.
- **OpenTelemetry Views (F4) and `tracing` (F6) drop silently.**
  - OpenTelemetry states two reasons. The project-wide one is "users would prefer to lose telemetry data rather than have the library significantly change the behavior of the instrumented application". The one specific to Views is that an operator "wishes to constrain the cardinality of labels" (OTEP 0126). So a View's drop is configured by an operator, not an error the library tolerates.
  - `tracing` states only its mechanism.
- **Micrometer (F3), in its current registry, went from raising, to dropping silently, to logging, to accepting.**
  - Each step has a stated reason.
  - Its deprecated legacy registry still leaves the mismatched meter out and tells only registered callbacks.
  - Against the change, a Prometheus contributor argued that a silent failure means "your graphs/alerts will silently break".

**Among the tenancy libraries (the conflicting shape):**

- **acts_as_tenant reversed** from silently overwriting a named tenant to failing validation, because the overwrite "was confusing and hid bugs" (F7).
- **Hibernate went, during the review of the change, from overwriting a named tenant to throwing.** Its author's reason is that honouring the tenant "would let the user set up cross-tenant associations", and a member of the project argued for keeping the supplied value (F8).
- **django-multitenant (F9) and stancl/tenancy (F10) keep the named tenant.** Neither states a reason.

**Among the unknown-field comparables:**

- **Rejection is the default** for BigQuery (S8), PostgreSQL (S10), and Rails and Django (F12).
- **Rejection is configured**, and is not the default, in Elasticsearch `dynamic: strict` (S7) and InfluxDB Cloud explicit bucket schemas (S9). InfluxDB rejects and counts per field value, not per line, and may report a rejection only after the write is acknowledged.
  - Elasticsearch's default, `dynamic: true`, adds the new field to the mapping, and `dynamic: false` keeps it in `_source` without indexing it.
  - InfluxDB's default bucket schema type is `implicit` (S9).
  - Both have a stated reason for the stricter mode: the Definitive Guide's "alert you to the problem" where Elasticsearch is the primary store, and InfluxData's protection against schemas "muddled up with junk".
- **ClickHouse (S6) and Laravel (F11) drop silently by default.**
  - ClickHouse's default came about as a side effect of a read-side change. In November 2026 a maintainer called it data loss and asked for a warning. The warning proposed does not cover data the client parses itself.
  - Laravel's reason is security, and its documentation calls the silence expected in production and confusing in development.
- **Elasticsearch's field limit (S7) gained an option to accept the document, with the surplus fields unmapped and unindexed and their names listed in `_ignored`.** Rejection stays the index default, and the built-in logs and metrics templates turn the option on. The reason given for the option and for the templates was that one misbehaving service could lose data for every service sharing the stream.

## Candidates not examined, or dropped

- **Not examined:** EF Core, the Rust `metrics` crate, structlog, Sentry scopes, Citus reference tables, VictoriaMetrics, Datadog and other hosted ingest (whose tenant comes from an API key, so it is ambient), and BigQuery partition decorators on a non-partitioned table.
- **Dropped:** Thanos Receive, because it has no tenancy-off mode. PostgreSQL row-level security, because it has a different shape (S10).
- **Read only in part:** the Hive rule for a partition spec on a non-partitioned table (an error is defined, but its use on the insert path was not traced), and the comment threads on Micrometer issue #877, client_java issue #696 and client_golang issue #1072.

## Fit, least surprise, options and recommendation

Not written yet. They follow the first adversarial review, as `REVIEW.md` requires.

## What the findings bear on in the specification

Not written yet, for the same reason.
