#!/bin/bash
if [[ "$1" == "--install" ]]; then
  # install go > 1.23:
  brew install go
  export PATH=$PATH:~/go/bin
  go install golang.org/x/mobile/cmd/gomobile@latest
  gomobile init
fi

# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
git reset --hard f6ea8a9e3d348b01bb44f03a1cc4ad65b0abe935
gomobile bind -target=ios .
mv -fn ./Mwebd.xcframework ../../../ios/
# cleanup:
cd ..
rm -rf mwebd