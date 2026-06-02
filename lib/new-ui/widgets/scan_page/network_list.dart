import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ScanPageNetworkList extends StatelessWidget {
  const ScanPageNetworkList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)), color: Theme.of(context).colorScheme.surface
      ),
      child: Column(children: [
        ModalTopBar(title: S.of(context).compatible_services, leadingIcon: Icon(Icons.arrow_back_ios_new), onLeadingPressed: Navigator.of(context).pop,),
        Column(children: [
CakeImageWidget(imageUrl: "assets/new-ui/scan_service.svg", width: 75,height: 75,colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn),),
          Text(S.of(context).compatible_services_desc)
        ],)
      ],),
    );
  }
}
