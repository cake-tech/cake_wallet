import 'package:cake_wallet/generated/i18n.dart';

enum SyncStatusDisplayMode { eta, blocksRemaining }

extension SyncStatusDisplayModeExtension on SyncStatusDisplayMode {
  String get title {
    switch (this) {
      case SyncStatusDisplayMode.eta:
        return S.current.sync_status_display_mode_eta;
      case SyncStatusDisplayMode.blocksRemaining:
        return S.current.sync_status_display_mode_blocks;
    }
  }

  String get description {
    switch (this) {
      case SyncStatusDisplayMode.eta:
        return S.current.sync_status_display_mode_eta;
      case SyncStatusDisplayMode.blocksRemaining:
        return S.current.sync_status_display_mode_blocks;
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
