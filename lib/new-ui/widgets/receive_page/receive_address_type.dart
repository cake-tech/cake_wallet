import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_address_type_selector.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ReceiveAddressTypeDisplay extends StatelessWidget {
  const ReceiveAddressTypeDisplay(
      {super.key,
      required this.receiveOptionViewModel,
      required this.largeQrMode,
      required this.lightningMode});

  final ReceiveOptionViewModel receiveOptionViewModel;
  final bool largeQrMode;
  final bool lightningMode;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        String text = receiveOptionViewModel.selectedReceiveOption.value;
        if (largeQrMode && receiveOptionViewModel.selectedReceiveOption.addAddressWord) {
          text += " Address";
        }

        if (text == "mainnet") {
          if (largeQrMode) {
            text = "${receiveOptionViewModel.walletTypeString} ${S.of(context).address}";
          } else {
            text = "${receiveOptionViewModel.walletTypeString} (Mainnet)";
          }
        }
        String? iconPath = receiveOptionViewModel.selectedReceiveOption.iconPath;
        if (iconPath != null &&
            receiveOptionViewModel.walletTypeString == "Litecoin" &&
            text.contains("Standard")) {
          iconPath = "assets/new-ui/address-type-picker-icons/litecoin.svg";
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showPicker(context),
          child: Row(
            key: ValueKey("$text$largeQrMode"),
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12.0,
            children: [
              if (iconPath != null)
                SvgPicture.asset(
                  width: 32,
                  height: 32,
                  iconPath!,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (!largeQrMode)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(999999),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => _showPicker(context),
                    icon: (Icon(
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                      Icons.keyboard_arrow_down,
                    )),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context) async {
    final res = await showCupertinoModalBottomSheet(
        context: context,
        barrierColor: Colors.black.withAlpha(80),
        builder: (context) {
          return Material(
              child: ReceiveAddressTypeSelector(
            lightningMode: lightningMode,
            receiveOptionViewModel: receiveOptionViewModel,
          ));
        });

    if (res != null && res is ReceivePageOption) {
      receiveOptionViewModel.selectReceiveOption(res);
    }
  }
}
