# DZIL_GUIDE.md

Optional shared Dist::Zilla setup. A Perl distribution may adopt this
`dist.ini` skeleton when it is useful; project-local packaging documents and
release decisions always take priority. This document is what
`agent_scripts/audit-dzil` checks projects against when asked.

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

---

## The contract

**Dist::Zilla owns the generated files.** `Makefile.PL`, `README`,
`README.md`, `cpanfile`, `LICENSE`, and `MANIFEST` are built during
`dzil build`. The first five are copied back into the working tree by
`[CopyFilesFromBuild]`; `MANIFEST` exists only in the build tree.

**Never hand-edit any of them.** Editing `Makefile.PL` to add a dependency is
the classic mistake: the next build overwrites it. Change `dist.ini`
instead. Change the main module's POD to change `README` / `README.md`.

**Releases are manual in this profile.** It uses `[FakeRelease]`, so `dzil
release` builds, tests, tags, commits and bumps but does **not** upload.
Uploading to PAUSE is a deliberate separate step by the user. Do not swap in
`[UploadToCPAN]`, and do not run `dzil release` unless asked.

---

## Skeleton

Sections appear in this order. Bracketed notes mark the parts that vary per
project.

```ini
name             = Dist-Name
author           = Chad Granum <exodist7@gmail.com>
license          = Perl_5
copyright_holder = Chad Granum

[RewriteVersion]   ; sets dist version from the main module's $VERSION
[License]
[ManifestSkip]
[Manifest]
[NextRelease]

[GatherDir]
; Dev-only trees and generated files never ship.
exclude_match    = ^old                ; [only if the project keeps a reference tree]
exclude_match    = ^reference          ; [only if the project keeps a reference tree]
exclude_match    = ^worktrees
exclude_match    = ^agent_scripts/
exclude_match    = ^AI_DOCS/
exclude_match    = ^release-scripts
exclude_match    = ^demo
exclude_match    = ^cover              ; cover_db and friends
exclude_match    = ^nyt
exclude_match    = ^test-logs
exclude_match    = ^data/
exclude_match    = ^pt                 ; only run these tests locally
exclude_match    = ^tt                 ; only run these tests locally
exclude_match    = ^xt/downstream      ; only run these tests locally
exclude_match    = ^t/                 ; re-gathered below, to pick up dotfiles
exclude_match    = \.md$               ; internal docs never ship
exclude_filename = LICENSE
exclude_filename = Makefile.PL
exclude_filename = README
exclude_filename = README.md
exclude_filename = cpanfile
exclude_filename = cpanfile.ci
exclude_filename = TEMPLATE.pod
exclude_filename = perltidyrc          ; developer formatting config
exclude_filename = .yath-persist.json

[PruneCruft]

; Re-gather t/ through Git so t/ dotfiles ship. One block per test root.
[Git::GatherDir / GatherDotFilesT]
root             = t/
prefix           = t/
include_dotfiles = 1

[ExecDir]                              ; [only if the dist ships scripts]
dir = scripts

[ShareDir]                             ; [only if the dist ships share/]
dir = share

[Run::AfterBuild]                      ; [only if POD is generated at build]
run = release-scripts/generate_command_pod.pl %d

[PodSyntaxTests]
[TestRelease]
[Test::ChangesHasContent]

; Add when xt/ exists.
;[RunExtraTests]

[MetaResources]
bugtracker.web  = https://github.com/<org>/<Dist-Name>/issues
repository.url  = https://github.com/<org>/<Dist-Name>/
repository.type = git

[Prereqs]
; Fill from this project's declared dependency policy.
perl = <project minimum>

[Prereqs / TestRequires]
Test2::V0 = 0.000060

[Prereqs / ConfigureRequires]
ExtUtils::MakeMaker = 0

[Prereqs / DevelopRequires]
; Fill from this project's declared dependency policy.

[Prereqs / RuntimeSuggests]
; Fill from this project's declared dependency policy.

[Prereqs / RuntimeRecommends]
; Fill from this project's declared dependency policy.

[MakeMaker]

[CPANFile]
[MetaYAML]
[MetaJSON]

; authordep Pod::Markdown
[ReadmeFromPod / Markdown]
filename = lib/Main/Module.pm
type     = markdown
readme   = README.md

[ReadmeFromPod / Text]
filename = lib/Main/Module.pm
type     = text
readme   = README

[CopyFilesFromBuild]
copy = LICENSE
copy = cpanfile
copy = README
copy = README.md
copy = Makefile.PL

[Git::Check]
allow_dirty = Makefile.PL
allow_dirty = README
allow_dirty = README.md
allow_dirty = cpanfile
allow_dirty = LICENSE
allow_dirty = Changes

[Git::Commit]
allow_dirty = Makefile.PL
allow_dirty = README
allow_dirty = README.md
allow_dirty = cpanfile
allow_dirty = LICENSE
allow_dirty = Changes

[Git::Tag]

[FakeRelease]

[BumpVersionAfterRelease]

[Git::Commit / Commit_Changes]
munge_makefile_pl = true
allow_dirty_match = ^lib
allow_dirty_match = ^scripts
allow_dirty       = Makefile.PL
allow_dirty       = README
allow_dirty       = README.md
allow_dirty       = cpanfile
allow_dirty       = LICENSE
commit_msg        = Automated Version Bump
```

---

## Distribution shapes

The skeleton above is the ordinary pure-Perl module. Five variants exist in
this account; each adds to the skeleton rather than replacing it.

### Ships executables

```ini
[ExecDir]
dir = scripts
```

Everything in `scripts/` is installed as a program. `[Git::Commit /
Commit_Changes]` also carries `allow_dirty_match = ^scripts` so the version
bump can touch them.

### Ships a share directory

```ini
[ShareDir]
dir = share
```

For schema files, templates, static web assets — anything read at runtime via
`File::ShareDir`.

### Ships a specific dotfile

`[GatherDir]` skips dotfiles. To ship one named file:

```ini
[GatherFile]
filename = .yath.rc
```

For a whole directory's dotfiles (a test root), use the `[Git::GatherDir]`
block with `include_dotfiles = 1` instead.

### XS

An XS distribution adds `<Name>.xs` and any `*.h` beside `lib/`, declares
`XSLoader` in `[Prereqs]`, and uses `[MakeMaker::Awesome]` so the generated
`Makefile.PL` can carry a `use Config` header for platform probing.

Ship a pure-Perl fallback where one is possible, and declare the XS
distribution as a **RuntimeRecommends** of the consumer rather than a
requirement — XS needs a compiler, so requiring it narrows who can install.

### Dual-life / core module

A distribution that also ships inside the Perl core plays by different rules.
`Test-Simple` is the one here.

```ini
[MakeMaker]        ; plain -- NOT MakeMaker::Awesome

[OnlyCorePrereqs]
starting_version = 5.040000

[DualLife]

[Breaks]
Some::Downstream::Module = <= 0.42

[RunExtraTests]
[Test::ChangesHasContent]
```

What changes:

- **`[DualLife]`** marks it, so it installs to the core-appropriate location
  when built as part of perl.
- **`[OnlyCorePrereqs]`** fails the build if a prerequisite is not itself core
  as of `starting_version`. A dual-life module cannot depend on something the
  core does not carry.
- **`[Breaks]`** declares `x_breaks` metadata naming downstream modules that
  break against this release, so CPAN clients warn. Keep the list curated;
  comment out entries that are merely untested rather than broken.
- **Plain `[MakeMaker]`, not `[MakeMaker::Awesome]`.** The generated
  `Makefile.PL` has to stay something the core build can consume — no custom
  headers, no NJH guard.
- **A very low perl floor** (`5.006002` for `Test-Simple`). The floor is a
  compatibility promise, not a preference, and raising it is a release
  decision.
- **Internal `.md` files are not excluded** from `[GatherDir]`; the core
  tarball comparison expects the tree as-is.
- The **directory name differs from the distribution name** — `Test-More/` on
  disk, `Test-Simple` on CPAN. The project's `AGENTS.md` says so.

If a project is dual-life and has adopted this repository, its local
packaging documents or `AGENTS_OVERRIDE.md` record the differences.

---

## Rules

### Identity

- `author = Chad Granum <exodist7@gmail.com>` — one address across all
  distributions. `exodist@cpan.org` appears in older `dist.ini` files; new
  and touched ones use the gmail address, matching `TEMPLATE.pod`.
- `license = Perl_5`, `copyright_holder = Chad Granum`.
- `name` is the distribution name with `::` replaced by `-`, and it does not
  have to match the directory name. A directory may be renamed (e.g. to mark
  a version as legacy) while the distribution keeps its published name — say
  so in the project's `AGENTS.md` when that is the case.

### Versioning

- `[RewriteVersion]` + `[BumpVersionAfterRelease]`: the main module's
  `$VERSION` is the source of truth, and the post-release commit bumps it.
  **That pair is the shared profile's arrangement.**
- `[VersionFromModule]` appears in a handful of older distributions. It reads
  the version but does not bump it, so the version has to be raised by hand
  every release. Move to `[RewriteVersion]` + `[BumpVersionAfterRelease]` when
  touching such a project, and say so in the commit.
- Never set `version =` in `dist.ini`.

### Cruft, manifest, and extra tests

- **`[PruneCruft]` is part of this shared profile.** It drops build droppings
  and editor leftovers that `[GatherDir]` would otherwise sweep into the
  tarball. `audit-dzil` reports it when checking a project against this
  profile.
- `[ManifestSkip]` reads a hand-written `MANIFEST.SKIP` when the project has
  one. Most do. Keep patterns there specific; `[PruneCruft]` already handles
  the generic cases, so `MANIFEST.SKIP` is for this distribution's own
  oddities.
- **`[RunExtraTests]` is required whenever the project has an `xt/`
  directory.** Without it those author tests never run at release time, which
  is the only time they were meant to run. A project with `xt/` and no
  `[RunExtraTests]` has author tests that have never executed.
- **`[Test::ChangesHasContent]` is part of the template.** It fails the release when
  the `{{$NEXT}}` section of `Changes` is empty — the exact failure the
  changelog rule exists to prevent, caught at the last possible moment.
  Releases have shipped with empty changelogs; this is the safeguard.

### What ships

- **`lib/`, `t/`, `scripts/`, `share/`, `Changes`,
  `AI_AND_LLM_POLICY.txt`, and the generated files.** That is the whole
  shipped surface.
- **Never ships:** `agent_scripts/`, `AI_DOCS/`, `worktrees/`,
  `release-scripts/`, `demo/`, coverage and profiling output, `pt/`, `tt/`,
  `xt/downstream/`, any reference tree the project keeps (`reference/`,
  `old*/`), the `perltidyrc` formatting config, and **every internal `.md`**
  (`AGENTS.md`, `AGENTS_OVERRIDE.md`, `CLAUDE.md`, `CODEX.md`,
  `ARCHITECTURE.md`, style guides, plans, reviews). `README.md` is exempt
  because `[ReadmeFromPod]` regenerates it into the build.
- None of that is useful to someone installing the distribution, and a
  document written for a project's own developers and agents reads as
  published documentation once it is inside a tarball on CPAN.
- **A project may ship any of it deliberately.** Packaging is a release
  decision the project owns, so an exception needs no argument here — only a
  record. Declare it in the project's `AGENTS_OVERRIDE.md`, naming what ships
  and why, and `audit-dzil` findings against that declaration are expected
  rather than debt. The dual-life shape below is one such declared exception.
- `t/` is excluded from `[GatherDir]` and re-gathered by a
  `[Git::GatherDir]` block with `include_dotfiles = 1`, so files like
  `t/.gitignore` ship. Add one block per test root the dist has (`t/`,
  `t2/`, …).
- Exactly one AI/LLM policy document ships: `AI_AND_LLM_POLICY.txt`. It is a
  `.txt`, not a `.md`, precisely so it ships with the distribution. Its content
  matches the canonical copy unless the project declares a replacement policy
  in `AGENTS_OVERRIDE.md`.

### Prereqs

- **Each project classifies its own dependencies.** The shared repository does
  not decide whether a named module is required, optional, suggested,
  recommended, test-only, or developer-only, and it does not prescribe the
  module's load behavior. Follow the project's architecture and packaging
  documents.
- The skeleton includes common Dist::Zilla prerequisite sections as places
  for the project's classifications; their presence is not a decision about
  any dependency.
- Keep the `=` column aligned within a section. It is scanned by eye
  constantly.
- A comment above a non-obvious dependency explaining *why* it is optional,
  or which feature needs it, is worth its space. This is one of the few
  places prose earns its keep.

### `MakeMaker::Awesome` headers

- Use `[MakeMaker::Awesome]` when the distribution needs a configure-time
  guard; plain `[MakeMaker]` otherwise.
- The **NJH smoker guard** is standard: those smokers report broken results
  under `AUTOMATED_TESTING`, so configuration aborts there.
- Platform guards go beside it: `unless $Config{d_fork}` for anything needing
  real forks, `$^O =~ m/(dos|os2)/i` for anything that cannot work there.

### Release wiring

- `[Git::Check]` and `[Git::Commit]` allow exactly the generated files plus
  `Changes` to be dirty. Nothing else.
- `[Git::Tag]` then `[FakeRelease]` — build, test, tag, but do not upload.
- `[Git::Commit / Commit_Changes]` with `munge_makefile_pl = true` lands the
  version bump as "Automated Version Bump".

### Continuous integration

Continuous-integration providers, workflow files, matrices, and credentials
are project-local concerns. This repository does not prescribe or audit them.

---

## Adding a dependency (the whole procedure)

1. Use the project's dependency policy to choose the right
   `[Prereqs / ...]` section in `dist.ini`.
2. Implement the load behavior required by that project policy.
3. `dzil build` — this regenerates `Makefile.PL` and `cpanfile` and
   `[CopyFilesFromBuild]` copies them back into the tree.
4. Commit `dist.ini`, `Makefile.PL`, and `cpanfile` together.

Do not skip step 3 and hand-edit `Makefile.PL`. It will be reverted.

---

## Manual release procedure

1. Confirm that the next-release section in `Changes` has content, the working
   tree contains only intended changes, and the project's pre-review and test
   procedures pass.
2. Run `dzil build`, inspect the built distribution, and test the built
   artifact using the project's documented commands.
3. Only the owner, or an agent explicitly authorized for that release, runs
   `dzil release`. With `[FakeRelease]` this performs the configured release
   checks, tags, commits, and version bump without uploading to PAUSE.
4. The owner uploads the inspected artifact separately with the PAUSE client
   chosen for that project.

Never infer authorization to release or upload from permission to edit or
test a repository.

---

## Auditing a project

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
```

It reports, per project:

- Missing or out-of-order plugin sections.
- Dev-only trees, internal Markdown, and `perltidyrc` that are not excluded
  from `[GatherDir]`.
- Generated files missing from `[CopyFilesFromBuild]`, `[Git::Check]`, or
  `[Git::Commit]`.
- A missing NJH smoker guard.
- An author string that is not the canonical one.
- `[UploadToCPAN]` where `[FakeRelease]` is expected.

Findings are advisory compatibility checks against this optional profile, not
universal pre-review gates. A project may have a good reason to differ. Report
them to the user rather than silently "fixing" a distribution's release
wiring.
