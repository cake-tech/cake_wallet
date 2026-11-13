import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_address_kind.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_entry.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

const _accountWalletTypes = [WalletType.monero, WalletType.wownero, WalletType.haven];

String _translateLabel(String label) => label
    .replaceAll(RegExp(r"active", caseSensitive: false), S.current.active)
    .replaceAll(RegExp(r"silent payments", caseSensitive: false), S.current.silent_payments);

Future<List<WalletContactEntry>> loadWalletContactEntries(WalletInfo info) async {
  if (!info.isReady) return const [];

  final entries = <WalletContactEntry>[];
  void add(String address, CryptoCurrency currency,
      {String label = "",
      String displayLabel = "",
      int? accountIndex,
      WalletAddressKind? addressKind}) {
    if (address.isEmpty) return;
    entries.add(WalletContactEntry(
      walletId: info.id,
      walletName: info.name,
      walletType: info.type,
      address: address,
      currency: currency,
      label: label,
      displayLabel: displayLabel,
      accountIndex: accountIndex,
      addressKind: addressKind,
    ));
  }

  final addressInfos = await info.getAddressInfos();
  final addresses = await info.getAddresses();
  final currency = getCryptoCurrencyForWalletListItem(info.type);

  if (_accountWalletTypes.contains(info.type) && addressInfos.isNotEmpty) {
    final keys = addressInfos.keys.toList()..sort();
    for (final key in keys) {
      final values = addressInfos[key];
      if (values == null || values.isEmpty) continue;
      final first = values.first;
      add(first.address, currency, displayLabel: _translateLabel(first.label), accountIndex: key);
    }
  } else if (addresses.length > 1) {
    if ([..._accountWalletTypes, WalletType.decred].contains(info.type)) {
      add(info.address, currency, accountIndex: _accountWalletTypes.contains(info.type) ? 0 : null);
    } else {
      final isTestnet = info.network?.toLowerCase().contains("testnet") ?? false;
      final labelledCurrency = getCryptoCurrencyForWalletListItem(info.type, isTestnet: isTestnet);
      addresses.forEach((address, label) {
        if (label.isEmpty) return;
        final kind = _addressKind(address, label, info.type);
        if (kind == WalletAddressKind.lightning) {
          // Lightning (Breez) is mainnet-only, even for testnet BTC wallets.
          if (isTestnet) return;
          add(address, CryptoCurrency.btcln,
              label: label, displayLabel: _translateLabel(label), addressKind: kind);
          return;
        }
        add(address, labelledCurrency,
            label: label, displayLabel: _translateLabel(label), addressKind: kind);
      });
    }
  } else if (!_isNotAnOnChainAddress(info.address)) {
    add(info.address, currency, accountIndex: _accountWalletTypes.contains(info.type) ? 0 : null);
  }

  return entries;
}

WalletAddressKind? _addressKind(String address, String label, WalletType type) {
  final fromLabel = WalletAddressKind.fromLabelCode(label, type: type);
  if (fromLabel != null) return fromLabel;
  if (label == "Active" && (type == WalletType.bitcoin || type == WalletType.litecoin)) {
    return WalletAddressKind.fromAddressFormat(address);
  }
  return null;
}

bool _isNotAnOnChainAddress(String address) =>
    address.contains("@") || address.startsWith("Error:");

Future<List<WalletContact>> loadWalletContactsForWallet(
  WalletInfo info, {
  String? groupId,
  String? groupName,
}) async =>
    (await loadWalletContactEntries(info))
        .map((e) => e.toContact(groupId: groupId, groupName: groupName))
        .toList();
