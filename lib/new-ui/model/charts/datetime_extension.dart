
extension DateTimeX on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch~/1000;

  static DateTime fromSecondsSinceEpoch(int seconds) => DateTime.fromMillisecondsSinceEpoch(seconds*1000);
}