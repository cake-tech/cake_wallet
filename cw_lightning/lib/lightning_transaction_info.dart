import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/wallet_type.dart';

class LightningTransactionInfo extends TransactionInfo {
  LightningTransactionInfo(
    this.type, {
    required String id,
    required int amount,
    int? fee,
    required TransactionDirection direction,
    required bool isPending,
    required DateTime date,
  }) {
    this.id = id;
    this.amount = amount;
    this.fee = fee;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
  }

  factory LightningTransactionInfo.fromHexAndHeader(WalletType type, String hex,
      {List<String>? addresses, required int height, int? timestamp, required int confirmations}) {
    final tx = bitcoin.Transaction.fromHex(hex);
    var exist = false;
    var amount = 0;

    if (addresses != null) {
      tx.outs.forEach((out) {
        try {
          final p2pkh =
              bitcoin.P2PKH(data: PaymentData(output: out.script), network: bitcoin.bitcoin);
          exist = addresses.contains(p2pkh.data.address);

          if (exist) {
            amount += out.value!;
          }
        } catch (_) {}
      });
    }

    final date =
        timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000) : DateTime.now();

    return LightningTransactionInfo(
      type,
      id: tx.getId(),
      isPending: false,
      fee: null,
      direction: TransactionDirection.incoming,
      amount: amount,
      date: date,
    );
  }

  factory LightningTransactionInfo.fromJson(Map<String, dynamic> data, WalletType type) {
    return LightningTransactionInfo(
      type,
      id: data['id'] as String,
      amount: data['amount'] as int,
      fee: data['fee'] as int,
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool,
    );
  }

  final WalletType type;

  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(bitcoinAmountToLightningString(amount: amount))} ${walletTypeToCryptoCurrency(type).title}';

  @override
  String? feeFormatted() => fee != null
      ? '${formatAmount(bitcoinAmountToLightningString(amount: fee!))} ${walletTypeToCryptoCurrency(type).title}'
      : '';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  LightningTransactionInfo updated(LightningTransactionInfo info) {
    return LightningTransactionInfo(
      info.type,
      id: id,
      amount: info.amount,
      fee: info.fee,
      direction: direction,
      date: date,
      isPending: isPending,
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['amount'] = amount;
    m['direction'] = direction.index;
    m['date'] = date.millisecondsSinceEpoch;
    m['isPending'] = isPending;
    m['fee'] = fee;
    return m;
  }
}
