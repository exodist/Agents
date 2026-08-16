# AGENTS.md

## MANDATORY: read the universal agent rules first

This project opts into shared agent guidance while keeping its own documents
authoritative for project-specific rules and design.

- Repository: `git@github.com:exodist/Agents.git`
- Default location: `~/projects/Agents`
- This project's location: as declared in `AGENTS_OVERRIDE.md` under "Agents
  repository location", when that section is present.

Use the declared location when there is one, otherwise the default. If no
checkout is there, **stop and ask the user** whether to clone it and where.
Never clone it for them, and never guess a location.

Shared documents spell their paths against the default location. When this
project declares another, read every such path against the declared one.

Then read `AGENTS.md` in that checkout and follow the shared guidance this
project has adopted. It points at task-specific guides and procedures.

All documents in THIS repository take priority over the shared repository.
Read the project documents named below; `AGENTS_OVERRIDE.md` records
declarations and explicit shared-rule overrides when present.

<!--
  Everything above is verbatim boilerplate -- do not edit it.
  Everything below is this project's own content.

  Follow ~/projects/Agents/DOCUMENTATION.md. Keep only project-specific
  context here; record deliberate shared-rule differences in
  AGENTS_OVERRIDE.md.
-->

---

## What this project is

<!-- State what it does and any scope boundary a future agent must know. -->

CPAN distribution name: `Dist-Name`

<!-- If the directory name differs from the distribution name, say so and say
     why -- agents otherwise assume one from the other. -->

---

## Canonical sources of truth

1. **`ARCHITECTURE.md`** — authoritative spec for this project.
2. **`AGENTS_OVERRIDE.md`** — this project's declarations and overrides.
3. **This file** — project context and conventions.

If you are about to implement something that seems to conflict with
`ARCHITECTURE.md`, stop and verify. The usual cause is that the other document
is stale — follow `ARCHITECTURE.md` and flag the inconsistency.

---

<!--
## Reference trees

  MOST PROJECTS HAVE NONE. Delete this whole section unless the project
  really does keep earlier iterations in-tree to read against -- an empty or
  speculative heading sends agents hunting for something that is not there.

  Where one exists: name each subtree and say what it is good for. The
  universal rule (never modify one in place; copy out and modify the copy)
  applies automatically and does not need restating here.
-->

---

## Testing

```
~/projects/Agents/bin/agent-test-lock -- prove --timer -Ilib -j16 -r t/
```

<!-- Rewrite the path above if AGENTS_OVERRIDE.md declares another location. -->

<!-- Project specifics only: extra environment variables, a second command
     that must also pass, expected suite duration, the right timeout, known
     slow files, database flavors exercised, and every non-Perl suite. -->

---

<!--
## Related repositories

- Path or distribution name, the shared interface or prerequisite contract,
  and exactly which changes require checking the related repository.

Delete this section when the project has no such relationship.
-->

---

## Project-specific pre-review gates

Beyond the three universal passes in `~/projects/Agents/AGENTS.md`, this
project also requires:

<!-- e.g. `perl agent_scripts/audit-<something> lib`, and what it enforces.
     Delete the section if there are none. -->

---

## Architecture quick-reference

Foundational rules an agent must internalise before writing any code here:

- `Object::HashBase` for objects; `Role::Tiny` for roles. They compose.
- `parent` for inheritance, not `base`.
- <!-- the project-specific ones that agents actually trip on -->
