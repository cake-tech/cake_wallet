import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/multi_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/single_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({super.key, required this.args});

  final CurrencyPickerArgs args;

  static Future<void> show({
    required BuildContext context,
    required CurrencyPickerArgs args,
  }) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyPickerSheet(args: args),
    );

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  bool _showingOtherAssets = false;

  void _showOtherAssets(bool show) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showingOtherAssets = show);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final args = widget.args;
    final otherAssets = args.otherAssets;
    final showingOtherAssets = otherAssets != null && _showingOtherAssets;

    final primaryPicker = args.useSingleNetworkLayout
        ? SingleNetworkCurrencyPicker(
            args: args,
            onSendAnotherAsset: otherAssets == null ? null : () => _showOtherAssets(true),
          )
        : MultiNetworkCurrencyPicker(args: args);

    return PopScope(
      canPop: !showingOtherAssets,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showOtherAssets(false);
        }
      },
      child: Padding(
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
                  leadingIcon: Icon(showingOtherAssets ? Icons.arrow_back_ios_new : Icons.close),
                  leadingSemanticLabel:
                      showingOtherAssets ? S.of(context).seed_alert_back : S.of(context).close,
                  onLeadingPressed: showingOtherAssets
                      ? () => _showOtherAssets(false)
                      : () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: otherAssets == null
                      ? primaryPicker
                      : IndexedStack(
                          index: showingOtherAssets ? 1 : 0,
                          sizing: StackFit.expand,
                          children: [
                            primaryPicker,
                            MultiNetworkCurrencyPicker(args: otherAssets),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
