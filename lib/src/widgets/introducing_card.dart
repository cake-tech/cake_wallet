import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IntroducingCard extends StatelessWidget {
  IntroducingCard(
      {required this.borderColor,
      required this.closeCard,
      required this.title,
      required this.subTitle});

  final String title;
  final String subTitle;
  final Color borderColor;
  final Function() closeCard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14),
                      Text(
                        subTitle,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
              child: Semantics(
                label: S.of(context).close,
                child: GestureDetector(
                  onTap: closeCard,
                  child: Container(
                    height: 23,
                    width: 23,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/x.png',
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 15,
                        width: 15,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
