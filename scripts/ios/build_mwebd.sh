#!/bin/bash
if [[ "$1" == "--dont-install" ]]; then
  echo "Skipping Go installation as per --dont-install flag"
else
  # install go > 1.24:
  brew install go
  export PATH=$PATH:~/go/bin
  go install golang.org/x/mobile/cmd/gomobile@latest
  gomobile init
fi

# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
git reset --hard 10bc71991aac95d264ce93d520e2334fdab4f2d6
gomobile bind -target=ios .
mv -fn ./Mwebd.xcframework ../../../cw_mweb/ios/
# cleanup:
cd ..
rm -rf mwebd