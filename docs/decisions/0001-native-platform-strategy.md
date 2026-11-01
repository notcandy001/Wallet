# 0001 Native platform strategy
Status: accepted. Swift/SwiftUI for iOS, Kotlin/Compose for Android. Share specs, fixtures and contracts, not runtime code. Reason: security-sensitive and platform-feel concerns outweigh code sharing at this size. Domain code sits in a separate Swift package so it can be tested without UI.
