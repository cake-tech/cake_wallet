import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'base_bottom_sheet_widget.dart';

class InfoStep {
  final String iconPath;
  final String description;

  const InfoStep(this.iconPath, this.description);
}

class InfoStepsBottomSheet extends BaseBottomSheet {
  final List<InfoStep> steps;

  InfoStepsBottomSheet({
    required String titleText,
    required this.steps,
    String? titleIconPath,
  }) : super(
            titleText: titleText,
            titleIconPath: titleIconPath,
            footerType: FooterType.none,
            maxHeight: 900);

  @override
  Widget contentWidget(BuildContext context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
          children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: steps
                        .map((step) => Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            spacing: 10.0,
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              SvgPicture.asset(
                                                step.iconPath,
                                                colorFilter: ColorFilter.mode(
                                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                                    BlendMode.srcIn),
                                              ),
                                              Text(
                                                step.description,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                        color: context
                                                            .currentTheme.colorScheme.onSurface,
                                                        fontWeight: FontWeight.w400),
                                              )
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                if (step != steps.last)
                                  Container(
                                    width: 5,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainer),
                                  )
                              ],
                            ))
                        .toList(),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                text: S.of(context).close,
                color: context.currentTheme.colorScheme.primary,
                textColor: context.currentTheme.isDark
                        ? context.currentTheme.colorScheme.onPrimary
                        : context.currentTheme.colorScheme.onPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
          ),
        ),
      );

  @override
  Widget footerWidget(BuildContext context) => SizedBox.shrink();
}
