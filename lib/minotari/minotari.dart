import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_minotari/minotari_amount_format.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_wallet_service.dart';
import 'package:cw_minotari/pending_minotari_transaction.dart';

part 'cw_minotari.dart';

Minotari? minotari = CWMinotari();

abstract class Minotari {
  WalletService createMinotariWalletService();

  WalletCredentials createMinotariNewWalletCredentials({
    required String name,
    String? password,
    String? passphrase,
    WalletInfo? walletInfo,
  });

  WalletCredentials createMinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    required int height,
    String? passphrase,
    WalletInfo? walletInfo,
  });

  double? getMinotariEstimatedFee(Object wallet);

  Object createMinotariTransactionCredentials(List<Output> outputs);

  Object createMinotariTransactionCredentialsRaw(List<OutputInfo> outputs);

  int getHeightByDate({required DateTime date});
  Future<int> getCurrentHeight();

  Map<String, String> getKeys(Object wallet);
  int? getRestoreHeight(Object wallet);

  String formatterMinotariAmountToString({required int amount});
  double formatterMinotariAmountToDouble({required int amount});
  int formatterMinotariParseAmount({required String amount});
}
