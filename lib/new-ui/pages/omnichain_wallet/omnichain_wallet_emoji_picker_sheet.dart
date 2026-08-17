import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/select_background_color_widget.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';


class OmniChainWalletEmojiPickerSheet extends StatefulWidget {
  const OmniChainWalletEmojiPickerSheet({
    super.key,
    this.initialEmoji,
    this.initialColorIndex = 0,
  });

  final String? initialEmoji;
  final int initialColorIndex;

  static List<Gradient> backgroundColors(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return [
      LinearGradient(colors: [surface, surface]),                            // default (theme)
      const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF7A00)]),  // orange
      const LinearGradient(colors: [Color(0xFFFFC400), Color(0xFFFFC400)]),  // yellow
      const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF34C759)]),  // green
      const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF3B82F6)]),  // blue
      const LinearGradient(colors: [Color(0xFF9B5CF6), Color(0xFF9B5CF6)]),  // purple
      const LinearGradient(colors: [Color(0xFFFF3E9D), Color(0xFFFF3E9D)]),  // pink
      const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF3B30)]),  // red
      const LinearGradient(colors: [Color(0xFFC7A008), Color(0xFFC7A008)]),  // gold
    ];
  }

  static Future<OmniChainWalletEmojiPickerSheet?> show(
      BuildContext context, {
        String? initialEmoji,
        int initialColorIndex = 0,
      }) =>
      showCupertinoModalBottomSheet<OmniChainWalletEmojiPickerSheet>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => Material(
          child: OmniChainWalletEmojiPickerSheet(
            initialEmoji: initialEmoji,
            initialColorIndex: initialColorIndex,
          ),
        ),
      );

  @override
  State<OmniChainWalletEmojiPickerSheet> createState() =>
      _OmniChainWalletEmojiPickerSheetState();
}

class _OmniChainWalletEmojiPickerSheetState
    extends State<OmniChainWalletEmojiPickerSheet> {
  static const _icons = <String>[
    "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣",
    "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰",
    "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜",
    "🤪", "🤨", "🧐", "🤓", "😎", "🥸", "🤩", "🥳",
    "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️",
    "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤",
    "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱",
    "🤗", "🤔", "🫣", "🤭", "🤫", "🤥", "😶", "😐",
    "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮",
    "🤠", "😈", "👿", "👻", "💀", "👽", "🤖", "🎃",
    "🐶", "🐱", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁",
    "🐸", "🐙", "🦄", "🐝", "🦋", "🌈", "⭐", "🌙",
    "🔥", "💎", "🚀", "🎯", "🎮", "🎲", "💰", "🪙",
  ];

  late String _selectedIcon;
  late int _selectedColorIndex;

  @override
  void initState() {
    super.initState();

    _selectedIcon =
    widget.initialEmoji != null && _icons.contains(widget.initialEmoji)
        ? widget.initialEmoji!
        : _icons.first;

    _selectedColorIndex = widget.initialColorIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = OmniChainWalletEmojiPickerSheet.backgroundColors(context);
    // guard against an out-of-range stored index
    final colorIndex =
    _selectedColorIndex.clamp(0, colors.length - 1);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          ModalTopBar(
            title: "Select Icon",
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 24),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors[colorIndex],
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
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final icon = _icons[index];
                final selected = icon == _selectedIcon;
                return Material(
                  color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}