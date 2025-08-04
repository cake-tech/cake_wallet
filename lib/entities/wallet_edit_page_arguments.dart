import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';

class WalletEditPageArguments {
  WalletEditPageArguments({
    required this.editingWallet,
    this.isWalletGroup = false,
    this.walletListViewModel,
    this.groupName = '',
    this.walletGroupKey = '',
    this.walletEditViewModel,
    this.walletNewVM,
    this.authService,
  });

  final WalletListItem editingWallet;
  final bool isWalletGroup;
  final String groupName;
  final String walletGroupKey;
  final WalletListViewModel? walletListViewModel;

  final WalletEditViewModel? walletEditViewModel;
  final WalletNewVM? walletNewVM;
  final AuthService? authService;
}
