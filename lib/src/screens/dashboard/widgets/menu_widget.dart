import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/setting_action_button.dart';
import 'package:cake_wallet/src/widgets/setting_actions.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';


class MenuWidget extends StatefulWidget {
  MenuWidget(this.dashboardViewModel, Key? key);

  final DashboardViewModel dashboardViewModel;

  @override
  MenuWidgetState createState() => MenuWidgetState();
}

class MenuWidgetState extends State<MenuWidget> {
  MenuWidgetState()
      : this.menuWidth = 0,
        this.screenWidth = 0,
        this.screenHeight = 0,
        this.headerHeight = 120,
        this.tileHeight = 60,
        this.fromTopEdge = 50,
        this.fromBottomEdge = 25,
        this.moneroIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/monero.svg', height: 40, width: 40),
        this.bitcoinIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/bitcoin.svg', height: 40, width: 40),
        this.litecoinIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/litecoin.svg', height: 40, width: 40),
        this.havenIcon = CakeImageWidget(imageUrl: 'assets/images/haven_menu.svg', height: 40, width: 40),
        this.ethereumIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/ethereum.svg', height: 40, width: 40),
        this.nanoIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/nano.svg', height: 40, width: 40),
        this.bananoIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/nano.svg', height: 40, width: 40),
        this.bitcoinCashIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/bitcoin-cash.svg', height: 40, width: 40),
        this.polygonIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/polygon.svg', height: 40, width: 40),
        this.baseIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/base.svg', height: 40, width: 40),
        this.solanaIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/solana.svg', height: 40, width: 40),
        this.tronIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/tron.svg', height: 40, width: 40),
        this.wowneroIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/wownero.svg', height: 40, width: 40),
        this.zanoIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/zano.svg', height: 40, width: 40),
        this.decredIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/decred.svg', height: 40, width: 40),
        this.dogecoinIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/dogecoin.svg', height: 40, width: 40);

  final largeScreen = 731;

  double menuWidth;
  double screenWidth;
  double screenHeight;

  double headerHeight;
  double tileHeight;
  double fromTopEdge;
  double fromBottomEdge;

  Widget moneroIcon;
  Widget bitcoinIcon;
  Widget litecoinIcon;
  Widget havenIcon;
  Widget ethereumIcon;
  Widget bitcoinCashIcon;
  Widget nanoIcon;
  Widget bananoIcon;
  Widget polygonIcon;
  Widget baseIcon;
  Widget solanaIcon;
  Widget tronIcon;
  Widget wowneroIcon;
  Widget zanoIcon;
  Widget decredIcon;
  Widget dogecoinIcon;

  @override
  void initState() {
    menuWidth = 0;
    screenWidth = 0;
    screenHeight = 0;

    headerHeight = 120;
    tileHeight = 60;
    fromTopEdge = 50;
    fromBottomEdge = 25;

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      menuWidth = screenWidth;

      if (screenHeight > largeScreen) {
        final scale = screenHeight / largeScreen;
        tileHeight *= scale;
        headerHeight *= scale;
        fromTopEdge *= scale;
        fromBottomEdge *= scale;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<SettingActions> items = List.of(SettingActions.all);
    if (!widget.dashboardViewModel.hasSilentPayments) {
      items.removeWhere(
          (element) => element.name(context) == S.of(context).silent_payments_settings);
    }
    if (!widget.dashboardViewModel.isMoneroViewOnly) {
      items.removeWhere((element) => element.name(context) == S.of(context).export_outputs);
    }
    if (!widget.dashboardViewModel.hasMweb) {
      items.removeWhere((element) => element.name(context) == S.of(context).litecoin_mweb_settings);
    }
    int itemCount = items.length;

    moneroIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/monero.svg', height: 40, width: 40);
    bitcoinIcon = CakeImageWidget(imageUrl: 'assets/images/crypto/bitcoin.svg', height: 40, width: 40);

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 24),
          child: Container(
            height: 60,
            width: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.separated(
                padding: EdgeInsets.only(top: 0),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Container(
                      height: headerHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      padding: EdgeInsets.only(
                        left: 24,
                        top: fromTopEdge,
                        right: 24,
                        bottom: fromBottomEdge,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          _iconFor(type: widget.dashboardViewModel.type),
                          SizedBox(width: 12),
                          SingleChildScrollView(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: widget.dashboardViewModel.subname.isNotEmpty
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    widget.dashboardViewModel.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (widget.dashboardViewModel.subname.isNotEmpty)
                                    Observer(
                                      builder: (_) => Text(
                                        widget.dashboardViewModel.subname,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  index--;

                  final item = items[index];
                  final isLastTile = index == itemCount - 1;

                  return SettingActionButton(
                    key: item.key,
                    isLastTile: isLastTile,
                    tileHeight: tileHeight,
                    selectionActive: false,
                    fromBottomEdge: fromBottomEdge,
                    fromTopEdge: fromTopEdge,
                    onTap: () => item.onTap.call(context),
                    image: item.image,
                    title: item.name.call(context),
                  );
                },
                separatorBuilder: (_, index) => Container(
                  height: 0,
                  color: Theme.of(context).colorScheme.outline,
                ),
                itemCount: itemCount + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconFor({required WalletType type}) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      case WalletType.ethereum:
        return ethereumIcon;
      case WalletType.bitcoinCash:
        return bitcoinCashIcon;
      case WalletType.nano:
        return nanoIcon;
      case WalletType.banano:
        return bananoIcon;
      case WalletType.polygon:
        return polygonIcon;
      case WalletType.solana:
        return solanaIcon;
      case WalletType.base:
        return baseIcon;
      case WalletType.tron:
        return tronIcon;
      case WalletType.wownero:
        return wowneroIcon;
      case WalletType.zano:
        return zanoIcon;
      case WalletType.decred:
        return decredIcon;
      case WalletType.dogecoin:
        return dogecoinIcon;
      default:
        throw Exception('No icon for ${type.toString()}');
    }
  }
}
