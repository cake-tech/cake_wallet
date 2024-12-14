import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
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

import '../../../themes/extensions/send_page_theme.dart';

class WalletSeedPage extends BasePage {
  WalletSeedPage(this.walletSeedViewModel, {required this.isNewWalletCreated});

  final imageLight = Image.asset('assets/images/crypto_lock_light.png');
  final imageDark = Image.asset('assets/images/crypto_lock.png');

  @override
  String get title => S.current.seed_title;

  final bool isNewWalletCreated;
  final WalletSeedViewModel walletSeedViewModel;

  @override
  Widget trailing(BuildContext context) {
    final copyImage = Image.asset(
      'assets/images/copy_address.png',
      color: Theme.of(context)
          .extension<CakeTextTheme>()!
          .buttonTextColor
    );

    return isNewWalletCreated
        ? GestureDetector(
            key: ValueKey('wallet_seed_page_copy_seeds_button_key'),
            onTap: () {
              ClipboardUtil.setSensitiveDataToClipboard(
                ClipboardData(text: walletSeedViewModel.seed),
              );
              showBar<void>(context, S.of(context).copied_to_clipboard);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              width: 40,
              alignment: Alignment.center,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Theme.of(context).cardColor,
              ),
              child: copyImage,
            ),
          )
        : Offstage();
  }

  @override
  Widget body(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Observer(
                builder: (_) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: currentTheme.type == ThemeType.dark
                                  ? Color.fromRGBO(132, 110, 64, 1)
                                  : Color.fromRGBO(194, 165, 94, 1),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              border: Border.all(
                                color: currentTheme.type == ThemeType.dark
                                    ? Color.fromRGBO(177, 147, 41, 1)
                                    : Color.fromRGBO(125, 122, 15, 1),
                                width: 2.0,
                              )),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.75),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  S.current.cake_seeds_save_disclaimer,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: currentTheme.type == ThemeType.dark
                                        ? Colors.white.withOpacity(0.75)
                                        : Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          key: ValueKey('wallet_seed_page_wallet_name_text_key'),
                          walletSeedViewModel.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            itemCount: walletSeedViewModel.seedSplit.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.8,
                              mainAxisSpacing: 8.0,
                              crossAxisSpacing: 8.0,
                            ),
                            itemBuilder: (context, index) {
                              final item = walletSeedViewModel.seedSplit[index];
                              final numberCount = index + 1;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      child: Text(
                                        //maxLines: 1,
                                        numberCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .extension<CakeTextTheme>()!
                                                .buttonTextColor
                                                .withOpacity(0.5)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${item[0].toLowerCase()}${item.substring(1)}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            height: 0.8,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .extension<CakeTextTheme>()!
                                                .buttonTextColor),
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
                },
              ),
              Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.only(right: 8.0, top: 8.0),
                          child: PrimaryButton(
                            key: ValueKey('wallet_seed_page_save_seeds_button_key'),
                            onPressed: () {
                              ShareUtil.share(
                                text: walletSeedViewModel.seed,
                                context: context,
                              );
                            },
                            text: S.of(context).save,
                            color: Theme.of(context).cardColor,
                            textColor: currentTheme.type == ThemeType.dark
                                ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                                : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Builder(
                            builder: (context) => PrimaryButton(
                              key: ValueKey('wallet_seed_page_verify_seed_button_key'),
                              onPressed: () =>
                                  Navigator.pushNamed(context, Routes.walletSeedVerificationPage),
                              text: S.current.verify_seed,
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
