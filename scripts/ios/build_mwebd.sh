# install go > 1.21:
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/go/bin
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
gomobile bind -target=ios ./mwebd
mkdir -p ../../../cw_mweb/android/libs/
mv ./Mwebd.xcframework ../../../ios/
# cleanup:
cd ..
rm -rf mwebd