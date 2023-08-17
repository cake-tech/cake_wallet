import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/string_constants.dart';
import '../buttons/custom_button.dart';

class Web3RequestModal extends StatelessWidget {
  final Widget child;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const Web3RequestModal({
    super.key,
    required this.child,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(
            height: StyleConstants.linear16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                onTap: onAccept ?? () => Navigator.of(context).pop(true),
                type: CustomButtonType.valid,
                child: const Text(
                  StringConstants.approve,
                  style: StyleConstants.buttonText,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                width: StyleConstants.linear16,
              ),
              CustomButton(
                onTap: onReject ?? () => Navigator.of(context).pop(false),
                type: CustomButtonType.invalid,
                child: const Text(
                  StringConstants.reject,
                  style: StyleConstants.buttonText,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
