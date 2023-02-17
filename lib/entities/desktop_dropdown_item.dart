import 'package:cw_core/wallet_type.dart';

abstract class DesktopDropdownItem {
  
  final String name;
  final WalletType type;
  final bool isCurrent;
  final dynamic key;
  final bool isEnabled;
  final String? optionName;

  DesktopDropdownItem({this.name = '', this.type = WalletType.none, this.isCurrent = false, this.key, this.isEnabled = true, this.optionName});
}

class DropdownOption extends DesktopDropdownItem {
  DropdownOption({required this.name, required this.optionName});

  final String name;
  final String optionName;
}