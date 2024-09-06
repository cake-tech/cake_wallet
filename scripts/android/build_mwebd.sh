# install go > 1.23:
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/go/bin
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
git reset --hard f6ea8a9e3d348b01bb44f03a1cc4ad65b0abe935
gomobile bind -target=android -androidapi 21 .
mkdir -p ../../../cw_mweb/android/libs/
mv ./mwebd.aar $_
# cleanup:
cd ..
rm -rf mwebd