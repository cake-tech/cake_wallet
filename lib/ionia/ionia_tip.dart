class IoniaTip {
  const IoniaTip({this.originalAmount, this.percentage});
  final double originalAmount;
  final double percentage;
  double get additionalAmount => double.parse((originalAmount * percentage / 100).toStringAsFixed(2));

  static const tipList = [
    IoniaTip(originalAmount: 0, percentage: 0),
    IoniaTip(originalAmount: 10, percentage: 10),
    IoniaTip(originalAmount: 20, percentage: 20)
  ];
}
