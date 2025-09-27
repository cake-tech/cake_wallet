import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String leftButtonTitle;
  final String rightButtonTitle;
  final String title;
  final String description;
  final String image;
  final MaterialThemeBase currentTheme;
  final Function() leftButtonAction;
  final Function() rightButtonAction;

  final Widget? hintWidget;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.leftButtonTitle,
    required this.rightButtonTitle,
    required this.leftButtonAction,
    required this.rightButtonAction,
    required this.image,
    required this.currentTheme,
    this.hintWidget,
  });

  @override
  Widget build(BuildContext context) {
    return DashBoardRoundedCardWidget(
      currentTheme: currentTheme,
      marginH: 0,
      marginV: 0,
      customBorder: 30,
      title: title,
      subTitle: description,
      hint: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hintWidget != null) hintWidget!,
          if (hintWidget != null) SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: leftButtonAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    leftButtonTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: rightButtonAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    rightButtonTitle,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => {},
      icon: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: CakeImageWidget(
          imageUrl: image,
          height: 40,
          width: 40,
        ),
      ),
    );
  }
}
