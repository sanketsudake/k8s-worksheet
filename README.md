# k8s-worksheet

**Kubernetes Internals Interview Worksheet** — a flow-first prep guide for senior/staff-level interviews on Kubernetes internals, controllers, and the standards around them (CNI, CSI, CRI, DRA).

- 10 chapters + appendices, ~108 pages as PDF
- 27 end-to-end "what happens when…" flows with sequence diagrams and failure modes
- ~90 tiered interview questions with model answers
- 3 find-the-bug controller-runtime code exercises
- Content baseline: Kubernetes v1.36

## Repo layout

```
chapters/     One markdown file per chapter — this is the content you edit
  ch01.md     Architecture big picture          (Flow 1)
  ch02.md     API server & etcd internals       (Flows 2-4)
  ch03.md     Scheduler internals               (Flows 5-7)
  ch04.md     Kubelet, pods & the node          (Flows 8-14, incl. master Flow 8)
  ch05.md     Controller fundamentals           (Flows 15-16)
  ch06.md     Writing controllers well          (Flows 17-19 + code exercises)
  ch07.md     Networking & CNI                  (Flows 20-22)
  ch08.md     Storage & CSI                     (Flows 23-24)
  ch09.md     CRI, device plugins & DRA         (Flow 25 + extension map)
  ch10.md     Scalability, resiliency & design  (Flows 26-27)
  appendices.md  Quick-reference tables, glossary, rubric, further reading
STYLE.md      The writing contract — read before editing any chapter
notes/        Research notes (version facts) and the original plan
build/        PDF build pipeline (build.py, style.css, cover.html)
dist/         Build output (gitignored): the PDF, rendered diagrams
```

## Making changes

1. Read `STYLE.md` first — it defines the chapter shape, flow format, mermaid rules, and question format that keep the book consistent.
2. Edit the relevant `chapters/*.md`. Diagrams are mermaid blocks inline in the markdown; each must be followed by an italic `*Figure N.M — caption*` line.
3. Version-sensitive claims should match `notes/research-notes.md`; update that file when a new Kubernetes release changes a fact.
4. Rebuild the PDF (below) and check the output.

## Building the PDF

### Prerequisites

```bash
pip install -r requirements.txt          # markdown + weasyprint
npm install -g @mermaid-js/mermaid-cli   # provides mmdc (needs Chrome/Chromium)
```

WeasyPrint needs system libraries (Debian/Ubuntu): `apt install libpango-1.0-0 libpangoft2-1.0-0 fonts-dejavu fonts-liberation`. On macOS: `brew install pango`.

If mermaid can't find a browser, point it at one: `export CHROME_PATH=/path/to/chrome`.

### Build

```bash
make pdf          # or: python3 build/build.py
open dist/kubernetes-internals-worksheet.pdf
```

Diagrams are cached in `dist/diagrams/` by content hash — only changed diagrams re-render, so incremental builds are fast.

### CI

Every push to `main` builds the PDF in GitHub Actions and uploads it as a workflow artifact (`.github/workflows/build-pdf.yml`). Pushing a tag like `v1.0` also attaches the PDF to a GitHub release.

## Roadmap ideas

- Questions-only "candidate edition" (answers are structurally marked, so they can be stripped programmatically)
- Per-release fact refresh when new Kubernetes versions ship
