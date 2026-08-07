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
2. **A timeout.** Exceeding it is a failure, not "still going". Default 600s.
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
2. Hunt orphans: `ps -eo args | grep -E 'db-quick-watcher|runner|Preload=launch'`.
   Note `pgrep -f` matches its own command line.
3. Signal the **watcher**, not the server: `kill -TERM <watcher pid>`. The
   watcher stops its server and removes its data dir the normal way.
4. Sweep debris:

   ```
   ~/projects/Agents/bin/sweep-test-debris
   ~/projects/Agents/bin/sweep-test-debris --delete
   ```

5. Fix the leak.

## Memory

**Do not wrap runs in a memory cgroup cap.** `MemoryMax` counts tmpfs pages,
so it caps the tests' *storage*, not their processes; a 12G cap OOM-killed
`mysqld` mid-run and presented as an ordinary test failure. Only
`journalctl --user | grep oom-kill` identifies that.

**Do not move `TMPDIR` off tmpfs.** Measured: one suite went from ~103s to
past a 900s timeout on disk.

The actual controls are the shared lock, lower fan-out on a loaded box
(`-j8`, `QDB_INSTALL_JOBS=2`), and sweeping debris after a crash. Check
`df -h /tmp` when a run behaves strangely.

## Databases

- Default backend: SQLite via `DBD::SQLite`, used directly.
- Ephemeral and non-default flavors: `DBIx::QuickDB`, usually via
  `Test2::Tools::QuickDB`.
- With `AUTHOR_TESTING=1`, helpers scan `~/dbs/*/bin` and run every applicable
  test once per developer install, each in a subprocess with that install's
  bin dir prepended to `$PATH`. The scan is live — drop an install in and it
  is picked up.
- Fan-out is `QDB_INSTALL_JOBS` (default 4) × `-j`, so `-j16` is ~64 install
  children each with a server and watcher.
- Nothing in `lib/` may know about `~/dbs`.

## A slow file

A file over 60 seconds in a concurrent run gets investigated, not ignored.
Check the project's gitignored `TEST_TIMING.md`; if there is no recent
comparable entry, rerun that file alone with concurrency removed and record
the result. Look for real acceleration (replace sleeps with IPC, avoid
redundant database setup, drop polling). Do not split a test to hide its
runtime.
