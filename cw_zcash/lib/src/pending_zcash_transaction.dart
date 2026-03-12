import 'dart:convert';
import 'dart:math';

import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:warp_api/data_fb_generated.dart';
import 'package:warp_api/warp_api.dart';

class PendingZcashTransaction with PendingTransaction {
  PendingZcashTransaction({
    required this.zcashWallet,
    required this.credentials,
    required this.txPlan,
    required this.fee,
    required this.availableBalance,
  });

  final ZcashWallet zcashWallet;
  final ZcashTransactionCredentials credentials;
  final String txPlan;
  String? _txId;
  final int availableBalance;

  @override
  String get id => _txId ?? '';

  @override
  String get hex => '';

  @override
  String get amountFormatted {
    return walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(totalAmount));
  }

  int get totalAmount {
    final isAll = credentials.outputs.fold<bool>(false, (final a, final b) => a || (b.sendAll));
    if (isAll) {
      return availableBalance;
    }
    return credentials.outputs.fold<int>(
      0,
      (final a, final b) => a + (b.formattedCryptoAmount ?? 0),
    );
  }

  @override
  String get feeFormatted =>
      '$feeFormattedValue ${walletTypeToCryptoCurrency(WalletType.zcash).title}';

  @override
  late String feeFormattedValue = walletTypeToCryptoCurrency(
    WalletType.zcash,
  ).formatAmount(BigInt.from(fee));

  int fee;

  @override
  Future<void> commit() async {
    _txId = await ZcashWalletService.runInDbMutex(
      () => WarpApi.signAndBroadcast(ZcashWalletBase.coin, zcashWallet.accountId, txPlan),
    );
    ZcashWalletBase.temporarySentTx[zcashWallet.accountId] ??= [];
    ZcashWalletBase.temporarySentTx[zcashWallet.accountId]?.add(
      ShieldedTx(
        base64.decode(
          ZcashTaddressRotation.flatBuffersPack(
            ShieldedTxT(
              id: Random().nextInt(pow(2, 32).toInt()),
              txId: _txId,
              height: 0,
              timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              value: -totalAmount,
            ).pack,
          ),
        ),
      ),
    );
    await ZcashTransactionInfo.addCachedDestinationAddress(
      _txId ?? '',
      credentials.outputs.reduce((final o1, final o2) {
        return OutputInfo(
          address: o1.address + "," + o2.address,
          sendAll: false,
          isParsedAddress: false,
        );
      }).address,
    );
    await zcashWallet.updateTransactions();
    await zcashWallet.updateBalance();
  }

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError('UR not supported for Zcash');
  }

  @override
  bool shouldCommitUR() => false;
}
