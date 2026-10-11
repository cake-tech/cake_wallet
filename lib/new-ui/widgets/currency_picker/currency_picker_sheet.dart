import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/modal_navigator.dart";
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/multi_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/single_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final otherAssets = args.otherAssets;
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
                title: S.of(context).select_asset,
                leadingIcon: Icon(_isOtherAssetsPage ? Icons.arrow_back_ios_new : Icons.close),
                leadingSemanticLabel:
                    _isOtherAssetsPage ? S.of(context).seed_alert_back : S.of(context).close,
                onLeadingPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: args.useSingleNetworkLayout
                    ? SingleNetworkCurrencyPicker(
                        args: args,
                        onSendAnotherAsset: otherAssets == null
                            ? null
                            : () => _showOtherAssets(context, otherAssets),
                      )
                    : MultiNetworkCurrencyPicker(args: args),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
