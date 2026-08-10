# Agents

Optional shared agent instructions, style rules, and cross-project tooling for
Chad Granum's ("Exodist") Perl projects.

Projects may point here when the shared guidance is useful. Nothing under
`~/projects` is required to adopt it. Employer repositories, third-party
forks, non-Perl repositories, and any other project that has not opted in are
outside its scope.

A consuming project's own documents always take priority over this repository.
The shared files provide defaults and reusable procedures; they do not replace
project architecture, policy, or context.

- **Clone URL:** `git@github.com:exodist/Agents.git`
- **Expected location:** `~/projects/Agents`

**Setting a project up? Read [`USING.md`](USING.md).** It covers the whole
wiring: the bootstrap stanza, what goes in which file, and how to audit a
project for drift.

## Documents

| File | What it covers |
|---|---|
| [`USING.md`](USING.md) | How a project wires itself to this repository. Point an agent here to set one up. |
| [`AGENTS.md`](AGENTS.md) | Agent workflow and engineering judgment: scope, cost versus value, decisions, pre-review, testing, commits, changelog, and worktrees. |
| [`DOCUMENTATION.md`](DOCUMENTATION.md) | Content rules for human and agent documents, commit messages, `Changes`, comments, and POD. |
| [`PERL_STYLE_GUIDE.md`](PERL_STYLE_GUIDE.md) | Perl style and layout: object orientation, errors, filehandles, conditionals, naming, terminology, perltidy, POD placement, and sizes. |
| [`STYLE_GUIDE_AGENT_CHECKLIST.md`](STYLE_GUIDE_AGENT_CHECKLIST.md) | The self-audit form of the style guide. Walk it before handing work back. |
| [`TESTING.md`](TESTING.md) | Test execution, the shared concurrency lock, memory traps, test layout and provenance. |
| [`DATABASES.md`](DATABASES.md) | Optional database-test operations, developer installs, and per-install isolation. |
| [`DZIL_GUIDE.md`](DZIL_GUIDE.md) | An optional shared `dist.ini` profile and manual release procedure. |
| [`CPAN_TESTERS.md`](CPAN_TESTERS.md) | Task-specific procedure for querying and analyzing public CPAN Testers reports. |
| [`AI_AND_LLM_POLICY.txt`](AI_AND_LLM_POLICY.txt) | Canonical contributor-facing AI/LLM policy. Adopting projects ship one synchronized copy unless they declare a replacement policy. |
| [`REPO_RULES.md`](REPO_RULES.md) | Rules for editing **this** repository. Consuming projects do not inherit them. |
| [`CLAUDE.md`](CLAUDE.md) | Points at `AGENTS.md`. That is its entire job. |

## Per-project files

| File | Role |
|---|---|
| `CLAUDE.md` | Points at the project's `AGENTS.md`. Nothing else, ever. |
| `AGENTS.md` | Bootstrap stanza pointing here, then project-specific context. |
| `AGENTS_OVERRIDE.md` | A ledger for project declarations and explicit shared-rule overrides. |
| `AI_AND_LLM_POLICY.txt` | The sole contributor-facing AI/LLM policy, included in the distribution. |

`CODEX.md` and `CLAUDE.md` are optional harness entry points. When present,
their job is to direct the agent to the project's `AGENTS.md`; existing useful
content is harvested into project documents before either file is replaced.

Five rules are deliberately **project-declared** — they have no universal
answer, and each project's `AGENTS_OVERRIDE.md` must pin them:

1. **Minimum Perl version** — the project's exact compatibility promise.
2. **Signature policy** — disabled, or required where the declared feature
   set can express the call shape.
3. **POD placement** — all POD under `__END__` (default), or the split layout.
4. **Test layout** — category directories plus origin headers (default for new
   projects), or a `t/AI/` mirror tree.
5. **perltidy** — the shared `templates/perltidyrc`, or a project-local one.

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

Code auditors exit non-zero on a hit and are used as project-applicable
pre-review gates:

```
agent_scripts/audit-methods-not-functions   Subs defined in an object module
                                            called as bare functions.
agent_scripts/audit-readonly-attrs          Read-only HashBase slots using
                                            `-attr` instead of `<attr`.
agent_scripts/audit-banned-words            Forbidden terminology.
agent_scripts/audit-test-layout             The optional category-and-origin
                                            test layout profile.
agent_scripts/find-long-subs                Subs over 75 lines.
agent_scripts/find-large-modules            Modules over 10,000 lines.
agent_scripts/audit-no-secrets              Credentials and sensitive
                                            material. Mandatory before every
                                            commit HERE (see REPO_RULES.md).
```

Packaging and adoption auditors also exit non-zero on findings, but their
findings are advisory and only relevant when a project elects to use the
corresponding shared profile:

```
agent_scripts/audit-dzil                    dist.ini against DZIL_GUIDE.md.
agent_scripts/audit-project-wiring          Optional Agents integration and
                                            project declarations.
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
`CODEX.md`, `CLAUDE.md`, an `AGENTS.md` scaffold, an `AGENTS_OVERRIDE.md`
scaffold, `TEMPLATE.pod`, `perltidyrc`, `dist.ini`, `Changes`,
`MANIFEST.SKIP`, and a `.gitignore`. `USING.md` has the copy-in sequence.

## Installing — not required

**Clone it and it works.** `AGENTS.md` points agents at the critical shared
documents and says when to use each tool, auditor, and procedure by absolute
path. Nothing is installed, and nothing breaks if it never is.

```
git clone git@github.com:exodist/Agents.git ~/projects/Agents
```

`./install` is a convenience for per-user skill discovery. It links skills
into `~/.claude/skills` for Claude Code and `~/.agents/skills` for Codex.
Codex also discovers repository-scoped `.agents/skills` directories and can
select skills implicitly or through `/skills` and `$skill-name`. Without the
installer, the same files are still read as procedures — `AGENTS.md` says when
to read which. It also links `bin/*` into `~/.local/bin` to save typing. See
OpenAI's [current Codex skill documentation](https://developers.openai.com/codex/skills)
for the discovery and invocation behavior.

```
./install --dry-run
./install
```

It links each per-user skills directory as a whole when that path is free, so
a skill added later needs no re-run. When a directory already exists, it links
each skill separately. It is idempotent and refuses to clobber anything that
is not a symlink it would have made itself.

## License

This repository is available under the same terms as Perl 5. See
[`LICENSE`](LICENSE).
