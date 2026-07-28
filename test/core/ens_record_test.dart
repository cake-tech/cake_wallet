import 'package:cake_wallet/core/address_resolver/ens/ens_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('EnsRecord.isZeroAddress', () {
    test('detects the address returned by the registry for an unset resolver', () {
      final address =
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
      expect(EnsRecord.isZeroAddress(address), isTrue);
    });

    test('does not flag a real resolver address', () {
      final address =
          EthereumAddress.fromHex('0xF29100983E058B709F3D539b0c765937B804AC15');
      expect(EnsRecord.isZeroAddress(address), isFalse);
    });

    test('does not flag an address whose leading bytes are zero', () {
      final address =
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000001');
      expect(EnsRecord.isZeroAddress(address), isFalse);
    });
  });
}
