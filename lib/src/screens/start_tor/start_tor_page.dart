import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/start_tor_view_model.dart';

class StartTorPage extends BasePage {
  StartTorPage(this.startTorViewModel);

  final StartTorViewModel startTorViewModel;

  @override
  String get title => S.current.tor_connection;

  @override
  Widget leading(BuildContext context) {
    return Container();
  }

  @override
  Widget body(BuildContext context) {
    startTorViewModel.startTor(context);
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              SizedBox(width: double.maxFinite),
              if (startTorViewModel.isLoading) ...[
                CircularProgressIndicator(),
                SizedBox(height: 20),
                _buildWaitingText(context),
                ],
              if (startTorViewModel.showOptions) ...[
                _buildOptionsButtons(context),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingText(BuildContext context) {
    return Observer(
      builder: (_) {
        return Column(
          children: [
            Text(
              S.current.establishing_tor_connection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (startTorViewModel.showOptions) _buildOptionsButtons(context),
          ],
        );
      },
    );
  }

  Widget _buildOptionsButtons(BuildContext context) {
    return Column(
      children: [
        Text(
          S.current.tor_connection_timeout,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        PrimaryButton(
          onPressed: () => startTorViewModel.disableTor(context),
          text: S.current.disable_tor,
          color: Theme.of(context).colorScheme.primary,
          textColor: Colors.white,
        ),
        SizedBox(height: 16),
        PrimaryButton(
          onPressed: () => startTorViewModel.ignoreAndLaunchApp(context),
          text: S.current.ignor,
          color: Theme.of(context).colorScheme.secondary,
          textColor: Colors.white,
        ),
      ],
    );
  }
} 