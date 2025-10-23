import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class ProviderOptionTile extends StatelessWidget {
  const ProviderOptionTile({
    required this.onPressed,
    required this.lightImagePath,
    required this.darkImagePath,
    required this.title,
    this.topLeftSubTitle,
    this.topRightSubTitle,
    this.bottomLeftSubTitle,
    this.bottomRightSubTitle,
    this.leftSubTitleIconPath,
    this.rightSubTitleLightIconPath,
    this.rightSubTitleDarkIconPath,
    this.description,
    this.badges,
    this.borderRadius,
    this.imageHeight,
    this.imageWidth,
    this.padding,
    this.titleTextStyle,
    this.firstSubTitleTextStyle,
    this.secondSubTitleTextStyle,
    this.leadingIcon,
    this.selectedBackgroundColor,
    this.isSelected = false,
    required this.isLightMode,
  });

  final VoidCallback onPressed;
  final String lightImagePath;
  final String darkImagePath;
  final String title;
  final String? topLeftSubTitle;
  final String? topRightSubTitle;
  final String? bottomLeftSubTitle;
  final String? bottomRightSubTitle;
  final String? leftSubTitleIconPath;
  final String? rightSubTitleLightIconPath;
  final String? rightSubTitleDarkIconPath;
  final String? description;
  final List<String>? badges;
  final double? borderRadius;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets? padding;
  final TextStyle? titleTextStyle;
  final TextStyle? firstSubTitleTextStyle;
  final TextStyle? secondSubTitleTextStyle;
  final IconData? leadingIcon;
  final Color? selectedBackgroundColor;
  final bool isSelected;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainer;

    final textColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    final badgeColor = isSelected
        ? Theme.of(context).colorScheme.surfaceContainer
        : Theme.of(context).colorScheme.onSurface;

    final badgeTextColor = isSelected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.surfaceContainer;

    final imagePath = isSelected
        ? !isLightMode
            ? darkImagePath
            : lightImagePath
        : !isLightMode
            ? lightImagePath
            : darkImagePath;

    final rightSubTitleIconPath = isSelected
        ? !isLightMode
            ? rightSubTitleDarkIconPath
            : rightSubTitleLightIconPath
        : !isLightMode
            ? rightSubTitleLightIconPath
            : rightSubTitleDarkIconPath;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 12)),
          border: isSelected && !isLightMode ? Border.all(color: textColor) : null,
          color: backgroundColor,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  ImageUtil.getImageFromPath(imagePath:imagePath,
                      height: imageHeight, width: imageWidth),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: titleTextStyle ??
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                            ),
                          ),
                          Row(
                            children: [
                              if (leadingIcon != null)
                                Icon(leadingIcon, size: 16, color: textColor),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (topLeftSubTitle != null || topRightSubTitle != null)
                subTitleWidget(
                    leftSubTitle: topLeftSubTitle,
                    subTitleIconPath: leftSubTitleIconPath,
                    textColor: textColor,
                    rightSubTitle: topRightSubTitle,
                    rightSubTitleIconPath: rightSubTitleIconPath),
              if (bottomLeftSubTitle != null || bottomRightSubTitle != null)
                subTitleWidget(
                  leftSubTitle: bottomLeftSubTitle,
                  textColor: textColor,
                  subTitleFontSize: 12,
                ),
              if (badges != null && badges!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      ...badges!
                          .map(
                            (badge) => Badge(
                              title: badge,
                              textColor: badgeTextColor,
                              backgroundColor: badgeColor,
                            ),
                          )
                          .toList()
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class subTitleWidget extends StatelessWidget {
  const subTitleWidget({
    super.key,
    this.leftSubTitle,
    this.subTitleIconPath,
    required this.textColor,
    this.rightSubTitle,
    this.rightSubTitleIconPath,
    this.subTitleFontSize = 16,
  });

  final String? leftSubTitle;
  final String? subTitleIconPath;
  final Color textColor;
  final String? rightSubTitle;
  final String? rightSubTitleIconPath;
  final double subTitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leftSubTitle != null || subTitleIconPath != null
            ? Row(
                children: [
                  if (subTitleIconPath != null && subTitleIconPath!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ImageUtil.getImageFromPath(imagePath: subTitleIconPath!),
                    ),
                  Text(
                    leftSubTitle ?? '',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: subTitleFontSize, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ],
              )
            : Offstage(),
        rightSubTitle != null || rightSubTitleIconPath != null
            ? Row(
                children: [
                  if (rightSubTitleIconPath != null && rightSubTitleIconPath!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ImageUtil.getImageFromPath(imagePath: rightSubTitleIconPath!),
                    ),
                  Text(
                    rightSubTitle ?? '',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: subTitleFontSize, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ],
              )
            : Offstage(),
      ],
    );
  }
}

class Badge extends StatelessWidget {
  Badge({required this.textColor, required this.backgroundColor, required this.title});

  final String title;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(24)), color: backgroundColor),
          alignment: Alignment.center,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class OptionTilePlaceholder extends StatefulWidget {
  OptionTilePlaceholder({
    this.borderRadius,
    this.imageHeight,
    this.imageWidth,
    this.padding,
    this.leadingIcon,
    this.withBadge = true,
    this.withSubtitle = true,
    this.isDarkTheme = false,
    this.errorText,
  });

  final double? borderRadius;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets? padding;
  final IconData? leadingIcon;
  final bool withBadge;
  final bool withSubtitle;
  final bool isDarkTheme;
  final String? errorText;

  @override
  _OptionTilePlaceholderState createState() => _OptionTilePlaceholderState();
}

class _OptionTilePlaceholderState extends State<OptionTilePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainer;
    final titleColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);

    return widget.errorText != null
        ? Container(
            width: double.infinity,
            padding: widget.padding ?? EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius ?? 12),
              ),
              color: backgroundColor,
            ),
            child: Column(
              children: [
                Text(
                  widget.errorText!,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: titleColor,
                        fontSize: 16,
                      ),
                ),
                if (widget.withSubtitle) SizedBox(height: 8),
                Text(
                  '',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: titleColor,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          )
        : AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: widget.padding ?? EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius ?? 12)),
                      color: backgroundColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: widget.imageHeight ?? 35,
                              width: widget.imageWidth ?? 35,
                              decoration: BoxDecoration(
                                color: titleColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 20,
                                      width: 70,
                                      decoration: BoxDecoration(
                                        color: titleColor,
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                      ),
                                    ),
                                    if (widget.leadingIcon != null)
                                      Icon(widget.leadingIcon, size: 16, color: titleColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.withSubtitle)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 20,
                                  width: 170,
                                  decoration: BoxDecoration(
                                    color: titleColor,
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.withBadge)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 30,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: titleColor,
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 30,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: titleColor,
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius ?? 12)),
                        gradient: LinearGradient(
                          begin: Alignment(-2, -4),
                          end: Alignment(2, 4),
                          stops: [
                            _animation.value - 0.2,
                            _animation.value,
                            _animation.value + 0.2,
                          ],
                          colors: [
                            backgroundColor.withOpacity(widget.isDarkTheme ? 0.4 : 0.7),
                            backgroundColor.withOpacity(widget.isDarkTheme ? 0.7 : 0.4),
                            backgroundColor.withOpacity(widget.isDarkTheme ? 0.4 : 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }
}
