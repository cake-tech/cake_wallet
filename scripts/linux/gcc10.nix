with import <nixpkgs> {};
gcc10Stdenv.mkDerivation {
  name="gcc10-stdenv";
  buildInputs = [
    pkgs.cmake
    pkgs.boost182
    pkgs.pkgconf
    pkgs.autoconf
    pkgs.libtool
    pkgs.expat
  ];
}

