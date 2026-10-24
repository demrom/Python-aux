#!/bin/bash
set -euo pipefail

# Build the OpenMP runtime from the same pinned LLVM source as Flang.
llvm_source=$(cd "${1:?LLVM source directory is required}" && pwd)
mkdir -p "${2:?Build directory is required}"
build_root=$(cd "$2" && pwd)
script_root=$(cd "$(dirname "$0")" && pwd)
patch_file=$script_root/patches/openmp-ios-linker.patch
if ! git -C "$llvm_source" apply --reverse --check "$patch_file" 2>/dev/null; then
	git -C "$llvm_source" apply "$patch_file"
fi

for target in iphoneos iphonesimulator iphonesimulator-x86_64; do
	sdk=${target%%-*}
	arch=arm64
	[[ $target != iphonesimulator-x86_64 ]] || arch=x86_64
	cmake -S "$llvm_source/runtimes" -B "$build_root/$target" -G Ninja \
		-DLLVM_ENABLE_RUNTIMES=openmp -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" \
		-DCMAKE_OSX_ARCHITECTURES="$arch" -DCMAKE_SYSTEM_PROCESSOR="$arch" \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DLLVM_INCLUDE_TESTS=OFF \
		-DCMAKE_C_COMPILER="$(xcrun --sdk "$sdk" -f clang)" \
		-DCMAKE_CXX_COMPILER="$(xcrun --sdk "$sdk" -f clang++)" \
		-DLIBOMP_ENABLE_SHARED=ON -DLIBOMP_FORTRAN_MODULES=OFF -DOPENMP_ENABLE_LIBOMPTARGET=OFF
	cmake --build "$build_root/$target" --target omp --parallel 4
	framework=$build_root/$target/libomp.framework
	mkdir -p "$framework/Headers"
	cp "$build_root/$target/openmp/runtime/src/omp.h" "$framework/Headers/"
	cp "$build_root/$target/openmp/runtime/src/libomp.dylib" "$framework/libomp"
	install_name_tool -id @rpath/libomp.framework/libomp "$framework/libomp"
	if [[ $sdk == iphoneos ]]; then
		cp "$script_root/basic_Info.plist" "$framework/Info.plist"
	else
		cp "$script_root/basic_Info_Simulator.plist" "$framework/Info.plist"
	fi
	plutil -replace CFBundleExecutable -string libomp "$framework/Info.plist"
	plutil -replace CFBundleName -string libomp "$framework/Info.plist"
	plutil -replace CFBundleIdentifier -string org.llvm.libomp "$framework/Info.plist"
done

simulator=$build_root/iphonesimulator-universal
rm -rf "$simulator/libomp.framework"
mkdir -p "$simulator"
cp -R "$build_root/iphonesimulator/libomp.framework" "$simulator/"
lipo -create "$build_root/iphonesimulator/libomp.framework/libomp" \
	"$build_root/iphonesimulator-x86_64/libomp.framework/libomp" -output "$simulator/libomp.framework/libomp"
test "$(lipo -archs "$simulator/libomp.framework/libomp")" = 'x86_64 arm64'
