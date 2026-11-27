import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/currencies/swap_currency_cubit.dart";
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_footer.dart";
import 'package:cake_wallet/new-ui/widgets/currency_picker/multi_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/single_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:flutter/material.dart';

class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key, required this.args}) : _isOtherAssetsPage = false;

  const CurrencyPickerSheet._otherAssetsPage({required this.args}) : _isOtherAssetsPage = true;

  final CurrencyPickerArgs args;
  final bool _isOtherAssetsPage;

  static Future<void> show({
    required BuildContext context,
    required CurrencyPickerArgs args,
  }) => showModalBottomSheet<CryptoCurrency>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => args.otherAssets != null && args.useSingleNetworkLayout
          ? ModalNavigator(
              parentContext: sheetContext,
              rootPage: CurrencyPickerSheet(args: args),
            )
          : CurrencyPickerSheet(args: args),
    );

  Future<void> _showOtherAssets(BuildContext context, CurrencyPickerArgs otherAssets) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await Navigator.of(context).push(
      CupertinoPageRoute<CryptoCurrency>(
        builder: (_) => CurrencyPickerSheet._otherAssetsPage(args: otherAssets),
      ),
    );

    if (picked != null && context.mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  Widget _picker(BuildContext context, CurrencyPickerArgs args) => args.useSingleNetworkLayout
      ? SingleNetworkCurrencyPicker(
          args: args,
          onSendAnotherAsset: switch (args.otherAssets) {
            final otherAssets? => () => _showOtherAssets(context, otherAssets),
            null => null,
          },
        )
      : MultiNetworkCurrencyPicker(args: args);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: colors.surface,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ModalTopBar(
                testId: "currency_picker_sheet_top_bar",
                title: S.of(context).select_asset,
                leadingIcon: Icon(_isOtherAssetsPage ? Icons.arrow_back_ios_new : Icons.close),
                leadingSemanticLabel:
                    _isOtherAssetsPage ? S.of(context).seed_alert_back : S.of(context).close,
                onLeadingPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: switch (args.currencyCubit) {
                  final cubit? => BlocBuilder<SwapCurrencyCubit, SwapCurrencyState>(
                    bloc: cubit,
                    builder: (context, state) => Stack(
                      children: [
                        Positioned.fill(child: _picker(context, args.withItems(cubit.currencies))),
                        if (state is SwapCurrenciesRefreshing)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: CurrencyPickerFooter.heightFor(
                                  hasAction: args.useSingleNetworkLayout && args.otherAssets != null,
                                ) +
                                8,
                            child: const Center(child: _LoadingCurrenciesPill()),
                          ),
                      ],
                    ),
                  ),
                  null => _picker(context, args),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCurrenciesPill extends StatelessWidget {
  const _LoadingCurrenciesPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(80),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CupertinoActivityIndicator(radius: 8),
        const SizedBox(width: 8),
        Text(
          S.of(context).loading_currencies,
          style: TextStyle(fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}
