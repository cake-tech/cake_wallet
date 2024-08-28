import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/src/screens/select_options_page.dart';
import 'package:flutter/cupertino.dart';

class BuyOptionsPage extends SelectOptionsPage {
  BuyOptionsPage({required this.items, this.pickAnOption});

  final List<SelectableItem> items;
  final Function(SelectableOption option)? pickAnOption;

  @override
  String get pageTitle => 'Choose a provider';

  @override
  EdgeInsets? get contentPadding => null;

  @override
  EdgeInsets? get tilePadding => EdgeInsets.only(top: 8);

  @override
  EdgeInsets? get innerPadding => EdgeInsets.symmetric(horizontal: 24, vertical: 8);

  @override
  double? get imageHeight => 40;

  @override
  double? get imageWidth => 40;

  @override
  TextStyle? get subTitleTextStyle => null;

  @override
  Color? get selectedBackgroundColor => null;

  @override
  double? get tileBorderRadius => 30;

  @override
  String get bottomSectionText => '';

  @override
  void Function(SelectableOption option)? get onOptionTap => pickAnOption;
}
