import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin;

List<int> addressToOutputScript(String address, bitcoin.BasedUtxoNetwork network) {
  try {
    // FIXME: improve validation for p2sh addresses
    // 3 for bitcoin
    // m for litecoin
    // (note: m is also for bitcoin's testnet. check networkType to make sure)
    if (address.startsWith('3') ||
        (address.toLowerCase().startsWith('m') && network != bitcoin.BitcoinNetwork.testnet)) {
      return bitcoin.P2shAddress.fromAddress(address: address, network: network)
          .toScriptPubKey()
          .toBytes();
    }

    return bitcoin.addressToOutputScript(address: address, network: network);
  } catch (err) {
    print(err);
    return Uint8List(0);
  }
}
