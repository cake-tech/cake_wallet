import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';

class PriceChangeData implements Comparable<PriceChangeData> {
  final PriceChangeDirection direction;
  final String amount;
  final String percentage;

  @override
  int compareTo(PriceChangeData other) {
    final double thisValue =
        double.parse(percentage) * (direction == PriceChangeDirection.up ? 1 : -1);
    final double otherValue =
        double.parse(other.percentage) * (other.direction == PriceChangeDirection.up ? 1 : -1);
    return thisValue.compareTo(otherValue);
  }

  const PriceChangeData({required this.direction, required this.amount, required this.percentage});
}
