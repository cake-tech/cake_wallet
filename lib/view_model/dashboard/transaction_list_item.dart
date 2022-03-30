import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/keyable.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_haven/haven_transaction_info.dart';

class TransactionListItem extends ActionListItem with Keyable {
  TransactionListItem(
      {this.transaction, this.balanceViewModel, this.settingsStore});

  final TransactionInfo transaction;
  final BalanceViewModel balanceViewModel;
  final SettingsStore settingsStore;

  double get price => balanceViewModel.price;

  FiatCurrency get fiatCurrency => settingsStore.fiatCurrency;

  BalanceDisplayMode get displayMode => settingsStore.balanceDisplayMode;

  @override
  dynamic get keyIndex => transaction.id;

  String get formattedCryptoAmount {
    return displayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : transaction.amountFormatted();
  }

  String get formattedFiatAmount {
    var amount = '';

    switch(balanceViewModel.wallet.type) {
      case WalletType.monero:
        amount = calculateFiatAmountRaw(
          cryptoAmount: monero.formatterMoneroAmountToDouble(amount: transaction.amount),
          price: price);
        break;
      case WalletType.bitcoin:
      case WalletType.litecoin:
        amount = calculateFiatAmountRaw(
          cryptoAmount: bitcoin.formatterBitcoinAmountToDouble(amount: transaction.amount),
          price: price);
        break;
      case WalletType.haven:
        final tx = transaction as HavenTransactionInfo;
        final asset = CryptoCurrency.fromString(tx.assetType);
        final price = balanceViewModel.fiatConvertationStore.prices[asset];
        amount = calculateFiatAmountRaw(
          cryptoAmount: haven.formatterMoneroAmountToDouble(amount: transaction.amount),
          price: price);
        break;
      default:
        break;
    }

    transaction.changeFiatAmount(amount);
    return displayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : fiatCurrency.title + ' ' + transaction.fiatAmount();
  }

  @override
  DateTime get date => transaction.date;
}
