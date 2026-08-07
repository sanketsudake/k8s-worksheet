# STYLE.md — rules every chapter must follow

**What this document is:** the contract for writing chapters of the "Kubernetes Internals Interview Worksheet". Follow it exactly so all chapters read as one book.

## Audience and voice

- Reader: senior/staff engineer preparing for a deep Kubernetes interview.
- Simple technical English. Short sentences (aim ≤ 20 words). One idea per paragraph. Paragraphs ≤ 4 sentences.
- Define every piece of jargon at first use, in one clause: "the informer (a client-side cache that watches the API server)".
- High signal, low noise: no filler ("It is important to note that…", "In the world of Kubernetes…"), no marketing tone, no repetition of what another section already said — cross-reference instead ("see Flow 1").
- Present tense. Active voice. "The scheduler writes a Binding" not "A Binding is written".
- Never invent facts. Version-sensitive claims MUST match `notes/research-notes.md`. Baseline is Kubernetes v1.36.

## File format

- One markdown file per chapter: `chapters/chNN.md` (`ch01.md` … `ch10.md`, `appendices.md`).
- Start with `# Chapter N — Title`. Use `##` for sections, `###` for flows and questions. No deeper nesting.
- No HTML in the markdown. Tables in GitHub style. Code in fenced blocks with language tag (`yaml`, `go`, `bash`).

## Chapter shape (in this order)

1. **Opening ("Why this chapter")** — 3–6 sentences: what the interviewer is probing here and the one mental model to hold.
2. **Concepts** — the minimum background needed to follow the flows. Keep short; teach details inside the flows.
3. **Flows** — the heart of the chapter (format below).
4. **Questions** — tiered Q&A (format below).
5. **Common mistakes & red flags** — 4–8 bullets: wrong things candidates often say, each with the correction.

## Flow format (strict)

Each flow is a `###` section titled: `### Flow N: What happens when <event>` (N = the global flow number from the plan).

Contents, in order:

1. One-sentence setup ("You run `kubectl cordon node-1`.").
2. **Numbered steps.** Each step starts with the acting component in bold: `1. **kubectl** sends a PATCH …`. One actor-action per step. 6–15 steps. If a step hides interview-relevant depth, add an indented sub-bullet, max one per step.
3. **A mermaid diagram** in a fenced ` ```mermaid ` block, immediately after the steps, followed by an italic caption line: `*Figure N.M — one line saying what to notice.*` (N = chapter, M = running count within chapter).
4. **Where this can fail** — 3–6 bullets: `- **Symptom:** … **Cause:** … **Where to look:** …`.

## Mermaid rules (build breaks if you're clever)

- Allowed types only: `sequenceDiagram`, `flowchart TD` (preferred) / `flowchart LR`, `stateDiagram-v2`.
- Sequence diagrams for under-the-hood flows; flowcharts for decisions; state diagrams for lifecycles.
- Participant names short and consistent across ALL chapters: `User`, `API` (kube-apiserver), `etcd`, `Sched` (kube-scheduler), `KCM` (controller-manager), `Kubelet`, `CRI` (container runtime), `CNI`, `CSI`, `KProxy` (kube-proxy), `Ctrl` (a custom controller).
- Keep it simple: no `%%{init}%%` directives, no `par`/`critical` blocks; `alt`/`opt`/`Note` are fine. Label every arrow with a short verb phrase.
- In node/edge labels avoid characters that break mermaid: `(){}[]<>"`; use plain words. Quote a label only using double quotes if it contains spaces plus special chars — better: avoid entirely. No HTML anywhere in a diagram body.
- `sequenceDiagram`: start with `autonumber`. Keep to ≤ 6 participants. Message text ≤ 6 words — message length is what makes these diagrams too wide to read.

### The size gate (this is a hard limit, not a preference)

The page gives a diagram **174 mm** of width and **150 mm** of height, and the image is scaled by
`min(174/W, 150/H)`. So a diagram that is too **tall** shrinks exactly like one that is too **wide**.
Mermaid's label font is ~16 px; below about 7 pt it is unreadable in print.

**Every diagram must render within W ≤ 1000 px and H ≤ 950 px.**

Check before you commit:

```bash
python3 build/check_diagrams.py chapters/ch04.md      # or chapters/*.md
```

`build/mermaid-config.json` already tightens sequence-diagram layout (narrower actor boxes and
margins) and both the build and the checker render with it. Mermaid's stock 150 px actor box puts a
floor of roughly 1,450 px under a seven-participant diagram, which is unreadable on A4; the tuned
config removes that floor, so you should not need to drop an actor to make a diagram fit.

Staying inside the gate:

- ≤ 12 nodes per diagram, ≤ 3 nodes per rank, ≤ 4 words per node or edge label.
- **Never drop a participant, node or edge to make a diagram fit.** Shorten the label text instead.
  A diagram that omits a real step is a worse defect than one that is hard to read, and removing a
  subgraph box is not licence to wire its members together — grouping is not a call path.
- Prefer `flowchart TD`. Use `LR` only for genuinely short chains.
- Avoid subgraphs that carry edges to nodes outside themselves — the layout goes wide regardless.
- If a diagram cannot fit, that usually means it is making two points. Say so and get the split reviewed
  rather than shrinking labels into noise — splitting adds a figure and **renumbers every later figure
  in the chapter**, and figure numbers are referenced from prose in other chapters.

### Colour: class nodes by semantic role

Flowcharts and state diagrams carry a small semantic palette, so role reads at a glance.
`classDef` is **not supported in `sequenceDiagram`** — those use `autonumber` and stay uncoloured.

| Class | Use for | Fill | Stroke |
|---|---|---|---|
| `leader` | active / primary actor | `#10b981` | `#047857` |
| `standby` | passive / waiting | `#94a3b8` | `#475569` |
| `lease` | coordination primitive (lock, lease, queue) | `#f59e0b` | `#b45309` |
| `resource` | the resource being acted on | `#fb7185` | `#be123c` |
| `external` | external system (cloud API, plugin) | `#64748b` | `#334155` |
| `process` | logic, decision, generic step | `#38bdf8` | `#0369a1` |

All fills use `color:#fff`. Rules:

- Declare only the classes the diagram uses.
- Once you class one node, class **every** node — a half-coloured diagram looks broken.
- Put `classDef` and `class` lines at the bottom of the diagram body. Inside a subgraph, after the `end`.

```
  classDef process fill:#38bdf8,stroke:#0369a1,color:#fff
  class AUTHN,AUTHZ process
```

### Caption coupling (silent failure if you get this wrong)

`build/build.py` matches a diagram with the regex ` ```mermaid … ``` ` followed by **only whitespace**
and then the `*Figure N.M — caption*` line. Put anything else between them and the match fails: the build
still exits 0 and raw mermaid source lands in the PDF. Keep the caption immediately after the closing
fence, on its own line, as plain italic text with no internal `**bold**`.

## Question format (strict)

Section `## Questions`. Three subsections: `### Tier 1 — Explain`, `### Tier 2 — Reason`, `### Tier 3 — Design & Debug`.

Each question:

```
**Q N.M — Question text?**

**Answer.** 5–15 lines. Direct answer first, then mechanism.

*Strong answers also mention:* one or two things that distinguish a great candidate.
```

Number questions `N.M` per chapter (chapter.number, continuous across tiers). Per chapter: 3–4 Tier 1, 3–4 Tier 2, 2–3 Tier 3. Tier 3 questions are scenarios: a symptom to debug or a system to design — the answer walks the reasoning, not just the conclusion.

## Cross-references

- Refer to flows by global number ("Flow 8"), figures by "Figure 4.2", chapters by "Chapter 5".
- The master flow is Flow 8 (pod creation → Running, Chapter 4). Other chapters zoom into their segment of it and say so.

## Length budgets (hard-ish)

- Ch 1: ~1,400 words · Ch 2: ~2,400 · Ch 3: ~1,700 · Ch 4: ~2,200
- Ch 5: ~2,400 · Ch 6: ~2,800 (incl. code exercises)
- Ch 7: ~2,400 · Ch 8: ~1,900 · Ch 9: ~1,900
- Ch 10: ~2,600 · Appendices: ~1,600
- Over budget → cut noise, not flows. Diagrams don't count against words.

## Code-reading exercises (Chapter 6 only)

Three short Go snippets (15–35 lines each) using controller-runtime, each with 1–3 planted bugs. Format: the snippet, then `**What's wrong?**`, then the answer explaining the bug, why it hurts in production, and the fix. Bugs must be realistic (non-idempotent create, status update racing on stale object, requeue storm, missing finalizer removal).
