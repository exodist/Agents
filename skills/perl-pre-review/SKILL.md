---
name: perl-pre-review
description: Run the mandatory pre-review passes on a Perl branch before handing work back — style-guide gates, POD, and util/role reuse. Use when work is finished and about to be announced as ready for review, when asked to "check my work", "run the gates", "pre-review", or before opening a PR in any of the Perl projects under ~/projects.
---

# Perl pre-review

Three mandatory passes, run against every file the branch touched. Resolve
everything they turn up, re-run the suite, and only then announce the work as
ready for review.

Authoritative sources: `~/projects/Agents/AGENTS.md` ("Pre-review checks"),
`~/projects/Agents/PERL_STYLE_GUIDE.md`,
`~/projects/Agents/DOCUMENTATION.md`, and
`~/projects/Agents/STYLE_GUIDE_AGENT_CHECKLIST.md`. Read the project's own
`AGENTS.md` too — it declares the Perl mode, POD layout, and test layout, and
may add project-specific gates.

## 0. Establish the touched set

Choose the branch this work was cut from, then include branch commits, the
index, the working tree, and untracked files. Keep the NUL-delimited manifest
for every later pass:

```sh
base_ref=origin/main # or origin/master / the actual parent branch
base=$(git merge-base "$base_ref" HEAD)
touched_file=$(mktemp)
{
    git diff --name-only -z "$base"...HEAD
    git diff --cached --name-only -z
    git diff --name-only -z
    git ls-files --others --exclude-standard -z
} | sort -zu > "$touched_file"
```

Do not substitute a branch-only diff: staged, unstaged, and newly created
files are commonly the work being handed back.

## 1. Style-guide pass

Run every applicable gate. **A hit is a hard stop, not a judgment call.**

```
perl agent_scripts/audit-methods-not-functions lib
perl agent_scripts/audit-readonly-attrs lib
perl agent_scripts/audit-banned-words
perl agent_scripts/find-long-subs lib
perl agent_scripts/find-large-modules lib
perltidy -b --pro=.perltidyrc <touched perl files>
git diff --check "$base"...HEAD
git diff --cached --check
git diff --check
```

If a project lacks a script, run the canonical copy from
`~/projects/Agents/agent_scripts/`.

Then walk `STYLE_GUIDE_AGENT_CHECKLIST.md` by hand for what the scripts
cannot see. The slips that actually recur:

- `eval` that tests `$@` instead of the eval's return value.
- A multi-line `eval` inside a conditional's parens.
- `croak` where the fault is internal, or `die` where the caller is at fault.
- A sub-second wait that is not `Time::HiRes::sleep`.
- A read-only HashBase slot declared `-attr` instead of `<attr`.
- Trailing whitespace.
- A helper defined in an object module and called as a bare function.

**When `audit-methods-not-functions` reports a hit, fix the CALL SITE.** Change
`helper($x)` to `$self->helper($x)`. Do not "fix" it by adding an unused
`my $self = shift;` to a declaration — the rule is about dispatch, and an
empty method that gains an unused invocant is a regression, not a fix.

## 2. POD pass

Check each touched `.pm` against the project's declared POD layout (default:
all POD at the bottom under `__END__`; some projects use the split layout).
Then:

```
podchecker <every touched .pm>
```

Resolve every error **and** every warning.

Check touched POD and other user-facing strings against `DOCUMENTATION.md`,
especially its audience and reference rules.

## 3. Util / role / base-class reuse pass

Re-scan the touched files for logic that already exists as a utility. Look in
the project's `*::Util`, `*::Util::*`, `*::Role::*`, and the relevant base
classes.

- Open-coding something a util/role/base class already provides → switch to
  it.
- The same logic in **three or more** touched files → extract it.

## 4. Re-run the suite

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

`AUTHOR_TESTING=1` and a timeout are mandatory; the lock is mandatory above
`-j4`. See the `perl-test-run` skill for the full contract.

## 5. Changelog and commits

- Every commit that changes shipped behavior has its own bullet under
  `{{$NEXT}}` in `Changes`, in that same commit.
- Commit messages and `Changes` entries satisfy their sections in
  `DOCUMENTATION.md`.
- Land fixups either as cleanup commits or by amending the relevant feature
  commits.

## 6. Report

Tell the user: gates run and their results, what was fixed, suite counts, and
anything deferred with the reason. **Do not push. Do not merge.**

Remove the temporary touched-file manifest when the pass is complete.
