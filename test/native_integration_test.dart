@TestOn('vm')
library;

import 'dart:io' show Directory, Platform;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/ffi_utils.dart';

// ignore_for_file: camel_case_types
typedef GetLibraryNameNative = Pointer<Char> Function();
typedef GetLibraryNameDart = Pointer<Char> Function();

typedef HelloNative = Pointer<Char> Function(Pointer<Char>);
typedef HelloDart = Pointer<Char> Function(Pointer<Char>);

typedef IntSizeNative = Int Function();
typedef IntSizeDart = int Function();

typedef BoolSizeNative = Int Function();
typedef BoolSizeDart = int Function();

typedef PointerSizeNative = Int Function();
typedef PointerSizeDart = int Function();

typedef StaticInitCheckNative = Int Function();
typedef StaticInitCheckDart = int Function();

void main() {
  group('Native integration', () {
    late String modulePath;

    setUpAll(() {
      final assetsDir = path.join(Directory.current.path, 'example', 'assets');
      if (Platform.isLinux || Platform.isAndroid) {
        modulePath = path.join(assetsDir, 'native_example');
      } else if (Platform.isMacOS || Platform.isIOS) {
        modulePath = path.join(assetsDir, 'native_example');
      } else if (Platform.isWindows) {
        modulePath = path.join(assetsDir, 'native_example');
      }
    });

    test('loads native library and executes functions via FfiHelper', () async {
      final helper = await FfiHelper.load(modulePath);
      expect(helper.library, isNotNull);

      final getLibraryName = helper.library
          .lookupFunction<GetLibraryNameNative, GetLibraryNameDart>(
            'getLibraryName',
          );
      final libName = getLibraryName().cast<Utf8>().toDartString();
      expect(libName, equals('native_example'));

      final hello = helper.library.lookupFunction<HelloNative, HelloDart>(
        'hello',
      );
      final greeting = helper.safeUsing((Arena arena) {
        final cStr = 'UniversalFFI'.toNativeUtf8(allocator: arena).cast<Char>();
        return hello(cStr).cast<Utf8>().toDartString();
      });
      expect(greeting, equals('Hello UniversalFFI!'));

      final intSize = helper.library.lookupFunction<IntSizeNative, IntSizeDart>(
        'intSize',
      );
      expect(intSize(), equals(sizeOf<Int>()));

      final boolSize = helper.library
          .lookupFunction<BoolSizeNative, BoolSizeDart>('boolSize');
      expect(boolSize(), isPositive);

      final pointerSize = helper.library
          .lookupFunction<PointerSizeNative, PointerSizeDart>('pointerSize');
      expect(pointerSize(), equals(sizeOf<Pointer<Void>>()));

      final staticInitCheck = helper.library
          .lookupFunction<StaticInitCheckNative, StaticInitCheckDart>(
            'static_init_check',
          );
      expect(staticInitCheck(), equals(1));
    });
  });
}
