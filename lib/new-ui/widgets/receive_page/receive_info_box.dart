import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveInfoBox extends StatelessWidget {
  ReceiveInfoBox(
      {super.key, required this.iconPath, required this.message, required this.onDismissed});

  ReceiveInfoBox.forWalletType(WalletType type, {required this.onDismissed}) {
    switch (type) {
      case WalletType.ethereum:
        iconPath = "assets/new-ui/chain_badges/ethereum.svg";
        message = "Use this address to receive any token or collectible on Ethereum";
      default:
        iconPath = "assets/new-ui/info.svg";
        message = "Your receive address will rotate every time you close and reopen this screen";
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
                            "Dismiss",
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
