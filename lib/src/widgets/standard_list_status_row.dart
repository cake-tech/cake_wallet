import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:flutter/material.dart';

class StandardListStatusRow extends StatelessWidget {
  StandardListStatusRow({required this.title, required this.value, this.status});

  final String title;
  final String value;
  final String? status; // waiting, action required, created, fetching, finished, success

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.left,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SyncIndicatorIcon(
                      boolMode: false,
                      value: status ?? value,
                      size: 6,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
