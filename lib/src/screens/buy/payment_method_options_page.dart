import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/select_options_page.dart';
import 'package:flutter/cupertino.dart';

class PaymentMethodOptionsPage extends SelectOptionsPage {
  PaymentMethodOptionsPage({required this.items, this.pickAnOption});

  final List<SelectableItem> items;
  final Function(SelectableOption option)? pickAnOption;

  @override
  String get pageTitle => S.current.choose_a_payment_method;

  @override
  EdgeInsets? get contentPadding => null;

  @override
  EdgeInsets? get tilePadding => EdgeInsets.only(top: 12);

  @override
  EdgeInsets? get innerPadding => EdgeInsets.symmetric(horizontal: 24, vertical: 12);

  @override
  double? get imageHeight => null;

  @override
  double? get imageWidth => null;

  @override
  Color? get selectedBackgroundColor => null;

  @override
  double? get tileBorderRadius => 30;

  @override
  String get bottomSectionText => '';

  @override
  void Function(SelectableOption option)? get onOptionTap => pickAnOption;

  @override
  String get primaryButtonText => S.current.confirm;

  @override
  void Function(BuildContext context)? get primaryButtonAction => null;
}
