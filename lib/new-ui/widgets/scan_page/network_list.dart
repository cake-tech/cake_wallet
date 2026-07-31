import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanPageNetworkList extends StatelessWidget {
  const ScanPageNetworkList({super.key});

  /// Same icon the row would render from `trailingIconPath`, but it now carries the
  /// information that following the row leaves the app.
  Widget _externalLinkIcon(BuildContext context) => Semantics(
        label: S.of(context).opens_in_browser,
        excludeSemantics: true,
        child: CakeImageWidget(
          imageUrl: "assets/new-ui/external_link.svg",
          height: 18,
          width: 18,
          colorFilter:
              ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          color: Theme.of(context).colorScheme.surface),
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).compatible_services,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              spacing: 32,
              children: [
                Column(
                  spacing: 24,
                  children: [
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/scan_service.svg",
                      width: 75,
                      height: 75,
                      colorFilter:
                          ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                    ),
                    Text(
                      S.of(context).compatible_services_desc,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
                NewListSections(sections: {
                  "base": [
                    ListItemRegularRow(
                        keyValue: "addrs",
                        label: S.of(context).crypto_addresses,
                        showArrow: false,
                        iconPath: "assets/new-ui/navbar/wallets.svg",
                        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        subtitle: "${availableWalletTypes.length} ${S.of(context).networks}"),
                    ListItemRegularRow(
                        keyValue: "invoices",
                        label: S.of(context).payment_invoices,
                        showArrow: false,
                        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        iconPath: "assets/new-ui/payment_invoices.svg"),
                    ListItemRegularRow(
                        keyValue: "contacts",
                        label: S.of(context).contacts,
                        showArrow: false,
                        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        iconPath: "assets/new-ui/navbar/contacts.svg"),
                    ListItemRegularRow(
                        keyValue: "nodes",
                        label: S.of(context).nodes,
                        showArrow: false,
                        iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        iconPath: "assets/new-ui/node_minimal.svg"),
                  ],
                  "extra": [
                    ListItemRegularRow(
                        iconPath: "assets/new-ui/wc_min.svg",
                        keyValue: "wc",
                        label: "WalletConnect",
                        subtitle: S.of(context).wc_desc,
                        trailingWidget: _externalLinkIcon(context),
                        onTap: () {
                          launchUrl(Uri.https("walletconnect.com"));
                        }),
                    ListItemRegularRow(
                        iconPath: "assets/new-ui/ocp_min.svg",
                        keyValue: "ocp",
                        label: "OpenCryptoPay",
                        subtitle: S.of(context).ocp_desc,
                        trailingWidget: _externalLinkIcon(context),
                        onTap: () {
                          launchUrl(Uri.https("opencryptopay.io"));
                        })
                  ]
                })
              ],
            ),
          )
        ],
      ),
    );
  }
}
