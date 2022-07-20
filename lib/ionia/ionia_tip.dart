class IoniaTip {
  const IoniaTip({this.originalAmount, this.percentage});
  final double originalAmount;
  final double percentage;
  double get additionalAmount => double.parse((originalAmount * percentage / 100).toStringAsFixed(2));
}
