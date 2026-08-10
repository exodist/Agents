# STYLE_GUIDE_AGENT_CHECKLIST.md

Self-audit checklist. Walk it against **every file the branch touched**
before declaring work ready for review. This is the operational form of
`PERL_STYLE_GUIDE.md` and `DOCUMENTATION.md`; where they disagree, the
authoritative guide wins and this file gets fixed.

Sources this mirrors:

- **`PERL_STYLE_GUIDE.md`** — style, formatting, language-feature rules.
- **`DOCUMENTATION.md`** — comments, POD content, human-facing text, commit
  messages, and `Changes` entries.
- **`AGENTS.md`** — workflow, pre-review checks, conventions.
- **`TESTING.md`** — test layout, provenance, execution policy.
- The project's `AGENTS_OVERRIDE.md` — declarations and overrides, which win.
- The project's `ARCHITECTURE.md` / `AGENTS.md` — project context and design.

Five items are **[project-declared]**: minimum Perl and signature policy
(§5a), perltidy (§7), test layout (§9), and POD placement (§16). Read the
project's `AGENTS_OVERRIDE.md` for its declarations before auditing those.
An unanswered declaration is itself a finding.

---

## 0. Before you start

- [ ] Read the project's `AGENTS.md`, `AGENTS_OVERRIDE.md`, and
      `ARCHITECTURE.md` this session.
- [ ] Established the complete touched set through
      `skills/perl-pre-review/SKILL.md`, including branch commits, index,
      working tree, and untracked files.
- [ ] No emojis in code, and all written material satisfies the no-emoji rule
      in `DOCUMENTATION.md`.
- [ ] Reviewed the change under `AGENTS.md` "Engineering judgment: value
      against cost"; speculative scope was not added, and questionable
      cost/benefit or maintenance tradeoffs were raised for the owner.

## 0a. Automated gates (hard stops, not judgment calls)

- [ ] `perl agent_scripts/audit-methods-not-functions lib` — every hit is a
      sub the module defines being **called** as a bare function instead of
      through an invocant. Fix the call site.
- [ ] `perl agent_scripts/audit-readonly-attrs lib` — every hit is a
      read-only `Object::HashBase` attribute declared with `-` instead of
      `<` (a dead throwing setter). Convert to `<`, or add a `-attr-ok`
      comment if the throwing setter is genuinely intended.
- [ ] `perl agent_scripts/audit-banned-words` — every hit is a forbidden
      term (§14a).
- [ ] `perl agent_scripts/find-long-subs lib` — resolve subs over 75 lines
      (excluding comments/POD).
- [ ] `perl agent_scripts/find-large-modules lib` — resolve modules over
      10,000 lines (excluding POD).
- [ ] `perltidy -b` with the repository `.perltidyrc` on every touched Perl
      file (`.pm`, `.pl`, `.t`, executable scripts).
- [ ] `perlcritic` with the repository `.perlcriticrc`, **if the project has
      one**.
- [ ] `podchecker` on every touched `.pm`. Zero errors, zero warnings.
- [ ] No trailing whitespace in branch commits, the index, or the working
      tree, using all three diff checks from the pre-review procedure.

These audits scan the whole tree, not a touched-file subset, so a partial
edit set cannot hide a hit.

---

## 1. Object orientation

- [ ] Uses `Object::HashBase` for object attributes (not Moose, Moo,
      Class::Accessor, or hand-rolled accessors).
- [ ] Uses `Role::Tiny` / `Role::Tiny::With` for roles (not `Moo::Role`,
      `Moose::Role`).
- [ ] Uses `parent` for inheritance, never `base`.
- [ ] Does not work around an imagined `Object::HashBase` + `Role::Tiny`
      incompatibility — they compose; use them together as needed.
- [ ] `Object::HashBase` slot ordering is intentional — additions go at the
      end unless the existing order has a documented reason.
- [ ] Read-only attributes use `<attr`, not `-attr`. Grep the touched files'
      HashBase blocks for a line matching `^\s*-` and convert each, unless a
      `-attr-ok` comment explains why the throwing setter is needed.

## 2. Naming and structure — helpers are called as methods

- [ ] No sub **defined in an object module** is **called** as a bare
      function from inside that module. Every such call goes through an
      invocant: `$self->helper(...)` / `$class->helper(...)`.
- [ ] No sub gained a `my $self = shift;` it does not use. Empty and no-op
      methods (`sub cache { }`, `sub uncache { return }`) stay empty — the
      rule is about the call site, not the declaration.
- [ ] Argless declarative-metadata methods (`sub TABLE { 'users' }`) left
      as-is.
- [ ] Imported functions (`croak`, `blessed`, `first`, …) still called as
      functions — the rule covers only subs the file itself defines.
- [ ] Perl specials (`BEGIN`, `DESTROY`, `import`, `AUTOLOAD`, …) untouched.
- [ ] One Perl namespace per file. `package Foo::Bar::Baz;` lives in
      `lib/Foo/Bar/Baz.pm`, not inline in `lib/Foo/Bar.pm`.
- [ ] Subs grouped exports → public → private; 1-line subs near the top of
      their group; folds used for coherent feature groups. No reordering
      across groups to hoist a 1-liner.

## 3. Error handling

- [ ] `croak` where the caller is at fault (bad arguments, missing required
      parameters, caller-supplied data that turns out invalid).
- [ ] `die` where the failure is internal (a file the code itself created,
      a violated invariant the caller could not control, a re-throw).
- [ ] No exception is silently suppressed. Every caught error is rethrown or
      warned — except `viable()`-style feature detection and optional module
      loading where failure is expected.
- [ ] Every `eval` decides success by its **return value**
      (`my $ok = eval { ...; 1 };`), never by the truthiness of `$@`.
- [ ] Multi-line `eval` blocks are never inside the parens of a conditional
      — three-step form (`$ok`, `$err`, `if`) instead.
- [ ] Where `$@` is used inside a conditional block after any other
      statement, it was saved to a lexical on the block's first statement.
- [ ] `fork` handled inline: `my $pid = fork // die "reason: $!"`. Never a
      separate conditional. Fork failure is `die`, never `croak`.
- [ ] No error *value* is tested for truthiness (exception objects may
      overload boolean to false).

## 3a. Filehandles

- [ ] No redundant `close($fh)` immediately before the enclosing scope ends —
      a lexical handle closes itself.
- [ ] Where a `close` is present, it earns its place: a long-lived scope, a
      checked result (`close($fh) or die ...`), `$?` from a pipe, required
      ordering, or freeing the descriptor for reuse.
- [ ] Any handle whose written data must actually land has a **checked**
      close, not a bare one — `close` is where a failed flush surfaces.

## 4. Conditionals

- [ ] Single-statement conditionals use postfix form (`do_thing() if $cond`).
- [ ] No multi-line conditional expression inside `if`/`unless`/`while`/
      `until` parens — step-accumulated boolean or an extracted predicate
      helper instead.

## 5. Language-feature defaults

- [ ] `//=` used for defaults where the intent is "if undef".
- [ ] "Is module installed" gating uses a constant
      (`use constant HAVE_FOO => eval { require Foo; 1 };`), not a package
      variable.
- [ ] `push` uses `=>` before the values: `push @items => $thing`.

## 5a. Minimum Perl and signatures **[project-declared]**

Check both declarations first. A missing declaration is itself a finding;
preserve existing compatibility and do not introduce signatures while it is
unresolved.

- [ ] The declared minimum is exact (or explicitly absent) and agrees with
      `dist.ini` and shipped module version pragmas.
- [ ] The signature policy is explicitly disabled or required where the
      declared feature set can express the call shape.
- [ ] Under a disabled policy, no signatures were introduced and `@_`
      handling matches the surrounding code.
- [ ] Under a required policy, every named sub / method / anonymous sub uses
      a signature unless its argument shape genuinely cannot be expressed.
      Methods declare `$self` / `$class` first.
- [ ] Default-value form matches intent: `$x = $default` (missing only),
      `$x //= $default` (missing or undef), `$x ||= $default` (missing or
      falsy — used sparingly, never where `0` / `""` must survive).
- [ ] `@_` only for genuine cases: re-dispatch (`goto &other`,
      `$other->(@_)`), shapes signatures cannot describe, or subs that peek
      at `wantarray` / `caller` before forwarding.

## 6. Sub-second sleeps

- [ ] Every sub-second sleep is `Time::HiRes::sleep($secs)`.
- [ ] No 4-arg `select(undef, undef, undef, $secs)` as a sleep primitive;
      any encountered was replaced.
- [ ] No `tinysleep`-style helper reintroduced.

## 7. Whitespace and formatting **[project-declared perltidy config]**

- [ ] No trailing whitespace.
- [ ] No emojis.
- [ ] perltidy run on every touched Perl file with the repository
      `.perltidyrc` (a copy of `~/projects/Agents/templates/perltidyrc`
      unless `AGENTS_OVERRIDE.md` declares a project-local one).
- [ ] No file was reformatted that the change did not otherwise touch.

## 8. Testing libraries

- [ ] New tests use `Test2::V0`, not `Test::More` / `Test::Simple`.
- [ ] Existing `Test::More` files may stay until touched substantively; once
      touched, migrated to `Test2::V0`.

## 9. Test layout and provenance **[project-declared]**

Under the default scheme:

- [ ] Test sits in the right category directory (`unit` / `acceptance` /
      `regression` / `integration`) by *why it exists*, using the documented
      precedence.
- [ ] Unit tests mirror the implementation path (exact or suffixed).
- [ ] Fixtures live in `<test>.fixtures/` beside the test, or `t/fixtures/`
      when shared.
- [ ] Every `.t` has an origin header (`human` / `AI` / `mixed`) as its
      first substantive line; AI sections of 15+ lines inside a mixed file
      are marked at their boundary.
- [ ] No test was split merely to disguise its runtime.

Under a `t/AI/` project:

- [ ] AI-generated tests live under `t/AI/` mirroring `t/`'s subdirectory
      layout.

## 10. Test execution

- [ ] Completed the project command through the procedure in
      `skills/perl-test-run/SKILL.md`.
- [ ] The run used the author-test state, timeout, lock, timing flag, and local
      library path required by `TESTING.md` and the project's instructions.
- [ ] Ran the release-path check when module-loading behavior was touched.
- [ ] Investigated overruns and cleaned project-specific child processes or
      debris through their documented procedure.

## 11. Database projects

Skip this section unless the project's entry documents opt into
`DATABASES.md`.

- [ ] Backend and dependency choices follow the project's architecture and
      packaging documents, not assumptions from another repository.
- [ ] Developer-only installation paths do not leak into shipped code.
- [ ] Per-install test children establish their environment before loading
      drivers or helpers that may cache it.

## 12. UUIDs

- [ ] UUID generation happens in Perl, not in SQL.
- [ ] v7 UUIDs are not bit-reordered for "index locality" — v7 is already
      time-ordered.

## 13. Module and subroutine size

- [ ] No `.pm` exceeds **10,000 lines of code** (blank lines and comments
      count; POD does not — POD = anything between `=pod`/`=head*` and
      `=cut`, plus everything after `__END__`).
- [ ] If a file crossed the limit, it was **flagged for human review**, not
      silently split, and not gamed via long POD or `do`/`require` tricks.
- [ ] No subroutine exceeds **75 lines** (signature through closing brace).
      Comments and POD inside the sub do not count.
- [ ] Where the narrow exception was invoked (packed-binary encoders, bit
      twiddling, table-driven dispatch of one-liners), a short comment says
      why splitting would do more harm than good.

## 14. Comments

- [ ] Every touched comment satisfies `DOCUMENTATION.md` under "Comments",
      including necessity, brevity, content, and reference rules.

## 14a. Terminology

- [ ] No `backstop` — `fallback` or `safeguard`.
- [ ] No `iff` — `if and only if`, or `only when` / `only if`.
- [ ] No `kwarg` / `kwargs` — `named argument` / `key/value argument`.
- [ ] No `load-bearing` — name the actual constraint.

## 15. POD content

- [ ] Every shipped `.pm` and all touched POD satisfy `DOCUMENTATION.md`
      under "POD".

## 16. POD placement **[project-declared]**

**Default (all POD at bottom):**

- [ ] All POD is under `__END__`, as one continuous document. No POD at the
      top of the file, none inline between subs.
- [ ] Section order matches `TEMPLATE.pod`: `NAME`, `DESCRIPTION`,
      `SYNOPSIS`, `ATTRIBUTES`, `EXPORTS`, `PUBLIC METHODS`,
      `PRIVATE METHODS`, `SOURCE`, `MAINTAINERS`, `AUTHORS`, `COPYRIGHT`.
- [ ] Method/export entries ordered to match code appearance.

**Split layout (project-declared):**

- [ ] `NAME` / `DESCRIPTION` / `SYNOPSIS` at the top of the file.
- [ ] `EXPORTS` / `PUBLIC METHODS` / `PRIVATE METHODS` inline, immediately
      above the sub each documents.
- [ ] `SOURCE` / `MAINTAINERS` / `AUTHORS` / `COPYRIGHT` under `__END__`.
- [ ] Sub order follows POD grouping (exports, then public, then private).

- [ ] Whichever layout applies, **every file in the project uses the same
      one** — the diff did not mix them.

## 17. Non-Markdown human-facing documentation and strings

- [ ] POD, help, diagnostics, and other human-facing text satisfy
      `DOCUMENTATION.md` under "Human-facing material outside Markdown".
- [ ] Every committed Markdown document points only to committed Markdown
      documents; anything landing together is included in the same commit.

## 18. Dependencies and distribution

- [ ] New dependencies follow the project's own packaging and architecture
      documents, including their classification and load behavior. The shared
      repository does not decide these for another project.
- [ ] When the project uses Dist::Zilla, its generated files were not
      hand-edited; the project's `dist.ini` and source POD were changed
      instead.
- [ ] When the project adopts the shared Dist::Zilla profile,
      `perl ~/projects/Agents/agent_scripts/audit-dzil .` passes or its
      advisory findings are explained.

## 19. Commits and changelog

- [ ] One distinct commit per change (or an amend to an unpushed commit that
      introduced the bug being fixed).
- [ ] Commit messages and `Changes` entries satisfy their sections in
      `DOCUMENTATION.md`.
- [ ] Every `Changes` entry is one physical-line bullet, no more than 35 words
      or 200 characters, and one short sentence; a second sentence appears
      only for essential compatibility or migration information.
- [ ] Every commit changing shipped behavior added its own bullet under
      `{{$NEXT}}` in `Changes`, **in that same commit**.
- [ ] Nothing was pushed or merged without the user asking.

## 19a. Worktrees

- [ ] Worktree use and integration satisfy `AGENTS.md` under "Worktrees":
      complicated work used one, two-or-more-commit branches retain a merge
      commit, and one-commit branches may fast-forward.

## 20. Reference trees — only if the project has one

Skip unless the project's `AGENTS.md` names a reference tree. Most do not.

- [ ] Nothing under it was modified in place. Borrowed code was copied out
      first.

---

## Handoff

- [ ] All three `AGENTS.md` pre-review passes ran:
  - Style-guide pass (this checklist).
  - POD pass (`podchecker` clean on every touched `.pm`).
  - Util/role/base-class reuse pass — re-scanned touched files for logic
    that already exists in the project's `*::Util*`, `*::Role::*`, or a
    relevant base class; switched to the existing helper where applicable;
    extracted shared logic where the same code appeared in three or more
    touched files.
- [ ] Test suite re-run after fixups; nothing regressed.
- [ ] Work announced as ready for review only after all of the above.
