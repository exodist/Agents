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

## 2026-08-15 — The AI/LLM policy is rewritten, and is now Markdown

**Action: delete `AI_AND_LLM_POLICY.txt`, copy `AI_AND_LLM_POLICY.md` from
this repository, and let the distribution ship it.**

The policy was rewritten end to end and changed filename. A distribution
excludes every internal `.md`, so this one is gathered back by name — add to
`dist.ini`, after the `t/` re-gather block:

    [GatherFile]
    filename = AI_AND_LLM_POLICY.md

Then confirm the built tarball contains it. Check `MANIFEST.SKIP` too if the
project keeps `.md` patterns there.

What changed in substance, beyond the rewrite:

- **Two goals, stated as two.** The humans who maintain the code later must be
  able to understand it, and the burden that externally submitted AI/LLM work
  places on the core maintainers has to stay manageable. The policy manages
  that burden rather than certifying a repository-wide standard, so core
  maintainers are not bound by it and a maintainer who works differently is
  not being a hypocrite.
- **Bot and AI accounts stay out of tickets and pull requests.** Two narrow
  exceptions: a complete, clearly labeled initial bug report — welcome, and
  especially for security issues — and a restricted-availability model
  answering on a security ticket when a human directly asks it to. The rule
  restricts who takes part, not what wrote the code; a human may submit
  AI-assisted work and then does the discussing themselves.
- **Noting AI use no longer points at bot usernames.** Notes go in the commit
  message, pull request description, or ticket, and exist to give maintainers
  a rough, unmeasured sense of how much incoming work is AI generated. The
  thresholds for what does and does not need noting are unchanged, as is the
  rule against using any of it to attack a contributor.
- **Trust is stated as a path.** Contributors who prove they will stick around
  get more leeway, up to becoming core maintainers, revocable if their work
  becomes unmaintainable.
- **Training on the code is permitted.** A new section grants permission to
  use the project's source and documentation as AI/LLM training data, on top
  of whatever its license already allows, excluding bundled third-party code.
  A project that does not want to grant this must declare its own policy.

A project that declares its own policy in `AGENTS_OVERRIDE.md` keeps that one,
but should decide whether it wants these positions.

## 2026-08-15 — The Agents checkout location is a project choice

**Action: replace the bootstrap stanza in the project's `AGENTS.md` with the
current one from `templates/AGENTS.md`.**

The old stanza told the agent to clone the repository on its own initiative
and assumed `~/projects/Agents`. The current one resolves a declared location
first, and stops to ask the user rather than cloning. A project whose checkout
is not at `~/projects/Agents` also adds the optional "Agents repository
location" section to `AGENTS_OVERRIDE.md` and rewrites the absolute paths it
spells out for itself, the `agent-test-lock` command most often.
