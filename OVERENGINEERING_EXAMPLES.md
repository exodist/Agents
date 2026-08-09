# Over-engineering examples

These are short examples of owner rulings where additional machinery was not
worth its likely value. Use them to calibrate plans, reviews, and decision-mode
recommendations so that similarly disproportionate work is identified and
raised for an owner decision.

These examples are not universal prohibitions or substitutes for the current
project's requirements. Compare the concrete benefit and cost in the case at
hand; do not decide a new tradeoff merely because it resembles an example.

## Unlikely method and field-name collisions

- **Situation:** Generated row accessors named `touch` or `touch_cas` can mask
  native methods with the same names.
- **Ruling:** Do not reserve the names, add collision detection, or emit a
  warning. Document the ambiguity, recommend aliasing those fields, retain
  generic field access, and show fully qualified native method calls as the
  escape hatch.
- **Why:** The names are unlikely as fields, affected callers can still reach
  both meanings, and a general collision system would cost more than the edge
  case warrants.

## New plugin machinery without a demonstrated gap

- **Situation:** A compatibility experiment proposed a runtime action
  dispatcher, action priorities, bypass controls, late loading, registries,
  and a generic alternate-class hook.
- **Ruling:** Prove the existing build-time plugin, subclass, mixin, and result
  selection seams first. Add a production hook only after a concrete use case
  demonstrates the smallest missing seam.
- **Why:** A new extension subsystem would maintain speculative flexibility
  that existing mechanisms might already provide.

## Complete compatibility instead of practical migration

- **Situation:** Easing migration from another ORM could grow into drop-in
  wrappers, universal result rewriting, complete method emulation, and
  speculative core seams.
- **Ruling:** Accept mechanical source changes and occasional manual migration.
  Add optional conveniences only where common behavior remains maintainable.
- **Why:** Rare compatibility cases do not justify making the new system carry
  another framework's complete contract.

## Cross-producer query transplantation

- **Situation:** Mixing independently rendered query producers would require a
  neutral correlation context, execution envelopes, bind remapping, a
  producer-pair capability matrix, and extensive pairwise conformance tests.
- **Ruling:** Require the inner and outer query to use the exact same producer
  instance. Revisit only if a concrete important use case cannot fit that
  boundary.
- **Why:** The proposed interoperability layer had a large permanent surface
  without demonstrated user value.

## A compile-time helper instead of a language extension

- **Situation:** A standalone table declaration feature could have used a
  parser keyword, source filter, XS, namespace-cleaning dependency, or
  end-of-scope framework.
- **Ruling:** Use a small compile-time import helper with exact cleanup and the
  language's ordinary warning behavior.
- **Why:** The narrow helper delivered the requested syntax and namespace
  behavior without a parser or dependency subsystem.

## Exact database-name comparison with actionable guidance

- **Situation:** MySQL may normalize database-name case, which could be
  accommodated by probing server settings and adding comparison modes.
- **Ruling:** Keep exact comparison. Explain the normalization in diagnostics
  and tell callers to use the spelling reported by the server.
- **Why:** A configuration probe and alternate matching policy added complexity
  where a clear contract and corrective message were sufficient.

## Lazy observation of database-generated fields

- **Situation:** Omitted database-generated fields could be observed eagerly
  by enlarging every `RETURNING` clause or forcing a follow-up query.
- **Ruling:** Mark the value unknown and let explicit refresh APIs or later
  field access load it unless the current write already returns trusted data.
- **Why:** Mandatory eager reads would add query and implementation cost to all
  writes to solve a need that can be handled on demand.
