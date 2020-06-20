import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

class BitcoinTransactionInfo extends TransactionInfo {
  BitcoinTransactionInfo(
      {@required this.id,
      @required int height,
      @required int amount,
      @required TransactionDirection direction,
      @required bool isPending,
      @required DateTime date}) {
    this.height = height;
    this.amount = amount;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
  }

  factory BitcoinTransactionInfo.fromHexAndHeader(
      String hex, Map<String, Object> header,
      {List<String> addresses}) {
    final tx = bitcoin.Transaction.fromHex(hex);
    var exist = false;
    var amount = 0;

    tx.outs.forEach((out) {
      try {
        final p2pkh = bitcoin.P2PKH(
            data: PaymentData(output: out.script), network: bitcoin.bitcoin);
        exist = addresses.contains(p2pkh.data.address);

        if (exist) {
          amount += out.value;
        }
      } catch (_) {}
    });

    // FIXME: Get transaction is pending
    return BitcoinTransactionInfo(
        id: tx.getId(),
        height: header['block_height'] as int,
        isPending: false,
        direction: TransactionDirection.incoming,
        amount: amount,
        date: DateTime.fromMillisecondsSinceEpoch(
            (header['timestamp'] as int) * 1000));
  }

  factory BitcoinTransactionInfo.fromJson(Map<String, dynamic> data) {
    return BitcoinTransactionInfo(
        id: data['id'] as String,
        height: data['height'] as int,
        amount: data['amount'] as int,
        direction: parseTransactionDirectionFromInt(data['direction'] as int),
        date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
        isPending: data['isPending'] as bool);
  }

  final String id;

  @override
  String amountFormatted() => bitcoinAmountToString(amount: amount);

  @override
  String fiatAmount() => '\$ 24.5';

  Map<String, dynamic> toJson() {
    final m = Map<String, dynamic>();
    m['id'] = id;
    m['height'] = height;
    m['amount'] = amount;
    m['direction'] = direction.index;
    m['date'] = date.millisecondsSinceEpoch;
    m['isPending'] = isPending;
    return m;
  }
}
