include build.mk

## build:
.PHONY: build
build: all

## clean:
.PHONY: clean
clean:
	cargo clean

## test:
.PHONY: test
test: all
	cargo test
	flutter test test/
	cd ../../flutter_app && flutter test  test/test_cases/unit_tests/csv_parser_test.dart

lint:
	cargo clippy
	flutter analyze

extract_artifacts:
	@cp -v ./android/src/main/jniLibs/arm64-v8a/libcsv_parser.so assets/binary/libcsv_parser-android-arm64.so
	@cp -v ./android/src/main/jniLibs/armeabi-v7a/libcsv_parser.so assets/binary/libcsv_parser-android-armv7.so
	@cp -v ./android/src/main/jniLibs/x86/libcsv_parser.so assets/binary/libcsv_parser-android-x86.so
	@cp -v ./ios/libcsv_parser.a assets/binary/libcsv_parser-ios.a
	@cp -v ./lib/csv_parser.h assets/binary/csv_parser.h

build_in_docker:
	docker build -f builder.dockerfile -t csv_parser_lib .
	@docker create --name csv_temp csv_parser_lib
	docker cp csv_temp:/binary-build - > lib-release.tar
	@docker rm -v csv_temp
	@echo 'File lib-release.tar contains build for: Linux, Windows, Android'