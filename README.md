# universal_ffi

[![build_badge]][build_url]
[![github_badge]](https://github.com/vm75/universal_ffi)
[![universal_ffi_pub_ver]][universal_ffi_pub_url]
[![universal_ffi_pub_points]][universal_ffi_pub_score_url]
[![universal_ffi_pub_popularity]][universal_ffi_pub_score_url]
[![universal_ffi_pub_likes]][universal_ffi_pub_score_url]
[![license_badge]][license_url]

`universal_ffi` is a wrapper on top of `wasm_ffi` and `dart:ffi` to provide a consistent API across all platforms.
It also has some helper methods to make it easier to use.

`wasm_ffi` has a few limitations, so some of the features of `dart:ffi` are not supported. Most notably:
* Array
* Struct
* Union


## Usage

### Install
```
dart pub add universal_ffi
```

or
```
flutter pub add universal_ffi
```

### Generate binding files
Generates bindings using [`package:ffigen`](https://pub.dev/packages/ffigen).
Replace `import 'dart:ffi' as ffi;` with `import 'package:universal_ffi/ffi.dart' as ffi;` in the generated binding files.

### Using FfiHelper
```
import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/ffi_utils.dart';
import 'native_example_bindings.dart';

...
  final ffiHelper = await FfiHelper.load('ModuleName');
  final bindings = WasmFfiBindings(ffiHelper.library);

  // use bindings
  using((Arena arena) {
    ...
  }, ffiHelper.library.allocator);
...
```

## Features

### DynamicLibrary.openAsync()
DynamicLibrary.open is synchronous for 'dart:ffi', but asynchronous for 'wasm_ffi'. This helper method uses both asynchronously.

### FfiHelper.load()
FfiHelper.load resolves the modulePath to the platform specific path in a variety of ways.

#### Simple usage
In the case, it is assumed that all platforms load a shared library from the same relative path.
For example, if the modulePath = 'path/name', then the following paths are used:
- Web: 'path/name.js' or 'path/name.wasm' (if `isStandaloneWasm` option is specified)
- Linux & Android: 'path/name.so'
- Windows: 'path/name.dll'
- macOS & iOS: 'path/libname.dylib'

#### Option: isStaticallyLinked
If the modulePath = 'path/name' and `isStaticallyLinked` option is specified, then the following paths are used:
- Web: 'path/name.js' or 'path/name.wasm' (if `isStandaloneWasm` option is specified)
- All other platforms: Instead of loading a shared library, calls DynamicLibrary.process().

#### Option: isFfiPlugin (used for Flutter Ffi Plugin)
If the modulePath = 'path/name' and `isFfiPlugin` option is specified, then 'path' is ignored and the following paths are used:
- Web: 'assets/package/name/assets/name.js' or 'assets/package/name/assets/name.wasm' (if `isStandaloneWasm` option is specified)
- Linux & Android: 'name.so'
- Windows: 'name.dll'
- macOS & iOS: 'name.framework/name'

#### Overrides
Overrides can be used to specify the path to the module to be loaded for specific [AppType].
Override strings are used as is.

#### Multiple wasm_ffi modules in the same project
If you have multiple wasm_ffi modules in the same project, the global memory will refer only to the first loaded module.
So unless the memory is explicitly specified, the memory from the first loaded module will be used for all modules, causing unexpected behavior.
One option is to explicitly use library.allocator for wasm & malloc/calloc for ffi.
Alternatively, you can use FfiHelper.safeUsing or FfiHelper.safeWithZoneArena:

#### FfiHelper.safeUsing()
`FfiHelper.safeUsing` is a wrapper for `using`. It ensures that the library-specific memory is used.

#### FfiHelper.safeWithZoneArena()
`FfiHelper.safeWithZoneArena` is a wrapper for `withZoneArena`. It ensures that the library-specific memory is used.

---

Contributions are welcome! 🚀

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_url]: https://github.com/vm75/universal_ffi/blob/main/LICENSE

[build_badge]: https://img.shields.io/github/actions/workflow/status/vm75/universal_ffi/.github/workflows/publish.yml?branch=main
[build_url]: https://github.com/vm75/universal_ffi/actions

[github_badge]: https://img.shields.io/badge/github-gray?style=flat&logo=Github

[universal_ffi_pub_ver]: https://img.shields.io/pub/v/universal_ffi
[universal_ffi_pub_points]: https://img.shields.io/pub/points/universal_ffi
[universal_ffi_pub_popularity]: https://img.shields.io/pub/popularity/universal_ffi
[universal_ffi_pub_likes]: https://img.shields.io/pub/likes/universal_ffi
[universal_ffi_github_url]: https://github.com/vm75/universal_ffi
[universal_ffi_pub_url]: https://pub.dev/packages/universal_ffi
[universal_ffi_pub_score_url]: https://pub.dev/packages/universal_ffi/score