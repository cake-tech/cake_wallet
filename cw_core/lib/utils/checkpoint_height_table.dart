class HeightCheckpoint {
  const HeightCheckpoint(int timeSec, this.height) : timeMs = timeSec * 1000;

  final int timeMs;
  final int height;
}

/// Converts between block heights and dates by interpolating between known checkpoints.
/// Past the last checkpoint it extrapolates with the average block time of the last two.
class CheckpointHeightTable {
  const CheckpointHeightTable(this._points);

  final List<HeightCheckpoint> _points;

  int getBlockHeightByTime(DateTime time) {
    final t = time.toUtc().millisecondsSinceEpoch;

    if (_points.isEmpty) {
      return 0;
    }

    if (t <= _points.first.timeMs) {
      return 1;
    }

    for (int i = 0; i < _points.length - 1; i++) {
      final p0 = _points[i];
      final p1 = _points[i + 1];

      if (t >= p0.timeMs && t < p1.timeMs) {
        return _interpolate(p0.height, p1.height, p0.timeMs, p1.timeMs, t);
      }
    }

    final last = _points[_points.length - 1];
    final prev = _points[_points.length - 2];
    final avgBlockTimeMs = (last.timeMs - prev.timeMs) / (last.height - prev.height);
    final blocksSinceLast = ((t - last.timeMs) / avgBlockTimeMs).floor();

    return last.height + blocksSinceLast;
  }

  DateTime getTimeByBlockHeight(int height) {
    if (_points.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    if (height <= 1) {
      return DateTime.fromMillisecondsSinceEpoch(_points.first.timeMs, isUtc: true);
    }

    for (int i = 0; i < _points.length - 1; i++) {
      final p0 = _points[i];
      final p1 = _points[i + 1];

      if (height >= p0.height && height < p1.height) {
        final t = _interpolate(p0.timeMs, p1.timeMs, p0.height, p1.height, height);

        return DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
      }
    }

    final last = _points[_points.length - 1];
    final prev = _points[_points.length - 2];
    final avgBlockTimeMs = (last.timeMs - prev.timeMs) / (last.height - prev.height);
    final msSinceLast = ((height - last.height) * avgBlockTimeMs).floor();

    return DateTime.fromMillisecondsSinceEpoch(last.timeMs + msSinceLast, isUtc: true);
  }

  static int _interpolate(int h0, int h1, int t0, int t1, int t) {
    final ratio = (t - t0) / (t1 - t0);

    return h0 + ((h1 - h0) * ratio).floor();
  }
}
