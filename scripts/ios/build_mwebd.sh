#!/bin/bash
# install go > 1.21:
brew install go
export PATH=$PATH:~/go/bin
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
git reset --hard 7f31c84eeb2e954f2c5f385b39db3b8e3b6389e3
gomobile bind -target=ios .
mv -fn ./Mwebd.xcframework ../../../ios/
# cleanup:
cd ..
rm -rf mwebd