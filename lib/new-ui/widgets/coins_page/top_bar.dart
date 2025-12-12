import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.lightningMode,
    required this.onLightningSwitchPress, required this.dashboardViewModel, required this.onSettingsButtonPress,
  });

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;
  final VoidCallback onSettingsButtonPress;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          (dashboardViewModel.balanceViewModel.hasSecondAdditionalBalance ||
          dashboardViewModel.balanceViewModel.hasSecondAvailableBalance) ?
          SizedBox(
              child: InkWell(
                onTap: onLightningSwitchPress,
                child: Container(
                  // decoration: ShapeDecoration(
                  //     shape: RoundedSuperellipseBorder(borderRadius: BorderRadiusGeometry.circular(30.0)),
                  //   color: Theme.of(context).colorScheme.surfaceContainer
                  // ),
                  width: 84,
                  height: 44,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(900.0)), color: Theme.of(context).colorScheme.surfaceContainer),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        alignment: Alignment.centerRight,
                        margin: EdgeInsets.only(left: lightningMode
                            ? 40
                            : 0),
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(900.0)), color: Theme.of(context).colorScheme.primary),
                      ),
                      Container(
                        child: Row(
                          spacing: 4.0,
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 150),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: SvgPicture.asset(
                                key: ValueKey(lightningMode),
                                'assets/new-ui/switcher-bitcoin.svg',
                                width: 36,
                                height: 36,
                                colorFilter: ColorFilter.mode(
                                  lightningMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceContainer,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 150),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: SvgPicture.asset(
                                key: ValueKey(lightningMode),
                                'assets/new-ui/switcher-lightning.svg',
                                width: 36,
                                height: 36,
                                colorFilter: ColorFilter.mode(
                                  lightningMode
                                      ? Theme.of(context).colorScheme.surfaceContainer
                                      : Theme.of(context).colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ) : Container(),
          ModernButton.svg(size: 44, onPressed: onSettingsButtonPress, svgPath: "assets/new-ui/top-settings.svg",),
        ],
      ),
    );
  }
}
