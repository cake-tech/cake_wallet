import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class ManufacturerOptionTile extends StatelessWidget {
  const ManufacturerOptionTile({
    required this.onPressed,
    required this.image,
    required this.supportedDevices,
    required this.isDarkTheme,
    this.tag,
  });

  final VoidCallback onPressed;
  final Widget image;
  final String supportedDevices;
  final String? tag;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                isDarkTheme
                    ? CustomThemeColors.cardGradientColorPrimaryDark
                    : CustomThemeColors.cardGradientColorPrimaryLight,
                isDarkTheme
                    ? CustomThemeColors.cardGradientColorSecondaryDark
                    : CustomThemeColors.cardGradientColorSecondaryLight,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Container(height: 25, child: image),
                        if (tag != null)
                          Container(
                              decoration: BoxDecoration(
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(20),
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              margin: EdgeInsets.only(left: 5),
                              child: Text(tag!))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '${S.of(context).supported}: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: supportedDevices,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ]),
                      ),
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              )
            ],
          ),
        ),
      );
}
