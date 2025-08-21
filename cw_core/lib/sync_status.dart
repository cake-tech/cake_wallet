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

  @override
  String toString() => 'Starting Scan $beginHeight';
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
    updateEtaHistory(left + 1);

    // sum 1 because if at the chain tip, will say "0 blocks left"
    return SyncingSyncStatus(left + 1, ptc);
  }

  static void updateEtaHistory(int blocksLeft) {
    blockHistory[DateTime.now()] = blocksLeft;

    // keep only the last 30 entries (gives us better statistical accuracy)
    while (blockHistory.length > 30) {
      blockHistory.remove(blockHistory.keys.first);
    }
  }

  static Map<DateTime, int> blockHistory = {};
  static Duration? lastEtaDuration;
  static const int _minDataPoints = 3;
  static const int _maxDataAgeMinutes = 2;

  String? getFormattedEtaWithPlaceholder() {
    _cleanOldEntries();

    // If we have enough data, show actual ETA
    if (blockHistory.length >= _minDataPoints) {
      final eta = getFormattedEta();
      if (eta != null) return eta;
    }

    // Show the placeholder ETA while gathering data
    return '--:--';
  }

  void _cleanOldEntries() {
    final cutoffTime = DateTime.now().subtract(Duration(minutes: _maxDataAgeMinutes));
    blockHistory.removeWhere((key, value) => key.isBefore(cutoffTime));
  }

  String? getFormattedEta() {
    Duration? duration = getEtaDuration();

    // Don't show ETA for very long durations or very few blocks
    if (duration.inDays > 0 || blocksLeft < 100) return null;

    // Apply smoothing to prevent ETA jumping
    duration = _applySmoothing(duration);
    lastEtaDuration = duration;

    return _formatDuration(duration);
  }

  Duration getEtaDuration() {
    DateTime now = DateTime.now();
    DateTime completionTime = calculateEta();
    return completionTime.difference(now);
  }

  Duration _applySmoothing(Duration newDuration) {
    if (lastEtaDuration == null) {
      return newDuration;
    }

    final currentMs = lastEtaDuration!.inMilliseconds;
    final newMs = newDuration.inMilliseconds;
    final diff = (newMs - currentMs).abs();

    // Apply different smoothing based on the magnitude of change
    if (diff > 3600) {
      // If it's more than 1 hour difference, it's a large change so we move by max 30 minutes
      final direction = newMs > currentMs ? 1 : -1;
      final maxChange = 30 * 60;
      final adjustedMs = currentMs + (direction * maxChange);
      return Duration(milliseconds: adjustedMs);
    } else if (diff > 300) {
      // If it's more than 5 minutes difference, it's a medium change so we move by max 2 minutes
      final direction = newMs > currentMs ? 1 : -1;
      final maxChange = 2 * 60;
      final adjustedMs = currentMs + (direction * maxChange);
      return Duration(milliseconds: adjustedMs);
    } else if (diff > 60) {
      // If it's more than 1 minute difference, it's a small change so we move by max 30 ms
      final direction = newMs > currentMs ? 1 : -1;
      final maxChange = 30;
      final adjustedMs = currentMs + (direction * maxChange);
      return Duration(milliseconds: adjustedMs);
    }

    return newDuration;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours == '00') {
      return '${minutes}m${seconds}s';
    }
    return '${hours}h${minutes}m${seconds}s';
  }

  DateTime calculateEta() {
    double rate = _calculateBlockRate();
    if (rate == 0) {
      return DateTime.now().add(const Duration(days: 2));
    }
    int remainingBlocks = this.blocksLeft;
    double timeRemainingMs = remainingBlocks / rate;
    return DateTime.now().add(Duration(milliseconds: timeRemainingMs.round()));
  }

  // Enhanced block rate calculation with weighted averages
  double _calculateBlockRate() {
    List<DateTime> timestamps = blockHistory.keys.toList();
    List<int> blockCounts = blockHistory.values.toList();

    if (timestamps.length < 2) return 0;

    // Sort by timestamp to ensure chronological order
    final sortedData =
        List.generate(timestamps.length, (i) => MapEntry(timestamps[i], blockCounts[i]))
          ..sort((a, b) => a.key.compareTo(b.key));

    double totalWeightedTime = 0;
    double totalWeightedBlocks = 0;
    double totalWeight = 0;

    for (int i = 0; i < sortedData.length - 1; i++) {
      final current = sortedData[i];
      final next = sortedData[i + 1];

      final blocksProcessed = current.value - next.value;

      if (blocksProcessed <= 0) continue; // Skip invalid data

      final timeDifference = next.key.difference(current.key);

      if (timeDifference.inMilliseconds <= 0) continue; // Skip invalid time

      // Weight recent data more heavily (exponential decay)
      final weight = 1.0 / (1.0 + (sortedData.length - 1 - i) * 0.1);

      totalWeightedTime += timeDifference.inMilliseconds * weight;
      totalWeightedBlocks += blocksProcessed * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0 || totalWeightedTime == 0) return 0;

    final weightedRate = totalWeightedBlocks / totalWeightedTime;

    return weightedRate;
  }
}

class ProcessingSyncStatus extends SyncStatus {
  final String? message;

  ProcessingSyncStatus({this.message});

  @override
  double progress() => 0.99;

  @override
  String toString() => 'Processing';
}

class SyncedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;

  @override
  String toString() => 'Synced';
}

class SyncedTipSyncStatus extends SyncedSyncStatus {
  SyncedTipSyncStatus(this.tip);

  final int tip;

  @override
  String toString() => 'Synced Tip $tip';
}

class SyncronizingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Synchronizing';
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  @override
  double progress() => 0.0;

  @override
  String toString() => 'Not Connected';
}

class AttemptingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Attempting';
}

class AttemptingScanSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Attempting Scan';
}

class FailedSyncStatus extends NotConnectedSyncStatus {
  String? error;
  FailedSyncStatus({this.error});

  @override
  String toString() => error ?? super.toString();
}

class ConnectingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Connecting';
}

class ConnectedSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Connected';
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
