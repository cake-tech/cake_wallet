import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/multi_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/single_network_currency_picker.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key, required this.args});

  final CurrencyPickerArgs args;

  static Future<void> show({
    required BuildContext context,
    required CurrencyPickerArgs args,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyPickerSheet(args: args),
    );
  }

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
                title: S.of(context).select_asset,
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: args.useSingleNetworkLayout
                    ? SingleNetworkCurrencyPicker(args: args)
                    : MultiNetworkCurrencyPicker(args: args),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
