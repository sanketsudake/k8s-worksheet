# Research notes — version-sensitive facts (verified Aug 2026)

Baseline for the worksheet: **Kubernetes v1.36** (released April 2026, "Haru"). v1.37 is in progress.

Facts to state correctly (with the version where they became true):

- **DRA (Dynamic Resource Allocation): GA since v1.34** (Aug 2025), using structured parameters (KEP-4381). The old "classic DRA" with opaque parameters was removed earlier. DRA is the forward path for GPUs/accelerators; device plugins still exist but DRA is the modern answer. Continued additions in v1.35/1.36 (multiple-driver support, workload-aware scheduling work).
- **kube-proxy nftables mode: GA in v1.33**. iptables remains the default mode; nftables is the performance-oriented option. IPVS still exists.
- **Native sidecar containers** (init containers with `restartPolicy: Always`): introduced v1.28, **stable in v1.33**.
- **In-place pod resize (resize CPU/memory without restart): GA in v1.35.** Pod-level resources: beta (v1.34→beta, still maturing in v1.36).
- **Server-Side Apply**: GA since v1.22 — safe to describe as the standard mechanism.
- **API Priority and Fairness (APF)**: GA since v1.29.
- **ValidatingAdmissionPolicy (CEL, in-process admission)**: GA since v1.30; **MutatingAdmissionPolicy** newer (beta ~v1.34+). Webhooks remain widely used.
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

Writing rule: give the version only when it matters for correctness or is likely to come up in interview ("GA since v1.34"), otherwise describe behavior as current. Never describe alpha features as default behavior.

Sources: kubernetes.io release blogs for v1.34 (2025-08-27), v1.35 (2025-12-17), v1.36 (2026-04-22); kubernetes.io DRA updates posts (v1.33, v1.34); nftables kube-proxy blog (2025-02).
