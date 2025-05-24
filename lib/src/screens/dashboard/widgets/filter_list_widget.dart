import 'package:cake_wallet/entities/list_order_mode.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';

class FilterListWidget extends StatefulWidget {
  FilterListWidget({
    required this.initalType,
    required this.initalAscending,
    required this.onClose,
  });

  final FilterListOrderType? initalType;
  final bool initalAscending;
  final Function(bool, FilterListOrderType) onClose;

  @override
  FilterListWidgetState createState() => FilterListWidgetState();
}

class FilterListWidgetState extends State<FilterListWidget> {
  late bool ascending;
  late FilterListOrderType? type;

  @override
  void initState() {
    super.initState();
    ascending = widget.initalAscending;
    type = widget.initalType;
  }

  void setSelectedOrderType(FilterListOrderType? orderType) {
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
              color: Theme.of(context).colorScheme.surface,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    S.of(context).order_by,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                  ),
                ),
                if (type != FilterListOrderType.Custom) ...[
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
                  value: FilterListOrderType.CreationDate,
                  groupValue: type,
                  title: Text(
                    FilterListOrderType.CreationDate.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile(
                  value: FilterListOrderType.Alphabetical,
                  groupValue: type,
                  title: Text(
                    FilterListOrderType.Alphabetical.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile(
                  value: FilterListOrderType.GroupByType,
                  groupValue: type,
                  title: Text(
                    FilterListOrderType.GroupByType.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile(
                  value: FilterListOrderType.Custom,
                  groupValue: type,
                  title: Text(
                    FilterListOrderType.Custom.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onChanged: setSelectedOrderType,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ]),
            ),
          ),
        )
      ],
    );
  }
}
