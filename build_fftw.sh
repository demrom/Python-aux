#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
build=$root/.build/fftw
archive=$build/fftw-3.3.11.tar.gz
mkdir -p "$build"
if [[ ! -f $archive ]]; then
	curl -fL --retry 3 https://fftw.org/fftw-3.3.11.tar.gz -o "$archive.part"
	mv "$archive.part" "$archive"
fi
printf '%s  %s\n' 5630c24cdeb33b131612f7eb4b1a9934234754f9f388ff8617458d0be6f239a1 "$archive" | shasum -a 256 -c -
if [[ ! -d $build/fftw-3.3.11 ]]; then tar -xzf "$archive" -C "$build"; fi
source_dir=$build/fftw-3.3.11
minos=${IPHONEOS_DEPLOYMENT_TARGET:-14.0}
if [[ $# == 0 ]]; then set -- macosx iphoneos iphonesimulator-arm64 iphonesimulator-x86_64; fi
for target in "$@"; do
	case $target in
		macosx) sdk=macosx; triple=arm64-apple-macos11.0; host=aarch64-apple-darwin ;;
		iphoneos) sdk=iphoneos; triple=arm64-apple-ios$minos; host=aarch64-apple-darwin ;;
		iphonesimulator-arm64) sdk=iphonesimulator; triple=arm64-apple-ios$minos-simulator; host=aarch64-apple-darwin ;;
		iphonesimulator-x86_64) sdk=iphonesimulator; triple=x86_64-apple-ios$minos-simulator; host=x86_64-apple-darwin ;;
		*) echo "Unsupported FFTW target: $target" >&2; exit 1 ;;
	esac
	sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
	prefix=$build/$target/install
	for precision in double float long-double; do
		options=(--enable-threads)
		case $precision in float) options+=(--enable-float) ;; long-double) options+=(--enable-long-double) ;; esac
		directory=$build/$target/$precision
		mkdir -p "$directory"
		pushd "$directory"
		CC=clang CXX=clang++ CFLAGS="-target $triple -isysroot $sdkroot -O3" \
		CPPFLAGS="-target $triple -isysroot $sdkroot" \
		"$source_dir/configure" --build="$("$source_dir/config.guess")" --host="$host" \
			--prefix="$prefix" --disable-shared --enable-static --disable-fortran \
			"${options[@]}" cross_compiling=yes
		make -j4
		make install
		popd
	done
done

# Package only complete target sets; single-target invocations stage their static
# libraries for Python consumers without replacing an existing XCFramework.
if [[ -f $build/iphoneos/install/lib/libfftw3.a && -f $build/iphonesimulator-arm64/install/lib/libfftw3.a && -f $build/iphonesimulator-x86_64/install/lib/libfftw3.a ]]; then
	mkdir -p "$build/simulator"
	for name in fftw3 fftw3_threads fftw3f fftw3f_threads fftw3l fftw3l_threads; do
		lipo -create "$build/iphonesimulator-arm64/install/lib/lib$name.a" "$build/iphonesimulator-x86_64/install/lib/lib$name.a" -output "$build/simulator/lib$name.a"
		args=(-library "$build/iphoneos/install/lib/lib$name.a" -headers "$build/iphoneos/install/include" -library "$build/simulator/lib$name.a" -headers "$build/iphonesimulator-arm64/install/include")
		if [[ -f $build/macosx/install/lib/lib$name.a ]]; then args+=(-library "$build/macosx/install/lib/lib$name.a" -headers "$build/macosx/install/include"); fi
		rm -rf "$root/lib$name.xcframework"
		xcodebuild -create-xcframework "${args[@]}" -output "$root/lib$name.xcframework"
	done
fi
