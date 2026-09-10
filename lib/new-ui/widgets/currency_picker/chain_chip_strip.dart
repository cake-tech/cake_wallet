import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

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
          _ChainChip(
            label: S.of(context).picker_chip_all,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final type in walletTypes)
            _ChainChip(
              label: walletTypeToString(type),
              isSelected: selected == type,
              onTap: () => onSelected(type),
            ),
        ],
      ),
    );
  }
}

class _ChainChip extends StatelessWidget {
  const _ChainChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

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
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: isSelected ? 14 : 12,
                        letterSpacing: -0.07,
                        color: isSelected ? colors.onPrimary : colors.primary,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
