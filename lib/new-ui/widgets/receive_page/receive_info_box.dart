import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveInfoBox extends StatelessWidget {
  ReceiveInfoBox(
      {super.key, required this.iconPath, required this.message, required this.onDismissed});

  static ReceiveInfoBox? forWalletType(WalletType type, {required VoidCallback onDismissed, required AutoGenerateSubaddressStatus autoGenerateSubaddressStatus}) {
    switch (type) {
      case WalletType.nano:
        return null;
      case WalletType.ethereum:
      case WalletType.base:
      case WalletType.solana:
      case WalletType.arbitrum:
      case WalletType.tron:
      case WalletType.polygon:
      case WalletType.zano:
        if(autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.disabled)
          return null;
        return ReceiveInfoBox(
          iconPath: "assets/new-ui/chain_badges/${walletTypeToString(type).toLowerCase()}.svg",
          message:
              "${S.current.infobox_multichain} ${walletTypeToString(type)}",
          onDismissed: onDismissed,
        );
      default:
        return ReceiveInfoBox(
          iconPath: "assets/new-ui/info.svg",
          message: S.current.infobox_auto_address,
          onDismissed: onDismissed,
        );
    }
  }

  late final String iconPath;
  late final String message;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
              Flexible(
                child: Column(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w300),
                      ),
                      GestureDetector(
                          onTap: onDismissed,
                          child: Text(
                            S.of(context).dismiss,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w300),
                          ))
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
