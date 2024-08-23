import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/wallet_type.dart';

class ElectrumTransactionBundle {
  ElectrumTransactionBundle(this.originalTransaction,
      {required this.ins, required this.confirmations, this.time});
  final BtcTransaction originalTransaction;
  final List<BtcTransaction> ins;
  final int? time;
  final int confirmations;
}

class ElectrumTransactionInfo extends TransactionInfo {
  List<BitcoinSilentPaymentsUnspent>? unspents;

  ElectrumTransactionInfo(this.type,
      {required String id,
      int? height,
      required int amount,
      int? fee,
      List<String>? inputAddresses,
      List<String>? outputAddresses,
      required TransactionDirection direction,
      required bool isPending,
      required DateTime date,
      required int confirmations,
      String? to,
      this.unspents}) {
    this.id = id;
    this.height = height;
    this.amount = amount;
    this.inputAddresses = inputAddresses;
    this.outputAddresses = outputAddresses;
    this.fee = fee;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.confirmations = confirmations;
    this.to = to;
  }

  factory ElectrumTransactionInfo.fromElectrumVerbose(Map<String, Object> obj, WalletType type,
      {required List<BitcoinAddressRecord> addresses, required int height}) {
    final addressesSet = addresses.map((addr) => addr.address).toSet();
    final id = obj['txid'] as String;
    final vins = obj['vin'] as List<Object>? ?? [];
    final vout = (obj['vout'] as List<Object>? ?? []);
    final date = obj['time'] is int
        ? DateTime.fromMillisecondsSinceEpoch((obj['time'] as int) * 1000)
        : DateTime.now();
    final confirmations = obj['confirmations'] as int? ?? 0;
    var direction = TransactionDirection.incoming;
    var inputsAmount = 0;
    var amount = 0;
    var totalOutAmount = 0;

    for (dynamic vin in vins) {
      final vout = vin['vout'] as int;
      final out = vin['tx']['vout'][vout] as Map;
      final outAddresses = (out['scriptPubKey']['addresses'] as List<Object>?)?.toSet();
      inputsAmount += stringDoubleToBitcoinAmount((out['value'] as double? ?? 0).toString());

      if (outAddresses?.intersection(addressesSet).isNotEmpty ?? false) {
        direction = TransactionDirection.outgoing;
      }
    }

    for (dynamic out in vout) {
      final outAddresses = out['scriptPubKey']['addresses'] as List<Object>? ?? [];
      final ntrs = outAddresses.toSet().intersection(addressesSet);
      final value = stringDoubleToBitcoinAmount((out['value'] as double? ?? 0.0).toString());
      totalOutAmount += value;

      if ((direction == TransactionDirection.incoming && ntrs.isNotEmpty) ||
          (direction == TransactionDirection.outgoing && ntrs.isEmpty)) {
        amount += value;
      }
    }

    final fee = inputsAmount - totalOutAmount;

    return ElectrumTransactionInfo(type,
        id: id,
        height: height,
        isPending: false,
        fee: fee,
        direction: direction,
        amount: amount,
        date: date,
        confirmations: confirmations);
  }

  factory ElectrumTransactionInfo.fromElectrumBundle(
      ElectrumTransactionBundle bundle, WalletType type, BasedUtxoNetwork network,
      {required Set<String> addresses, int? height}) {
    final date = bundle.time != null
        ? DateTime.fromMillisecondsSinceEpoch(bundle.time! * 1000)
        : DateTime.now();
    var direction = TransactionDirection.incoming;
    var amount = 0;
    var inputAmount = 0;
    var totalOutAmount = 0;
    List<String> inputAddresses = [];
    List<String> outputAddresses = [];

    for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
      final input = bundle.originalTransaction.inputs[i];
      final inputTransaction = bundle.ins[i];
      final outTransaction = inputTransaction.outputs[input.txIndex];
      inputAmount += outTransaction.amount.toInt();
      if (addresses.contains(addressFromOutputScript(outTransaction.scriptPubKey, network))) {
        direction = TransactionDirection.outgoing;
        inputAddresses.add(addressFromOutputScript(outTransaction.scriptPubKey, network));
      }
    }

    final receivedAmounts = <int>[];
    for (final out in bundle.originalTransaction.outputs) {
      totalOutAmount += out.amount.toInt();
      final addressExists = addresses.contains(addressFromOutputScript(out.scriptPubKey, network));
      outputAddresses.add(addressFromOutputScript(out.scriptPubKey, network));

      if (addressExists) {
        receivedAmounts.add(out.amount.toInt());
      }

      if ((direction == TransactionDirection.incoming && addressExists) ||
          (direction == TransactionDirection.outgoing && !addressExists)) {
        amount += out.amount.toInt();
      }
    }

    if (receivedAmounts.length == bundle.originalTransaction.outputs.length) {
      // Self-send
      direction = TransactionDirection.incoming;
      amount = receivedAmounts.reduce((a, b) => a + b);
    }

    final fee = inputAmount - totalOutAmount;
    return ElectrumTransactionInfo(type,
        id: bundle.originalTransaction.txId(),
        height: height,
        isPending: bundle.confirmations == 0,
        inputAddresses: inputAddresses,
        outputAddresses: outputAddresses,
        fee: fee,
        direction: direction,
        amount: amount,
        date: date,
        confirmations: bundle.confirmations);
  }

  factory ElectrumTransactionInfo.fromJson(Map<String, dynamic> data, WalletType type) {
    final inputAddresses = data['inputAddresses'] as List<dynamic>? ?? [];
    final outputAddresses = data['outputAddresses'] as List<dynamic>? ?? [];
    final unspents = data['unspents'] as List<dynamic>? ?? [];

    return ElectrumTransactionInfo(
      type,
      id: data['id'] as String,
      height: data['height'] as int,
      amount: data['amount'] as int,
      fee: data['fee'] as int,
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool,
      confirmations: data['confirmations'] as int,
      inputAddresses:
          inputAddresses.isEmpty ? [] : inputAddresses.map((e) => e.toString()).toList(),
      outputAddresses:
          outputAddresses.isEmpty ? [] : outputAddresses.map((e) => e.toString()).toList(),
      to: data['to'] as String?,
      unspents: unspents
          .map((unspent) =>
              BitcoinSilentPaymentsUnspent.fromJSON(null, unspent as Map<String, dynamic>))
          .toList(),
    );
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

  ElectrumTransactionInfo updated(ElectrumTransactionInfo info) {
    return ElectrumTransactionInfo(info.type,
        id: id,
        height: info.height,
        amount: info.amount,
        fee: info.fee,
        direction: direction,
        date: date,
        isPending: isPending,
        inputAddresses: inputAddresses,
        outputAddresses: outputAddresses,
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
    m['to'] = to;
    m['unspents'] = unspents?.map((e) => e.toJson()).toList() ?? [];
    m['inputAddresses'] = inputAddresses;
    m['outputAddresses'] = outputAddresses;
    return m;
  }

  String toString() {
    return 'ElectrumTransactionInfo(id: $id, height: $height, amount: $amount, fee: $fee, direction: $direction, date: $date, isPending: $isPending, confirmations: $confirmations, to: $to, unspent: $unspents, inputAddresses: $inputAddresses, outputAddresses: $outputAddresses)';
  }
}
