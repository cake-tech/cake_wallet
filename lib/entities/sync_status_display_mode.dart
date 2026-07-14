enum SyncStatusDisplayMode { eta, blocksRemaining }

extension SyncStatusDisplayModeExtension on SyncStatusDisplayMode {
  String get title {
    switch (this) {
      case SyncStatusDisplayMode.eta:
        return 'ETA';
      case SyncStatusDisplayMode.blocksRemaining:
        return 'Blocks Remaining';
    }
  }

  String get description {
    switch (this) {
      case SyncStatusDisplayMode.eta:
        return 'Show estimated time remaining for sync completion';
      case SyncStatusDisplayMode.blocksRemaining:
        return 'Show number of blocks remaining to sync';
    }
  }

  static SyncStatusDisplayMode fromString(String value) {
    switch (value) {
      case 'eta':
        return SyncStatusDisplayMode.eta;
      case 'blocksRemaining':
        return SyncStatusDisplayMode.blocksRemaining;
      default:
        return SyncStatusDisplayMode.eta;
    }
  }

  String toJson() => name;
}
