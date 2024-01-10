import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';

List<int> addressToOutputScript(String address, BasedUtxoNetwork network) {
  try {
    // FIXME: improve validation for p2sh addresses
    // 3 for bitcoin
    // m for litecoin
    // (note: m is also for bitcoin's testnet. check networkType to make sure)
    if (address.startsWith('3') ||
        (address.toLowerCase().startsWith('m') && network != BitcoinNetwork.testnet)) {
      return P2shAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
    }

    return addressToOutputScript(address, network);
  } catch (err) {
    print(err);
    return Uint8List(0);
  }
}
