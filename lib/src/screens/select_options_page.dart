import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/provider_optoin_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

abstract class SelectOptionsPage extends BasePage {
  SelectOptionsPage();

  String get pageTitle;

  EdgeInsets? get contentPadding;

  EdgeInsets? get tilePadding;

  EdgeInsets? get innerPadding;

  double? get imageHeight;

  double? get imageWidth;

  Color? get selectedBackgroundColor;

  double? get tileBorderRadius;

  String get bottomSectionText;

  bool get primaryButtonEnabled => true;

  String get primaryButtonText => '';

  List<SelectableItem> get items;

  void Function(SelectableOption option)? get onOptionTap;

  void Function(BuildContext context)? get primaryButtonAction;

  @override
  String get title => pageTitle;

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      content: BodySelectOptionsPage(
          items: items,
          onOptionTap: onOptionTap,
          tilePadding: tilePadding,
          tileBorderRadius: tileBorderRadius,
          imageHeight: imageHeight,
          imageWidth: imageWidth,
          innerPadding: innerPadding),
      bottomSection: Padding(
        padding: contentPadding ?? EdgeInsets.zero,
        child: Column(
          children: [
            Text(
              bottomSectionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
              ),
            ),
            if (primaryButtonEnabled)
              LoadingPrimaryButton(
                  text: primaryButtonText,
                  onPressed: () {
                    primaryButtonAction != null
                        ? primaryButtonAction!(context)
                        : Navigator.pop(context);
                  },
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isDisabled: false,
                  isLoading: false)
          ],
        ),
      ),
    );
  }
}

class BodySelectOptionsPage extends StatefulWidget {
  const BodySelectOptionsPage({
    required this.items,
    this.onOptionTap,
    this.tilePadding,
    this.tileBorderRadius,
    this.imageHeight,
    this.imageWidth,
    this.innerPadding,
  });

  final List<SelectableItem> items;
  final void Function(SelectableOption option)? onOptionTap;
  final EdgeInsets? tilePadding;
  final double? tileBorderRadius;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets? innerPadding;

  @override
  _BodySelectOptionsPageState createState() => _BodySelectOptionsPageState();
}

class _BodySelectOptionsPageState extends State<BodySelectOptionsPage> {
  late List<SelectableItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  void _handleOptionTap(SelectableOption option) {
    setState(() {
      for (var item in _items) {
        if (item is SelectableOption) {
          item.isOptionSelected = false;
        }
      }
      option.isOptionSelected = true;
    });
    widget.onOptionTap?.call(option);
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).extension<OptionTileTheme>()?.useDarkImage ?? false;

    Color titleColor =
        isLightMode ? Theme.of(context).appBarTheme.titleTextStyle!.color! : Colors.white;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          children: _items.map((item) {
            if (item is OptionTitle) {
              return Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: titleColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
              );
            } else if (item is SelectableOption) {
              return Padding(
                padding: widget.tilePadding ?? const EdgeInsets.only(top: 24),
                child: ProviderOptionTile(
                  title: item.title,
                  lightImagePath: item.lightIconPath,
                  darkImagePath: item.darkIconPath,
                  imageHeight: widget.imageHeight,
                  imageWidth: widget.imageWidth,
                  padding: widget.innerPadding,
                  description: item.description,
                  topLeftSubTitle: item.topLeftSubTitle,
                  topRightSubTitle: item.topRightSubTitle,
                  rightSubTitleLightIconPath: item.topRightSubTitleLightIconPath,
                  rightSubTitleDarkIconPath: item.topRightSubTitleDarkIconPath,
                  bottomLeftSubTitle: item.bottomLeftSubTitle,
                  badges: item.badges,
                  isSelected: item.isOptionSelected,
                  borderRadius: widget.tileBorderRadius,
                  isLightMode: isLightMode,
                  onPressed: () => _handleOptionTap(item),
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }
}
