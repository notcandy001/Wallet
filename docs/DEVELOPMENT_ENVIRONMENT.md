# Development environment (recorded in the first session)
| Item | Result |
|---|---|
| OS / arch | Linux x86_64 (container) |
| Disk / RAM | ~10 GB free / ~3.9 GB |
| git | 2.43.0 |
| Java | OpenJDK 21 |
| Node / Python | 22.22 / 3.12 |
| Swift, Xcode, iOS SDK, simulators | **not available** |
| Kotlin, Gradle, Android SDK | **not available** (Java only) |
| Go, Rust | not available |
| Network | outbound HTTPS to GitHub works; other hosts restricted |

Consequences: iOS code could not be compiled or tested here; Android build tools were not installed. All Swift code is **implemented, unverified**. First action on a Mac: run `swift test` in `apps/ios/WalletCore`, then generate and build the app.
