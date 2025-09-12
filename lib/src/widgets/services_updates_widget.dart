import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/service_status.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/service_status_tile.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesUpdatesWidget extends StatefulWidget {
  final Future<ServicesResponse> servicesResponse;
  final bool enabled;

  const ServicesUpdatesWidget(this.servicesResponse, {super.key, required this.enabled});

  @override
  State<ServicesUpdatesWidget> createState() => _ServicesUpdatesWidgetState();
}

class _ServicesUpdatesWidgetState extends State<ServicesUpdatesWidget> {
  bool wasOpened = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return InkWell(
        onTap: () async {
          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  alertTitle: S.current.service_health_disabled,
                  alertContent: S.current.service_health_disabled_message,
                  buttonText: S.current.ok,
                  buttonAction: () => Navigator.of(context).pop(),
                );
              });
        },
        child: CakeImageWidget(
          imageUrl: "assets/images/notif.svg",
          color: Theme.of(context).colorScheme.primary,
          width: DeviceInfo.instance.isDesktop ? 30 : 20,
        ),
      );
    }
    return Padding(
      padding: DeviceInfo.instance.isDesktop
          ? EdgeInsets.zero
          : EdgeInsets.only(left: 16, top: 12, right: 8, bottom: 8),
      child: FutureBuilder<ServicesResponse>(
        future: widget.servicesResponse,
        builder: (context, state) {
          return InkWell(
            onTap: state.hasData
                ? () {
                    // save currentSha when the user see the status
                    getIt
                        .get<SharedPreferences>()
                        .setString(PreferencesKey.serviceStatusShaKey, state.data!.currentSha);

                    setState(() => wasOpened = true);

                    showModalBottomSheet(
                      backgroundColor: Theme.of(context).colorScheme.surface,
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
                            child: Text(
                              "Everything is up and running as expected",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        } else {
                          body = SingleChildScrollView(
                            child: Column(
                              children: state.data!.servicesStatus
                                  .map((status) => ServiceStatusTile(status))
                                  .toList(),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Expanded(child: body),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: PrimaryImageButton(
                                    onPressed: () {
                                      try {
                                        launchUrl(
                                            Uri.parse(
                                              "https://status.cakewallet.com/",
                                            ),
                                            mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                    },
                                    image: Image.asset(
                                      "assets/images/status_website_image.png",
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    text: "Status Website",
                                    color: Theme.of(context).colorScheme.primary,
                                    textColor: Theme.of(context).colorScheme.onPrimary,
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
                CakeImageWidget(
                  imageUrl: "assets/images/notif.svg",
                  color: Theme.of(context).colorScheme.primary,
                  width: DeviceInfo.instance.isDesktop ? 30 : 20,
                ),
                if (state.hasData && state.data!.hasUpdates && !wasOpened)
                  Container(
                    height: 7,
                    width: 7,
                    margin: EdgeInsetsDirectional.only(start: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
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
