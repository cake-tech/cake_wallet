import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

import 'base_bottom_sheet_widget.dart';

class InfoStep {
  final String title;
  final String description;

  const InfoStep(this.title, this.description);
}

class InfoStepsBottomSheet extends BaseBottomSheet {
  final MaterialThemeBase currentTheme;
  final List<InfoStep> steps;

  InfoStepsBottomSheet({
    required String titleText,
    required this.steps,
    String? titleIconPath,
    required this.currentTheme,
  }) : super(titleText: titleText, titleIconPath: titleIconPath, footerType: FooterType.none, maxHeight: 900);

  @override
  Widget contentWidget(BuildContext context) => SizedBox(
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: steps
                      .map((step) => Container(
                            margin: EdgeInsets.only(
                                bottom: 15, left: 20, right: 20),
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).cardColor,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          step.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Text(
                                            step.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                text: S.of(context).close,
                color: Theme.of(context).colorScheme.primary,
                textColor: currentTheme.isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
      );

  @override
  Widget footerWidget(BuildContext context) {
    return const SizedBox.shrink();
  }
}
