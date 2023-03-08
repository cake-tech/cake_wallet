import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

part 'support_view_model.g.dart';

class SupportViewModel = SupportViewModelBase with _$SupportViewModel;

abstract class SupportViewModelBase with Store {
  SupportViewModelBase()
  : items = [
      RegularListItem(
        title: S.current.faq,
        handler: (BuildContext context) async {
          try {
            await launch(url);
          } catch (e) {}
        },
      ),
      LinkListItem(
          title: 'Email',
          linkTitle: 'support@cakewallet.com',
          link: 'mailto:support@cakewallet.com'),
      if (!isMoneroOnly)
        LinkListItem(
            title: 'Website',
            linkTitle: 'cakewallet.com',
            link: 'https://cakewallet.com'),
      if (!isMoneroOnly)      
        LinkListItem(
            title: 'GitHub',
            icon: 'assets/images/github.png',
            hasIconColor: true,
            linkTitle: S.current.apk_update,
            link: 'https://github.com/cake-tech/cake_wallet/releases'),
      LinkListItem(
          title: 'Telegram',
          icon: 'assets/images/Telegram.png',
          linkTitle: '@cakewallet_bot',
          link: 'https://t.me/cakewallet_bot'),
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
        title: 'SideShift',
        icon: 'assets/images/sideshift.png',
        linkTitle: S.current.help,
        link: 'https://help.sideshift.ai/en/'),
    LinkListItem(
        title: 'SimpleSwap',
        icon: 'assets/images/simpleSwap.png',
        linkTitle: 'support@simpleswap.io',
        link: 'mailto:support@simpleswap.io'),
      if (!isMoneroOnly) ... [    
         LinkListItem(
     title: 'Wyre',
             icon: 'assets/images/wyre.png',
             linkTitle: S.current.submit_request,
             link: 'https://wyre-support.zendesk.com/hc/en-us/requests/new'),
   LinkListItem(
     title: 'MoonPay',
             icon: 'assets/images/moonpay.png',
             hasIconColor: true,
             linkTitle: S.current.submit_request,
             link: 'https://support.moonpay.com/hc/en-gb/requests/new')
    ]
      //LinkListItem(
      //    title: 'Yat',
      //    icon: 'assets/images/yat_mini_logo.png',
      //    hasIconColor: true,
      //    linkTitle: 'support@y.at',
      //    link: 'mailto:support@y.at')
  ];

  static const url = 'https://guides.cakewallet.com';

  List<SettingsListItem> items;
}