import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/line_tab_switcher.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0, left: 12.0, right: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LineTabSwitcher(
            tabs: tabs,
            onTabChange: onTabChange,
            selectedTab: selectedTab,
          ),
      Opacity(
        opacity: tabs[selectedTab] == S.of(context).assets ? 1 : 0,
        child: ElevatedButton(
                  onPressed: () {Navigator.of(context).pushNamed(Routes.homeSettings, arguments: dashboardViewModel.balanceViewModel,);},
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      spacing: 4.0,
                      children: [
                        SvgPicture.asset("assets/new-ui/options_slider.svg", colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn)),
                        Text(
                          S.of(context).tokens,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        )
                      ],
                    ),
                  ),
                ),
      ),

        ],
      ),
    );
  }
}
