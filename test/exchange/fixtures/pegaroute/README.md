# Pegaroute fixtures

Contract target: **v0.5.3**. Updating this label is not a new compatibility audit,
runtime check or deployment claim; no endpoint or catalog content changes follow.

The reference synthetic codec fixtures were originally audited against Pegasus
`74e2cd8d9dbb71f0b5cd29bd5193d0182346dd34` (2026-09-09), with the last compatibility
review at `177d6891aada4659ca9d24cf3de8cb336ce31442` (2026-09-14).
These historical identifiers remain provenance, not proof of the target version.
The R5 port retains selected codec fixtures and adapts caller fixtures to its
provider-owned record/store architecture. Decoding does not authorize funding.

Wire authorities include `src/server/openapi/schemas.ts`,
`src/server/swaps/{schemas,handlers,mappers,execution}.ts`, and
`src/shared/private-mode.ts`. Tests use offline transport/wallet doubles; they do
not place orders, sign transactions, broadcast or prove native integration.
