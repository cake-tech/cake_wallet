import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class AlertWithPickerOption extends BaseAlertDialog {
  AlertWithPickerOption(
      {required this.alertTitle,
      required this.alertTitleTextSize,
      required this.alertSubtitle,
      required this.options,
      this.onOptionSelected,
      this.alertBarrierDismissible = true,
      Key? key});

  final String alertTitle;
  final double alertTitleTextSize;
  final String alertSubtitle;
  final List<Map<String, String>> options;
  final ValueChanged<Map<String, String>>? onOptionSelected;
  final bool alertBarrierDismissible;

  @override
  String get titleText => alertTitle;

  @override
  double? get titleTextSize => alertTitleTextSize;

  @override
  String get contentText => alertSubtitle;

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  Widget actionButtons(BuildContext context) => Container();

  @override
  bool get isBottomDividerExists => false;

  @override
  Widget content(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          contentText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                 
                color: Theme.of(context).colorScheme.onSurface,
                decoration: TextDecoration.none,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final item = options[index];
              final displayKey = item['displayKey'] ?? '';
              final displayValue = item['displayValue'] ?? '';
              return GestureDetector(
                onTap: () {
                  onOptionSelected?.call(item);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).colorScheme.surface),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayKey,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              decoration: TextDecoration.none,
                            ),
                      ),
                      Row(
                        children: [
                          Text(
                            displayValue,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  decoration: TextDecoration.none,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
