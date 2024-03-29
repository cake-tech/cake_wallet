import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin;

List<int> addressToOutputScript(String address, bitcoin.BasedUtxoNetwork network) {
  try {
    if (network == bitcoin.BitcoinCashNetwork.mainnet) {
      return bitcoin.BitcoinCashAddress(address).baseAddress.toScriptPubKey().toBytes();
    }
    return bitcoin.addressToOutputScript(address: address, network: network);
  } catch (err) {
    print(err);
    return Uint8List(0);
  }
}
