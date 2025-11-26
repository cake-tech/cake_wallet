import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_checkbox_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_text_field_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_toggle_widget.dart';
import 'package:flutter/material.dart';

class NewListSections extends StatelessWidget {
  const NewListSections({
    super.key,
    required this.sections,
    this.controllers = const {},
    this.getCheckboxValue,
    this.updateCheckboxValue,
  });

  final Map<String, List<ListItem>> sections;
  final Map<String, TextEditingController> controllers;
  final bool Function(String key)? getCheckboxValue;
  final void Function(String key, bool value)? updateCheckboxValue;

  static const double sectionSpacing = 20.0;

  @override
  Widget build(BuildContext context) {
    final entries = sections.entries.toList();

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: sectionSpacing),
          _buildSection(entries[i].value),
        ],
      ],
    );
  }

  Widget _buildSection(List<ListItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < items.length; index++)
          _withSectionFlags(items[index], index, items.length),
      ],
    );
  }

  Widget _withSectionFlags(ListItem item, int index, int length) {
    final isFirst = index == 0;
    final isLast = index == length - 1;

    if (item is ListItemTextField) {
      final controller = controllers[item.keyValue];

      assert(
          controller != null,
          'No controller provided for key ${item.keyValue}. '
          'Please provide a TextEditingController for this key.');

      return ListItemTextFieldWidget(
        keyValue: item.keyValue,
        label: item.label,
        controller: controllers[item.keyValue]!,
        validator: item.validator,
        isFirstInSection: isFirst,
        isLastInSection: isLast,
      );
    }

    if (item is ListItemToggle) {
      return ListItemToggleWidget(
        keyValue: item.keyValue,
        label: item.label,
        value: getCheckboxValue!(item.keyValue),
        onChanged: (newValue) {
          updateCheckboxValue!(item.keyValue, newValue);
          item.onChanged(newValue);
        },
        isFirstInSection: isFirst,
        isLastInSection: isLast,
      );
    }

    if (item is ListItemCheckbox) {
      return ListItemCheckboxWidget(
        keyValue: item.keyValue,
        label: item.label,
        value: getCheckboxValue!(item.keyValue),
        onChanged: (newValue) {
          updateCheckboxValue!(item.keyValue, newValue);
          item.onChanged(newValue);
        },
        isFirstInSection: isFirst,
        isLastInSection: isLast,
      );
    }

    return SizedBox.shrink();
  }
}
