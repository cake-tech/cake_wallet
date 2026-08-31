import "dart:async";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/entities/solana_nft_asset_model.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart";

part "nft_send_view_model.g.dart";

class NFTSendViewModel = NFTSendViewModelBase with _$NFTSendViewModel;

abstract class NFTSendViewModelBase with Store {
  NFTSendViewModelBase(this._appStore, this._contactListViewModel);

  final AppStore _appStore;
  final ContactListViewModel _contactListViewModel;

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  PendingTransaction? pendingTransaction;

  bool shouldRequireTOTP2FAFor(String destinationAddress) {
    final settingsStore = _appStore.settingsStore;

    final isContact = _contactListViewModel.contactsToShow
        .any((contact) => contact.address == destinationAddress);

    if (isContact) {
      return settingsStore.shouldRequireTOTP2FAForSendsToContact;
    }

    final isInternalWallet = _contactListViewModel.walletContactsToShow
        .any((contact) => contact.address == destinationAddress);

    if (isInternalWallet) {
      return settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets;
    }

    return settingsStore.shouldRequireTOTP2FAForSendsToNonContact;
  }

  @action
  Future<void> createTransaction(SolanaNFTAssetModel asset, String destinationAddress) async {
    state = IsExecutingState();

    try {
      pendingTransaction = await solana!.sendNFT(
        _appStore.wallet!,
        mintAddress: asset.mint!,
        destinationAddress: destinationAddress,
        name: asset.name,
      );

      state = ExecutedSuccessfullyState();
    } catch (e) {
      pendingTransaction = null;
      state = FailureState(_errorMessage(e));
    }
  }

  @action
  Future<void> commitTransaction() async {
    state = IsExecutingState();

    try {
      final wallet = _appStore.wallet!;
      final transaction = pendingTransaction!;

      await transaction.commit();

      final signature = transaction.id;

      pendingTransaction = null;
      state = ExecutedSuccessfullyState();

      if (signature.isNotEmpty) {
        unawaited(_pollForTransaction(wallet, signature));
      }
    } catch (e) {
      state = FailureState(_errorMessage(e));
    }
  }

  @action
  void reset() {
    pendingTransaction = null;
    state = InitialExecutionState();
  }

  Future<void> _pollForTransaction(WalletBase wallet, String signature) async {
    try {
      await solana!.pollForTransaction(wallet, signature);
    } catch (e) {
      printV("Failed to poll for NFT transfer: ${e.toString()}");
    }
  }

  String _errorMessage(Object error) {
    if (error is NotAnNFTException) {
      return S.current.nft_send_not_an_nft;
    }

    if (error is NoAssociatedTokenAccountException) {
      return S.current.solana_no_associated_token_account_exception;
    }

    if (error is SignSPLTokenTransactionRentException) {
      return S.current.solana_sign_spl_token_transaction_rent_exception;
    }

    if (error is CreateAssociatedTokenAccountException) {
      return "${S.current.solana_create_associated_token_account_exception} "
          "${S.current.added_message_for_ata_error}";
    }

    return error.toString();
  }
}
