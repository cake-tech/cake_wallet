import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/keyable.dart';
import 'package:cw_core/wallet_type.dart';

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
    if (balanceViewModel.wallet.type == WalletType.monero) {
      final amount = calculateFiatAmountRaw(
          cryptoAmount: monero.formatterMoneroAmountToDouble(amount: transaction.amount),
          price: price);
      transaction.changeFiatAmount(amount);
    }

    if (balanceViewModel.wallet.type == WalletType.bitcoin
        || balanceViewModel.wallet.type == WalletType.litecoin) {
      final amount = calculateFiatAmountRaw(
          cryptoAmount: bitcoin.formatterBitcoinAmountToDouble(amount: transaction.amount),
          price: price);
      transaction.changeFiatAmount(amount);
    }

    return displayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : fiatCurrency.title + ' ' + transaction.fiatAmount();
  }

  @override
  DateTime get date => transaction.date;
}
