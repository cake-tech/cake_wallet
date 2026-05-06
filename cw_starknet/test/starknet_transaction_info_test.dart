import 'package:flutter_test/flutter_test.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';

void main() {
  group('StarknetTransactionInfo', () {
    late StarknetTransactionInfo txInfo;

    setUp(() {
      txInfo = StarknetTransactionInfo(
        id: '0xabc123:0',
        transactionHash: '0xabc123',
        blockTime: DateTime(2025, 1, 15, 12, 30),
        to: '0xrecipient',
        from: '0xsender',
        direction: TransactionDirection.outgoing,
        amountWei: '1500',
        tokenAddress: '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d',
        tokenDecimals: 3,
        tokenSymbol: 'STRK',
        isPending: false,
        txFeeWei: '1000000000000000',
        evmSignatureName: 'approval',
        additionalInfo: {'starknetActionLabel': 'Approval'},
        height: 42,
      );
    });

    test('properties are set correctly', () {
      expect(txInfo.id, '0xabc123:0');
      expect(txInfo.transactionHash, '0xabc123');
      expect(txInfo.to, '0xrecipient');
      expect(txInfo.from, '0xsender');
      expect(txInfo.direction, TransactionDirection.outgoing);
      expect(txInfo.rawAmountAsDouble(), 1.5);
      expect(txInfo.tokenSymbol, 'STRK');
      expect(txInfo.isPending, false);
      expect(txInfo.txFeeWei, '1000000000000000');
      expect(txInfo.evmSignatureName, 'approval');
      expect(txInfo.additionalInfo['starknetActionLabel'], 'Approval');
      expect(txInfo.height, 42);
    });

    test('amount stores raw token units', () {
      expect(txInfo.amount, 1500);
    });

    test('date returns blockTime', () {
      expect(txInfo.date, txInfo.blockTime);
    });

    test('amountFormatted includes token symbol', () {
      final formatted = txInfo.amountFormatted();
      expect(formatted.contains('1.5'), true);
      expect(formatted.contains('STRK'), true);
    });

    test('amountFormatted truncates long amounts', () {
      final longTx = StarknetTransactionInfo(
        id: '0x1:0',
        transactionHash: '0x1',
        blockTime: DateTime.now(),
        to: '0x1',
        from: '0x2',
        direction: TransactionDirection.incoming,
        amountWei: '1123456789012345678',
        tokenAddress: '0x1',
        tokenDecimals: 18,
        tokenSymbol: 'STRK',
        isPending: false,
        txFeeWei: '0',
      );
      final formatted = longTx.amountFormatted();
      // Amount part (before space+symbol) should be truncated
      expect(formatted.length, lessThan(30));
    });

    test('feeFormatted shows fee in STRK', () {
      expect(txInfo.feeFormatted(), '0.001 STRK');
    });

    test('default token symbol is STRK', () {
      final tx = StarknetTransactionInfo(
        id: '0x1:0',
        transactionHash: '0x1',
        blockTime: DateTime.now(),
        to: '0x1',
        from: '0x2',
        direction: TransactionDirection.incoming,
        amountWei: '1000',
        tokenAddress: '0x1',
        tokenDecimals: 3,
        isPending: false,
        tokenSymbol: 'STRK',
        txFeeWei: '0',
      );
      expect(tx.tokenSymbol, 'STRK');
    });

    test('fiatAmount starts empty', () {
      expect(txInfo.fiatAmount(), '');
    });

    test('changeFiatAmount sets fiat value', () {
      txInfo.changeFiatAmount('12.50');
      expect(txInfo.fiatAmount(), isNotEmpty);
    });

    test('formats Starknet decoded details', () {
      final detailedTx = StarknetTransactionInfo(
        id: '0x2:0',
        transactionHash: '0x2',
        blockTime: DateTime.now(),
        to: '0xrouter',
        from: '0xsender',
        direction: TransactionDirection.outgoing,
        amountWei: '0',
        tokenAddress: '0xstrk',
        tokenDecimals: 18,
        tokenSymbol: 'STRK',
        isPending: false,
        txFeeWei: '2000000000000000',
        evmSignatureName: 'swap',
        additionalInfo: {
          'starknetTransactionType': 'INVOKE',
          'starknetExecutionStatus': 'SUCCEEDED',
          'starknetFinalityStatus': 'ACCEPTED_ON_L2',
          'starknetExecutionFeeWei': '1500000000000000',
          'starknetDeployAccountFeeWei': '500000000000000',
          'starknetFeePriorityLabel': 'Fast',
          'starknetCallCount': 3,
          'starknetPrimaryContract': '0xrouter',
          'starknetPrimaryEntrypoint': 'swap_exact_tokens_for_tokens',
          'starknetTip': 7,
          'starknetAccountDeploymentRequired': true,
        },
      );

      expect(detailedTx.transactionTypeLabel(), 'Invoke');
      expect(detailedTx.executionStatusLabel(), 'Succeeded');
      expect(detailedTx.finalityStatusLabel(), 'Accepted On L2');
      expect(detailedTx.executionFeeFormatted(), '0.0015 STRK');
      expect(detailedTx.deployAccountFeeFormatted(), '0.0005 STRK');
      expect(detailedTx.feePriorityLabel(), 'Fast');
      expect(detailedTx.callCountLabel(), '3');
      expect(detailedTx.primaryContractAddress(), '0xrouter');
      expect(detailedTx.primaryEntrypoint(), 'swap_exact_tokens_for_tokens');
      expect(detailedTx.transactionTipLabel(), '7');
      expect(detailedTx.accountDeploymentRequired, isTrue);
    });

    group('JSON serialization', () {
      test('toJson contains all fields', () {
        final json = txInfo.toJson();

        expect(json['id'], '0xabc123:0');
        expect(json['transactionHash'], '0xabc123');
        expect(json['amountWei'], '1500');
        expect(json['direction'], TransactionDirection.outgoing.index);
        expect(json['isPending'], false);
        expect(json['tokenSymbol'], 'STRK');
        expect(json['tokenAddress'], isNotEmpty);
        expect(json['tokenDecimals'], 3);
        expect(json['to'], '0xrecipient');
        expect(json['from'], '0xsender');
        expect(json['txFeeWei'], '1000000000000000');
        expect(json['blockTime'], isA<int>());
        expect(json['evmSignatureName'], 'approval');
        expect(json['additionalInfo'], {'starknetActionLabel': 'Approval'});
        expect(json['height'], 42);
      });

      test('fromJson round-trips correctly', () {
        final json = txInfo.toJson();
        final restored = StarknetTransactionInfo.fromJson(json);

        expect(restored.id, txInfo.id);
        expect(restored.transactionHash, txInfo.transactionHash);
        expect(restored.amountWei, txInfo.amountWei);
        expect(restored.direction, txInfo.direction);
        expect(restored.isPending, txInfo.isPending);
        expect(restored.tokenSymbol, txInfo.tokenSymbol);
        expect(restored.tokenAddress, txInfo.tokenAddress);
        expect(restored.tokenDecimals, txInfo.tokenDecimals);
        expect(restored.to, txInfo.to);
        expect(restored.from, txInfo.from);
        expect(restored.txFeeWei, txInfo.txFeeWei);
        expect(restored.blockTime.millisecondsSinceEpoch, txInfo.blockTime.millisecondsSinceEpoch);
        expect(restored.evmSignatureName, txInfo.evmSignatureName);
        expect(restored.additionalInfo, txInfo.additionalInfo);
        expect(restored.height, txInfo.height);
      });

      test('fromJson handles incoming direction', () {
        final json = {
          'id': '0x1:0',
          'transactionHash': '0x1',
          'amountWei': '2000000',
          'direction': TransactionDirection.incoming.index,
          'blockTime': DateTime.now().millisecondsSinceEpoch,
          'isPending': true,
          'tokenAddress': '0xeth',
          'tokenDecimals': 6,
          'tokenSymbol': 'ETH',
          'to': '0xme',
          'from': '0xyou',
          'txFeeWei': '10000000000000000',
        };

        final tx = StarknetTransactionInfo.fromJson(json);
        expect(tx.direction, TransactionDirection.incoming);
        expect(tx.isPending, true);
        expect(tx.tokenSymbol, 'ETH');
        expect(tx.rawAmountAsDouble(), 2.0);
      });
    });
  });
}
