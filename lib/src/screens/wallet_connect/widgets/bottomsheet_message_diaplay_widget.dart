import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class BottomSheetMessageDisplayWidget extends StatelessWidget {
  final String errorText;
  final bool isError;

  const BottomSheetMessageDisplayWidget({super.key, required this.errorText, this.isError = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isError ? S.current.error : 'Successful',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          errorText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
