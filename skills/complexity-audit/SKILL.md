---
name: complexity-audit
description: Run a persistent complexity auditor alongside large work. It watches the user's instructions, rulings, the planned approach, commits, and review fixes, and flags unnecessary complexity or scope growth for the user to decide. Use at the start of any work the worktree rule covers, including foundations-phase work where a project suspends that rule.
---

# Complexity audit

This file is the authoritative complexity-audit procedure. `AGENTS.md` states
when it is required and points here rather than duplicating these steps.

Large work drifts in small, individually reasonable steps: an option nobody
asked for, a layer with one caller, an edge case handled "while we are here", a
review fix that adds machinery. The agent doing the work is the worst placed to
notice. A separate auditor with its own context watches for that drift and
raises it with the user.

The auditor is advisory. It has no veto and edits nothing. The user decides.

## When

Spawn one auditor at the start of any work the worktree rule in `AGENTS.md`
covers. This includes the same kind of work in a project that has suspended
that rule for a foundations phase. Simple fixes and small edits do not get
one.

One auditor per session. It stays open until the work ends or the session
does.

## The main agent's duties

**Spawn it with a brief** containing:

- The user's request, verbatim.
- Earlier messages in the session that bear on the work, verbatim.
- The project root, and any worktree path.
- The auditor section of this file, as its instructions.

Use a model at least as capable as the main agent's.

**Forward, while it runs:**

- **Every user message, verbatim.** Paraphrase is where scope drifts. Do not
  filter for relevance; the auditor decides that.
- **The approach, before writing code.** Wait for the auditor's reply before
  implementing. This is the cheapest point to remove complexity.
- **Each commit**, by sha. The auditor reads the diff itself.
- **Each review cycle's fix list, before applying it.** See `CODE_REVIEW.md`.
- **Any point where you are about to widen the work**: a new option, layer,
  file, dependency, or edge case the approach did not include.

Only the approach checkpoint blocks. Otherwise keep working, and read replies
before the next checkpoint.

**Handle every flag** in one of two ways:

- **Agree:** change course, and tell the auditor what changed.
- **Disagree or unsure:** take it to the user with the auditor's reasoning
  intact beside yours. Use `skills/decision-discussion/SKILL.md` when several
  are pending.

Never dismiss a flag silently. Do not announce work complete while a flag is
unhandled.

**Pass rulings back.** When the user rules on a flag or anything else in
scope, forward the ruling. Record it in `RULINGS.md` only when it meets the
bar in `AGENTS.md` under "What earns a place in `RULINGS.md`".

**Replace a stale auditor.** Long sessions compact context. If its flags cite
things no longer true or re-raise settled points, stop it and spawn a fresh
one. Its brief adds every ruling made so far this session.

**Report at completion:** the number of flags raised, and how each was
disposed of (changed course, or the user's ruling).

### Harnesses without persistent sub-agents

Spawn a fresh auditor at each checkpoint instead. Its brief is the spawn brief
above plus every ruling and flag disposition so far this session.

## The auditor

You watch one body of work for unnecessary complexity and scope growth. You do
not review correctness, style, tests, or documentation rules; other procedures
cover those. You edit nothing and direct no one. You flag, and the user
decides.

### Calibrate first

Read these before the first checkpoint:

- `~/projects/Agents/AGENTS.md`, "Engineering judgment: value against cost"
  and "Keep it simple".
- `~/projects/Agents/OVERENGINEERING_EXAMPLES.md`, completely.
- The project's `RULINGS.md`, `ARCHITECTURE.md`, and `AGENTS_OVERRIDE.md`,
  where they exist.

### What to watch

- **Scope.** Work the user did not ask for: features, options, supported
  cases, or "while here" changes beyond the request. Compare against the user's
  words, not the main agent's summary of them.
- **Complexity.** An abstraction, layer, option, or state with one real
  caller. Generality where the direct solution would do. Sprawl, which usually
  means the approach is wrong. New machinery where the language, an existing
  component, a carried dependency, or the project's reference trees already do
  the job.
- **Speculative support.** Edge cases with no evidence they occur, handled
  instead of documented as unsupported or rejected with a clear exception.
- **Review fixes that grow the work.** A fix list that adds behavior or
  machinery rather than correcting the requested behavior.
- **Drift.** The work moving away from what the user said earlier in the
  session, or contradicting a recorded ruling.

### What not to flag

- Anything a recorded ruling or a user decision this session already settled.
- Taste. A flag needs a concrete cost, not a preference.
- The same issue twice. Raise it once; the main agent tracks it.
- Correctness bugs. Mention one only if you happen to see it, as one line
  outside any flag.

### Reply format

At a checkpoint with nothing to raise, reply with exactly `No flag.`

Otherwise, one block per issue:

```
Complexity flag: <one line>

- Where: <path, commit, or plan step>
- Grows: <what was added or widened>
- Against: <the user's words, ruling, or rule it exceeds, quoted>
- Cost: <implementation, testing, and maintenance burden>
- Simpler: <the smaller alternative, including pruning or declaring the case
  unsupported>
- Recommendation: <which, and why>
```

Keep it terse. The main agent may hand the block to the user unchanged.
