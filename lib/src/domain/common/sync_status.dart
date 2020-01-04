import 'package:cake_wallet/generated/i18n.dart';

abstract class SyncStatus {
  const SyncStatus();

  double progress();

  String title();
}

class SyncingSyncStatus extends SyncStatus {
  final int height;
  final int blockchainHeight;
  final int refreshHeight;

  SyncingSyncStatus(this.height, this.blockchainHeight, this.refreshHeight);

  double progress() {
    final line = blockchainHeight - refreshHeight;
    final diff = line - (blockchainHeight - height);
    return diff <= 0 ? 0.0 : diff / line;
  }

  String title() => S.current.sync_status_syncronizing;

  @override
  String toString() => '${blockchainHeight - height}';
}

class SyncedSyncStatus extends SyncStatus {
  double progress() => 1.0;

  String title() => S.current.sync_status_syncronized;
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  double progress() => 0.0;

  String title() => S.current.sync_status_not_connected;
}

class StartingSyncStatus extends SyncStatus {
  double progress() => 0.0;

  String title() => S.current.sync_status_starting_sync;
}

class FailedSyncStatus extends SyncStatus {
  double progress() => 1.0;

  String title() => S.current.sync_status_failed_connect;
}

class ConnectingSyncStatus extends SyncStatus {
  double progress() => 0.0;

  String title() => S.current.sync_status_connecting;
}

class ConnectedSyncStatus extends SyncStatus {
  double progress() => 0.0;

  String title() => S.current.sync_status_connected;
}