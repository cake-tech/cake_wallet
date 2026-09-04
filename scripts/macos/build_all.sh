#!/bin/sh

./build_torch.sh

./build_scanqr.sh

./build_monero_all.sh universal && ./build_decred.sh
