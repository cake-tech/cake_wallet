import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'support_view_model.g.dart';

class SupportViewModel = SupportViewModelBase with _$SupportViewModel;

abstract class SupportViewModelBase with Store {
  SupportViewModelBase() {
    items = [
      RegularListItem(
        title: S.current.faq,
        handler: (BuildContext context) async {
          if (await canLaunch(url)) await launch(url);
        },
      ),
      LinkListItem(
          title: 'Email',
          linkTitle: 'support@cakewallet.com',
          link: 'mailto:support@cakewallet.com'),
      LinkListItem(
          title: 'Telegram',
          icon: 'assets/images/Telegram.png',
          linkTitle: '@cakewallet_bot',
          link: 'https:t.me/cakewallet_bot'),
      LinkListItem(
          title: 'Twitter',
          icon: 'assets/images/Twitter.png',
          linkTitle: '@cakewallet',
          link: 'https://twitter.com/cakewallet'),
      LinkListItem(
          title: 'ChangeNow',
          icon: 'assets/images/change_now.png',
          linkTitle: 'support@changenow.io',
          link: 'mailto:support@changenow.io'),
      LinkListItem(
          title: 'SideShift.ai',
          icon: 'assets/images/sideshift_icon.png',
          linkTitle: 'help@sideshift.ai',
          link: 'mailto:help@sideshift.ai'),
      LinkListItem(
          title: 'Wyre',
          icon: 'assets/images/wyre.png',
          linkTitle: S.current.submit_request,
          link: 'https://wyre-support.zendesk.com/hc/en-us/requests/new')
    ];
  }
  static const url = 'https://cakewallet.com/guide/';

  List<SettingsListItem> items;
}