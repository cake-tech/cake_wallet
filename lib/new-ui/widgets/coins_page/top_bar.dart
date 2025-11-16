import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.lightningMode,
    required this.onLightningSwitchPress, required this.dashboardViewModel,
  });

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(dashboardViewModel.balanceViewModel.hasSecondAdditionalBalance ||
          dashboardViewModel.balanceViewModel.hasSecondAvailableBalance)
          SizedBox(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: ElevatedButton(
                key: ValueKey(lightningMode),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(900.0)),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                ),
                onPressed: onLightningSwitchPress,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      lightningMode
                          ? 'assets/new-ui/switcher-lightning.svg'
                          : 'assets/new-ui/switcher-bitcoin.svg',
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    SvgPicture.asset(
                      lightningMode
                          ? 'assets/new-ui/switcher-bitcoin-off.svg'
                          : 'assets/new-ui/switcher-lightning-off.svg',
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ModernButton.svg(size: 44, onPressed: (){}, svgPath: "assets/new-ui/top-settings.svg",),
        ],
      ),
    );
  }
}
