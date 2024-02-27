{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.curl
    pkgs.unzip
    pkgs.automake
    pkgs.file
    pkgs.pkg-config
    pkgs.git
    pkgs.libtool
    pkgs.ncurses5
    pkgs.openjdk8
    pkgs.clang
  ];
}
