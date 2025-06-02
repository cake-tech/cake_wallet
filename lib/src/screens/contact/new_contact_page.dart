import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/contact/edit_contact_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class EditNewContactGroupPage extends BasePage {
  EditNewContactGroupPage({
    required this.fillColor,
    required this.selectedParsedAddress,
    this.singleActionButtonText,
    this.singleActionButtonKey,
  });

  final Color fillColor;
  final ParsedAddress selectedParsedAddress;
  final String? singleActionButtonText;
  final Key? singleActionButtonKey;

  @override
  String? get title => 'New Contact';

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                'Contact info auto-detected from ${selectedParsedAddress.addressSource.label}',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                        child: Column(
                          children: [
                            ImageUtil.getImageFromPath(
                              imagePath: selectedParsedAddress.profileImageUrl,
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(height: 1),
                            Text('Icon',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Address group name',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              selectedParsedAddress.profileName,
                              style:
                              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
            child: LoadingPrimaryButton(
              key: singleActionButtonKey,
              text: singleActionButtonText ?? '',
              onPressed: () {
                Navigator.of(context).push(
                  _slideLeft(
                    EditNewContactPage(
                      selectedParsedAddress: selectedParsedAddress,
                    ),
                  ),
                );
              },
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              isLoading: false,
              isDisabled: false,
            ),
          )
        ],
      ),
    );
  }
}

Route<Object?> _slideLeft(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
  );
}