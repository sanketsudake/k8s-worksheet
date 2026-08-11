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
| Leader election (lease / renew / retry) | 15 s / 10 s / 2 s | Standard controller leader-election timings (Flow 20) |

### Rollout math (maxSurge / maxUnavailable)

| Field | Rounding | 10 replicas at the 25% default |
|---|---|---|
| `maxSurge` | Rounds **up** | 3 extra — up to 13 pods |
| `maxUnavailable` | Rounds **down** | 2 — at least 8 available |

The rounding directions are safety-biased: never less capacity than the percentage promises (Flow 15).

### Common container exit codes

| Code | Meaning | Usual cause |
|---|---|---|
| 0 | Clean exit | Completed (Jobs) or intentional stop |
| 1 | Application error | Unhandled failure in the app |
| 137 | SIGKILL (128+9) | OOM-kill, or grace period expired (Flows 9, 14) |
| 139 | SIGSEGV (128+11) | Segfault |
| 143 | SIGTERM (128+15) | Graceful stop honored (Flow 9) |

### Failure modes at a glance

The failure-mode matrix — which component going down breaks what — lives in Chapter 10 and is the best last-hour review table in the book; read it together with Flows 27 and 28.

## Appendix B — Glossary

- **Admission controller** — code that inspects or mutates an API request after authorization, before storage.
- **APF (API Priority and Fairness)** — API server mechanism that queues and fair-shares requests per flow so no client starves the rest.
- **Aggregated API** — a separate API server mounted under the main one, serving extra APIs (e.g. metrics).
- **Binding** — the API write that sets a pod's `nodeName`; the scheduler's actual output.
- **Bookmark** — a watch event that only advances the client's resourceVersion, keeping a resumed watch cheap.
- **CDI (Container Device Interface)** — the spec format a device driver hands the runtime to inject device nodes, mounts, and env into a container.
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
- **DeviceClass** — the DRA object an admin curates to preselect devices; the StorageClass analog.
- **EndpointSlice** — a chunk of a Service's backend addresses; sliced to keep watch updates small.
- **etcd** — the consistent key-value store holding all cluster state; raft-replicated.
- **Eviction** — removing a pod from a node: by node pressure (kubelet), by the eviction API (voluntary), or by taint-based deletion from the taint-eviction controller.
- **Expectations pattern** — a controller's in-memory note of writes it just made, so a lagging cache doesn't cause duplicates.
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
- **nominatedNodeName** — the pod status field marking where preemption freed room; a hint, not a reservation.
- **OwnerReference** — a pointer from a child object to its parent, driving cascading deletion.
- **PDB (PodDisruptionBudget)** — a floor on ready pods that voluntary evictions must respect.
- **PLEG (pod lifecycle event generator)** — the kubelet part that watches the runtime for container state changes and feeds the sync loop.
- **Preemption** — the scheduler evicting lower-priority pods to make room for a pending one.
- **Quorum** — the majority of etcd members required to commit writes.
- **Reconcile** — one run of a controller's logic for one object: observe, diff, act.
- **Reflector** — the informer part that performs the LIST and WATCH against the API server.
- **ResourceClaim** — the DRA object requesting a device for a pod; the PVC analog.
- **ResourceSlice** — the DRA object where a driver publishes device inventory the scheduler allocates from.
- **resourceVersion** — the change counter on every object; powers optimistic concurrency and watch resumption.
- **Resync** — periodic replay of the informer cache into handlers; not a re-LIST.
- **RuntimeClass** — the object selecting which runtime handler (runc, gVisor, Kata) runs a pod's sandbox.
- **Sandbox** — the pod's shared environment (network namespace, cgroup parent) created before containers.
- **Server-Side Apply (SSA)** — declarative PATCH where the API server merges fields and tracks per-field ownership.
- **Sidecar container** — an init container with `restartPolicy: Always`; runs alongside app containers (stable v1.33).
- **Static pod** — a pod run by the kubelet from a local file, independent of the API server.
- **Taint / toleration** — node-side repellent and pod-side exemption controlling placement and eviction.
- **Topology spread constraint** — a rule spreading replicas across zones or nodes.
- **VolumeAttachment** — the object recording that a volume is attached to a node; driven by the attach-detach controller.
- **Watch** — a streaming API request delivering object changes as events.
- **Watch cache** — the API server's per-resource in-memory cache that fans one etcd watch out to all clients.
- **Workqueue** — the rate-limited, deduplicating queue between informer events and reconciles.

## Appendix C — Answer-quality rubric

What interviewers listen for, by tier:

| Tier | The question probes | Strong signal | Weak signal |
|---|---|---|---|
| 1 — Explain | Mechanism accuracy | Correct sequence, correct *acting component* per step ("the kubelet restarts it", not "Kubernetes restarts it") | Vague agents ("the system"), wrong order, folklore |
| 2 — Reason | Trade-off awareness | Explains *why* the design, what breaks under the alternative, names the cost being paid | Restates the mechanism; "because it's better" |
| 3 — Design/Debug | Failure-mode and scale instincts | Asks clarifying questions, bisects systematically, sizes things (objects × bytes, qps), states blast radius and recovery | Jumps to one tool, ignores scale numbers, no failure story |
| 4 — Judge (principal+) | Consequence, economics, strategy | Frames the org and fleet consequence, names assumptions and kill-criteria, argues the strongest counter-position before committing, cites history ("we tried X, it failed because…") | Mechanism-perfect but consequence-free; "it depends" with no decision; trend name-dropping without a position |

Five signals that run across all tiers: (1) mechanism accuracy; (2) naming the acting component; (3) trade-off awareness; (4) failure-mode instincts — unprompted "and if that's down…"; (5) scale instincts — unprompted "and at 10k objects…".

Two more mark principal-level answers — and a staff candidate who shows them signals the next rung: (6) economic framing — cost, people, and risk enter the answer unprompted; (7) kill-criteria — the answer states what evidence would change the recommendation.

**Weak vs strong, same question** — "What happens when a liveness probe fails?"

*Weak:* "Kubernetes sees the pod is unhealthy and reschedules it to another node."

*Strong:* "The kubelet — probes are local, the control plane isn't involved — kills that container and restarts it in place per restartPolicy, with backoff. The pod stays on the node; nothing is rescheduled. If I wanted traffic removed instead, that's the readiness probe updating EndpointSlices. Mixing the two causes restart storms during dependency outages."

*Principal:* everything in the strong answer, then the unit of impact changes: "At fleet scale I don't rely on every team knowing this. One dependency-checking liveness probe pattern can restart-storm an entire tier, so the platform bans that shape by admission policy and makes the right probe the paved-road default. The mechanism is table stakes — the job is making the mistake impossible."

The strong answer names the actor, corrects the scope, contrasts the neighboring mechanism, and volunteers the failure mode. The principal answer keeps all of that and moves the blast radius from one pod to every team's pods — then does something about it.

## Appendix D — The principal's lens

Chapters 1–10 teach mechanisms. At principal and distinguished level the interview changes unit: from one cluster to a fleet, from correctness to cost, from "how does it work" to "what should we do". This appendix reframes each subsystem at that altitude, tabulates the recurring bets, and ends with critique prompts to argue out loud. Staff candidates: read it to see the next rung.

### Zoom out, chapter by chapter

- **Architecture (Ch 1).** Hub-and-spoke scales organizations, not just clusters: teams integrate by reading and writing objects, not by meetings. Consequence: the API server is your company's integration bus, and its schemas plus admission rules are de facto company policy — change them like public APIs.
- **API machinery (Ch 2).** The etcd ceiling is why fleets exist: you do not scale one cluster past its store, you multiply clusters — and inherit config distribution, drift, and upgrade waves. SSA field ownership is a multi-team contract; admission is the governance chokepoint where policy engines enforce compliance on every write.
- **Scheduling (Ch 3).** Scheduling is bin-packing economics. Requests are a price signal teams game: systematic over-requesting shows up as a "full" cluster at 40% usage, and the fix is incentive design — showback, quotas, right-sizing tools — not a scheduler flag.
- **The node (Ch 4).** Eviction ranking and QoS are a business-priority statement written in YAML. Decide platform-wide which classes of work die first under pressure; otherwise the defaults decide, and they do not know your revenue path.
- **Controllers (Ch 5–6).** The controller pattern is an org pattern. A CRD is an API your team supports forever — versioning, conversion, deprecation, every consumer. And many teams' controllers interacting produce emergent behavior nobody owns; someone must own the interaction budget, usually the platform team.
- **Networking (Ch 7).** The dataplane this book teaches — kube-proxy programming the kernel — is consolidating under eBPF CNIs, and the service-mesh layer above it (outside this book's scope) went sidecar-less (ambient mode GA since late 2024); sidecar proxies persist where heavy L7 policy earns their cost. NetworkPolicy doubles as a compliance artifact: auditors read it.
- **Storage (Ch 8).** Storage is where cloud lock-in actually lives: compute moves between clusters easily, volumes and their topology do not. Stateful-on-Kubernetes is a per-system judgment — operators made it routine for some databases, free for none.
- **Runtime and devices (Ch 9).** DRA is the project's bet that Kubernetes wins AI infrastructure. In accelerator fleets, device cost dominates everything else: scheduler efficiency is measured in money, and idle-GPU percentage is a board-level number.
- **Scale (Ch 10).** Past one cluster's limits you trade a technical problem for an organizational one. Every admission webhook, CRD, and controller you ship now has fleet-wide blast radius — design the staged-rollout system for platform changes before the fleet exists; retrofitting one during an incident is how fleets die.

### The recurring bets

**When Kubernetes is the wrong default**

| Workload shape | Why Kubernetes strains | What wins today | What would change the answer |
|---|---|---|---|
| Large-scale ML training | Gang, topology, and fabric scheduling are add-ons (Kueue, Volcano), not defaults | Slurm-class schedulers still run the biggest dedicated training fleets | DRA maturity plus queueing layers closing the gap |
| A handful of services | A platform team costs more than the product | PaaS or serverless | Fleet growth or compliance requirements |
| Bursty, event-shaped work | Paying for idle nodes; cold-start fights | Serverless platforms | A sustained baseline load appears |
| Hard real-time or kernel-bypass | The abstraction is in the way: scheduling jitter, network stack | Bare metal, specialized OS | Rarely changes |
| Single-purpose edge appliance | A full control plane per site is overhead | k3s-class distributions or plain OS | Fleet management outgrowing the OS |

**Tenancy models**

| Model | Isolation | Cost | Ops load | Blast radius | Fits when |
|---|---|---|---|---|---|
| Namespaces + quotas | Soft: shared kernel and control plane | Lowest | One cluster | Control-plane failures hit everyone | Trusted teams, cost-sensitive |
| Cluster per team | Hard | Highest: control plane and headroom per team | A fleet | Contained per team | Low trust, hard compliance lines |
| Virtual clusters | Control-plane isolation on shared nodes | Middle | Novel tooling to run | Node-level faults still shared | API isolation without a hardware split |

**Managed vs self-hosted control plane**

| | You own | You give up | Economics | Choose when |
|---|---|---|---|---|
| Managed | Workloads and node config | etcd access, upgrade timing, apiserver flags | The fee beats one SRE until the fleet is large | The default answer |
| Self-hosted | Everything, including etcd tuning and version choice | The provider's guardrails | Pays off at large fleets or special requirements | Compliance, bare metal, deep control-plane needs |

**Multi-cluster patterns**

| Pattern | Coordination | Failure story | Blast radius | Fits when |
|---|---|---|---|---|
| Replicated independent clusters | None at runtime; CD applies the same config N times | One cluster dies, the others never notice | Smallest | The default; failover lives above (DNS, global LB) |
| Hub-spoke controller | A hub cluster reconciles the spokes | Hub outage freezes fleet change; hub compromise is fleet compromise | Largest | Fleet config at scale, with the hub risk priced in |
| Federated API layer | One API facade over many clusters | The facade is a new SPOF and a version-skew surface | Middle | Rare: genuine multi-cluster scheduling needs |

### Critique prompts

Argue both sides out loud, then commit — expect the follow-up to attack whichever side you take.

1. **"Kubernetes is too complex for 90% of the teams using it."** For: most teams need "run my container, give it a URL" and inherit a distributed system instead. Against: the complexity belongs to the domain — Kubernetes just refuses to hide it, and platforms on top can. A position: both are true at different layers; the real failure is organizational — handing raw Kubernetes to product teams instead of a paved road built on it.
2. **"etcd was the wrong choice."** For: the ~8 GiB practical ceiling and watch fan-out cap cluster size and forced the fleet era. Against: strict consistency made resourceVersion, watches, and optimistic concurrency simple enough to build an ecosystem on. A position: right choice then; the mistake today is treating one etcd as the unit of scale — cluster sharding is the working answer, sharded list/watch the upstream one.
3. **"CRDs created an unmaintainable ecosystem."** For: every install drags in third-party APIs with unowned lifecycles; abandoned operators rot clusters. Against: CRDs are why Kubernetes won — the extensibility flywheel produced the ecosystem that made it the default. A position: the flywheel was worth it; the missing half is discipline — own your CRDs like public APIs, audit third-party ones like dependencies.
4. **"The service-mesh sidecar was a mistake."** For: per-pod proxies taxed every pod's memory and latency, and their lifecycle problems were bad enough that Kubernetes built native sidecar support (Chapter 4). Against: sidecars delivered mesh features a decade before kernels could, with per-pod isolation. A position: right pattern for its decade; L3/L4 belongs in the kernel now (eBPF, ambient), and sidecars retreat to the heavy-L7 cases that still pay their rent.
5. **"Kubernetes will lose AI training to specialized schedulers."** For: Slurm-class systems still own the biggest training fleets; gang and topology scheduling remain add-ons. Against: DRA is GA, queueing layers are maturing, and "everything else already runs here" is enormous gravity. A position: inference is already Kubernetes'; training converges as DRA and queueing close the gap — bet on convergence, and keep a bridge to the dedicated fleet meanwhile.

## Appendix E — Further reading

**Official docs (stable top-level pages)**

- Kubernetes concepts: https://kubernetes.io/docs/concepts/ — architecture, workloads, and the controller model.
- Reference section: https://kubernetes.io/docs/reference/ — API conventions and the "API Concepts" page (resourceVersion semantics, watches, SSA).
- Large-cluster considerations and scalability thresholds: https://kubernetes.io/docs/setup/best-practices/cluster-large/
- etcd documentation: https://etcd.io/docs/ — raft, quotas, maintenance (compaction, defrag, snapshot restore).

**Lineage papers (read before a distinguished-level loop)**

- "Large-scale cluster management at Google with Borg" (EuroSys 2015) — the system Kubernetes distilled.
- "Borg, Omega, and Kubernetes" (ACM Queue, 2016) — the design lessons across all three, from the people who built them.

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
