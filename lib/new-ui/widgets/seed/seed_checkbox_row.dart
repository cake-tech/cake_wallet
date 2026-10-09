import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart";
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
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          checked: isChecked,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!isChecked),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
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
                      colorFilter:
                          ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.06,
                          ),
                    ),
                  ),
                  NewSimpleCheckbox(value: isChecked, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      );
}
