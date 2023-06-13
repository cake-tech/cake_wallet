import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../routes.dart';

class Modify2FAPage extends BasePage {
  Modify2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.modify_2fa;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: _2FAControlsWidget(setup2FAViewModel: setup2FAViewModel),
    );
  }
}

class _2FAControlsWidget extends StatefulWidget {
  const _2FAControlsWidget({
    required this.setup2FAViewModel,
  });

  final Setup2FAViewModel setup2FAViewModel;

  @override
  State<_2FAControlsWidget> createState() => _2FAControlsWidgetState();
}

class _2FAControlsWidgetState extends State<_2FAControlsWidget>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Setup2FAViewModel get viewModel => widget.setup2FAViewModel;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsCellWithArrow(
              title: S.current.disable_cake_2fa,
              handler: (_) async {
                await showPopUp<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithTwoActions(
                      alertTitle: S.current.disable_cake_2fa,
                      alertContent: S.current.question_to_disable_2fa,
                      leftButtonText: S.current.cancel,
                      rightButtonText: S.current.disable,
                      actionLeftButton: () {
                        Navigator.of(context).pop();
                      },
                      actionRightButton: () {
                      widget.setup2FAViewModel.setUseTOTP2FA(false);
                        Navigator.pushNamedAndRemoveUntil(
                            context, Routes.dashboard, (route) => false);
                      },
                    );
                  },
                );
            },
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Cake 2FA Preset'),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Color(0xffF2F0FA),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Theme(
              data: ThemeData(
                  primaryTextTheme: TextTheme(
                      bodyLarge:
                          TextStyle(backgroundColor: Colors.transparent))),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: Theme.of(context).accentTextTheme.bodyLarge!.color!,
                ),
                labelColor: Theme.of(context)
                    .primaryTextTheme
                    .displayLarge!
                    .backgroundColor!,
                unselectedLabelColor: Theme.of(context)
                    .primaryTextTheme
                    .displayLarge!
                    .backgroundColor!,
                tabs: [
                  Tab(
                    text: 'Narrow',
                    height: 30,
                  ),
                  Tab(
                    text: 'Normal',
                    height: 30,
                  ),
                  Tab(
                    text: 'Verbose',
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
          SettingsSwitcherCell(
              title: 'Require for accessing wallet',
              value: viewModel.shouldRequireTOTP2FAForAccessingWallet,
              onValueChange: (context, value) async => viewModel
                  .switchShouldRequireTOTP2FAForAccessingWallet(value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
              title: 'Require for sends to non-contacts',
              value: viewModel.shouldRequireTOTP2FAForSendsToNonContact,
              onValueChange: (context, value) async => viewModel
                  .switchShouldRequireTOTP2FAForSendsToNonContact(value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
              title: 'Require for sends to contacts',
              value: viewModel.shouldRequireTOTP2FAForSendsToContact,
              onValueChange: (context, value) async =>
                  viewModel.switchShouldRequireTOTP2FAForSendsToContact(value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
              title: 'Require for sends to internal wallets',
              value: viewModel.shouldRequireTOTP2FAForSendsToInternalWallets,
              onValueChange: (context, value) async => viewModel
                  .switchShouldRequireTOTP2FAForSendsToInternalWallets(value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
              title: 'Require for exchanges to internal wallets',
              value:
                  viewModel.shouldRequireTOTP2FAForExchangesToInternalWallets,
              onValueChange: (context, value) async => viewModel
                  .switchShouldRequireTOTP2FAForExchangesToInternalWallets(
                      value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
              title: 'Require for adding contacts',
              value: viewModel.shouldRequireTOTP2FAForAddingContacts,
              onValueChange: (context, value) async =>
                  viewModel.switchShouldRequireTOTP2FAForAddingContacts(value)),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
            title: 'Require for creating new wallets',
            value: viewModel.shouldRequireTOTP2FAForCreatingNewWallets,
            onValueChange: (context, value) async =>
                viewModel.switchShouldRequireTOTP2FAForCreatingNewWallet(value),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsSwitcherCell(
            title: 'Require for all security and backup settings',
            value:
                viewModel.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
            onValueChange: (context, value) async => viewModel
                .switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(
                    value),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        ],
      );
    }
    );
  }
}
