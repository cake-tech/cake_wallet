import 'package:cake_wallet/entities/desktop_dropdown_item.dart';
import 'package:cw_core/wallet_type.dart';

class WalletListItem extends DesktopDropdownItem {
   WalletListItem(
      {required this.name,
       required this.type,
      required this.key,
      this.isCurrent = false,
      this.isEnabled = true,  this.optionName = '',});

  final String name;
  final WalletType type;
  final bool isCurrent;
  final dynamic key;
  final bool isEnabled;
  final String optionName;
}
