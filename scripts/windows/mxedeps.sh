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
  gcc-mingw-w64-x86-64 \
  g++ \
  g++-multilib \
  g++-mingw-w64-x86-64 \
  gperf \
  intltool \
  libc6-dev-i386 \
  libffi-dev \
  libgtk-3-0 \
  libtool \
  libtool-bin \
  libltdl-dev \
  libssl-dev \
  libxml-parser-perl \
  lzip \
  make \
  openssl \
  patch \
  perl \
  pkg-config \
  python \
  python3-mako \
  ruby \
  scons \
  sed \
  unzip \
  wget \
  xz-utils \

# Install MXE
mkdir -p ~/development
cd ~/development
MXE_URL="https://github.com/mxe/mxe.git"
if [ ! -d "mxe" ] ; then
    git clone $MXE_URL
fi
cd mxe || exit
git pull $MXE_URL
make cc gcc cmake MXE_TARGETS='x86_64-w64-mingw32.static'
if ! [[ $PATH == *"/mxe"* ]]; then
  echo 'export PATH="$HOME/development/mxe/usr/bin:$PATH"' >> ~/.bashrc  # Prepend to PATH
  source ~/.bashrc
fi
# make openssl expat MXE_TARGETS='x86_64-w64-mingw32.static'
