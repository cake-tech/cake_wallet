import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class HandlesListWidget extends StatelessWidget {
  const HandlesListWidget({
    super.key,
    required this.items,
    required this.fillColor,
  });

  final List<AddressSource> items;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final src = items[index];
        return ListTile(
          title: Text(src.label, style: Theme
              .of(context)
              .textTheme
              .bodyMedium),
          trailing: Text(src.alias, style: Theme
              .of(context)
              .textTheme
              .bodyMedium),
          tileColor: fillColor,
          dense: true,
          visualDensity: VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: ImageUtil.getImageFromPath(imagePath: src.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        );
      },
    );
  }
}