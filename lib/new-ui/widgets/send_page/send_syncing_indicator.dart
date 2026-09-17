import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/material.dart';

class SendSyncingIndicator extends StatelessWidget {
  const SendSyncingIndicator({super.key, required this.status});

  final SyncStatus status;

  static const outlineColor = Color(0xFFFFB84E);
  static const backgroundColor = Color(0xFF8E5800);

  @override
  Widget build(BuildContext context) {
    late final String eta;
    if (status is SyncingSyncStatus) {
      eta = (status as SyncingSyncStatus).getFormattedEta() ?? "";
    } else {
      eta = "";
    }

    final statusText = "${S.of(context).synchronizing}... ${eta}";

    // A single status node: progress ticks keep updating the value, and without a live
    // region they do not interrupt the user on every tick.
    return Semantics(
      container: true,
      label: statusText,
      value: status.progress() > 0 ? "${(status.progress() * 100).round()}%" : null,
      excludeSemantics: true,
      child: Container(
        height: 48,
        decoration:
            BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(99999)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              if (status.progress() > 0)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: status.progress(),
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: outlineColor,
                    semanticsLabel: S.of(context).synchronizing,
                  ),
                ),
              Text(statusText, style: TextStyle(color: outlineColor)),
            ],
          ),
        ),
      ),
    );
  }
}
