#!/bin/bash
# install go > 1.21:
brew install go
export PATH=$PATH:~/go/bin
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
gomobile bind -target=ios .
mv -fn ./Mwebd.xcframework ../../../ios/
# cleanup:
cd ..
rm -rf mwebd