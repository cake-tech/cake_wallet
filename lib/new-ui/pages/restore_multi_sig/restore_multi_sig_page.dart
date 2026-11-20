import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/restore_multi_sig/multi_sig_options_page.dart";
import "package:cake_wallet/new-ui/pages/restore_multi_sig/multi_sig_signers_page.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_multi_sig/restore_multi_sig_bloc.dart";
import "package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cw_core/multisig/multisig_config.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class RestoreMultiSigPage extends BasePage {
  RestoreMultiSigPage();

  @override
  String get title => S.current.multisig_wallet;

  @override
  Widget body(BuildContext context) => SafeArea(
        child: BlocProvider(
          create: (_) => RestoreMultiSigBloc(),
          child: BlocBuilder<RestoreMultiSigBloc, RestoreMultiSigState>(
            builder: (_, state) {
              final content = switch (state) {
                RestoreMultiSigInitial() => const MultiSigOptionsPage(key: ValueKey(0)),
                RestoreMultiSigConnectSigners(
                  walletName: final String _,
                  threshold: final int _,
                  :final int signers,
                  :final List<MultisigSigner> connectedSigners,
                ) =>
                  MultiSigSignersPage(
                    key: const ValueKey(1),
                    totalSigners: signers,
                    connectedSigners: connectedSigners.map((e) => e.hardwareWalletType).toList(),
                  ),
              };

              return DirectionalAnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: content,
              );
            },
          ),
        ),
      );
}
