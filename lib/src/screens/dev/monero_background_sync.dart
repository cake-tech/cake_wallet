import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dev/monero_background_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DevMoneroBackgroundSyncPage extends BasePage {
  final DevMoneroBackgroundSync viewModel;

  DevMoneroBackgroundSyncPage(this.viewModel);

  @override
  String? get title => "[dev] xmr background sync";

  Widget _buildSingleCell(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 25/9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSingleCell('Height (local)', viewModel.localBlockHeight ?? ''),
            _buildSingleCell('Height (node)', viewModel.nodeBlockHeight ?? ''),
            _buildSingleCell('Time', viewModel.tick.toString()),
            _buildSingleCell('Background Sync', viewModel.isBackgroundSyncing ? 'Enabled' : 'Disabled'),
            _buildSingleCell('Public View Key', viewModel.publicViewKey ?? ''),
            _buildSingleCell('Private View Key', viewModel.privateViewKey ?? ''),
            _buildSingleCell('Public Spend Key', viewModel.publicSpendKey ?? ''),
            _buildSingleCell('Private Spend Key', viewModel.privateSpendKey ?? ''),
            _buildSingleCell('Primary Address', viewModel.primaryAddress ?? ''),
            _buildSingleCell('Passphrase', viewModel.passphrase ?? ''),
            _buildSingleCell('Seed', viewModel.seed ?? ''),
            _buildSingleCell('Seed Legacy', viewModel.seedLegacy ?? ''),
            _enableBackgroundSyncButton(),
            _disableBackgroundSyncButton(),
            _refreshButton(),
            _manualRescanButton(),
          ],
        );
      },
    );
  }

  PrimaryButton _enableBackgroundSyncButton() {
    return PrimaryButton(
      text: "Enable background sync",
      color: Colors.purple,
      textColor: Colors.white,
      onPressed: () {
        viewModel.startBackgroundSync();
      },
    );
  }

  PrimaryButton _disableBackgroundSyncButton() {
    return PrimaryButton(
      text: "Disable background sync",
      color: Colors.purple,
      textColor: Colors.white,
      onPressed: () {
        viewModel.stopBackgroundSync();
      },
    );
  }

  PrimaryButton _refreshButton() {
    return PrimaryButton(
      text: viewModel.refreshTimer == null ? "Enable refresh" : "Disable refresh",
      color: Colors.purple,
      textColor: Colors.white,
      onPressed: () {
        if (viewModel.refreshTimer == null) {
          viewModel.startRefreshTimer();
        } else {
          viewModel.stopRefreshTimer();
        }
      },
    );
  }

  PrimaryButton _manualRescanButton() {
    return PrimaryButton(
      text: "Manual rescan",
      color: Colors.purple,
      textColor: Colors.white,
      onPressed: () {
        viewModel.manualRescan();
      },
    );
  }
}
