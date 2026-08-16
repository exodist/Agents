# DOCUMENTATION.md

Human-readable shared rules for commit messages, `Changes` entries, comments,
POD, human documentation, and AI/agent working documents. A consuming
project's own documents take priority over this file.

This file governs content. `AGENTS.md` governs workflow, including when a
commit or `Changes` entry is required.

## Applies to all documentation

- Write for the intended reader. Make the result, behavior, or rule easy to
  find and understand.
- Be brief, but do not omit context the reader needs. Concise documentation
  says everything necessary once and stops.
- Remove repetition, obvious restatements, narrative lead-in, and detail that
  does not help the reader use, review, or maintain the work.
- Keep one authoritative explanation. Point to it only when the reference
  rules below permit; do not maintain several copies that can drift.
- Prefer plain language, short sentences, and a structure the intended reader
  can scan quickly.
- No emojis.

## Audience and references

Audience determines content and level of detail. Medium determines whether a
document reference is allowed: Markdown documents have their own rule, and
code comments have the only non-Markdown exception.

### Markdown documents

Any Markdown document may reference any other Markdown document, whether its
audience is human, AI/agent, or mixed.

- An uncommitted working Markdown document may reference committed or
  uncommitted Markdown documents.
- A committed Markdown document may reference only Markdown documents that
  are already committed or land in the same commit. Never commit a dangling
  reference to an uncommitted Markdown working file.

### Human-facing material outside Markdown

This includes user and contributor documentation in other formats, POD,
command descriptions and help, diagnostics, `Changes`, and commit messages.

- It must not reference any `.md` file.
- It must not reference any AI/agent document, regardless of that document's
  filename or format.
- When information from an internal document matters to the reader, restate
  the necessary behavior briefly in human terms. When it does not matter,
  omit it.
- Describe what exists, what changed, and the decisions actually made. Do not
  inventory work not done, rejected choices, or investigative dead ends just
  because they occurred.
- Record an unchosen path when the distinction is critical: for example, the
  implementation deliberately departs from prior art or a common pattern and
  a future maintainer might otherwise undo that choice. Explain the relevant
  deviation and reason, not every alternative considered.

### AI/agent-facing material

Agent instructions, AI task documents, plans, reviews, and similar working
documents may carry more context than human-facing documentation. They may
record alternatives, roads not taken, and the reasons choices were rejected
when that context will help later work.

They must still be readable, relevant, and no more verbose than their purpose
requires. When they are Markdown, they may cross-reference under the Markdown
rules above. Prefer a specific permitted reference to an authoritative
explanation over a duplicated rule.

Project `AGENTS.md` files carry project-specific context. They point to shared
rules instead of copying them; deliberate local differences belong in a
project-local authoritative document or `AGENTS_OVERRIDE.md`.

## Commit messages

- Start with a brief, direct summary. Add a body only when the reason,
  constraint, or compatibility effect is not otherwise clear.
- Explain what changed and the necessary why. Do not narrate the investigation
  or list rejected alternatives unless a critical deviation from prior art or
  a common pattern needs to be preserved.
- Be self-explanatory. Do not refer to plan or review documents, finding
  numbers, or other AI/agent-only context.
- Do not reference a `.md` file or any AI/agent document.
- Write `#` followed by digits **only** to reference a GitHub issue or pull
  request on purpose — `Fixes #1086`, `related to #926`. GitHub renders it as
  a link to that issue, which is exactly what a deliberate reference wants.
- Never write it any other way. `#` before a count, an ordinal, a column, or a
  version (`fixed #3 of the failures`, `RFC #2119`) becomes a link to an
  unrelated issue and stays wrong forever. Write `number 3`, `test 3`, or
  reword.

## `Changes` entries

- Write each entry as one top-level `-` bullet on one physical line.
- Use one short sentence. A second sentence is allowed only for
  essential compatibility or migration information.
- Keep the bullet text at or below 35 words and 200 characters.
- Describe shipped behavior in user-facing terms, not implementation work or
  agent process.
- Do not use continuation paragraphs, sub-bullets, implementation details,
  test summaries, rationale, or agent-process history. Put supporting detail
  in the appropriate user documentation.
- State what changed. Mention what did not change only when it is an important
  compatibility guarantee or other critical user information.
- Do not put a literal `{{` or `}}` inside a bullet; `Changes` is a
  `Text::Template` document.

Good: `- Reject undefined field names instead of silently ignoring them.`

Exceptional second sentence: `- Rename foo() to bar(). The old name remains as a deprecated alias.`

## Comments

Comments are a middle ground: humans and agents both read them, but they live
with maintained code and must justify that cost.

- **Default: no comment.** Do not write or keep a comment that merely restates
  the code, labels an obvious operation, or adds no significant value.
- A useful comment records a non-obvious reason, hidden constraint, subtle
  invariant, necessary workaround, surprising behavior, or durable external
  contract.
- Write the reason, not the investigation. Record a rejected path only when
  the deviation is critical and likely to be mistakenly reversed.
- Be as brief as the point allows. One line is usual; two or three are fine
  when the reason genuinely needs them. A paragraph is a signal to cut the
  comment or move the explanation to appropriate documentation.
- Each comment stands alone. Do not write "as above", "see below", or another
  reference to a separate comment.
- Do not use comments as a changelog: no "added for", "removed", issue
  history, or temporary merge notes.
- Use the `Agent Note:` prefix when the context is primarily for a future
  agent.
- Use POD rather than a comment block to explain what a callable is for, how
  to call it, or its inputs and outputs. Keep implementation reasoning in a
  justified comment.

A comment may reference documentation only when the target is a Markdown
document and all of these are true:

- The reference is necessary to the comment's value.
- The target is tracked and committed no later than the comment; landing both
  in the same commit is acceptable.
- The reference gives the full repository-relative path and exact section.
- When the target is AI/agent-facing, the comment explicitly labels it as an
  AI/agent document.

For example:

```perl
# AI/agent document: AI_DOCS/2026-08-08-cache-layout.md, "Rejected shared cache".
```

Never reference an uncommitted Markdown document or a non-Markdown AI/agent
document from maintained code.

## POD

- Every shipped `.pm` file has POD. Start from the project's `TEMPLATE.pod`
  (shared canonical copy: `~/projects/Agents/templates/TEMPLATE.pod`) and
  remove sections that do not apply.
- Describe behavior the reader cannot infer from the signature, normally in
  one or two sentences. Do not retell the module for every method.
- Put shared explanation in `DESCRIPTION` once and keep method and export
  entries short.
- Include `ATTRIBUTES` for `Object::HashBase`-style classes.
- Keep implementation detail out unless a caller would be surprised, such as
  an important side effect.
- POD must not reference any `.md` file or any AI/agent document, even when
  that document is committed, public, or otherwise available to the reader.
  Restate necessary behavior in the POD or omit the reference.
- `podchecker` must report zero errors and zero warnings.

POD placement and section ordering are Perl layout rules; see
`PERL_STYLE_GUIDE.md` under "POD".

## AI task documents

`AI_DOCS/` holds durable agent context that code and commit history cannot
carry on their own. **Default: do not write one.** Write one only for:

- A significant new feature.
- An architectural change, such as process topology, schema layout, lifecycle
  contracts, or module boundaries with real design weight.
- A non-trivial refactor that changes module boundaries, public interfaces,
  or coding patterns across multiple files.

Do not write one for:

- A bug fix. If it contradicts or extends an existing AI task document or
  `ARCHITECTURE.md`, update that document in place; otherwise the commit
  message is the only record.
- Test-only work.
- Trivial cleanup such as typos, whitespace, formatting, or comment tweaks.

When warranted, record what triggered the work, the decisions made, relevant
alternatives and why they were rejected, and architectural changes. This is
the appropriate place for useful roads-not-taken context that would burden a
human-facing commit message or user document.

Name the file `AI_DOCS/<YYYY-MM-DD>-<short-slug>.md`.

A deviation from `ARCHITECTURE.md` must also be recorded as an addendum to
that document, with the deviation and its reason. This is critical decision
context, not an invitation to list every option considered.
