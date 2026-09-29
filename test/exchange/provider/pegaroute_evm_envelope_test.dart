import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_native_eth.dart';
import 'package:flutter_test/flutter_test.dart';

// Published EIP-155 example, also retained by web3dart's transaction tests.
// https://eips.ethereum.org/EIPS/eip-155
// Unlike the synthetic caller fixtures, expected sender and envelope are fixed
// independently of this decoder. No private keys or signing computations.
const raw = 'f86c098504a817c800825208943535353535353535353535353535353535353535'
    '880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276'
    'a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83';
const sender = '0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f';

void main() {
  test('published EIP-155 envelope has independently known sender and principal', () {
    final decoded = inspectPegarouteEvm(raw, chainId: 1, sender: sender);
    expect(decoded.to, '0x3535353535353535353535353535353535353535');
    expect(decoded.valueBaseUnits, '1000000000000000000');
    expect(decoded.gasLimit, '21000');
    expect(decoded.data, isNull);
  });
  test('published signature cannot authorize another wallet', () {
    expect(() => inspectPegarouteEvm(raw, chainId: 1,
        sender: '0x1111111111111111111111111111111111111111'), throwsFormatException);
  });
  test('published signature cannot authorize another chain', () {
    expect(() => inspectPegarouteEvm(raw, chainId: 56, sender: sender), throwsFormatException);
  });
}
