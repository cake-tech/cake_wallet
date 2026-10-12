import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_preset_icons.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_emoji_picker_sheet.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/wallet_icon_preview_circle_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_background_color_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

// TODO(serhii): localize strings
const _titleText = "Select Icon";
const _doneText = "Done";
const _cryptoSectionTitle = "Cryptocurrencies";
const _presetSectionTitle = "Icons";

class OmniChainSelectIconSheet extends StatefulWidget {
  const OmniChainSelectIconSheet({
    required this.cryptoTypes,
    super.key,
    this.initial,
  });

  final List<WalletType> cryptoTypes;
  final WalletIcon? initial;

  static Future<WalletIcon?> show(
    BuildContext context, {
    required List<WalletType> cryptoTypes,
    WalletIcon? initial,
  }) =>
      showCupertinoModalBottomSheet<WalletIcon>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => Material(
          child: OmniChainSelectIconSheet(cryptoTypes: cryptoTypes, initial: initial),
        ),
      );

  @override
  State<OmniChainSelectIconSheet> createState() => _OmniChainSelectIconSheetState();
}

class _OmniChainSelectIconSheetState extends State<OmniChainSelectIconSheet> {
  static const _previewSize = 100.0;
  static const _sheetHeightFactor = 0.85;

  late final List<_SelectableIcon> _cryptoOptions;
  late final List<_SelectableIcon> _presetOptions;

  _SelectableIcon? _selected;
  late int _selectedColorIndex;
  late bool _isBackgroundEnabled;

  @override
  void initState() {
    super.initState();

    _cryptoOptions = widget.cryptoTypes.map(_SelectableIcon.crypto).toList(growable: false);
    _presetOptions = WalletPresetIcons.all.map(_SelectableIcon.preset).toList(growable: false);

    final initial = widget.initial;
    _selectedColorIndex = initial?.colorIndex ?? 0;
    _isBackgroundEnabled = initial?.backgroundEnabled ?? false;
    _selected = initial == null ? null : _findOption(initial.type, initial.value);
  }

  _SelectableIcon? _findOption(WalletIconType type, String value) {
    for (final option in [..._cryptoOptions, ..._presetOptions]) {
      if (option.matches(type, value)) return option;
    }
    return null;
  }

  void _select(_SelectableIcon option) => setState(() => _selected = option);

  void _onDone(int colorIndex) {
    final selected = _selected;
    if (selected == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      WalletIcon(
        type: selected.type,
        value: selected.value,
        colorIndex: colorIndex,
        backgroundEnabled: _isBackgroundEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    final colorIndex = _selectedColorIndex.clamp(0, colors.length - 1);
    final selected = _selected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * _sheetHeightFactor,
        child: Column(
          children: [
            ModalTopBar(
              title: _titleText,
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () => Navigator.of(context).pop(),
              trailingIcon: const Icon(Icons.check),
              trailingSemanticLabel: _doneText,
              onTrailingPressed: () => _onDone(colorIndex),
            ),
            const SizedBox(height: 24),
            WalletIconPreviewCircle(
              size: _previewSize,
              background: _isBackgroundEnabled ? colors[colorIndex] : null,
              icon: selected == null
                  ? null
                  : WalletIcon(
                      type: selected.type,
                      value: selected.value,
                      colorIndex: colorIndex,
                      backgroundEnabled: _isBackgroundEnabled,
                    ),
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
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewPaddingOf(context).bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconSelectionSection(
                      title: _cryptoSectionTitle,
                      options: _cryptoOptions,
                      selected: selected,
                      onSelected: _select,
                    ),
                    if (_cryptoOptions.isNotEmpty && _presetOptions.isNotEmpty)
                      const SizedBox(height: 24),
                    _IconSelectionSection(
                      title: _presetSectionTitle,
                      options: _presetOptions,
                      selected: selected,
                      onSelected: _select,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableIcon {
  const _SelectableIcon({
    required this.type,
    required this.value,
    required this.assetPath,
    required this.label,
  });

  factory _SelectableIcon.crypto(WalletType walletType) => _SelectableIcon(
        type: WalletIconType.crypto,
        value: walletType.name,
        assetPath: getCryptoCurrencyIconForWalletListItem(walletType),
        label: walletTypeToDisplayName(walletType),
      );

  factory _SelectableIcon.preset(WalletPresetIconDefinition preset) => _SelectableIcon(
        type: WalletIconType.preset,
        value: preset.value,
        assetPath: preset.assetPath,
        label: preset.label,
      );

  final WalletIconType type;
  final String value;
  final String assetPath;
  final String label;


  bool matches(WalletIconType otherType, String otherValue) =>
      type == otherType && value == otherValue;
}

class _IconSelectionSection extends StatelessWidget {
  const _IconSelectionSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  static const _spacing = 12.0;

  final String title;
  final List<_SelectableIcon> options;
  final _SelectableIcon? selected;
  final ValueChanged<_SelectableIcon> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final current = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: _spacing),
        Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final option in options)
              _IconOption(
                option: option,
                isSelected: current != null && option.matches(current.type, current.value),
                onTap: () => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.option, required this.isSelected, required this.onTap});

  static const _size = 48.0;
  static const _padding = 10.0;

  final _SelectableIcon option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: _size,
            height: _size,
            padding: const EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: scheme.primary, width: 2) : null,
            ),
            child: CakeImageWidget(imageUrl: option.assetPath),
          ),
        ),
      ),
    );
  }
}
