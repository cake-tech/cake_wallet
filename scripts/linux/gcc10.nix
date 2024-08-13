with import <nixpkgs> {};
gcc10Stdenv.mkDerivation {
  name="gcc10-stdenv";
  buildInputs = [
    pkgs.cmake
    pkgs.pkg-config
    pkgs.autoconf
    pkgs.libtool
    pkgs.expat
  ];
}

