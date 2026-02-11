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

```dart
dart pub add universal_ffi
```

or

```dart
flutter pub add universal_ffi
```

### Generate binding files

Generates bindings using [`package:ffigen`](https://pub.dev/packages/ffigen).
Replace `import 'dart:ffi' as ffi;` with `import 'package:universal_ffi/ffi.dart' as ffi;` in the generated binding files.

### Using FfiHelper

```dart
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

* Web: 'path/name.js' or 'path/name.wasm' (if `isStandaloneWasm` option is specified)
* Linux & Android: 'path/name.so'
* Windows: 'path/name.dll'
* macOS & iOS: 'path/libname.dylib'

#### Option: isStaticallyLinked

If the modulePath = 'path/name' and `isStaticallyLinked` option is specified, then the following paths are used:

* Web: 'path/name.js' or 'path/name.wasm' (if `isStandaloneWasm` option is specified)
* All other platforms: Instead of loading a shared library, calls DynamicLibrary.process().

#### Option: isFfiPlugin (used for Flutter Ffi Plugin)

If the modulePath = 'path/name' and `isFfiPlugin` option is specified, then 'path' is ignored and the following paths are used:

* Web: 'assets/packages/name/assets/name.js' or 'assets/packages/name/assets/name.wasm' (if `isStandaloneWasm` option is specified)
* Linux & Android: 'name.so'
* Windows: 'name.dll'
* macOS & iOS: 'name.framework/name'

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

## 📦 Creating a Plugin

### Naming the Plugin/Module

When creating a plugin, choice of `moduleName` is critical. It should be consistent across:

1. **Usage**: `FfiHelper.load('moduleName')`.
2. **Files**: Output filenames (e.g., `libmoduleName.so`, `moduleName.dll`, `moduleName.wasm`).
3. **Emscripten**: The `EXPORT_NAME` for Emscripten builds.
4. **Flutter Plugin**: For Flutter FFI plugins, the `moduleName` **MUST** match the package name specified in `pubspec.yaml`. This enables correct asset resolution (`assets/packages/moduleName/...`).

### Creating a Dart Plugin (see `example`)

To create a pure Dart plugin that works on all platforms (including web):

1. **Project Structure**:
    * `src/`: Contains your C/C++ source code.
    * `lib/`: Dart code and generated bindings.
    * `web/assets/`: Recommended location for compiled WASM/JS modules.
    * `assets/`: Location for compiled dynamic libraries (optional).

2. **Build Native Assets**:
    * Compile `src/` to shared libraries (`.so`, `.dylib`, `.dll`) for desktop platforms.
    * Compile `src/` to WASM/JS for web (see [WASM Compilation](#wasm-compilation)).

3. **Usage**:

    ```dart
    final ffiHelper = await FfiHelper.load('web/assets/emscripten/moduleName');
    // or just 'moduleName' if assets are in root logic
    ```

### Creating a Flutter FFI Plugin (see `example_ffi_plugin`)

To create a Flutter FFI plugin that includes Web support:

1. **Project Structure**:
    Follow the [standard Flutter FFI plugin structure](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms).
    * `src/`: C/C++ source code.
    * `assets/`: Place compiled WASM/JS modules here.

2. **Build Native Assets**:
    * **Mobile/Desktop**: Use `CMakeLists.txt` and `pubspec.yaml` as per standard Flutter plugin development.
    * **Web**: Manually compile WASM/JS assets and place them in `assets/`.

3. **pubspec.yaml**:
    Ensure your `assets/` folder is included:

    ```yaml
    flutter:
      assets:
        - assets/
    ```

4. **Usage**:

    ```dart
    // Must match package name
    final ffiHelper = await FfiHelper.load('moduleName', options: {LoadOption.isFfiPlugin});
    ```

### WASM Compilation

To support Web, you must compile your C code using `emcc` (Emscripten). A plugin should support **either** Emscripten JS **or** Standalone WASM, not both simultaneously config-wise.
The examples illustrate both for completeness, but you should choose one.

#### Option 1: Emscripten JS (Recommended)

This generates a `.js` file that loads the `.wasm` file. This is generally more compatible.

**Command:**

```bash
emcc -o path/to/moduleName.js \
    src/native_code.c \
    -O3 \
    -s MODULARIZE=1 \
    -s 'EXPORT_NAME="moduleName"' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s ENVIRONMENT='web,worker' \
    -s EXPORTED_RUNTIME_METHODS=HEAPU8 \
    -s EXPORTED_FUNCTIONS='["_malloc", "_free", "_your_function"]'
```

**Crucial:** You **MUST** include `-s EXPORTED_RUNTIME_METHODS=HEAPU8`. This exports the memory object so `universal_ffi` can access it.

#### Option 2: Standalone WASM

This generates a single `.wasm` file without glue JS.

**Command:**

```bash
emcc -o path/to/moduleName.wasm \
    src/native_code.c \
    -O3 \
    -s STANDALONE_WASM=1 \
    -s ENVIRONMENT='web,worker' \
    -s EXPORTED_FUNCTIONS='["_malloc", "_free", "_your_function"]'
```

**Crucial:** You **MUST** include `--export=__wasm_call_ctors` if you are using C++ to ensure static constructors run.

#### Naming Convention

* **Emscripten JS**: Output `moduleName.js` (and `moduleName.wasm` will be generated next to it).
* **Standalone WASM**: Output `moduleName.wasm`.

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
[universal_ffi_pub_url]: https://pub.dev/packages/universal_ffi
[universal_ffi_pub_score_url]: https://pub.dev/packages/universal_ffi/score
