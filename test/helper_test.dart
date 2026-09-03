import 'package:test/test.dart';
import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';
import 'package:universal_ffi/ffi_utils.dart';

class _TrackingAllocator implements Allocator {
  int allocations = 0;
  int deallocations = 0;

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    allocations++;
    return calloc.allocate<T>(byteCount, alignment: alignment);
  }

  @override
  void free(Pointer<NativeType> pointer) {
    deallocations++;
    calloc.free(pointer);
  }
}

void main() {
  group('FfiHelper allocator helpers', () {
    test(
      'safeUsing releases allocations using default or provided allocator',
      () async {
        final helper = await FfiHelper.load(
          '',
          options: {LoadOption.isStaticallyLinked},
        );
        final tracker = _TrackingAllocator();

        final result = helper.safeUsing((Arena arena) {
          final ptr = arena.allocate<Uint8>(10);
          expect(ptr.address, isNot(0));
          return 42;
        }, tracker);

        expect(result, equals(42));
        expect(tracker.allocations, equals(1));
        expect(tracker.deallocations, equals(1));
      },
    );

    test('safeWithZoneArena runs computation in zoned arena', () async {
      final helper = await FfiHelper.load(
        '',
        options: {LoadOption.isStaticallyLinked},
      );
      final tracker = _TrackingAllocator();

      final result = helper.safeWithZoneArena(() {
        final ptr = tracker.allocate<Uint8>(16);
        tracker.free(ptr);
        return 'success';
      }, tracker);

      expect(result, equals('success'));
      expect(tracker.allocations, equals(1));
      expect(tracker.deallocations, equals(1));
    });

    test('load throws ArgumentError for statically linked on Web', () {
      // On native it succeeds for DynamicLibrary.process(),
      // Web throws ArgumentError.
      if (appType == AppType.web) {
        expect(
          () => FfiHelper.load('', options: {LoadOption.isStaticallyLinked}),
          throwsArgumentError,
        );
      }
    });
  });
}
