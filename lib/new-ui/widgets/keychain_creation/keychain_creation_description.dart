import "dart:io";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class KeychainCreationDescriptionWidget extends StatelessWidget {
  const KeychainCreationDescriptionWidget({
    required this.imagePath,
    required this.spans,
    super.key,
  });

  final String imagePath;
  final List<TextSpan> spans;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 40,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CakeImageWidget(
            imageUrl: imagePath,
            width: 200,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: const TextStyle(fontSize: 16, fontFamily: "Wix Madefor Text"),
                  children: spans),
            ),
          ),
        ],
      );
}

class KeychainCreationDescriptionModal extends StatefulWidget {
  const KeychainCreationDescriptionModal({super.key});

  String get keychainName => Platform.isAndroid ? "Keystore" : "Keychain";

  String get cloudServiceName => Platform.isAndroid ? S.current.google_drive : "iCloud Drive";

  @override
  State<KeychainCreationDescriptionModal> createState() => _KeychainCreationDescriptionModalState();
}

class _KeychainCreationDescriptionModalState extends State<KeychainCreationDescriptionModal> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).recovery_method,
              trailingIcon: const Icon(Icons.close),
              trailingSemanticLabel: S.of(context).close,
              onTrailingPressed: Navigator.of(context).pop,
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  KeychainCreationDescriptionWidget(
                    imagePath: "assets/new-ui/seedphrase_box.svg",
                    spans: [
                      TextSpan(
                        text:
                        "${S.of(context).keychain_option_desc_1(widget.keychainName, widget.cloudServiceName)}.\n\n",
                      ),
                      TextSpan(text: "${S.of(context).keychain_option_desc_2}\n\n"),
                      TextSpan(text: S.of(context).keychain_option_desc_3),
                    ],
                  ),
                  KeychainCreationDescriptionWidget(
                    imagePath: "assets/new-ui/seedphrase_manual_save.svg",
                    spans: [
                      TextSpan(
                          text:
                          "${S.of(context).seed_phrase_option_desc_1(widget.keychainName)}\n\n"),
                      TextSpan(text: S.of(context).seed_phrase_option_desc_2),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: NewPrimaryButton(
                onPressed: () {
                  if (_currentPage == 0) {
                    _controller.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                text: _currentPage == 0
                    ? S.of(context).continue_text
                    : S.of(context).close,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          ],
        ),
      ),
    ),
  );
}
