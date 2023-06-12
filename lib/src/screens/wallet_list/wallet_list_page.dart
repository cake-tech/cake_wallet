import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

class WalletListPage extends BasePage {
  WalletListPage({required this.walletListViewModel, required this.authService});

  final WalletListViewModel walletListViewModel;
  final AuthService authService;

  @override
  String get title => S.current.wallets;

  @override
  Widget body(BuildContext context) =>
      WalletListBody(walletListViewModel: walletListViewModel, authService: authService);
}

class WalletListBody extends StatefulWidget {
  WalletListBody({required this.walletListViewModel, required this.authService});

  final WalletListViewModel walletListViewModel;
  final AuthService authService;

  @override
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  final moneroIcon = Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final litecoinIcon = Image.asset('assets/images/litecoin_icon.png', height: 24, width: 24);
  final nonWalletTypeIcon = Image.asset('assets/images/close.png', height: 24, width: 24);
  final havenIcon = Image.asset('assets/images/haven_logo.png', height: 24, width: 24);
  final scrollController = ScrollController();
  final double tileHeight = 60;
  Flushbar<void>? _progressBar;

  @override
  Widget build(BuildContext context) {
    final newWalletImage =
        Image.asset('assets/images/new_wallet.png', height: 12, width: 12, color: Colors.white);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12, width: 12, color: Theme.of(context).primaryTextTheme!.titleLarge!.color!);

    return Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 20),
          content: Container(
            child: Observer(
              builder: (_) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, index) =>
                      Divider(color: Theme.of(context).colorScheme.background, height: 32),
                  itemCount: widget.walletListViewModel.wallets.length,
                  itemBuilder: (__, index) {
                    final wallet = widget.walletListViewModel.wallets[index];
                    final currentColor = wallet.isCurrent
                        ? Theme.of(context).accentTextTheme!.titleSmall!.decorationColor!
                        : Theme.of(context).colorScheme.background;
                    final row = GestureDetector(
                        onTap: () async {
                          if (wallet.isCurrent || !wallet.isEnabled) {
                            return;
                          }

                          final confirmed = await showPopUp<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertWithTwoActions(
                                        alertTitle: S.of(context).change_wallet_alert_title,
                                        alertContent:
                                            S.of(context).change_wallet_alert_content(wallet.name),
                                        leftButtonText: S.of(context).cancel,
                                        rightButtonText: S.of(context).change,
                                        actionLeftButton: () =>
                                            Navigator.of(dialogContext).pop(false),
                                        actionRightButton: () =>
                                            Navigator.of(dialogContext).pop(true));
                                  }) ??
                              false;

                          if (confirmed) {
                            await _loadWallet(wallet);
                          }
                        },
                        child: Container(
                          height: tileHeight,
                          width: double.infinity,
                          child: Row(
                            children: <Widget>[
                              Container(
                                height: tileHeight,
                                width: 4,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4)),
                                    color: currentColor),
                              ),
                              Expanded(
                                child: Container(
                                  height: tileHeight,
                                  padding: EdgeInsets.only(left: 20, right: 20),
                                  color: Theme.of(context).colorScheme.background,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      wallet.isEnabled
                                          ? _imageFor(type: wallet.type)
                                          : nonWalletTypeIcon,
                                      SizedBox(width: 10),
                                      Text(
                                        wallet.name,
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .titleLarge!
                                                .color!),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ));

                    return wallet.isCurrent
                        ? row
                        : Row(children: [
                            Expanded(child: row),
                            GestureDetector(
                              onTap: () => _removeWallet(wallet),
                              child: Container(
                                height: 40,
                                width: 44,
                                padding: EdgeInsets.only(right: 20),
                                child: Center(
                                  child: Image.asset('assets/images/trash.png',
                                      height: 16,
                                      width: 16,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .titleLarge!
                                          .color),
                                ),
                              ),
                            )
                          ]);
                  }),
            ),
          ),
          bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
          bottomSection: Column(children: <Widget>[
            PrimaryImageButton(
              onPressed: () {
                if (isSingleCoin) {
                  Navigator.of(context).pushNamed(Routes.newWallet,
                      arguments: widget.walletListViewModel.currentWalletType);
                } else {
                  Navigator.of(context).pushNamed(Routes.newWalletType);
                }
              },
              image: newWalletImage,
              text: S.of(context).wallet_list_create_new_wallet,
              color: Theme.of(context).accentTextTheme!.bodyLarge!.color!,
              textColor: Colors.white,
            ),
            SizedBox(height: 10.0),
            PrimaryImageButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.restoreOptions, arguments: false);
                },
                image: restoreWalletImage,
                text: S.of(context).wallet_list_restore_wallet,
                color: Theme.of(context).accentTextTheme!.bodySmall!.color!,
                textColor: Theme.of(context).primaryTextTheme!.titleLarge!.color!)
          ])),
    );
  }

  Image _imageFor({required WalletType type}) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.monero:
        return moneroIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        return nonWalletTypeIcon;
    }
  }

  Future<void> _loadWallet(WalletListItem wallet) async {
    await widget.authService.authenticateAction(context,
        onAuthSuccess: (isAuthenticatedSuccessfully) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }

      try {
        changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
        await widget.walletListViewModel.loadWallet(wallet);
        await hideProgressText();
        // only pop the wallets route in mobile as it will go back to dashboard page
        // in desktop platforms the navigation tree is different
        if (DeviceInfo.instance.isMobile) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
      } catch (e) {
        changeProcessText(S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
      }
    });
  }

  Future<void> _removeWallet(WalletListItem wallet) async {
    widget.authService.authenticateAction(context,
        onAuthSuccess: (isAuthenticatedSuccessfully) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }
      _onSuccessfulAuth(wallet);
    });
  }

  void _onSuccessfulAuth(WalletListItem wallet) async {
    bool confirmed = false;
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
            alertTitle: S.of(context).delete_wallet,
            alertContent: S.of(context).delete_wallet_confirm_message(wallet.name),
            leftButtonText: S.of(context).cancel,
            rightButtonText: S.of(context).delete,
            actionLeftButton: () => Navigator.of(context).pop(),
            actionRightButton: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
          );
        });

    if (confirmed) {
      try {
        changeProcessText(S.of(context).wallet_list_removing_wallet(wallet.name));
        await widget.walletListViewModel.remove(wallet);
        hideProgressText();
      } catch (e) {
        changeProcessText(
          S.of(context).wallet_list_failed_to_remove(wallet.name, e.toString()),
        );
      }
    }
  }

  void changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)..show(context);
  }

  Future<void> hideProgressText() async {
    await Future.delayed(Duration(milliseconds: 50), () {
      _progressBar?.dismiss();
      _progressBar = null;
    });
  }
}
