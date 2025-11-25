import 'package:cake_wallet/entities/new_ui_entities/new_list_row_item.dart';
import 'package:cake_wallet/src/widgets/new_list_row.dart';
import 'package:flutter/material.dart';

class NewListSections extends StatelessWidget {
  const NewListSections({
    super.key,
    required this.sections,
    required this.controllers,
    required this.getCheckboxValue,
    required this.updateCheckboxValue,
  });

  final Map<String, List<NewListRowItem>> sections;
  final Map<String, TextEditingController> controllers;
  final bool Function(String key) getCheckboxValue;
  final void Function(String key, bool value) updateCheckboxValue;

  final double sectionSpacing = 20.0;

  @override
  Widget build(BuildContext context) {
    final entries = sections.entries.toList();

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) SizedBox(height: sectionSpacing),
          _buildSection(entries[i].value),
        ],
      ],
    );
  }

  Widget _buildSection(List<NewListRowItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        switch (item.type) {
          case NewListRowType.textFormField:
            return NewListRow(
              key: ValueKey(item.key),
              type: NewListRowType.textFormField,
              label: item.label,
              controller: controllers[item.key],
              isFirstInSection: item == items.first,
              isLastInSection: item == items.last,
            );

          case NewListRowType.checkbox:
            return NewListRow(
              key: ValueKey(item.key),
              type: NewListRowType.checkbox,
              label: item.label,
              checkboxValue: getCheckboxValue(item.key),
              isFirstInSection: item == items.first,
              isLastInSection: item == items.last,
              onCheckboxChanged: (newValue) {
                updateCheckboxValue(item.key, newValue);
              },
            );

          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}
