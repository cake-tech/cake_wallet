import 'package:flutter/material.dart';

abstract class BaseBottomSheet extends StatelessWidget {
  final String titleText;
  final String? titleIconPath;
  final double maxHeight;

  const BaseBottomSheet({required this.titleText, this.titleIconPath, this.maxHeight = 900});

  Widget headerWidget(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Spacer(flex: 4),
              Expanded(
                flex: 2,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (titleIconPath != null)
              Image.asset(titleIconPath!, height: 24, width: 24, excludeFromSemantics: true)
            else
              Container(),
            const SizedBox(width: 6),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget contentWidget(BuildContext context);

  Widget footerWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              headerWidget(context),
              contentWidget(context),
              footerWidget(context),
            ],
          ),
        ),
      ),
    );
  }
}
