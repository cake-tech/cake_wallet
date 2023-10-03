import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

class Web3RequestModal extends StatelessWidget {
  const Web3RequestModal({required this.child, this.onAccept, this.onReject, super.key});

  final Widget child;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
             
              Expanded(
                child: PrimaryButton(
                  onPressed: onReject ?? () => Navigator.of(context).pop(false),
                  text: S.current.reject,
                  color: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.onError,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  onPressed: onAccept ?? () => Navigator.of(context).pop(true),
                  text: S.current.approve,
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),       
            ],
          ),
        ],
      ),
    );
  }
}
