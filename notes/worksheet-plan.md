# Plan: Kubernetes Internals Interview Worksheet

> Historical planning document. The flow catalog in Section 3 is superseded by FLOWS.md (30 flows as of Aug 2026 — the HPA flow was added as Flow 16; Part E added Flows 29–30).

**Goal:** A comprehensive (~40–60 page), PDF-exportable worksheet that helps candidates prepare for senior/staff-level interviews on Kubernetes, its internals, controllers, and the surrounding standards (CNI, CSI, CRI, DRA, Gateway API, etc.).

**Audience:** Senior / Staff engineers. Style: simple technical English, diagram-heavy, questions with detailed model answers, mostly conceptual with some code-reading exercises.

---

## 1. What the worksheet is (design principles)

- **Flows are the backbone.** The worksheet is organized around end-to-end "what happens when…" walkthroughs. Each flow is presented the same way: a numbered step-by-step narrative (one component action per step) + a sequence diagram + "where this can fail" notes. Concepts are introduced *through* flows, not before them — e.g., informers are explained inside the "pod creation" flow at the moment the scheduler learns about the new pod. The full flow catalog is in Section 3.
- **One consistent chapter format.** Every chapter follows the same rhythm so it is easy to read: short concept explanation → the chapter's flows (narrative + diagram + failure notes) → questions with model answers → common mistakes / red flags.
- **Simple language, deep content.** Short sentences. One idea per paragraph. Jargon is always defined the first time it appears. Depth comes from the *content* (what actually happens under the hood), not from complex prose.
- **Diagrams carry the explanation.** Target roughly one diagram per 1.5–2 pages. Each diagram is referenced in the text ("see Figure 3.2") and has a one-line caption saying what to notice.
- **Questions are layered.** Each topic has 3 tiers:
  - **Tier 1 – Explain:** "Walk me through what happens when…" (mechanism recall)
  - **Tier 2 – Reason:** "Why is it designed this way? What breaks if…" (trade-offs)
  - **Tier 3 – Design/Debug:** "Design a controller that… / Here's a symptom, find the cause" (senior/staff signal)
- **Model answers teach, not just answer.** Each answer is 5–15 lines: the direct answer, the underlying mechanism, and one "a strong candidate also mentions…" note so readers know what distinguishes a great answer.

---

## 2. Proposed structure (10 chapters + appendices)

### Part A — Foundations & Control Plane Internals

**Ch. 1 — Architecture Big Picture** (~4 pages)
Control plane vs data plane, what runs where, the "everything is a reconcile loop against desired state in etcd" mental model.
*Diagrams:* full cluster architecture; request path from `kubectl apply` to running pod (the single most important diagram in the book — referenced by later chapters).

**Ch. 2 — API Server & etcd Internals** (~6 pages)
Request lifecycle: authn → authz → admission (mutating/validating webhooks, CEL admission policies) → validation → storage. etcd's role: raft basics, revisions, watches, compaction. resourceVersion semantics, optimistic concurrency, Server-Side Apply and field management, API aggregation vs CRDs, watch cache, priority & fairness (APF).
*Diagrams:* API request pipeline with admission chain; watch event flow from etcd to clients; conflict on stale resourceVersion.

**Ch. 3 — Scheduler Internals** (~4 pages)
Scheduling framework: queueing → filtering → scoring → binding; extension points; preemption; affinity/anti-affinity, topology spread; what happens when no node fits.
*Diagrams:* scheduling framework pipeline; preemption decision flow.

**Ch. 4 — Kubelet, Pods & the Node** (~5 pages)
Pod lifecycle on the node: kubelet sync loop, CRI calls, sandbox creation, init/sidecar containers, probes, cgroups & QoS classes, eviction, static pods. What "a pod is running" actually means.
*Diagrams:* pod startup sequence (kubelet ↔ CRI ↔ runtime ↔ CNI); QoS/eviction ladder; pod termination sequence (grace period, SIGTERM/SIGKILL, finalizers).

### Part B — Controllers (the core of the worksheet)

**Ch. 5 — Controller Fundamentals** (~6 pages)
The reconcile pattern: observe → diff → act. Level-triggered vs edge-triggered and why Kubernetes chooses level-triggered. Informers, listers, shared informer cache, work queues, resync. Owner references and garbage collection. Built-in controllers as case studies: Deployment → ReplicaSet → Pod chain; StatefulSet ordering; Job/CronJob.
*Diagrams:* informer/workqueue machinery (reflector → delta FIFO → indexer → handlers → queue → reconciler); Deployment rollout state machine.

**Ch. 6 — Writing Controllers Well (controller-runtime & practices)** (~7 pages)
CRD design (spec/status split, conditions conventions, versioning & conversion webhooks). controller-runtime: manager, caches, builder, Owns/Watches/mapping functions. Efficient practices: idempotent reconciles, no state in memory between reconciles, status updates vs spec writes, requeue strategies & backoff, rate limiting, finalizers done right, leader election, expectations pattern, avoiding hot loops (status-update-triggers-reconcile), server-side apply from controllers, watch filtering with predicates and label selectors to cut cache memory.
*Code-reading exercises live here:* 2–3 short flawed reconciler snippets ("find the bug": e.g. non-idempotent create, missing finalizer removal, update racing on stale object, requeue storm).
*Diagrams:* reconcile decision flowchart; finalizer/deletion flow; "bad loop" diagram showing a self-triggering reconcile.

### Part C — Standards & Extension Interfaces

**Ch. 7 — Networking & CNI** (~6 pages)
What CNI actually is (a binary contract invoked by the runtime, not a daemon API): ADD/DEL calls, plugin chaining, IPAM. Pod-to-pod networking models (overlay vs routed). Services under the hood: kube-proxy modes (iptables/IPVS/nftables), conntrack, ClusterIP → endpoint selection path. EndpointSlices. DNS. Ingress vs Gateway API. NetworkPolicy: who enforces it and why kube-proxy doesn't.
*Diagrams:* CNI ADD sequence during pod creation; packet path for a ClusterIP request (client pod → iptables/IPVS → backend pod); overlay vs routed comparison.

**Ch. 8 — Storage & CSI** (~5 pages)
Why CSI exists (out-of-tree drivers). CSI architecture: controller plugin vs node plugin, sidecars (external-provisioner, attacher, resizer, snapshotter), gRPC services. Full volume lifecycle: PVC → provision → attach → mount (stage/publish) → pod use → teardown. Access modes, topology, binding modes (Immediate vs WaitForFirstConsumer), snapshots and expansion.
*Diagrams:* CSI component layout (which piece runs where); end-to-end dynamic provisioning + attach/mount sequence diagram.

**Ch. 9 — Runtime, Device & Resource Standards: CRI, DRA & friends** (~5 pages)
CRI: what the kubelet asks of the runtime, containerd/CRI-O, sandboxes. Device Plugins and their limits → DRA (Dynamic Resource Allocation): ResourceClaims, DeviceClasses, structured parameters, how the scheduler participates — why DRA replaces device plugins for GPUs/accelerators. Where the other extension points sit: CPU/topology manager, NRI, KMS, cloud providers (CCM). A one-page "map of all extension interfaces" that ties CNI/CSI/CRI/DRA/webhooks/aggregation together.
*Diagrams:* extension-interface map (the second most important diagram); DRA allocation flow (claim → scheduler → driver → kubelet).

### Part D — Operating at Scale

**Ch. 10 — Scalability, Resiliency & System Design** (~7 pages)
Scalability: what actually limits cluster size (etcd object count/size, watch fan-out, API server memory, per-node pod density). Controller scale: cache memory, list storms on restart, resync cost, sharding strategies. Resiliency: what still works when the control plane is down (data plane keeps running — a classic interview question), etcd quorum loss, kubelet disconnection & node lifecycle, PodDisruptionBudgets, topology spread, graceful degradation. Multi-tenancy and blast radius. HA control plane layout. Design questions in classic interview form: "Design an operator that manages 10k objects", "Design multi-cluster failover", "Your API server latency spiked — walk me through debugging".
*Diagrams:* failure-mode matrix (component down × what breaks/keeps working); HA control plane topology; controller sharding pattern.

### Appendices
- **A. Quick-reference tables:** resourceVersion rules, QoS classes, probe types, admission phases, requeue/backoff defaults.
- **B. Glossary** of every term used (one-liners, simple English).
- **C. Answer-quality rubric** — what interviewers listen for at each tier (useful for both candidates and interviewers).
- **D. Further reading:** KEPs, source-code entry points (`kube-controller-manager` controllers, `client-go` tool packages), and key docs.

**Estimated totals:** ~55 pages, ~30 diagrams (most of them flow/sequence diagrams), ~80–100 questions with model answers, ~3 code-reading exercises.

---

## 3. Flow catalog (the core content)

Every flow below gets the full treatment: numbered narrative + sequence diagram + failure-mode notes + at least one interview question ("walk me through…", "at which step would X break?"). Mapped to the chapter that hosts it:

**Ch. 1–2 (API server & etcd)**
1. `kubectl apply -f pod.yaml` → object persisted: client-side (kubeconfig, discovery) → authn → authz → mutating admission → validation → validating admission → etcd write → watch events fan out. *(The anchor flow — later flows link back to it.)*
2. What happens on a conflicting write (two controllers update the same object) — resourceVersion conflict, retry, Server-Side Apply path.
3. What happens when a watch is established — and what happens when it falls behind (resync, relist, "too old resource version").
4. What happens when a webhook is down (failurePolicy, cluster-wide blast radius).

**Ch. 3 (Scheduler)**
5. Pod created → node chosen: queue entry → filter → score → reserve → permit → bind, and what "binding" actually writes.
6. What happens when **no node fits** — pending pod, preemption decision, victim eviction, nominatedNodeName.
7. What happens when a **taint is applied** to a node — NoSchedule vs NoExecute, tolerationSeconds, taint-based eviction by the node lifecycle controller.

**Ch. 4 (Kubelet & node)**
8. **Pod creation → Running (end-to-end master flow):** scheduler binds → kubelet watch fires → admission on the node → sandbox via CRI → CNI ADD → image pull → init containers → volumes mounted → containers started → probes pass → Ready → endpoints updated → traffic arrives. *(Spans chapters; presented as one full-page diagram with per-chapter zoom-ins.)*
9. Pod deletion → gone: grace period, SIGTERM, preStop hooks, endpoint removal ordering (why traffic can still arrive during shutdown), SIGKILL, finalizers, API object removal.
10. What happens when a **node is cordoned** — what it does (unschedulable flag) and, just as important, what it does *not* do (running pods stay; contrast with drain).
11. What happens when a **node is drained** — cordon + evictions, PDB checks, DaemonSet exception, where drain gets stuck.
12. What happens when a **node dies / kubelet stops heartbeating** — lease expiry, node lifecycle controller, NoExecute taint, pod eviction & the StatefulSet "don't force it" caveat.
13. What happens when a **liveness/readiness probe fails** (restart vs endpoint removal — and why confusing the two is a classic outage).
14. What happens under **memory pressure** — kubelet eviction ranking (QoS), vs OOM-kill (kernel), and how the two differ.

**Ch. 5–6 (Controllers)**
15. `kubectl scale deployment` (or edit) → rollout: Deployment controller → new ReplicaSet → surge/unavailable math → pods created → rollout status. Including rollback flow.
16. Object deleted with owner references → cascading GC flow (foreground/background/orphan).
17. One reconcile, end to end, inside a controller: watch event → workqueue → dedupe → reconcile → status write → (avoiding) self-retrigger. *(This is the flow the code-reading exercises break.)*
18. Controller pod restarts → informer cold start: list storm, cache sync, why reconciles must be idempotent.
19. Leader election handover flow.

**Ch. 7 (Networking)**
20. Pod gets its network: CNI ADD sequence — who calls whom, netns, veth, IPAM, routes.
21. A request to a ClusterIP Service, packet by packet: DNS → VIP → iptables/IPVS DNAT → conntrack → backend; plus what changes for NodePort/LoadBalancer.
22. Endpoint update propagation: pod becomes Ready → EndpointSlice update → kube-proxy reprograms rules (and the latency window this creates).

**Ch. 8 (Storage)**
23. PVC created → pod using it: provision → bind (Immediate vs WaitForFirstConsumer) → attach → NodeStage → NodePublish → in-container mount; and the teardown ordering in reverse.
24. What happens when a pod with a volume moves nodes (detach/attach races, multi-attach errors).

**Ch. 9 (CRI/DRA)**
25. DRA flow: ResourceClaim → scheduler consults driver → allocation → kubelet prepares device → container sees GPU.

**Ch. 10 (Scale & failure)**
26. What still happens — and what stops happening — when the **control plane is down** (data plane keeps serving; no new scheduling, no self-healing; step through each component).
27. etcd loses quorum → observable behavior flow (reads/writes/watches, and recovery).

The catalog is the checklist for completeness: a chapter is "done" when its flows are written, diagrammed, and questioned. New flows can be added in review (e.g., HPA scale-up flow, cert rotation) without changing the structure.

## 4. Diagram approach

- **Tooling:** Mermaid for sequence/flow diagrams (renders cleanly to SVG/PDF, easy to edit as text and keep in the project), hand-built SVG only where Mermaid is too rigid (e.g., the architecture map).
- **Types used deliberately:**
  - *Sequence diagrams* for anything "under the hood" (pod creation, CSI mount, CNI ADD, watch events) — these answer "what talks to what, in what order", which is exactly what interviewers probe.
  - *Flowcharts* for decision logic (scheduling, eviction, reconcile logic, requeue).
  - *Block/topology diagrams* for architecture and "what runs where".
  - *State machines* for lifecycles (pod phases, Deployment rollout, PV binding).
- Consistent visual language throughout: same colors for control plane vs node vs external components; every figure numbered and captioned.

## 5. PDF pipeline

- **Source of truth:** one Markdown file per chapter, stored in this project (so any future session can edit or regenerate).
- **Build:** Markdown + rendered diagram SVGs → styled HTML → PDF (via headless Chromium in the session workspace). This gives: cover page, table of contents with page numbers, chapter headers, footer with page numbers, consistent typography, and diagrams that stay crisp at print size.
- **Deliverables:** a single shareable PDF; the Markdown chapters remain in the project so we can maintain a "questions-only" candidate variant later with near-zero extra effort (answers are structurally marked, so they can be stripped programmatically).

## 6. Build order (phased, reviewable)

Each phase ends with a draft PDF sent to you, so you can course-correct early instead of reviewing 55 pages at the end.

- **Phase 0 — Skeleton & style proof (first checkpoint).** Chapter outline, the two anchor diagrams (request path, extension-interface map), and one fully written sample **flow** — "pod creation → Running" (flow #8), end to end with narrative, diagram, failure notes, and questions — rendered as a sample PDF to lock the look, tone, and format. You review, we adjust.
- **Phase 1 — Part B first (Ch. 5–6).** Controllers are the heart of the stated interview focus, so they get written first and deepest.
- **Phase 2 — Part A (Ch. 1–4).** Control plane internals; reuses the anchor diagrams.
- **Phase 3 — Part C (Ch. 7–9).** Standards: CNI, CSI, CRI, DRA. Includes a quick web check of current state (e.g., DRA GA status, current Kubernetes version behaviors) so the content isn't stale.
- **Phase 4 — Part D + appendices (Ch. 10, A–D).** Scalability/resiliency/design questions, glossary, rubric.
- **Phase 5 — Polish & final PDF.** Consistency pass (terms, figure numbering, cross-references), simple-English pass (shorten sentences, kill jargon), fact verification pass against current Kubernetes docs, final typeset PDF.

## 7. Quality checks (built into Phase 5, not left to chance)

- **Technical accuracy:** verify version-sensitive claims (DRA, sidecar containers, APF, nftables kube-proxy, Gateway API status) against current upstream docs.
- **Readability:** every paragraph ≤ 4 sentences; every term in the glossary; diagrams referenced from text.
- **Interview realism:** each chapter's Tier 3 questions cross-checked against the style of real senior interview questions (debugging scenarios, trade-off defenses, design prompts).
- **Answer key quality:** every model answer includes the "strong candidate also mentions" note.

---

**Open point for later (not blocking):** once the full PDF exists, we can cheaply generate the questions-only candidate variant if you want it — the structure supports it.
