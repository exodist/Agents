# AGENTS_OVERRIDE.md

This project's answers to the choices the universal agent rules deliberately
leave open, plus every deliberate departure from them.

Universal rules live in `~/projects/Agents` (see `AGENTS.md` for the clone
URL). Every project-local document already takes priority over shared rules;
this file keeps declarations and explicit overrides easy to find.

---

## Declarations

Every one of these must be answered. An unanswered declaration is how two
files in one repository end up in different styles.

### Minimum Perl version

> **Minimum: _____**

Give the exact version promised by the distribution, matching `dist.ini` and
shipped module pragmas, or explicitly state that the project makes no
minimum-version promise.

Reason: _____

### Subroutine signatures

> **Policy: disabled / required where expressible**

If required, name the version/feature pragma that enables signatures. If
disabled, argument handling follows the surrounding code using `@_`.

Reason: _____

### POD placement

> **Layout: _____**

- **All at bottom (default).** One continuous POD document under `__END__`, in
  `TEMPLATE.pod` order. No POD at the top of the file, none between subs.
- **Split.** `NAME` / `DESCRIPTION` / `SYNOPSIS` at the top, per-method POD
  inline above each sub, tail sections under `__END__`. Sub order then follows
  the POD grouping.

Reason: _____

### Test layout and provenance

> **Scheme: _____**

- **Categories plus origin headers (default for new projects).** `t/unit`,
  `t/acceptance`, `t/regression`, `t/integration`, with `t/lib`, `t/fixtures`,
  `t/scripts`; every `.t` carries `# Test origin: human|AI|mixed`.
- **`t/AI/` mirror tree.** Human tests in `t/`, AI-generated tests in `t/AI/`
  mirroring the same subdirectory layout. No per-file origin header.

If using categories plus origin headers, record the exact strict audit command
here, including `--namespace` and any project-specific options:

> **Layout audit: _____**

Reason: _____

### perltidy

> **Config: _____**

- **Shared.** `~/projects/Agents/templates/perltidyrc`, copied to
  `.perltidyrc` at the project root.
- **Project-local.** A `.perltidyrc` that differs — list what differs and why
  below.

Reason: _____

---

## Overrides

Every deliberate departure from a universal rule, with its reason. A rule
quietly ignored in the code is a bug; a rule overridden here is a decision.

Delete the examples and replace them with the real ones. If there are none,
say "None." and leave the heading.

<!--
### Module size limit

Universal: 10,000 lines of code per `.pm`.
Here: 1,000.
Reason: this codebase is being split aggressively during the rewrite; the
lower cap is the forcing function.

### Dual-life distribution

This distribution also ships inside the Perl core, which overrides several
packaging rules at once (see DZIL_GUIDE.md "Distribution shapes"):

- Plain [MakeMaker], not [MakeMaker::Awesome] -- no custom header and no NJH
  guard; the core build has to be able to consume the generated Makefile.PL.
- [OnlyCorePrereqs] with starting_version = X: every prerequisite must itself
  be core as of that perl.
- Perl floor 5.00XXXX. That is a compatibility promise, not a preference --
  raising it is a release decision, never a cleanup.
- Internal .md files are NOT excluded from [GatherDir]; the core tarball
  comparison expects the tree as-is.
- The directory name differs from the distribution name.

### Reference tree

Universal: most projects have none, and the section is left out of AGENTS.md.
Here: `reference/`, with one subtree per abandoned iteration.
Reason: five prior attempts, each still worth reading for a different
subsystem.
-->

---

## Prior rulings

Decisions the owner has already made that agents keep re-asking about. One
line each, dated. This section exists so the same question is not walked
through discussion mode twice.

<!--
- 2026-07-15: Review findings about missing AI_DOCS entries and about
  module/file/sub length are ignored entirely. Do not act on them, do not
  report them as pending work.
-->
