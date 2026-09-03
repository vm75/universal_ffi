@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/ffi_utils.dart';

typedef Add32Native = Uint32 Function(Uint32 a, Uint32 b);
typedef Add32Dart = int Function(int a, int b);

typedef Add64Native = Uint64 Function(Uint64 a, Uint64 b);
typedef Add64Dart = int Function(int a, int b);

typedef DerefU8Native = Uint8 Function(Pointer<Uint8> ptr);
typedef DerefU8Dart = int Function(Pointer<Uint8> ptr);

typedef WriteU8Native = Void Function(Pointer<Uint8> ptr, Uint8 val);
typedef WriteU8Dart = void Function(Pointer<Uint8> ptr, int val);

void main() {
  group('Web standalone Wasm integration', () {
    late FfiHelper helper;

    setUpAll(() async {
      try {
        helper = await FfiHelper.load(
          'standalone_test_module.wasm',
          options: {LoadOption.isStandaloneWasm},
        );
      } catch (e) {
        helper = await FfiHelper.load(
          'test/standalone_test_module.wasm',
          options: {LoadOption.isStandaloneWasm},
        );
      }
    });

    test('add32 32-bit integer addition', () {
      final add32 = helper.library.lookupFunction<Add32Native, Add32Dart>(
        'add32',
      );
      expect(add32(10, 20), equals(30));
    });

    test('add64 64-bit integer addition', () {
      final add64 = helper.library.lookupFunction<Add64Native, Add64Dart>(
        'add64',
      );
      expect(add64(100, 200), equals(300));
      // Large 64-bit value test (BigInt path in wasm_ffi 2.4.0)
      final a = 4294967296; // 2^32
      final b = 4294967296;
      expect(add64(a, b), equals(a + b));
    });

    test('safeUsing pointer read/write memory operations', () {
      final derefU8 = helper.library.lookupFunction<DerefU8Native, DerefU8Dart>(
        'deref_u8',
      );
      final writeU8 = helper.library.lookupFunction<WriteU8Native, WriteU8Dart>(
        'write_u8',
      );

      helper.safeUsing((Arena arena) {
        final ptr = arena.allocate<Uint8>(1);
        writeU8(ptr, 42);
        expect(derefU8(ptr), equals(42));
        expect(ptr.value, equals(42));

        ptr.value = 99;
        expect(derefU8(ptr), equals(99));
      });
    });
  });
}
