// ignore: must_be_immutable
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class QRFormatSelectionDialog extends BaseAlertDialog {
  final List<String> formats;
  final int currentIndex;
  final Function(int) onFormatSelected;

  QRFormatSelectionDialog({
    required this.formats,
    required this.currentIndex,
    required this.onFormatSelected,
  });

  @override
  String get titleText => S.current.choose_qr_code_format;

  @override
  Widget content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.current.choose_qr_code_format_note,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
          ),
          SizedBox(height: 16),
          ...formats.asMap().entries.map((entry) {
            final index = entry.key;
            final format = entry.value;
            final isSelected = index == currentIndex;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onFormatSelected(index),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (format.startsWith('Cupcake'))
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SvgPicture.asset(
                                'assets/images/cupcake.svg',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFormatName(format),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _getFormatSubtitle(format),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.6)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  String get leftActionButtonText => "";

  @override
  String get rightActionButtonText => "";

  @override
  VoidCallback get actionLeft => () {};

  @override
  VoidCallback get actionRight => () {};

  @override
  bool get isBottomDividerExists => false;

  @override
  Widget actionButtons(BuildContext context) {
    return SizedBox.shrink(); // get rid fo cancel button
  }

  String _getFormatName(String format) {
    return format.split(' ')[0];
  }

  String _getFormatSubtitle(String format) {
    return format.substring(format.indexOf(' ') + 1);
  }
}
