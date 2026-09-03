import 'dart:io' show Platform;
import 'package:test/test.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/src/dart_ffi/_ffi_helper.dart' as dart_ffi;
import 'package:universal_ffi/src/wasm_ffi/_ffi_helper.dart' as wasm_ffi;

void main() {
  group('Web path resolution', () {
    test('defaults to .js when no extension and standalone is false', () {
      final resolved = wasm_ffi.resolveModulePath('my_module', {});
      expect(resolved, equals('my_module.js'));
    });

    test('resolves to .wasm when isStandaloneWasm is set', () {
      final resolved = wasm_ffi.resolveModulePath('my_module', {
        LoadOption.isStandaloneWasm,
      });
      expect(resolved, equals('my_module.wasm'));
    });

    test('preserves existing extension .wasm', () {
      final resolved = wasm_ffi.resolveModulePath('custom/path.wasm', {});
      expect(resolved, equals('custom/path.wasm'));
    });

    test('preserves existing extension .js', () {
      final resolved = wasm_ffi.resolveModulePath('custom/path.js', {});
      expect(resolved, equals('custom/path.js'));
    });

    test('formats plugin asset path when isFfiPlugin is set', () {
      final resolved = wasm_ffi.resolveModulePath('native_example.wasm', {
        LoadOption.isFfiPlugin,
      });
      expect(
        resolved,
        equals('assets/packages/native_example/assets/native_example.wasm'),
      );
    });

    test('formats plugin asset path with inferred extension', () {
      final resolved = wasm_ffi.resolveModulePath('native_example', {
        LoadOption.isFfiPlugin,
        LoadOption.isStandaloneWasm,
      });
      expect(
        resolved,
        equals('assets/packages/native_example/assets/native_example.wasm'),
      );
    });

    test('wasm appType reports web', () {
      expect(wasm_ffi.appType, equals(AppType.web));
    });
  });

  group('Native path resolution', () {
    test('returns empty string when modulePath is empty', () {
      final resolved = dart_ffi.resolveModulePath('', {});
      expect(resolved, equals(''));
    });

    test('resolves platform-specific file name and path', () {
      final resolved = dart_ffi.resolveModulePath('path/to/native_module', {});
      if (Platform.isLinux || Platform.isAndroid) {
        expect(resolved, equals('path/to/libnative_module.so'));
      } else if (Platform.isMacOS || Platform.isIOS) {
        expect(resolved, equals('path/to/libnative_module.dylib'));
      } else if (Platform.isWindows) {
        expect(resolved, equals(r'path\to\native_module.dll'));
      }
    });

    test('resolves FFI plugin module path without directory prefix', () {
      final resolved = dart_ffi.resolveModulePath('path/to/native_module', {
        LoadOption.isFfiPlugin,
      });
      if (Platform.isLinux || Platform.isAndroid) {
        expect(resolved, equals('libnative_module.so'));
      } else if (Platform.isMacOS || Platform.isIOS) {
        expect(resolved, equals('native_module.framework/native_module'));
      } else if (Platform.isWindows) {
        expect(resolved, equals('native_module.dll'));
      }
    });

    test('native appType matches current platform', () {
      if (Platform.isLinux) {
        expect(dart_ffi.appType, equals(AppType.linux));
      } else if (Platform.isMacOS) {
        expect(dart_ffi.appType, equals(AppType.macos));
      } else if (Platform.isWindows) {
        expect(dart_ffi.appType, equals(AppType.windows));
      } else if (Platform.isAndroid) {
        expect(dart_ffi.appType, equals(AppType.android));
      } else if (Platform.isIOS) {
        expect(dart_ffi.appType, equals(AppType.ios));
      }
    });
  });
}
