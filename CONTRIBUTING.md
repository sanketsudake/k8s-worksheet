# Contributing

Everything needed to edit a chapter and rebuild the PDF.

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
build/        PDF build pipeline
  build.py            Renders diagrams, assembles HTML, writes the PDF
  check_diagrams.py   Diagram size gate — run before committing
  style.css, cover.html
dist/         Build output (gitignored): the PDF, rendered diagrams
```

## Making changes

1. Read [STYLE.md](STYLE.md) first.
It defines the chapter shape, flow format, mermaid rules, and question format that keep the book consistent.
2. Edit the relevant `chapters/*.md`.
Diagrams are mermaid blocks inline in the markdown; each must be followed immediately by an italic `*Figure N.M — caption*` line.
3. Version-sensitive claims should match `notes/research-notes.md`.
Update that file when a new Kubernetes release changes a fact.
4. Run the diagram gate, then rebuild the PDF and check the output.

### Two things that fail silently

**Caption pairing.**
`build.py` pairs a diagram with its caption using a regex that allows only whitespace between the closing fence and the `*Figure ...*` line.
Break that pairing and the build still exits 0, but raw mermaid source lands in the PDF.

**Diagram size.**
The page gives a diagram 174 mm of width and 150 mm of height, and the image is scaled to fit both.
A diagram that is too tall shrinks exactly like one that is too wide, and its labels drop below readable size in print.

`build/check_diagrams.py` catches both:

```bash
python3 build/check_diagrams.py chapters/ch04.md    # one chapter
python3 build/check_diagrams.py chapters/*.md       # everything
```

It renders each diagram, reports the size a label actually prints at, and fails if any diagram exceeds W 1000 px or H 950 px.
Adding or removing a figure renumbers every later figure in that chapter, and figure numbers are referenced from prose in other chapters — so grep for the old numbers before you do it.

## Building the PDF

### Prerequisites

```bash
pip install -r requirements.txt          # markdown + weasyprint
npm install -g @mermaid-js/mermaid-cli   # provides mmdc (needs Chrome/Chromium)
```

WeasyPrint needs system libraries.
On Debian/Ubuntu: `apt install libpango-1.0-0 libpangoft2-1.0-0 fonts-dejavu fonts-liberation`.
On macOS: `brew install pango`.

If mermaid cannot find a browser, point it at one:

```bash
export CHROME_PATH=/path/to/chrome
```

### Build

```bash
make pdf          # or: python3 build/build.py
open dist/kubernetes-internals-worksheet.pdf
```

Diagrams are cached in `dist/diagrams/` by content hash, so only changed diagrams re-render and incremental builds are fast.

## CI

`.github/workflows/build-pdf.yml` builds the PDF on every push to `main` and on every pull request, and uploads it as a workflow artifact.
Pushing a tag like `v1.0` also attaches the PDF to a GitHub release.
The workflow can be run by hand from the Actions tab (`workflow_dispatch`), which is the way to check a branch before opening a PR.

Dependabot keeps the action pins and Python dependencies current, grouped into one weekly PR per ecosystem.

## Roadmap ideas

- Questions-only "candidate edition" — answers are structurally marked, so they can be stripped programmatically.
- Per-release fact refresh when new Kubernetes versions ship.
