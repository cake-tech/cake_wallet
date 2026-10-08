import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_background_color_widget.dart";
import "package:cw_core/card_design.dart";
import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/foundation.dart" as foundation;
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
  static const _pickerHeight = 500.0;

  late String _selectedIcon;
  late int _selectedColorIndex;
  late bool _isBackgroundEnabled;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    _selectedIcon = (initial?.type == WalletIconType.emoji ? initial?.value : null) ?? _defaultIcon;
    _selectedColorIndex = initial?.colorIndex ?? 0;
    _isBackgroundEnabled = initial?.backgroundEnabled ?? false;
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    setState(() => _selectedIcon = emoji.emoji);
  }

  Widget _buildEmojiPicker(ThemeData theme) {
    final scheme = theme.colorScheme;
    final pickerBackground = scheme.surfaceContainerHigh;

    return EmojiPicker(
      onEmojiSelected: _onEmojiSelected,
      config: Config(
        height: _pickerHeight,
        checkPlatformCompatibility: true,
        viewOrderConfig: const ViewOrderConfig(
          top: EmojiPickerItem.searchBar,
          middle: EmojiPickerItem.emojiView,
          bottom: EmojiPickerItem.categoryBar,
        ),
        emojiViewConfig: EmojiViewConfig(
          columns: 8,
          emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          backgroundColor: pickerBackground,
          noRecents: Text(
            "No recents",
            style: TextStyle(fontSize: 20, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        categoryViewConfig: CategoryViewConfig(
          initCategory: Category.SMILEYS,
          backgroundColor: pickerBackground,
          indicatorColor: scheme.primary,
          iconColor: scheme.onSurfaceVariant,
          iconColorSelected: scheme.primary,
        ),
        searchViewConfig: SearchViewConfig(
          backgroundColor: pickerBackground,
          buttonIconColor: scheme.onSurfaceVariant,
          hintText: "Search Emoji",
        ),
        skinToneConfig: SkinToneConfig(
          dialogBackgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
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
              border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: _buildEmojiPicker(theme),
          ),
        ],
      ),
    );
  }
}
