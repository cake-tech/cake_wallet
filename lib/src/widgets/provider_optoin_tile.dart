import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
        ? isLightMode
            ? Theme.of(context).extension<ReceivePageTheme>()!.currentTileBackgroundColor
            : Theme.of(context).extension<OptionTileTheme>()!.titleColor
        : Theme.of(context).cardColor;

    final textColor = isSelected
        ? isLightMode
            ? Colors.white
            : Theme.of(context).cardColor
        : Theme.of(context).extension<OptionTileTheme>()!.titleColor;

    final badgeColor = isSelected
        ? Theme.of(context).cardColor
        : Theme.of(context).extension<OptionTileTheme>()!.titleColor;

    final badgeTextColor = isSelected
        ? Theme.of(context).extension<OptionTileTheme>()!.titleColor
        : Theme.of(context).cardColor;

    final imagePath = isSelected
        ? isLightMode
            ? darkImagePath
            : lightImagePath
        : isLightMode
            ? lightImagePath
            : darkImagePath;

    final rightSubTitleIconPath = isSelected
        ? isLightMode
            ? rightSubTitleDarkIconPath
            : rightSubTitleLightIconPath
        : isLightMode
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
                  getImage(imagePath, height: imageHeight, width: imageWidth),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(title,
                                  style: titleTextStyle ?? textLargeBold(color: textColor))),
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
                    subTitleFontSize: 12),
              if (badges != null && badges!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    ...badges!
                        .map((badge) => Badge(
                            title: badge, textColor: badgeTextColor, backgroundColor: badgeColor))
                        .toList()
                  ]),
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
                    child: getImage(subTitleIconPath!),
                  ),
                Text(
                  leftSubTitle ?? '',
                  style: TextStyle(
                      fontSize: subTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor),
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
                      child: getImage(rightSubTitleIconPath!, imageColor: textColor),
                    ),
                  Text(
                    rightSubTitle ?? '',
                    style: TextStyle(
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
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Widget getImage(String imagePath, {double? height, double? width, Color? imageColor}) {
  final bool isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');
  final bool isSvg = imagePath.endsWith('.svg');
  final double imageHeight = height ?? 35;
  final double imageWidth = width ?? 35;

  if (isNetworkImage) {
    return isSvg
        ? SvgPicture.network(
            imagePath,
            height: imageHeight,
            width: imageWidth,
            colorFilter: imageColor != null ? ColorFilter.mode(imageColor, BlendMode.srcIn) : null,
            placeholderBuilder: (BuildContext context) => Container(
              height: imageHeight,
              width: imageWidth,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          )
        : Image.network(
            imagePath,
            height: imageHeight,
            width: imageWidth,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                height: imageHeight,
                width: imageWidth,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Container(
                height: imageHeight,
                width: imageWidth,
              );
            },
          );
  } else {
    return isSvg
        ? SvgPicture.asset(
            imagePath,
            height: imageHeight,
            width: imageWidth,
            colorFilter: imageColor != null ? ColorFilter.mode(imageColor, BlendMode.srcIn) : null,
          )
        : Image.asset(imagePath, height: imageHeight, width: imageWidth);
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
    final backgroundColor = Theme.of(context).cardColor;
    final titleColor = Theme.of(context).extension<OptionTileTheme>()!.titleColor.withOpacity(0.4);

    return widget.errorText != null
        ? Container(
            width: double.infinity,
            padding: widget.padding ?? EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius ?? 12)),
              color: backgroundColor,
            ),
            child: Column(
              children: [
                Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                  ),
                ),
                if (widget.withSubtitle) SizedBox(height: 8),
                Text(
                  '',
                  style: TextStyle(
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
