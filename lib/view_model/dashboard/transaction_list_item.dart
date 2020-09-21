import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';

class TransactionListItem extends ActionListItem {
  TransactionListItem({
    this.transaction,
    this.price,
    this.fiatCurrency,
    this.displayMode
  });

  final TransactionInfo transaction;
  final double price;
  final FiatCurrency fiatCurrency;
  final BalanceDisplayMode displayMode;

  String get formattedCryptoAmount {

    return displayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : transaction.amountFormatted();
  }

  String get formattedFiatAmount {

    if (transaction is MoneroTransactionInfo) {
      final amount = calculateFiatAmountRaw(
          cryptoAmount: moneroAmountToDouble(amount: transaction.amount),
          price: price);
      transaction.changeFiatAmount(amount);
    }

    if (transaction is BitcoinTransactionInfo) {
      final amount = calculateFiatAmountRaw(
          cryptoAmount: bitcoinAmountToDouble(amount: transaction.amount),
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