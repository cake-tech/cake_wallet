import 'package:cake_wallet/entities/list_order_mode.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class FilterListWidget extends StatefulWidget {
  FilterListWidget({
    required this.initalType,
    required this.initalAscending,
    required this.onClose,
  });

  final WalletListOrderType? initalType;
  final bool initalAscending;
  final Function(bool, WalletListOrderType) onClose;

  @override
  FilterListWidgetState createState() => FilterListWidgetState();
}

class FilterListWidgetState extends State<FilterListWidget> {
  late bool ascending;
  late WalletListOrderType? type;

  @override
  void initState() {
    super.initState();
    ascending = widget.initalAscending;
    type = widget.initalType;
  }

  void setSelectedOrderType(WalletListOrderType? orderType) {
    setState(() {
      type = orderType;
    });
  }

  @override
  Widget build(BuildContext context) {
    const sectionDivider = const HorizontalSectionDivider();
    return PickerWrapperWidget(
      onClose: () {
        widget.onClose(ascending, type!);
        Navigator.of(context).pop();
      },
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
                    S.of(context).order_by,
                    style: TextStyle(
                      color:
                          Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
                      fontSize: 16,
                      fontFamily: 'Lato',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (type != WalletListOrderType.Custom) ...[
                  sectionDivider,
                  SettingsChoicesCell(
                    ChoicesListItem<ListOrderMode>(
                      title: "",
                      items: ListOrderMode.all,
                      selectedItem: ascending ? ListOrderMode.ascending : ListOrderMode.descending,
                      onItemSelected: (ListOrderMode listOrderMode) {
                        setState(() {
                          ascending = listOrderMode == ListOrderMode.ascending;
                        });
                      },
                    ),
                  ),
                ],
                sectionDivider,
                RadioListTile(
                  value: WalletListOrderType.CreationDate,
                  groupValue: type,
                  title: Text(
                    WalletListOrderType.CreationDate.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).primaryColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.Alphabetical,
                  groupValue: type,
                  title: Text(
                    WalletListOrderType.Alphabetical.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).primaryColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.GroupByType,
                  groupValue: type,
                  title: Text(
                    WalletListOrderType.GroupByType.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).primaryColor,
                ),
                RadioListTile(
                  value: WalletListOrderType.Custom,
                  groupValue: type,
                  title: Text(
                    WalletListOrderType.Custom.toString(),
                    style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ]),
            ),
          ),
        )
      ],
    );
  }
}
