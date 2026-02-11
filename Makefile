.PHONY: version build run

version:
	bash ./tool/update-version.sh

build:
	cd example_ffi_plugin && make build

run-web:
	cd example && make run-wasm

run-ffi:
	cd example && make run-ffi