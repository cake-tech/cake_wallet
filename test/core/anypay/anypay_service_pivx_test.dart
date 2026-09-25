import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/wallet_switch_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _AppStore extends Mock implements AppStore {}

class _SwitchService extends Mock implements WalletSwitchService {}

class _Wallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  // PIVX D... addrs share Dogecoin's version byte, so the detector reads them as Doge.
  const pivxAddress = "DEEprWtZfUGBMah9FFLuxouapE6LtxcnEU";
  const exmAddress = "EXMQ3t6kSpkdbLj714JheTo4sSsZ1Tiw7Dne";
  const shieldedAddress =
      "ps1sgv40dhuz3y6jq0k3zu5s3h4wyq8wrl0up2hsxpmaysl9s4xxxd8cj4cqwhndqxd7r0dcuz8e29";

  late AnyPayService service;
  late _AppStore appStore;
  late _Wallet wallet;

  // AddressValidator reads S.current; unloaded, the guard throws into the catch.
  setUpAll(() => S.delegate.load(const Locale("en")));

  setUp(() {
    wallet = _Wallet();
    when(() => wallet.type).thenReturn(WalletType.pivx);
    when(() => wallet.currency).thenReturn(CryptoCurrency.pivx);
    when(() => wallet.isTestnet).thenReturn(false);
    appStore = _AppStore();
    when(() => appStore.wallet).thenReturn(wallet);
    service = AnyPayService(appStore: appStore, walletSwitchService: _SwitchService());
  });

  for (final address in [pivxAddress, exmAddress, shieldedAddress]) {
    test("$address stays a native send in a PIVX wallet", () async {
      final evaluation = await service.evaluateRawInput(address);
      final decision = evaluation.decision as AnyPayApplyToCurrentWallet;
      expect(decision.fallbackCurrency, isNull);
      // The guard validated and answered; routing would read the wallet again.
      verify(() => wallet.currency).called(1);
      verify(() => appStore.wallet).called(1);
    });
  }

  test("pivx: URI with an amount keeps PIVX as the currency", () async {
    final evaluation = await service.evaluateRawInput("pivx:$pivxAddress?amount=1.5");
    final decision = evaluation.decision as AnyPayApplyToCurrentWallet;
    expect(decision.fallbackCurrency, CryptoCurrency.pivx);
    expect(evaluation.request.amount, "1.5");
    verify(() => wallet.currency).called(greaterThanOrEqualTo(1));
    verify(() => appStore.wallet).called(1);
  });
}
