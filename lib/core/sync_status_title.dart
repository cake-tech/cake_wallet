import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/sync_status.dart';

String syncStatusTitle(SyncStatus syncStatus) {
  if (syncStatus is SyncingSyncStatus) {
    return S.current.Blocks_remaining('${syncStatus.blocksLeft}');
  }

  if (syncStatus is SyncedSyncStatus) {
    return S.current.sync_status_syncronized;
  }

  if (syncStatus is NotConnectedSyncStatus) {
    return S.current.sync_status_not_connected;
  }

  if (syncStatus is AttemptingSyncStatus) {
    return S.current.sync_status_attempting_sync;
  }

  if (syncStatus is FailedSyncStatus) {
    return S.current.sync_status_failed_connect;
  }

  if (syncStatus is ConnectingSyncStatus) {
    return S.current.sync_status_connecting;
  }

  if (syncStatus is ConnectedSyncStatus) {
    return S.current.sync_status_connected;
  }

  if (syncStatus is LostConnectionSyncStatus) {
    return S.current.sync_status_failed_connect;
  }

  return '';
}