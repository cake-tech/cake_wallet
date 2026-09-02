import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:flutter/material.dart";

class CurrencyPickerFooter extends StatelessWidget {
  const CurrencyPickerFooter({
    required this.searchController,
    this.action,
    super.key,
  });

  final TextEditingController searchController;
  final Widget? action;

  static const double _actionHeight = 55;
  static const double _actionGap = 16;

  static const double _searchHeight = 60;
  static const double _bottomMargin = 24;

  static const double _fadeHeightWithAction = 200;
  static const double _fadeHeight = 125;

  static double heightFor({required bool hasAction}) =>
      (hasAction ? _actionHeight + _actionGap : 0) + _searchHeight + _bottomMargin;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IgnorePointer(
            child: Container(
              height: action == null ? _fadeHeight : _fadeHeightWithAction,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surfaceDim.withAlpha(0),
                    Theme.of(context).colorScheme.surfaceDim,
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (action != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(height: _actionHeight, child: action),
                ),
                const SizedBox(height: _actionGap),
              ],
              CurrencyPickerSearchField(
                controller: searchController,
                hintText: S.of(context).search,
              ),
              const SizedBox(height: _bottomMargin),
            ],
          ),
        ],
      ),
    );
  }
}
