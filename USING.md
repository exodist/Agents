# USING.md

How a project optionally wires itself to this repository.

Point an agent at this file when a project needs to be set up — or checked —
against the shared agent rules.

---

## The model

This repository is a shared copy of reusable agent rules, Perl style, testing
policy, and packaging guidance. Projects that choose to adopt it
**reference** it. No project is required to do so.

The project's own documents remain authoritative and always override shared
guidance. Adoption supplies defaults; it does not transfer ownership of the
project's architecture or policy.

- **Clone URL:** `git@github.com:exodist/Agents.git`
- **Default location:** `~/projects/Agents`, overridable per project

The main files in a consuming project are:

| File | Role |
|---|---|
| `CODEX.md` / `CLAUDE.md` | Optional harness entry points that direct the agent to the project's `AGENTS.md`. |
| `AGENTS.md` | Opens with the bootstrap stanza pointing here, then carries project-specific context. |
| `AGENTS_OVERRIDE.md` | A convenient ledger for declarations and explicit shared-rule overrides, and where a non-default checkout location is declared. |
| `RULINGS.md` | Optional. Durable record of owner decisions, read only when a decision is needed. |

Copying rules into a project is the failure mode this structure exists to
prevent: a copy drifts, and then two repositories disagree with no way to tell
which is current.

---

## Bootstrap

An agent working in a consuming project starts with `CODEX.md` and/or
`AGENTS.md`, as directed by its harness. If that entry point opts into Agents,
it resolves the checkout in this order:

1. The location `AGENTS_OVERRIDE.md` declares under "Agents repository
   location", when it declares one.
2. `~/projects/Agents`, the default.

**When neither is there, the agent stops and asks the user** whether to clone
the repository and where. It does not clone on the user's behalf and does not
choose a location — a sandbox may have no access to `~/projects` at all, and
where a rules repository lands on someone's disk is theirs to decide. Suggest
the default, and offer a path inside the project when nothing outside it is
writable. Recording the answer in `AGENTS_OVERRIDE.md` is what makes the next
session find it.

```
git clone git@github.com:exodist/Agents.git ~/projects/Agents
```

Shared documents write their paths against the default location. Where a
project declares another, read every `~/projects/Agents/...` path against the
declared one — including the `bin/agent-test-lock` command in the project's
own `AGENTS.md`, which is spelled out there and needs rewriting to match.

**Cloning is the whole setup.** There is no install step: `AGENTS.md` there
points at critical documents and says when to use each tool, auditor, and
procedure by absolute path, so they work from any project immediately.
`~/projects/Agents/install` is an optional convenience that links the
procedure files into the per-user paths `~/.claude/skills` and
`~/.agents/skills`. Codex can then discover them and select them through
`/skills`, `$skill-name`, or implicit matching. Skipping it changes nothing
else.

A consuming project may instead make the Codex skills repository-scoped by
pointing its `.agents/skills` at `~/projects/Agents/skills`. Codex scans that
directory from the working directory up to the repository root and follows
skill-directory symlinks. This remains optional project wiring, not an Agents
adoption requirement.

Whichever location is used may be a checkout or a symlink to one. The checkout
is read-only from a project's point of view. **Never edit it as a side effect
of project work** — a rule change is its own task, in its own commit, in that
repository.

A checkout kept inside a project needs a `.gitignore` entry and, for a
distribution, a packaging exclusion. The project picks the path; shared
guidance deliberately does not name one, because a sandbox that cannot use the
default location usually cannot use a prescribed alternative either.

If the clone looks stale and the work is substantial, `git -C ~/projects/Agents
pull` first. Do not pull mid-task; a rule changing under you halfway through is
worse than a rule being a week old.

---

## Staying in sync

A project references these rules rather than copying them, so most changes
here reach it with nothing to do. The exceptions are the files it does hold
copies of and the changes that ask something of the project itself. Both are
tracked against one recorded commit.

**The project records the commit it last synced with** in its bootstrap
stanza:

```
- Last synced: 9f3c1ab2d4e6f8a0b1c2d3e4f5a6b7c8d9e0f1a2 (2026-08-15)
```

Use the full 40-character sha and the date it was applied. A project adopting
this repository for the first time records the current commit — there is
nothing to apply, because it is copying today's files.

**Every session begins by checking it**, from the project's stanza:

```
git -C ~/projects/Agents log --oneline <last-synced-sha>..HEAD -- \
    AI_AND_LLM_POLICY.md templates/ agent_scripts/ SYNC.md
```

`AI_AND_LLM_POLICY.md`, `templates/`, and `agent_scripts/` are what a project
holds copies of. `SYNC.md` is this repository's ledger of changes requiring
project action — a new declaration to answer, a document to edit, a ruling to
make. `git diff <last-synced-sha>..HEAD -- SYNC.md` yields exactly the entries
added since, each naming its action.

**The user decides what happens next.** Shared `AGENTS.md` under "Staying in
sync" is the procedure: report what is pending, offer to sync now as one
commit or a worktree branch depending on size, and accept "skip for now" as
the normal answer when the user came to do something else. The `Last synced`
line moves to the commit actually reached, in the same commit or branch as the
sync. Nothing is synced unasked.

---

## Reading and authority

Read the project's entry point first, then follow only the critical references
it names. Do not scan every `.md` file for possible instructions.

If the project opts in, read shared `AGENTS.md` and the particular shared
guide or procedure needed for the current task. `AGENTS.md` points to
`DOCUMENTATION.md` for written material. Then read the project-local documents
named by its entry point. Authority does not depend on which file was read
last:

- Project documents override shared Agents documents.
- `ARCHITECTURE.md` governs project design and may replace shared templates
  without an override declaration.
- `AGENTS_OVERRIDE.md` records project declarations and explicit departures
  from shared defaults; it does not grant local files their priority.
- Shared guides cover separate domains. The checklist mirrors the style guide
  and is corrected when they disagree.

---

## Project instruction files

### Harness entry points — harvest before replacing

Sources: `~/projects/Agents/templates/CODEX.md` and
`~/projects/Agents/templates/CLAUDE.md`.

```markdown
# MANDATORY

You MUST read `AGENTS.md` at the root of this repository before doing ANY
work in this project. This is not optional. No exceptions.

`AGENTS.md` contains the authoritative project instructions, conventions,
and constraints. CLAUDE.md exists solely to point you there.

Do not answer questions, make edits, run commands, or plan work until you
have read `AGENTS.md` in the current session.
```

Nothing project-specific goes in a pointer-only entry file. Before replacing
an existing `CLAUDE.md` or `CODEX.md`, inventory its useful content and move
that content into `AGENTS.md` or another appropriate project document. Never
overwrite an existing entry file blindly.

The inventory explicitly includes:

- The CPAN distribution name and any CPAN Testers notes. Keep the name in the
  project `AGENTS.md`; the reusable query procedure lives in
  `~/projects/Agents/CPAN_TESTERS.md`.
- Every test command, environment setting, timeout, alternate harness path,
  and project-specific audit gate.
- Related-repository contracts: paths or distribution names, interfaces and
  prerequisite versions that propagate, and when the related repository must
  be checked.
- Architecture, release, platform, and compatibility facts that are truly
  local to the project.

For a new pointer-only `CLAUDE.md`, use the template above. A `CODEX.md` may
use the same short direction to `AGENTS.md` when the project wants that entry
point. Once harvested, anything you are tempted to put in the pointer belongs
in `AGENTS.md`.

### `AGENTS.md` — bootstrap stanza, then project content

Scaffold: `~/projects/Agents/templates/AGENTS.md`.

It **must open** with this stanza, verbatim:

```markdown
## MANDATORY: read the universal agent rules first

This project opts into shared agent guidance while keeping its own documents
authoritative for project-specific rules and design.

- Repository: `git@github.com:exodist/Agents.git`
- Default location: `~/projects/Agents`
- This project's location: as declared in `AGENTS_OVERRIDE.md` under "Agents
  repository location", when that section is present.
- Last synced: 0000000000000000000000000000000000000000 (YYYY-MM-DD)

Use the declared location when there is one, otherwise the default. If no
checkout is there, **stop and ask the user** whether to clone it and where.
Never clone it for them, and never guess a location.

Shared documents spell their paths against the default location. When this
project declares another, read every such path against the declared one.

Check for pending syncs once, at the start of the session:

    git -C <location> log --oneline <last-synced-sha>..HEAD -- \
        AI_AND_LLM_POLICY.md templates/ agent_scripts/ SYNC.md

No output means nothing to apply. Otherwise follow "Staying in sync" in the
shared `AGENTS.md`: show the user what is pending and let them sync now or
skip it and carry on with what they came here to do. Never sync unasked.

Then read `AGENTS.md` in that checkout and follow the shared guidance this
project has adopted. It points at task-specific guides and procedures.

All documents in THIS repository take priority over the shared repository.
Read the project documents named below; `AGENTS_OVERRIDE.md` records
declarations and explicit shared-rule overrides when present.
```

After the stanza, `AGENTS.md` carries **only what is true of this project**:

- What the project is, and the CPAN distribution name.
- Project test specifics — extra environment variables, a second command that
  must also pass, expected suite duration, the right timeout, known slow files.
- Project-specific pre-review gates (extra `agent_scripts/` auditors).
- Related repositories and the exact changes that require checking them.
- An architecture quick-reference: the foundational rules an agent must
  internalise before writing code here.
- **Only if the project has one:** its reference tree, and what each subtree
  is good for. Most projects have none — leave the section out entirely rather
  than leaving an empty heading, or an agent will go hunting for one.

It does **not** restate universal rules. A rule that appears in both places
will drift, and the copy is the one that goes stale.

Its writing follows `DOCUMENTATION.md` under "AI/agent-facing material".

### `AGENTS_OVERRIDE.md` — declarations and overrides

Scaffold: `~/projects/Agents/templates/AGENTS_OVERRIDE.md`.

Three jobs, one of them optional.

**0. Declare the Agents location, only when it is not the default.** An
optional `## Agents repository location` section pins where the checkout is,
for projects that cannot or do not use `~/projects/Agents`. Its absence means
the default, so nearly every project leaves it out. It is deliberately not a
sixth mandatory declaration: the other five exist because no answer suits all
projects, and this one has a perfectly good default.

**1. Answer every project-declared choice.** The universal docs deliberately
leave some rules open because there is no right answer for all projects. Each
must be pinned, with a reason:

- **Minimum Perl version** — an exact compatibility promise, or an explicit
  statement that the project makes no minimum-version promise.
- **Signature policy** — disabled, or required where the project's declared
  version/feature pragma can express the call shape.
- **POD placement** — all POD under `__END__` (default) or the split layout.
- **Test layout** — category directories (`t/unit`, `t/acceptance`,
  `t/regression`, `t/integration`) plus `# Test origin:` headers (default for
  new projects), or a mirrored `t/AI/` tree.
- **perltidy** — the shared `templates/perltidyrc`, or a project-local
  `.perltidyrc`.

An unanswered declaration is how two files in one repository end up in
different styles.

**2. Record deliberate shared-rule overrides**, with the reason. This is the
preferred ledger so an exception is easy to find. A project-local
`ARCHITECTURE.md`, `TESTING.md`, or other authoritative document also wins
without duplicating its contents here.

Keep it to declarations and overrides. Project *context* goes in `AGENTS.md`,
project *design* goes in `ARCHITECTURE.md`. Owner *rulings* go in
`RULINGS.md`.

### `RULINGS.md` — durable owner decisions

Scaffold: `~/projects/Agents/templates/RULINGS.md`.

Optional, and not part of new-project setup — create it from the scaffold when
the first ruling worth recording lands. Absent means the project has none, and
a long-running project may never need one. Agents read it only when a decision
is in front of them; shared `AGENTS.md` under "Rulings" governs how a recorded
ruling is treated and, under "What earns a place in `RULINGS.md`", which
decisions belong there at all. Most do not.

---

## Setting up a new project

With the checkout in place (see "Bootstrap" — ask the user before creating
one, and substitute its location throughout if it is not the default):

```
cd /path/to/project

cp ~/projects/Agents/templates/CLAUDE.md            CLAUDE.md
cp ~/projects/Agents/templates/CODEX.md             CODEX.md
cp ~/projects/Agents/templates/AGENTS.md            AGENTS.md
cp ~/projects/Agents/templates/AGENTS_OVERRIDE.md   AGENTS_OVERRIDE.md
cp ~/projects/Agents/templates/perltidyrc           .perltidyrc
cp ~/projects/Agents/templates/TEMPLATE.pod         TEMPLATE.pod
cp ~/projects/Agents/AI_AND_LLM_POLICY.md           AI_AND_LLM_POLICY.md
cp ~/projects/Agents/templates/dist.ini             dist.ini
cp ~/projects/Agents/templates/Changes              Changes
cp ~/projects/Agents/templates/MANIFEST.SKIP        MANIFEST.SKIP
cp ~/projects/Agents/templates/gitignore            .gitignore

mkdir -p agent_scripts
cp ~/projects/Agents/agent_scripts/audit-methods-not-functions agent_scripts/
cp ~/projects/Agents/agent_scripts/audit-readonly-attrs        agent_scripts/
cp ~/projects/Agents/agent_scripts/audit-banned-words          agent_scripts/
cp ~/projects/Agents/agent_scripts/find-long-subs              agent_scripts/
cp ~/projects/Agents/agent_scripts/find-large-modules          agent_scripts/
```

Keep exactly one AI/LLM policy document in the repository and distribution,
named `AI_AND_LLM_POLICY.md`. It matches the canonical copy byte-for-byte
unless `AGENTS_OVERRIDE.md` explicitly declares a different policy. An
override replaces the file's content; it does not add a second policy file.

If the project selects TESTING.md's category-and-origin layout, also copy
`audit-test-layout` and record its exact parameterized `--mode strict` command
in `AGENTS_OVERRIDE.md`. Projects selecting another layout do not copy or run
that auditor.

Record the commit the project is starting from, in the stanza's `Last synced`
line:

```
git -C ~/projects/Agents log -1 --format='%H %ad' --date=short
```

Then fill in `AGENTS.md` (project content), `AGENTS_OVERRIDE.md` (the five
declarations), `dist.ini` (name, main module, repo URL, prereqs),
`TEMPLATE.pod` (dist name, repo URL), `.gitignore` (dist name), and any
project-specific `MANIFEST.SKIP` patterns.

Before copying either harness entry point, harvest useful content from the
existing file, including CPAN Testers names, all test commands and gates, and
related-repository propagation rules. Verify packaging and optional Agents
wiring separately:

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
perl ~/projects/Agents/agent_scripts/audit-project-wiring .
```

### Packaging changes an existing project needs on adoption

An older distribution usually needs these, and the audit reports each:

- **Add `[PruneCruft]`** if it is missing. It is part of this repository's
  packaging guidance; several existing distributions predate the rule.
- **Add `[RunExtraTests]`** if the project has an `xt/` directory. Without it
  those author tests have never run.
- **Exclude the dev-only trees** the project actually has — `agent_scripts/`,
  `AI_DOCS/`, `worktrees/`, and internal `.md` — from `[GatherDir]`.
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

Run packaging and optional wiring audits separately. Then read
`skills/perl-pre-review/SKILL.md` and run its applicable whole-tree code gates:

```
perl ~/projects/Agents/agent_scripts/audit-dzil .
perl ~/projects/Agents/agent_scripts/audit-project-wiring .
```

By hand:

- Does `CLAUDE.md` or `CODEX.md` do anything besides point at `AGENTS.md`?
  Harvest that content into the appropriate project document before replacing
  the entry point.
- Does `AGENTS.md` open with the current bootstrap stanza? An older one tells
  the agent to clone the repository itself and names no override — replace it.
- Does the stanza carry a `Last synced` line with a real commit? Without one
  no session can tell what is pending. Establish the baseline by applying
  whatever is outstanding, then record the commit reached.
- Is the checkout somewhere other than `~/projects/Agents`? Then
  `AGENTS_OVERRIDE.md` needs its location section, and any absolute path the
  project spells out for itself — the `agent-test-lock` command in its
  `AGENTS.md`, most often — needs to match. If it sits inside the project, is
  it gitignored and excluded from the distribution?
- Does `AGENTS.md` follow `DOCUMENTATION.md` under "AI/agent-facing material",
  especially the rule against copying universal guidance? Replace each copy
  with a pointer, keeping only the project-specific parts. If a copy has
  drifted, move a real override to `AGENTS_OVERRIDE.md`; delete stale text.
- Does `AGENTS_OVERRIDE.md` exist, and answer all five declarations?
- If it selects the category-and-origin test layout, does its recorded strict
  `audit-test-layout` command match the project namespace and exceptions?
- Is `AI_AND_LLM_POLICY.md` the repository's only AI/LLM policy document, and
  does it ship with the distribution? Unless an override declares a different
  policy, does it match `~/projects/Agents/AI_AND_LLM_POLICY.md` exactly?
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
