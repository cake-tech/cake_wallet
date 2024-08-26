import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

abstract class SelectOptionsPage<T extends SelectableOption> extends BasePage {
  SelectOptionsPage();

  String get pageTitle;

  EdgeInsets? get contentPadding;

  EdgeInsets? get tilePadding;

  EdgeInsets? get innerPadding;

  double? get imageHeight;

  double? get imageWidth;

  TextStyle? get subTitleTextStyle;

  Color? get selectedBackgroundColor;

  double? get tileBorderRadius;

  String get bottomSectionText;

  List<T> get options;

  void Function(T option)? get onOptionTap;

  @override
  String get title => pageTitle;

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      content: BodySelectOptionsPage<T>(
          options: options,
          onOptionTap: onOptionTap,
          tilePadding: tilePadding,
          tileBorderRadius: tileBorderRadius,
          subTitleTextStyle: subTitleTextStyle,
          imageHeight: imageHeight,
          imageWidth: imageWidth,
          innerPadding: innerPadding),
      bottomSection: Padding(
        padding: contentPadding ?? EdgeInsets.zero,
        child: Text(
          bottomSectionText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
          ),
        ),
      ),
    );
  }
}

class BodySelectOptionsPage<T extends SelectableOption> extends StatefulWidget {
  const BodySelectOptionsPage({
    required this.options,
    this.onOptionTap,
    this.tilePadding,
    this.tileBorderRadius,
    this.subTitleTextStyle,
    this.imageHeight,
    this.imageWidth,
    this.innerPadding,
  });

  final List<T> options;
  final void Function(T option)? onOptionTap;
  final EdgeInsets? tilePadding;
  final double? tileBorderRadius;
  final TextStyle? subTitleTextStyle;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets? innerPadding;

  @override
  _BodySelectOptionsPageState<T> createState() => _BodySelectOptionsPageState<T>();
}

class _BodySelectOptionsPageState<T extends SelectableOption>
    extends State<BodySelectOptionsPage<T>> {
  late List<T> _options;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
  }

  void _handleOptionTap(T option) {
    setState(() {
      for (var opt in _options) {
        opt.isOptionSelected = false;
      }
      option.isOptionSelected = true;
    });
    widget.onOptionTap?.call(option);
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).extension<OptionTileTheme>()?.useDarkImage ?? false;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 350),
        child: Column(
          children: [
            ..._options
                .map((option) => Padding(
                    padding: widget.tilePadding ?? EdgeInsets.only(top: 24),
                    child: OptionTile(
                      title: option.title,
                      imagePath: option.iconPath,
                      imageHeight: widget.imageHeight,
                      imageWidth: widget.imageWidth,
                      padding: widget.innerPadding,
                      description: option.description,
                      subTitle: option.subTitle,
                      firstBadgeName: option.firstBadgeTitle,
                      secondBadgeName: option.secondBadgeTitle,
                      isSelected: option.isOptionSelected,
                      subTitleTextStyle: widget.subTitleTextStyle,
                      borderRadius: widget.tileBorderRadius,
                      isLightMode: isLightMode,
                      onPressed: () => _handleOptionTap(option),
                    )))
                .toList(),
          ],
        ),
      ),
    );
  }
}
