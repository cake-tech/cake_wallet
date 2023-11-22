import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class FilterListWidget extends StatelessWidget {
  FilterListWidget({required this.initialType});

  final WalletListOrderType? initialType;

  void setSelectedOrderType(BuildContext context, WalletListOrderType? orderType) {
    Navigator.of(context).pop(orderType);
  }

  @override
  Widget build(BuildContext context) {
    const sectionDivider = const HorizontalSectionDivider();
    return PickerWrapperWidget(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            child: Container(
              color: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    S.of(context).filter_by,
                    style: TextStyle(
                      color:
                          Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
                      fontSize: 16,
                      fontFamily: 'Lato',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                sectionDivider,
                RadioListTile(
                  value: WalletListOrderType.CreationDate,
                  groupValue: initialType,
                  title: Text(
                    WalletListOrderType.CreationDate.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: (WalletListOrderType? type) => setSelectedOrderType(context, type),
                  activeColor: Theme.of(context).dividerColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.Alphabetical,
                  groupValue: initialType,
                  title: Text(
                    WalletListOrderType.Alphabetical.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: (WalletListOrderType? type) => setSelectedOrderType(context, type),
                  activeColor: Theme.of(context).dividerColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.GroupByType,
                  groupValue: initialType,
                  title: Text(
                    WalletListOrderType.GroupByType.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: (WalletListOrderType? type) => setSelectedOrderType(context, type),
                  activeColor: Theme.of(context).dividerColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.Custom,
                  groupValue: initialType,
                  title: Text(
                    WalletListOrderType.Custom.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: (WalletListOrderType? type) => setSelectedOrderType(context, type),
                  activeColor: Theme.of(context).dividerColor,
                ),
              ]),
            ),
          ),
        )
      ],
    );
  }
}
