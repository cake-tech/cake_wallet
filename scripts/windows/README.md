# `flutter_libmonero` for Windows
Supported platform: Ubuntu 20.04

### Install dependencies
Run `monerodeps.sh` to install Monero dependencies, or use the command below:
```bash
sudo apt install libsecret-1-dev libjsoncpp-dev libsecret-1-0
```

Run `mxedeps.sh` to install MXE and its dependencies, or use the commands below:
```bash
sudo apt-get install p7zip-full autoconf automake autopoint bash bison bzip2 cmake flex gettext git g++ gperf intltool libffi-dev libtool libtool-bin libltdl-dev libssl-dev libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386 lzip gcc-mingw-w64-x86-64

# Install MXE to ~/development/mxe
mkdir -p ~/development
cd ~/development
git clone https://github.com/mxe/mxe.git
cd mxe
make cc cmake MXE_TARGETS='x86_64-w64-mingw32.static'
if ! [[ $PATH == *"/mxe"* ]]; then
  echo 'export PATH="$HOME/development/mxe/usr/bin:$PATH"' >> ~/.bashrc  # Prepend to PATH
  source ~/.bashrc
fi
make cmake MXE_TARGETS='x86_64-w64-mingw32.static'
```

### Build
Run `build_all.sh` (may need to alter permissions like `chmod +x *.sh`)

Libraries will be output to `scripts/windows/build`
