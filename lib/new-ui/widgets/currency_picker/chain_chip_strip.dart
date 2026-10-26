import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class ChainChipStrip extends StatelessWidget {
  const ChainChipStrip({
    super.key,
    required this.walletTypes,
    required this.selected,
    required this.onSelected,
  });

  final List<WalletType> walletTypes;
  final WalletType? selected;
  final ValueChanged<WalletType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        children: [
          ChainChip(
            label: S.of(context).picker_chip_all,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final type in walletTypes)
            ChainChip(
              label: walletTypeToString(type),
              isSelected: selected == type,
              onTap: () => onSelected(type),
            ),
        ],
      ),
    );
  }
}

class ChainChip extends StatelessWidget {
  const ChainChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconPath,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          selected: isSelected,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(80),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    if (iconPath != null)
                      CakeImageWidget(imageUrl: iconPath, width: 16, height: 16),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: isSelected ? 14 : 12,
                            letterSpacing: -0.07,
                            color: isSelected ? colors.onPrimary : colors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
