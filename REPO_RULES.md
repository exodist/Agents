# REPO_RULES.md

Rules that apply to **this repository only** — `~/projects/Agents` itself.

These are not universal rules. A project consuming this repository does not
inherit them; it follows `AGENTS.md`, `PERL_STYLE_GUIDE.md`, and the rest.
Read this file when you are editing `~/projects/Agents`.

---

## Work directly on `master` unless the owner asks for a worktree

This is an agent-guidance and tooling repository, not a consuming Perl
distribution. The shared worktree selection and commit-count merge rules in
`AGENTS.md` are for projects that adopt this repository; they do not govern
work on this repository itself.

- Default to making changes directly on `master`.
- Worktrees are rare here. Create one only when the owner explicitly asks for
  one, and place it under `<repository-root>/worktrees/<worktree-name>`.
- Do not choose fast-forward versus merge-commit integration from the number
  of branch commits. Follow the owner's explicit integration direction.
- The general rule still applies: never merge, push, or delete the branch or
  worktree unless the owner asks.

---

## Documentation-only changes may skip independent review

This repository does not require the independent review cycle in
`CODE_REVIEW.md` for a change that touches documentation only. Consuming
projects do not inherit this exception. An explicit user request for review,
including a multi-model review, still applies.

---

## No credentials, no secrets, ever

This repository is public-by-intent and gets cloned onto every machine that
does agent work. **Nothing sensitive goes in it. No exceptions.**

Never commit:

- Passwords, passphrases, PINs.
- API keys, access tokens, refresh tokens, session cookies, bearer tokens.
- Private keys of any kind — SSH, GPG, TLS, JWT signing keys, `*.pem`,
  `*.key`, `id_rsa*`, keystores.
- `.env` files, `.netrc`, `.pgpass`, `.my.cnf`, `credentials`, `auth.json`,
  `.credentials.json`, cloud credential files.
- Database connection strings that carry a password.
- Internal hostnames, IP addresses, or URLs that are not meant to be public.
- Anything copied out of `~/.claude`, `~/.codex`, `~/.ssh`, `~/.aws`,
  `~/.config`, or a browser profile.
- Personal data about anyone other than the repository owner.

Not sensitive, and fine to keep here:

- The owner's published CPAN contact addresses (`exodist7@gmail.com`,
  `exodist@cpan.org`) — they appear in every shipped module's POD and in the
  LICENSE.
- The repository's own clone URL.
- Paths that describe the local convention (`~/projects`, `~/dbs`) with no
  contents attached.

### When an example needs to look like a secret

Use an obvious placeholder that cannot be mistaken for a real value:
`<API_KEY>`, `password=REDACTED`, `dbi:Pg:...;password=<PASSWORD>`. Never
paste a real value and never paste a "revoked" or "expired" one — a value that
looks real gets treated as real by the next reader, and revocation is not
always what someone believed it was.

### Before every commit here

```
perl ~/projects/Agents/agent_scripts/audit-no-secrets
```

It scans for key material, credential-shaped assignments, high-entropy blobs,
credential filenames, and non-text files. A hit is a hard stop.

Also glance at `git diff --cached` before committing. The scanner catches
shapes; a human catches meaning.

### If something sensitive does land

Assume it is compromised the moment it is committed, whether or not it was
pushed.

1. **Rotate the credential first.** Revoke and reissue it at the source.
   Removing it from git history does not un-leak it.
2. Tell the repository owner. Do not quietly rewrite history and move on.
3. Only then discuss history rewriting — and that is the owner's call, not an
   agent's. Never run `git filter-branch`, `git filter-repo`, or a force-push
   here without being explicitly asked.

---

## No project content

Content specific to one project belongs in that project, not here. If you find
yourself writing "in DBIx-QuickORM, ..." into a universal document, it belongs
in that project's `AGENTS.md` or `AGENTS_OVERRIDE.md` instead.

The exception is an illustrative example — naming a real project to show what a
rule looks like in practice is fine, as long as the rule itself is general.

---

## Rules leave choices open on purpose

When two projects legitimately disagree about a rule, the answer is **not** to
pick a winner and force the other to change. Mark the rule
**`[project-declared]`**, document each mode fully, and let
`AGENTS_OVERRIDE.md` pin it per project. See `USING.md`.

A rule that a project silently ignores is worse than a rule with two
documented modes.

---

## Changing a rule is its own commit

Never edit `~/projects/Agents` as a side effect of working in another project.
A rule change is a separate task, in this repository, in its own commit, with a
message explaining what changed and why.

If project work reveals that a universal rule is wrong, say so and stop.
Changing the rule mid-task means the work you are reviewing was done under one
rule and judged under another.

---

## Changes that require project action are recorded in `SYNC.md`

Most changes here need nothing from adopting projects: they reference these
rules, so a reworded rule reaches them the moment it lands. Some do require
action — re-copying a file the project holds, editing one of its documents,
answering a new declaration, making a ruling. **Those write a `SYNC.md` entry
in the same commit**, naming what changed and the exact action a project
takes.

That entry is what a project's session-start check shows its user. A missing
one is recoverable — add it in a later commit and every project that has not
yet synced past it still sees it — but the user who hit the gap in between
does not get told.

Changes to `AI_AND_LLM_POLICY.txt`, `templates/`, and `agent_scripts/` are
caught by the check whether or not they have an entry, because projects hold
copies of those. Write the entry anyway when the action is not obvious from
the commit subject.

---

## Auditors stay in sync

`agent_scripts/` here is canonical. Projects hold copies. When an auditor needs
fixing, fix it here first, then re-copy into the projects that carry it — never
the reverse, and never only in the project.

A mechanical bug fix may be copied after its canonical tests pass. A semantic
change to what an auditor accepts or rejects requires review against each
consumer's local policy before it is copied; do not silently turn a new shared
opinion into a project gate.
