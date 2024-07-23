import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

class SelectOptionsPage<T extends SelectableOption> extends BasePage {
  SelectOptionsPage({
    required this.title,
    required this.options,
    required this.onOptionTap,
  });

  final String title;
  final List<T> options;
  final void Function(T option)? onOptionTap;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      content: BodySelectOptionsPage<T>(
        options: options,
        onOptionTap: onOptionTap,
      ),
      bottomSection: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text(
          '',
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
    required this.onOptionTap,
  });

  final List<T> options;
  final void Function(T option)? onOptionTap;

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
        constraints: BoxConstraints(maxWidth: 330),
        child: Column(
          children: [
            ..._options
                .map((option) => Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      imagePath: option.iconPath,
                      title: option.title.toString(),
                      leftSubTitle: option.leftSubTitle,
                      rightSubTitle: option.rightSubTitle,
                      description: option.description,
                      firstBadgeName: option.firstBadgeName,
                      secondBadgeName: option.secondBadgeName,
                      isSelected: option.isOptionSelected,
                      isLightMode: isLightMode,
                      borderRadius: option.borderRadius,
                      onPressed: () => _handleOptionTap(option),
                    )))
                .toList(),
          ],
        ),
      ),
    );
  }
}
