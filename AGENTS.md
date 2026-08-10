# AGENTS.md

Optional shared agent instructions for Chad Granum's ("Exodist") projects.
A repository inherits these rules only when its own instructions point here.
No project is required to adopt this repository.

Every document in the consuming project takes priority over shared guidance
here. `AGENTS_OVERRIDE.md` is a convenient place to collect declarations and
exceptions, but it is not what grants local documents their authority.

You are an expert Perl developer. Write code following the patterns and
style of "Exodist" as seen throughout these codebases and codified in
`PERL_STYLE_GUIDE.md`. Written material follows `DOCUMENTATION.md`.

## What to read

Start with `CODEX.md` and/or `AGENTS.md` in the project, according to the
entry points available to the agent harness. Follow the critical references
those files name for the task at hand. **Do not enumerate and read every
Markdown file in the repository.** Plans, reviews, historical notes, and
unrelated procedures are not implicit instructions.

For a project that opts into this repository:

1. Read the project's complete entry document.
2. Read this file for shared workflow and safety rules.
3. Read only the shared documents this file names for the work being done:
   `DOCUMENTATION.md` before writing or editing documentation in any form,
   the Perl guide for Perl edits, `TESTING.md` before test work,
   `CODE_REVIEW.md` before announcing a completed change,
   `DZIL_GUIDE.md` before packaging work, `DATABASES.md` only when a database
   project's entry documents opt into it, and the matching procedure under
   `skills/` before carrying it out.
4. Read the project documents its entry point names, including its
   `ARCHITECTURE.md`, test instructions, and declarations.

The shared documents cover separate domains rather than outranking one
another. If the checklist differs from the Perl style guide or documentation
guide, fix the checklist. If any shared rule differs from a project-local
document, follow the project. A project's `ARCHITECTURE.md` is authoritative
for its design even when it began as a copy of a shared template and even
when no `AGENTS_OVERRIDE.md` mentions the change.

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

### Code auditors — pre-review gates when applicable

Projects keep copies in their own `agent_scripts/`. When a project lacks one,
run the canonical copy from `~/projects/Agents/agent_scripts/`.

| Auditor | Catches |
|---|---|
| `audit-methods-not-functions` | Subs defined in an object module called as bare functions. |
| `audit-readonly-attrs` | Read-only HashBase slots using `-attr` instead of `<attr`. |
| `audit-banned-words` | Forbidden terminology. |
| `audit-test-layout` | The category-and-origin test layout, when selected. |
| `find-long-subs` | Subs over 75 lines. |
| `find-large-modules` | Modules over 10,000 lines. |

Packaging and adoption checks are advisory and run only when the task calls
for them:

| Auditor | Catches |
|---|---|
| `audit-dzil` | `dist.ini` against the optional `DZIL_GUIDE.md` profile. |
| `audit-project-wiring` | Optional Agents integration and declarations. |

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
| `~/projects/Agents/CPAN_TESTERS.md` | Querying or analyzing CPAN Testers reports. |

*(These files are also valid Claude Code / Codex skills.
`~/projects/Agents/install` optionally links them into the per-user discovery
paths `~/.claude/skills` and `~/.agents/skills`. Codex can then select them
implicitly or through `/skills` and `$skill-name`. That is a convenience only
— the procedures are authoritative as files, and everything works without
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

## Engineering judgment: value against cost

Act as an experienced developer, not merely a capable implementer. Weigh the
concrete value of code against its implementation cost, complexity, testing
surface, compatibility burden, and ongoing maintenance. Every new component,
abstraction, option, special case, and platform accommodation must justify its
existence through useful behavior.

Before adding or expanding code, ask:

- Is this actually useful for a requested or documented use case?
- Is this edge case likely and important enough to justify its cost?
- Are we assuming how users will use the code, or assuming they all have the
  same problem, without evidence?
- Are we locking the design to speculative use cases instead of leaving room
  for real uses to emerge?
- Is the benefit worth the implementation and long-term maintenance burden?
- Has the work grown complicated enough that a smaller design, pruning the
  feature, or leaving a narrow case unsupported may be better?

Treat support as a long-lived compatibility commitment. When there is no
known use case or an edge case is unlikely, lean toward the smallest honest
contract: document it as unsupported and/or fail with a clear exception
instead of adding speculative logic. Support can usually be added later
without breaking existing callers once a real need appears. Removing poorly
designed support after callers depend on it is much harder, and can leave a
permanent testing and maintenance burden. Additional support must justify its
full lifetime cost, not only the cost of its initial implementation.

A requested implementation plan must apply this test before treating added
machinery or edge-case support as planned work. For any questionable addition,
state the evidence and expected frequency, concrete benefit and affected
users, implementation and testing cost, ongoing maintenance and compatibility
burden, and reversibility. When the need is unproven or unlikely, plan the
smallest honest contract—documentation and/or a clear exception—by default.
Do not postpone this judgment until implementation or code review.

`OVERENGINEERING_EXAMPLES.md` is a calibration set of prior owner rulings for
these judgments. It is not routine context and does not need to be loaded for
ordinary implementation work. Read it completely before writing a requested
implementation plan, and when the decision-discussion or code-review
procedures require it; otherwise leave it out of context until it is needed.

Do not build speculative flexibility either. Avoiding assumptions means
keeping the design nimble and open to real extension, not adding hooks,
configuration, or abstraction for imagined futures. Intentionally optimizing
a common use case or making it safer is fine when that goal is explicit.

These are owner decisions. When the value is uncertain, an edge case or
platform causes disproportionate complexity, or implementation begins to
balloon, **stop and flag it before publishing the result**. Give the owner the
known benefit, the assumptions involved, the complexity and maintenance cost,
and the simpler alternatives—including pruning or declaring a narrow case
unsupported. Recommend a direction, but do not silently choose the product or
support tradeoff.

---

## Decision discussion mode

When one or more owner decisions are needed, stop implementation and read
`skills/decision-discussion/SKILL.md` completely. That file is the
authoritative discussion procedure: it governs counting, one-item pacing,
context, recommendations, and recording each ruling before continuing.

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

Before announcing work ready for review, read and follow
`skills/perl-pre-review/SKILL.md` completely. It is the authoritative ordered
procedure for establishing the full touched set, running automated gates,
walking `STYLE_GUIDE_AGENT_CHECKLIST.md`, checking POD and reuse, rerunning
tests, and reporting results. A gate hit is a hard stop.

---

## Independent code review

After the applicable pre-review checks pass, follow
[`CODE_REVIEW.md`](CODE_REVIEW.md) before announcing any change complete. It
defines the required fresh-context sub-agent review, the review-and-fix loop
with one fix commit per cycle and a narrowing scope, and handoff of deferred
decisions, minor findings, and pre-existing problems.

---

## Testing

`TESTING.md` is the authoritative policy. Before running or diagnosing a
suite, read it and `skills/perl-test-run/SKILL.md`; the skill is the ordered
execution procedure. Project-local test instructions take priority and may
add commands or tighter limits.

---

## Documentation

Read `DOCUMENTATION.md` before writing or editing commit messages, `Changes`
entries, comments, POD, human-facing text, or AI/agent documents. It defines
the shared rules for brevity, duplication, audience, references, and useful
roads-not-taken context.

---

## Commits

- **Make a distinct commit for each change.**
- **Exception:** if fixing a bug introduced by a recent commit that has not
  yet been pushed to origin, amend that commit instead of creating a new one.
  This exception does not apply while a review-and-fix loop is running; each
  cycle's fixes land as a new commit per [`CODE_REVIEW.md`](CODE_REVIEW.md).
- Commit-message content follows `DOCUMENTATION.md` under "Commit messages".
- **Never push, never merge, never delete user-visible state** without the
  user asking.

---

## Changelog

- Every commit that changes shipped behavior records itself in `Changes` in
  the **same commit**, as a bullet under the `{{$NEXT}}` section at the top.
  Do not defer changelog entries to release time — releases have shipped with
  empty changelogs because entries were never written.
- Entry content and formatting follow `DOCUMENTATION.md` under "`Changes`
  entries".
- Keep each entry to one brief bullet on one physical line and one short
  sentence. A second sentence is reserved for essential compatibility or
  migration information.
- This applies to **all** such commits, whether they land directly on the
  main branch or on a worktree branch merged in later. When you open a
  worktree, the work's `Changes` entry lands in that branch alongside the
  code; integrating the branch carries it onto the main branch.
- **Exempt:** changes that ship nothing to users — pure test-only work,
  trivial cleanups (whitespace, typos, formatting), and dev-only tooling
  (`agent_scripts/`, reference trees, `AI_DOCS/`). Everything else needs an
  entry.

---

## Worktrees

- **Complicated work requires a worktree.** This includes multi-step features,
  architectural changes, broad refactors, risky changes, and work expected to
  need several commits. Place each worktree under the project repository root
  as `<project-root>/worktrees/<worktree-name>`; the root `worktrees/`
  directory is gitignored.
- Simple bug fixes, minor changes, and small documentation edits may be made
  directly on the primary branch (`master`, or the project's declared
  equivalent).
- Count the commits a worktree branch adds relative to its target branch. A
  branch adding **two or more commits** must be integrated with a merge commit
  (`git merge --no-ff`) so the discrete body of work remains visible.
- A worktree branch adding **one commit** may be fast-forwarded when the target
  permits it. Do not manufacture a merge commit solely to wrap one commit.
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

When a project uses Dist::Zilla and elects to follow the shared packaging
guidance, audit it with:

```
perl ~/projects/Agents/agent_scripts/audit-dzil /path/to/project
```

Never hand-edit `Makefile.PL`, `README`, `README.md`, `cpanfile`, or `LICENSE`
— Dist::Zilla generates them and copies them back into the tree. `MANIFEST`
is generated only in the build tree. Edit `dist.ini` and the main module's
POD instead.

---

## AI / LLM contribution policy

Projects ship `AI_AND_LLM_POLICY.txt` at their root (canonical copy in this
repository). An adopting project keeps exactly one AI/LLM policy document in
the repository and distribution, under that filename. Keep it byte-for-byte
current with the canonical copy unless `AGENTS_OVERRIDE.md` explicitly
declares a different policy; a local policy replaces the canonical text rather
than adding a second policy document.

The short version, which agents must honor:

- Work lands in **digestible chunks** a human can actually review.
- Generated code is **human-vetted** before merge.
- **No 'vibe' coding** in final product — a human understands the change end
  to end.
- Significant AI/LLM-authored code is **noted as such** in the commit or
  author metadata.
