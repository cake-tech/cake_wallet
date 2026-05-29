import 'package:cake_wallet/core/csv_export_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/line_tab_switcher.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class AssetsTopBar extends StatelessWidget {
  const AssetsTopBar({
    super.key,
    required this.onTabChange,
    required this.selectedTab,
    required this.tabs, required this.dashboardViewModel,
  });

  final void Function(int) onTabChange;
  final int selectedTab;
  final List<String> tabs;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final settingsButtonText = _getSettingsButtonText();
    final hasTokenSettingsButton = settingsButtonText != null;
    // Reuse the exact same detection logic as _getSettingsButtonText so the
    // export button always matches whether the Filters button is visible.
    final isHistoryTab = settingsButtonText == S.current.filters;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, bottom: 0.0, left: 12.0, right: 18.0),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(tabs.length > 1)
          LineTabSwitcher(
            tabs: tabs,
            onTabChange: onTabChange,
            selectedTab: selectedTab,
          )
      else SizedBox.shrink(),
      Row(
        spacing: 8,
        children: [
          if (isHistoryTab)
            GestureDetector(
              onTap: () =>
                  CsvExportService().exportToCsv(dashboardViewModel.items, context),
              child: Semantics(
                label: S.of(context).export_csv,
                button: true,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
          Opacity(
            opacity: hasTokenSettingsButton ? 1 : 0,
            child: ElevatedButton(
              onPressed: () {
                if (tabs[selectedTab] == S.of(context).assets) {
                  Navigator.of(context).pushNamed(
                    Routes.homeSettings,
                    arguments: dashboardViewModel.balanceViewModel,
                  );
                } else if (tabs[selectedTab] == S.of(context).history) {
                  showPopUp<void>(
                    context: context,
                    builder: (context) =>
                        FilterWidget(filterItems: dashboardViewModel.filterItems),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999999),
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  spacing: 6,
                  children: [
                    CakeImageWidget(
                        imageUrl: "assets/new-ui/options_slider.svg",
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
                    Text(
                      settingsButtonText ?? "",
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
          ],
        ),
      ),
    );
  }

  String? _getSettingsButtonText() {
    if (tabs[selectedTab] == S.current.assets &&
        dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled) {
      return S.current.tokens;
    }

    if (tabs[selectedTab] == S.current.history) {
      return S.current.filters;
    }
    return null;
  }
}
