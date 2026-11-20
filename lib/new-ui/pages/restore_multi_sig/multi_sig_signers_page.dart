import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_multi_sig/restore_multi_sig_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/screens/connect_device/select_device_manufacturer_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MultiSigSignersPage extends StatelessWidget {
  const MultiSigSignersPage({
    this.totalSigners = 3,
    this.connectedSigners = const [],
    super.key,
  });

  final int totalSigners;
  final List<HardwareWalletType> connectedSigners;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                spacing: 32,
                children: [
                  _CollectedProgress(collected: connectedSigners.length, total: totalSigners),
                  Column(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < totalSigners; i++)
                        _SignerRow(
                          key: ValueKey("multi_sig_signers_page_signer_${i}_row_key"),
                          index: i + 1,
                          hardwareWalletType: connectedSigners.elementAtOrNull(i),
                          onPressed: () async {
                            final provider = await Navigator.of(context).push<HardwareWalletType?>(
                              MaterialPageRoute(
                                builder: (context) => SelectDeviceManufacturerPage(
                                  onSelect: Navigator.pop,
                                  showUnavailable: false,
                                  availableHardwareWalletTypes: [
                                    HardwareWalletType.ledger,
                                    HardwareWalletType.bitbox,
                                    HardwareWalletType.trezor,
                                  ],
                                ),
                              ),
                            );

                            if (provider == null || !context.mounted) {
                              return;
                            }

                            HardwareAccountData? account;
                            await Navigator.of(context).pushNamed(
                              Routes.connectDevices,
                              arguments: ConnectDevicePageParams(
                                walletType: WalletType.bitcoin,
                                hardwareWalletType: provider,
                                onConnectDevice: (context, hwwVM) async {
                                  final service =
                                      hwwVM.getHardwareWalletService(WalletType.bitcoin);
                                  account = (await service.getAvailableAccounts(index: 0, limit: 1))
                                      .first;
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                isReconnect: false,
                              ),
                            );

                            if (account != null && context.mounted) {
                              context
                                  .read<RestoreMultiSigBloc>()
                                  .add(ConnectSigner(account!.multisigSigner));
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: NewPrimaryButton(
              key: const ValueKey("multi_sig_signers_page_next_button_key"),
              onPressed: () {},
              text: S.of(context).seed_language_next,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              disabled: connectedSigners.length < totalSigners,
            ),
          ),
        ],
      );
}

class _CollectedProgress extends StatelessWidget {
  const _CollectedProgress({required this.collected, required this.total});

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 16,
        children: [
          Text(
            "$collected / $total",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            spacing: 6,
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < collected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            S.of(context).connect_your_hardware_wallet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
}

class _SignerRow extends StatelessWidget {
  const _SignerRow({
    required this.index,
    required this.onPressed,
    this.hardwareWalletType,
    super.key,
  });

  final int index;
  final HardwareWalletType? hardwareWalletType;
  final VoidCallback onPressed;

  String get deviceTileLeading {
    switch (hardwareWalletType) {
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.bitbox:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_7.svg";

      default:
        return "assets/new-ui/hardware_wallet.svg";
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: CakeImageWidget(
                    imageUrl: deviceTileLeading,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        "${S.of(context).hardware_wallet} $index",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        hardwareWalletType?.toString() ?? S.of(context).not_connected,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                CakeImageWidget(
                  imageUrl: "assets/new-ui/arrow_right.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
