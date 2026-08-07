# DZIL_GUIDE.md

Canonical Dist::Zilla setup. Every Perl distribution in this account uses the
same `dist.ini` skeleton, in the same order, with the same generated-file
round trip. This document is what `agent_scripts/audit-dzil` checks projects
against.

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

---

## The contract

**Dist::Zilla owns the generated files.** `Makefile.PL`, `README`,
`README.md`, `cpanfile`, `LICENSE`, and `MANIFEST` are built during
`dzil build` and copied back into the working tree by `[CopyFilesFromBuild]`.

**Never hand-edit any of them.** Editing `Makefile.PL` to add a dependency is
the classic mistake: the next build overwrites it. Change `dist.ini`
instead. Change the main module's POD to change `README` / `README.md`.

**Releases are manual.** Every project uses `[FakeRelease]`, so `dzil
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

[MetaResources]
bugtracker.web  = https://github.com/<org>/<Dist-Name>/issues
repository.url  = https://github.com/<org>/<Dist-Name>/
repository.type = git

[Prereqs]
; Hard runtime requirements. Aligned `=` column.
perl = 5.012000

[Prereqs / TestRequires]
Test2::V0 = 0.000060

[Prereqs / ConfigureRequires]
ExtUtils::MakeMaker = 0

[Prereqs / DevelopRequires]
; Author-only tooling and every optional driver, so a dev box installs them all.

[Prereqs / RuntimeSuggests]
; Optional, lazily loaded. Nothing breaks without them; a feature is absent.

[Prereqs / RuntimeRecommends]
; Optional, but you want it if you can have it (e.g. an XS accelerator).

[MakeMaker::Awesome]
:version  = 0.26
delimiter = |
header    = |use Config qw/%Config/;
header    = |if ($ENV{AUTOMATED_TESTING}) {
header    = |    my $is_njh = 0;
header    = |    $is_njh ||= -d '/export/home/njh';
header    = |    $is_njh ||= -d '/home/njh';
header    = |    $is_njh ||= lc($ENV{USER} // 'na') eq 'njh';
header    = |    $is_njh ||= lc($ENV{HOME} // 'na') =~ m{njh$};
header    = |    $is_njh ||= lc($ENV{PATH} // 'na') =~ m{/njh/};
header    = |    die "OS unsupported\nNJH smokers are broken, aborting tests.\n"
header    = |        if $is_njh;
header    = |}

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

If a project is dual-life, its `AGENTS_OVERRIDE.md` records that, because it
overrides several universal rules at once.

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
  **That pair is the canonical arrangement.**
- `[VersionFromModule]` appears in a handful of older distributions. It reads
  the version but does not bump it, so the version has to be raised by hand
  every release. Move to `[RewriteVersion]` + `[BumpVersionAfterRelease]` when
  touching such a project, and say so in the commit.
- Never set `version =` in `dist.ini`.

### Cruft, manifest, and extra tests

- **`[PruneCruft]` is mandatory in every project.** It drops build droppings
  and editor leftovers that `[GatherDir]` would otherwise sweep into the
  tarball. **Add it when a project adopts this repository** — several existing
  distributions are missing it, and a missing `[PruneCruft]` is a finding, not
  a preference.
- `[ManifestSkip]` reads a hand-written `MANIFEST.SKIP` when the project has
  one. Most do. Keep patterns there specific; `[PruneCruft]` already handles
  the generic cases, so `MANIFEST.SKIP` is for this distribution's own
  oddities.
- **`[RunExtraTests]` is required whenever the project has an `xt/`
  directory.** Without it those author tests never run at release time, which
  is the only time they were meant to run. A project with `xt/` and no
  `[RunExtraTests]` has author tests that have never executed.
- **`[Test::ChangesHasContent]` is recommended.** It fails the release when
  the `{{$NEXT}}` section of `Changes` is empty — the exact failure the
  changelog rule exists to prevent, caught at the last possible moment.
  Releases have shipped with empty changelogs; this is the safeguard.

### What ships

- **`lib/`, `t/`, `scripts/`, `share/`, `Changes`, and the generated files.**
  That is the whole shipped surface.
- **Never ships:** `agent_scripts/`, `AI_DOCS/`, `worktrees/`,
  `release-scripts/`, `demo/`, coverage and profiling output, `pt/`, `tt/`,
  `xt/downstream/`, any reference tree the project keeps (`reference/`,
  `old*/`), and **every internal `.md`** (`AGENTS.md`, `ARCHITECTURE.md`,
  style guides, plans, reviews). `README.md` is exempt because
  `[ReadmeFromPod]` regenerates it.
- `t/` is excluded from `[GatherDir]` and re-gathered by a
  `[Git::GatherDir]` block with `include_dotfiles = 1`, so files like
  `t/.gitignore` ship. Add one block per test root the dist has (`t/`,
  `t2/`, …).
- `AI_AND_LLM_POLICY.txt` is a `.txt`, not a `.md`, precisely so it ships
  with the distribution.

### Prereqs

- **Hard requires go in `[Prereqs]`.** Only modules the distribution loads
  unconditionally.
- **Optional drivers and flavor helpers are Suggests or Recommends** — never
  hard requires. That covers `DBD::Pg`, `DBD::mysql`, `DBD::MariaDB`,
  Percona drivers, `DBD::DuckDB`, and `DateTime::Format::*`. `DBD::SQLite`
  is the one database driver that may be a hard require, because it is the
  default backend.
  - **Suggests** — nothing breaks without it; a feature is simply absent.
  - **Recommends** — you want it if you can have it (an XS accelerator, a
    faster JSON backend), but the pure-Perl path is complete.
- Every optional module is `require`d **lazily at its point of use**, with an
  actionable error naming what to install. Nothing always-loaded may `use` an
  optional module at compile time.
- **`[Prereqs / DevelopRequires]` lists every optional driver too**, so a
  developer box installs the full matrix and the author suite actually
  exercises it.
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

### CI

GitHub Actions, in `.github/workflows/`. Two shapes are in use:

- **`testsuite.yml`** — the current one. A cheap `ubuntu` job runs first
  (`perl Makefile.PL && make && make test`), then a `perl-versions` job
  computes the matrix via `perl-actions/perl-versions` (`since-perl` /
  `until-perl`), then the matrix job runs only if the cheap job passed. Deps
  install with `perl-actions/install-with-cpm` from `.github/cpanfile.ci`
  first, then `cpanfile`. `local/` is cached, keyed on the cpanfile hashes
  plus a week number so the cache rolls over.
- **`linux.yml` / `macos.yml` / `windows.yml`** — the older per-platform
  shape with a hand-listed `perl-version` matrix. Fine where it exists; do not
  add new ones.

Standard job environment:

```yaml
PERL_USE_UNSAFE_INC: 0
AUTOMATED_TESTING: 1
RELEASE_TESTING: 1
AUTHOR_TESTING: 0      # 1 only where author tests are meant to run in CI
```

`AUTHOR_TESTING` in CI is the opposite of the local rule: locally it is always
on so nothing silently skips, in CI it is off unless the author suite is cheap
and portable enough to belong there.

`cpanfile.ci` (at the root or under `.github/`) lists modules CI needs that
Dist::Zilla cannot see. It is excluded from the distribution.

---

## Adding a dependency (the whole procedure)

1. Add it to the right `[Prereqs / ...]` section in `dist.ini`.
2. If it is optional, make the load site `require` it lazily with an
   actionable error.
3. `dzil build` — this regenerates `Makefile.PL` and `cpanfile` and
   `[CopyFilesFromBuild]` copies them back into the tree.
4. Commit `dist.ini`, `Makefile.PL`, and `cpanfile` together.

Do not skip step 3 and hand-edit `Makefile.PL`. It will be reverted.

---

## Auditing a project

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
```

It reports, per project:

- Missing or out-of-order plugin sections.
- Dev-only trees that are not excluded from `[GatherDir]`.
- Generated files missing from `[CopyFilesFromBuild]`, `[Git::Check]`, or
  `[Git::Commit]`.
- Optional database drivers or flavor helpers sitting in `[Prereqs]` as hard
  requires.
- A missing NJH smoker guard.
- An author string that is not the canonical one.
- `[UploadToCPAN]` where `[FakeRelease]` is expected.

Findings are advisory: a project may have a good reason to differ. Report
them to the user rather than silently "fixing" a distribution's release
wiring.
