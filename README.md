# Agents

Universal agent instructions, style rules, and cross-project tooling for
Chad Granum's ("Exodist") Perl projects.

Every project under `~/projects` points here rather than carrying its own copy
of the rules. A project's own files hold only what is true of that project.

- **Clone URL:** `git@github.com:exodist/Agents.git`
- **Expected location:** `~/projects/Agents`

**Setting a project up? Read [`USING.md`](USING.md).** It covers the whole
wiring: the bootstrap stanza, what goes in which file, and how to audit a
project for drift.

## Documents

| File | What it covers |
|---|---|
| [`USING.md`](USING.md) | How a project wires itself to this repository. Point an agent here to set one up. |
| [`AGENTS.md`](AGENTS.md) | Agent workflow: how work happens, decision discussion mode, reference trees, the three mandatory pre-review passes, AI docs, commits, changelog, worktrees. |
| [`PERL_STYLE_GUIDE.md`](PERL_STYLE_GUIDE.md) | Perl style: object orientation, error handling, filehandles, conditionals, naming, comments, terminology, perltidy, POD, sizes. |
| [`STYLE_GUIDE_AGENT_CHECKLIST.md`](STYLE_GUIDE_AGENT_CHECKLIST.md) | The self-audit form of the style guide. Walk it before handing work back. |
| [`TESTING.md`](TESTING.md) | Test execution, the shared concurrency lock, memory traps, the `~/dbs` contract, test layout and provenance. |
| [`DZIL_GUIDE.md`](DZIL_GUIDE.md) | The canonical `dist.ini` skeleton and packaging rules every distribution is audited against. |
| [`AI_AND_LLM_POLICY.txt`](AI_AND_LLM_POLICY.txt) | Contributor-facing AI/LLM policy. Ships with each distribution. |
| [`REPO_RULES.md`](REPO_RULES.md) | Rules for editing **this** repository. Consuming projects do not inherit them. |
| [`CLAUDE.md`](CLAUDE.md) | Points at `AGENTS.md`. That is its entire job. |

## Per-project files

| File | Role |
|---|---|
| `CLAUDE.md` | Points at the project's `AGENTS.md`. Nothing else, ever. |
| `AGENTS.md` | Bootstrap stanza pointing here, then project-specific context. |
| `AGENTS_OVERRIDE.md` | The project's declarations and overrides. Where it speaks, it wins. |

Four rules are deliberately **project-declared** — they have no universal
answer, and each project's `AGENTS_OVERRIDE.md` must pin them:

1. **Perl floor / signatures** — portable (`use strict; use warnings;`) or
   modern (`use v5.38;` with signatures everywhere).
2. **POD placement** — all POD under `__END__` (default), or the split layout.
3. **Test layout** — category directories plus origin headers (default for new
   projects), or a `t/AI/` mirror tree.
4. **perltidy** — the shared `templates/perltidyrc`, or a project-local one.

## Tools

```
bin/agent-test-lock      Serialize high-concurrency test runs machine-wide,
                         set AUTHOR_TESTING=1, enforce a timeout.
bin/sweep-test-debris    Find and remove QuickDB data dirs left in /tmp by a
                         crashed run.
```

The lock lives at `~/projects/.agent-test-lock`. Any test run above `-j4`
takes it, so two agents cannot both fan out to sixty database servers and OOM
the machine. It is agent-side only — nothing in any project knows about it.

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

## Auditors

Cross-project gates, all exiting non-zero on a hit:

```
agent_scripts/audit-methods-not-functions   Subs defined in an object module
                                            called as bare functions.
agent_scripts/audit-readonly-attrs          Read-only HashBase slots using
                                            `-attr` instead of `<attr`.
agent_scripts/audit-banned-words            Forbidden terminology.
agent_scripts/find-long-subs                Subs over 75 lines.
agent_scripts/find-large-modules            Modules over 10,000 lines.
agent_scripts/audit-dzil                    dist.ini against DZIL_GUIDE.md.
agent_scripts/audit-no-secrets              Credentials and sensitive
                                            material. Mandatory before every
                                            commit HERE (see REPO_RULES.md).
```

Copy the ones a project needs into its own `agent_scripts/`. Fix the canonical
copy here first, then re-copy — the project copies are expected to match.

## Skills

| Skill | Use for |
|---|---|
| `perl-pre-review` | The three mandatory passes before announcing work ready for review. |
| `perl-test-run` | Running a suite correctly; diagnosing hangs, leaks, and OOMs. |
| `decision-discussion` | Walking pending decisions past the user, one item at a time. |
| `dzil-audit` | Checking or changing a distribution's packaging and release setup. |
| `perl-project-align` | Bootstrapping a new project, or auditing an existing one for drift. |

## Templates

`templates/` holds the files a project copies verbatim or fills in:
`CLAUDE.md`, an `AGENTS.md` scaffold, an `AGENTS_OVERRIDE.md` scaffold,
`TEMPLATE.pod`, `perltidyrc`, `dist.ini`, and a `.gitignore`. `USING.md` has
the copy-in sequence.

## Installing — not required

**Clone it and it works.** `AGENTS.md` points agents at every document, tool,
auditor, and procedure by absolute path. Nothing is installed, and nothing
breaks if it never is.

```
git clone git@github.com:exodist/Agents.git ~/projects/Agents
```

`./install` is a convenience for one thing only: Claude Code and Codex
auto-discover skills solely under `~/.claude/skills` and `~/.codex/skills`, so
linking them there gains `/name` invocation and automatic surfacing. Without
it the same files are still read as procedures — `AGENTS.md` says when to read
which. It also links `bin/*` into `~/.local/bin` to save typing.

```
./install --dry-run
./install
```

It links `~/.claude/skills` as a whole directory when that path is free, so a
skill added later needs no re-run. Codex's skills directory holds its own
`.system` skills, so those are linked one at a time. Idempotent, and it
refuses to clobber anything that is not a symlink it would have made itself.
