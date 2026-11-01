# Instructions for AI agents working on Wallet
- Be evidence-based: never report a build, test or feature as done unless it was actually run. Use the statuses in docs/ROADMAP.md.
- Trust levels (sample/custom/imported/verified/payment) must never be converted implicitly. Drafts can only create `.custom` passes.
- No real payments, no fake official credentials, no secrets in Git or QR payloads.
- Domain rules live in `WalletCore` and are tested there; keep business logic out of SwiftUI views.
- Brand name only via `Brand.name`; colours/spacing/motion via `DesignSystem/Tokens.swift`.
- Ask before: publishing, spending money, registering services, real personal data, real transactions.
- Update docs/ROADMAP.md at the end of each work session.
