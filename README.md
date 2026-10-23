# Python-aux

Auxiliary libraries needed for Python3 compilation, precompiled (libpng, harfbuzz, freetype...). They can be useful for many other OpenSource projects on iOS, too.

What we have:
- [libpng](http://www.libpng.org/pub/png/libpng.html) (1.6.37)
- [libffi](https://github.com/libffi/libffi) (main branch)
- [libzmq](https://github.com/zeromq/libzmq) (zeroMQ) (main branch)
- [OpenBLAS](https://github.com/xianyi/OpenBLAS) (develop branch)
- [freetype](https://www.freetype.org) (2.10.2)
- [harfbuzz](https://github.com/harfbuzz/harfbuzz) (main branch)

## How to use: 

In your Xcode project, use the menu File -> "Swift Packages" -> "Add Package Dependency". In the window that opens, enter the address for this repository (https://github.com/holzschu/Python-aux.git). 

In the rightmost column, you will see "Swift Package Dependencies", and under it "Python-aux". Under "Referenced Binaries", you have all the libraries, precompiled, as "xcframework". You can link with them, embed them, and Xcode will extract the iOS or Simulator version as needed.

## How to compile: 

In this repository, run `build_all_packages.sh`. This will update the code, compile the packages, create the frameworks, create and compress the xcframeworks and output the hash sums.

For use in your own repository, update the hash sums in `Package.swift`, publish the xcframeworks.zip in the right place and enjoy.

## Work in progress: 

- libheif: needs libpng (OK), libde265 and libx265 (WIP): https://github.com/strukturag/libde265

## Releasing xcframeworks

CI builds the libpng, freetype and harfbuzz xcframeworks on pull requests (except Markdown-only changes) and manual runs. It uploads the ZIPs, `checksums.txt` and `release.md` in the `xcframeworks` artifact. The build summary lists each slice and its architectures.

To release from this repository, push a `v*` tag, then wait for the "Publishing release" job. It creates a release with the generated notes, or adds the assets to an existing release while keeping its notes. Uploads fail if an asset already exists; published files are never overwritten. Only the release job has write permission.

Update each consuming `binaryTarget` URL and checksum with the new release and the values in `checksums.txt`.

## OpenBLAS with Fortran LAPACK

The Fortran CI job builds arm64 device and universal arm64/x86_64 Simulator frameworks with Homebrew Flang 23.1.4 and matching LLVM runtime sources. It compiles LAPACK's `dpotrf.f` for each platform, links OpenBLAS against a shared `flang_rt.framework`, and runs Cholesky, linear-system and Fortran `dsyev` eigenvalue checks on the arm64 Simulator. The x86_64 Simulator consumer is compiled and linked only. The `openblas` artifact contains `openblas.xcframework.zip`, `flang_rt.xcframework.zip` and their SwiftPM checksums; tag releases include them alongside the other libraries. Embed both frameworks in consuming apps.

Run `nice -n 15 bash build_flang_runtime.sh <llvm-source> <runtime-build>`, then `nice -n 15 bash build_openblas_flang.sh <runtime-build> <openblas-build>`. The workflow lists the LLVM sparse-checkout paths and pinned revision. Both scripts use four build jobs. The x86_64 Simulator uses this revision's CORE2 cross-build configuration. The runtime patch makes command-line execution report unsupported on iOS and rejects executable trampolines there. LAPACK uses neither facility.

This build includes the Fortran BLAS and LAPACK APIs and CBLAS. LAPACKE is disabled because this OpenBLAS revision's LAPACKE headers disagree with its deprecated wrappers. NumPy and SciPy use the Fortran LAPACK API.
