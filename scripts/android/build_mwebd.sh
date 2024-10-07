if [[ "$1" == "--dont-install" ]]; then
  echo "Skipping Go installation as per --dont-install flag"
else
  # install go > 1.23:
  wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  export PATH=$PATH:~/go/bin
  go install golang.org/x/mobile/cmd/gomobile@latest
  gomobile init
fi

# build mwebd:
git clone https://github.com/ltcmweb/mwebd
cd mwebd
git reset --hard c880e276e4b06645ad8427972e8a788fe2fd0557
gomobile bind -target=android -androidapi 21 .
mkdir -p ../../../cw_mweb/android/libs/
mv ./mwebd.aar $_
# cleanup:
cd ..
rm -rf mwebd