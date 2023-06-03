import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/wallet_types.g.dart';

class NewWalletTypePage extends BasePage {
  NewWalletTypePage({required this.onTypeSelected});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => S.current.wallet_list_restore_wallet;

  @override
  Widget body(BuildContext context) => WalletTypeForm(
      onTypeSelected: onTypeSelected,
      walletImage: currentTheme.type == ThemeType.dark ? walletTypeImage : walletTypeLightImage);
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm({required this.onTypeSelected, required this.walletImage});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final Image walletImage;

  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  WalletTypeFormState() : types = availableWalletTypes;

  static const aspectRatioImage = 1.22;

  final moneroIcon = Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final litecoinIcon = Image.asset('assets/images/litecoin_icon.png', height: 24, width: 24);
  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');
  final havenIcon = Image.asset('assets/images/haven_logo.png', height: 24, width: 24);

  WalletType? selected;
  List<WalletType> types;

  @override
  void initState() {
    types = availableWalletTypes;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      content: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtil.kDesktopMaxWidthConstraint),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 12, right: 12),
                child: AspectRatio(
                    aspectRatio: aspectRatioImage,
                    child: FittedBox(child: widget.walletImage, fit: BoxFit.fill)),
              ),
              Padding(
                padding: EdgeInsets.only(top: 48),
                child: Text(
                  S.of(context).choose_wallet_currency,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .titleLarge!
                          .color!),
                ),
              ),
              ...types.map((type) => Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: SelectButton(
                        image: _iconFor(type),
                        text: walletTypeToDisplayName(type),
                        isSelected: selected == type,
                        onTap: () => setState(() => selected = type)),
                  ))
            ],
          ),
        ),
      ),
      bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      bottomSection: PrimaryButton(
        onPressed: () => onTypeSelected(),
        text: S.of(context).seed_language_next,
        color: Theme.of(context)
            .accentTextTheme!
            .bodyLarge!
            .color!,
        textColor: Colors.white,
        isDisabled: selected == null,
      ),
    );
  }

  Image _iconFor(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        throw Exception(
            '_iconFor: Incorrect Wallet Type. Cannot find icon for Wallet Type: ${type.toString()}');
    }
  }

  Future<void> onTypeSelected() async {
    if (selected == null) {
      throw Exception('Wallet Type is not selected yet.');
    }

    widget.onTypeSelected(context, selected!);
  }
}
