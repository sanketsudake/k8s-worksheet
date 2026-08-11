# Research notes — version-sensitive facts (verified Aug 2026)

Baseline for the worksheet: **Kubernetes v1.36** (released April 2026, "Haru"). v1.37 is in progress.

Facts to state correctly (with the version where they became true):

- **DRA (Dynamic Resource Allocation): GA since v1.34** (Aug 2025), using structured parameters (KEP-4381). The old "classic DRA" with opaque parameters was removed earlier. DRA is the forward path for GPUs/accelerators; device plugins still exist but DRA is the modern answer. Continued additions in v1.35/1.36 (multiple-driver support, workload-aware scheduling work).
- **kube-proxy nftables mode: GA in v1.33**. iptables remains the default mode; nftables is the performance-oriented option. IPVS still exists.
- **Native sidecar containers** (init containers with `restartPolicy: Always`): introduced v1.28, **stable in v1.33**.
- **In-place pod resize (resize CPU/memory without restart): GA in v1.35.** Pod-level resources: beta (v1.34→beta, still maturing in v1.36).
- **Server-Side Apply**: GA since v1.22 — safe to describe as the standard mechanism.
- **API Priority and Fairness (APF)**: GA since v1.29.
- **ValidatingAdmissionPolicy (CEL, in-process admission)**: GA since v1.30; **MutatingAdmissionPolicy: GA in v1.36** (beta since ~v1.34). Webhooks remain widely used.
- **Gateway API**: standard channel mature; **v1.5 (2026): TCPRoute and UDPRoute moved to Standard**. Position Gateway API as the successor to Ingress (Ingress is frozen, not removed).
- **User namespaces: GA in v1.36.**
- **Declarative validation for K8s APIs: GA in v1.36** (internal API-machinery improvement — mention only if useful).
- **Sharded list/watch (server-side): beta in v1.36** — relevant to the scalability chapter as "recent work to reduce list storms".
- **In-place Pod restart / container restart improvements**: v1.35 work.
- **Extended toleration operators (numeric comparisons): alpha in v1.35** — do not present as usable default.
- **EndpointSlices** replaced Endpoints as the scalable mechanism (Endpoints API deprecated ~v1.33).
- **Decoupled taint manager: stable in v1.34** (node lifecycle controller split — relevant to taint-eviction flow).
- **cgroup v2** is the assumed node baseline (v1 deprecated); memory QoS work ongoing.
- etcd: v3 API, revisions/watch/lease model; watch cache in API server serves most watches.

Facts added for the principal's-lens pass (verified Aug 2026):

- **Service mesh / dataplane direction**: Istio ambient (sidecar-less) mode GA since Istio 1.24 (Nov 2024); by 2026 new mesh deployments default to sidecar-less/eBPF designs, with sidecar proxies persisting for L7-heavy cases. eBPF CNIs are consolidating the kernel dataplane. Sources: istio.io ambient GA; 2026 mesh-state industry coverage.
- **AI training schedulers**: Slurm-class schedulers still common for large dedicated training fleets (native gang/topology/fabric scheduling); Kubernetes closes the gap via DRA plus queueing/gang layers (Kueue, Volcano — quota/admission and gang scheduling respectively, often layered). HPC-style features are arriving in production Kubernetes through 2026. Treat "who wins training" as an open bet, not a settled fact.
- **Lineage citations (stable)**: "Large-scale cluster management at Google with Borg" (EuroSys 2015); "Borg, Omega, and Kubernetes" (ACM Queue, 2016).
- **Frontier project status (for Ch 12)**: Crossplane CNCF **Graduated** (Oct 2025) — the "control plane for everything" pattern is mainstream. SpinKube (WASM workloads on K8s): CNCF Sandbox (Jan 2025), active but early — never present WASM as a default. KCP: active project, multi-tenant Kubernetes-like control planes for platform engineering. Karpenter-class node provisioning: name the pattern, make no version claims. Sources: cncf.io project pages, 2026 KubeCon EU coverage.
- The when-not-Kubernetes / tenancy / managed-vs-self-hosted content is judgment framing, not version-sensitive fact.

Facts added for the coverage-additions pass (verified Aug 2026):

- **HPA defaults**: control loop every 15s (`--horizontal-pod-autoscaler-sync-period`); tolerance 0.1 (no scale when current/target is within 10% of 1); downscale stabilization window 300s, upscale 0s; per-HPA `behavior` policies override these; per-HPA configurable tolerance is alpha since v1.33 — do not present as default. Formula: `desired = ceil(current × currentMetric/targetMetric)`; HPA writes only the scale subresource.
- **Version skew**: kubelet may be up to **3 minor versions older** than kube-apiserver (since kubelet v1.25; never newer). KCM/scheduler/CCM: not newer than the API server, up to 1 minor older. HA API servers: within 1 minor of each other. kubectl: ±1 minor. Upgrade order: etcd → kube-apiserver → KCM/scheduler → kubelet.
- **ServiceAccount tokens**: projected, audience- and pod-bound tokens via the TokenRequest API; default lifetime 1h, kubelet refreshes before expiry. Auto-created Secret-based tokens are gone since v1.24 (LegacyServiceAccountTokenNoAutoGeneration).
- **CronJob**: with no `startingDeadlineSeconds`, >100 missed schedules since the last run stops the controller from starting jobs ("too many missed start time"); `startingDeadlineSeconds` bounds the counting window. `concurrencyPolicy`: Allow (default) / Forbid / Replace; Forbid skips count as missed. `timeZone` field is GA.
- **ConfigMap/Secret propagation**: mounted values refresh on the kubelet sync period (default 1 min) plus cache TTL — up to ~2 min of lag; `subPath` mounts never update; env vars never update (restart needed); immutable ConfigMaps/Secrets close the kubelet's watches and refuse edits.

Writing rule: give the version only when it matters for correctness or is likely to come up in interview ("GA since v1.34"), otherwise describe behavior as current. Never describe alpha features as default behavior.

Sources: kubernetes.io release blogs for v1.34 (2025-08-27), v1.35 (2025-12-17), v1.36 (2026-04-22); kubernetes.io DRA updates posts (v1.33, v1.34); nftables kube-proxy blog (2025-02). For the coverage-additions facts (verified 2026-08): kubernetes.io HPA walkthrough and algorithm docs, releases/version-skew-policy, cron-jobs concepts page, security/service-accounts, configure-pod-configmap tasks page.
