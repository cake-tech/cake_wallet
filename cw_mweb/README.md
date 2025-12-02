# cw_mweb

MimbleWimble Extension Blocks (MWEB) integration bridge for Cake Wallet modules that support MWEB-enabled chains.

## Features

- Dart platform interface and method-channel implementation.
- Protobuf stubs for `mwebd` interactions (`mwebd.pb*.dart`).
- Provides a uniform API surface for MWEB-capable coins.

## Usage

Import `cw_mweb` and use the platform interface to interact with an MWEB daemon/binding. See the chain-specific modules for concrete usage.
