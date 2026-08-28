import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart';
import 'package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_emoji_picker_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart';
import 'package:cake_wallet/new-ui/widgets/new_elevated_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/select_background_color_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class _SelectableIcon {
  const _SelectableIcon({
    required this.type,
    required this.value,
    required this.assetPath,
    required this.label,
  });

  final WalletIconType type;
  final String value;
  final String assetPath;
  final String label;
}

class OmniChainSelectIconSheet extends StatefulWidget {
  const OmniChainSelectIconSheet({
    super.key,
    required this.cryptoTypes,
    this.initial,
  });

  /// The wallet's own selected networks — these are what populate the
  /// "Cryptocurrencies" grid. Deliberately scoped to this wallet's own
  /// networks rather than every currency the app supports, since picking an
  /// unrelated coin's logo as your wallet's icon wouldn't make much sense.
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

  static const _presetIcons = <_SelectableIcon>[
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'heart',
      assetPath: 'assets/new-ui/favorite_icon.svg',
      label: 'Heart',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'flower',
      assetPath: 'assets/new-ui/wallet_icons/flower.svg',
      label: 'Flower',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'star',
      assetPath: 'assets/new-ui/wallet_icons/star.svg',
      label: 'Star',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'cart',
      assetPath: 'assets/new-ui/wallet_icons/cart.svg',
      label: 'Cart',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'chess',
      assetPath: 'assets/new-ui/wallet_icons/chess.svg',
      label: 'Chess',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'paraglider',
      assetPath: 'assets/new-ui/wallet_icons/paraglider.svg',
      label: 'Paraglider',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'tshirt',
      assetPath: 'assets/new-ui/wallet_icons/tshirt.svg',
      label: 'T-Shirt',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'piggy_bank',
      assetPath: 'assets/new-ui/wallet_icons/piggy_bank.svg',
      label: 'Piggy Bank',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'bank',
      assetPath: 'assets/new-ui/wallet_icons/bank.svg',
      label: 'Bank',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'dice',
      assetPath: 'assets/new-ui/wallet_icons/dice.svg',
      label: 'Dice',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'motorcycle',
      assetPath: 'assets/new-ui/wallet_icons/motorcycle.svg',
      label: 'Motorcycle',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'paper_plane',
      assetPath: 'assets/new-ui/wallet_icons/paper_plane.svg',
      label: 'Paper Plane',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'infinity',
      assetPath: 'assets/new-ui/wallet_icons/infinity.svg',
      label: 'Infinity',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'shield',
      assetPath: 'assets/new-ui/wallet_icons/shield.svg',
      label: 'Shield',
    ),
    _SelectableIcon(
      type: WalletIconType.preset,
      value: 'music_notes',
      assetPath: 'assets/new-ui/wallet_icons/music_notes.svg',
      label: 'Music Notes',
    ),
  ];

  @override
  State<OmniChainSelectIconSheet> createState() => _OmniChainSelectIconSheetState();
}

class _OmniChainSelectIconSheetState extends State<OmniChainSelectIconSheet> {
  late int _selectedColorIndex;
  late bool _isBackgroundEnabled;
  WalletIconType? _selectedType;
  String? _selectedValue;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    _selectedColorIndex = initial?.colorIndex ?? 0;
    _isBackgroundEnabled = initial?.backgroundEnabled ?? true;

    if (initial != null &&
        (initial.type == WalletIconType.crypto || initial.type == WalletIconType.preset)) {
      _selectedType = initial.type;
      _selectedValue = initial.value;
    }

    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SelectableIcon> get _cryptoOptions => widget.cryptoTypes
      .map((type) => _SelectableIcon(
    type: WalletIconType.crypto,
    value: type.name,
    assetPath: getCryptoCurrencyIconForWalletListItem(type),
    label: walletTypeToDisplayName(type),
  ))
      .where((option) => _query.isEmpty || option.label.toLowerCase().contains(_query))
      .toList();

  List<_SelectableIcon> get _presetOptions => OmniChainSelectIconSheet._presetIcons
      .where((option) => _query.isEmpty || option.label.toLowerCase().contains(_query))
      .toList();

  bool get _canConfirm => _selectedType != null && _selectedValue != null;

  void _select(_SelectableIcon option) {
    setState(() {
      _selectedType = option.type;
      _selectedValue = option.value;
    });
  }

  void _confirm() {
    if (!_canConfirm) return;

    Navigator.of(context).pop(
      WalletIcon(
        type: _selectedType!,
        value: _selectedValue!,
        colorIndex: _selectedColorIndex,
        backgroundEnabled: _isBackgroundEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    final colorIndex = _selectedColorIndex.clamp(0, colors.length - 1);

    final previewIcon = _canConfirm
        ? WalletIcon(
      type: _selectedType!,
      value: _selectedValue!,
      colorIndex: colorIndex,
      backgroundEnabled: _isBackgroundEnabled,
    )
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            ModalTopBar(
              title: "Select Icon",
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            Center(child: WalletIconAvatar(icon: previewIcon)),
            const SizedBox(height: 16),
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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconSelectionGrid(
                          title: "Cryptocurrencies",
                          options: _cryptoOptions,
                          selectedValue:
                          _selectedType == WalletIconType.crypto ? _selectedValue : null,
                          onSelected: _select,
                        ),
                        const SizedBox(height: 24),
                        _IconSelectionGrid(
                          title: "Icons",
                          options: _presetOptions,
                          selectedValue:
                          _selectedType == WalletIconType.preset ? _selectedValue : null,
                          onSelected: _select,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSelectionGrid extends StatelessWidget {
  const _IconSelectionGrid({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<_SelectableIcon> options;
  final String? selectedValue;
  final ValueChanged<_SelectableIcon> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = option.value == selectedValue;

            return Material(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelected(option),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: CakeImageWidget(imageUrl: option.assetPath),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}