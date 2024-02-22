import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/wallet_type.dart';

class LightningTransactionInfo extends TransactionInfo {
  LightningTransactionInfo(this.type,
      {required String id,
      required int height,
      required int amount,
      int? fee,
      required TransactionDirection direction,
      required bool isPending,
      required DateTime date,
      required int confirmations}) {
    this.id = id;
    this.height = height;
    this.amount = amount;
    this.fee = fee;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.confirmations = confirmations;
  }

  factory LightningTransactionInfo.fromHexAndHeader(WalletType type, String hex,
      {List<String>? addresses, required int height, int? timestamp, required int confirmations}) {
    final tx = bitcoin.Transaction.fromHex(hex);
    var exist = false;
    var amount = 0;

    if (addresses != null) {
      tx.outs.forEach((out) {
        try {
          final p2pkh = bitcoin.P2PKH(
              data: PaymentData(output: out.script), network: bitcoin.bitcoin);
          exist = addresses.contains(p2pkh.data.address);

          if (exist) {
            amount += out.value!;
          }
        } catch (_) {}
      });
    }

    final date = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        : DateTime.now();

    return LightningTransactionInfo(type,
        id: tx.getId(),
        height: height,
        isPending: false,
        fee: null,
        direction: TransactionDirection.incoming,
        amount: amount,
        date: date,
        confirmations: confirmations);
  }

  factory LightningTransactionInfo.fromJson(
      Map<String, dynamic> data, WalletType type) {
    return LightningTransactionInfo(type,
        id: data['id'] as String,
        height: data['height'] as int,
        amount: data['amount'] as int,
        fee: data['fee'] as int,
        direction: parseTransactionDirectionFromInt(data['direction'] as int),
        date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
        isPending: data['isPending'] as bool,
        confirmations: data['confirmations'] as int);
  }

  final WalletType type;

  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(bitcoinAmountToString(amount: amount))} ${walletTypeToCryptoCurrency(type).title}';

  @override
  String? feeFormatted() => fee != null
      ? '${formatAmount(bitcoinAmountToString(amount: fee!))} ${walletTypeToCryptoCurrency(type).title}'
      : '';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  LightningTransactionInfo updated(LightningTransactionInfo info) {
    return LightningTransactionInfo(info.type,
        id: id,
        height: info.height,
        amount: info.amount,
        fee: info.fee,
        direction: direction,
        date: date,
        isPending: isPending,
        confirmations: info.confirmations);
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['height'] = height;
    m['amount'] = amount;
    m['direction'] = direction.index;
    m['date'] = date.millisecondsSinceEpoch;
    m['isPending'] = isPending;
    m['confirmations'] = confirmations;
    m['fee'] = fee;
    return m;
  }
}
