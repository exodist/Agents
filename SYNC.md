# SYNC.md

Changes here that require an adopting project to do something. A project
compares this file against the commit it last synced with and acts on
whatever is newer.

Most changes in this repository need no entry. Projects reference these rules
rather than copying them, so a reworded rule reaches every project the moment
it lands. An entry is warranted when a project must **do** something: re-copy
a file it holds, change one of its own documents, answer a new declaration, or
make a ruling.

Newest first. Each entry gives the date, what changed, and the exact action a
project takes. A change requiring project action writes its entry in the same
commit — see `REPO_RULES.md`.

Reading it as an agent: `git diff <last-synced-sha>..HEAD -- SYNC.md` in this
repository yields exactly the entries added since that project last synced.
Present those actions to the user; do not apply them unasked.

---

## 2026-08-15 — Record the commit you last synced with

**Action: add a `Last synced` line to the bootstrap stanza in the project's
`AGENTS.md`, and check for pending syncs at the start of every session.**

The stanza gains a bullet beside the repository and location:

    - Last synced: <40-character commit sha> (YYYY-MM-DD)

Use the commit this sync brings the project up to. `audit-project-wiring`
reports a missing or unparseable line as `WIR108`.

The session-start check and the procedure for applying a pending sync are in
`AGENTS.md` under "Staying in sync"; `skills/perl-project-align/SKILL.md` has
the short form. A project adopting this repository for the first time records
the current commit and has nothing to apply.

## 2026-08-15 — The policy says whose burden it manages

**Action: re-copy `AI_AND_LLM_POLICY.txt` from this repository.**

"Who these rules are for, and how strict they are" now states that the policy
manages what an outside contribution asks of the core maintainers rather than
setting a standard the repository is held to, and that a maintainer working
differently is not being a hypocrite. A project that declares its own policy
should decide whether it wants the same framing.

## 2026-08-15 — Bot accounts are barred from tickets and pull requests

**Action: re-copy `AI_AND_LLM_POLICY.txt` from this repository.**

The policy gained a "Tickets and pull requests are for humans" section and a
matching TL;DR line. A project keeps its copy byte-for-byte current unless
`AGENTS_OVERRIDE.md` declares a different policy, in which case check whether
the local policy wants the same rule.

## 2026-08-15 — The Agents checkout location is a project choice

**Action: replace the bootstrap stanza in the project's `AGENTS.md` with the
current one from `templates/AGENTS.md`.**

The old stanza told the agent to clone the repository on its own initiative
and assumed `~/projects/Agents`. The current one resolves a declared location
first, and stops to ask the user rather than cloning. A project whose checkout
is not at `~/projects/Agents` also adds the optional "Agents repository
location" section to `AGENTS_OVERRIDE.md` and rewrites the absolute paths it
spells out for itself, the `agent-test-lock` command most often.
