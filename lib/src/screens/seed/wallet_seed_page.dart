import 'dart:io';

import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
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
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

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
                    alertTitle: S.of(context).seed_alert_title,
                    alertContent: S.of(context).seed_alert_content,
                    leftButtonText: S.of(context).seed_alert_back,
                    rightButtonText: S.of(context).seed_alert_yes,
                    actionLeftButton: () => Navigator.of(context).pop(false),
                    actionRightButton: () => Navigator.of(context).pop(true));
              }) ??
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
    final image = currentTheme.type == ThemeType.dark ? imageDark : imageLight;

    return WalletSeedPageBody(
      walletSeedViewModel: walletSeedViewModel,
      image: image,
      isNewWalletCreated: isNewWalletCreated,
    );
  }
}

class WalletSeedPageBody extends StatefulWidget {
  const WalletSeedPageBody(
      {Key? key,
      required this.walletSeedViewModel,
      required this.image,
      required this.isNewWalletCreated})
      : super(key: key);

  final WalletSeedViewModel walletSeedViewModel;
  final Image image;
  final bool isNewWalletCreated;

  @override
  State<WalletSeedPageBody> createState() => _WalletSeedPageBodyState();
}

class _WalletSeedPageBodyState extends State<WalletSeedPageBody> {
  final FocusNode _seedNode = FocusNode();

  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _seedFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // required to setup autofill context:
    _nameFieldController.text = widget.walletSeedViewModel.name;
  }

  Future<void> setupPasswordManager() async {
    _seedNode.requestFocus();

    await Future.delayed(Duration(milliseconds: 200));
    _seedFieldController.text = widget.walletSeedViewModel.seed;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: WillPopScope(
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
                /// triggering credential managers API, requires the text to be in Text Fields
                /// and since the Seeds and Name at this stage are already given
                /// then we add them into hidden text fields so that it triggers the API
                AutofillGroup(
                  child: Visibility(
                    visible: false,
                    maintainState: true,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameFieldController,
                          autofillHints: const [AutofillHints.username],
                          keyboardType: TextInputType.none,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          autofillHints: const [AutofillHints.password],
                          controller: _seedFieldController,
                          focusNode: _seedNode,
                        ),
                      ],
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                  child: AspectRatio(aspectRatio: 1, child: widget.image),
                ),
                Observer(builder: (_) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        widget.walletSeedViewModel.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 16, right: 16),
                        child: Text(
                          widget.walletSeedViewModel.seed,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color:
                                  Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                        ),
                      )
                    ],
                  );
                }),
                Column(
                  children: <Widget>[
                    widget.isNewWalletCreated
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 43, left: 43, right: 43),
                            child: Text(
                              S.of(context).seed_reminder,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .extension<TransactionTradeTheme>()!
                                    .detailsTitlesColor,
                              ),
                            ),
                          )
                        : Offstage(),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.only(right: 4),
                            child: PrimaryButton(
                              onPressed: () {
                                ShareUtil.share(
                                  text: widget.walletSeedViewModel.seed,
                                  context: context,
                                );
                              },
                              text: S.of(context).save,
                              color: Colors.green,
                              textColor: Colors.white,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.only(left: 4),
                            child: Builder(
                              builder: (context) => PrimaryButton(
                                onPressed: () {
                                  ClipboardUtil.setSensitiveDataToClipboard(
                                      ClipboardData(text: widget.walletSeedViewModel.seed));
                                  showBar<void>(context, S.of(context).copied_to_clipboard);
                                },
                                text: S.of(context).copy,
                                color: Theme.of(context).extension<PinCodeTheme>()!.indicatorsColor,
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (Platform.isIOS || Platform.isAndroid)
                      Container(
                        padding: EdgeInsets.only(top: 10),
                        child: PrimaryButton(
                          onPressed: () async {
                            bool open = await showPopUp<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertWithTwoActions(
                                      alertTitle: S.current.save_to_pm,
                                      alertContent: S.current.save_pm_content,
                                      rightButtonText: S.current.save,
                                      leftButtonText: S.current.cancel,
                                      actionRightButton: () async {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      actionLeftButton: () =>
                                          Navigator.of(dialogContext).pop(false),
                                    );
                                  },
                                ) ??
                                false;

                            if (open) {
                              await setupPasswordManager();
                              await Future.delayed(Duration(milliseconds: 300));
                              TextInput.finishAutofillContext();
                            }
                          },
                          text: S.current.save_to_pm,
                          color: Colors.blue,
                          textColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
