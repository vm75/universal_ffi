.PHONY: clean

UNAME_S := $(shell uname -s)

default: build

build: assets/libnative_example.so assets/native_example.dll assets/libnative_example.dylib

clean:
ifeq ($(UNAME_S), Linux)
	rm -f assets/libnative_example.so
	rm -f assets/native_example.dll
else ifeq  ($(filter Darwin,$(UNAME_S)),)
	rm -f assets/libnative_example.dylib
endif

SRC=src/native_example.c src/native_example_cpp.cpp
DEPS=$(SRC) src/native_example.h
CFLAGS=-fPIC -fvisibility=hidden

assets/libnative_example.so: $(DEPS)
ifeq ($(UNAME_S), Linux)
	clang -shared $(CFLAGS) -o $@ $(SRC)
endif

assets/libnative_example.dylib: $(DEPS)
ifeq ($(UNAME_S), Darwin)
	clang -dynamiclib $(CFLAGS) -o $@ $(SRC)
endif

assets/native_example.dll: $(DEPS)
ifeq ($(UNAME_S), Linux)
	x86_64-w64-mingw32-gcc -shared $(CFLAGS) -o $@ $(SRC)
endif

run-wasm:
	webdev serve

run-ffi:
	dart run
