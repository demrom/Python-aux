#!/bin/bash
set -euo pipefail

source_root=$PWD/libzmq
build_root=$PWD/.build/libzmq
for target in iphoneos iphonesimulator iphonesimulator-x86_64; do
	sdk=${target%%-*}
	arch=arm64
	[[ $target != iphonesimulator-x86_64 ]] || arch=x86_64
	cmake -S "$source_root" -B "$build_root/$target" \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" \
		-DCMAKE_OSX_ARCHITECTURES="$arch" -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
		-DCMAKE_C_COMPILER="$(xcrun --sdk "$sdk" -f clang)" \
		-DCMAKE_CXX_COMPILER="$(xcrun --sdk "$sdk" -f clang++)" \
		-DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED=ON -DBUILD_STATIC=OFF \
		-DBUILD_TESTS=OFF -DWITH_DOCS=OFF -DWITH_PERF_TOOL=OFF \
		-DWITH_TLS=OFF -DWITH_LIBSODIUM=OFF -DENABLE_CURVE=OFF -DENABLE_DRAFTS=OFF
	cmake --build "$build_root/$target" --target libzmq --parallel 4
	framework=$build_root/$target/libzmq.framework
	mkdir -p "$framework/Headers"
	cp "$source_root/include/zmq.h" "$source_root/include/zmq_utils.h" "$framework/Headers/"
	cp "$build_root/$target/lib/libzmq.5.dylib" "$framework/libzmq"
	install_name_tool -id @rpath/libzmq.framework/libzmq "$framework/libzmq"
	if [[ $sdk == iphoneos ]]; then
		cp basic_Info.plist "$framework/Info.plist"
	else
		cp basic_Info_Simulator.plist "$framework/Info.plist"
	fi
	plutil -replace CFBundleExecutable -string libzmq "$framework/Info.plist"
	plutil -replace CFBundleName -string libzmq "$framework/Info.plist"
	plutil -replace CFBundleIdentifier -string org.zeromq.libzmq "$framework/Info.plist"
done

simulator=$build_root/iphonesimulator-universal
rm -rf "$simulator/libzmq.framework" libzmq.xcframework
mkdir -p "$simulator"
cp -R "$build_root/iphonesimulator/libzmq.framework" "$simulator/"
lipo -create "$build_root/iphonesimulator/libzmq.framework/libzmq" \
	"$build_root/iphonesimulator-x86_64/libzmq.framework/libzmq" -output "$simulator/libzmq.framework/libzmq"
xcodebuild -create-xcframework -framework "$build_root/iphoneos/libzmq.framework" \
	-framework "$simulator/libzmq.framework" -output libzmq.xcframework
