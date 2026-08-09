---
name: decision-discussion
description: Walk one or more pending decisions past the user one item at a time, with progress indicators, full context, options and a recommendation per item. Use when review findings, design questions, API-shape choices, or deferred rulings need the user's judgment and an agent cannot rule on them itself.
---

# Decision discussion mode

This file is the authoritative decision-walk procedure. `AGENTS.md` states
when it is required and points here rather than duplicating these steps.

Any time one or more decisions are needed from the user — deferred review
findings, design questions, API-shape choices, anything an agent cannot rule
on itself — walk them this way. Except for the final minor-finding disposition
defined in `CODE_REVIEW.md`, never dump the whole list and never batch the
answers.

## The rules

- **One item per message.** Never advance until the user says "next" (or
  equivalent). The user may ask questions, request probes or code reading, or
  change direction mid-item; answer within the current item until told to move
  on.
- **Progress indicator first.** Every item opens with a header like
  `Item 3 of 10`, so the user always knows position and remaining count.
  Follow-up answers within the same item repeat the indicator.
- **Grouping.** Items sharing one root cause may be presented together as a
  single combined item — say so and count them accordingly
  (`Items 5+9+10 of 10`). Do **not** group items that merely resemble each
  other.
- **Review minor-finding exception.** `CODE_REVIEW.md` collects unfixed minor
  findings into one final disposition item. This is the sole exception to the
  grouping rule: present its brief bullet list and let the user skip the
  items, request details, or identify which ones to fix.
- **Plain conversation, not a selector.** Never present the decision through a
  menu or choice UI. The user decides in free-form discussion.
- **Record the ruling** where the project tracks such decisions (the active
  disposition ledger, the relevant doc) **before** presenting the next item.
- **Do not implement anything mid-walk** unless the user says to. Collect
  rulings; implement when asked.

## Per-item format

Terse wording. Bullet lists over prose paragraphs.

```
Item 3 of 10

<What the issue is — one or two sentences.>

Context
- Where it lives: path/to/file.pm:123
- How it arises: ...
- Measured behavior: ...
- Prior rulings that bear on it: ...

Value and cost (when behavior or additional support is at issue)
- Evidence and expected frequency: ...
- Concrete benefit and affected users: ...
- Implementation and testing cost: ...
- Ongoing maintenance and compatibility burden: ...
- Reversibility: cost of adding support later versus removing it once relied on

<Code example, when it clarifies — current behavior, or the shapes a fix
would take.>

Options
- A: ... — cost/consequence
- B: ... — cost/consequence

Recommendation: <which, and why.>
```

Include the code example only when it earns its space. Include options only
when obvious ones exist. Always include the recommendation and its reason.

For edge-case and optional-support decisions, include the value-and-cost
assessment even when the evidence is "no known use case." Do not hide
uncertainty behind a generic cost or consequence.

When demand is unproven or the situation is unlikely, the recommendation
should lean toward the smallest honest contract: document the case as
unsupported and/or throw a clear exception instead of adding speculative
logic. Support can usually be added compatibly later when a concrete need
appears. Poor or over-engineered support is harder to withdraw after callers
rely on it and can impose a permanent testing, compatibility, and maintenance
burden. Recommend additional machinery only when a known or commonly
encountered use case is important enough to justify its full lifetime cost.
This default does not override documented requirements, existing compatibility
contracts, correctness, safety, or data integrity.

## Before you start

- Read `~/projects/Agents/OVERENGINEERING_EXAMPLES.md` completely and keep it
  in context throughout the discussion. Use it to calibrate options and the
  recommendation, and call out a close analogy when it helps expose likely
  disproportionate complexity. The examples are not binding precedents; the
  current decision still belongs to the owner.
- Count the items and say so up front: "N decisions to walk."
- Check whether the project has already pre-ruled on any of them (a
  `PENDING_DECISIONS.md`, a disposition ledger, an earlier AI_DOC). Use the
  recorded answers; only raise items that are still open, that the record does
  not cover, or where the code contradicts the record's framing.
- Where a decision blocks execution that is otherwise ready to run, say so in
  the item so the user knows what is waiting on it.
