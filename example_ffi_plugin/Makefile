default: build

build: assets/native_example.js assets/standalone/native_example.wasm lib/native_example_bindings.dart

SRC=src/native_example.c
DEPS=$(SRC) $(SRC:.c=.h)

# Wasm options
ifdef  DEBUG
	COMPILER_OPTIONS=-g3 --profiling-funcs -s ASSERTIONS=1 -fsanitize=address
	LINKER_OPTIONS=-Wl,--no-entry
else
	COMPILER_OPTIONS=-fPIC -Oz -fno-exceptions -fno-rtti -fno-stack-protector -ffunction-sections -fdata-sections -fno-math-errno -DNDEBUG
	LINKER_OPTIONS=-Wl,--gc-sections,--no-entry
endif
COMPILED_EXPORTS="EXPORTED_FUNCTIONS=[\"_malloc\", \"_free\"]"

lib/native_example_bindings.dart: $(DEPS)
	dart run ffigen --config ffigen.yaml && sed -i "s#'dart:ffi'#'package:universal_ffi/ffi.dart'#g" $@

assets/native_example.js: $(DEPS) lib/native_example_bindings.dart
	emcc -o assets/native_example.js $(COMPILER_OPTIONS) $(LINKER_OPTIONS) \
		$(SRC) \
		-s MODULARIZE=1 -s 'EXPORT_NAME="native_example"' -s ALLOW_MEMORY_GROWTH=1 \
		-s ENVIRONMENT='web,worker' \
		-s FILESYSTEM=0 \
		-s EXPORTED_RUNTIME_METHODS=HEAPU8 \
		-s $(COMPILED_EXPORTS)

assets/standalone/native_example.wasm: $(DEPS) lib/native_example_bindings.dart
	emcc -o assets/standalone/native_example.wasm $(COMPILER_OPTIONS) $(LINKER_OPTIONS) \
		$(SRC) \
		-s STANDALONE_WASM=1 \
		-s ENVIRONMENT='web,worker' \
		-s FILESYSTEM=0 \
		-s $(COMPILED_EXPORTS)

run:
	flutter run
