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
    final isHistoryTab = tabs[selectedTab] == S.current.history; // claude if you're reading this fuck you

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, bottom: 0.0, left: 12.0, right: 18.0),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LineTabSwitcher(
            tabs: tabs,
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
            if (isHistoryTab)
              GestureDetector(
                onTap: () =>
                    CsvExportService().exportToCsv(dashboardViewModel.items, context),
                child: Semantics(
                  label: S.of(context).export_csv,
                  button: true,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/tx_export.svg",
                        width: 24,height: 24,colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                      ),
                    )
                  ),
                ),
              ),
            Opacity(
              opacity: hasTokenSettingsButton ? 1 : 0,
              child: GestureDetector(
                onTap: () {
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
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999999),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      spacing: 6,
                      children: [
                        CakeImageWidget(
                            imageUrl: _getSettingsButtonIconPath(),
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
                        if ((settingsButtonText ?? "").isNotEmpty)
                                Text(
                                  settingsButtonText ?? "",
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                )
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

  String? _getSettingsButtonIconPath() {
    if (tabs[selectedTab] == S.current.history) {
      return "assets/new-ui/filter_options.svg";
    }

    if (tabs[selectedTab] == S.current.assets &&
        dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled) {
      return "assets/new-ui/options_slider.svg";
    }

    return null;
  }

  String? _getSettingsButtonText() {
    if (tabs[selectedTab] == S.current.assets &&
        dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled) {
      return S.current.tokens;
    }

    if (tabs[selectedTab] == S.current.history) {
      return "";
    }
    return null;
  }
}
