---
name: dzil-audit
description: Audit a Perl distribution's Dist::Zilla setup against the optional shared dist.ini profile — plugin set, what ships, generated-file round trip, and release wiring. Use when asked to check or align a project's dist.ini, packaging, or release setup, when adding a dependency, or when setting up a new distribution.
---

# Dist::Zilla audit

Canonical spec: `~/projects/Agents/DZIL_GUIDE.md`. Skeleton to copy:
`~/projects/Agents/templates/dist.ini`.

## Run it

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

It reports missing or out-of-order plugins, dev-only trees that would ship,
generated files missing from the round trip, a missing NJH smoker guard, a
non-canonical author string, and `[UploadToCPAN]` where `[FakeRelease]`
belongs. It does not classify individual dependencies; that is project-local.

## Findings are advisory

A project may have a good reason to differ. **Report findings to the user
rather than silently rewriting release wiring.** Packaging changes affect what
ships to CPAN; they are the user's call.

Where a finding is unambiguous and mechanical — a dev-only tree that would
ship, a missing `allow_dirty` entry — say what you would change and ask before
changing it.

## The two rules that matter most

**Dist::Zilla owns the generated files.** `Makefile.PL`, `README`,
`README.md`, `cpanfile`, `LICENSE`, and `MANIFEST` are built during
`dzil build`. The first five are copied back by `[CopyFilesFromBuild]`;
`MANIFEST` remains in the build tree. **Never hand-edit generated files** —
the next build overwrites the edit. Change `dist.ini`, or the main module's
POD.

**Releases are manual in this profile.** `[FakeRelease]` builds, tests, tags,
commits, and bumps, but does not upload. Do not swap in `[UploadToCPAN]`, and
do not run `dzil release` unless asked.

## Adding a dependency

1. Follow the project's dependency policy and add it to the chosen
   `[Prereqs / ...]` section in `dist.ini`.
   - **`[Prereqs]`** — loaded unconditionally.
   - **`RuntimeSuggests`** — nothing breaks without it; a feature is absent.
   - **`RuntimeRecommends`** — wanted when available (an XS accelerator), but
     the pure-Perl path is complete.
   - **`DevelopRequires`** — author tooling and optional integrations needed
     by the project's author-test matrix.
2. If the project classifies it as optional, keep load behavior consistent
   with that classification.
3. `dzil build` — regenerates `Makefile.PL` and `cpanfile` and copies them
   back.
4. Commit `dist.ini`, `Makefile.PL`, and `cpanfile` together.

## What never ships

`agent_scripts/`, `AI_DOCS/`, `worktrees/`, `release-scripts/`, `demo/`,
coverage and profiling output, `pt/`, `tt/`, `xt/downstream/`, any reference
tree the project keeps (`reference/`, `old*/`), and every internal `.md`
(`AGENTS.md`, `ARCHITECTURE.md`, style guides, plans, reviews). `README.md` is
exempt — `[ReadmeFromPod]` regenerates it.

`t/` is excluded from `[GatherDir]` and re-gathered by a `[Git::GatherDir]`
block with `include_dotfiles = 1`, so `t/` dotfiles ship. One block per test
root.

`AI_AND_LLM_POLICY.txt` is a `.txt` rather than `.md` precisely so it ships.
