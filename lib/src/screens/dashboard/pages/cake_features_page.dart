import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/apps_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';

class CakeFeaturesPage extends StatelessWidget {
  CakeFeaturesPage({required this.dashboardViewModel, required this.cakeFeaturesViewModel});

  final DashboardViewModel dashboardViewModel;
  final CakeFeaturesViewModel cakeFeaturesViewModel;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scaffold: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: !FeatureFlag.hasNewUi ? _buildOldUi(context) : _buildNewUi(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (!FeatureFlag.hasNewUi) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16),
        child: Text(
          S.of(context).apps,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        child: Text(
          S.of(context).apps,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }

  Widget _buildOldUi(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        DashBoardRoundedCardWidget(
          shadowBlur: dashboardViewModel.getShadowBlur(),
          shadowSpread: dashboardViewModel.getShadowSpread(),
          onTap: () => _onCakePayTap(context),
          title: 'Cake Pay',
          subTitle: S.of(context).cake_pay_subtitle,
          image: Image.asset('assets/images/cakepay.png', height: 74, width: 70, fit: BoxFit.cover),
        ),
        Observer(builder: (_) {
          if (dashboardViewModel.type == WalletType.ethereum) {
            return DashBoardRoundedCardWidget(
              shadowBlur: dashboardViewModel.getShadowBlur(),
              shadowSpread: dashboardViewModel.getShadowSpread(),
              onTap: () => Navigator.of(context).pushNamed(Routes.dEuroSavings),
              title: S.of(context).deuro_savings,
              subTitle: S.of(context).deuro_savings_subtitle,
              image: Image.asset('assets/images/deuro_icon.png',
                  height: 80, width: 80, fit: BoxFit.cover),
            );
          }
          return const SizedBox();
        }),
        DashBoardRoundedCardWidget(
          shadowBlur: dashboardViewModel.getShadowBlur(),
          shadowSpread: dashboardViewModel.getShadowSpread(),
          onTap: () => _launchUrl("cake.nano-gpt.com"),
          title: "NanoGPT",
          subTitle: S.of(context).nanogpt_subtitle,
          image: Image.asset('assets/images/nanogpt.png', height: 80, width: 80, fit: BoxFit.cover),
        ),
        const Spacer(),
        const SizedBox(height: 125),
      ],
    );
  }

  Widget _buildNewUi(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: CakeImageWidget(
                imageUrl: "assets/new-ui/by-cakelabs.svg",
                height: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        AppsWidget(
          isWide: true,
          isCake: true,
          onTap: () => _onCakePayTap(context),
          title: 'Cake Pay',
          subTitle: S.of(context).cake_pay_subtitle,
          image: 'assets/images/cakepay.png',
        ),
        AppsWidget(
          isWide: true,
          isLink: true,
          isCake: true,
          onTap: () => _launchUrl("cupcakewallet.com"),
          title: "Cupcake",
          subTitle: "Turn your old phone into your new hardware wallet with our new app",
          image: 'assets/images/cupcake.png',
        ),
        AppsWidget(
          isWide: true,
          isLink: true,
          isCake: true,
          onTap: () => _launchUrl("radar.chat"),
          title: "Radar",
          subTitle: "Your messages. Your Bitcoin. Together, at last",
          image: 'assets/images/radar.png',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
          child: Text(
            "Featured Apps",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        AppsWidget(
          isWide: true,
          isLink: true,
          onTap: () => _launchUrl("cake.nano-gpt.com"),
          title: "NanoGPT",
          subTitle: S.of(context).nanogpt_subtitle,
          image: 'assets/images/nanogpt.png',
        ),
        Observer(builder: (_) {
          if (dashboardViewModel.type == WalletType.ethereum ||
              dashboardViewModel.type == WalletType.solana ||
              dashboardViewModel.type == WalletType.polygon ||
              dashboardViewModel.type == WalletType.base ||
              dashboardViewModel.type == WalletType.arbitrum) {
            return AppsWidget(
              isWide: true,
              onTap: () => _navigatorToFeaturePage(
                  context: context,
                  errorAlertContent: 'MoonPay Virtual Accounts unavailable',
                  route: Routes.moonPayVAOnboardingPage),
              title: "Virtual Account (Iron)",
              subTitle:
                  "Create a virtual bank account with Iron (by Moonpay) and receive funds directly in your wallet",
              image: 'assets/images/iron_icon.svg',
            );
          }
          return const SizedBox();
        }),
        Observer(builder: (_) {
          if (dashboardViewModel.type == WalletType.ethereum) {
            return AppsWidget(
              isWide: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.dEuroSavings),
              title: S.of(context).deuro_savings,
              subTitle: S.of(context).deuro_savings_subtitle,
              image: 'assets/images/deuro_icon.png',
            );
          }
          return const SizedBox();
        }),
        const Spacer(),
        const SizedBox(height: 125),
      ],
    );
  }

  void _onCakePayTap(BuildContext context) {
    if (Platform.isMacOS) {
      _launchUrl("buy.cakepay.com");
    } else {
      _navigatorToFeaturePage(
          context: context,
          errorAlertContent: S.of(context).gift_cards_unavailable,
          route: Routes.cakePayCardsPage);
    }
  }

  void _launchUrl(String url) {
    try {
      launchUrl(Uri.https(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      printV(e);
    }
  }

  void _navigatorToFeaturePage(
      {required BuildContext context, required String errorAlertContent, required String route}) {
    if (dashboardViewModel.type == WalletType.haven) {
      showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).error,
                alertContent: errorAlertContent,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    } else {
      Navigator.pushNamed(context, route);
    }
  }
}
