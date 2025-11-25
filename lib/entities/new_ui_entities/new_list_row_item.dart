import 'package:cake_wallet/src/widgets/new_list_row.dart';
import 'package:flutter/cupertino.dart';

class NewListRowItem {
  NewListRowItem({
    required this.key,
    required this.label,
    required this.type,
    this.initialValue = '',
    this.checkboxValue = false,
    this.validator,
    this.onCheckboxChanged,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String key;
  final String label;
  final NewListRowType type;

  final String initialValue;
  final bool checkboxValue;
  final ValueChanged<bool>? onCheckboxChanged;

  final FormFieldValidator<String>? validator;

  final bool isFirstInSection;
  final bool isLastInSection;
}
