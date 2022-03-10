import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'lend_view_model.g.dart';


class LendViewModel = LendViewModelBase
    with _$LendViewModel;

abstract class LendViewModelBase with Store {
  LendViewModelBase({@required this.wallet});

  final WalletBase wallet;

  @computed
  bool get status => wallet.syncStatus is SyncedSyncStatus;

}