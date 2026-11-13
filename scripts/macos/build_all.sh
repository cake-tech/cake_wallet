#!/bin/sh

./build_torch.sh

./build_monero_all.sh universal && ./build_decred.sh || exit 1

if [ "$APP_MACOS_TYPE" = "cakewallet" ]; then
	../prepare_minotari.sh macos
fi
