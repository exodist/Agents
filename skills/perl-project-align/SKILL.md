---
name: perl-project-align
description: Bootstrap a new Perl project against the shared agent repository, or audit an existing one for drift — CLAUDE.md/AGENTS.md/AGENTS_OVERRIDE.md wiring, declarations, agent_scripts, .perltidyrc, TEMPLATE.pod, dist.ini, AI policy. Use when setting up a new distribution under ~/projects or when asked to bring a project in line with the shared conventions.
---

# Align a project with the shared agent repository

Full procedure: **`~/projects/Agents/USING.md`**. Read it — this skill is the
short form.

## The model

The shared repository is an optional common copy of reusable rules. Projects
that adopt it reference it; no project is required to do so. Project-local
documents always take priority.

- Clone URL: `git@github.com:exodist/Agents.git`
- Expected location: `~/projects/Agents`

```
[ -d ~/projects/Agents ] || git clone git@github.com:exodist/Agents.git ~/projects/Agents
```

Three files per project:

| File | Role |
|---|---|
| `CLAUDE.md` | Points at the project's `AGENTS.md`. Nothing else, ever. |
| `AGENTS.md` | Bootstrap stanza (verbatim), then project-specific context. |
| `AGENTS_OVERRIDE.md` | Ledger for declarations and explicit shared-rule overrides. |

## The five declarations

`AGENTS_OVERRIDE.md` **must** answer all five, each with a reason. An
unanswered declaration is how two files in one repository end up in different
styles.

1. **Minimum Perl version** — the exact compatibility promise, or an explicit
   statement that there is no minimum-version promise.
2. **Signature policy** — disabled, or required where the declared
   version/feature pragma can express the call shape.
3. **POD placement** — all POD under `__END__` (default) or the split layout.
4. **Test layout** — category directories (`t/unit`, `t/acceptance`,
   `t/regression`, `t/integration`) plus `# Test origin:` headers (default for
   new projects), or a mirrored `t/AI/` tree.
5. **perltidy** — the shared `templates/perltidyrc` copied to `.perltidyrc`,
   or a project-local variant with what differs and why.

## Setting up a new project

Harvest useful instructions from any existing `CLAUDE.md` or `CODEX.md`
before replacing an entry point. Then copy in: `templates/CODEX.md`,
`templates/CLAUDE.md`, `templates/AGENTS.md`,
`templates/AGENTS_OVERRIDE.md`, `templates/perltidyrc` → `.perltidyrc`,
`templates/TEMPLATE.pod`, `AI_AND_LLM_POLICY.txt`, `templates/dist.ini`,
`templates/gitignore` → `.gitignore`, and the `agent_scripts/` auditors the
project needs. Create `Changes` with a `{{$NEXT}}` section. Then fill in the
placeholders and verify with `audit-dzil`. `USING.md` has the exact command
sequence.

## Auditing an existing project

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
perl ~/projects/Agents/agent_scripts/audit-project-wiring .
perl ~/projects/Agents/agent_scripts/audit-methods-not-functions lib
perl ~/projects/Agents/agent_scripts/audit-readonly-attrs lib
perl ~/projects/Agents/agent_scripts/audit-banned-words
perl ~/projects/Agents/agent_scripts/find-long-subs lib
perl ~/projects/Agents/agent_scripts/find-large-modules lib
```

Then by hand:

- Does `CLAUDE.md` do anything besides point at `AGENTS.md`? Move that content
  into `AGENTS.md`.
- Does `AGENTS.md` open with the bootstrap stanza?
- Does `AGENTS.md` restate universal rules instead of referencing them?
  Replace each copy with a pointer. Where a copy has **drifted** from the
  universal text, that drift is either a real override — move it to
  `AGENTS_OVERRIDE.md` with its reason — or rot, and gets deleted. Decide
  which; do not leave it ambiguous.
- Does `AGENTS_OVERRIDE.md` exist and answer all five declarations?
- Do the project's `agent_scripts/` copies match `~/projects/Agents/`? Fix the
  canonical copy first, then re-copy.

## Report, do not silently restructure

These files are the instructions every future agent reads. Copying in a
missing `.perltidyrc` is fine unasked; rewriting an `AGENTS.md` is not.
Present what drifted and what you propose, then change it once the user
agrees.

Never edit `~/projects/Agents` as a side effect of project work. A rule change
is its own task, in that repository, in its own commit — see its
`REPO_RULES.md`.
