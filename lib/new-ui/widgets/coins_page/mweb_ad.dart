import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MwebAd extends StatelessWidget {
  const MwebAd({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!dashboardViewModel.shouldShowMwebAd) return SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 24),
        child: Column(
          spacing: 12,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(Routes.mwebSettings),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.surfaceContainer),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        "assets/new-ui/settings_row_icons/mweb.svg",
                        width: 24,
                        height: 24,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            S.of(context).mweb_ad,
                            softWrap: true,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Icon(
                        size: 16,
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => dashboardViewModel.dismissMwebAd(false),
              child: Text(
                S.of(context).do_not_show_anymore,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary),
              ),
            )
          ],
        ),
      );
    });
  }
}
