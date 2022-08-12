sudo apt-get install libsecret-1-dev libjsoncpp-dev libsecret-1-0
sudo apt install libjsoncpp-dev

cd build
cmake ../cmakefiles/aarch64
make -j$(nproc)