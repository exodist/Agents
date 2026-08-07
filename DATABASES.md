# Optional database-testing operations

Read this document only when a project's entry instructions opt into it.
Database framework, default backend, supported flavors, and dependency
classification are project architecture. Project documents always take
priority over this shared operational guidance.

## Dependency ownership

The shared Agents repository does not classify individual database modules,
choose prerequisite tiers, or prescribe load behavior. A project's own
architecture and packaging documents make those decisions. Auditors here do
not maintain a module-name allowlist or denylist.

## Developer database installs

Projects may use `~/dbs/<name>/bin` for developer installations of database
servers. This is a developer convention, never a shipped runtime contract.
Nothing under `lib/` may assume that path exists.

When a project supports the convention, author tests can scan `~/dbs/*/bin`
and run applicable tests once per discovered install. The inventory should be
live rather than hardcoded: adding or removing an install changes the next run
without a source edit. Unavailable optional flavors skip themselves.

Unix implementations normally isolate installs with real subprocesses. On
platforms where Perl's process model differs, use a fresh external Perl
process rather than assuming fork semantics.

## Per-install isolation

Set the child installation's environment before loading a database driver or
test helper. Some providers cache executable discovery at load time; loading
them in the parent and then changing `$PATH` in a child silently tests the
wrong installation.

For helpers based on `DBIx::QuickDB`, load `DBIx::QuickDB`, its drivers, and
`Test2::Tools::QuickDB` inside the isolated child only, after `$PATH` is set.
Keep implementation-specific cache names and workarounds in the project that
owns them.

## Concurrency

Per-install fan-out multiplies harness concurrency. For a helper using
`QDB_INSTALL_JOBS=4` under `prove -j16`, the upper bound is roughly 64 install
children, each potentially owning a server and watcher. Lower either setting
on a smaller or busy machine, and use the shared test lock for harness
concurrency above four.

System IPC limits and RAM usually fail before CPU. Do not hide that fan-out
inside a helper; project test instructions should state the knobs and expected
resource use.

## Crash cleanup

Do not wrap a database suite in a memory cgroup cap without understanding its
storage. `MemoryMax` counts tmpfs pages as well as process memory; a cap can
kill a server because of its temporary database files and present as an
ordinary test failure. Check the system OOM log when a server disappears.

Do not move database `TMPDIR` off tmpfs as an unmeasured workaround. The
shared lock, lower harness/per-install fan-out, and cleanup after a crash are
the established controls. Check `df -h /tmp` when a run behaves strangely.

`bin/sweep-test-debris` recognizes QuickDB data directories and refuses
deletion while a live watcher is found. QuickDB sets the watcher process title
to begin with `db-quick-watcher`; the detector and producer must change
together if that contract changes.

The default report considers directories at least one hour old. A strong
fingerprint is required; a generic `data/` directory alone never authorizes
deletion. Use `--min-age 0` only while deliberately investigating a fresh
crash, and inspect the report before adding `--delete`.

After a killed run, find live watchers with `ps -eo pid,args` rather than
`pgrep -f`, which may match its own command. Signal the watcher with `TERM`,
not the database server; the watcher stops its server and removes the data
directory through the normal cleanup path.
