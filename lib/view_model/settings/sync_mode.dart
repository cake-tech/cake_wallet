enum SyncType { disabled, unobtrusive, aggressive }

class SyncMode {
  SyncMode(this.name, this.type, this.frequency);

  final String name;
  final SyncType type;
  final Duration frequency;

  static final all = [
    SyncMode("Disabled", SyncType.disabled, Duration.zero),
    SyncMode("Unobtrusive", SyncType.unobtrusive, Duration(days: 1)),
    SyncMode("Aggressive", SyncType.aggressive, Duration(hours: 6)),
  ];
}
