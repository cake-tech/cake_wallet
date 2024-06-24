import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

class SelectOptionsPage<T extends SelectableOption> extends BasePage {
  SelectOptionsPage({required this.title, required this.options, required this.onOptionTap});

  final String title;
  final List<T> options;
  final void Function(T option)? onOptionTap;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    final isLightMode = Theme.of(context).extension<OptionTileTheme>()?.useDarkImage ?? false;

    return ScrollableWithBottomSection(
      content: Container(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 330),
            child: Column(
              children: [
                ...options.map((option) {
                  final icon = Image.asset(
                    option.iconPath,
                    height: 40,
                    width: 40,
                  );

                  return Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      image: icon,
                      title: option.title.toString(),
                      description: option.description ?? '',
                      onPressed: () => onOptionTap?.call(option),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      bottomSection: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text(
          'S.of(context).select_provider_notice',
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
