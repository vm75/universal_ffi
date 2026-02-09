import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/ffi_utils.dart';
import 'native_example_bindings.dart';

class ExampleLibraryWrapper {
  final FfiHelper helper;
  final NativeExampleBindings bindings;

  ExampleLibraryWrapper._(this.helper)
      : bindings = NativeExampleBindings(helper.library);

  static Future<ExampleLibraryWrapper> create(String libPath) async {
    final helper = await FfiHelper.load(libPath);
    return ExampleLibraryWrapper._(helper);
  }

  String getLibraryName() =>
      bindings.getLibraryName().cast<Utf8>().toDartString();

  String hello(String name) {
    return helper.safeUsing(
      (Arena arena) {
        final cString = name.toNativeUtf8(allocator: arena).cast<Char>();
        return bindings.hello(cString).cast<Utf8>().toDartString();
      },
    );
  }

  int intSize() => bindings.intSize();

  int boolSize() => bindings.boolSize();

  int pointerSize() => bindings.pointerSize();
}
