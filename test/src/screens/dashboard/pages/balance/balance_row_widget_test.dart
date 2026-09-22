import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_row_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BalanceRowWidget MWEB controls', () {
    test('shows MWEB controls only for Litecoin LTC balances', () {
      expect(
        BalanceRowWidget.shouldShowLitecoinMwebControls(
          walletType: WalletType.litecoin,
          currency: CryptoCurrency.ltc,
        ),
        isTrue,
      );
    });

    test('does not show Litecoin MWEB controls for PIVX shielded rows', () {
      expect(
        BalanceRowWidget.shouldShowLitecoinMwebControls(
          walletType: WalletType.pivx,
          currency: CryptoCurrency.pivx,
        ),
        isFalse,
      );
    });

    test('does not show MWEB controls for non-Litecoin wallets using LTC asset',
        () {
      expect(
        BalanceRowWidget.shouldShowLitecoinMwebControls(
          walletType: WalletType.pivx,
          currency: CryptoCurrency.ltc,
        ),
        isFalse,
      );
    });
  });
}
