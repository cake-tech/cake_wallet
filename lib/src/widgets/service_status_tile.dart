import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/entities/service_status.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceStatusTile extends StatelessWidget {
  final ServiceStatus status;

  const ServiceStatusTile(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(8),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AutoSizeText(
                "${status.title}${status.status != null ? " - ${status.status}" : ""}",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                   
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
                maxLines: 1,
                textAlign: TextAlign.start,
              ),
            ),
            Text(
              _getTimeString(status.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      leading: RotatedBox(
        child: Icon(
          Icons.info,
          color: status.status == "resolved"
              ? CustomThemeColors.syncGreen
              : Theme.of(context).colorScheme.errorContainer,
        ),
        quarterTurns: 2,
      ),
      subtitle: Row(
        children: [
          Expanded(child: Text(status.description)),
          if (status.image != null)
            SizedBox(
              height: 50,
              width: 50,
              child: Image.network(status.image!),
            ),
        ],
      ),
    );
  }

  String _getTimeString(DateTime date) {
    int difference = DateTime.now().difference(date).inHours;
    if (difference == 0) {
      return "few minutes ago";
    }
    if (difference < 24) {
      return DateFormat('h:mm a').format(date);
    }
    return DateFormat('d-MM-yyyy').format(date);
  }
}
