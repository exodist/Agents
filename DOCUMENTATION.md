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
- Keep one authoritative explanation. Point to it when the intended reader
  can access it; do not maintain several copies that can drift.
- Prefer plain language, short sentences, and a structure the intended reader
  can scan quickly.
- No emojis.

## Audience and references

The intended audience determines the rules, not the filename or file type.
For example, an AI contribution policy written for human contributors is
human-facing even though its subject is AI.

### Human-facing material

Human-facing material includes user and contributor documentation, README
files, POD, command descriptions and help, diagnostics, `Changes`, and commit
messages.

- It must stand on its own or reference other human-facing material that its
  audience can actually access.
- It must not reference AI/agent-only plans, reviews, findings, decision
  ledgers, prompts, or working documents.
- When an internal rule matters to the human reader, state the necessary
  behavior briefly in human terms. When it does not matter, omit it.
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
reference one another and may record alternatives, roads not taken, and the
reasons choices were rejected when that context will help later work.

They must still be readable, relevant, and no more verbose than their purpose
requires. Prefer a specific reference to an authoritative explanation over a
duplicated rule. A committed document must not leave a dangling reference to
an uncommitted working file.

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
- Never write `#` followed by digits; GitHub interprets it as an issue link.

## `Changes` entries

- Describe shipped behavior in user-facing terms, not implementation work or
  agent process.
- Keep each bullet to one line and one sentence where possible, two sentences
  at most.
- State what changed. Mention what did not change only when it is an important
  compatibility guarantee or other critical user information.
- Do not put a literal `{{` or `}}` inside a bullet; `Changes` is a
  `Text::Template` document.

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

A comment may reference a committed human-facing document using its full
repository-relative path and a specific section.

A comment may also reference an AI/agent document only when all of these are
true:

- The reference is necessary to the comment's value.
- The document is tracked and committed no later than the comment; landing
  both in the same commit is acceptable.
- The comment explicitly labels the target as an AI document.
- The reference gives the full repository-relative path and exact section.

For example:

```perl
# AI document: AI_DOCS/2026-08-08-cache-layout.md, "Rejected shared cache".
```

Never reference an uncommitted AI/agent document from maintained code.

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
- POD is human-facing. It must not reference AI/agent-only documents or an
  internal Markdown file that will not be available to the POD reader.
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
