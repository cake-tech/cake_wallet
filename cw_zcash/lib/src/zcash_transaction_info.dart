import 'dart:convert';
import 'dart:io';

import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:path/path.dart' as p;

class ZcashTransactionInfo extends TransactionInfo {
  ZcashTransactionInfo({
    required final String id,
    required final int amount,
    required final int fee,
    required final TransactionDirection direction,
    required final bool isPending,
    required final DateTime date,
    required final int height,
    required final int confirmations,
    required final String to,
    final String? memo,
  }) {
    this.id = id;
    this.amount = amount;
    this.fee = fee;
    this.height = height;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.confirmations = confirmations;
    this.to = getCachedDestinationAddress(id);
    if (memo != null && memo.isNotEmpty) {
      additionalInfo['memo'] = memo;
    }
    additionalInfo['autoShield'] = false;
    // note: this won't work yet, fee is not in zcash_lib metadata,
    // leaving here so it can start working automagically in future
    if (amount == fee && to.startsWith("u")) {
      additionalInfo['autoShield'] = true;
    }
    // remove below when above starts working
    additionalInfo['autoShield'] = ZcashWalletService.autoshieldTx.contains(txHash);
    //    --- == === cut here === == ---
    if (additionalInfo['autoShield'] == true) {
      additionalInfo['memo'] ??= '';
      additionalInfo['memo'] += '\This is an auto-shielding transaction. Enjoy default privacy!';
      additionalInfo['memo'] = additionalInfo['memo'].trim();
    }
  }

  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(amount))} ${walletTypeToCryptoCurrency(WalletType.zcash).title}';

  @override
  String? feeFormatted() {
    if (fee == null || fee == 0) return null;
    return '${walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(fee!))} ${walletTypeToCryptoCurrency(WalletType.zcash).title}';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(final String amount) => _fiatAmount = formatAmount(amount);

  String? get memo => additionalInfo['memo'] as String?;

  static final Map<String, String> _destinationAddressMap = {};

  static String? getCachedDestinationAddress(final String txId) {
    printV("$txId -> ${_destinationAddressMap.keys.join(",")}");
    return _destinationAddressMap[txId] ??
        _destinationAddressMap['"$txId"'] ??
        _destinationAddressMap[txId.replaceAll('"', '')];
  }

  static Future<void> addCachedDestinationAddress(final String txId, final String address) async {
    _destinationAddressMap[txId] = address;
    final pfwt = await pathForWalletTypeDir(type: WalletType.zcash);
    final f = File(p.join(pfwt, "sent-tx-map.json"));
    f.writeAsStringSync(json.encode(_destinationAddressMap));
  }

  static Future<void> init() async {
    try {
      final pfwt = await pathForWalletTypeDir(type: WalletType.zcash);
      final f = File(p.join(pfwt, "sent-tx-map.json"));
      if (!f.existsSync()) {
        f.writeAsStringSync('{}');
      }
      final tmpMap = json.decode(f.readAsStringSync());
      tmpMap.forEach((final k, final v) {
        _destinationAddressMap[k.toString()] = v.toString();
      });
    } catch (e, s) {
      printV("failed to deserialize: $e, $s");
    }
  }
}
