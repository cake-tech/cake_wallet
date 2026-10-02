import "dart:typed_data";

import "package:cw_evm/clients/evm_chain_client.dart";
import "package:cw_evm/utils/network_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";
import "package:web3dart/web3dart.dart";

void main() {
  final sender = EthereumAddress.fromHex("0x52908400098527886E0F7030069857D2E4169EE7");
  final recipient = EthereumAddress.fromHex("0x8617E340B3D01FA5F11F306F4090FD50E238070D");

  final gasWithBaseFee = GasParamsHandler(
    estimatedGasUnits: 21000,
    estimatedGasFee: 651000000000000,
    maxFeePerGas: 31000000000,
    gasPrice: 29000000000,
    priorityFeeWei: 1500000000,
    hasBaseFee: true,
  );

  // Gas from a node that reports no base fee, so an added network like chain 10 sends legacy
  final gasWithoutBaseFee = GasParamsHandler(
    estimatedGasUnits: 21000,
    estimatedGasFee: 609000000000000,
    maxFeePerGas: 29000000000,
    gasPrice: 29000000000,
    priorityFeeWei: 0,
    hasBaseFee: false,
  );

  Transaction build(FeeType feeType, GasParamsHandler gas, {int chainId = 10}) =>
      EVMChainClient(chainId: chainId, feeType: feeType).createTransaction(
        from: sender,
        to: recipient,
        amount: EtherAmount.zero(),
        maxGas: gas.estimatedGasUnits,
        gasParams: gas,
      );

  group("EVMChainClient transaction shape", () {
    test("legacy carries the gas price only", () {
      final transaction = build(FeeType.legacy, gasWithBaseFee);

      expect(transaction.gasPrice?.getInWei, BigInt.from(29000000000));
      expect(transaction.maxFeePerGas, isNull);
      expect(transaction.maxPriorityFeePerGas, isNull);
      expect(transaction.isEIP1559, isFalse);
    });

    test("type-2 carries the two EIP-1559 fields and no gas price", () {
      final transaction = build(FeeType.eip1559, gasWithBaseFee);

      expect(transaction.maxFeePerGas?.getInWei, BigInt.from(31000000000));
      expect(transaction.maxPriorityFeePerGas?.getInWei, BigInt.from(1500000000));
      expect(transaction.gasPrice, isNull);
      expect(transaction.isEIP1559, isTrue);
    });

    test("an EIP-1559 chain whose node reports no base fee is sent legacy", () {
      final transaction = build(FeeType.eip1559OrLegacy, gasWithoutBaseFee);

      expect(transaction.isEIP1559, isFalse);
      expect(transaction.gasPrice?.getInWei, BigInt.from(29000000000));
    });

    test("an EIP-1559 chain without a base fee signs and sends a legacy body", () async {
      final client = EVMChainClient(chainId: 10, feeType: FeeType.eip1559OrLegacy);
      final transaction = build(FeeType.eip1559OrLegacy, gasWithoutBaseFee)
          .copyWith(nonce: 3, value: EtherAmount.zero(), data: Uint8List(0));
      final privateKey = EthPrivateKey.fromHex(
        "4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318",
      );

      final signed = await signTransactionRaw(transaction, privateKey, chainId: 10);
      final prepared =
          client.prepareSignedTransactionForSending(signed, isType2: transaction.isEIP1559);

      // A legacy body is an RLP list, so it starts at 0xc0 or above, never with a type byte
      expect(signed.first, greaterThanOrEqualTo(0xc0));
      expect(prepared, signed);
    });

    test("Ethereum keeps the type-2 envelope when its node reports no base fee", () async {
      const ethereumChainId = 1;
      final client = EVMChainClient(chainId: ethereumChainId, feeType: FeeType.eip1559);
      final transaction = build(FeeType.eip1559, gasWithoutBaseFee, chainId: ethereumChainId)
          .copyWith(nonce: 3, value: EtherAmount.zero(), data: Uint8List(0));
      final privateKey = EthPrivateKey.fromHex(
        "4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318",
      );

      expect(transaction.isEIP1559, isTrue);
      expect(transaction.maxFeePerGas?.getInWei, BigInt.from(29000000000));
      expect(transaction.gasPrice, isNull);

      final signed = await signTransactionRaw(transaction, privateKey, chainId: ethereumChainId);
      final prepared =
          client.prepareSignedTransactionForSending(signed, isType2: transaction.isEIP1559);

      expect(prepared.first, 0x02);
    });

    test("an added network whose node reports a base fee sends type-2", () {
      final transaction = build(FeeType.eip1559OrLegacy, gasWithBaseFee);

      expect(transaction.isEIP1559, isTrue);
      expect(transaction.maxPriorityFeePerGas?.getInWei, BigInt.from(1500000000));
      expect(transaction.gasPrice, isNull);
    });

    test("an added network with a base fee but no usable tip sends legacy at the max fee", () {
      // What the wallet builds when fetchPriorityFeeFromNode gives null for a 7000000 base fee
      final gasWithoutTip = GasParamsHandler(
        estimatedGasUnits: 21000,
        estimatedGasFee: 169050000000,
        maxFeePerGas: 8050000,
        gasPrice: 8050000,
        priorityFeeWei: null,
        hasBaseFee: true,
      );

      final transaction = build(FeeType.eip1559OrLegacy, gasWithoutTip);

      expect(transaction.isEIP1559, isFalse);
      expect(transaction.gasPrice?.getInWei, BigInt.from(8050000));
      expect(transaction.maxFeePerGas, isNull);
      expect(transaction.maxPriorityFeePerGas, isNull);
    });

    test("the 0x02 envelope byte is added only to a type-2 body", () {
      final client = EVMChainClient(chainId: 10, feeType: FeeType.eip1559);
      final signedBody = Uint8List.fromList([0xf8, 0x6b, 0x01]);

      expect(
        client.prepareSignedTransactionForSending(signedBody, isType2: true),
        [0x02, 0xf8, 0x6b, 0x01],
      );
      expect(
        client.prepareSignedTransactionForSending(signedBody, isType2: false),
        [0xf8, 0x6b, 0x01],
      );
    });
  });
}
