import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/pin_code_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';

class WalletSeedPage extends BasePage {
  WalletSeedPage(this.walletSeedViewModel, {required this.isNewWalletCreated});

  final imageLight = Image.asset('assets/images/crypto_lock_light.png');
  final imageDark = Image.asset('assets/images/crypto_lock.png');

  @override
  String get title => S.current.seed_title;

  final bool isNewWalletCreated;
  final WalletSeedViewModel walletSeedViewModel;

  @override
  void onClose(BuildContext context) async {
    if (isNewWalletCreated) {
      final confirmed = await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                alertDialogKey: ValueKey('wallet_seed_page_seed_alert_dialog_key'),
                alertRightActionButtonKey:
                    ValueKey('wallet_seed_page_seed_alert_confirm_button_key'),
                alertLeftActionButtonKey: ValueKey('wallet_seed_page_seed_alert_back_button_key'),
                alertTitle: S.of(context).seed_alert_title,
                alertContent: S.of(context).seed_alert_content,
                leftButtonText: S.of(context).seed_alert_back,
                rightButtonText: S.of(context).seed_alert_yes,
                actionLeftButton: () => Navigator.of(context).pop(false),
                actionRightButton: () => Navigator.of(context).pop(true),
              );
            },
          ) ??
          false;

      if (confirmed) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget? leading(BuildContext context) => isNewWalletCreated ? null : super.leading(context);

  @override
  Widget trailing(BuildContext context) {
    return isNewWalletCreated
        ? GestureDetector(
            key: ValueKey('wallet_seed_page_next_button_key'),
            onTap: () => onClose(context),
            child: Container(
              width: 100,
              height: 32,
              alignment: Alignment.center,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Theme.of(context).cardColor),
              child: Text(
                S.of(context).seed_language_next,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor),
              ),
            ),
          )
        : Offstage();
  }

  @override
  Widget body(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: EdgeInsets.all(24),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Observer(builder: (_) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 221, 44, 0.37),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              border: Border.all(
                                color: Color.fromRGBO(223, 214, 0, 0.7),
                                width: 2.0,
                              )),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 64,
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  S.current.cake_seeds_save_disclaimer,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        Text(
                          key: ValueKey('wallet_seed_page_wallet_name_text_key'),
                          walletSeedViewModel.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                          ),
                        ),
                        SizedBox(height: 24),
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: walletSeedViewModel.seedSplit.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: walletSeedViewModel.columnCount,
                              childAspectRatio: 3,
                              mainAxisSpacing: 8.0,
                              crossAxisSpacing: 8.0,
                            ),
                            itemBuilder: (context, index) {
                              final item = walletSeedViewModel.seedSplit[index];
                              final numberCount = index + 1;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color:
                                      Theme.of(context).extension<PinCodeTheme>()!.indicatorsColor,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      numberCount.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .extension<DashboardPageTheme>()!
                                            .textColor
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item[0].toUpperCase()}${item.substring(1)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .extension<DashboardPageTheme>()!
                                            .textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.only(right: 8.0),
                            child: PrimaryButton(
                              key: ValueKey('wallet_seed_page_save_seeds_button_key'),
                              onPressed: () {
                                ShareUtil.share(
                                  text: walletSeedViewModel.seed,
                                  context: context,
                                );
                              },
                              text: S.of(context).save,
                              color: Theme.of(context).primaryColor,
                              textColor: currentTheme.type == ThemeType.dark
                                  ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                                  : Colors.white,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Builder(
                              builder: (context) => PrimaryButton(
                                key: ValueKey('wallet_seed_page_copy_seeds_button_key'),
                                onPressed: () {
                                  ClipboardUtil.setSensitiveDataToClipboard(
                                    ClipboardData(text: walletSeedViewModel.seed),
                                  );
                                  showBar<void>(context, S.of(context).copied_to_clipboard);
                                },
                                text: S.of(context).copy,
                                color: Theme.of(context).extension<PinCodeTheme>()!.indicatorsColor,
                                textColor:
                                    Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
