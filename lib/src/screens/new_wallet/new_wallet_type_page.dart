import 'dart:io';

import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletTypePageHeader extends StatelessWidget {
  const NewWalletTypePageHeader({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 138,
        height: 75,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/hardware_wallet.svg",
                width: 75,
                height: 75,
              ),
            ),
            Positioned(
              left: 63,
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/cake_coin.svg",
                width: 75,
                height: 75,
              ),
            ),
          ],
        ),
      );
}

class NewWalletTypePage extends BasePage {
  NewWalletTypePage({required this.newWalletTypeArguments});

  final NewWalletTypeArguments newWalletTypeArguments;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => newWalletTypeArguments.isCreate
      ? S.current.wallet_list_create_new_wallet
      : S.current.wallet_list_restore_wallet;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) currentFocus.focusedChild?.unfocus();
      };

  @override
  Widget body(BuildContext context) => WalletTypeForm(
        walletImage: currentTheme.isDark ? walletTypeImage : walletTypeLightImage,
        isCreate: newWalletTypeArguments.isCreate,
        onTypeSelected: newWalletTypeArguments.onTypeSelected,
        hardwareWalletType: newWalletTypeArguments.hardwareWalletType,
      );
}

class WalletTypeForm extends StatefulWidget {
  const WalletTypeForm({
    required this.walletImage,
    required this.isCreate,
    this.onTypeSelected,
    this.hardwareWalletType,
  });

  final bool isCreate;
  final Image walletImage;
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final HardwareWalletType? hardwareWalletType;

  bool get isHardwareWallet => hardwareWalletType != null;

  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  WalletTypeFormState() : types = availableWalletTypes;

  static const aspectRatioImage = 1.22;

  List<WalletType> types;
  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    types = filteredTypes = availableWalletTypes
        .where((element) =>
            !widget.isHardwareWallet ||
            DeviceConnectionType.supportedConnectionTypes(
                    element, widget.hardwareWalletType!, Platform.isIOS)
                .isNotEmpty)
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
        child: Column(
          spacing: 24,
          children: [
            widget.hardwareWalletType != null
                ? const NewWalletTypePageHeader()
                : const CakeImageWidget(
                    imageUrl: "assets/new-ui/wallet.svg",
                    width: 100,
                    height: 100,
                  ),
            Text(
              S.of(context).choose_wallet_currency,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListView.separated(
                        key: const ValueKey('new_wallet_type_scrollable_key'),
                        itemCount: filteredTypes.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final item = filteredTypes[index];

                          return GestureDetector(
                            key: ValueKey('new_wallet_type_${item.name}_button_key'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              onTypeSelected(item);
                            },
                            child: SizedBox(
                              height: 50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CakeImageWidget(
                                          height: 24,
                                          width: 24,
                                          imageUrl: getCryptoCurrencyIconForWalletListItem(item),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(walletTypeToDisplayName(item)),
                                        const SizedBox(width: 4),
                                        Text(
                                          walletTypeToDisplayTicker(item),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      ],
                                    ),
                                    CakeImageWidget(
                                      imageUrl: "assets/new-ui/arrow_forward.svg",
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                        BlendMode.srcIn,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> onTypeSelected(WalletType selected) async {
    // If it's a restore flow, trigger the external callback
    // If it's not a BIP39 Wallet or if there are no other wallets, route to the newWallet page
    // Any other scenario, route to pre-existing seed page
    final walletList = await WalletInfo.getAll();
    if (!widget.isCreate) {
      widget.onTypeSelected!(context, selected);
    } else if (!isBIP39Wallet(selected) || walletList.isEmpty) {
      Navigator.of(context).pushNamed(
        Routes.newWallet,
        arguments: NewWalletArguments(type: selected),
      );
    } else {
      Navigator.of(context).pushNamed(Routes.walletGroupDescription, arguments: selected);
    }
  }
}
