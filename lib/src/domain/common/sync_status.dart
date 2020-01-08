import 'package:cake_wallet/generated/i18n.dart';

abstract class SyncStatus {
  const SyncStatus();

  double progress();

  String title();
}

class SyncingSyncStatus extends SyncStatus {
  SyncingSyncStatus(this.height, this.blockchainHeight, this.refreshHeight);

  final int height;
  final int blockchainHeight;
  final int refreshHeight;

  @override
  double progress() {
    final line = blockchainHeight - refreshHeight;
    final diff = line - (blockchainHeight - height);
    return diff <= 0 ? 0.0 : diff / line;
  }

  @override
  String title() => S.current.sync_status_syncronizing;

  @override
  String toString() => '${blockchainHeight - height}';
}

class SyncedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;

  @override
  String title() => S.current.sync_status_syncronized;
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  @override
  double progress() => 0.0;

  @override
  String title() => S.current.sync_status_not_connected;
}

class StartingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String title() => S.current.sync_status_starting_sync;
}

class FailedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;

  @override
  String title() => S.current.sync_status_failed_connect;
}

class ConnectingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String title() => S.current.sync_status_connecting;
}

class ConnectedSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String title() => S.current.sync_status_connected;
}
