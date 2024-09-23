abstract class SyncStatus {
  const SyncStatus();
  double progress();

  String formattedProgress() {
    return "${(progress() * 100).toStringAsFixed(2)}%";
  }
}

class StartingScanSyncStatus extends SyncStatus {
  StartingScanSyncStatus(this.beginHeight);

  final int beginHeight;
  @override
  double progress() => 0.0;
}

class SyncingSyncStatus extends SyncStatus {
  SyncingSyncStatus(this.blocksLeft, this.ptc) {
    updateEtaHistory(blocksLeft);
  }

  double ptc;
  int blocksLeft;

  @override
  double progress() => ptc;

  @override
  String toString() => '$blocksLeft';

  factory SyncingSyncStatus.fromHeightValues(int chainTip, int initialSyncHeight, int syncHeight) {
    final track = chainTip - initialSyncHeight;
    final diff = track - (chainTip - syncHeight);
    final ptc = diff <= 0 ? 0.0 : diff / track;
    final left = chainTip - syncHeight;

    // sum 1 because if at the chain tip, will say "0 blocks left"
    return SyncingSyncStatus(left + 1, ptc);
  }

  void updateEtaHistory(int blocksLeft) {
    blockHistory[DateTime.now()] = blocksLeft;

    // Keep only the last 5 entries to limit memory usage
    if (blockHistory.length > 5) {
      var oldestKey = blockHistory.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      blockHistory.remove(oldestKey);
    }
  }

  static Map<DateTime, int> blockHistory = {};

  DateTime? estimatedCompletionTime;
  Duration? estimatedCompletionDuration;

  Duration getEtaDuration() {
    DateTime now = DateTime.now();
    DateTime? completionTime = calculateETA();
    return completionTime.difference(now);
  }

  String? getFormattedEta() {
    // throw out any entries that are more than a minute old:
    blockHistory.removeWhere(
        (key, value) => key.isBefore(DateTime.now().subtract(const Duration(minutes: 1))));

    if (blockHistory.length < 2) return null;
    Duration? duration = getEtaDuration();

    if (duration.inDays > 0) {
      return null;
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours == '00') {
      return '${minutes}m${seconds}s';
    }
    return '${hours}h${minutes}m${seconds}s';
  }

  // Calculate the rate of block processing (blocks per second)
  double calculateRate() {
    List<DateTime> timestamps = blockHistory.keys.toList();
    List<int> blockCounts = blockHistory.values.toList();

    double totalTimeMinutes = 0;
    int totalBlocksProcessed = 0;

    for (int i = 0; i < blockCounts.length - 1; i++) {
      int blocksProcessed = blockCounts[i + 1] - blockCounts[i];
      Duration timeDifference = timestamps[i].difference(timestamps[i + 1]);
      totalTimeMinutes += timeDifference.inSeconds;
      totalBlocksProcessed += blocksProcessed;
    }

    if (totalTimeMinutes == 0 || totalBlocksProcessed == 0) {
      return 0;
    }

    return totalBlocksProcessed / totalTimeMinutes; // Blocks per second
  }

  // Calculate the ETA
  DateTime calculateETA() {
    double rate = calculateRate();
    if (rate < 0.01) {
      return DateTime.now().add(const Duration(days: 1));
    }
    int remainingBlocks = this.blocksLeft;
    double timeRemainingSeconds = remainingBlocks / rate;
    return DateTime.now().add(Duration(seconds: timeRemainingSeconds.round()));
  }
}

class SyncedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;
}

class SyncedTipSyncStatus extends SyncedSyncStatus {
  SyncedTipSyncStatus(this.tip);

  final int tip;
}

class SyncronizingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  @override
  double progress() => 0.0;
}

class AttemptingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class AttemptingScanSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class FailedSyncStatus extends NotConnectedSyncStatus {}

class ConnectingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class ConnectedSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class UnsupportedSyncStatus extends NotConnectedSyncStatus {}

class TimedOutSyncStatus extends NotConnectedSyncStatus {
  @override
  String toString() => 'Timed out';
}

class LostConnectionSyncStatus extends NotConnectedSyncStatus {
  @override
  String toString() => 'Reconnecting';
}
