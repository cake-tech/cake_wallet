import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upstream bitcoin_base parses PIVX D addresses as P2PKH', () {
    const address = 'DNmHG2VuQc54GRa3Hu4QgZ7RLGm1Ly9o3S';
    final parsed = RegexUtils.addressTypeFromStr(address, PivxNetwork.mainnet);
    expect(parsed, isA<P2pkhAddress>());
    expect(parsed.toAddress(PivxNetwork.mainnet), address);
  });
}
