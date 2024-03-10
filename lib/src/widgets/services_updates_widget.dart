import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/service_status.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/service_status_tile.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesUpdatesWidget extends StatelessWidget {
  final Future<ServicesResponse> servicesResponse;

  const ServicesUpdatesWidget(this.servicesResponse, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<ServicesResponse>(
        future: servicesResponse,
        builder: (context, state) {
          return InkWell(
            onTap: state.hasData
                ? () {
                    // save currentSha when the user see the status
                    getIt
                        .get<SharedPreferences>()
                        .setString(PreferencesKey.serviceStatusShaKey, state.data!.currentSha);

                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2,
                        minHeight: MediaQuery.of(context).size.height / 4,
                      ),
                      builder: (context) {
                        Widget body;
                        if (state.data!.servicesStatus.isEmpty) {
                          body = Center(
                            child: Text("Everything is up and running as expected"),
                          );
                        } else {
                          body = SingleChildScrollView(
                            child: Column(
                                children: state.data!.servicesStatus
                                    .map((status) => ServiceStatusTile(status))
                                    .toList()),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                          child: Stack(
                            children: [
                              body,
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.width / 8),
                                  child: PrimaryImageButton(
                                    onPressed: () {
                                      try {
                                        launchUrl(Uri.parse("https://status.cakewallet.com/"));
                                      } catch (_) {}
                                    },
                                    image: Image.asset(
                                      "assets/images/status_website_image.png",
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.white
                                          : null,
                                    ),
                                    text: "Status Website",
                                    color: Theme.of(context)
                                        .extension<WalletListTheme>()!
                                        .createNewWalletButtonBackgroundColor,
                                    textColor: Theme.of(context)
                                        .extension<WalletListTheme>()!
                                        .restoreWalletButtonTextColor,
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Stack(
              children: [
                Image.asset(
                  "assets/images/notification_icon.png",
                  color: Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                ),
                if (state.hasData && state.data!.hasUpdates)
                  Container(
                    height: 7,
                    width: 7,
                    margin: EdgeInsetsDirectional.only(start: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
