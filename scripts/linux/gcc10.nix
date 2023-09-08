with import <nixpkgs> {};
gcc10Stdenv.mkDerivation {
  name="gcc10-stdenv";
  buildInputs = [
    pkgs.cmake
    pkgs.pkgconfig
    pkgs.autoconf
    pkgs.libtool
    pkgs.expat
  ];
}

