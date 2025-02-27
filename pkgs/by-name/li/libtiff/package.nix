{
  lib,
  stdenv,
  fetchFromGitLab,
  fetchpatch,
  nix-update-script,

  cmake,
  pkg-config,
  sphinx,

  lerc,
  libdeflate,
  libjpeg,
  libwebp,
  xz,
  zlib,
  zstd,

  # for passthru.tests
  libgeotiff,
  python3Packages,
  imagemagick,
  graphicsmagick,
  gdal,
  openimageio,
  freeimage,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libtiff";
  version = "4.7.0";

  src = fetchFromGitLab {
    owner = "libtiff";
    repo = "libtiff";
    rev = "v${finalAttrs.version}";
    hash = "sha256-SuK9/a6OUAumEe1kz1itFJGKxJzbmHkBVLMnyXhIwmQ=";
  };

  patches = [
    # libc++abi 11 has an `#include <version>`, this picks up files name
    # `version` in the project's include paths
    ./rename-version.patch
    ./static.patch
  ];

  postPatch = ''
    mv VERSION VERSION.txt
  '';

  outputs = [
    "bin"
    "dev"
    "dev_private"
    "out"
    "man"
    "doc"
  ];

  postFixup = ''
    mkdir -p $dev_private/include
    mv -t $dev_private/include \
      libtiff/tif_config.h \
      ../libtiff/tif_dir.h \
      ../libtiff/tif_hash_set.h \
      ../libtiff/tiffiop.h
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    sphinx
  ];

  buildInputs = [
    lerc
    zstd
  ];

  # TODO: opengl support (bogus configure detection)
  propagatedBuildInputs = [
    libdeflate
    libjpeg
    # libwebp depends on us; this will cause infinite
    # recursion otherwise
    (libwebp.override { tiffSupport = false; })
    xz
    zlib
    zstd
  ];

  cmakeFlags = [
    "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON"
  ];

  enableParallelBuilding = true;

  doCheck = true;
  # Avoid flakiness like https://gitlab.com/libtiff/libtiff/-/commit/94f6f7315b1
  enableParallelChecking = false;

  passthru = {
    tests = {
      inherit
        libgeotiff
        imagemagick
        graphicsmagick
        gdal
        openimageio
        freeimage
        ;
      inherit (python3Packages) pillow imread;
      pkg-config = testers.hasPkgConfigModules {
        package = finalAttrs.finalPackage;
      };
    };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Library and utilities for working with the TIFF image file format";
    homepage = "https://libtiff.gitlab.io/libtiff";
    changelog = "https://libtiff.gitlab.io/libtiff/releases/v${finalAttrs.version}.html";
    license = licenses.libtiff;
    platforms = platforms.unix ++ platforms.windows;
    pkgConfigModules = [ "libtiff-4" ];
    maintainers = teams.geospatial.members;
  };
})
