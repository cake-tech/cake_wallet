import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:flutter/material.dart";

class MoneroHardwareWalletPassphraseInputModal extends StatelessWidget {
  const MoneroHardwareWalletPassphraseInputModal({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalTopBar(
                  title: S.of(context).passphrase_entry,
                  leadingIcon: const Icon(Icons.close),
                  leadingSemanticLabel: S.of(context).close,
                  onLeadingPressed: Navigator.of(context).pop,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 12,
                    children: [
                      BaseTextFormField(
                        controller: controller,
                        hintText: S.of(context).passphrase_raw,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(),
                      NewPrimaryButton(
                        onPressed: Navigator.of(context).pop,
                        text: S.of(context).restore_next,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
