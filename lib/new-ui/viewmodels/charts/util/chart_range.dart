
class ChartRange {
  final Duration? duration;
  final String displayText;

  // api can handle any precision up to 5min, regardless of data range.
  // we set a "preferred" precision for 2 reasons:
  // - less precision means less data sent, less bandwidth used, and thus less load on the backend
  // - less data points means the chart is easier to look through on a small screen
  final Duration dataPrecision;

  const ChartRange._(this.duration, this.displayText, this.dataPrecision);

  static const oneHour = ChartRange._(Duration(hours: 1), "1H", Duration(minutes: 5));
  static const oneDay = ChartRange._(Duration(days: 1), "1D", Duration(minutes: 15));
  static const sevenDays = ChartRange._(Duration(days: 7), "7D", Duration(hours: 1));
  static const thirtyDays = ChartRange._(Duration(days: 30), "30D", Duration(hours: 4));
  static const oneYear = ChartRange._(Duration(days: 365), "1Y", Duration(days: 1));
  static const all = ChartRange._(null, "ALL", Duration(days: 5));

  static const ranges = [oneHour, oneDay, sevenDays, thirtyDays, oneYear, all];
}
