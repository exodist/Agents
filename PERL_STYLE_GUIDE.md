# PERL_STYLE_GUIDE.md

Universal Perl style for Chad Granum's ("Exodist") projects. This is the
single source of truth for formatting, naming, and language-feature rules
across every repository that points at it.

Architecture and design rules belong in a project's own `ARCHITECTURE.md`.
Workflow rules belong in `AGENTS.md`. Test layout and execution policy
belong in `TESTING.md`. Documentation content belongs in `DOCUMENTATION.md`.
This file is Perl style and layout only.

A project may **override** a rule here, but only by recording the override
explicitly in its own `AGENTS_OVERRIDE.md`. Silent divergence is a bug. The
rules below marked **[project-declared]** have no universal answer and *must*
be pinned there per project.

This guide describes the target style for new code and for code you
substantively touch. Existing code predates parts of it; bring a file into
line when you have real reason to edit it, not as a mass retro-fix pass.

---

## Object orientation

- **`Object::HashBase` for object attributes.** Not Moose, not Moo, not
  Class::Accessor, not hand-rolled accessors.
- **`Role::Tiny` / `Role::Tiny::With` for roles.** Not `Moose::Role`, not
  `Moo::Role`.
- **`parent` for inheritance, never `base`.**
- `Object::HashBase` and `Role::Tiny` **compose**. `Object::HashBase` may be
  used inside a role, and may be used by a class that consumes a role built
  with it. There is no incompatibility — do not reach for a heavier
  framework to route around an imagined one.
- Slot ordering in the `Object::HashBase` attribute list is intentional.
  Additions go at the end unless a specific grouping is documented.
- **Read-only attributes use the `<attr` prefix, not `-attr`.** Both give a
  reader and no usable writer, but `-attr` generates a `set_attr` that
  exists only to throw "read-only" — a fake writer nobody is meant to call.
  `<attr` generates no setter at all. Internal writes via
  `$self->{+ATTR} = ...` work identically under both.

  Reach for `-attr` only when you specifically need the throwing `set_attr`
  to exist (e.g. to give a clearer error than "method not found" at a call
  site you cannot remove). Mark such a line with the literal token
  `-attr-ok` in a comment so the audit skips it deliberately.

  Audit: `agent_scripts/audit-readonly-attrs lib`

### Inlining HashBase

A distribution that wants **zero runtime dependencies** can carry its own
copy instead of depending on `Object::HashBase`:

```
perl ~/projects/Test2/Object-HashBase/scripts/hashbase_inc.pl Prefix::Namespace
```

That generates `lib/Prefix/Namespace/HashBase.pm` plus `t/HashBase.t`. Modules
then `use Prefix::Namespace::HashBase qw/...attrs.../` and behave identically.
Several distributions here do this.

The generated file is **regenerated, never hand-edited** — treat it the way
you treat `Makefile.PL`. Re-run the script to pick up an upstream fix, and say
so in the commit.

Only reach for this when the dependency genuinely matters (a bootstrap-level
module, or something meant to install with nothing else present). Otherwise
depend on `Object::HashBase` normally; one more copy to keep current is a real
cost.

---

## Naming and structure

### Helpers defined in an object module are called as methods

In a module that defines an object class, every named sub **that module
itself defines** is called through an invocant — `$self->helper($x)` or
`$class->helper($x)` — never as a bare function `helper($x)`.

**The rule is about the call site, not the sub declaration.** The reason:
a sub defined in a class is part of that class's interface. Calling it as a
plain function bypasses method dispatch, so a subclass or a consuming role
cannot override it; it also hides the call from stack traces and from
anyone grepping for the class's callers. Writing `$self->_helper(...)`
keeps the helper overridable and keeps it visibly owned by the class.

Because the call passes an invocant, such a helper naturally accepts one:

```perl
# Wrong — function call to a sub this module defines:
sub _flavor_from_dsn {
    my ($dsn) = @_;
    return undef unless $dsn && $dsn =~ /^dbi:([^:]+):/;
    return $FLAVOR_FROM_DSN_SCHEME{$1};
}
# ... called as: $self->{+FLAVOR} //= _flavor_from_dsn($self->{+DSN});

# Right — method call:
sub _flavor_from_dsn {
    my ($self, $dsn) = @_;
    return undef unless $dsn && $dsn =~ /^dbi:([^:]+):/;
    return $FLAVOR_FROM_DSN_SCHEME{$1};
}
# ... called as: $self->{+FLAVOR} //= $self->_flavor_from_dsn($self->{+DSN});
```

**What the rule does not mean.** It is not "every sub must shift an
invocant." A sub with no call site inside the module has nothing to fix.
In particular:

- **Empty and no-op methods stay empty.** `sub cache { }`,
  `sub uncache { return }` — a stub that does nothing and returns nothing
  behaves identically however it is called. Adding `my $self = shift;` to
  it is pure noise. Do not add one.
- **Argless declarative-metadata methods stay argless.**
  `sub TABLE { 'users' }`, `sub json_fields { qw{a b c} }` — callers invoke
  them as `$obj->TABLE`, which is already a method call.
- **Imported functions stay functions.** `croak(...)`, `first { ... } @list`,
  `blessed($x)` — those are another module's subs; the rule covers only subs
  the file itself defines.
- **Perl specials are exempt**: `BEGIN`, `END`, `INIT`, `CHECK`,
  `UNITCHECK`, `DESTROY`, `AUTOLOAD`, `CLONE`, `CLONE_SKIP`, `import`,
  `unimport`.
- **Anonymous subs and coderefs are exempt.** `my $cb = sub { ... }`,
  `\&_handler` passed as a callback, `sort { ... }` blocks.
- **Non-object modules are exempt.** A pure function library or exporter
  (`Foo::Util` with no `Object::HashBase` and no consumed role) calls its
  own functions as functions. That is what it is for.
- **`goto &_helper` is fine** — it re-dispatches `@_` unchanged, invocant
  included.

Audit: `agent_scripts/audit-methods-not-functions lib` — it scans **call
sites**, flagging bare calls to subs the file defines. It does not ask any
sub to grow an unused invocant.

### One namespace per file

A package `Foo::Bar::Baz` lives in `lib/Foo/Bar/Baz.pm`, not declared inline
inside `lib/Foo/Bar.pm`. Helper or inline namespaces that grow complex
enough to deserve their own package get their own file at the path
mirroring the package name.

The exception is throwaway lexical scaffolding — `package main;` blocks in
test scripts, anonymous-class patterns. Those are not "namespaces deserving
their own package." When in doubt: a `package` declaration containing any
`sub` definitions or attributes belongs in its own file.

### Sub ordering within a file

Subs group **exports first, then public methods, then private methods** —
the same grouping the POD documents. Ordering rules apply *within* a group,
not across groups.

Within a group, 1-line methods go near the top:

```perl
sub one_line { "1 line" }
```

Longer subs follow. When a set of subs is grouped because it implements one
role interface or one coherent feature, introduce a fold and put that
group's 1-liners at the top of the fold:

```perl
# {{{ This is where the doohickey is implemented

sub one_line { "1 line" }
sub default  { 1 }
sub is_smart { 1 }

sub longer_method {
    my $self = shift;
    ...
    return "That was long";
}

sub another {
    ...
}

# }}} This is where the doohickey is implemented
```

Do not reorder across groups to put a 1-liner first when that breaks the
grouping.

---

## Error handling

- Use `Carp qw/croak/` when the problem is in the caller; use `die` when the
  problem is in the current scope. Rule of thumb:
  - **`croak`** for interface misuse — bad arguments, missing required
    parameters, or operations on caller-provided data that turns out to be
    invalid (e.g. `do_thing_to(file => 'blah')` where the caller's path does
    not exist or is unreadable).
  - **`die`** for failures internal to the implementation — a temp file the
    code itself created cannot be written, an invariant the caller could not
    have controlled is violated, or an exception is being re-thrown.
  - Examples: `croak "Missing required parameter 'file'"` (caller's fault).
    `die "Failed to write temp file: $!"` (internal failure). A failed
    `open` on a path the caller passed in: `croak`. A failed `open` on a
    path the code constructed for its own use: `die`.
- **Never suppress or discard exceptions.** Always rethrow (`die $@`) or
  warn (`warn $@`). The only exceptions are `viable()`-style feature
  detection and optional module loading where failure is expected.
- **Always use the return value of `eval` to decide success, never the
  content of `$@`**: `my $ok = eval { ...; 1 };`

Accepted forms, in increasing order of complexity:

- Postfix, `$@` used immediately: `warn $@ unless eval { ...; 1 };`
- Block: `unless (eval { ...; 1 }) { warn $@; exit(1); }`
- Or-form: `eval { ...; 1 } or warn $@;` — acceptable when the eval block is
  a single statement *and* the `or`-clause is a single statement, so nothing
  can clobber `$@` in between. For longer blocks or multi-statement
  handlers, use the three-step form.
- Capture-in-block:
  `unless (eval { ...; 1 }) { my $err = $@; ...handler using $err... }` —
  the conditional must test `eval`'s return value (not `$@`), and if `$@` is
  referenced anywhere other than the block's very first statement it must be
  saved to a lexical on that first statement so later code cannot clobber
  it.
- Three-step form, required for if/else branching on the result:

  ```perl
  my $ok  = eval { ...; 1 };
  my $err = $@;
  if ($ok) { ... }
  else     { ... }
  ```

- **A multi-line `eval` block must never appear inside the parens of a
  conditional.** Use the three-step form. The postfix / inline / or-form
  variants are only for eval blocks short enough to fit on one line.
- **`fork` failure is handled inline**: `my $pid = fork // die "reason: $!"`.
  Never a separate conditional afterward. Fork failures are always `die`,
  never `croak`.
- Nothing tests an error *value* for truthiness — an exception object may
  overload boolean to false. Test the `eval` return, or `defined`-ness.

---

## Sub-second sleeps

Use **`Time::HiRes::sleep($secs)`** for every sub-second sleep — poll
cycles, backoff sleeps, anywhere code waits a fraction of a second.

`Time::HiRes::sleep` returns early on signal interruption (`EINTR`), which
is the behavior we want: a signal delivered during the wait should break the
sleep immediately rather than being swallowed. It wakes on signal exactly
like `sleep` / `usleep`. There is no need for a `tinysleep` helper.

**Do not use 4-arg `select(undef, undef, undef, $secs)` as a sleep
primitive.** Replace it with `Time::HiRes::sleep` when you find it.

---

## Conditionals

- **Single-statement conditional blocks use postfix form**:
  `do_thing() if $cond`, `do_thing() unless $cond`. Never
  `if ($cond) { do_thing(); }`. Multi-statement blocks keep the block form.
- **Never write a multi-line conditional expression inside the parens** of
  `if` / `unless` / `while` / `until`. A test expression spanning more than
  one source line is hard to scan — the eye loses which clauses combine.
  Refactor by one of:

  - Accumulate the boolean step by step:

    ```perl
    my $ok = defined $arg;
    $ok &&= !ref($arg);
    $ok &&= $arg !~ m{^[0-9]};
    $ok &&= $arg !~ m{^@};
    if ($ok) { ... }
    ```

  - Extract a predicate helper that returns true/false:

    ```perl
    sub _is_unknown_kv_arg {
        my ($class, $arg, $has_next) = @_;
        return 0 unless $has_next;
        return 0 unless defined $arg;
        return 0 if ref $arg;
        return 0 if $arg =~ m{^[0-9]};
        return 0 if $arg =~ m{^@};
        return 1;
    }

    if ($class->_is_unknown_kv_arg($arg, $i + 1 < @args)) { ... }
    ```

  Either form is fine; pick the one that reads better in context. Short
  conditionals that fit on a single line are still fine.

---

## Filehandles

**A lexical filehandle closes itself when it goes out of scope. Do not write a
redundant `close($fh)`.**

```perl
# Good -- the handle closes when the sub returns.
sub read_config {
    my ($self, $path) = @_;
    open(my $fh, '<', $path) or croak "open '$path': $!";
    my @lines = <$fh>;
    return \@lines;
}
```

Adding `close($fh)` immediately before a scope ends says nothing the scope did
not already say, and it is one more line to keep correct on every early
return.

Close explicitly when there is an actual reason:

- **The scope lives a long time.** A handle opened in a long-running loop
  body, a daemon's main scope, or a package-level variable holds a descriptor
  until that scope ends. Close it when you are done with it.
- **You need the result.** `close` reports write errors that `print` never
  saw — a full disk, a failed flush. Any handle whose data must actually land
  gets a checked close:

  ```perl
  close($fh) or die "close '$path': $!";
  ```

- **You need `$?` from a pipe.** Closing a pipe handle reaps the child and
  sets `$?`; that is the only way to get its exit status.
- **Ordering matters.** Another process must see the file complete, a lock
  must drop, or a rename must follow. Close where the ordering requires it,
  not where the scope happens to end.
- **The descriptor is needed elsewhere.** Freeing a slot before spawning, or
  before reopening the same path.

The rule is about redundancy, not about closing. A close that does work stays;
a close that only restates the scope goes.

## Lists and pushes

When using `push`, separate the target array from the values with `=>`
instead of a comma: `push @items => $thing`, `push @{$ref} => $thing`. The
fat comma makes the destination visually distinct from the values.

---

## Language-feature defaults

- Prefer `//=` for defaults.
- Use constants over package vars for "is module installed" gating:
  `use constant HAVE_FOO => eval { require Foo; 1 };`

---

## Minimum Perl version **[project-declared]**

There is no universal Perl floor. Each project records its actual minimum as
an exact version, or explicitly states that it makes no minimum-version
promise. The declaration must agree with `dist.ini` and with version pragmas
in shipped modules.

Do not raise a project's minimum as a cleanup. Compatibility is a release and
architecture decision owned by that project.

## Subroutine signatures **[project-declared]**

Signature policy is independent of the minimum Perl version. Each project
declares either:

- **Disabled.** Use `use strict; use warnings;` and ordinary `@_` argument
  handling consistent with the surrounding code.
- **Required where expressible.** Declare the version/feature pragma that
  enables signatures in that project, then use signatures for all named subs,
  methods, and anonymous subs whose call shape they can express.

For a project using `use v5.38`, that one line enables `strict`, `warnings`,
and stable signatures. Do not add a separate experimental-signature
incantation at that floor.

Under a required-signatures declaration:

- Methods: `sub method ($self, $arg, $other = undef) { ... }`
- Class methods: `sub new ($class, %params) { ... }`
- Functions: `sub helper ($x, $y //= compute_default()) { ... }`
- Variadic tails: `sub foo ($first, @rest) { ... }`, `sub bar (%opts) { ... }`

Default-value form follows the same intent rules as `//=` / `||=` on
assignment:

- `$x = $default` — applied only when the argument is **missing**. An
  explicit `undef` is preserved.
- `$x //= $default` — applied when the argument is missing **or** `undef`.
  Use wherever the body would otherwise do `$x //= $default;`.
- `$x ||= $default` — applied when the argument is missing or falsy. Use
  sparingly; like the assignment form, it drops legitimate `0` / `""`.

Drop to `@_` only where signatures genuinely cannot express the call shape:
re-dispatching arguments unchanged (`goto &other`, `$other->(@_)`),
positional + key/value + flag mixes needing custom parsing, or subs that
peek at `wantarray` / `caller` before forwarding. Aesthetic preference for
`my $self = shift;` is **not** a reason to skip a signature.

Argless declarative-metadata methods may keep an empty parameter list —
`sub TABLE { 'users' }` and `sub TABLE () { 'users' }` are both fine. Pick
one and be consistent within a file.

### If a project has not declared

Preserve the existing minimum-version promise and do not introduce
signatures. Report the missing declarations instead of guessing new values.

---

## Whitespace and formatting

- **No trailing whitespace. No emojis in code.** Documentation has its own
  no-emoji rule in `DOCUMENTATION.md`.
- Run **perlcritic** with the repository `.perlcriticrc` when the project has
  one. Not every project does; do not invent one unasked.

### perltidy **[project-declared]**

**Every new or edited Perl file is run through perltidy** — `.pm`, `.pl`,
`.t`, and executable scripts alike.

The canonical configuration is **`~/projects/Agents/templates/perltidyrc`**.
Each project keeps a copy at its own root as `.perltidyrc`, so perltidy picks
it up automatically:

```
perltidy -b <file>              # uses the project's ./.perltidyrc
perltidy -b --pro=.perltidyrc <file>
```

Copy it in when a project lacks one:

```
cp ~/projects/Agents/templates/perltidyrc /path/to/project/.perltidyrc
```

What it sets, in short: four-space indent, no tabs, no maximum line length,
tight parens/brackets/braces, uncuddled `else`, `qw{}` left alone, welded
nested containers, and `--converge` so the output is stable rather than
merely one pass better.

**A project may override it** with its own `.perltidyrc`. That is a
declaration, so it gets recorded in the project's `AGENTS_OVERRIDE.md` along
with what differs and why — otherwise the next agent assumes the local file is
stale and "fixes" it back.

Never reformat a file you are not otherwise editing. Bringing a file into line
happens when you have real reason to touch it, not as a mass retro-tidy pass.

---

## Module size

- No single `.pm` file exceeds **10,000 lines of code**. That counts blank
  lines and comments but **excludes POD** — everything between
  `=pod` / `=head*` and `=cut`, and everything after `__END__`.
- When a module crosses 10,000 lines, **flag it for human review** rather
  than silently splitting it. The likely action is to break it into multiple
  modules; the human decides where the seams go.
- Do not game the rule by stuffing logic into long POD or another file via
  `do` / `require` tricks. It exists to keep modules comprehensible.

Audit: `agent_scripts/find-large-modules lib`

---

## Subroutine size

- No subroutine exceeds **75 lines** (signature line through closing brace,
  inclusive). POD blocks and code comments inside a sub do not count; the
  limit applies to executable Perl.
- When a sub crosses 75 lines, break it into smaller helpers with names that
  describe each step.
- **Narrow exception**: some low-level operations — packed-binary encoders,
  hex / bit-twiddling, table-driven dispatch where every branch is a
  one-liner — read worse when split. If splitting genuinely does more harm
  than good, keep it and add a short comment saying why. Do not invoke the
  exception as a default; if unsure, split.

Audit: `agent_scripts/find-long-subs lib`

---

## Comments

Comments are maintained documentation. Follow `DOCUMENTATION.md` under
"Comments" for when they are justified, how brief they should be, what
belongs in POD instead, and the rules for referencing committed AI documents.

---

## Terminology

Some words are forbidden in code, code comments, POD, user-facing strings,
and user documentation. Internal Markdown such as agent instructions, plans,
reviews, and decision records may use them when discussing the concepts
precisely. Do not introduce them into maintained code or user documentation;
if you touch a line there that already has one, replace it.

- **`backstop`** — use `fallback` for a mechanism that fires when the
  primary path fails, or `safeguard` for a protective limit.
- **`iff`** — write `if and only if`, or reword to `only when` / `only if`.
- **`kwarg`** / **`kwargs`** — write `named argument` / `named arguments`,
  or `key/value argument`.
- **`load-bearing`** — name the actual constraint instead (e.g. "the runner
  relies on this", "required for X to work").

Audit: `agent_scripts/audit-banned-words`. Its default scope is maintained
code plus specifically named user documents, not every Markdown file. A line
carrying the literal token `banned-words-ok` is skipped; use that only when
quoting an external name you cannot change.

---

## POD

POD requirements and content rules live in `DOCUMENTATION.md` under "POD".
This section defines placement and ordering.

### Placement — default: all POD at the bottom

**All POD lives at the bottom of the file, under the `__END__` marker.** Do
not place POD at the top of the file or inline between subs; the code body
comes first, then `__END__`, then one continuous POD document. This keeps
the code uninterrupted by prose and gives every module the same shape.

Within that document, keep the `TEMPLATE.pod` order:

- `NAME`
- `DESCRIPTION`
- `SYNOPSIS`
- `ATTRIBUTES` (for `Object::HashBase`-style classes)
- `EXPORTS` — one entry per exported function
- `PUBLIC METHODS` — one entry per public method
- `PRIVATE METHODS` — one entry per private method (leading-underscore
  convention)
- `SOURCE`
- `MAINTAINERS`
- `AUTHORS`
- `COPYRIGHT`
- any other tail sections the template carries

Method and export entries are still ordered to match code appearance, just
gathered under their heading at the bottom rather than interleaved.

### Placement — split layout **[project-declared]**

A project may instead declare the split layout in its `AGENTS_OVERRIDE.md`.
Under it:

- **Top of file** (after `use` statements, before the package does real
  work): `NAME`, `DESCRIPTION`, `SYNOPSIS`.
- **Inline with code** (a POD block immediately above the relevant sub):
  `EXPORTS` above each exported function, `PUBLIC METHODS` above each public
  method, `PRIVATE METHODS` above each private method. Those are still the
  headings used; the inline blocks are pieces of those sections, ordered by
  code appearance.
- **End of file**, under `__END__`: `SOURCE`, `MAINTAINERS`, `AUTHORS`,
  `COPYRIGHT`, and any other tail sections.

Under the split layout, POD placement dictates the outer ordering of subs:
the `EXPORTS` group comes before `PUBLIC METHODS`, which comes before
`PRIVATE METHODS`. The within-group ordering rules above still apply.

Whichever layout a project uses, every file in it uses the same one.

---

## Testing libraries

- **`Test2::V0`** for everything new under `t/`. Avoid `Test::More` and
  `Test::Simple` in new code; existing imports may stay until the file is
  touched substantively.
- Test layout, naming, fixtures, provenance, execution, and timing policy
  live in `TESTING.md`.

---

## Database guidance

Database framework, backend, dependency, and developer-install choices are
project architecture rather than Perl style. Database projects may reference
`DATABASES.md` for optional shared testing operations. Projects that do not
name it ignore it.

---

## UUIDs

- Generate UUIDs **in Perl, not in the database**. `Test2::Util::UUID` where
  it is already a dependency; `UUID` directly otherwise.
- They are **v7**. Do not reorder bits for "index locality" — v7 is already
  ordered by time of generation.
