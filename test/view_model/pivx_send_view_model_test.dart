import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIVX send displayed balance fallback', () {
    test('uses transparent available balance outside Sapling mode', () {
      final balance = _pivxBalance(
        availableBalance: '12.345',
        secondAvailableBalance: '6.789',
      );

      expect(
        SendViewModelBase.pivxDisplayedBalanceForSourcePool(
          coinTypeToSpendFrom: UnspentCoinType.transparent,
          pivxBalance: balance,
        ),
        '12.345',
      );
      expect(
        SendViewModelBase.pivxDisplayedBalanceForSourcePool(
          coinTypeToSpendFrom: UnspentCoinType.any,
          pivxBalance: balance,
        ),
        '12.345',
      );
    });

    test('uses shielded second-available balance in Sapling mode', () {
      final balance = _pivxBalance(
        availableBalance: '12.345',
        secondAvailableBalance: '6.789',
      );

      expect(
        SendViewModelBase.pivxDisplayedBalanceForSourcePool(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          pivxBalance: balance,
        ),
        '6.789',
      );
    });

    test('falls back to zero when PIVX balance is unavailable', () {
      expect(
        SendViewModelBase.pivxDisplayedBalanceForSourcePool(
          coinTypeToSpendFrom: UnspentCoinType.transparent,
          pivxBalance: null,
        ),
        '0',
      );
      expect(
        SendViewModelBase.pivxDisplayedBalanceForSourcePool(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          pivxBalance: null,
        ),
        '0',
      );
    });
  });

  group('PIVX send route matrix', () {
    test('leaves empty destinations incomplete', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.transparent,
          destinationAddresses: [''],
        ),
        PivxSendRouteStatus.incomplete,
      );
    });

    test('allows transparent-to-transparent sends', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.transparent,
          destinationAddresses: ['DTransparentAddress'],
        ),
        PivxSendRouteStatus.transparentToTransparent,
      );
    });

    test('allows shielded-to-shielded sends', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          destinationAddresses: ['ps1shieldedaddress'],
        ),
        PivxSendRouteStatus.shieldedToShielded,
      );
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          destinationAddresses: ['ptestsapling1shieldedaddress'],
        ),
        PivxSendRouteStatus.shieldedToShielded,
      );
    });

    test('allows transparent-to-shielded shield route', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.transparent,
          destinationAddresses: ['ps1shieldedaddress'],
        ),
        PivxSendRouteStatus.transparentToShielded,
      );
    });

    test('allows shielded-to-transparent deshield route', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          destinationAddresses: ['DTransparentAddress'],
        ),
        PivxSendRouteStatus.shieldedToTransparent,
      );
    });

    test('blocks mixed transparent and shielded outputs', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.sapling,
          destinationAddresses: ['ps1shieldedaddress', 'DTransparentAddress'],
        ),
        PivxSendRouteStatus.mixedOutputsUnsupported,
      );
    });

    test('blocks ambiguous any-source shielded sends', () {
      expect(
        SendViewModelBase.pivxSendRouteStatusFor(
          coinTypeToSpendFrom: UnspentCoinType.any,
          destinationAddresses: ['ps1shieldedaddress'],
        ),
        PivxSendRouteStatus.ambiguousShieldedSource,
      );
    });
  });
}

BalanceRecord _pivxBalance({
  required String availableBalance,
  required String secondAvailableBalance,
}) {
  return BalanceRecord(
    availableBalance: availableBalance,
    additionalBalance: '0',
    secondAvailableBalance: secondAvailableBalance,
    secondAdditionalBalance: '0',
    frozenBalance: '0',
    fiatAvailableBalance: '0.00',
    fiatAdditionalBalance: '0.00',
    fiatFrozenBalance: '0.00',
    fiatSecondAvailableBalance: '0.00',
    fiatSecondAdditionalBalance: '0.00',
    asset: CryptoCurrency.pivx,
    formattedAssetTitle: 'PIVX',
  );
}
