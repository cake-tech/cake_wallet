import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/monero/monero_subaddress_list.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'dart:convert';
import 'package:cake_wallet/store/yat/yat_exception.dart';
import 'package:http/http.dart';

part 'yat_store.g.dart';

class YatLink {
  static const baseDevUrl = 'https://yat.fyi';
  static const baseReleaseUrl = 'https://y.at';
  static const signInSuffix = '/partner/CW/link-email';
  static const createSuffix = '/create';
  static const queryParameter = '?addresses=';
  static const requestDevUrl = 'https://a.yat.fyi/emoji_id/';
  static const requestReleaseUrl = 'https://a.y.at/emoji_id/';
  static const isDevMode = true;
  static const tags = <String, List<String>>{"XMR" : ['0x1001', '0x1002'],
    "BTC" : ['0x1003'], "LTC" : ['0x3fff']};
}

Future<List<String>> fetchYatAddress(String emojiId, String ticker) async {
  final requestURL = YatLink.isDevMode
      ? YatLink.requestDevUrl
      : YatLink.requestReleaseUrl;
  final url = requestURL + emojiId;
  final response = await get(url);

  if (response.statusCode != 200) {
    throw YatException(text: response.body.toString());
  }

  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  final result = responseJSON['result'] as List<dynamic>;

  if (result?.isEmpty ?? true) {
    return [];
  }

  final List<String> addresses = [];
  final currency = ticker.toUpperCase();

  for (var elem in result) {
    final tag = elem['tag'] as String;
    if (tag?.isEmpty ?? true) {
      continue;
    }
    if (YatLink.tags[currency]?.contains(tag) ?? false) {
      final yatAddress = elem['data'] as String;
      if (yatAddress?.isNotEmpty ?? false) {
        addresses.add(yatAddress);
      }
    }
  }

  return addresses;
}

class YatStore = YatStoreBase with _$YatStore;

abstract class YatStoreBase with Store {
  YatStoreBase({@required this.appStore}) {
    _wallet ??= appStore.wallet;
    emoji = _wallet?.walletInfo?.yatEmojiId ?? '';
    refreshToken = _wallet?.walletInfo?.yatToken ?? '';
    reaction((_) => appStore.wallet, _onWalletChange);
    reaction((_) => emoji, (String emoji) => _onEmojiChange());
  }

  AppStore appStore;

  @observable
  String emoji;

  @observable
  String refreshToken;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
  _wallet;

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
          TransactionInfo>
      wallet) {
    this._wallet = wallet;
    emoji = wallet?.walletInfo?.yatEmojiId ?? '';
    refreshToken = wallet?.walletInfo?.yatToken ?? '';
  }

  @action
  void _onEmojiChange() {
    try {
      final walletInfo = _wallet.walletInfo;

      if (walletInfo == null) {
        return;
      }

      walletInfo.yatEid = emoji;
      walletInfo.yatRefreshToken = refreshToken;

      if (walletInfo.isInBox) {
        walletInfo.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  String defineQueryParameters() {
    String parameters = '';
    switch (_wallet.type) {
      case WalletType.monero:
        final wallet = _wallet as MoneroWallet;
        final subaddressList = MoneroSubaddressList();
        var isFirstAddress = true;

        wallet.walletAddresses.accountList.accounts.forEach((account) {
          subaddressList.update(accountIndex: account.id);
          subaddressList.subaddresses.forEach((subaddress) {
            if (!isFirstAddress) {
              parameters += '%7C';
            } else {
              isFirstAddress = !isFirstAddress;
            }

            parameters += subaddress.address.startsWith('4')
                ? YatLink.tags["XMR"].first + '%3D'
                : YatLink.tags["XMR"].last + '%3D';

            parameters += subaddress.address;
          });
        });
        break;
      case WalletType.bitcoin:
        final wallet = _wallet as ElectrumWallet;
        var isFirstAddress = true;

        wallet.walletAddresses.addresses.forEach((record) {
          if (!isFirstAddress) {
            parameters += '%7C';
          } else {
            isFirstAddress = !isFirstAddress;
          }

          parameters += YatLink.tags["BTC"].first + '%3D' + record.address;
        });
        break;
      case WalletType.litecoin:
        final wallet = _wallet as ElectrumWallet;
        var isFirstAddress = true;

        wallet.walletAddresses.addresses.forEach((record) {
          if (!isFirstAddress) {
            parameters += '%7C';
          } else {
            isFirstAddress = !isFirstAddress;
          }

          parameters += YatLink.tags["LTC"].first + '%3D' + record.address;
        });
        break;
      default:
        parameters = '';
    }
    return parameters;
  }
}