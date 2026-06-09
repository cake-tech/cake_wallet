import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:flutter/material.dart';

class MoneroHardwareWalletPassphraseInputModal extends StatefulWidget {
  const MoneroHardwareWalletPassphraseInputModal({super.key});

  @override
  State<MoneroHardwareWalletPassphraseInputModal> createState() =>
      _MoneroHardwareWalletPassphraseInputModalState();
}

class _MoneroHardwareWalletPassphraseInputModalState
    extends State<MoneroHardwareWalletPassphraseInputModal> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            color: Theme.of(context).colorScheme.surface),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).passphrase_entry,
                leadingIcon: Icon(Icons.close),
                onLeadingPressed: Navigator.of(context).pop,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0),
                child: Expanded(
                  child: Column(
                    spacing: 12,
                    children: [
                      BaseTextFormField(
                        controller: controller,
                        hintText: S.of(context).passphrase_raw,
                      ),
                      SizedBox(),
                      NewPrimaryButton(
                          onPressed: () {},
                          text: S.of(context).restore_next,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary),
                      SizedBox()
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
