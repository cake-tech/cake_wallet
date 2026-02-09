import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({super.key, required this.balance, required this.chainIconPath});

  final BalanceRecord balance;
  final String chainIconPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHigh,
              Theme.of(context).colorScheme.surfaceContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 45,
                      height: 45,
                      child: Stack(
                        children: [
                          Image.asset(balance.asset.iconPath ?? ""),
                          if (chainIconPath.isNotEmpty)
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                    decoration: ShapeDecoration(
                                        shape: RoundedSuperellipseBorder(
                                            borderRadius: BorderRadius.circular(5)),
                                        color: Colors.white),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: SvgPicture.asset(
                                        chainIconPath,
                                        width: 12,
                                        height: 12,
                                        colorFilter:
                                            ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                      ),
                                    )))
                        ],
                      )),
                  SizedBox(width: 8.0),
                  Column(
                    spacing: 4.0,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.asset.fullName ?? balance.asset.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        balance.availableBalance + " " + balance.asset.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                balance.fiatAvailableBalance,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
