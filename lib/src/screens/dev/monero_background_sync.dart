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

  Widget _buildSingleCell(String title, String value, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
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
          childAspectRatio: 25 / 9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSingleCell('Height (local)', viewModel.localBlockHeight ?? '', context),
            _buildSingleCell('Height (node)', viewModel.nodeBlockHeight ?? '', context),
            _buildSingleCell('Time', viewModel.tick.toString(), context),
            _buildSingleCell(
                'Background Sync', viewModel.isBackgroundSyncing ? 'Enabled' : 'Disabled', context),
            _buildSingleCell('Public View Key', viewModel.publicViewKey ?? '', context),
            _buildSingleCell('Private View Key', viewModel.privateViewKey ?? '', context),
            _buildSingleCell('Public Spend Key', viewModel.publicSpendKey ?? '', context),
            _buildSingleCell('Private Spend Key', viewModel.privateSpendKey ?? '', context),
            _buildSingleCell('Primary Address', viewModel.primaryAddress ?? '', context),
            _buildSingleCell('Passphrase', viewModel.passphrase ?? '', context),
            _buildSingleCell('Seed', viewModel.seed ?? '', context),
            _buildSingleCell('Seed Legacy', viewModel.seedLegacy ?? '', context),
            _enableBackgroundSyncButton(context),
            _disableBackgroundSyncButton(context),
            _refreshButton(context),
            _manualRescanButton(context),
          ],
        );
      },
    );
  }

  PrimaryButton _enableBackgroundSyncButton(BuildContext context) {
    return PrimaryButton(
      text: "Enable background sync",
      color: Colors.purple,
      textColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () {
        viewModel.startBackgroundSync();
      },
    );
  }

  PrimaryButton _disableBackgroundSyncButton(BuildContext context) {
    return PrimaryButton(
      text: "Disable background sync",
      color: Colors.purple,
      textColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () {
        viewModel.stopBackgroundSync();
      },
    );
  }

  PrimaryButton _refreshButton(BuildContext context) {
    return PrimaryButton(
      text: viewModel.refreshTimer == null ? "Enable refresh" : "Disable refresh",
      color: Colors.purple,
      textColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () {
        if (viewModel.refreshTimer == null) {
          viewModel.startRefreshTimer();
        } else {
          viewModel.stopRefreshTimer();
        }
      },
    );
  }

  PrimaryButton _manualRescanButton(BuildContext context) {
    return PrimaryButton(
      text: "Manual rescan",
      color: Colors.purple,
      textColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () {
        viewModel.manualRescan();
      },
    );
  }
}
