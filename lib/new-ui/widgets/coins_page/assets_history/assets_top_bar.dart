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
    required this.onTransactionHistoryOpened,
    required this.selectedTab,
    required this.tabs, required this.dashboardViewModel,
  });

  final void Function(int) onTabChange;
  final VoidCallback onTransactionHistoryOpened;
  final int selectedTab;
  final List<String> tabs;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final settingsButtonText = _getSettingsButtonText();
    final hasTokenSettingsButton = settingsButtonText != null;

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

                    onTransactionHistoryOpened();
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

                        if ((settingsButtonText ?? "").isNotEmpty)
                                Text(
                                  settingsButtonText ?? "",
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                        CakeImageWidget(
                            imageUrl: _getSettingsButtonIconPath(),
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

  String? _getSettingsButtonIconPath() {
    if (tabs[selectedTab] == S.current.history) {
      return "assets/new-ui/arrow_right.svg";
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
      return S.current.all_pascal_case;
    }
    return null;
  }
}
