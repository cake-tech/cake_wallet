import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class SeedCheckboxRow extends StatelessWidget {
  const SeedCheckboxRow({
    required this.iconPath,
    required this.text,
    required this.isChecked,
    required this.onChanged,
    super.key,
  });

  final String iconPath;
  final String text;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MergeSemantics(
      child: Semantics(
        checked: isChecked,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!isChecked),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              spacing: 12,
              children: [
                ExcludeSemantics(
                  child: CakeImageWidget(
                    imageUrl: iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          letterSpacing: -0.06,
                        ),
                  ),
                ),
                ExcludeSemantics(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked ? colors.primary : colors.surfaceContainerHighest,
                    ),
                    child: isChecked ? Icon(Icons.check, size: 16, color: colors.onPrimary) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
