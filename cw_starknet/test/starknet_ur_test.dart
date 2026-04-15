import 'package:cw_starknet/starknet_ur.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Starknet UR codec', () {
    test('encodes and decodes a sign request', () {
      final payload = StarknetSignRequestUrPayload(
        planJson: '{"plan":"value"}',
        accountAddressHex: '0x123',
        publicKeyHex: '0x456',
        accountClassHashHex: '0x789',
        invokeTransactionHashHex: '0xabc',
        deployAccountTransactionHashHex: '0xdef',
        amountWei: '1000',
        amountDecimals: 18,
        amountSymbol: 'STRK',
        destinationAddress: '0xfeed',
        feeWei: '10',
      );

      final encoded = encodeStarknetSignRequestUrMap(payload);
      final decoded = decodeStarknetSignRequestUr(encoded.values.first);

      expect(decoded.planJson, payload.planJson);
      expect(decoded.accountAddressHex, payload.accountAddressHex);
      expect(decoded.publicKeyHex, payload.publicKeyHex);
      expect(decoded.accountClassHashHex, payload.accountClassHashHex);
      expect(decoded.invokeTransactionHashHex, payload.invokeTransactionHashHex);
      expect(decoded.deployAccountTransactionHashHex, payload.deployAccountTransactionHashHex);
      expect(decoded.amountWei, payload.amountWei);
      expect(decoded.amountDecimals, payload.amountDecimals);
      expect(decoded.amountSymbol, payload.amountSymbol);
      expect(decoded.destinationAddress, payload.destinationAddress);
      expect(decoded.feeWei, payload.feeWei);
    });

    test('encodes and decodes a sign response', () {
      final payload = StarknetSignResponseUrPayload(
        planJson: '{"plan":"value"}',
        invokeTransactionHashHex: '0xabc',
        invokeSignature: StarknetUrSignature(rHex: '0x1', sHex: '0x2'),
        deployAccountTransactionHashHex: '0xdef',
        deploySignature: StarknetUrSignature(rHex: '0x3', sHex: '0x4'),
      );

      final encoded = encodeStarknetSignResponseUr(payload);
      final decoded = decodeStarknetSignResponseUr(encoded);

      expect(decoded.planJson, payload.planJson);
      expect(decoded.invokeTransactionHashHex, payload.invokeTransactionHashHex);
      expect(decoded.invokeSignature.rHex, payload.invokeSignature.rHex);
      expect(decoded.invokeSignature.sHex, payload.invokeSignature.sHex);
      expect(decoded.deployAccountTransactionHashHex, payload.deployAccountTransactionHashHex);
      expect(decoded.deploySignature?.rHex, payload.deploySignature?.rHex);
      expect(decoded.deploySignature?.sHex, payload.deploySignature?.sHex);
    });
  });
}
