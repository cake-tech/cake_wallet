import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveLargeAmountPreview extends StatelessWidget {
  const ReceiveLargeAmountPreview(
      {super.key, required this.amount, required this.currency, required this.largeQrMode});

  final String amount;
  final String currency;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      opacity: largeQrMode && amount.isNotEmpty ? 1 : 0,
      child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transformAlignment: Alignment.bottomCenter,
          height: largeQrMode && amount.isNotEmpty ? 52 : 0,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              SvgPicture.asset("assets/new-ui/send.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn)),
              Row(
                spacing: 4,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    currency,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                ],
              )
            ],
          )),
    );
  }
}
