import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_api.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_execution_terms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const target = '0x0000000000000000000000000000000000000001';
  const token = '0x0000000000000000000000000000000000000002';
  final amount = PegarouteTokenAmount(display: '1', baseUnits: '1000000000000000000');
  final execution = PegarouteExecution(family: 'evm', mode: 'contract-call', chainId: 1,
      to: target, data: '0x1234', value: amount,
      approval: PegarouteEvmApproval(spender: target, tokenAddress: token, amount: amount));

  for (final boundary in ['creation', 'store']) {
    test('$boundary checks the same reviewed target, memo, and spender', () {
      void validate(Map<String, dynamic> route) {
        if (boundary == 'creation') {
          PegarouteExecutionTerms.validateProviderDetails(
              provider: PegarouteProviderInfo(name: 'thorchain'), route: route,
              execution: execution, sourceChain: 'ETH', sourceAmount: '1');
        } else {
          PegarouteExecutionTerms.validateReviewedExecution(
              route: route, execution: execution, sourceChain: 'ETH');
        }
      }
      final route = <String, dynamic>{'provider': 'thorchain', 'router': target, 'memo': null};
      expect(() => validate(route), returnsNormally);
      for (final changed in [
        {...route, 'router': token},
        {...route, 'router': null},
        {...route, 'memo': 'changed'},
        {...route, 'memo': 1},
        {...route, 'router': null, 'inboundAddress': target}, // Unbound approval spender.
      ]) {
        expect(() => validate(changed), throwsA(isA<PegarouteCodecException>()));
      }
      // OpenOcean's authenticated target and spender remain allowed without a quoted router.
      expect(() => validate({...route, 'provider': 'openocean', 'router': null}), returnsNormally);
    });
  }

  test('creation still cross-checks API deposit details before common route checks', () {
    final deposit = PegarouteExecution(family: 'evm', mode: 'native-transfer', chainId: 1,
        to: target, value: amount);
    void validate(Map<String, dynamic> details) => PegarouteExecutionTerms.validateProviderDetails(
        provider: PegarouteProviderInfo(name: 'instaswap', referenceId: 'reference',
            details: {'instaswapSwapLite': details}),
        route: {'provider': 'instaswap', 'memo': null}, execution: deposit,
        sourceChain: 'ETH', sourceAmount: '1');
    final details = {'txid': 'reference', 'depositAddress': target, 'depositAmountExact': '1'};
    expect(() => validate(details), returnsNormally);
    for (final changed in [
      {...details, 'txid': 'changed'},
      {...details, 'depositAddress': token},
      {...details, 'depositAmountExact': '2'},
      {...details, 'expiresAt': 'invalid'},
    ]) {
      expect(() => validate(changed), throwsA(isA<PegarouteCodecException>()));
    }
  });
}
