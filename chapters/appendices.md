# Appendices

## Appendix A — Quick-reference tables

### resourceVersion semantics (get / list / watch)

| Operation | resourceVersion | Meaning |
|---|---|---|
| get | unset | Most recent: quorum read through etcd — strongest, most expensive |
| get | `"0"` | Any: served from the API server watch cache, may be stale |
| get | `"<rv>"` | Not older than the given version |
| list | unset | Most recent: quorum read, full cost — the expensive one |
| list | `"0"` | Any: served from watch cache; what informers use on relist |
| list | `"<rv>"` + `resourceVersionMatch: NotOlderThan` | At least that fresh, cache-friendly |
| list | `"<rv>"` + `resourceVersionMatch: Exact` | Exactly that version; fails if compacted away |
| watch | unset | Sends current state as synthetic ADDED events, then streams from most recent |
| watch | `"0"` | Same, but the starting snapshot may be stale |
| watch | `"<rv>"` | Stream events strictly after that version; `410 Gone` if compacted — the "too old resource version" relist trigger (Flow 3) |

### QoS classes and eviction order

| QoS class | Definition | Kubelet eviction rank | OOM behavior |
|---|---|---|---|
| Guaranteed | requests = limits for every container (CPU and memory) | Evicted last | Lowest OOM score adj (-997), killed last |
| Burstable | Some requests set, not fully guaranteed | Middle: ranked by usage above requests, then priority | OOM score scales with request size |
| BestEffort | No requests or limits | Evicted first | Highest OOM score adj (1000), killed first |

Kubelet eviction (node pressure, Flow 14) ranks by: usage exceeding requests first, then pod priority, then how far usage exceeds requests. Kernel OOM-kill is separate and ranks by OOM score, not by kubelet policy.

### Probe types and effects

| Probe | On failure | What it does NOT do |
|---|---|---|
| Liveness | Kubelet restarts the container (per restartPolicy) | Does not remove from Service endpoints first |
| Readiness | Pod marked NotReady; removed from EndpointSlices; traffic stops | Does not restart anything |
| Startup | Holds liveness/readiness until it passes; failure past threshold restarts the container | Does not run again after first success |

Confusing liveness with readiness is a classic outage: restart storms where you needed traffic removal (Flow 13).

### Admission pipeline order (write request)

| Order | Phase | What runs |
|---|---|---|
| 1 | Authentication | Certs, tokens, OIDC — who are you |
| 2 | Authorization | RBAC — may you do this |
| 3 | Mutating admission | Built-in mutating plugins, MutatingAdmissionPolicy, mutating webhooks — may change the object |
| 4 | Schema validation | Structural check against the API type |
| 5 | Validating admission | Built-in validators, ValidatingAdmissionPolicy (CEL), validating webhooks — may only reject |
| 6 | Storage | Write to etcd; watch events fan out |

Mutation always precedes validation, so validators see the final object (Flow 1, Flow 4).

### Default workqueue rate limits (client-go / controller-runtime)

| Limiter | Default | Effect |
|---|---|---|
| Per-item exponential backoff | 5 ms base, doubling, 1000 s cap | A repeatedly failing item retries at 5ms, 10ms, 20ms … up to ~16.7 min |
| Overall token bucket | 10 qps, burst 100 | Caps total requeue rate across all items |

The default limiter takes the slower of the two. Per-item backoff resets on `Forget` (successful reconcile).

### Grace periods and timing defaults

| Setting | Default | Meaning |
|---|---|---|
| `terminationGracePeriodSeconds` | 30 s | SIGTERM → wait → SIGKILL window (Flow 9) |
| `kubectl delete --grace-period=0 --force` | — | Deletes the API object without waiting; container may still be running |
| Node lease renew interval | 10 s | Kubelet heartbeat |
| `node-monitor-grace-period` | 50 s | Missed heartbeats before NotReady |
| Default NoExecute toleration | 300 s | Time pods stay on an unreachable node before eviction (Flow 12) |
| Leader election (lease / renew / retry) | 15 s / 10 s / 2 s | Standard controller leader-election timings (Flow 19) |

## Appendix B — Glossary

- **Admission controller** — code that inspects or mutates an API request after authorization, before storage.
- **APF (API Priority and Fairness)** — API server mechanism that queues and fair-shares requests per flow so no client starves the rest.
- **Aggregated API** — a separate API server mounted under the main one, serving extra APIs (e.g. metrics).
- **Binding** — the API write that sets a pod's `nodeName`; the scheduler's actual output.
- **CNI (Container Network Interface)** — the binary contract the runtime invokes to wire a pod into the network.
- **Condition** — a typed status entry (`type`, `status`, `reason`) reporting one aspect of an object's state.
- **Conntrack** — the kernel's connection-tracking table; remembers NAT decisions per flow.
- **Container runtime** — the software (containerd, CRI-O) that actually creates and runs containers.
- **Controller** — a loop that watches desired state and acts to make actual state match it.
- **CRD (CustomResourceDefinition)** — an object that adds a new API type to the cluster.
- **CRI (Container Runtime Interface)** — the gRPC API the kubelet uses to talk to the runtime.
- **CSI (Container Storage Interface)** — the gRPC contract storage drivers implement for provisioning and mounting volumes.
- **DRA (Dynamic Resource Allocation)** — the claim-based API (GA since v1.34) for allocating devices like GPUs.
- **DeltaFIFO** — the informer's internal queue of object changes between the reflector and the cache.
- **EndpointSlice** — a chunk of a Service's backend addresses; sliced to keep watch updates small.
- **etcd** — the consistent key-value store holding all cluster state; raft-replicated.
- **Eviction** — removing a pod from a node: by node pressure (kubelet), by the eviction API (voluntary), or by taint-based deletion from the taint-eviction controller.
- **Finalizer** — a marker on an object that blocks its deletion until a controller removes the marker.
- **Gateway API** — the successor to Ingress for traffic routing; Ingress is frozen, not removed.
- **Garbage collection (GC)** — deletion of objects whose owners (via ownerReferences) are gone.
- **HPA (Horizontal Pod Autoscaler)** — controller that changes replica counts based on metrics.
- **Informer** — a client-side cache that lists then watches a resource and calls handlers on changes.
- **Kubelet** — the node agent that runs pods via CRI and reports status.
- **kube-proxy** — the per-node component programming Service routing rules (iptables, IPVS, or nftables).
- **Leader election** — using a Lease object so only one replica of a controller acts at a time.
- **Lease** — a small object renewed periodically to signal liveness (node heartbeats, leader election).
- **Level-triggered** — reacting to observed state, not to individual events; missed events don't matter.
- **Lister** — a read interface over an informer's cache; no API calls.
- **OwnerReference** — a pointer from a child object to its parent, driving cascading deletion.
- **PDB (PodDisruptionBudget)** — a floor on ready pods that voluntary evictions must respect.
- **Preemption** — the scheduler evicting lower-priority pods to make room for a pending one.
- **Quorum** — the majority of etcd members required to commit writes.
- **Reconcile** — one run of a controller's logic for one object: observe, diff, act.
- **Reflector** — the informer part that performs the LIST and WATCH against the API server.
- **resourceVersion** — the change counter on every object; powers optimistic concurrency and watch resumption.
- **Resync** — periodic replay of the informer cache into handlers; not a re-LIST.
- **Sandbox** — the pod's shared environment (network namespace, cgroup parent) created before containers.
- **Server-Side Apply (SSA)** — declarative PATCH where the API server merges fields and tracks per-field ownership.
- **Sidecar container** — an init container with `restartPolicy: Always`; runs alongside app containers (stable v1.33).
- **Static pod** — a pod run by the kubelet from a local file, independent of the API server.
- **Taint / toleration** — node-side repellent and pod-side exemption controlling placement and eviction.
- **Topology spread constraint** — a rule spreading replicas across zones or nodes.
- **Watch** — a streaming API request delivering object changes as events.
- **Workqueue** — the rate-limited, deduplicating queue between informer events and reconciles.

## Appendix C — Answer-quality rubric

What interviewers listen for, by tier:

| Tier | The question probes | Strong signal | Weak signal |
|---|---|---|---|
| 1 — Explain | Mechanism accuracy | Correct sequence, correct *acting component* per step ("the kubelet restarts it", not "Kubernetes restarts it") | Vague agents ("the system"), wrong order, folklore |
| 2 — Reason | Trade-off awareness | Explains *why* the design, what breaks under the alternative, names the cost being paid | Restates the mechanism; "because it's better" |
| 3 — Design/Debug | Failure-mode and scale instincts | Asks clarifying questions, bisects systematically, sizes things (objects × bytes, qps), states blast radius and recovery | Jumps to one tool, ignores scale numbers, no failure story |

Five signals that run across all tiers: (1) mechanism accuracy; (2) naming the acting component; (3) trade-off awareness; (4) failure-mode instincts — unprompted "and if that's down…"; (5) scale instincts — unprompted "and at 10k objects…".

**Weak vs strong, same question** — "What happens when a liveness probe fails?"

*Weak:* "Kubernetes sees the pod is unhealthy and reschedules it to another node."

*Strong:* "The kubelet — probes are local, the control plane isn't involved — kills that container and restarts it in place per restartPolicy, with backoff. The pod stays on the node; nothing is rescheduled. If I wanted traffic removed instead, that's the readiness probe updating EndpointSlices. Mixing the two causes restart storms during dependency outages."

The strong answer names the actor, corrects the scope, contrasts the neighboring mechanism, and volunteers the failure mode.

## Appendix D — Further reading

**Official docs (stable top-level pages)**

- Kubernetes concepts: https://kubernetes.io/docs/concepts/ — architecture, workloads, and the controller model.
- Reference section: https://kubernetes.io/docs/reference/ — API conventions and the "API Concepts" page (resourceVersion semantics, watches, SSA).
- Large-cluster considerations and scalability thresholds: https://kubernetes.io/docs/setup/best-practices/cluster-large/
- etcd documentation: https://etcd.io/docs/ — raft, quotas, maintenance (compaction, defrag, snapshot restore).

**Load-bearing KEPs** (browse by number at https://github.com/kubernetes/enhancements)

- KEP-4381 — DRA structured parameters: the design that took Dynamic Resource Allocation to GA.
- KEP-753 — Sidecar containers: why sidecars are init containers with `restartPolicy: Always`.
- KEP-1040 — API Priority and Fairness: the request-classification and queuing model.
- KEP-555 — Server-Side Apply: field management and merge semantics.

**Source-code entry points**

- https://github.com/kubernetes/kubernetes — `pkg/controller/` holds the built-in controllers (deployment, replicaset, job, nodelifecycle); readable and canonical.
- https://github.com/kubernetes/client-go — `tools/cache/` (reflector, DeltaFIFO, informers) and `util/workqueue/`; the machinery of Chapter 5.
- https://github.com/kubernetes-sigs/controller-runtime — the manager/builder/reconciler stack of Chapter 6.
- https://github.com/kubernetes/sample-controller — the smallest complete controller against raw client-go; read it once, end to end.
