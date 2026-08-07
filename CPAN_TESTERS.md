# CPAN_TESTERS.md

Read this procedure only when a task involves CPAN Testers reports. The
project's `AGENTS.md` supplies its exact CPAN distribution name; do not infer
the name from the checkout directory.

The public MCP service is `https://mcp.cpantesters.org`. Prefer connecting it
through an available MCP-capable client. It exposes these report operations:

- `list_reports_by_dist` — distribution name, with optional version and grade
  filters; results identify reports by GUID and include OS, platform, Perl,
  and grade.
- `list_dists_by_author` — PAUSE author ID, such as `EXODIST`.
- `read_report` — one report GUID, returning its full test output.

## Investigating reports

1. Confirm the distribution name in the project's local instructions.
2. List reports for the relevant distribution and narrow by version or grade
   when the task calls for it.
3. Group failures by Perl version, operating system, platform, and repeated
   error signature before opening individual reports.
4. Read representative report GUIDs from each group. Preserve the GUIDs in
   findings so another reviewer can reproduce the query.
5. Compare the failing path with the project's documented release-path test,
   prerequisites, supported Perl floor, and platform promises. A smoker
   failure is evidence to investigate, not authority to change a project
   contract.
6. Report the affected versions and environments, the common failure text in
   paraphrase, representative GUIDs, and the narrowest plausible local
   reproduction. Do not make a release or support-policy decision silently.

## Raw protocol fallback

When no MCP client supports the service's Streamable HTTP transport, use its
JSON-RPC endpoint at `/`: send `initialize`, retain the `Mcp-Session-Id`
response header, send the `notifications/initialized` notification, then send
`tools/call` requests with that session header. Responses are SSE-framed
`data:` records.

Do not copy credentials, cookies, or unrelated client configuration into a
project or into this repository. The CPAN Testers service and report data are
public; querying it should not require a secret.
