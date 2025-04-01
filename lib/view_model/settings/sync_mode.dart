enum SyncType { aggresive, hourly, daily }

class SyncMode {
  SyncMode(this.name, this.type, this.frequency);

  final String name;
  final SyncType type;
  final Duration frequency;

  static final all = [
    // **Technically** we could call aggressive option "15 minutes" but OS may "not feel like it",
    // so instead we will call it aggressive so user knows that it will be as frequent as possible.
    SyncMode("Aggressive", SyncType.aggresive, Duration(minutes: 15)),
    SyncMode("Hourly", SyncType.hourly, Duration(hours: 1)),
    SyncMode("Daily", SyncType.daily, Duration(hours: 18)), // yes this is straight up lie.
  ];
}
