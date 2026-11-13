import 'dart:io';

import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/seedphrase_grid_widget.dart';
import 'package:cake_wallet/src/widgets/warning_box_widget.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:file_picker/file_picker.dart";
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';

class WalletSeedPage extends BasePage {
  WalletSeedPage(this.walletSeedViewModel, {required this.isNewWalletCreated});

  @override
  String get title =>
      '${walletTypeToString(walletSeedViewModel.walletType)} ${S.current.seed_title}';

  final bool isNewWalletCreated;
  final WalletSeedViewModel walletSeedViewModel;

  @override
  Widget trailing(BuildContext context) {
    return isNewWalletCreated
        ? GestureDetector(
            key: ValueKey('wallet_seed_page_copy_seeds_button_key'),
            onTap: () {
              if (!walletSeedViewModel.hasSeed) return;
              ClipboardUtil.setSensitiveDataToClipboard(
                ClipboardData(text: walletSeedViewModel.seed),
              );
              showBar<void>(context, S.of(context).copied_to_clipboard);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              width: 40,
              alignment: Alignment.center,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Image.asset(
                'assets/images/copy_address.png',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : Offstage();
  }

  @override
  Widget body(BuildContext context) {
    return ClearSeedOnDispose(walletSeedViewModel,
        child: PopScope(
          //FIXME i can't figure out why this was here? it caused back gesture to break
          canPop: true,
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Observer(
                  builder: (_) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(height: 16),
                            WarningBox(content: S.current.cake_seeds_save_disclaimer),
                            SizedBox(height: 36),
                            Text(
                              key: ValueKey('wallet_seed_page_wallet_name_text_key'),
                              walletSeedViewModel.name,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            SizedBox(height: 24),
                            Expanded(
                              child: walletSeedViewModel.hasSeed
                                  ? SeedPhraseGridWidget(list: walletSeedViewModel.seedSplit)
                                  : SeedLoadState(walletSeedViewModel),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Observer(
                  builder: (_) => Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.only(right: 8.0, top: 8.0),
                                child: PrimaryButton(
                                  key: ValueKey('wallet_seed_page_save_seeds_button_key'),
                                  isDisabled: !walletSeedViewModel.hasSeed,
                                  onPressed: () {
                                    _shareSeed(context);
                                  },
                                  text: S.of(context).save,
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.only(left: 8.0, top: 8.0),
                                child: PrimaryButton(
                                  key: ValueKey('wallet_seed_page_verify_seed_button_key'),
                                  isDisabled: !walletSeedViewModel.hasSeed,
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    Routes.walletSeedVerificationPage,
                                    arguments: isNewWalletCreated,
                                  ),
                                  text: S.current.verify_phrase,
                                  color: Theme.of(context).colorScheme.primary,
                                  textColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  void _shareSeed(BuildContext context) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        ShareUtil.share(
          text: walletSeedViewModel.seed,
          context: context,
        );
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        final path = await FilePicker.platform.saveFile(
          dialogTitle: "Save seed as",
          fileName: "${walletSeedViewModel.name}-seed.txt",
          lockParentWindow: true,
        );
        if (path != null) {
          final file = File(path);
          await file.writeAsString(walletSeedViewModel.seed);
        }
      default:
        break;
    }
  }
}

/// Shown while a seed that loads after the page opens (Minotari) is on its way, or why it
/// failed with a retry.
class SeedLoadState extends StatelessWidget {
  const SeedLoadState(this.walletSeedViewModel);

  final WalletSeedViewModel walletSeedViewModel;

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final error = walletSeedViewModel.seedLoadError.value;
        if (error == null) return const Center(child: CircularProgressIndicator());

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: walletSeedViewModel.loadMinotariSeed,
              text: S.of(context).try_again,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        );
      });
}

/// Disposes [walletSeedViewModel] when the page closes, so its seed copy goes with it.
class ClearSeedOnDispose extends StatefulWidget {
  const ClearSeedOnDispose(this.walletSeedViewModel, {required this.child});

  final WalletSeedViewModel walletSeedViewModel;
  final Widget child;

  @override
  State<ClearSeedOnDispose> createState() => _ClearSeedOnDisposeState();
}

class _ClearSeedOnDisposeState extends State<ClearSeedOnDispose> {
  @override
  void dispose() {
    widget.walletSeedViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
