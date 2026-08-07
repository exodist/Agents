# USING.md

How a project wires itself to this repository.

Point an agent at this file when a project needs to be set up — or checked —
against the shared agent rules.

---

## The model

This repository is the **single copy** of the agent rules, Perl style, testing
policy, and packaging spec. Projects **reference** it. They never copy it.

- **Clone URL:** `git@github.com:exodist/Agents.git`
- **Expected location:** `~/projects/Agents`

Three files live in each consuming project:

| File | Role |
|---|---|
| `CLAUDE.md` | Points at the project's `AGENTS.md`. Nothing else, ever. |
| `AGENTS.md` | Opens with the bootstrap stanza pointing here, then carries project-specific context. |
| `AGENTS_OVERRIDE.md` | The project's declarations and overrides. Wins over the universal rules. |

Copying rules into a project is the failure mode this structure exists to
prevent: a copy drifts, and then two repositories disagree with no way to tell
which is current.

---

## Bootstrap

An agent working in a consuming project follows the chain from `CLAUDE.md`. If
`~/projects/Agents` is not present, it clones it before doing anything else:

```
[ -d ~/projects/Agents ] || git clone git@github.com:exodist/Agents.git ~/projects/Agents
```

**Cloning is the whole setup.** There is no install step: `AGENTS.md` there
points at every document, tool, auditor, and procedure by absolute path, so
they work from any project immediately. (`~/projects/Agents/install` is an
optional convenience that links the procedure files into `~/.claude/skills`
and `~/.codex/skills` — the only paths those harnesses scan — so they also
gain `/name` invocation. Skipping it changes nothing else.)

The clone is read-only from a project's point of view. **Never edit
`~/projects/Agents` as a side effect of project work** — a rule change is its
own task, in its own commit, in that repository.

If the clone looks stale and the work is substantial, `git -C ~/projects/Agents
pull` first. Do not pull mid-task; a rule changing under you halfway through is
worse than a rule being a week old.

---

## Resolution order

An agent reads, in this order, and later entries win over earlier ones:

1. **`CLAUDE.md`** (project) — sends you to `AGENTS.md`.
2. **`AGENTS.md`** (project) — bootstrap stanza sends you here.
3. **`~/projects/Agents/AGENTS.md`** — workflow, pre-review passes, commits,
   changelog, worktrees.
4. **`~/projects/Agents/PERL_STYLE_GUIDE.md`**,
   **`STYLE_GUIDE_AGENT_CHECKLIST.md`**, **`TESTING.md`**, **`DZIL_GUIDE.md`**.
5. **`AGENTS.md`** (project) — the rest of it: what this project is, its
   reference trees, its extra gates.
6. **`AGENTS_OVERRIDE.md`** (project) — declarations and overrides. **Where it
   speaks, it wins.**
7. **`ARCHITECTURE.md`** and other project docs — authoritative for design.

---

## The three files

### `CLAUDE.md` — copy verbatim

Source: `~/projects/Agents/templates/CLAUDE.md`.

```markdown
# MANDATORY

You MUST read `AGENTS.md` at the root of this repository before doing ANY
work in this project. This is not optional. No exceptions.

`AGENTS.md` contains the authoritative project instructions, conventions,
and constraints. CLAUDE.md exists solely to point you there.

Do not answer questions, make edits, run commands, or plan work until you
have read `AGENTS.md` in the current session.
```

Nothing project-specific goes in `CLAUDE.md`. It exists so Claude Code's
automatic `CLAUDE.md` pickup lands on the real instructions. Anything you are
tempted to put here belongs in `AGENTS.md`.

### `AGENTS.md` — bootstrap stanza, then project content

Scaffold: `~/projects/Agents/templates/AGENTS.md`.

It **must open** with this stanza, verbatim:

```markdown
## MANDATORY: read the universal agent rules first

The authoritative agent instructions for this project live in a shared
repository, not in this file.

- Repository: `git@github.com:exodist/Agents.git`
- Expected location: `~/projects/Agents`

If `~/projects/Agents` does not exist, clone it before doing anything else:

    git clone git@github.com:exodist/Agents.git ~/projects/Agents

Then read `~/projects/Agents/AGENTS.md` and follow it. It is authoritative for
workflow, pre-review checks, commits, changelog, and worktrees, and it points
at the Perl style guide, the self-audit checklist, the testing policy, and the
packaging guide.

`AGENTS_OVERRIDE.md` in THIS repository records the declarations and overrides
that apply here. Read it after the universal rules; where it speaks, it wins.
```

After the stanza, `AGENTS.md` carries **only what is true of this project**:

- What the project is, and the CPAN distribution name.
- Project test specifics — extra environment variables, a second command that
  must also pass, expected suite duration, the right timeout, known slow files.
- Project-specific pre-review gates (extra `agent_scripts/` auditors).
- An architecture quick-reference: the foundational rules an agent must
  internalise before writing code here.
- **Only if the project has one:** its reference tree, and what each subtree
  is good for. Most projects have none — leave the section out entirely rather
  than leaving an empty heading, or an agent will go hunting for one.

It does **not** restate universal rules. A rule that appears in both places
will drift, and the copy is the one that goes stale.

### `AGENTS_OVERRIDE.md` — declarations and overrides

Scaffold: `~/projects/Agents/templates/AGENTS_OVERRIDE.md`.

Two jobs.

**1. Answer every project-declared choice.** The universal docs deliberately
leave some rules open because there is no right answer for all projects. Each
must be pinned, with a reason:

- **Perl floor / signatures** — Mode A (portable: `use strict; use warnings;`,
  no signatures) or Mode B (modern: `use v5.38;`, signatures everywhere).
  Unstated means Mode A.
- **POD placement** — all POD under `__END__` (default) or the split layout.
- **Test layout** — category directories (`t/unit`, `t/acceptance`,
  `t/regression`, `t/integration`) plus `# Test origin:` headers (default for
  new projects), or a mirrored `t/AI/` tree.
- **perltidy** — the shared `templates/perltidyrc`, or a project-local
  `.perltidyrc`.

An unanswered declaration is how two files in one repository end up in
different styles.

**2. Record every deliberate override**, with the reason. A project may
override any universal rule — but only in this file, in the open. A rule
quietly ignored in the code is a bug; a rule overridden here is a decision.

Keep it to declarations and overrides. Project *context* goes in `AGENTS.md`,
project *design* goes in `ARCHITECTURE.md`.

---

## Setting up a new project

```
[ -d ~/projects/Agents ] || git clone git@github.com:exodist/Agents.git ~/projects/Agents
cd /path/to/project

cp ~/projects/Agents/templates/CLAUDE.md            CLAUDE.md
cp ~/projects/Agents/templates/AGENTS.md            AGENTS.md
cp ~/projects/Agents/templates/AGENTS_OVERRIDE.md   AGENTS_OVERRIDE.md
cp ~/projects/Agents/templates/perltidyrc           .perltidyrc
cp ~/projects/Agents/templates/TEMPLATE.pod         TEMPLATE.pod
cp ~/projects/Agents/AI_AND_LLM_POLICY.txt          AI_AND_LLM_POLICY.txt
cp ~/projects/Agents/templates/dist.ini             dist.ini
cp ~/projects/Agents/templates/gitignore            .gitignore

mkdir -p agent_scripts
cp ~/projects/Agents/agent_scripts/audit-methods-not-functions agent_scripts/
cp ~/projects/Agents/agent_scripts/audit-readonly-attrs        agent_scripts/
cp ~/projects/Agents/agent_scripts/audit-banned-words          agent_scripts/
cp ~/projects/Agents/agent_scripts/find-long-subs              agent_scripts/
cp ~/projects/Agents/agent_scripts/find-large-modules          agent_scripts/
```

Then fill in `AGENTS.md` (project content), `AGENTS_OVERRIDE.md` (the four
declarations), `dist.ini` (name, main module, repo URL, prereqs),
`TEMPLATE.pod` (dist name, repo URL), and `.gitignore` (dist name). Create
`Changes` with a `{{$NEXT}}` section.

Verify:

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
```

### Packaging changes an existing project needs on adoption

An older distribution usually needs these, and the audit reports each:

- **Add `[PruneCruft]`** if it is missing. It is mandatory in every project
  going forward; several existing ones predate the rule.
- **Add `[RunExtraTests]`** if the project has an `xt/` directory. Without it
  those author tests have never run.
- **Exclude the dev-only trees** the project actually has — `agent_scripts/`,
  `AI_DOCS/`, `worktrees/`, and internal `.md` — from `[GatherDir]`.
- **Move optional database drivers and flavor helpers** out of `[Prereqs]`
  into `RuntimeSuggests`.
- **Move `[VersionFromModule]`** to `[RewriteVersion]` +
  `[BumpVersionAfterRelease]`.
- **Update the author string** to `Chad Granum <exodist7@gmail.com>`.

Packaging changes affect what ships to CPAN. Report them and let the user
decide, rather than applying them as part of adopting the repository.

**A dual-life distribution overrides several of these at once** (plain
`[MakeMaker]`, no `.md` exclusion, a very low perl floor). Record that in
`AGENTS_OVERRIDE.md` — see `DZIL_GUIDE.md` "Distribution shapes".

---

## Auditing an existing project

Run the gates, then check the wiring by hand:

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
perl ~/projects/Agents/agent_scripts/audit-methods-not-functions lib
perl ~/projects/Agents/agent_scripts/audit-readonly-attrs lib
perl ~/projects/Agents/agent_scripts/audit-banned-words
perl ~/projects/Agents/agent_scripts/find-long-subs lib
perl ~/projects/Agents/agent_scripts/find-large-modules lib
```

By hand:

- Does `CLAUDE.md` do anything besides point at `AGENTS.md`? Move that content
  into `AGENTS.md`.
- Does `AGENTS.md` open with the bootstrap stanza?
- Does `AGENTS.md` restate universal rules instead of referencing them? Replace
  each copy with a pointer, keeping only the project-specific parts. If a copy
  has drifted from the universal text, that drift is either a real override —
  move it to `AGENTS_OVERRIDE.md` — or rot, and gets deleted.
- Does `AGENTS_OVERRIDE.md` exist, and answer all four declarations?
- Do the project's `agent_scripts/` copies match `~/projects/Agents/`? Fix the
  canonical copy first, then re-copy.

**Report before restructuring.** These files are the instructions every future
agent reads. Copying in a missing `.perltidyrc` is fine unasked; rewriting an
`AGENTS.md` is not.

---

## Changing a universal rule

1. Change it in `~/projects/Agents`, in its own commit.
2. If a project already overrides it, check whether the override is still
   wanted.
3. Do not sweep the change through project files — there is nothing to sweep.
   That is the point.
