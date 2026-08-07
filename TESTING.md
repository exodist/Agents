# TESTING.md

Shared testing policy for projects that opt into it. A project's own test
instructions take priority.

Test-code formatting and Perl conventions live in `PERL_STYLE_GUIDE.md`.

---

## Running tests

Four rules apply to every run governed by this guide:

1. **Always `AUTHOR_TESTING=1`.** Author-gated tests must run, not silently
   skip. A run without it is a deliberate check of skip behavior, not the
   routine command.
2. **Always a timeout.** Never sit on a run that may be stuck. Exceeding the
   ceiling is a *failure*, not "still going".
3. **`-j16` is the default concurrency** on the primary dev box. Lower it on
   a loaded or smaller machine, and use the concurrency appropriate to a
   deliberately verbose or serial diagnostic.
4. **Hold the shared test lock for any concurrency above 4.** See below.

The canonical command:

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

`agent-test-lock` sets `AUTHOR_TESTING=1`, takes the shared lock, applies the
timeout, runs the command in its own process group, and releases on exit —
including on signal. Where the project uses `yath`:

```
~/projects/Agents/bin/agent-test-lock -- yath test -D -T -j16
```

`--timer` (`prove`) / `-T` (`yath`) are mandatory for agent-run suites: a
per-file timing report is what makes a slow test visible instead of just
making the suite feel slow.

`-Ilib` (`prove`) / `-D` (`yath`) are mandatory so the suite exercises this
checkout's `lib/`, not an installed copy.

### Wall-clock ceilings

- **Concurrent run (`-j16` or any `-j` > 1): 5 minutes.** Not finished in
  five minutes → kill and investigate.
- **Serial run (`-j1`): 15 minutes.** Same.

Raise the timeout only for a suite genuinely known to be slower (some
database suites run ~5 minutes at `-j16`, so a 600s ceiling is right for
them). If a run approaches its ceiling *without* any failing or stuck test,
that is a signal the suite itself has grown too slow — speed up the suite
rather than raising the ceiling by default.

A run that blows past its ceiling is almost always a **hung test or a leaked
process**. Kill the run, hunt the orphans, kill them, then fix the leak. Do
not sit on a multi-minute "maybe it's just slow" run.

### The shared test lock

**`~/projects/.agent-test-lock`** — an advisory `flock` held for the duration
of any test run with concurrency above 4.

Multiple agents working in parallel across projects will each happily run
`-j16`. Two full database suites at once fan out to roughly 128 servers,
which is what OOM'd this machine. The lock is the mitigation: high-concurrency
runs serialize against each other, machine-wide, across every project.

This is **agent-side only.** Nothing in any project's `lib/` or `t/` knows
about the lock; it never ships. Do not build it into a test suite.

`bin/agent-test-lock` handles it:

```
agent-test-lock [options] -- <command...>

  --jobs N        Concurrency this run will use. Default: parsed from the
                  command's -jN / --jobs N, else 16. Runs at 4 or below skip
                  the lock entirely.
  --timeout SECS  Kill the command after this long. Default 900 for serial,
                  300 for concurrent.
  --wait SECS     Give up waiting for the lock after this long. Default 3600.
  --no-lock       Run without taking the lock. For a genuinely serial run.
  --no-author     Force AUTHOR_TESTING=0. The sole opt-out, for deliberately
                  checking that author-gated tests skip.
```

While waiting, it reports who holds the lock (pid, working directory,
command, held-since) so a stale holder is obvious.

### Resource failures

Investigate the processes and storage the project actually uses rather than
adding an arbitrary memory cap or relocating temporary storage. Database
suites have measured tmpfs, fan-out, watcher, and debris-cleanup constraints;
those live in `DATABASES.md` and apply only when the project opts in.

### Who runs the suite

**Only whoever is making the change.** Reviewers assume it passes — the
implementer verifies before handing work over. A reviewer who believes a
change breaks the suite reports that as a finding rather than running it.
Review rounds otherwise multiply full suites across agents, which is how the
machine got OOM'd.

### The release path

Before handing back anything that touches how modules are **loaded** — `@INC`,
`%INC`, `require`, re-exec, or a test that asserts on a module's path — also
run the release path once:

```
perl Makefile.PL && make && \
  ~/projects/Agents/bin/agent-test-lock --timeout 900 --jobs 16 -- make test
```

`prove -Ilib` puts `./lib` first in `@INC`; `make test` loads from
`blib/lib`, which is what CPAN clients, CPAN Testers and `dzil release` do. A
test that hardcodes `lib` passes the first and fails the second, so the dev
command structurally cannot see that class of bug. This has bitten: a test
asserting `abs_path('lib')` was green through nine review rounds and would
have failed every CPAN Testers report.

Run the two paths **one at a time, never concurrently** — that is what the
shared lock enforces.

---

## Test libraries

**`Test2::V0`** for everything new. Avoid `Test::More` and `Test::Simple` in
new code; existing imports may stay until the file is touched substantively.

---

## Database projects

Database backend selection, dependency classification, developer server
installs, and per-install fan-out are not universal test policy. A database
project may opt into `DATABASES.md`; its own architecture and test documents
still take priority. Projects that do not name that guide do not read or audit
against it.

---

## Test layout and provenance **[project-declared]**

There is no single universal layout. Each project declares its own in its
`AGENTS_OVERRIDE.md`. **New projects default to the scheme below.**

### Default: categories plus origin headers

```text
t/
    00-report.t
    01-test-support.t
    unit/
    acceptance/
    regression/
    integration/
    lib/
    fixtures/
    scripts/        (when used)
```

Only suite-wide diagnostics, harness/meta tests, and other explicitly
approved special tests live directly under `t/`. A numeric prefix does not by
itself make a test special. Numbered component suites stay nested with their
component and must not depend on serial execution.

Classify a test by **why it exists**, using this precedence when more than
one category looks applicable:

1. **`regression`** — reproduces a particular fixed defect.
2. **`acceptance`** — proves a published API, promise, or documented
   workflow.
3. **`integration`** — proves that multiple units or operations interact
   correctly, where the behavior is not primarily a published contract or a
   bug reproducer.
4. **`unit`** — directly exercises one implementation module or unit,
   including private behavior where useful.

Independently motivated sections in one test should be split when they belong
to different categories. **Do not split tests merely to disguise runtime.**

`t/lib/` holds importable Perl test helpers. `t/scripts/` is reserved for
programs invoked by tests and is not created while empty. Neither contains
`.t` files. There are no category-local helper, fixture, or script
directories.

**Naming and mirrors.** Unit tests omit the fixed distribution prefix and
mirror the remaining case-sensitive implementation path:

```text
lib/Foo/Bar.pm                -> t/unit/Bar.t
lib/Foo/Bar/Row.pm            -> t/unit/Row.t
lib/Foo/Bar/Schema/Table.pm   -> t/unit/Schema/Table.t
```

(The fixed prefix here is `lib/Foo/Bar`, the distribution's own namespace.)

A module may instead have multiple suffixed tests (`Row_fetch.t`,
`Row_store.t`). Every implementation module must have an exact or suffixed
mirror with meaningful coverage.

POD-only documentation modules are excluded from the unit mirror. Where a
project has a documentation tree (a `Manual/` or similar), its acceptance
tests mirror that path instead — `lib/Foo/Manual/Types.pm` →
`t/acceptance/Manual/Types.t`.

Test basenames stay at roughly 100 characters or fewer. Paths must not differ
only by capitalization — supported platforms may use case-insensitive
filesystems.

**Fixtures.** Test-owned fixtures sit beside the owning test in a directory
formed by replacing `.t` with `.fixtures`:

```text
t/acceptance/Aside.t
t/acceptance/Aside.fixtures/sqlite.sql
```

The suffix keeps a fixture directory from colliding with a directory of
mirrored module tests. No directory may both contain `.t` files and serve as
a fixture directory. Fixtures used by multiple tests live under
`t/fixtures/`; consumers name that shared path explicitly.

**Origin headers.** Every `.t` file carries one of these as its first
substantive line:

```perl
# Test origin: human
# Test origin: AI
# Test origin: mixed
```

Tests copied in from elsewhere -- an upstream project, or a reference tree
where the project keeps one -- remain human-origin even when an AI does the
copying. In upstream-derived tests, the origin header precedes the
retained source and licensing header.

In a mixed file, a substantial coherent AI-created section is marked at its
section or subtest boundary with `# Test origin: AI`. A section of 15 or more
source lines must be marked. Edits and small additions inside an existing
section inherit that section. Unmarked sections added later are presumed
human-origin; humans are not required to add section markers. When existing
human and AI material is combined, human material stays above AI material.

Origin records meaningful **section** provenance — not individual assertions,
and not the identity of the last editor.

### Alternative: a mirrored `t/AI/` tree

Some projects separate AI-authored tests physically instead:

```text
t/          human-authored tests
t/scripts/  helpers invoked by human-authored tests
t/AI/       AI-generated tests, mirroring t/'s subdirectory layout
t/AI/scripts/
```

`t/unit/Thing.t` ↔ `t/AI/unit/Thing.t`. Tests copied in from elsewhere count
as human-authored even when an AI does the copy. Under this scheme no
per-file origin header is needed.

Use it only where a project already does. It is not the default.

---

## Runtime investigation

If a concurrent suite reports a test file taking over **60 seconds**, consult
the project's gitignored `TEST_TIMING.md`. If it has no recent comparable
investigation, or the concurrent duration changed by more than 15 seconds,
rerun that file alone with harness and database concurrency removed.

Schedule isolated and full-suite timing runs when no other agent is running a
test harness or database-heavy diagnostic — that is exactly what the shared
lock is for.

Record timing history at one-second granularity. Each entry includes: date
and commit; command and external/internal concurrency; concurrent file
duration; available database sets and DBD drivers including skips; host
identity, active-agent count, and other suite activity; isolated per-flavor
times where applicable; and the disposition.

Only entries with comparable host, inventory, concurrency, agent load, and
test load may avoid a repeated investigation. Losing the ignored ledger is
not serious; regenerate it by timing and reinvestigating the slow files.

For a genuinely slow flavor or whole-file test, first look for
straightforward acceleration: replace sleeps with IPC, avoid redundant
database setup, remove unnecessary polling. **Do not game the threshold by
mechanically splitting the same workload.** Escalate unresolved cases for a
project decision. Splitting an essential test is considered only when its
work is genuinely independent and harness concurrency reduces total wall
time.

---

## Correct failing tests and deferred decisions

When a correct new test exposes a runtime defect, use the narrowest useful
Test2 TODO scope and record the defect for follow-up rather than weakening
the assertion. Do the same for ambiguous published promises, architecture
conflicts, and coverage that cannot be written without a significant ruling.
Continue unrelated work.

During a multi-phase test effort, unresolved items live in its tracked
deferral ledger. A TODO may remain in the final tree only after an explicit
user ruling, recorded beside it in a dated durable comment:

```perl
# Phase-5 disposition (YYYY-MM-DD): reason the TODO remains
```

---

## Author-only tests

`xt/` in the source tree is reserved for future author/release gates that are
too slow or too fragile for ordinary CPAN installation testing. No fixed
duration moves a test there automatically; moving one requires an explicit
project decision. Such tests use `AUTHOR_TESTING` only.

Dist::Zilla generates `xt/author/pod-syntax.t` in built distributions. That
generated file is not a source-tree author test.
