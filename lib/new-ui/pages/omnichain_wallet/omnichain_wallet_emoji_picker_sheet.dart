import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_background_color_widget.dart";
import "package:cw_core/card_design.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class OmniChainWalletEmojiPickerSheet extends StatefulWidget {
  const OmniChainWalletEmojiPickerSheet({
    super.key,
    this.initial,
  });

  final WalletIcon? initial;

  static List<Gradient> backgroundColors(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return [
      LinearGradient(colors: [surface, surface]), // default (theme)
      ...CardDesign.allGradients,
    ];
  }

  static Future<WalletIcon?> show(
    BuildContext context, {
    WalletIcon? initial,
  }) =>
      showCupertinoModalBottomSheet<WalletIcon>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => Material(
          child: OmniChainWalletEmojiPickerSheet(initial: initial),
        ),
      );

  @override
  State<OmniChainWalletEmojiPickerSheet> createState() => _OmniChainWalletEmojiPickerSheetState();
}

class _OmniChainWalletEmojiPickerSheetState extends State<OmniChainWalletEmojiPickerSheet> {
  static const _defaultIcon = "";

  late String _selectedIcon;
  late int _selectedColorIndex;
  late bool _isBackgroundEnabled;
  late final TextEditingController _emojiController;
  final FocusNode _emojiFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    _selectedIcon = (initial?.type == WalletIconType.emoji ? initial?.value : null) ?? _defaultIcon;
    _selectedColorIndex = initial?.colorIndex ?? 0;
    _isBackgroundEnabled = initial?.backgroundEnabled ?? true;
    _emojiController = TextEditingController();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    super.dispose();
  }

  void _onEmojiInput(String value) {
    if (value.isEmpty) return;
    final lastChar = value.characters.last;
    setState(() => _selectedIcon = lastChar);
    _emojiController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    // guard against an out-of-range stored index
    final colorIndex = _selectedColorIndex.clamp(0, colors.length - 1);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: "Select Icon",
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: () => Navigator.of(context).pop(),
            trailingIcon: const Icon(Icons.check),
            trailingSemanticLabel: "Done",
            onTrailingPressed: () => Navigator.of(context).pop(
              WalletIcon(
                type: WalletIconType.emoji,
                value: _selectedIcon,
                colorIndex: colorIndex,
                backgroundEnabled: _isBackgroundEnabled,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isBackgroundEnabled ? colors[colorIndex] : null,
              color: _isBackgroundEnabled ? null : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(_selectedIcon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SelectBackgroundColorWidget(
              colors: colors,
              selectedIndex: colorIndex,
              onColorSelected: (index) => setState(() => _selectedColorIndex = index),
              isToggleable: true,
              isEnabled: _isBackgroundEnabled,
              onToggleChanged: (value) => setState(() => _isBackgroundEnabled = value),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _emojiController,
              focusNode: _emojiFocusNode,
              autofocus: true,
              showCursor: false,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
              onChanged: _onEmojiInput,
              decoration: InputDecoration(
                hintText: "Tap to choose an emoji",
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
