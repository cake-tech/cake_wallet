import 'package:cw_evm/evm_chain_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EVMChainFormatter', () {
    group('truncateDecimals', () {
      test('no decimals', () => expect(EVMChainFormatter.truncateDecimals("5", 6), "5"));
      test('less than max decimals',
          () => expect(EVMChainFormatter.truncateDecimals("5.00001", 6), "5.00001"));
      test('max decimals',
          () => expect(EVMChainFormatter.truncateDecimals("5.000001", 6), "5.000001"));
      test('more than max decimals',
          () => expect(EVMChainFormatter.truncateDecimals("5.0000001", 6), "5.000000"));
    });
  });
}
