# LAB.md

An optional cross-platform Perl test lab. Some machines the owner manages
can run a dist's suite on VMs of the CPAN Testers platforms (Linux, 32-bit
Linux, the BSDs, Solaris, Windows with Strawberry and Cygwin, an Android
device), each with every perl in the Lyon Amendment window plus the OS perl.

Most machines that use this repository do not have it. Never assume it.

## Is the lab available here?

The lab belongs to the owner's systems repository, not to this one. It is
available only when all of these exist:

```
~/systems/bin/sys-lab           executable
~/systems/lab/README.md
~/.ssh/id_ed25519_lab
```

```
test -x ~/systems/bin/sys-lab && test -f ~/systems/lab/README.md \
  && test -f ~/.ssh/id_ed25519_lab && echo lab-available
```

If any is missing, there is no lab on this machine. Do not search for one,
clone anything, copy keys, or ask the user to set it up; test locally and use
CPAN Testers reports (`CPAN_TESTERS.md`) for other platforms. Mention the
missing lab only when a task actually needed another platform.

The files existing does not mean the lab is reachable: the machine may be
offline or the lab hosts down. If `sys-lab` cannot connect, report that and
carry on without it rather than retrying in a loop.

## Using it

**`~/systems/lab/README.md` is authoritative.** Read it before the first lab
run in a session; it covers commands, guests, perls, databases, and
platform quirks. This file only decides when the lab applies and lists the
rules an agent most often gets wrong.

Use the lab when the work needs another platform:

- reproducing a CPAN Testers failure on the OS or perl that reported it;
- a change touching portability: paths, filesystems, fork and signals,
  process handling, line endings, 32-bit integers, Windows or Cygwin;
- verifying a fix for a platform-specific bug;
- the user asks for it.

It is not part of the routine suite run. Local testing under
`agent-test-lock` (`TESTING.md`) still comes first; the lab is extra
coverage, not a replacement. Lab runs execute on the lab hosts, so they do
not take the local test lock.

Rules from the lab's README that matter most:

- **Run from inside the dist checkout.** `~/systems/bin/sys-lab run GUEST`
  copies the current directory to a fresh guest. `sys-lab list` shows the
  guests; `--perl` narrows the perl set.
- **Identify yourself.** Every guest is tagged with its owner. Run
  `sys-lab whoami` first; if it shows a plain `user@host` rather than a name
  for your session, set `SYS_LAB_OWNER=<agent>-<session>` (for example
  `codex-1a2b3c4d`) on every lab command.
- **Bound your own runs.** sys-lab has no timeout. Run it in the background
  with a timer sized to the suite. When the timer expires, investigate the
  hang as the README describes before stopping anything.
- **Only stop your own guests.** `sys-lab ps` shows who is using what.
  Never `--force` a guest someone else started; ask the user.
- **Long or many-platform runs** go through `sys-lab submit` so they outlive
  the session; check them with `sys-lab jobs` and `sys-lab result`.
- **Do not change the lab.** `build`, `net`, `sync`, `dbs`, and other
  `--execute` commands alter the lab hosts; run them only when the user asks.
- **Keep findings in the project.** A platform failure found in the lab is
  project work, reported like any other test failure. Lab problems (a broken
  guest, a missing package) are reported to the user, not fixed from a
  project session.
