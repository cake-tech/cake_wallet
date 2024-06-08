git clone https://github.com/ltcmweb/mwebd
cd mwebd
go install github.com/ltcmweb/mwebd/cmd/mwebd@latest
gomobile bind -target=android -androidapi 19 github.com/ltcmweb/mwebd

mkdir -p ../../../cw_mweb/android/libs/
mv ./mwebd.aar $_