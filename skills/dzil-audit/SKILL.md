---
name: dzil-audit
description: Audit a Perl distribution's Dist::Zilla setup against the canonical dist.ini spec — plugin set, what ships, generated-file round trip, optional-vs-hard prereqs, release wiring. Use when asked to check or align a project's dist.ini, packaging, or release setup, when adding a dependency, or when setting up a new distribution.
---

# Dist::Zilla audit

Canonical spec: `~/projects/Agents/DZIL_GUIDE.md`. Skeleton to copy:
`~/projects/Agents/templates/dist.ini`.

## Run it

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

It reports missing or out-of-order plugins, dev-only trees that would ship,
generated files missing from the round trip, optional database drivers sitting
in `[Prereqs]` as hard requires, a missing NJH smoker guard, a non-canonical
author string, and `[UploadToCPAN]` where `[FakeRelease]` belongs.

## Findings are advisory

A project may have a good reason to differ. **Report findings to the user
rather than silently rewriting release wiring.** Packaging changes affect what
ships to CPAN; they are the user's call.

Where a finding is unambiguous and mechanical — a dev-only tree that would
ship, a missing `allow_dirty` entry — say what you would change and ask before
changing it.

## The two rules that matter most

**Dist::Zilla owns the generated files.** `Makefile.PL`, `README`,
`README.md`, `cpanfile`, `LICENSE`, `MANIFEST` are built during `dzil build`
and copied back by `[CopyFilesFromBuild]`. **Never hand-edit them** — the next
build overwrites the edit. Change `dist.ini`, or the main module's POD.

**Releases are manual.** Every project uses `[FakeRelease]`: build, test, tag,
commit, bump — but no upload. Do not swap in `[UploadToCPAN]`, and do not run
`dzil release` unless asked.

## Adding a dependency

1. Add it to the right `[Prereqs / ...]` section in `dist.ini`.
   - **`[Prereqs]`** — loaded unconditionally.
   - **`RuntimeSuggests`** — nothing breaks without it; a feature is absent.
     Every non-default DB driver (`DBD::Pg`, `DBD::mysql`, `DBD::MariaDB`,
     Percona, `DBD::DuckDB`) and flavor helper (`DateTime::Format::*`) lives
     here. `DBD::SQLite` is the exception — it is the default backend and may
     be a hard require.
   - **`RuntimeRecommends`** — wanted when available (an XS accelerator), but
     the pure-Perl path is complete.
   - **`DevelopRequires`** — author tooling *plus* every optional driver, so a
     dev box installs the full matrix.
2. If optional, make the load site `require` it lazily with an actionable
   error naming what to install. Nothing always-loaded may `use` an optional
   module at compile time.
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
