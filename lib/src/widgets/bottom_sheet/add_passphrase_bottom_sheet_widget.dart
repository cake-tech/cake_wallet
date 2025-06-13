import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class AddPassphraseBottomSheet extends StatefulWidget {
  AddPassphraseBottomSheet({
    required String titleText,
    required this.currentTheme,
    required this.onRestoreButtonPressed,
  });

  final void Function(String) onRestoreButtonPressed;
  final MaterialThemeBase currentTheme;

  @override
  State<AddPassphraseBottomSheet> createState() => _AddPassphraseBottomSheetState();
}

class _AddPassphraseBottomSheetState extends State<AddPassphraseBottomSheet> {
  late final TextEditingController passphraseController;
  late final TextEditingController confirmPassphraseController;

  @override
  void initState() {
    super.initState();
    passphraseController = TextEditingController();
    confirmPassphraseController = TextEditingController();
  }

  @override
  void dispose() {
    passphraseController.dispose();
    confirmPassphraseController.dispose();
    super.dispose();
  }

  final passphraseImageLight = 'assets/images/passphrase_light.png';
  final passphraseImageDark = 'assets/images/passphrase_dark.png';

  bool obscurePassphrase = true;
  @override
  Widget build(BuildContext context) {

    final passphraseImage = widget.currentTheme.isDark ? passphraseImageDark : passphraseImageLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(flex: 4),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
            SizedBox(height: 16),
            Text(
              S.of(context).add_passphrase,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
            ),
            SizedBox(height: 20),
            CakeImageWidget(imageUrl: passphraseImage, height: 85),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${S.of(context).warning.toUpperCase()}: ',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.errorContainer,
                            decoration: TextDecoration.none,
                          ),
                    ),
                    TextSpan(
                      text: S.of(context).add_passphrase_warning_text,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      decoration: TextDecoration.none,
                    ),
              ),
            ),
            SizedBox(height: 24),
            BaseTextFormField(
              key: ValueKey('add_passphrase_bottom_sheet_widget_passphrase_textfield_key'),
              controller: passphraseController,
              obscureText: obscurePassphrase,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              hintText: S.of(context).required_passphrase,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    obscurePassphrase = !obscurePassphrase;
                  });
                },
                child: Icon(
                  obscurePassphrase ? Icons.visibility_off : Icons.visibility,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            SizedBox(height: 8),
            BaseTextFormField(
              key: ValueKey('add_passphrase_bottom_sheet_widget_confirm_passphrase_textfield_key'),
              controller: confirmPassphraseController,
              obscureText: obscurePassphrase,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              hintText: S.of(context).confirm_passphrase,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    obscurePassphrase = !obscurePassphrase;
                  });
                },
                child: Icon(
                  obscurePassphrase ? Icons.visibility_off : Icons.visibility,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              validator: (text) {
                if (text == passphraseController.text) {
                  return null;
                }

                return S.of(context).passphrases_doesnt_match;
              },
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                      child: PrimaryButton(
                        key: ValueKey('add_passphrase_bottom_sheet_widget_cancel_button_key'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        text: S.of(context).cancel,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        textColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: PrimaryButton(
                        key: ValueKey('add_passphrase_bottom_sheet_widget_restore_button_key'),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRestoreButtonPressed(passphraseController.text);
                        },
                        text: S.of(context).restore,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
