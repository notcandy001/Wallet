# Product specification (implemented rules, v0.1)
- **Categories:** loyalty, membership, event ticket, boarding pass, general, document reference, card (visual only).
- **Trust levels:** sample, custom, imported, verified, payment. User drafts always create `custom`. Only sample/custom passes are editable. Only `custom`/`sample` exist today; imported/verified/payment are reserved.
- **Validity:** valid from `validFrom` (inclusive) until `expiresAt` (exclusive). "Expires soon" = within 30 days. Expiry must be after start.
- **Validation:** title/issuer required, ≤ 60 chars; identifier ≤ 64 chars (letters, digits, `-_./` space); detail label ≤ 30, value ≤ 120, max 8 details; QR text ≤ 300 chars; no control characters. Over-length input is rejected, never truncated.
- **Search:** title or issuer, case- and diacritic-insensitive; category filter; sort by recently added, title or expiry (no expiry last); scope active/archived.
- **Archive:** reversible, keeps the pass. **Delete:** removes locally only; it does not revoke anything at an issuer.
- **Samples:** seeded once per install; deleting them does not bring them back.
- **Identifiers:** shown masked (last 4); reveal is per-view.
- **Export:** JSON of all local passes. **Import:** not implemented.
