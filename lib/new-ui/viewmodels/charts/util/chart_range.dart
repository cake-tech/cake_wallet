
class ChartRange {
  final Duration? duration;
  final String displayText;

  const ChartRange._(this.duration, this.displayText);

  static const oneHour = ChartRange._(Duration(hours: 1), "1H");
  static const oneDay = ChartRange._(Duration(days: 1), "1D");
  static const sevenDays = ChartRange._(Duration(days: 7), "7D");
  static const thirtyDays = ChartRange._(Duration(days: 30), "30D");
  static const oneYear = ChartRange._(Duration(days: 365), "1Y");
  static const all = ChartRange._(null, "ALL");

  static const ranges = [oneHour, oneDay, sevenDays, thirtyDays, oneYear, all];
}
