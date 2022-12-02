import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> getDate({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate}) {

  if (Platform.isIOS) {
    return _buildCupertinoDataPicker(context, initialDate, firstDate, lastDate);
  }

  return _buildMaterialDataPicker(context, initialDate, firstDate, lastDate);
}

Future<DateTime?> _buildMaterialDataPicker(
  BuildContext context,
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate) async {
  return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '');
}

Future<DateTime?> _buildCupertinoDataPicker(
  BuildContext context,
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate) async {
  DateTime? date;
  await showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height / 3,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (picked) => date = picked,
            initialDateTime: initialDate,
            minimumDate: firstDate,
            maximumDate: lastDate,
          ),
        );
      }
  );
  return date;
}