#!/bin/bash

# MXE dependencies
sudo apt-get install -y \
  p7zip-full \
  autoconf \
  automake \
  autopoint \
  bash \
  bison \
  bzip2 \
  cmake \
  flex \
  gettext \
  git \
  g++ \
  gperf \
  intltool \
  libffi-dev \
  libtool \
  libtool-bin \
  libltdl-dev \
  libssl-dev \
  libxml-parser-perl \
  make \
  openssl \
  patch \
  perl \
  pkg-config \
  python \
  ruby \
  scons \
  sed \
  unzip \
  wget \
  xz-utils \
  g++-multilib \
  libc6-dev-i386 \
  lzip \
  gcc-mingw-w64-x86-64 \
  g++-mingw-w64-x86-64

# Install MXE
mkdir -p ~/development
cd ~/development
git clone https://github.com/mxe/mxe.git
cd mxe
make cc gcc cmake MXE_TARGETS='x86_64-w64-mingw32.static'
if ! [[ $PATH == *"/mxe"* ]]; then
  echo 'export PATH="$HOME/development/mxe/usr/bin:$PATH"' >> ~/.bashrc  # Prepend to PATH
  source ~/.bashrc
fi
# make openssl expat MXE_TARGETS='x86_64-w64-mingw32.static'
