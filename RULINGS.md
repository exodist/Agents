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

## 2026-10-23 — IPX is opted into from a project's `AGENTS.md`

**Ruling: `IPX.md` is optional, adopted by a line in a project's `AGENTS.md`
as `DATABASES.md` is. Departures from its recommendations go in
`AGENTS_OVERRIDE.md`. There is no declaration section, no wiring-audit check,
and no `SYNC.md` entry. Agents read it before adding a module, moving logic
between modules, or writing a requested plan; in an adopting project, code
review checks new and moved modules against it.**

A mandatory or audited declaration was rejected for the reason the repository
location is optional: most projects will not adopt IPX, and a required entry
would flag every one of them.

## 2026-10-23 — IPX: where Process modules live

**Ruling: recommended layout, which projects may vary. A small process used by
one Interface class lives under it (`Foo::Thing::Proc`), with roles only it
uses under the process (`Foo::Thing::Proc::SomeRole`). A process shared by
several classes, or meant for public use, lives under `Foo::Process::`, again
with its own roles beneath it. Shared roles keep the project's usual role
location. Process modules rarely sit directly under the main namespace, so
they are not mistaken for Interface objects. A process both private to one
class and public goes under `Foo::Process::`.**

Flat naming by task was proposed and rejected: telling process modules from
Interface objects at a glance was judged worth the longer names. The
DBIx-QuickORM MVP's ad-hoc layout prompted this, and the owner intends to
bring it up to this standard.

## 2026-10-23 — `confess` over `@CARP_NOT`; validate where it adds value

**Ruling: the Perl style guide's error rules gain a third case. `die` for
errors in this code; `croak` when the immediate caller used it wrong;
`confess` when the misuse happened further up, with stack levels between the
mistake and the check. Managing `@CARP_NOT` to aim `croak` is strongly
discouraged, not banned. The same section states when to validate arguments:
where a wrong value would produce a wrong result rather than an error, or
where the error would surface far from the mistake. Input that simply dies
when wrong — a missing method, say — needs no check. IPX refers to this rather
than restating it.**

A full trace always contains the frame that erred; `@CARP_NOT` guesses which
frame to blame, skips the rest, and confuses when it guesses wrong. The
DBIx-QuickORM MVP's `@CARP_NOT` use prompted the change, and the owner intends
to remove it there. It is not banned outright because a good use may exist,
though none is known.

Revisit if: a concrete case appears where `confess` output is worse than an
aimed `croak`.

## 2026-10-23 — IPX: Process modules use Interface objects through methods

**Ruling: a Process module never reads or writes an Interface object's slots;
the Interface object provides the accessors and mutators the process needs.
Distribution-internal `_methods` may be called across classes in the same
distribution — except where a process or its component roles are meant for
third-party use, where every method a role requires is public. A role
describes a Process module's inputs only when unrelated types can stand in;
one class and its subclasses need none. Loading runs one way: an Interface
module that delegates loads the Process module; the Process module takes
instances through `new`. A Process module may also be a public, documented
entry point in its own right, with no Interface method calling it.**

Requiring public methods for all in-distribution collaboration was rejected:
each would become a compatibility promise. The third-party exception exists so
an extension never has to define an underscore method to fit.

**Ruling: IPX recommends two Process forms as guides, not rules — depart
where a case does not fit. A task takes its inputs at construction, keeps
scratch state in its own slots, exposes one domain-verb entry method, and is
discarded. An accumulator takes optional seed values, is fed through
`add`-style methods, and its result method never consumes state, so more
values can be added and the result read again. An Interface object may be an
immutable value whose refining methods return copies; building one by
refinement is not Process aggregation.**

A hard contract was rejected so exceptions are not fought. `Digest::SHA`,
whose result methods reset the object, is the accumulator counterexample. The
value-object case was settled against `DBIx::QuickORM::Handle`: every
refinement is a query the caller can use, while an accumulator's intermediate
state is meaningful only to the process. A separate builder Process for such
objects was rejected as splitting the main interface for no gain over
immutability.

## 2026-10-23 — IPX: when work becomes a Process module

**Ruling: a method on the Interface object is the default. Work becomes a
Process module when either holds: (1) it spans several subs sharing
significant process-specific state — state that would otherwise sit in scratch
slots on the Interface object or be threaded through every helper; or (2) it
mutates objects in more than one ownership tree. A tree is an object and what
it contains, at any depth; a reference such as a foreign key does not make a
parent, and a link row belongs to the side that owns the relationship's API.**

Size and replaceability were proposed as triggers and rejected: a long
stateless algorithm splits into private methods or Utility functions, and
replaceability is speculative. Rule 2 follows the domain-driven-design
aggregate boundary — a cross-tree mutation has no natural owner. It will
produce some very small Process modules; that is accepted over picking an
arbitrary owner.

Revisit if: rule 2 produces Process modules reviewers consistently judge
pointless, or the ownership-tree test proves ambiguous in practice.

## 2026-10-23 — IPX: Interface and Process, with X left undefined

**Ruling: the optional methodology is named IPX — Interface and Process, then
X for whatever a project builds on top. It covers Utility, Interface,
Utiliface, and Process modules only. Presentation layers — CLI, web, TUI —
are the X; their structure is out of scope.**

"Interface/Process" with no acronym was weighed and rejected. Collision with
Novell's IPX protocol was judged irrelevant: the protocol is obsolete, and the
term is used only inside these agent documents.

The first draft named UX as a third, optional focus without defining it. No
adopting project needed one, and web projects already bring a framework with
its own structure. A reserved empty section was rejected because agents fill
gaps with invented rules; adding a defined layer later is cheap, withdrawing
one projects built against is not.

Revisit if: several adopting projects grow presentation layers with a shared
shape worth codifying.

## 2026-09-23 — Every test run is memory-capped by default

**Ruling: `agent-test-lock` runs every command in a systemd user scope with
`MemoryMax=75%` and swap off. Projects override with `--memory-max` or
`--no-memory-cap` in their test instructions; database suites get the same
default. Without user systemd the run proceeds uncapped with a warning.
Agents cap other memory-heavy commands the same way.**

This replaces the earlier guidance against "an arbitrary memory cap". The
shared lock stops suites stacking, but every OOM kill on the primary machine
between April and August 2026 was a single runaway process (80–118 GiB), which
the lock does not prevent; one of them coincided with filesystem checksum
errors. 75% was chosen over 50% for suite headroom. Database suites were not
exempted because they are the heaviest runs; their tmpfs usage is handled by a
measured per-project cap instead.

Revisit if: capped runs routinely hit the cap for legitimate suites, or agents
run mostly where user systemd is unavailable and the cap silently never
applies.

## 2026-08-15 — Sync-worthy changes are found by path, plus a ledger

**Ruling: a project detects pending syncs with one `git log` over the
artifacts it copies — `AI_AND_LLM_POLICY.md`, `templates/`, `agent_scripts/`
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
