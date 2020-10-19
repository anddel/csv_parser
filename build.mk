.DEFAULT_GOAL := help
PROJECT_NAME=$(shell basename "$(PWD)")
SOURCES=./src/lib.rs

OS_NAME=$(shell uname | tr '[:upper:]' '[:lower:]')
PATH := $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64/bin:$(PATH)

ANDROID_AARCH64_LINKER=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64/bin/aarch64-linux-android29-clang
ANDROID_ARMV7_LINKER=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64/bin/armv7a-linux-androideabi29-clang
ANDROID_I686_LINKER=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64/bin/i686-linux-android29-clang
ANDROID_X86_64_LINKER=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64/bin/x86_64-linux-android29-clang

SHELL := /bin/bash

.PHONY: ndk-home
ndk-home:
	@if [ ! -d "${ANDROID_NDK_HOME}" ] ; then \
		echo "Error: Please, set the ANDROID_NDK_HOME env variable to point to your NDK folder" ; \
		exit 1 ; \
	fi


# ##############################################################################
# # GENERAL
# ##############################################################################

.PHONY: help
help: makefile
	@echo
	@echo " Available actions in "$(PROJECT_NAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

## init: Install missing dependencies.
.PHONY: init
init:
	@if [ $$(uname) == "Darwin" ] ; then \
		rustup toolchain install 1.41.0-x86_64-apple-darwin && \
		rustup target add --toolchain 1.41.0-x86_64-apple-darwin aarch64-apple-ios x86_64-apple-ios \
		 i386-apple-ios armv7-apple-ios armv7s-apple-ios && \
		cargo install cargo-lipo --force; \
	fi
	rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
	@if [ $$(uname) == "Linux" ] || [ $$(uname) == "Darwin" ] ; then rustup target add x86_64-pc-windows-gnu ; fi
	cargo install cbindgen --force


# ##############################################################################
# # RECIPES
# ##############################################################################

## all: Compile iOS, Android and bindings targets
all: native ios android windows

native: native_binding_header
	@cargo build --release
	@cp -v target/release/libcsv_parser.{dylib,so,dll} assets/binary/ || true

## bindings: Generate the .h file for iOS
bindings: native_binding_header ios_binding_header

native_binding_header:
	@cbindgen src/lib.rs -l c > lib/csv_parser.h

ios_binding_header: $(SOURCES)
	@cp -v lib/csv_parser.h ios/
	@cat ios/Classes/CsvParserPlugin.h.in > ios/Classes/CsvParserPlugin.h
	@cat ios/csv_parser.h | grep -v "#include"  >> ios/Classes/CsvParserPlugin.h

## ios: Compile the iOS universal library
ios: release_universal

LIPO_TARGETS=aarch64-apple-ios,x86_64-apple-ios,armv7-apple-ios,armv7s-apple-ios,i386-apple-ios

release_universal: $(SOURCES)
	@if [ $$(uname) == "Darwin" ] ; then \
		cargo +1.41.0-x86_64-apple-darwin lipo --targets=$(LIPO_TARGETS) --release && \
		cp -fv ./target/universal/release/libcsv_parser.a ./ios/ ;\
		else echo "Skipping iOS compilation on $$(uname)" ; \
	fi

## android: Compile the android targets (arm64, armv7 and i686)
android: android_armv7 android_i686 android_aarch64

android_aarch64: $(SOURCES) ndk-home
	@CC_aarch64_linux_android=$(ANDROID_AARCH64_LINKER) \
	CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$(ANDROID_AARCH64_LINKER) \
	cargo build --target aarch64-linux-android --release && \
	cp -fv ./target/aarch64-linux-android/release/libcsv_parser.so ./android/src/main/jniLibs/arm64-v8a/

android_armv7: $(SOURCES) ndk-home
	@CC_armv7_linux_androideabi=$(ANDROID_ARMV7_LINKER) \
	CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER=$(ANDROID_ARMV7_LINKER) \
	cargo build --target armv7-linux-androideabi --release && \
	cp -fv ./target/armv7-linux-androideabi/release/libcsv_parser.so ./android/src/main/jniLibs/armeabi-v7a/

android_i686: $(SOURCES) ndk-home
	@CC_i686_linux_android=$(ANDROID_I686_LINKER) \
	CARGO_TARGET_I686_LINUX_ANDROID_LINKER=$(ANDROID_I686_LINKER) \
	cargo  build --target i686-linux-android --release && \
	cp -fv ./target/i686-linux-android/release/libcsv_parser.so ./android/src/main/jniLibs/x86/

#android_x86_64: $(SOURCES) ndk-home
#	CC_x86_64_linux_android=$(ANDROID_X86_64_LINKER) \
#	CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER=$(ANDROID_X86_64_LINKER) \
#	cargo  build --target x86-64-linux-android --release && \
# 	cp -fv ./target/x86-64-linux-android/release/libcsv_parser.so ./android/src/main/jniLibs/x64/

windows:
	cargo build --target x86_64-pc-windows-gnu --release
	@cp -v target/x86_64-pc-windows-gnu/release/csv_parser.dll assets/binary/libcsv_parser.dll
