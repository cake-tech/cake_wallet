import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/main_actions.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/market_place_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/market_place_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DesktopDashboardActions extends StatelessWidget {
  final DashboardViewModel dashboardViewModel;

  const DesktopDashboardActions(this.dashboardViewModel, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Observer(
        builder: (_) {
          return Column(
            children: [
              const SizedBox(height: 16),
              DesktopActionButton(
                title: MainActions.exchangeAction.name(context),
                image: MainActions.exchangeAction.image,
                canShow: MainActions.exchangeAction.canShow?.call(dashboardViewModel),
                isEnabled: MainActions.exchangeAction.isEnabled?.call(dashboardViewModel),
                onTap: () async => await MainActions.exchangeAction.onTap(context, dashboardViewModel),
              ),
              Row(
                children: [
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.receiveAction.name(context),
                      image: MainActions.receiveAction.image,
                      canShow: MainActions.receiveAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.receiveAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async =>
                          await MainActions.receiveAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.sendAction.name(context),
                      image: MainActions.sendAction.image,
                      canShow: MainActions.sendAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.sendAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async => await MainActions.sendAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.buyAction.name(context),
                      image: MainActions.buyAction.image,
                      canShow: MainActions.buyAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.buyAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async => await MainActions.buyAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.sellAction.name(context),
                      image: MainActions.sellAction.image,
                      canShow: MainActions.sellAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.sellAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async => await MainActions.sellAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: MarketPlacePage(
                dashboardViewModel: dashboardViewModel,
                marketPlaceViewModel: getIt.get<MarketPlaceViewModel>(),
              ),
            ),
            ],
          );
        }
      ),
    );
  }
}
