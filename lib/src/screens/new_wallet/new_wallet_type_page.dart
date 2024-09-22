import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/bip39_wallet_utils.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/new_wallet_type_view_model.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypePage extends BasePage {
  NewWalletTypePage({
    required this.newWalletTypeViewModel,
    required this.newWalletTypeArguments,
  });

  final NewWalletTypeViewModel newWalletTypeViewModel;
  final NewWalletTypeArguments newWalletTypeArguments;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => newWalletTypeArguments.isCreate
      ? S.current.wallet_list_create_new_wallet
      : S.current.wallet_list_restore_wallet;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.focusedChild?.unfocus();
    }
  };

  @override
  Widget body(BuildContext context) => WalletTypeForm(
        walletImage: currentTheme.type == ThemeType.dark ? walletTypeImage : walletTypeLightImage,
        isCreate: newWalletTypeArguments.isCreate,
        newWalletTypeViewModel: newWalletTypeViewModel,
        onTypeSelected: newWalletTypeArguments.onTypeSelected,
        isHardwareWallet: newWalletTypeArguments.isHardwareWallet,
      );
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm({
    required this.walletImage,
    required this.isCreate,
    required this.newWalletTypeViewModel,
    this.onTypeSelected,
    required this.isHardwareWallet,
  });

  final bool isCreate;
  final Image walletImage;
  final NewWalletTypeViewModel newWalletTypeViewModel;
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool isHardwareWallet;

  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  WalletTypeFormState() : types = availableWalletTypes;

  static const aspectRatioImage = 1.22;

  final TextEditingController searchController = TextEditingController();

  WalletType? selected;
  List<WalletType> types;
  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    types = filteredTypes = availableWalletTypes
        .where((element) =>
            !widget.isHardwareWallet ||
            DeviceConnectionType.supportedConnectionTypes(element, Platform.isIOS).isNotEmpty)
        .toList();
    super.initState();

    searchController.addListener(() {
      setState(() {
        filteredTypes = List.from(types.where((type) => walletTypeToDisplayName(type)
            .toLowerCase()
            .contains(searchController.text.toLowerCase())));
        return;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 48),
              child: Text(
                S.of(context).choose_wallet_currency,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: SearchBarWidget(searchController: searchController, borderRadius: 24),
            ),
            Expanded(
              child: ScrollableWithBottomSection(
                contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                scrollableKey: ValueKey('new_wallet_type_scrollable_key'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ...filteredTypes.map(
                      (type) => Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: SelectButton(
                          key: ValueKey('new_wallet_type_${type.name}_button_key'),
                          image: Image.asset(
                            walletTypeToCryptoCurrency(type).iconPath ?? '',
                            height: 24,
                            width: 24,
                          ),
                          text: walletTypeToDisplayName(type),
                          showTrailingIcon: false,
                          height: 54,
                          isSelected: selected == type,
                          onTap: () => setState(() => selected = type),
                          deviceConnectionTypes: widget.isHardwareWallet
                              ? DeviceConnectionType.supportedConnectionTypes(type, Platform.isIOS)
                              : [],
                        ),
                      ),
                    ),
                  ],
                ),
                bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                bottomSection: PrimaryButton(
                  key: ValueKey('new_wallet_type_next_button_key'),
                  onPressed: () => onTypeSelected(),
                  text: S.of(context).seed_language_next,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isDisabled: selected == null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onTypeSelected() async {
    if (selected == null) throw Exception('Wallet Type is not selected yet.');

    if (selected == WalletType.haven && widget.isCreate) {
      return await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => PopUpCancellableAlertDialog(
          contentText: S.of(context).pause_wallet_creation,
          actionButtonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    // If it's a restore flow, trigger the external callback
    // If it's not a BIP39 Wallet or if there are no other wallets, route to the newWallet page
    // Any other scenario, route to pre-existing seed page
    if (!widget.isCreate) {
      widget.onTypeSelected!(context, selected!);
    } else if (!isBIP39Wallet(selected!) || !widget.newWalletTypeViewModel.hasExisitingWallet) {
      Navigator.of(context).pushNamed(
        Routes.newWallet,
        arguments: NewWalletArguments(type: selected!),
      );
    } else {
      Navigator.of(context).pushNamed(Routes.walletGroupDescription, arguments: selected!);
    }
  }
}
