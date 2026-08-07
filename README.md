# k8s-worksheet

**Kubernetes Internals Interview Worksheet** — a flow-first prep guide for senior and staff-level interviews on Kubernetes internals.
It is built around 27 end-to-end "what happens when…" flows, each traced step by step from the command you type to the container that runs, with a diagram and the ways it fails in production.
Around those flows sit ~90 tiered interview questions with model answers, and three find-the-bug controller-runtime exercises.
Content baseline is Kubernetes v1.36; the whole thing builds to a ~113-page PDF.

## Chapters

**Part A — Foundations & control plane internals**

- [Chapter 1 — Architecture Big Picture](chapters/ch01.md) · Flow 1
- [Chapter 2 — API Server & etcd Internals](chapters/ch02.md) · Flows 2–4
- [Chapter 3 — Scheduler Internals](chapters/ch03.md) · Flows 5–7
- [Chapter 4 — Kubelet, Pods & the Node](chapters/ch04.md) · Flows 8–14, including the master flow

**Part B — Controllers**

- [Chapter 5 — Controller Fundamentals](chapters/ch05.md) · Flows 15–16
- [Chapter 6 — Writing Controllers Well](chapters/ch06.md) · Flows 17–19, plus the code exercises

**Part C — Standards & extension interfaces**

- [Chapter 7 — Networking & CNI](chapters/ch07.md) · Flows 20–22
- [Chapter 8 — Storage & CSI](chapters/ch08.md) · Flows 23–24
- [Chapter 9 — Runtime & Device Standards: CRI, Device Plugins, DRA](chapters/ch09.md) · Flow 25

**Part D — Operating at scale**

- [Chapter 10 — Scalability, Resiliency & System Design](chapters/ch10.md) · Flows 26–27

**Reference**

- [Appendices](chapters/appendices.md) — quick-reference tables, glossary, answer-quality rubric, further reading

## Contributing

Build instructions, the writing contract, and the diagram size gate are in [CONTRIBUTING.md](CONTRIBUTING.md).
