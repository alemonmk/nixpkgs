{
  lib,
  stdenv,
  fetchFromGitHub,

  withPython ? true,

  cairo,
  cmake,
  curl,
  fcgi,
  freetype,
  fribidi,
  gdal,
  geos,
  giflib,
  harfbuzz,
  libjpeg,
  libpng,
  libpq,
  librsvg,
  libxml2,
  pkg-config,
  proj,
  protobufc,
  python3,
  swig,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "mapserver";
  version = "8.4.0";

  src = fetchFromGitHub {
    owner = "MapServer";
    repo = "MapServer";
    rev = "rel-${lib.replaceStrings [ "." ] [ "-" ] version}";
    hash = "sha256-XEjRklbvYV7UoVX12iW6s1mS8pzIljla488CQNuFfto=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals withPython [
    swig
    python3.pkgs.setuptools
    python3.pkgs.pythonImportsCheckHook
  ];

  buildInputs = [
    cairo
    curl
    fcgi
    freetype
    fribidi
    gdal
    geos
    giflib
    harfbuzz
    libjpeg
    libpng
    libpq
    librsvg
    libxml2
    proj
    protobufc
    zlib
  ]
  ++ lib.optional withPython python3;

  cmakeFlags = [
    (lib.cmakeBool "WITH_KML" true)
    (lib.cmakeBool "WITH_SOS" true)
    (lib.cmakeBool "WITH_RSVG" true)
    (lib.cmakeBool "WITH_CURL" true)
    (lib.cmakeBool "WITH_CLIENT_WMS" true)
    (lib.cmakeBool "WITH_CLIENT_WFS" true)
    (lib.cmakeBool "WITH_PYTHON" withPython)

    # RPATH of binary /nix/store/.../bin/... contains a forbidden reference to /build/
    (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
  ];

  postInstall = lib.optionalString withPython ''
    mkdir -p $out/${python3.sitePackages}
    cp -r src/mapscript/python/mapscript $out/${python3.sitePackages}
  '';

  pythonImportsCheck = [ "mapscript" ];

  meta = {
    description = "Platform for publishing spatial data and interactive mapping applications to the web";
    homepage = "https://mapserver.org/";
    changelog = "https://mapserver.org/development/changelog/";
    license = lib.licenses.mit;
    teams = [ lib.teams.geospatial ];
    platforms = lib.platforms.unix;
  };
}
