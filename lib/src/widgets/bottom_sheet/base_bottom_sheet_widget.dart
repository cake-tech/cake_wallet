import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

abstract class BaseBottomSheet extends StatelessWidget {
  final String titleText;
  final String? titleIconPath;

  const BaseBottomSheet({required this.titleText, this.titleIconPath, super.key});

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
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
              Image.asset(titleIconPath!, height: 24, width: 24)
            else
              Container(),
            const SizedBox(width: 6),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
      ],
    );
  }

  Widget contentWidget(BuildContext context);

  Widget footerWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 600),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
        child: Container(
          color: Theme.of(context).dialogBackgroundColor,
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
