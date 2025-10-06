import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class ManufacturerOptionTile extends StatelessWidget {
  const ManufacturerOptionTile({
    required this.onPressed,
    required this.image,
    required this.currentTheme,
    this.tag,
    this.isUnavailable = false,
  });

  final VoidCallback onPressed;
  final Widget image;
  final String? tag;
  final bool isUnavailable;
  final MaterialThemeBase currentTheme; 

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: isUnavailable ? 0.5 : 1,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  currentTheme.customColors.cardGradientColorPrimary,
                  currentTheme.customColors.cardGradientColorSecondary,
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
                                    border: Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context).colorScheme.surfaceContainerLow),
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                margin: EdgeInsets.only(left: 5),
                                child: Text(tag!))
                        ],
                      ),
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
        ),
      );
}
