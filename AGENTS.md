# Agent Guide for universal_ffi

## Project overview
`universal_ffi` is a cross-platform Dart library providing a unified Foreign Function Interface (FFI) abstraction across native platforms (via `dart:ffi` / `package:ffi`) and the web (via `wasm_ffi`). It enables pure Dart packages and Flutter FFI plugins to write portable C/C++ interop code and load platform-specific dynamic libraries (`.so`, `.dylib`, `.dll`, `.wasm`, `.js`) with unified helpers.

## Repository map
- `lib/` — Public package entry points (`ffi.dart`, `ffi_helper.dart`, `ffi_utils.dart`).
- `lib/src/dart_ffi/` — Native platform implementations backed by `dart:ffi` and `package:ffi`.
- `lib/src/wasm_ffi/` — Web implementations backed by `wasm_ffi`.
- `test/` — Unit, integration, and path resolution test suites.
- `example/` — Pure Dart CLI and web example project demonstrating `universal_ffi` usage and bindings.
- `example_ffi_plugin/` — Flutter FFI plugin example showing multi-platform C/C++ builds with Emscripten and CMake.
- `tool/update-version.sh` — Interactive versioning, changelog update, and release preparation script.
- `.github/workflows/ci.yml` — Continuous integration testing and validation workflow.
- `.github/workflows/publish.yml` — Workflow triggered on `pubspec.yaml` version updates for analysis, testing, and automated publishing.

## Working commands
- Setup / Dependencies: `dart pub get`
- Static Analysis / Lint: `dart analyze`
- Tests: `dart test`
- Package Validation: `dart pub publish --dry-run`
- Version Management: `make version` (or `bash ./tool/update-version.sh`)
- Build Example Plugin Assets: `make build` (in `example_ffi_plugin/`)
- Run Web Example: `make run-web` (in `example/` via `webdev serve`)
- Run Native Example: `make run-ffi` (in `example/` via `dart run`)

## Engineering constraints
- Follow KISS and YAGNI; keep the core wrapper minimal and focused on bridging `dart:ffi` and `wasm_ffi`.
- Preserve conditional export separation (`dart.library.ffi` vs Web/WASM) across `lib/ffi.dart`, `lib/ffi_utils.dart`, and `lib/ffi_helper.dart`.
- `wasm_ffi` does not support `Array`, `Struct`, and `Union`; preserve compatibility constraints and do not introduce dependencies on unsupported constructs.
- Use `FfiHelper.safeUsing` or `FfiHelper.safeWithZoneArena` when multiple WASM modules are involved to prevent allocator collisions across module boundaries.
- Respect `LoadOption` conventions (`isStaticallyLinked`, `isFfiPlugin`, `isStandaloneWasm`) in `resolveModulePath`. Note that statically linked libraries (`DynamicLibrary.process()`) are unsupported on Web.

## Context discipline
- Start with targeted search and the repository map before opening files.
- Read only files relevant to the task and follow linked documentation as needed.
- Do not load generated files, `.dart_tool/`, `.vscode/`, or compiled native/WASM binaries unless diagnosing build or asset packaging issues.

## Documentation routing
- User setup, usage guide, and plugin development: [`README.md`](README.md)
- Release history: [`CHANGELOG.md`](CHANGELOG.md)

## Definition of done
- Static analysis passes with no issues: `dart analyze`.
- Package dry-run validation passes with zero warnings: `dart pub publish --dry-run`.
- Public APIs and conditional exports maintain parity across native and web targets.
- Only documentation made inaccurate by the change was updated.

## Documentation maintenance
- Update `AGENTS.md` only when agent workflow, verified commands, navigation, or architectural constraints change.
- Update `README.md` only when user-facing setup, API capabilities, plugin guides, or requirements change.
- Update `CHANGELOG.md` when preparing a new package release.
