import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:mocktail/mocktail.dart";

class _MockAppStore extends Mock implements AppStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockDescriptionBox extends Mock implements Box<TransactionDescription> {}

class _MockSendViewModel extends Mock implements SendViewModel {}

class _BitcoinWithoutFeeBumping extends CWBitcoin {
  @override
  Future<String?> canReplaceByFee(Object wallet, Object transactionInfo) async => null;
}

class _Transaction extends TransactionInfo {
  _Transaction(TransactionDirection direction, Map<String, dynamic> additionalInfo) {
    final currency =
        additionalInfo["isLightning"] == true ? CryptoCurrency.btcln : CryptoCurrency.btc;
    id = "payment-id";
    amount = Money.fromInt(1000, currency);
    fee = Money.fromInt(1, currency);
    this.direction = direction;
    isPending = false;
    date = DateTime(2026, 11, 17, 12);
    confirmations = 10;
    this.additionalInfo = additionalInfo;
  }
}

List<String> _memoRows(_Transaction transaction) {
  final appStore = _MockAppStore();
  final settings = _MockSettingsStore();
  final wallet = _MockWallet();
  final addresses = _MockWalletAddresses();
  final descriptions = _MockDescriptionBox();

  when(() => appStore.settingsStore).thenReturn(settings);
  when(() => appStore.amountParsingProxy)
      .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.satoshiForLightning));
  when(() => settings.shouldSaveRecipientAddress).thenReturn(false);
  when(() => settings.languageCode).thenReturn("en");
  when(() => wallet.type).thenReturn(WalletType.bitcoin);
  when(() => wallet.walletAddresses).thenReturn(addresses);
  when(() => addresses.primaryAddress).thenReturn("bc1qprimary");
  when(() => descriptions.values).thenReturn(<TransactionDescription>[]);

  final viewModel = TransactionDetailsViewModel(
    transactionInfo: transaction,
    transactionDescriptionBox: descriptions,
    wallet: wallet,
    appStore: appStore,
    sendViewModel: _MockSendViewModel(),
  );

  return viewModel.items
      .where((item) => item.title == S.current.memo)
      .map((item) => item.value)
      .toList();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting("en");
    S.current = const S();
  });

  setUp(() {
    final appBitcoin = bitcoin;
    bitcoin = _BitcoinWithoutFeeBumping();
    addTearDown(() => bitcoin = appBitcoin);
  });

  test("a sent Lightning payment shows its memo", () {
    final payment = _Transaction(
      TransactionDirection.outgoing,
      {"isLightning": true, "memo": "Thanks for dinner"},
    );

    expect(_memoRows(payment), ["Thanks for dinner"]);
  });

  test("a received Lightning payment shows the sender's comment", () {
    final payment = _Transaction(
      TransactionDirection.incoming,
      {"isLightning": true, "memo": "Happy birthday"},
    );

    expect(_memoRows(payment), ["Happy birthday"]);
  });

  test("a Lightning payment without a memo has no memo row", () {
    final payment = _Transaction(TransactionDirection.outgoing, {"isLightning": true});

    expect(_memoRows(payment), isEmpty);
  });

  test("an on-chain Bitcoin transaction has no memo row", () {
    final transaction = _Transaction(TransactionDirection.incoming, {"memo": "not lightning"});

    expect(_memoRows(transaction), isEmpty);
  });
}
