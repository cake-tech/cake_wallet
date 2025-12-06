import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemTextField extends ListItem {
  const ListItemTextField({
    required super.keyValue,
    required super.label,
    this.initialValue,
    this.validator,
    this.onChanged,
  });

  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
}
