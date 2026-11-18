import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';

class WalletEditPageArguments {
  WalletEditPageArguments({
    required this.editingWallet,
    this.isWalletGroup = false,
    this.isSingleWalletGroup = false,
    this.walletListViewModel,
    this.groupName = '',
    this.walletGroupKey = '',
    this.walletEditViewModel,
    this.authService,
  });

  final WalletListItem editingWallet;

  final bool isWalletGroup;
  final bool isSingleWalletGroup;

  final String groupName;
  final String walletGroupKey;
  final WalletListViewModel? walletListViewModel;

  final WalletEditViewModel? walletEditViewModel;
  final AuthService? authService;
}
