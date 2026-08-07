---
name: perl-test-run
description: Run a Perl project's test suite correctly — shared concurrency lock, AUTHOR_TESTING, timeout, per-file timing — and diagnose a hung, slow, or OOM-ing run. Use whenever running prove, yath, or make test in any project under ~/projects, and when a suite hangs, leaks processes, or leaves database debris behind.
---

# Running a Perl suite

Full policy: `~/projects/Agents/TESTING.md`. This is the operating procedure.

## The command

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

`agent-test-lock` does four things: sets `AUTHOR_TESTING=1`, takes the shared
lock, applies the timeout, and runs the command in its own process group so a
timeout kills the whole tree.

Four rules, every run:

1. **`AUTHOR_TESTING=1`** so author-gated tests run instead of silently
   skipping. The wrapper sets it; `--no-author` opts out for a deliberate
   check of skip behavior.
2. **A timeout.** Exceeding it is a failure, not "still going". Defaults are
   900s for serial and 300s for concurrent runs.
3. **`-j16`** default concurrency on the primary dev box.
4. **The shared lock above `-j4`** — `~/projects/.agent-test-lock`. Two agents
   each running `-j16` against database suites is what OOM'd this machine.
   The wrapper parses `-jN` out of the command, so it usually needs no
   `--jobs`.

For a yath project:

```
~/projects/Agents/bin/agent-test-lock -- yath test -D -T -j16
```

`--timer` / `-T` are mandatory — a per-file timing report is what makes a slow
test visible. `-Ilib` / `-D` are mandatory so the suite exercises this
checkout, not an installed copy.

## Ceilings

- Concurrent run: **5 minutes**, unless the project documents otherwise (some
  database suites legitimately take ~5 minutes at `-j16`; give those 600s).
- Serial run (`-j1`): **15 minutes**.

Approaching the ceiling with nothing failing means the suite has grown too
slow — raise that, do not wait longer.

## The release path

Before handing back anything touching `@INC`, `%INC`, `require`, re-exec, or a
test that asserts on a module's path:

```
perl Makefile.PL && make && \
  ~/projects/Agents/bin/agent-test-lock --timeout 900 --jobs 16 -- make test
```

`prove -Ilib` loads `./lib`; `make test` loads `blib/lib`, which is what CPAN
clients and CPAN Testers do. A test hardcoding `lib` passes the first and
fails the second. Run them one at a time — the lock enforces that.

## Who runs it

**Only whoever is making the change.** A reviewer who believes a change breaks
the suite reports that as a finding rather than running it. Otherwise review
rounds multiply full suites across agents.

## When a run overruns

Almost always a hung test or a leaked process, not slowness.

1. Kill the run.
2. Inspect the process tree for children the project is known to launch.
3. Stop those children through their documented supervisor or cleanup path.
4. Fix the leak.

For an opted-in database project, follow `DATABASES.md` for watcher and
debris cleanup rather than applying those operations to every project.

## Memory

Do not improvise a memory cgroup or relocate temporary storage without first
identifying which project resource is exhausted. For opted-in database
projects, the measured constraints and controls are in `DATABASES.md`.

## Database projects

Read `~/projects/Agents/DATABASES.md` only when the project's entry documents
opt into that database-testing guidance. Backend choice and dependency
classification remain project decisions.

## A slow file

A file over 60 seconds in a concurrent run gets investigated, not ignored.
Check the project's gitignored `TEST_TIMING.md`; if there is no recent
comparable entry, rerun that file alone with concurrency removed and record
the result. Look for real acceleration (replace sleeps with IPC, avoid
redundant database setup, drop polling). Do not split a test to hide its
runtime.
