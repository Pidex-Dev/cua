# Pidex CUA Windows runtime

This branch starts from trycua/cua commit `32b34fbc75abeb96af77df49ae0da72328e67707` (driver 0.33.0), with the Pidex host migrated from Pidex. Upstream `main` is not the Pidex release branch.

The host preserves Pidex application identities, process generations, signature verification, a narrow tool allowlist, and execution target binding. Chat authorization remains in Pidex. Native capture, snapshot validation and input remain upstream implementations.

Build: `cargo build --locked --release --target x86_64-pc-windows-msvc --manifest-path libs/cua-driver/rust/Cargo.toml -p cpx-cua`.

Verify: `pwsh -File pidex/VerifyRuntime.ps1 -Executable libs/cua-driver/rust/target/x86_64-pc-windows-msvc/release/cpx-cua.exe`.

Push a `pidex-cua-v*` tag to publish a dedicated Windows x64 release. Releases contain the EXE, SHA256SUMS, licenses, and exact source revision. Never replace a published release asset. Pidex pins both the release tag and SHA-256; no upstream or repository-wide latest selection is used.

See `licenses/` for provenance and notices. Existing identity tests read Windows system signatures but never inject desktop input.
