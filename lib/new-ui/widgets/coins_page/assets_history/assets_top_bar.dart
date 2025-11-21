import 'package:cake_wallet/new-ui/widgets/line_tab_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

class AssetsTopBar extends StatelessWidget {
  const AssetsTopBar({
    super.key,
    required this.onTabChange,
    required this.selectedTab,
  });

  final void Function(int) onTabChange;
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LineTabSwitcher(
            tabs: const ["Assets", "History"],
            onTabChange: onTabChange,
            selectedTab: selectedTab,
          ),
          Row(
            spacing: 8.0,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99999),
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999999),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      spacing: 4.0,
                      children: [
                        Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                        Text(
                          "Tokens",
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              ModernButton(size: 48, onPressed: () {}, icon: Icon(Icons.question_mark)),
            ],
          ),
        ],
      ),
    );
  }
}
