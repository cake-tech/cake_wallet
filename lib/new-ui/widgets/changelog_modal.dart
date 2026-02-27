import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

const changelogIconLocation = "assets/new-ui/changelog/icons";
const changelogTextLocation = "assets/new-ui/changelog/text";

class ChangelogItem {
  final String iconFilename;
  final String title;
  final String description;

  ChangelogItem(this.iconFilename, this.title, this.description);
}

class ChangelogModal extends StatefulWidget {
  const ChangelogModal({super.key, required this.version});

  final String version;

  @override
  State<ChangelogModal> createState() => _ChangelogModalState();
}

class _ChangelogModalState extends State<ChangelogModal> {
  List<ChangelogItem> _items = [];

  @override
  void initState() {
    super.initState();
    loadChangelog();
  }

  void loadChangelog() async {
    String lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (lang == "und" ||
        lang.isEmpty ||
        !(await File("$changelogTextLocation/changelog_$lang.json").exists())) {
      lang = "en";
    }

    final List<dynamic> changelog =
        jsonDecode(await rootBundle.loadString("$changelogTextLocation/changelog_$lang.json"))
            as List<dynamic>;

    for (final item in changelog) {
      final itemMap = item as Map<String, dynamic>;
      _items.add(ChangelogItem(
        itemMap["icon"] as String? ?? "",
        itemMap["title"] as String? ?? "",
        itemMap["description"] as String? ?? "",
      ));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            SizedBox(),
            ModalTopBar(title: S.of(context).whats_new),
            SizedBox(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    VersionNumberHeader(version: widget.version),
                    SizedBox(height: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 32,
                      children: _items.map((item) => ChangelogItemWidget(item: item)).toList(),
                    ),
                    SizedBox(height: 32),
                    Text(
                      S.of(context).and_much_more_to_come,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 12,
                children: [
                  NewPrimaryButton(
                      onPressed: () {
                        try {
                            launchUrl(Uri.https("blog.cakewallet.com"));
                        } catch (_) {}
                      },
                      text: S.of(context).view_more_info,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.primary),
                  NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class VersionNumberHeader extends StatelessWidget {
  VersionNumberHeader({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(99999999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              "assets/images/cake_logo_dark.svg",
              height: 32,
              width: 32,
              colorFilter:
                  ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
            ),
            Text(
              version,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 36),
            )
          ],
        ),
      ),
    );
  }
}

class ChangelogItemWidget extends StatelessWidget {
  const ChangelogItemWidget({super.key, required this.item});

  final ChangelogItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        if (item.iconFilename.isNotEmpty)
          SvgPicture.asset(
            "$changelogIconLocation/${item.iconFilename}.svg",
            height: 36,
            width: 36,
            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            if (item.title.isNotEmpty)
              Text(
                item.title,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            if (item.description.isNotEmpty)
              Text(item.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ))
          ],
        )
      ],
    );
  }
}
