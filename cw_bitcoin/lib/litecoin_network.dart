import 'package:bitcoin_flutter/bitcoin_flutter.dart';

final litecoinNetwork = NetworkType(
    messagePrefix: '\x19Litecoin Signed Message:\n',
    bech32: 'ltc',
    bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x30,
    scriptHash: 0x32,
    wif: 0xb0);
