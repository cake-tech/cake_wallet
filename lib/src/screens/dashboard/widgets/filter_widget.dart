import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_tile.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

//import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class FilterWidget extends StatelessWidget {
  FilterWidget({required this.filterItems});

  final Map<String, List<FilterItem>> filterItems;

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
                ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filterItems.length,
                  separatorBuilder: (context, _) => sectionDivider,
                  itemBuilder: (_, index1) {
                    final title = filterItems.keys.elementAt(index1);
                    final section = filterItems.values.elementAt(index1);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 20, left: 24, right: 24),
                          child: Text(
                            title,
                            style: TextStyle(
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                fontSize: 16,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none),
                          ),
                        ),
                        ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 28.0),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: section.length,
                          itemBuilder: (_, index2) {
                            final item = section[index2];

                            if (item is DropdownFilterItem) {
                              return  Padding(
                                padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.0,
                                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                                    ),
                                  ),
                                  child: DropdownFilterList(
                                    items: item.items,
                                    caption: item.caption,
                                    selectedItem: item.selectedItem,
                                    onItemSelected: item.onItemSelected,
                                  ),
                                ),
                              );
                            }
                            final content = Observer(
                                builder: (_) => StandardCheckbox(
                                      value: item.value(),
                                      caption: item.caption,
                                      gradientBackground: true,
                                      borderColor: Theme.of(context).dividerColor,
                                      iconColor: Colors.white,
                                      onChanged: (value) => item.onChanged(),
                                    ));
                            return FilterTile(child: content);
                          },
                        )
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        )
      ],
    );
  }
}
