import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

ReactionDisposer? _onWalletSyncStatusChangeReaction;

void startWalletSyncStatusChangeReaction(
    WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet,
    SettingsStore settingsStore) {
  _onWalletSyncStatusChangeReaction?.reaction.dispose();
  _cancelPendingKeyImageSyncOffer();
  _onWalletSyncStatusChangeReaction = reaction((_) => wallet.syncStatus, (SyncStatus status) async {
    try {
      if (status is ConnectedSyncStatus) {
        SyncingSyncStatus.resetSyncStartTime();
        await wallet.startSync();
      }

      if (status is SyncingSyncStatus || status is ProcessingSyncStatus) {
        await WakelockPlus.enable();
      }

      if (status is SyncedSyncStatus) {
        await WakelockPlus.disable();
        SyncingSyncStatus.resetSyncStartTime();
        SyncingSyncStatus.blockHistory.clear();
      }

      if (status is FailedSyncStatus) {
        await WakelockPlus.disable();
        SyncingSyncStatus.resetSyncStartTime();
      }

      if (status is SyncedSyncStatus &&
          wallet.type == WalletType.bitcoin &&
          settingsStore.usePayjoin) {
        bitcoin!.resumePayjoinSessions(wallet);
      }

      if (status is SyncedSyncStatus) {
        _promptTrezorKeyImageSyncIfNeeded(wallet);
      }
    } catch (e) {
      printV(e.toString());
    }
  });
}

/// Wallets a key-image sync was already offered for during this app run, so a
/// wallet that keeps syncing is not nagged on every completed sync.
final Set<String> _keyImageSyncOffered = {};

/// An offer that had to wait for the user to come back to the dashboard.
ReactionDisposer? _pendingKeyImageSyncOffer;

/// Identity of the deferral currently in flight, so a newer one (or a wallet
/// switch) makes an older one give up when it wakes.
Object? _pendingKeyImageSyncOfferToken;

void _cancelPendingKeyImageSyncOffer() {
  _pendingKeyImageSyncOffer?.call();
  _pendingKeyImageSyncOffer = null;
  _pendingKeyImageSyncOfferToken = null;
}

/// Waits until the user is on the dashboard and nothing is talking to the
/// device, then offers again. The route is observable, so a MobX `when` covers
/// it; the device mutex is plain Dart state MobX cannot see, so idleness is
/// awaited on the mutex itself instead of polled or inferred.
Future<void> _deferKeyImageSyncOffer(WalletBase wallet, AppStore appStore) async {
  _cancelPendingKeyImageSyncOffer();
  final token = Object();
  _pendingKeyImageSyncOfferToken = token;

  if (appStore.currentRouteName != Routes.dashboard) {
    final onDashboard = Completer<void>();
    _pendingKeyImageSyncOffer = when(
      (_) => appStore.currentRouteName == Routes.dashboard,
      onDashboard.complete,
    );
    await onDashboard.future;
    _pendingKeyImageSyncOffer = null;
  }
  if (!identical(_pendingKeyImageSyncOfferToken, token)) return;

  await monero!.waitForTrezorIdle();
  if (!identical(_pendingKeyImageSyncOfferToken, token)) return;

  _pendingKeyImageSyncOfferToken = null;
  _promptTrezorKeyImageSyncIfNeeded(wallet);
}

/// A Monero wallet on a Trezor is view-only on the phone: without the key
/// images from the device it cannot tell which outputs were spent and shows a
/// balance that is too high. Offer the sync as soon as the first sync after a
/// restore (or after new outputs arrived) completes, instead of waiting for
/// the user to try to send.
///
/// The offer is only made from the dashboard while nothing is talking to the
/// device. A sync completing mid-flow (a block landing while a transaction is
/// being signed on the Trezor, for instance) must not push the sync page on
/// top of the send flow: a second THP conversation while the first is still
/// on the device leaves the Trezor unresponsive. In that case the offer waits
/// for the user to return to the dashboard.
void _promptTrezorKeyImageSyncIfNeeded(WalletBase wallet) {
  if (wallet.type != WalletType.monero ||
      wallet.hardwareWalletType != HardwareWalletType.trezor ||
      !monero!.hasUnknownKeyImages(wallet)) {
    return;
  }

  final key = "${wallet.type.name}/${wallet.name}";
  if (_keyImageSyncOffered.contains(key)) return;

  final appStore = getIt.get<AppStore>();
  if (appStore.wallet != wallet) return;

  if (!_canOfferKeyImageSync(appStore)) {
    unawaited(_deferKeyImageSyncOffer(wallet, appStore));
    return;
  }

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  _keyImageSyncOffered.add(key);
  // For a Trezor the route builds the sync sheet itself and ignores route
  // arguments; the output export those would carry is only for the QR flow.
  navigator.pushNamed(Routes.syncKeyImagesDevices);
}

bool _canOfferKeyImageSync(AppStore appStore) =>
    appStore.currentRouteName == Routes.dashboard && !monero!.isTrezorBusy();
