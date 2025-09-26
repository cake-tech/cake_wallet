git clone https://github.com/konstantinullrich/bitbox_flutter
cd bitbox_flutter
./build_bindings.sh --dont-install

FILE=api.aar
if [ -f "$FILE" ]; then
    echo "$FILE exists."
fi
