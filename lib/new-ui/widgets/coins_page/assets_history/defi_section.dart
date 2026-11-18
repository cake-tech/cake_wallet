import "package:cake_wallet/new-ui/widgets/everstake/everstake_defi_tile.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";

class DefiSection extends StatelessWidget {
  const DefiSection({super.key});

  static bool supportsWallet(WalletBase wallet) =>
      isEVMCompatibleChain(wallet.type) && wallet.chainId == 1 && !wallet.isHardwareWallet;

  @override
  Widget build(BuildContext context) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 64),
          child: EverstakeDefiTile(),
        ),
      );
}
