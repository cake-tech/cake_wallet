import 'package:cw_core/card_design.dart';

class CardDisplayConfig {
  final CardDesign design;
  final bool showIconOnCard;

  const CardDisplayConfig({
    required this.design,
    this.showIconOnCard = false,
  });
}
