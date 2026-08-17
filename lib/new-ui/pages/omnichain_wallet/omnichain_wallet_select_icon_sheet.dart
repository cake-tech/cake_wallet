import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_emoji_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class OmniChainEmojiPicker {
  const OmniChainEmojiPicker({
    required this.emoji,
    required this.colorIndex,
  });

  final String emoji;
  final int colorIndex;
}

class OmniChainWalletIconPickerSheet extends StatefulWidget {
  const OmniChainWalletIconPickerSheet({
    super.key,
    this.initialEmoji,
    this.initialColorIndex = 0,
  });

  final String? initialEmoji;
  final int initialColorIndex;

  static Future<OmniChainEmojiPicker?> show(
      BuildContext context, {
        String? initialEmoji,
        int initialColorIndex = 0,
      }) =>
      showCupertinoModalBottomSheet<OmniChainEmojiPicker>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => Material(
          child: OmniChainWalletIconPickerSheet(
            initialEmoji: initialEmoji,
            initialColorIndex: initialColorIndex,
          ),
        ),
      );

  @override
  State<OmniChainWalletIconPickerSheet> createState() => _OmniChainWalletIconPickerSheetState();
}

class _OmniChainWalletIconPickerSheetState extends State<OmniChainWalletIconPickerSheet> {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.35,
        child: Column(
          children: [
            ModalTopBar(
              title: "Select Icon",
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NewListSections(
                  sections: {
                    "": [
                      ListItemRegularRow(
                        iconPath: "😀",
                        keyValue: "omnichain_icon_picker_emoji_row_key",
                        label: "Emoji",
                        onTap: () async {
                          final selection = await OmniChainWalletEmojiPickerSheet.show(
                            context,
                            initialEmoji: widget.initialEmoji,
                            initialColorIndex: widget.initialColorIndex,
                          );

                          if (selection != null && context.mounted) {
                            Navigator.of(context).pop(selection);
                          }
                        },
                      ),
                      ListItemRegularRow(
                          iconPath: "assets/new-ui/favorite_icon.svg",
                          keyValue: "omnichain_icon_picker_icon_row_key",
                          label: "Icon",
                          onTap: () {}),
                      ListItemRegularRow(
                          iconPath: "assets/new-ui/select_image_icon.svg",
                          keyValue: "omnichain_icon_picker_selected_image_row_key",
                          label: "Selected Image",
                          onTap: () {}),
                      ListItemRegularRow(
                          iconPath: "assets/new-ui/take_photo_icon.svg",
                          keyValue: "omnichain_icon_picker_take_photo_row_key",
                          label: "Take Photo",
                          onTap: () {}),
                    ],
                  },
                ),
              ),
            ),
          ],
        ),
      );
}
