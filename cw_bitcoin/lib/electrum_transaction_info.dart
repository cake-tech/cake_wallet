import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hex/hex.dart';

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
  bool isReceivedSilentPayment;

  ElectrumTransactionInfo(
    this.type, {
    required String id,
    int? height,
    required int amount,
    int? fee,
    List<String>? inputAddresses,
    List<String>? outputAddresses,
    required TransactionDirection direction,
    required bool isPending,
    bool isReplaced = false,
    required DateTime date,
    required int confirmations,
    String? to,
    this.unspents,
    this.isReceivedSilentPayment = false,
    Map<String, dynamic>? additionalInfo,
  }) {
    this.id = id;
    this.height = height;
    this.amount = amount;
    this.inputAddresses = inputAddresses;
    this.outputAddresses = outputAddresses;
    this.fee = fee;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.isReplaced = isReplaced;
    this.confirmations = confirmations;
    this.to = to;
    this.additionalInfo = additionalInfo ?? {};
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
    var totalInputsAmount = 0;
    var amount = 0;
    var totalOutsAmount = 0;

    final ourSentAmounts = <int>[];
    for (dynamic vin in vins) {
      final vout = vin['vout'] as int;
      final out = vin['tx']['vout'][vout] as Map;
      final outAddresses = (out['scriptPubKey']['addresses'] as List<Object>?)?.toSet();
      totalInputsAmount += stringDoubleToBitcoinAmount((out['value'] as double? ?? 0).toString());

      if (outAddresses?.intersection(addressesSet).isNotEmpty ?? false) {
        ourSentAmounts.add(out['value'] as int);
      }
    }

    final ourReceivedAmounts = <int>[];
    for (dynamic out in vout) {
      final outAddresses = out['scriptPubKey']['addresses'] as List<Object>? ?? [];
      final ntrs = outAddresses.toSet().intersection(addressesSet);
      final value = stringDoubleToBitcoinAmount((out['value'] as double? ?? 0.0).toString());
      totalOutsAmount += value;

      final address = out['scriptPubKey'] as String;
      final addressExists = addresses.contains(address);

      if ((direction == TransactionDirection.incoming && ntrs.isNotEmpty) ||
          (direction == TransactionDirection.outgoing && ntrs.isEmpty)) {
        amount += value;
      }

      if (addressExists) {
        ourReceivedAmounts.add(value);
      }
    }

    final ourTotalReceivedAmount =
        ourReceivedAmounts.length > 0 ? ourReceivedAmounts.reduce((a, b) => a + b) : 0;
    final ourTotalSentAmount =
        ourSentAmounts.length > 0 ? ourSentAmounts.reduce((a, b) => a + b) : 0;

    final weSent = ourSentAmounts.length > 0;
    final weReceived = ourReceivedAmounts.length > 0;

    // All outputs in this tx were received
    if (ourReceivedAmounts.length == vout.length) {
      direction = TransactionDirection.incoming;
      amount = ourTotalReceivedAmount;
    } else if (weSent && weReceived && ourTotalSentAmount > ourTotalReceivedAmount) {
      // We sent and received in the same transaction
      // The amount sent is greater than the amount received (which is change)
      direction = TransactionDirection.outgoing;
      amount = totalOutsAmount - ourTotalReceivedAmount;
    } else {
      direction = TransactionDirection.outgoing;

      if (ourTotalReceivedAmount > 0) {
        // In case we sent and received in the same transaction
        // but the amount received is greater than the amount sent
        amount = ourTotalReceivedAmount - ourTotalSentAmount;
      } else {
        amount = ourTotalSentAmount;
      }
    }

    final fee = totalInputsAmount - totalOutsAmount;
    amount = amount - fee;

    return ElectrumTransactionInfo(type,
        id: id,
        height: height,
        isPending: false,
        isReplaced: false,
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
    var totalInputsAmount = 0;
    var totalOutsAmount = 0;
    List<String> inputAddresses = [];
    List<String> outputAddresses = [];

    final ourSentAmounts = <int>[];
    if (bundle.ins.length > 0) {
      for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
        final input = bundle.originalTransaction.inputs[i];
        final inputTransaction = bundle.ins[i];
        final outTransaction = inputTransaction.outputs[input.txIndex];
        totalInputsAmount += outTransaction.amount.toInt();

        final address = addressFromOutputScript(outTransaction.scriptPubKey, network);
        final ourAddressExists = addresses.contains(address);

        if (ourAddressExists) {
          inputAddresses.add(address);
          ourSentAmounts.add(outTransaction.amount.toInt());
        }
      }
    }

    final ourReceivedAmounts = <int>[];
    for (final out in bundle.originalTransaction.outputs) {
      totalOutsAmount += out.amount.toInt();

      final address = addressFromOutputScript(out.scriptPubKey, network);
      final addressExists = addresses.contains(address);

      if (address.isNotEmpty) outputAddresses.add(address);

      // Check if the script contains OP_RETURN
      final script = out.scriptPubKey.script;
      if (script.contains('OP_RETURN')) {
        final index = script.indexOf('OP_RETURN');
        if (index + 1 <= script.length) {
          try {
            final opReturnData = script[index + 1].toString();
            final decodedString = utf8.decode(HEX.decode(opReturnData));
            outputAddresses.add('OP_RETURN:$decodedString');
          } catch (_) {
            outputAddresses.add('OP_RETURN:');
          }
        }
      }

      if (addressExists) {
        ourReceivedAmounts.add(out.amount.toInt());
      }
    }

    final ourTotalReceivedAmount =
        ourReceivedAmounts.length > 0 ? ourReceivedAmounts.reduce((a, b) => a + b) : 0;
    final ourTotalSentAmount =
        ourSentAmounts.length > 0 ? ourSentAmounts.reduce((a, b) => a + b) : 0;

    final weSent = ourSentAmounts.length > 0;
    final weReceived = ourReceivedAmounts.length > 0;
    final weReceivedAll = ourReceivedAmounts.length == bundle.originalTransaction.outputs.length;

    if (weReceivedAll) {
      direction = TransactionDirection.incoming;
      amount = ourTotalReceivedAmount;
    } else if (weSent && weReceived && ourTotalSentAmount > ourTotalReceivedAmount) {
      // We sent and received in the same transaction
      // The amount sent is greater than the amount received (change)
      direction = TransactionDirection.outgoing;
      amount = ourTotalSentAmount - ourTotalReceivedAmount;
    } else {
      direction = TransactionDirection.outgoing;

      if (ourTotalReceivedAmount > 0) {
        // In case we sent and received in the same transaction
        // but the amount received is greater than the amount sent
        amount = ourTotalReceivedAmount - ourTotalSentAmount;
      } else {
        amount = ourTotalSentAmount;
      }
    }

    final fee = totalInputsAmount - totalOutsAmount;

    return ElectrumTransactionInfo(type,
        id: bundle.originalTransaction.txId(),
        height: height,
        isPending: bundle.confirmations == 0,
        isReplaced: false,
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
      isReplaced: data['isReplaced'] as bool? ?? false,
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
      isReceivedSilentPayment: data['isReceivedSilentPayment'] as bool? ?? false,
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
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
        isReplaced: isReplaced ?? false,
        inputAddresses: inputAddresses,
        outputAddresses: outputAddresses,
        confirmations: info.confirmations,
        additionalInfo: additionalInfo);
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['height'] = height;
    m['amount'] = amount;
    m['direction'] = direction.index;
    m['date'] = date.millisecondsSinceEpoch;
    m['isPending'] = isPending;
    m['isReplaced'] = isReplaced;
    m['confirmations'] = confirmations;
    m['fee'] = fee;
    m['to'] = to;
    m['unspents'] = unspents?.map((e) => e.toJson()).toList() ?? [];
    m['inputAddresses'] = inputAddresses;
    m['outputAddresses'] = outputAddresses;
    m['isReceivedSilentPayment'] = isReceivedSilentPayment;
    m['additionalInfo'] = additionalInfo;
    return m;
  }

  String toString() {
    return 'ElectrumTransactionInfo(id: $id, height: $height, amount: $amount, fee: $fee, direction: $direction, date: $date, isPending: $isPending, isReplaced: $isReplaced, confirmations: $confirmations, to: $to, unspent: $unspents, inputAddresses: $inputAddresses, outputAddresses: $outputAddresses, additionalInfo: $additionalInfo)';
  }
}
