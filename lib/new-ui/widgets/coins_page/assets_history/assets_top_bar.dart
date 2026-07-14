import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_history_section.dart';
import 'package:cake_wallet/new-ui/widgets/line_tab_switcher.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class AssetsTopBar extends StatelessWidget {
  const AssetsTopBar({
    super.key,
    required this.onTabChange,
    required this.onTransactionHistoryOpened,
    required this.selectedTab,
    required this.tabs, required this.dashboardViewModel,
  });

  final void Function(int) onTabChange;
  final VoidCallback onTransactionHistoryOpened;
  final int selectedTab;
  final List<AssetsHistorySectionTab> tabs;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, bottom: 0.0, left: 12.0, right: 18.0),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LineTabSwitcher(
            tabs: tabs.map((item)=>item.title).toList(),
            onTabChange: onTabChange,
            selectedTab: selectedTab,
          ),
      AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Row(
          key: ValueKey(selectedTab),
          spacing: 8,
          children: [

            Opacity(
              opacity: tabs[selectedTab].actionButton != null ? 1 : 0,
              child: GestureDetector(
                onTap: () {
                    if(tabs[selectedTab].actionButton != null) {
                      tabs[selectedTab].actionButton?.onPressed();
                    }
                  },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999999),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      spacing: 6,
                      children: [

                        if ((tabs[selectedTab].actionButton?.title ?? "").isNotEmpty)
                                Text(
                                  tabs[selectedTab].actionButton?.title ?? "",
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                        CakeImageWidget(
                            imageUrl: tabs[selectedTab].actionButton?.iconPath,
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
                            ],
                          ),
                  ),
                ),
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
