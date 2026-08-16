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
- Default location: `~/projects/Agents`, or whatever the project's
  `AGENTS_OVERRIDE.md` declares under "Agents repository location"

Shared paths are written against the default; read them against a declared
location where there is one. When no checkout exists, ask the user whether to
clone it and where — never clone it for them, and never pick the location
yourself. Record a non-default answer in `AGENTS_OVERRIDE.md`.

## Pending syncs

A project records the commit it last synced with in its bootstrap stanza, and
every session checks it:

```
git -C ~/projects/Agents log --oneline <last-synced-sha>..HEAD -- \
    AI_AND_LLM_POLICY.md templates/ agent_scripts/ SYNC.md
```

Those are the files a project copies, plus the ledger of changes that require
project action. `git diff <last-synced-sha>..HEAD -- SYNC.md` gives the new
ledger entries and their actions. Report what is pending and let the user sync
now — one commit if small, a worktree branch if not — or skip and get on with
what they came for. Move the `Last synced` line to the commit reached, in the
same commit or branch. Never sync unasked. Full procedure: `AGENTS.md` under
"Staying in sync".

Three files per project:

| File | Role |
|---|---|
| `CLAUDE.md` | Points at the project's `AGENTS.md`. Nothing else, ever. |
| `AGENTS.md` | Bootstrap stanza (verbatim), then project-specific context. |
| `AGENTS_OVERRIDE.md` | Ledger for declarations, shared-rule overrides, and a non-default checkout location. |

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
before replacing an entry point. The inventory includes CPAN Testers names,
every test command and local gate, and related-repository propagation
contracts. Then copy in: `templates/CODEX.md`,
`templates/CLAUDE.md`, `templates/AGENTS.md`,
`templates/AGENTS_OVERRIDE.md`, `templates/perltidyrc` → `.perltidyrc`,
`templates/TEMPLATE.pod`, `AI_AND_LLM_POLICY.md`, `templates/dist.ini`,
`templates/Changes`, `templates/MANIFEST.SKIP`, `templates/gitignore` →
`.gitignore`, and the `agent_scripts/` auditors the project needs. If the
project selects the category-and-origin test profile, include
`audit-test-layout` and record its parameterized strict command. Then fill in
the placeholders and verify packaging and optional wiring separately.
`USING.md` has the exact command sequence.

Keep `AI_AND_LLM_POLICY.md` as the repository's only AI/LLM policy document
and include it in the distribution. Match the canonical copy exactly unless
`AGENTS_OVERRIDE.md` declares that the project replaces its policy.

## Auditing an existing project

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
perl ~/projects/Agents/agent_scripts/audit-project-wiring .
```

Then read `skills/perl-pre-review/SKILL.md` and run its applicable whole-tree
code gates. Do not maintain a second command list here.

Then by hand:

- Does `CLAUDE.md` do anything besides point at `AGENTS.md`? Move that content
  into `AGENTS.md`.
- Does `AGENTS.md` open with the current bootstrap stanza? An older one clones
  the repository on its own initiative and names no override — replace it.
- Does the stanza record a real `Last synced` commit? Without one, no session
  can tell what is pending.
- If the checkout is not at `~/projects/Agents`, does `AGENTS_OVERRIDE.md`
  declare where it is, and do the project's own absolute paths match? A
  checkout inside the project must be gitignored and excluded from the
  distribution.
- Does `AGENTS.md` follow `~/projects/Agents/DOCUMENTATION.md` under
  "AI/agent-facing material", especially the rule against copying universal
  guidance? Replace each copy with a pointer. Move real drift to
  `AGENTS_OVERRIDE.md` as a reasoned override; delete stale text.
- Does `AGENTS_OVERRIDE.md` exist and answer all five declarations?
- If it selects the category-and-origin test layout, is its strict
  `audit-test-layout` command parameterized for this project?
- Is `AI_AND_LLM_POLICY.md` the only AI/LLM policy document, included in the
  distribution, and identical to the canonical copy unless an override
  declares a replacement policy?
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
