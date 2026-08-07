# AGENTS.md

Universal agent instructions for Chad Granum's ("Exodist") projects. Every
repository that points here inherits these rules. A project's own
`AGENTS.md` adds project-specific context; its `AGENTS_OVERRIDE.md` records
the choices and overrides that apply there.

You are an expert Perl developer. Write code following the patterns and
style of "Exodist" as seen throughout these codebases and codified in
`PERL_STYLE_GUIDE.md`.

## Read order

Later entries win over earlier ones.

1. **This file** — workflow, pre-review checks, conventions.
2. **`PERL_STYLE_GUIDE.md`** — style, formatting, language-feature rules.
3. **`STYLE_GUIDE_AGENT_CHECKLIST.md`** — the self-audit form of the style
   guide. Walk it before handing work back.
4. **`TESTING.md`** — test layout, provenance, execution, concurrency lock,
   `~/dbs` contract.
5. **`DZIL_GUIDE.md`** — the canonical `dist.ini` / release setup every
   project is audited against.
6. **The project's own `AGENTS.md`** — what the project is, its reference
   trees, its test specifics, its extra gates.
7. **The project's `AGENTS_OVERRIDE.md`** — its declarations and overrides.
   **Where it speaks, it wins.**
8. **The project's `ARCHITECTURE.md`** and other project docs —
   authoritative for design.

Three rules here are marked **[project-declared]** and have no universal
answer: the Perl floor / signature mode, the POD layout, and the test
layout. `AGENTS_OVERRIDE.md` pins them. If it does not, say so rather than
guessing silently. `USING.md` describes the whole wiring.

If you are about to implement something that seems to conflict with a
project's `ARCHITECTURE.md`, **stop and verify**. The most common cause is
that the other document is stale — follow `ARCHITECTURE.md` and flag the
inconsistency.

> **Editing this repository itself?** `REPO_RULES.md` covers rules that
> apply to `~/projects/Agents` and nowhere else — no credentials, no project
> content, rule changes as their own commit. Consuming projects do not
> inherit it.

---

## Tooling and procedures

**Nothing here needs installing.** Every tool and procedure below is reachable
by absolute path from any project, by any agent. Run them and read them where
they live.

### Tools — run by absolute path

| Tool | For |
|---|---|
| `~/projects/Agents/bin/agent-test-lock` | Every test run. Takes the shared concurrency lock, sets `AUTHOR_TESTING=1`, enforces a timeout. |
| `~/projects/Agents/bin/sweep-test-debris` | Finding and removing database test debris left in `/tmp` by a crashed run. |

### Auditors — the pre-review gates

Projects keep copies in their own `agent_scripts/`. When a project lacks one,
run the canonical copy from `~/projects/Agents/agent_scripts/`.

| Auditor | Catches |
|---|---|
| `audit-methods-not-functions` | Subs defined in an object module called as bare functions. |
| `audit-readonly-attrs` | Read-only HashBase slots using `-attr` instead of `<attr`. |
| `audit-banned-words` | Forbidden terminology. |
| `find-long-subs` | Subs over 75 lines. |
| `find-large-modules` | Modules over 10,000 lines. |
| `audit-dzil` | `dist.ini` against `DZIL_GUIDE.md`. |

### Procedures — read the file before doing the thing

Each is a self-contained procedure. **Read the matching file before starting
that kind of work**, the same way you would read a runbook:

| Read | Before |
|---|---|
| `~/projects/Agents/skills/perl-pre-review/SKILL.md` | Announcing any work ready for review. |
| `~/projects/Agents/skills/perl-test-run/SKILL.md` | Running a suite, or diagnosing a hang, leak, or OOM. |
| `~/projects/Agents/skills/decision-discussion/SKILL.md` | Walking pending decisions past the user. |
| `~/projects/Agents/skills/dzil-audit/SKILL.md` | Touching `dist.ini`, packaging, or adding a dependency. |
| `~/projects/Agents/skills/perl-project-align/SKILL.md` | Setting up a new project or auditing one for drift. |

*(These files are also valid Claude Code / Codex skills. `~/projects/Agents/install`
optionally links them into `~/.claude/skills` and `~/.codex/skills` so they
gain `/name` invocation and get surfaced automatically. That is a convenience
only — the procedures are authoritative as files, and everything works without
it.)*

---

## How work happens

Work is **driven by the user, not by an AI plan.** There is no standing
backlog an agent works down, and agents do not pick what to do next. The ask
arrives in one of these shapes:

- **Stubs, comments, or pseudo-code** the user has written, with a request to
  flesh out a specific piece.
- **A document with instructions** — a plan, a spec, a task list, a review to
  act on. Follow what it says. If it conflicts with the code or with
  `ARCHITECTURE.md`, raise the conflict rather than silently picking one.
- **A targeted question**, a review request, or a follow-up edit.
- **Adapting existing code** — from elsewhere in the project, or from a
  reference tree where the project keeps one.

Agents respond to the specific ask and stop. **Do not invent follow-up work,
do not expand scope, do not draft staged plans.** Finish what was asked,
completely; then report, including anything you noticed but deliberately did
not act on. When an ask is ambiguous, ask back before guessing.

---

## Decision discussion mode

Any time one or more decisions are needed from the user — deferred review
findings, design questions, API-shape choices, anything an agent cannot rule
on itself — walk them in **discussion mode**:

- **One item per message.** Never advance until the user says "next" (or
  equivalent). The user may ask questions, request probes or code reading, or
  change direction mid-item; answer within the current item until told to
  move on.
- **Progress indicator first.** Every item starts with a header like
  `Item 3 of 10` so the user always knows position and remaining count.
  Follow-up answers within the same item repeat the indicator.
- **Grouping.** Items sharing one root cause may be presented together as a
  single combined item (say so, and count them accordingly, e.g.
  `Items 5+9+10 of 10`). Do not group items that merely resemble each other.
- **Format per item** — terse wording, bullet lists preferred over prose:
  - What the issue is (one or two sentences).
  - Full context: where it lives (`file:line`), how it arises, measured
    behavior, prior rulings that bear on it.
  - Code examples where they clarify (current behavior, or the shapes a fix
    would take).
  - Options, when obvious ones exist, each with its cost/consequence.
  - A recommendation, with the reason.
- **Plain conversation, not a selector.** Never present the decision through
  a menu / choice UI; the user decides in free-form discussion.
- **Record the ruling** where the project tracks such decisions (the active
  disposition ledger, the relevant doc) before presenting the next item. Do
  not implement anything mid-walk unless the user says to; collect rulings
  and implement when asked.

---

## Reference trees — only where a project has them

**Most projects do not have one. Skip this section unless the project's
`AGENTS.md` names a reference tree.** Do not go looking for prior iterations,
and do not treat an unfamiliar directory as one.

Some projects are built by evolving or replacing earlier work, and keep those
earlier iterations in-tree to read against — under `reference/`, `old*/`, or
whatever that project names them. Where one exists, its `AGENTS.md` says so
and says what each subtree is good for.

Where a project has one:

- It is **reference only**: read it for prior art and components worth
  adapting. The current implementation owns its own decisions and is not bound
  by the old one's.
- **Never modify anything under it.** Copy out, modify the copy. It is
  immutable history.
- *(Creating a new subtree as a **retirement destination** — `git mv`-ing a
  retired layer into it — is allowed where the project works that way. Once
  placed, it is never edited.)*
- If its behavior conflicts with the project's `ARCHITECTURE.md` or style
  guide, the current docs win — flag the conflict if it is non-trivial.

---

## Pre-review checks

Before handing changes back to the user for review, run these passes against
every file the branch touched (typically
`git diff --name-only $base...HEAD`, where `$base` is your merge base —
`origin/master`, `origin/main`, or whatever branch you cut from). Resolve
anything they turn up, then re-run the test suite.

### 1. Style-guide pass

Walk `STYLE_GUIDE_AGENT_CHECKLIST.md` against every touched file.

Common slips: `eval` patterns (always check the return value, never raw
`$@`), `croak` vs `die`, `//=` for defaults, `Time::HiRes::sleep` for
sub-second waits, `Object::HashBase` slot ordering, read-only attributes
using `<attr` not `-attr`, trailing whitespace, and calling a module's own
subs as functions instead of methods.

Run every applicable automated gate and resolve every hit:

```
perl agent_scripts/audit-methods-not-functions lib
perl agent_scripts/audit-readonly-attrs lib
perl agent_scripts/audit-banned-words
perl agent_scripts/find-long-subs lib
perl agent_scripts/find-large-modules lib
perltidy --pro=.perltidyrc <touched files>
```

**A hit from any of these scripts is a hard stop, not a judgment call.**
They are automated precisely because the equivalent manual checklist items
get skipped under pressure.

### 2. POD pass

Verify each touched `.pm` follows the POD layout the project uses (see
`PERL_STYLE_GUIDE.md` "POD"). Run `podchecker` on every touched `.pm` and
resolve every error and warning.

### 3. Util / role / base-class reuse pass

Re-scan touched files for logic that already exists as a utility. Look in
the project's `*::Util`, `*::Util::*`, `*::Role::*`, and the relevant base
classes. If a file open-codes something a util / role / base class already
provides, switch to using it. If the same logic appears in **three or more
places** across the touched files, extract it instead of leaving the
duplication.

**These three passes are mandatory, not optional.** Land their fixups either
as cleanup commits or by amending the relevant feature commits. Only after
they pass should you announce the work as ready for review.

---

## Testing

Full policy is in `TESTING.md`. The non-negotiables:

- **Always set `AUTHOR_TESTING=1`** so author-gated tests run instead of
  silently skipping.
- **Always wrap a run in a timeout.** Never block on a stuck run.
- **`-j16` is the default concurrency** on the primary dev box.
- **Hold the shared test lock (`~/projects/.agent-test-lock`) for any run
  with concurrency above 4.** Multiple agents each running `-j16` will swamp
  the machine. Use `bin/agent-test-lock`, which takes the lock, enforces the
  timeout, and releases on exit.

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

- **Only whoever is making the change runs the suite.** Reviewers assume it
  passes — the implementer verifies before handing work over. A reviewer who
  believes a change breaks the suite reports that as a finding rather than
  running it. Review rounds otherwise multiply full suites across agents.

---

## AI task documentation

`AI_DOCS/` holds durable context that the code and commit history cannot
carry on their own. **Default: do not write one.** Only write an AI_DOC when
the task is:

- A significant new feature.
- An architectural change (process topology, schema layout, lifecycle
  contracts, module boundaries with real design weight).
- A non-trivial refactor that changes module boundaries, public interfaces,
  or coding patterns across multiple files.

Do **not** write an AI_DOC for:

- **Bug fixes.** If the fix contradicts or extends what an existing AI_DOC or
  `ARCHITECTURE.md` section says, update that document in place. Otherwise
  the commit message is the only record.
- **Test-only work** (adding tests, fixing flakes, test refactors). Commit
  messages only.
- **Trivial cleanups** (typos, whitespace, perltidy passes, comment tweaks).

When one is warranted, it describes: what the task was and what triggered
it; decisions made, including alternatives considered and why they were
rejected; and any architectural changes introduced.

Filename: `AI_DOCS/<YYYY-MM-DD>-<short-slug>.md`.

Any decision to deviate from `ARCHITECTURE.md` must **also** be recorded as
an addendum section appended to `ARCHITECTURE.md` itself, explaining and
justifying the deviation. `ARCHITECTURE.md` remains the authoritative spec;
addenda exist so anyone reading it sees the deviation and its reasoning in
one place. This applies whether or not an AI_DOC is also written.

### Referencing docs from code

User-facing text — POD, command `description` / `summary` / help output,
`die` / `warn` / `croak` / `print` strings, any diagnostic a user might see —
must **never** reference any `.md` document. If the rule matters to the user,
restate it in plain prose; if it does not, drop the reference. Users cannot
read internal documentation and should not be pointed at it.

Regular `#` comments may reference `ARCHITECTURE.md` or a style guide (both
tracked, both authoritative). References to `AI_DOCS/*` or other Markdown
are **discouraged** and should appear only when the comment cannot stand on
its own without one. A reference must be specific: full path plus a section
identifier. A bare token like `D6` or `M2 step 4+5` is not acceptable.

---

## Commits

- **Make a distinct commit for each change.**
- **Exception:** if fixing a bug introduced by a recent commit that has not
  yet been pushed to origin, amend that commit instead of creating a new one.
- Commit messages are fully self-explanatory. **No references to plan
  documents, review documents, or finding numbers.** Never `#` followed by
  digits — GitHub reads it as an issue link.
- No emojis in commit messages.
- **Never push, never merge, never delete user-visible state** without the
  user asking.

---

## Changelog

- Every commit that changes shipped behavior records itself in `Changes` in
  the **same commit**, as a bullet under the `{{$NEXT}}` section at the top,
  describing the change in user-facing terms. Do not defer changelog entries
  to release time — releases have shipped with empty changelogs because
  entries were never written.
- Keep each entry brief: one line, one sentence where possible, two at most.
- This applies to **all** such commits, whether they land directly on the
  main branch or on a worktree branch merged in later. When you open a
  worktree, the work's `Changes` entry lands in that branch alongside the
  code; the merge commit carries it onto the main branch.
- `Changes` is a `Text::Template` document — **never put a literal `{{` or
  `}}` inside a bullet.**
- **Exempt:** changes that ship nothing to users — pure test-only work,
  trivial cleanups (whitespace, typos, formatting), and dev-only tooling
  (`agent_scripts/`, reference trees, `AI_DOCS/`). Everything else needs an
  entry.

---

## Worktrees

- **Significant work requires a worktree.** Place worktrees in `worktrees/`
  (gitignored).
- **Documentation-only work does not require a worktree.**
- **Always integrate a worktree's branch with a merge commit**
  (`git merge --no-ff`), never a fast-forward. The merge commit is the record
  that a discrete piece of work landed; preserve it even when the target
  branch has not advanced.
- A project may suspend the worktree rule during a foundations phase. If so,
  its own `AGENTS.md` says which branch to commit to directly.

---

## Agent scripts

Anything an agent (human- or AI-driven) needs as standalone tooling —
auditors, finders, stage verification helpers — lives in `agent_scripts/` in
the project. Throwaway scripts to verify in-progress functionality are fine
there too. These are **not** part of the shipped distribution: exclude
`agent_scripts/` in `dist.ini`.

Cross-project auditors live in `~/projects/Agents/agent_scripts/` and are
copied or symlinked into a project's `agent_scripts/`. Keep the copies in
sync; fix the canonical one first.

---

## Distribution setup

Every project uses Dist::Zilla with the layout in `DZIL_GUIDE.md`. Audit an
existing project with:

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

Never hand-edit `Makefile.PL`, `README`, `README.md`, `cpanfile`, `LICENSE`,
or `MANIFEST` — Dist::Zilla generates them and copies them back into the
tree. Edit `dist.ini` and the main module's POD instead.

---

## AI / LLM contribution policy

Projects ship `AI_AND_LLM_POLICY.txt` at their root (canonical copy in this
repository). The short version, which agents must honor:

- Work lands in **digestible chunks** a human can actually review.
- Generated code is **human-vetted** before merge.
- **No 'vibe' coding** in final product — a human understands the change end
  to end.
- Significant AI/LLM-authored code is **noted as such** in the commit or
  author metadata.
