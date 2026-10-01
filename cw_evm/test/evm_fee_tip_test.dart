import "package:cw_evm/clients/evm_chain_client.dart";
import "package:cw_evm/evm_chain_exceptions.dart";
import "package:cw_evm/evm_chain_transaction_priority.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";
import "package:cw_evm/utils/network_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";
import "package:web3dart/web3dart.dart";

void main() {
  group("priorityFeeFromFeeHistory", () {
    // One row per block, columns are the 25th, 50th and 75th reward percentiles
    final rewards = [
      [BigInt.from(10), BigInt.from(200), BigInt.from(3000)],
      [BigInt.from(20), BigInt.from(400), BigInt.from(6000)],
      [BigInt.from(30), BigInt.from(600), BigInt.from(9000)],
    ];

    test("each priority takes the median of its own percentile column", () {
      expect(priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.slow), BigInt.from(20));
      expect(
        priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.medium),
        BigInt.from(400),
      );
      expect(
        priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.fast),
        BigInt.from(6000),
      );
    });

    test("one block with a huge tip does not move the median", () {
      final rewards = [
        [BigInt.zero, BigInt.from(1000), BigInt.zero],
        [BigInt.zero, BigInt.from(3000), BigInt.zero],
        [BigInt.zero, BigInt.from(2000), BigInt.zero],
        [BigInt.zero, BigInt.from(37000000), BigInt.zero],
        [BigInt.zero, BigInt.from(4000), BigInt.zero],
      ];

      expect(
        priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.medium),
        BigInt.from(3000),
      );
    });

    test("an even number of blocks takes the mean of the two middle tips", () {
      final rewards = [
        [BigInt.from(7)],
        [BigInt.from(1)],
        [BigInt.from(100)],
        [BigInt.from(4)],
      ];

      expect(priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.slow), BigInt.from(5));
    });

    test("an empty history has no tip, so the caller asks eth_maxPriorityFeePerGas", () {
      expect(priorityFeeFromFeeHistory([], EVMChainTransactionPriority.medium), isNull);
      expect(priorityFeeFromFeeHistory([[]], EVMChainTransactionPriority.medium), isNull);
    });

    test("a hostile 2^200 reward stays a BigInt without narrowing to int", () {
      final hostile = BigInt.two.pow(200);

      final rewards = [
        [hostile, hostile, hostile],
      ];

      expect(priorityFeeFromFeeHistory(rewards, EVMChainTransactionPriority.medium), hostile);
    });

    test("the estimate's tip is the envelope's max priority fee", () {
      final gas = GasParamsHandler(
        estimatedGasUnits: 21000,
        estimatedGasFee: 105000000,
        maxFeePerGas: 5000,
        gasPrice: 4000,
        priorityFeeWei: 400,
        hasBaseFee: true,
      );
      final address = EthereumAddress.fromHex("0x52908400098527886E0F7030069857D2E4169EE7");

      final transaction = EVMChainClient(chainId: 10, feeType: FeeType.eip1559).createTransaction(
        from: address,
        to: address,
        amount: EtherAmount.zero(),
        gasParams: gas,
      );

      expect(transaction.maxPriorityFeePerGas?.getInWei, BigInt.from(400));
    });
  });

  group("boundedPriorityFee", () {
    const baseFee = 7000000;
    const hundredGwei = 100000000000;

    test("a hostile 2^200 tip is rejected instead of saturating at int64 max", () {
      expect(boundedPriorityFee(BigInt.two.pow(200), baseFee), isNull);
    });

    test("a negative tip is rejected and a zero tip is kept", () {
      expect(boundedPriorityFee(BigInt.from(-5), baseFee), isNull);
      expect(boundedPriorityFee(BigInt.zero, baseFee), 0);
    });

    test("with a small base fee the bound is 100 gwei", () {
      expect(boundedPriorityFee(BigInt.from(hundredGwei), baseFee), hundredGwei);
      expect(boundedPriorityFee(BigInt.from(hundredGwei + 1), baseFee), isNull);
    });

    test("with a large base fee the bound is ten base fees", () {
      const fiftyGwei = 50000000000;

      expect(boundedPriorityFee(BigInt.from(fiftyGwei * 10), fiftyGwei), fiftyGwei * 10);
      expect(boundedPriorityFee(BigInt.from(fiftyGwei * 10 + 1), fiftyGwei), isNull);
    });
  });

  group("computeBufferedMaxFeePerGasWei", () {
    test("a fee past int64 throws instead of wrapping negative", () {
      expect(
        () => EVMChainUtils.computeBufferedMaxFeePerGasWei(
          gasBaseFee: 9223372036854775807,
          gasPrice: 1,
          priorityFeeWei: 1,
          chainHasPriorityFee: true,
        ),
        throwsA(isA<EVMChainTransactionFeesException>()),
      );
      expect(
        () => EVMChainUtils.computeBufferedMaxFeePerGasWei(
          gasBaseFee: null,
          gasPrice: 9223372036854775807,
          priorityFeeWei: 1,
          chainHasPriorityFee: true,
        ),
        throwsA(isA<EVMChainTransactionFeesException>()),
      );
    });

    test("base fee plus tip gets the 15% buffer", () {
      expect(
        EVMChainUtils.computeBufferedMaxFeePerGasWei(
          gasBaseFee: 7000000,
          gasPrice: 1,
          priorityFeeWei: 1000,
          chainHasPriorityFee: true,
        ),
        8051150,
      );
    });
  });

  group("fetchPriorityFeeFromNode", () {
    test("a chain without a base fee gets no tip", () async {
      final client = EVMChainClient(chainId: 10, feeType: FeeType.eip1559);

      expect(await client.fetchPriorityFeeFromNode(EVMChainTransactionPriority.fast, null), 0);
    });

    test("a node answering neither fee method gives null instead of a zero tip", () async {
      // Never connected, so eth_feeHistory and eth_maxPriorityFeePerGas both fail
      final client = EVMChainClient(chainId: 10, feeType: FeeType.eip1559);

      expect(
        await client.fetchPriorityFeeFromNode(EVMChainTransactionPriority.fast, 7000000),
        isNull,
      );
    });
  });
}
