import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/sync_status.dart';

String syncStatusTitle(SyncStatus syncStatus, SyncStatusDisplayMode syncStatusDisplayMode) {
  if (syncStatus is SyncingSyncStatus) {
    // Show blocks remaining for the first 3 seconds, then switch to percentage
    if (syncStatus.shouldShowBlocksRemaining()) {
      if (syncStatus.blocksLeft == 1) {
        return S.current.block_remaining;
      }
      return S.current.Blocks_remaining('${syncStatus.blocksLeft}');
    }

    // After 3 seconds, show percentage-based display
    // Don't show ETA for very few blocks (less than 100) to avoid inconsistency
    if (syncStatus.blocksLeft < 100) {
      return S.current.Blocks_remaining('${syncStatus.blocksLeft}');
    }

    if (syncStatus.blocksLeft == 1) {
      return S.current.block_remaining;
    }

    // Check user preference for sync status display
    if (syncStatusDisplayMode == SyncStatusDisplayMode.eta) {
      // Get ETA with placeholder while gathering data
      String eta = syncStatus.getFormattedEtaWithPlaceholder() ?? '';

      if (eta.isEmpty) {
        return S.current.Blocks_remaining('${syncStatus.blocksLeft}');
      } else {
        return "$eta";
      }
    } else {
      return S.current.Blocks_remaining('${syncStatus.blocksLeft}');
    }
  }

  if (syncStatus is SyncedTipSyncStatus) {
    return S.current.silent_payments_scanned_tip(syncStatus.tip.toString());
  }

  if (syncStatus is SyncedSyncStatus) {
    return "";
  }

  if (syncStatus is FailedSyncStatus) {
    if (syncStatus.error != null) {
      return syncStatus.error!;
    }
    return S.current.sync_offline;
  }

  if (syncStatus is LostConnectionSyncStatus) {
    return S.current.sync_offline;
  }

  if (syncStatus is NotConnectedSyncStatus) {
    return S.current.sync_not_connected;
  }

  if (syncStatus is AttemptingSyncStatus) {
    return S.current.sync_attempting;
  }

  if (syncStatus is ConnectingSyncStatus) {
    return S.current.sync_connecting;
  }

  if (syncStatus is ConnectedSyncStatus) {
    return S.current.connected;
  }

  if (syncStatus is UnsupportedSyncStatus) {
    return S.current.sync_unsupported_node;
  }

  if (syncStatus is TimedOutSyncStatus) {
    return S.current.sync_timed_out;
  }

  if (syncStatus is SyncronizingSyncStatus) {
    return S.current.sync_syncing;
  }

  if (syncStatus is StartingScanSyncStatus) {
    return "${S.current.sync_starting_scan} (${(syncStatus.beginHeight.toString())})";
  }

  if (syncStatus is AttemptingScanSyncStatus) {
    return "Attempting scan";
  }

  if (syncStatus is ProcessingSyncStatus) {
    return syncStatus.message ?? S.current.processing;
  }

  return '';
}
