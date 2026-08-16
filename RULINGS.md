# RULINGS.md

Decisions this repository's owner has already made. A recorded ruling stands
until the owner changes it.

Read this file when a decision is in front of you, not for general context.
When new evidence — a bug report, a pull request, a user request, a changed
constraint — suggests a ruling needs revisiting, flag it for the owner rather
than acting against it. See `AGENTS.md` under "Rulings".

Newest first. Each entry gives the date, what was ruled, and enough evidence
for the next reader to judge whether the situation has changed.

---

## 2026-08-15 — Sync-worthy changes are found by path, plus a ledger

**Ruling: a project detects pending syncs with one `git log` over the
artifacts it copies — `AI_AND_LLM_POLICY.txt`, `templates/`, `agent_scripts/`
— and over `SYNC.md`, this repository's ledger of changes that require action
in an adopting project. A change requiring project action writes its `SYNC.md`
entry in the same commit.**

Projects reference these rules rather than copying them, so most commits here
need no project action at all; reporting every commit would bury the few that
matter. The path filter alone catches copied artifacts but misses a rule
change that requires a new ruling or a new project practice — hence the
ledger. A commit trailer was considered and rejected: a forgotten trailer is
invisible and cannot be fixed after the fact, while a missing ledger entry can
be added in a later commit and every project that has not yet synced past it
still sees it. A ledger entry also carries the instructions to show the user;
a subject line does not.

Revisit if: the ledger goes unwritten often enough that projects miss required
actions, or the path filter starts reporting mostly noise.

## 2026-08-15 — The synced commit is recorded in the bootstrap stanza

**Ruling: an adopting project records `- Last synced: <sha> (<date>)` in the
bootstrap stanza of its `AGENTS.md`, and `audit-project-wiring` reports a
missing or unparseable line.**

The stanza is the block an agent reads before anything else and already names
the repository and its location, so sync state belongs beside them and needs
no extra file read to resolve. It is the one line of otherwise verbatim
boilerplate that changes per project and per sync. The advisory finding is
deliberate: every project adopted before this rule lacks the line, and that is
accurate rather than noisy.

Revisit if: keeping a machine-updated line inside a hand-written file causes
merge friction, in which case the ledger in `AGENTS_OVERRIDE.md` is the
alternative that was weighed.

## 2026-08-15 — No named location for a project-local checkout

**Ruling: shared guidance does not name a path for a checkout kept inside a
project. The sandbox picks one and records it in `AGENTS_OVERRIDE.md`; the
only requirement is that the chosen path is ignored by git and excluded from
the distribution.**

A single recommended dot-prefixed path was considered and rejected. A named
path settles the ignore line and the packaging exclusion once, but every
sandbox that cannot use it goes back to choosing anyway, and the shared
requirement — ignore it, do not ship it — covers the real risk without
standardizing something no two sandboxes need to agree on.

Revisit if: project-local checkouts become common enough that the same path is
being re-derived, or one is found committed or shipped in a tarball.

## 2026-08-15 — The repository location is an optional declaration

**Ruling: a project pins a non-default Agents location in an optional
`## Agents repository location` section of `AGENTS_OVERRIDE.md`. It is not a
sixth mandatory declaration, and its absence means the default location.**

The five mandatory declarations exist because there is no right answer for all
projects. The location does have one: `~/projects/Agents` is correct for
nearly every project, and a mandatory sixth entry would fail
`audit-project-wiring` in every project already adopted, to answer a question
with a good default.

Revisit if: enough projects keep the checkout elsewhere that the default stops
being the common case.

## 2026-08-15 — Shared documents keep writing the literal default path

**Ruling: `~/projects/Agents/...` stays written out in every shared document.
A project that keeps its checkout elsewhere is covered by one substitution
rule, stated in the bootstrap stanza and in `AGENTS.md`.**

Roughly forty references across the shared guides, skills, and templates name
the repository by absolute path so that tools and procedures work from any
project with nothing installed. Replacing them with a placeholder token was
considered and rejected: it would cost every runnable command its
copy-and-paste property and change the testing command in every consuming
project's `AGENTS.md`, to serve checkouts that are not at the default
location.

Revisit if: non-default locations become the common case rather than the
sandbox exception, or agents are observed following a literal path after a
project declared a different one.
