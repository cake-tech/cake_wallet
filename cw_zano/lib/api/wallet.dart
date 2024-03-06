import 'dart:async';
import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_zano/api/api_calls.dart' as calls;
import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/api/model/get_wallet_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/zano_wallet_keys.dart';
import 'package:cw_zano/zano_balance.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart' as mobx;

int getCurrentHeight(int hWallet) {
  final json = ApiCalls.getWalletStatus(hWallet: hWallet);
  final walletStatus = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  return walletStatus.currentWalletHeight;
}

int getNodeHeightSync(int hWallet) {
  final json = ApiCalls.getWalletStatus(hWallet: hWallet);
  final walletStatus = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  return walletStatus.currentDaemonHeight;
}

class SyncListener {
  SyncListener(this.onNewBlock, this.onNewTransaction)
      : _cachedBlockchainHeight = 0,
        _lastKnownBlockHeight = 0,
        _initialSyncHeight = 0;

  void Function(int, int, double) onNewBlock;
  void Function() onNewTransaction;

  Timer? _updateSyncInfoTimer;
  int _cachedBlockchainHeight;
  int _lastKnownBlockHeight;
  int _initialSyncHeight;

  // Future<int> getNodeHeightOrUpdate(int hWallet, int baseHeight) async {
  //   if (_cachedBlockchainHeight < baseHeight || _cachedBlockchainHeight == 0) {
  //     _cachedBlockchainHeight = await compute<int, int>(getNodeHeightSync, hWallet);
  //   }

  //   return _cachedBlockchainHeight;
  // }

  void start(ZanoWalletBase wallet, int hWallet) async {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
    _updateSyncInfoTimer ??= Timer.periodic(Duration(milliseconds: 1200), (_) async {
      /**if (isNewTransactionExist()) {
        onNewTransaction?.call();
      }*/

      var json = ApiCalls.getWalletStatus(hWallet: hWallet);
      final status = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
      // You can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
      if (!status.isInLongRefresh && status.walletState == 2) {
        final syncHeight = status.currentWalletHeight;

        json = ApiCalls.getWalletInfo(hWallet);
        final result = GetWalletInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
        wallet.seed = result.wiExtended.seed;
        wallet.keys = ZanoWalletKeys(
          privateSpendKey: result.wiExtended.spendPrivateKey,
          privateViewKey: result.wiExtended.viewPrivateKey,
          publicSpendKey: result.wiExtended.spendPublicKey,
          publicViewKey: result.wiExtended.viewPublicKey,
        );

        final balance = result.wi.balances.first;
        wallet.assetId = balance.assetInfo.assetId;
        wallet.balance = mobx.ObservableMap.of({CryptoCurrency.zano: ZanoBalance(total: balance.total, unlocked: balance.unlocked)});

        if (_initialSyncHeight <= 0) {
          _initialSyncHeight = syncHeight;
        }

        final bchHeight = status.currentDaemonHeight;

        if (_lastKnownBlockHeight == syncHeight) {
          return;
        }

        _lastKnownBlockHeight = syncHeight;
        final track = bchHeight - _initialSyncHeight;
        final diff = track - (bchHeight - syncHeight);
        final ptc = diff <= 0 ? 0.0 : diff / track;
        final left = bchHeight - syncHeight;

        if (syncHeight < 0 || left < 0) {
          return;
        }

        // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
        onNewBlock.call(syncHeight, left, ptc);
      }
    });
  }

  void stop() => _updateSyncInfoTimer?.cancel();
}

SyncListener setListeners(void Function(int, int, double) onNewBlock, void Function() onNewTransaction) {
  final listener = SyncListener(onNewBlock, onNewTransaction);
  /**setListenerNative();*/
  return listener;
}
