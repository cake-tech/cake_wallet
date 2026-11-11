import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/hash_wallet_identifier.dart";
import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/services/wallet_pool_service.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class DevRunWithWalletPlaygroundPage extends BasePage {
  DevRunWithWalletPlaygroundPage(this.walletPoolService);

  final WalletPoolService walletPoolService;

  @override
  String? get title => "[dev] runWithWallet playground";

  @override
  Widget body(BuildContext context) => _Playground(walletPoolService: walletPoolService);
}

class _Playground extends StatefulWidget {
  const _Playground({required this.walletPoolService});

  final WalletPoolService walletPoolService;

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  var _wallets = WalletInfo.getAll();
  final Map<WalletKey, WalletHold> _holds = {};
  final Set<WalletKey> _pending = {};
  String _text = "";
  String? _stressProgress;
  String? _holdAllProgress;

  bool get _busy => _stressProgress != null || _holdAllProgress != null;

  Future<void> _holdAll() async {
    final wallets = await WalletInfo.getAll();

    for (final (index, walletInfo) in wallets.indexed) {
      if (!mounted) return;
      if (_holds.containsKey(walletInfo.key) || _pending.contains(walletInfo.key)) continue;

      setState(() => _holdAllProgress = "${index + 1}/${wallets.length} ${walletInfo.name}");
      await _toggleHold(walletInfo, true);
    }

    if (mounted) setState(() => _holdAllProgress = null);
  }

  Future<void> _createStressWallets() async {
    final run = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final plan = [
      for (final type in [WalletType.bitcoin, WalletType.monero, WalletType.ethereum])
        for (var i = 1; i <= 20; i++) (type, "stress $run ${walletTypeToString(type)} $i"),
    ];

    for (final (index, (type, name)) in plan.indexed) {
      if (!mounted) return;
      setState(() => _stressProgress = "${index + 1}/${plan.length} $name");

      try {
        final wallet = await _createWallet(type, name);
        // the pool can't adopt an open instance from here, so let it reopen the wallet itself
        await wallet.close();

        final hold = await widget.walletPoolService.hold(wallet.key);
        if (!mounted) {
          await hold.release();
          return;
        }
        _holds[wallet.key] = hold;
      } catch (e) {
        _text += "$name: <stress create failed: $e>\n\n";
      }

      if (mounted) setState(() {
        _wallets = WalletInfo.getAll();
      });
    }

    if (mounted) setState(() => _stressProgress = null);
  }

  Future<WalletBase> _createWallet(WalletType type, String name) async {
    final credentials = switch (type) {
      WalletType.bitcoin => bitcoin!.createBitcoinNewWalletCredentials(name: name),
      WalletType.monero => monero!.createMoneroNewWalletCredentials(
          name: name,
          language: "English",
          seedType: MoneroSeedType.polyseed.raw,
          passphrase: null,
        ),
      _ => evm!.createEVMNewWalletCredentials(name: name),
    };

    // electrum_derivations is shared and save() writes its id back, so save a copy per wallet
    final electrum = bitcoin!.getElectrumDerivations()[DerivationType.electrum]!.first;
    final derivationInfo = type == WalletType.bitcoin
        ? DerivationInfo(
            derivationType: electrum.derivationType,
            derivationPath: electrum.derivationPath,
            scriptType: electrum.scriptType,
            description: electrum.description,
          )
        : DerivationInfo(derivationType: DerivationType.unknown);

    credentials.derivationInfo = derivationInfo;
    credentials.walletInfo = WalletInfo.external(
      id: WalletBase.idFor(name, type),
      name: name,
      type: type,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime.now(),
      dirPath: await pathForWalletDir(name: name, type: type),
      path: await pathForWallet(name: name, type: type),
      address: "",
      showIntroCakePayCard: false,
      derivationInfoId: await derivationInfo.save(),
    );

    final wallet = await getIt.get<WalletCreationService>(param1: type).create(credentials);
    credentials.walletInfo!.hashedWalletIdentifier = createHashedWalletIdentifier(wallet);
    credentials.walletInfo!.address = wallet.walletAddresses.address;
    await credentials.walletInfo!.save();
    await wallet.save();
    return wallet;
  }

  Future<void> _appendSeed(WalletInfo walletInfo) async {
    String seed;
    try {
      seed = await widget.walletPoolService
          .runWithWallet(walletInfo.key, (wallet) async => wallet.seed ?? "<no seed>");
    } catch (e) {
      seed = "<error: $e>";
    }

    if (mounted) setState(() => _text += "${walletInfo.name}: $seed\n\n");
  }

  Future<void> _toggleHold(WalletInfo walletInfo, bool held) async {
    final key = walletInfo.key;
    setState(() => _pending.add(key));

    var line = "";
    try {
      if (held) {
        _holds[key] = await widget.walletPoolService.hold(key);
      } else {
        await _holds.remove(key)?.release();
      }
    } catch (e) {
      line = "${walletInfo.name}: <hold failed: $e>\n\n";
    }

    if (!mounted) {
      await _holds.remove(key)?.release();
      return;
    }

    setState(() {
      _pending.remove(key);
      _text += line;
    });
  }

  @override
  void dispose() {
    for (final hold in _holds.values) {
      unawaited(hold.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<WalletInfo>>(
        future: _wallets,
        builder: (context, snapshot) => ListView(
          controller: ModalScrollController.of(context),
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton(
              onPressed: _busy ? null : _createStressWallets,
              child: Text(
                _stressProgress == null ? "create wallets for stress test" : "creating $_stressProgress",
              ),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _holdAll,
              child: Text(
                _holdAllProgress == null ? "hold all wallets" : "holding $_holdAllProgress",
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _text.isEmpty ? "tap a wallet to append its seed, toggle to hold or release it" : _text,
            ),
            const Divider(),
            for (final walletInfo in snapshot.data ?? <WalletInfo>[])
              ListTile(
                title: Text(walletInfo.name),
                subtitle: Text(walletTypeToString(walletInfo.type)),
                onTap: () => _appendSeed(walletInfo),
                trailing: Switch(
                  value: _holds.containsKey(walletInfo.key),
                  onChanged: _pending.contains(walletInfo.key)
                      ? null
                      : (held) => _toggleHold(walletInfo, held),
                ),
              ),
          ],
        ),
      );
}
