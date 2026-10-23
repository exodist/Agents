# IPX — Interface and Process

An optional methodology for structuring Perl modules. Read this document only
when a project's `AGENTS.md` says it follows IPX, and then before adding a
module, moving logic between modules, or writing a requested plan. A routine
edit inside an existing method does not need it.

Everything here is recommended form, not hard rule. Where a case does not fit,
depart from it and say why in a comment where the reason is not obvious. A
project records standing departures in its `AGENTS_OVERRIDE.md`. The reasoning
behind each section is in `RULINGS.md` under the "IPX" entries.

## The idea

Design the developer-facing interface first: how a person uses the module.
Keep the objects behind that interface thin — state, accessors, state checks,
simple mutators. Put complex algorithms in separate Process modules, so the
state an algorithm needs while it runs never lives on the objects it works on.

That separation is the point. Interface objects hold domain state; Process
modules hold process state. Neither is left half-mutated or carrying scratch
slots for the other.

The name: **I**nterface and **P**rocess, then **X** — whatever a project
builds on top. Presentation layers (CLI, web, TUI) are the X; they call
Interface and Process modules, and IPX does not define their structure.

IPX borrows from DCI without following it. A Process module resembles DCI's
Context, but roles are composed into classes as usual, never cast onto objects
at runtime, and there need not be a database. A task Process module is the
Command or Method Object pattern.

## Module types

**Utility.** Exports stateless functions that stand alone:
`write_file($name => $content)`, `my $content = read_file($name)`.

**Interface.** Objects with methods: accessors, state checks, simple
mutators, and methods for complex behavior that delegate to Process modules.
Database row objects are Interface objects.

An Interface object may be an immutable value: refining methods return a
modified copy and leave the original untouched, as `DBIx::QuickORM::Handle`
and `DBIx::Class::ResultSet` do. Prefer this for objects callers refine and
reuse — refining in place changes the object under every other holder. Copies
may be shallow, so a value object never mutates its internals in place.
Building one by refinement is not Process aggregation: every intermediate
value is usable by the caller.

**Utiliface.** A cross between the two: an instance, plus functions exported
into the consumer as shortcuts for acting on it. It takes one of two forms:

- A process-wide singleton.
- An instance per consuming class, reachable from it (`Consumer->my_meta`) —
  as the meta object is in Moose or Exporter::Declare.

**Process.** Encapsulates one algorithm or task. It may be called by an
Interface method, or be a public entry point in its own right, documented as
"use this to accomplish X; these are the inputs".

## When work becomes a Process module

A method on the Interface object is the default. Promote the work to a Process
module when either holds:

1. It spans several subs that share significant process-specific state —
   state you would otherwise park in scratch slots on the Interface object or
   thread through every helper.
2. It mutates objects in more than one ownership tree. A tree is an object and
   what it contains, at any depth; changes within one tree go through its
   root. A reference such as a foreign key does not make a parent, and a link
   row belongs to the side that owns the relationship's API.

Length alone is not a reason: a long algorithm with no shared state splits
into private methods or Utility functions. Rule 2 is the domain-driven-design
aggregate boundary, and it will produce some very small Process modules; that
is correct, since a cross-tree change has no natural owner.

Two unrelated rows changed together is rule 2. Four elements of a JSON
structure stored in one row is one tree, and stays a method.

## Process forms

**Task.** Inputs go to `new` as read-only slots, checked in `init`. Scratch
state lives in the process's own slots, never on its inputs. One public entry
method, named for the domain verb, returns the result. Discard the object
afterward.

```perl
package Foo::Process::DepResolve;
use Object::HashBase qw{ <dist <index -seen -order };

sub init {
    my $self = shift;
    croak "'dist' is a required attribute"  unless $self->{+DIST};
    croak "'index' is a required attribute" unless $self->{+INDEX};
    $self->{+SEEN}  = {};
    $self->{+ORDER} = [];
}

sub resolve { ... }
```

**Accumulator.** `new` takes optional seed values. One or more `add`-style
methods feed it; a result method may be called any number of times without
consuming state, so more values can be added and the result read again. A
digest is the model — but unlike `Digest::SHA`, reading the result does not
reset it. Its state exists for the computation, not as a domain entity, which
is what makes it a Process rather than an Interface object: its intermediate
state means nothing to the caller.

Errors and argument validation follow `PERL_STYLE_GUIDE.md` under "Error
handling". Public entry points and role-defined inputs are where input checks
most often earn their place.

### Reporting a caller's mistake

A Process module built by an Interface method finds the user's mistakes two or
more frames from the user, which the style guide answers with `confess`: a
full trace where a `croak` from the Interface method would have given one
line. Where that matters, the process may take an optional `trace` input
instead and die at it.

- The Interface method that builds the process passes `trace => [caller]`.
  That is the user only when the method is public and called directly; a
  public method reached through another of the distribution's methods passes
  the trace it was given. The trace is an input like any other, given once at
  construction, never threaded through internal subs.
- The process's checks of the caller's mistakes call `$self->throw($msg)`.
  With a trace it dies with `croak`'s one-line form at the trace's file and
  line; without one it confesses, so a process built any other way still
  reports correctly.
- Failures internal to the process still `die`, and argument checks on its
  internal methods still `croak`. Errors from code the process calls keep
  that code's own policy.
- Never count, skip, or walk frames to find the user. Pass the frame down
  from where it is in hand.

A role is the recommended shape once more than one process in a project
reports this way; `requires` documents the input and marks which processes do.
A single process can define `throw` itself.

```perl
package Foo::Role::TracedProcess;
use Role::Tiny;
use Carp qw/confess/;

requires 'trace';    # [package, file, line], or undef

sub throw {
    my $self = shift;
    my ($msg) = @_;
    my $trace = $self->trace or confess $msg;
    die "$msg at $trace->[1] line $trace->[2].\n";
}
```

The process declares `<trace` in its `Object::HashBase` list and composes the
role. A process built inside an `Object::HashBase` `init` cannot get the
user's frame from `[caller]`, which there is the generated `new`; it falls
back to `confess` unless its builder captures the caller honestly, such as a
hand-written `new` taking `[caller]` before calling the generated one.

## Process modules and Interface objects

- A Process module never reads or writes an Interface object's slots. The
  Interface object provides the accessors and mutators the process needs.
- Within one distribution a Process module may call another class's
  `_methods`. Where a process or its roles are meant for third-party use,
  every method a role requires is public, so an extension never has to define
  an underscore method to fit.
- Define a role for a Process module's inputs only when unrelated types can
  stand in. One class and its subclasses need none.
- Loading runs one way: an Interface module that delegates loads the Process
  module; the Process module takes instances through `new` rather than
  loading Interface classes to use them.

## Layout

Projects may vary this.

- A small process used by one Interface class lives under it:
  `Foo::Thing::Proc`. Roles only it uses live under the process:
  `Foo::Thing::Proc::SomeRole`.
- A process shared by several classes, or meant for public use, lives under
  `Foo::Process::`, with its own roles beneath it. A private process that
  becomes shared moves there; start anything public there.
- Shared roles keep the project's usual role location.
- Process modules rarely sit directly under the main namespace, where they
  read as Interface objects.
