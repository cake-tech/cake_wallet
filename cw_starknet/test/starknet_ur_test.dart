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
        summaryActionName: 'approval',
        summaryTokenAddress: '0x4718',
        summaryAdditionalInfo: {'starknetActionLabel': 'Approval'},
        preferSummary: true,
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
      expect(decoded.summaryActionName, payload.summaryActionName);
      expect(decoded.summaryTokenAddress, payload.summaryTokenAddress);
      expect(decoded.summaryAdditionalInfo, payload.summaryAdditionalInfo);
      expect(decoded.preferSummary, isTrue);
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

    test('encodes and decodes a message sign request and response', () {
      final request = StarknetMessageSignRequestUrPayload(
        accountAddressHex: '0x123',
        publicKeyHex: '0x456',
        message: 'hello starknet',
        messageHashHex: '0xabc',
      );

      final encodedRequest = encodeStarknetMessageSignRequestUrMap(request);
      final decodedRequest = decodeStarknetMessageSignRequestUr(encodedRequest.values.first);

      expect(decodedRequest.accountAddressHex, request.accountAddressHex);
      expect(decodedRequest.publicKeyHex, request.publicKeyHex);
      expect(decodedRequest.message, request.message);
      expect(decodedRequest.messageHashHex, request.messageHashHex);

      final response = StarknetSignatureResponseUrPayload(
        messageHashHex: '0xabc',
        signature: StarknetUrSignature(rHex: '0x1', sHex: '0x2'),
      );
      final encodedResponse = encodeStarknetMessageSignResponseUr(response);
      final decodedResponse = decodeStarknetMessageSignResponseUr(encodedResponse);

      expect(decodedResponse.messageHashHex, response.messageHashHex);
      expect(decodedResponse.signature.rHex, response.signature.rHex);
      expect(decodedResponse.signature.sHex, response.signature.sHex);
    });

    test('encodes and decodes a typed-data sign request and response', () {
      final request = StarknetTypedDataSignRequestUrPayload(
        accountAddressHex: '0x123',
        publicKeyHex: '0x456',
        typedDataJson: '{"types":{},"message":{"hello":"world"}}',
        typedDataHashHex: '0xdef',
      );

      final encodedRequest = encodeStarknetTypedDataSignRequestUrMap(request);
      final decodedRequest = decodeStarknetTypedDataSignRequestUr(encodedRequest.values.first);

      expect(decodedRequest.accountAddressHex, request.accountAddressHex);
      expect(decodedRequest.publicKeyHex, request.publicKeyHex);
      expect(decodedRequest.typedDataJson, request.typedDataJson);
      expect(decodedRequest.typedDataHashHex, request.typedDataHashHex);

      final response = StarknetSignatureResponseUrPayload(
        messageHashHex: '0xdef',
        signature: StarknetUrSignature(rHex: '0xa', sHex: '0xb'),
      );
      final encodedResponse = encodeStarknetTypedDataSignResponseUr(response);
      final decodedResponse = decodeStarknetTypedDataSignResponseUr(encodedResponse);

      expect(decodedResponse.messageHashHex, response.messageHashHex);
      expect(decodedResponse.signature.rHex, response.signature.rHex);
      expect(decodedResponse.signature.sHex, response.signature.sHex);
    });
  });
}
