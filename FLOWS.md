# The 28 flows

Every flow traces one event end to end, from the command you type to the container that runs.
Each has numbered steps, a diagram, and the ways it fails in production.

Flow 8 is the master flow: other chapters zoom into their segment of it and say so.

## Part A — Foundations & control plane internals

**[Chapter 1 — Architecture Big Picture](chapters/ch01.md)**

1. [What happens when you run kubectl apply](chapters/ch01.md#flow-1-what-happens-when-you-run-kubectl-apply)

**[Chapter 2 — API Server & etcd Internals](chapters/ch02.md)**

2. [What happens when two controllers write the same object](chapters/ch02.md#flow-2-what-happens-when-two-controllers-write-the-same-object)
3. [What happens when a watch is established — and falls behind](chapters/ch02.md#flow-3-what-happens-when-a-watch-is-established--and-falls-behind)
4. [What happens when an admission webhook is down](chapters/ch02.md#flow-4-what-happens-when-an-admission-webhook-is-down)

**[Chapter 3 — Scheduler Internals](chapters/ch03.md)**

5. [What happens when a pod is created and a node is chosen](chapters/ch03.md#flow-5-what-happens-when-a-pod-is-created-and-a-node-is-chosen)
6. [What happens when no node fits](chapters/ch03.md#flow-6-what-happens-when-no-node-fits)
7. [What happens when a taint is applied to a node](chapters/ch03.md#flow-7-what-happens-when-a-taint-is-applied-to-a-node)

**[Chapter 4 — Kubelet, Pods & the Node](chapters/ch04.md)**

8. [What happens when a pod goes from created to Running (master flow)](chapters/ch04.md#flow-8-what-happens-when-a-pod-goes-from-created-to-running-master-flow)
9. [What happens when a pod is deleted](chapters/ch04.md#flow-9-what-happens-when-a-pod-is-deleted)
10. [What happens when a node is cordoned](chapters/ch04.md#flow-10-what-happens-when-a-node-is-cordoned)
11. [What happens when a node is drained](chapters/ch04.md#flow-11-what-happens-when-a-node-is-drained)
12. [What happens when a node dies](chapters/ch04.md#flow-12-what-happens-when-a-node-dies)
13. [What happens when a probe fails](chapters/ch04.md#flow-13-what-happens-when-a-probe-fails)
14. [What happens when a node comes under memory pressure](chapters/ch04.md#flow-14-what-happens-when-a-node-comes-under-memory-pressure)

## Part B — Controllers

**[Chapter 5 — Controller Fundamentals](chapters/ch05.md)**

15. [What happens when you edit or scale a Deployment](chapters/ch05.md#flow-15-what-happens-when-you-edit-or-scale-a-deployment)
16. [What happens when the HPA scales a Deployment](chapters/ch05.md#flow-16-what-happens-when-the-hpa-scales-a-deployment)
17. [What happens when you delete an object that owns others](chapters/ch05.md#flow-17-what-happens-when-you-delete-an-object-that-owns-others)

**[Chapter 6 — Writing Controllers Well](chapters/ch06.md)**

18. [What happens when one reconcile runs, end to end](chapters/ch06.md#flow-18-what-happens-when-one-reconcile-runs-end-to-end)
19. [What happens when a controller pod restarts](chapters/ch06.md#flow-19-what-happens-when-a-controller-pod-restarts)
20. [What happens when leader election hands over](chapters/ch06.md#flow-20-what-happens-when-leader-election-hands-over)

## Part C — Standards & extension interfaces

**[Chapter 7 — Networking & CNI](chapters/ch07.md)**

21. [What happens when a pod gets its network (CNI ADD)](chapters/ch07.md#flow-21-what-happens-when-a-pod-gets-its-network-cni-add)
22. [What happens when a pod sends a request to a ClusterIP Service](chapters/ch07.md#flow-22-what-happens-when-a-pod-sends-a-request-to-a-clusterip-service)
23. [What happens when a pod becomes Ready (endpoint propagation)](chapters/ch07.md#flow-23-what-happens-when-a-pod-becomes-ready-endpoint-propagation)

**[Chapter 8 — Storage & CSI](chapters/ch08.md)**

24. [What happens when a PVC is created and a pod uses it](chapters/ch08.md#flow-24-what-happens-when-a-pvc-is-created-and-a-pod-uses-it)
25. [What happens when a pod with a volume moves to another node](chapters/ch08.md#flow-25-what-happens-when-a-pod-with-a-volume-moves-to-another-node)

**[Chapter 9 — Runtime & Device Standards: CRI, Device Plugins, DRA](chapters/ch09.md)**

26. [What happens when a pod requests a GPU via DRA](chapters/ch09.md#flow-26-what-happens-when-a-pod-requests-a-gpu-via-dra)

## Part D — Operating at scale

**[Chapter 10 — Scalability, Resiliency & System Design](chapters/ch10.md)**

27. [What happens when the control plane is down](chapters/ch10.md#flow-27-what-happens-when-the-control-plane-is-down)
28. [What happens when etcd loses quorum](chapters/ch10.md#flow-28-what-happens-when-etcd-loses-quorum)
