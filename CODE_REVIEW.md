# Code review

Every completed change must pass an independent review cycle before an agent
announces it complete. The review scope may be a task or set of tasks, working
tree, commit or group of commits, branch, or other batch of work. There is no
minimum change size that skips review.

Run the cycle after implementation and the applicable pre-review checks. A
single completed body of work is one review scope even when it can be
described in several ways, such as both a branch and its commits. That whole
body of work is the first cycle's scope; later cycles narrow to the fixes made
since, as "Cycle scope" below defines.

## Independent reviewer

Use one newly launched sub-agent for the whole review scope unless the large
change rules below justify splitting it. Use the same model as the agent that
implemented the work. When no agent implemented the change, use the same model
as the parent agent coordinating the review. Launch every reviewer with
`medium` effort in Claude or `medium` reasoning in Codex.

The reviewer must be independent:

- It did not implement or help implement the work under review.
- It starts with fresh context, not the parent's inherited implementation
  conversation.
- The parent gives it a self-contained review brief with the requested
  outcome, acceptance criteria, the scope manifest and this cycle's scope,
  applicable repository entry documents, relevant owner rulings, and
  validation already run.
- The brief identifies what to review without telling the reviewer what
  conclusion to reach or where the parent expects problems.

The reviewer reads the applicable repository instructions, inspects the full
diff and enough surrounding code and documentation to understand it, and
reports findings without editing the work. Each finding states the location,
problem, and concrete impact. The reviewer explicitly says when it found no
issues.

Every reviewer also reads
[`OVERENGINEERING_EXAMPLES.md`](OVERENGINEERING_EXAMPLES.md) completely and
keeps it in context while reviewing. Use it to recognize changes whose likely
value may be disproportionate to their complexity and maintenance burden, but
not as binding precedent. A comparable tradeoff is an owner decision to flag,
not permission for the reviewer to remove requested behavior by analogy.

Apply [`AGENTS.md`](AGENTS.md) under "Engineering judgment: value against
cost" whenever a finding concerns added behavior or support. Report the
evidence and expected frequency, concrete benefit and affected users,
implementation and testing cost, ongoing maintenance and compatibility burden,
and the reversibility of adding support later versus removing it once callers
rely on it. When there is no known or commonly encountered use case, recommend
the smallest honest contract by default: document the case as unsupported
and/or fail with a clear exception instead of adding speculative machinery.
Support can usually be added compatibly after a concrete need appears, while
poor or over-engineered support is difficult to withdraw. This default does
not override documented requirements, existing compatibility contracts,
correctness, safety, or data integrity.

## User-requested multi-model review

The user may explicitly request independent reviews from multiple named
models. This is an alternate review mode, not an automatic addition to the
normal review cycle. Give one independent sub-agent of each named model the
same self-contained prompt and review scope.

Multi-model review has different cost controls and defaults:

- Run one review round, not an automatic review-and-fix loop.
- Use one sub-agent per named model regardless of the change size or commit
  count.
- Add reviewers only when the user asks for additional agents. When that
  request gives no agent-count limit, use five agents per model as the maximum,
  not as a target.
- Do not fix findings or launch a re-review unless the user explicitly asks.

Unless the user requests another output, consolidate all reviewers' findings
into one Markdown document and give the user a brief report about it. Follow
any requested fixes, additional rounds, or different deliverables only to the
extent the user specified; do not silently expand them into the normal
automatic loop.

## Test execution during review

For agent-authored work, assume the implementation agent left the applicable
test suite green or received the user's permission to commit with known test
failures. Reviewers inspect tests and prior validation as evidence but do not
rerun test suites. This applies to the normal review cycle and user-requested
multi-model review.

Do not rerun a suite after review fixes. Run a test only when the finding and
fix concern a specific test and a pinpoint invocation is truly necessary to
verify that fix. Never expand that check into the full suite.

Review-derived fixes remain part of the review process for this rule,
including fixes the user requests during later disposition. Run the applicable
non-test gates and launch a new independent review cycle, but do not restart
the full pre-review procedure or test suite solely because those fixes were
made.

This assumption does not apply when reviewing a human-authored change, a pull
request from outside the agent workflow, or another external contribution
whose prior validation is not guaranteed. Follow the project's test procedure
for those changes. Explicit user instructions to run tests also take priority.

## Scope manifest

Before the first cycle, record the manifest that fixes the loop's boundary,
and give it to every reviewer as part of the brief:

- The request and the requested outcome.
- The baseline commit the work started from and the commits in scope.
- The paths the work changed.
- Owner rulings that bear on the work, including any problems the owner
  already said to defer.

The manifest does not change while the loop runs. A finding about a path the
manifest does not list is pre-existing or optional hardening, never must-fix,
unless the reviewed work newly triggers it. A fix that needs to touch a path
outside the manifest is an owner decision, not a fix the agent makes on its
own.

## Cycle scope

Each cycle reviews only the work produced before it. No cycle re-reviews work
an earlier cycle already covered.

- The first cycle's scope is the complete body of work: every commit in the
  branch or commit set under review, diffed against the baseline it started
  from.
- Every later cycle's scope is exactly one commit — the fix commit the
  previous cycle produced.

A reviewer may read earlier commits, the baseline, and surrounding code as
context, but reports findings only about its own scope. It does not re-report
or re-litigate findings against commits an earlier cycle reviewed.

## Out-of-scope and pre-existing problems

Review what the work under review changed. Code, comments, tests, and
documentation the work did not touch are context, not review targets. Do not
go looking for problems in them.

A problem that already exists in the baseline the branch or commit set started
from is a **pre-existing finding**. Record its location and problem and stop
there. Pre-existing findings are never fixed during the review loop, never
make a cycle unclean, and never justify another cycle. The narrow exception is
a pre-existing problem the reviewed work newly triggers or makes materially
worse; there the finding is the reviewed work's interaction with it, not the
old code's general quality.

Hand recorded pre-existing findings to the user after the loop ends, under
"Report and owner disposition".

## Large change review

In the normal review cycle, one reviewer owns the entire scope. Multiple
reviewers may be used only when either of these thresholds is met. These
thresholds do not add agents in user-requested multi-model review. A changed
line is an addition or deletion in the reviewed diff; additions and deletions
both count.

- **Commit split:** At least five commits in the scope each contain 200 or
  more changed lines. Assign one reviewer to each such commit and one more
  reviewer to all smaller commits together, when smaller commits exist.
- **File split:** The scope contains at least 1,000 changed lines across at
  least five files. Assign one reviewer to each file with 200 or more changed
  lines and one more reviewer to all smaller files together, when smaller
  files exist.

Choose either the commit split or the file split, not both. Give every
reviewer the full change as context but a distinct primary scope, so it can
check interactions without duplicating responsibility. Together the assigned
scopes must cover every change.

Measure these thresholds against the current cycle's scope, not the branch
total. A later cycle reviews a single fix commit and normally uses one
reviewer.

## Review standard

Review against the user's request, the project's architecture and other
instructions, relevant tests, and the surrounding implementation. Look for:

- Correctness bugs, including error paths, edge cases, and integration
  failures.
- Behavior that does not satisfy the requested or documented outcome.
- Missing or inadequate tests where they leave changed behavior unverified.
- Missing, inaccurate, or misleading user-facing documentation.
- `Changes` entries that are multiline, nested, exceed 35 words or 200
  characters, include supporting detail or process history, or use a second
  sentence without essential compatibility or migration information.
- Violations of the style guide or any other repository rule.
- Maintainability problems with meaningful ongoing cost.
- Machinery whose likely value appears disproportionate to its complexity,
  testing surface, compatibility burden, or maintenance cost.
- Complexity a simpler implementation would avoid, under [`AGENTS.md`](AGENTS.md)
  "Keep it simple": a layer, option, or abstraction nothing needs yet, or
  human-interface sugar that has thickened into internal complexity.

Classify each finding by the disposition it requires:

- **Owner decision:** A finding whose proper resolution requires a product,
  support, architecture, compatibility, or cost tradeoff the agent is not
  authorized to make. This classification takes precedence even when the
  finding concerns correctness or documentation.
- **Must fix:** Any correctness bug, user-facing documentation problem, style
  violation, repository-rule violation, or significant maintainability
  problem that does not require an owner decision.
- **Optional hardening:** A change that would strengthen the work although
  nothing about the work is wrong without it — an additional test
  combination, a defensive check, further cleanup. It never makes a cycle
  unclean. Record it with the minor findings, and raise it as an owner
  decision when it carries material cost.
- **Minor:** A nit with no effect on correctness and no significant effect on
  maintainability.

Do not dilute a must-fix finding into a minor item merely because its fix is
inconvenient. Do not guess at an owner decision. Do not classify optional
hardening as must-fix because it would make the work stronger.

A fix requires an owner decision, whatever class the finding carries, when it
would:

- change supported behavior or error policy;
- add a backend, process, producer, or execution-mode special case;
- change architecture rather than restore an existing contract;
- create or substantially expand a test matrix;
- restructure a large module or a user manual;
- touch anything outside the scope manifest;
- exceed 100 changed lines or three files as a single fix.

Correctness does not exempt a fix from this. When the resolution is a product,
support, or cost tradeoff, it is an owner decision even though the finding is
a real bug.

A missing test is must-fix only when changed behavior has no reasonable
evidence, or a distinct implementation seam makes the untested failure
plausible; the reviewer names that seam. Further backend, mode, producer, or
state combinations that exercise the same code path are optional hardening. A
hypothetical broken implementation that only an unwritten combination would
catch does not by itself make a test required.

## Review and fix loop

One review cycle is one round of independent reviewer sub-agents, whether the
round uses one reviewer or a permitted large-change split.

1. Launch the fresh-context reviewer or reviewers for this cycle's scope.
2. Collect and reconcile their findings.
3. If there are no must-fix findings, the cycle is clean; stop the loop.
4. Fix every must-fix finding. Defer owner decisions and record any minor
   findings intentionally left unfixed and any pre-existing findings.
5. Run the applicable non-test validation for the fixes. Test execution stays
   within the narrow limits above.
6. Commit all of this cycle's fixes as one new commit on top of the work under
   review.
7. Check the stop conditions below. If one is met, halt the loop and flag it.
8. Otherwise begin a new cycle with a newly launched reviewer or set of
   reviewers whose scope is that new commit alone.

Never reuse a reviewer for a later cycle. A cycle is clean when no unresolved
must-fix finding remains in its scope. It may still contain minor findings
deliberately left unfixed, items deferred for an owner decision, or recorded
pre-existing findings.

## Fix commits and history

Each cycle produces exactly one fix commit: work N commits, first cycle's
fixes land as commit N+1, the second cycle's as N+2, and so on. A cycle that
finds nothing to fix produces no commit and ends the loop.

While the loop is running, do not amend, rebase, or squash the work under
review — the next cycle needs the fixes as their own reviewable commit. This
overrides the amend exception in [`AGENTS.md`](AGENTS.md) under "Commits" for
the duration of the loop.

When the work is meant to land with review fixes folded into the original
commits, squash only after a clean cycle. The agent doing the squash verifies
the result itself; a squash that preserves already-reviewed content does not
need another independent review cycle.

Create an archive ref before the first cycle, pointing at the pre-review tip,
and another before any squash, pointing at the clean tip. Name them
`refs/archive/<branch>-<what-it-marks>-<YYYYMMDD>` and report them with the
review results. They make rollback an ordinary operation instead of reflog
archaeology.

These refs are scaffolding for a live loop, not history worth keeping. When
the user merges, pushes, or removes the worktree for the work, delete that
work's archive refs as part of that step and say which ones you deleted.
Never delete an archive ref for work still in flight, and never leave stale
ones behind after the work lands.

## Stop conditions

A clean cycle is the normal way the loop ends. These conditions end it early,
because each is evidence of a problem the loop itself cannot fix. When one is
met, keep the fixes already committed, stop launching reviewers, and report to
the user instead of continuing.

- **Oversized fix:** One cycle's fix commit changes more than half as many
  lines as the original work under review. Count changed lines the same way
  the large-change thresholds do, comparing the fix commit against the first
  cycle's scope.
- **Cumulative growth:** The loop's fix commits together change more than half
  as many lines as the original work, measured the same way. This catches many
  moderate rounds that no single round would trip.
- **Round limit:** Nine cycles have run without a clean result.

Flag the halt with the unresolved must-fix findings and an explanation of what
the trigger indicates. Oversized or cumulatively large fixes usually mean the
original work missed the requirement, took a wrong approach, or that reviewers
are rewriting it rather than correcting it. Nine unclean rounds usually mean
the same, or that fixes keep introducing new problems, or that reviewers are
churning on
subjective preferences. Recommend a direction — for example redoing the work,
narrowing the requirement, or accepting the remaining findings — and let the
user decide.

Do not resume the loop, retry with different reviewers, or start over on your
own after a halt.

## Report and owner disposition

After a clean cycle, report to the user:

- The number of review cycles completed.
- An extremely brief bullet list of the issues review found and the agent
  fixed.
- The count of deferred owner decisions.
- The count of unfixed minor findings and recorded optional hardening.
- The count of recorded pre-existing findings.
- The original changed-line count, the cumulative size of the review fixes,
  and the archive refs created.

Report the same items when a stop condition halted the loop, plus which
condition tripped, the unresolved must-fix findings, and the explanation and
recommendation that condition requires. Do not announce halted work complete.

Name the state the loop ended in. "Clean" is not the only acceptable outcome:

- clean;
- halted at a stop condition with known findings;
- the owner accepted the remaining findings;
- the owner sent the work back for redesign instead of another round.

End the turn after this report so the user can read it. Do not begin walking
the remaining items in the same message.

If deferred decisions, minor findings, or pre-existing findings remain when
the user continues, read and follow
[`skills/decision-discussion/SKILL.md`](skills/decision-discussion/SKILL.md).
Walk substantive owner decisions under that procedure. Make disposition of
the minor findings and optional hardening the last review-finding discussion
item: present them as one brief bullet list, then let the user skip them,
request more detail about any item, or identify which ones to fix.

Close with the pre-existing findings when any were recorded. Present them
briefly and ask the user how to track them — commonly a new document or an
addition to an existing TODO document. Do not fix them as part of this work
unless the user asks for that.

Any review fixes requested during that discussion receive the non-test
validation allowed above, land as their own commit, and must pass a new
independent review cycle scoped to that commit before being announced
complete. The user may waive that cycle for a narrow approved correction such
as a typo, a wording change, or a single-line edit; a waiver covers only the
correction it was given for.
