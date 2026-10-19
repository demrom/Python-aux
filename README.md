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
