# Code review

Every completed change must pass an independent review cycle before an agent
announces it complete. The review scope may be a task or set of tasks, working
tree, commit or group of commits, branch, or other batch of work. There is no
minimum change size that skips review.

Run the cycle after implementation and the applicable pre-review checks. A
single completed body of work is one review scope even when it can be
described in several ways, such as both a branch and its commits.

## Independent reviewer

Use one newly launched sub-agent for the whole review scope unless the large
change rules below justify splitting it. Use the same model as the agent that
implemented the work. When no agent implemented the change, use the same model
as the parent agent coordinating the review. Launch every reviewer with
`high` effort in Claude or `high` reasoning in Codex.

The reviewer must be independent:

- It did not implement or help implement the work under review.
- It starts with fresh context, not the parent's inherited implementation
  conversation.
- The parent gives it a self-contained review brief with the requested
  outcome, acceptance criteria, review scope and baseline, applicable
  repository entry documents, relevant owner rulings, and validation already
  run.
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

Classify each finding by the disposition it requires:

- **Owner decision:** A finding whose proper resolution requires a product,
  support, architecture, compatibility, or cost tradeoff the agent is not
  authorized to make. This classification takes precedence even when the
  finding concerns correctness or documentation.
- **Must fix:** Any correctness bug, user-facing documentation problem, style
  violation, repository-rule violation, or significant maintainability
  problem that does not require an owner decision.
- **Minor:** A nit with no effect on correctness and no significant effect on
  maintainability.

Do not dilute a must-fix finding into a minor item merely because its fix is
inconvenient. Do not guess at an owner decision.

## Review and fix loop

One review cycle is one round of independent reviewer sub-agents, whether the
round uses one reviewer or a permitted large-change split.

1. Launch the fresh-context reviewer or reviewers.
2. Collect and reconcile their findings.
3. If there are no must-fix findings, the cycle is clean; stop the loop.
4. Fix every must-fix finding. Defer owner decisions and record any minor
   findings intentionally left unfixed.
5. Run the applicable non-test validation for the fixes. Test execution stays
   within the narrow limits above.
6. Begin a new cycle with a newly launched reviewer or set of reviewers. Have
   them review the entire updated scope, including the fixes.

Never reuse a reviewer for a later cycle. A cycle is clean when no unresolved
must-fix finding remains. It may still contain minor findings deliberately
left unfixed or items deferred for an owner decision.

## Report and owner disposition

After a clean cycle, report to the user:

- The number of review cycles completed.
- An extremely brief bullet list of the issues review found and the agent
  fixed.
- The count of deferred owner decisions.
- The count of unfixed minor findings.

End the turn after this report so the user can read it. Do not begin walking
the remaining items in the same message.

If deferred decisions or minor findings remain when the user continues, read
and follow
[`skills/decision-discussion/SKILL.md`](skills/decision-discussion/SKILL.md).
Walk substantive owner decisions under that procedure. Make disposition of
the minor findings the final discussion item: present a brief bullet list of
the unfixed minor items, then let the user skip them, request more detail
about any item, or identify which ones to fix.

Any review fixes requested during that discussion receive the non-test
validation allowed above and must pass a new independent review cycle before
being announced complete.
