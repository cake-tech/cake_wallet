import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_emoji_picker_sheet.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_wallet_select_icon_sheet.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class WalletIconEditor extends StatelessWidget {
  const WalletIconEditor({
    required this.icon,
    required this.onChanged,
    this.cryptoTypes = const [],
    this.size,
    this.emojiOnly = false,
    super.key,
  });

  static const double _defaultSize = 100;
  static const double _defaultContentSize = 80;

  final WalletIcon? icon;
  final ValueChanged<WalletIcon> onChanged;
  final List<WalletType> cryptoTypes;
  final double? size;
  final bool emojiOnly;

  bool get _isDefaultIcon {
    final current = icon;
    if (current == null) return true;
    const defaults = WalletIcon.defaultIcon;
    return current.type == defaults.type &&
        current.value == defaults.value &&
        current.colorIndex == defaults.colorIndex &&
        current.backgroundEnabled == defaults.backgroundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? _defaultSize;
    final contentSize = _defaultContentSize * avatarSize / _defaultSize;
    final avatar = icon == null
        ? SizedBox(width: avatarSize, height: avatarSize)
        : WalletIconAvatar(
            icon: icon,
            size: avatarSize,
            contentSize: contentSize,
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100),
          );

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            child: avatar,
          ),
          Positioned(
            right: -2,
            bottom: 4,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final WalletIcon? selection = emojiOnly
                      ? await OmniChainWalletEmojiPickerSheet.show(context, initial: icon)
                      : await OmniChainWalletIconPickerSheet.show(
                    context,
                    initial: icon,
                    cryptoTypes: cryptoTypes,
                  );

                  if (selection != null && context.mounted) {
                    onChanged(selection);
                  }
                },
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _isDefaultIcon ? Icons.add : Icons.edit_outlined,
                    size: _isDefaultIcon ? 22 : 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
